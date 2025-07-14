#!/usr/bin/env luajit

local argparse = require('argparse')
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

local processor = {}

function processor.load_json(path)
    local json = require('libs.external.json')
    local file = io.open(path, "r")
    
    if not file then
        error("Cannot open file: " .. path)
    end
    
    local content = file:read("*a")
    file:close()
    
    local success, data = pcall(json.decode, content)
    if not success then
        error("Invalid JSON in file: " .. path)
    end
    
    return data
end

function processor.save_json(data, path, pretty)
    local json = require('libs.external.json')
    local file = io.open(path, "w")
    
    if not file then
        error("Cannot write to file: " .. path)
    end
    
    local content
    if pretty then
        content = processor.pretty_print_json(data)
    else
        content = json.encode(data)
    end
    
    file:write(content)
    file:close()
end

function processor.pretty_print_json(data, indent)
    indent = indent or 0
    local json = require('libs.external.json')
    local space = string.rep("  ", indent)
    
    if type(data) == "table" then
        local is_array = true
        local max_index = 0
        
        -- Check if table is an array
        for k, v in pairs(data) do
            if type(k) ~= "number" or k <= 0 or k ~= math.floor(k) then
                is_array = false
                break
            end
            max_index = math.max(max_index, k)
        end
        
        if is_array then
            -- Check for contiguous array
            for i = 1, max_index do
                if data[i] == nil then
                    is_array = false
                    break
                end
            end
        end
        
        if is_array then
            local parts = {}
            table.insert(parts, "[")
            for i = 1, #data do
                if i > 1 then
                    table.insert(parts, ",")
                end
                table.insert(parts, "\n" .. space .. "  ")
                table.insert(parts, processor.pretty_print_json(data[i], indent + 1))
            end
            if #data > 0 then
                table.insert(parts, "\n" .. space)
            end
            table.insert(parts, "]")
            return table.concat(parts)
        else
            local parts = {}
            table.insert(parts, "{")
            local first = true
            for k, v in pairs(data) do
                if not first then
                    table.insert(parts, ",")
                end
                first = false
                table.insert(parts, "\n" .. space .. "  ")
                table.insert(parts, json.encode(tostring(k)))
                table.insert(parts, ": ")
                table.insert(parts, processor.pretty_print_json(v, indent + 1))
            end
            if not first then
                table.insert(parts, "\n" .. space)
            end
            table.insert(parts, "}")
            return table.concat(parts)
        end
    else
        return json.encode(data)
    end
end

function processor.query_json(data, path)
    local parts = utils.string_split(path, ".")
    local current = data
    
    for _, part in ipairs(parts) do
        if type(current) ~= "table" then
            return nil
        end
        
        -- Handle array indices
        local index = tonumber(part)
        if index then
            current = current[index]
        else
            current = current[part]
        end
        
        if current == nil then
            return nil
        end
    end
    
    return current
end

