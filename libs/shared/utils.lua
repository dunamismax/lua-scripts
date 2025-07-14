local utils = {}

function utils.table_merge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

function utils.string_split(str, delimiter)
    local result = {}
    local pattern = "([^" .. delimiter .. "]+)"
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end

function utils.file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

function utils.deep_copy(obj)
    if type(obj) ~= 'table' then return obj end
    local copy = {}
    for k, v in pairs(obj) do
        copy[utils.deep_copy(k)] = utils.deep_copy(v)
    end
    return copy
end

function utils.trim(str)
    return str:match("^%s*(.-)%s*$")
end

function utils.get_timestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

function utils.format_bytes(bytes)
    local units = {"B", "KB", "MB", "GB", "TB"}
    local size = bytes
    local unit_index = 1
    
    while size >= 1024 and unit_index < #units do
        size = size / 1024
        unit_index = unit_index + 1
    end
    
    return string.format("%.2f %s", size, units[unit_index])
end

function utils.escape_shell_arg(arg)
    return "'" .. arg:gsub("'", "'\\''") .. "'"
end

function utils.map(tbl, func)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = func(v)
    end
    return result
end

function utils.filter(tbl, predicate)
    local result = {}
    for _, v in ipairs(tbl) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

return utils