function processor.set_json_value(data, path, value)
    local parts = utils.string_split(path, ".")
    local current = data
    
    for i = 1, #parts - 1 do
        local part = parts[i]
        local index = tonumber(part)
        
        if index then
            if type(current) ~= "table" then
                current = {}
            end
            if not current[index] then
                current[index] = {}
            end
            current = current[index]
        else
            if type(current) ~= "table" then
                current = {}
            end
            if not current[part] then
                current[part] = {}
            end
            current = current[part]
        end
    end
    
    local last_part = parts[#parts]
    local index = tonumber(last_part)
    
    if index then
        current[index] = value
    else
        current[last_part] = value
    end
    
    return data
end

function processor.filter_json(data, filter_func)
    if type(data) == "table" then
        local result = {}
        local is_array = true
        
        -- Check if it's an array
        for k, v in pairs(data) do
            if type(k) ~= "number" then
                is_array = false
                break
            end
        end
        
        if is_array then
            for i, v in ipairs(data) do
                if filter_func(v, i) then
                    table.insert(result, processor.filter_json(v, filter_func))
                end
            end
        else
            for k, v in pairs(data) do
                if filter_func(v, k) then
                    result[k] = processor.filter_json(v, filter_func)
                end
            end
        end
        
        return result
    else
        return data
    end
end

function processor.transform_json(data, transform_func)
    if type(data) == "table" then
        local result = {}
        local is_array = true
        
        -- Check if it's an array
        for k, v in pairs(data) do
            if type(k) ~= "number" then
                is_array = false
                break
            end
        end
        
        if is_array then
            for i, v in ipairs(data) do
                local transformed = transform_func(v, i)
                if transformed ~= nil then
                    table.insert(result, processor.transform_json(transformed, transform_func))
                end
            end
        else
            for k, v in pairs(data) do
                local transformed = transform_func(v, k)
                if transformed ~= nil then
                    result[k] = processor.transform_json(transformed, transform_func)
                end
            end
        end
        
        return result
    else
        return transform_func(data)
    end
end

function processor.merge_json(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return source
    end
    
    local result = utils.deep_copy(target)
    
    for k, v in pairs(source) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = processor.merge_json(result[k], v)
        else
            result[k] = utils.deep_copy(v)
        end
    end
    
    return result
end

function processor.validate_schema(data, schema)
    local function validate_value(value, schema_part)
        if schema_part.type then
            local value_type = type(value)
            if value_type == "number" and schema_part.type == "integer" then
                if value ~= math.floor(value) then
                    return false, "Expected integer, got float"
                end
            elseif value_type ~= schema_part.type then
                return false, "Expected " .. schema_part.type .. ", got " .. value_type
            end
        end
        
        if schema_part.required and value == nil then
            return false, "Required field is missing"
        end
        
        if schema_part.minimum and type(value) == "number" and value < schema_part.minimum then
            return false, "Value below minimum: " .. schema_part.minimum
        end
        
        if schema_part.maximum and type(value) == "number" and value > schema_part.maximum then
            return false, "Value above maximum: " .. schema_part.maximum
        end
        
        if schema_part.pattern and type(value) == "string" then
            if not value:match(schema_part.pattern) then
                return false, "String does not match pattern"
            end
        end
        
        if schema_part.properties and type(value) == "table" then
            for prop, prop_schema in pairs(schema_part.properties) do
                local valid, err = validate_value(value[prop], prop_schema)
                if not valid then
                    return false, "Property '" .. prop .. "': " .. err
                end
            end
        end
        
        return true
    end
    
    return validate_value(data, schema)
end

-- CLI interface
local parser = argparse('json-processor', 'Advanced JSON processing tool')

parser:command_target("command")

local query_cmd = parser:command('query q', 'Query JSON data')
query_cmd:argument('file', 'JSON file path')
query_cmd:argument('path', 'Query path (e.g., users.0.name)')
query_cmd:flag('-p --pretty', 'Pretty print output')

local set_cmd = parser:command('set', 'Set JSON value')
set_cmd:argument('file', 'JSON file path')
set_cmd:argument('path', 'Path to set (e.g., users.0.name)')
set_cmd:argument('value', 'Value to set')
set_cmd:option('-t --type', 'Value type'):choices({'string', 'number', 'boolean', 'null'}):default('string')
set_cmd:flag('-p --pretty', 'Pretty print output')

local merge_cmd = parser:command('merge', 'Merge JSON files')
merge_cmd:argument('target', 'Target JSON file')
merge_cmd:argument('source', 'Source JSON file')
merge_cmd:option('-o --output', 'Output file (default: target)')
merge_cmd:flag('-p --pretty', 'Pretty print output')

local format_cmd = parser:command('format fmt', 'Format JSON file')
format_cmd:argument('file', 'JSON file path')
format_cmd:option('-o --output', 'Output file (default: overwrite input)')
format_cmd:flag('-c --compact', 'Compact output (no pretty printing)')

local validate_cmd = parser:command('validate', 'Validate JSON against schema')
validate_cmd:argument('file', 'JSON file path')
validate_cmd:argument('schema', 'Schema file path')

local filter_cmd = parser:command('filter', 'Filter JSON data')
filter_cmd:argument('file', 'JSON file path')
filter_cmd:argument('expression', 'Filter expression (Lua code)')
filter_cmd:option('-o --output', 'Output file')
filter_cmd:flag('-p --pretty', 'Pretty print output')

local function convert_value(value, value_type)
    if value_type == "number" then
        return tonumber(value)
    elseif value_type == "boolean" then
        return value:lower() == "true"
    elseif value_type == "null" then
        return nil
    else
        return value
    end
end

local function main()
    logger.set_level("INFO")
    
    local args = parser:parse()
    
    if args.command == "query" then
        local data = processor.load_json(args.file)
        local result = processor.query_json(data, args.path)
        
        if result == nil then
            logger.error("Path not found: %s", args.path)
            os.exit(1)
        end
        
        if args.pretty and type(result) == "table" then
            print(processor.pretty_print_json(result))
        else
            local json = require('libs.external.json')
            print(json.encode(result))
        end
        
    elseif args.command == "set" then
        local data = processor.load_json(args.file)
        local value = convert_value(args.value, args.type)
        
        processor.set_json_value(data, args.path, value)
        processor.save_json(data, args.file, args.pretty)
        
        logger.info("Set %s = %s", args.path, args.value)
        
    elseif args.command == "merge" then
        local target = processor.load_json(args.target)
        local source = processor.load_json(args.source)
        
        local merged = processor.merge_json(target, source)
        local output_file = args.output or args.target
        
        processor.save_json(merged, output_file, args.pretty)
        logger.info("Merged %s into %s", args.source, output_file)
        
    elseif args.command == "format" then
        local data = processor.load_json(args.file)
        local output_file = args.output or args.file
        
        processor.save_json(data, output_file, not args.compact)
        logger.info("Formatted %s", output_file)
        
    elseif args.command == "validate" then
        local data = processor.load_json(args.file)
        local schema = processor.load_json(args.schema)
        
        local valid, error_msg = processor.validate_schema(data, schema)
        
        if valid then
            logger.info("JSON is valid according to schema")
        else
            logger.error("Validation failed: %s", error_msg)
            os.exit(1)
        end
        
    elseif args.command == "filter" then
        local data = processor.load_json(args.file)
        
        -- Create filter function from expression
        local filter_func = load("return function(value, key) return " .. args.expression .. " end")()
        
        local filtered = processor.filter_json(data, filter_func)
        
        if args.output then
            processor.save_json(filtered, args.output, args.pretty)
            logger.info("Filtered data saved to %s", args.output)
        else
            if args.pretty then
                print(processor.pretty_print_json(filtered))
            else
                local json = require('libs.external.json')
                print(json.encode(filtered))
            end
        end
    end
end

if not pcall(main) then
    logger.error("An error occurred during execution")
    os.exit(1)
end