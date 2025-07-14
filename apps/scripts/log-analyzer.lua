#!/usr/bin/env luajit

local lfs = require('lfs')
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

local analyzer = {}

function analyzer.parse_log_line(line, format_type)
    format_type = format_type or "common"
    
    local patterns = {
        common = "^(%S+) %- %- %[(.-)%] \"(.-)\" (%d+) (%d+)",
        combined = "^(%S+) %- %- %[(.-)%] \"(.-)\" (%d+) (%d+) \"(.-)\" \"(.-)\"",
        nginx = "^(%S+) %- %- %[(.-)%] \"(.-)\" (%d+) (%d+)",
        apache = "^(%S+) %- %- %[(.-)%] \"(.-)\" (%d+) (%d+)",
        custom = "^%[(.-)%] (%w+): (.+)"
    }
    
    local pattern = patterns[format_type]
    if not pattern then
        return nil
    end
    
    if format_type == "common" or format_type == "nginx" or format_type == "apache" then
        local ip, timestamp, request, status, size = line:match(pattern)
        if ip then
            return {
                ip = ip,
                timestamp = timestamp,
                request = request,
                status = tonumber(status),
                size = tonumber(size),
                method = request and request:match("^(%S+)") or nil,
                url = request and request:match("^%S+ (%S+)") or nil
            }
        end
    elseif format_type == "combined" then
        local ip, timestamp, request, status, size, referer, user_agent = line:match(pattern)
        if ip then
            return {
                ip = ip,
                timestamp = timestamp,
                request = request,
                status = tonumber(status),
                size = tonumber(size),
                referer = referer,
                user_agent = user_agent,
                method = request and request:match("^(%S+)") or nil,
                url = request and request:match("^%S+ (%S+)") or nil
            }
        end
    elseif format_type == "custom" then
        local timestamp, level, message = line:match(pattern)
        if timestamp then
            return {
                timestamp = timestamp,
                level = level,
                message = message
            }
        end
    end
    
    return nil
end

function analyzer.analyze_file(file_path, format_type)
    local file = io.open(file_path, "r")
    if not file then
        error("Cannot open file: " .. file_path)
    end
    
    local stats = {
        total_lines = 0,
        parsed_lines = 0,
        error_lines = 0,
        status_codes = {},
        ip_addresses = {},
        methods = {},
        urls = {},
        user_agents = {},
        hourly_traffic = {},
        error_messages = {}
    }
    
    logger.info("Analyzing file: %s", file_path)
    
    for line in file:lines() do
        stats.total_lines = stats.total_lines + 1
        
        local parsed = analyzer.parse_log_line(line, format_type)
        
        if parsed then
            stats.parsed_lines = stats.parsed_lines + 1
            
            -- Count status codes
            if parsed.status then
                stats.status_codes[parsed.status] = (stats.status_codes[parsed.status] or 0) + 1
            end
            
            -- Count IP addresses
            if parsed.ip then
                stats.ip_addresses[parsed.ip] = (stats.ip_addresses[parsed.ip] or 0) + 1
            end
            
            -- Count HTTP methods
            if parsed.method then
                stats.methods[parsed.method] = (stats.methods[parsed.method] or 0) + 1
            end
            
            -- Count URLs
            if parsed.url then
                stats.urls[parsed.url] = (stats.urls[parsed.url] or 0) + 1
            end
            
            -- Count user agents
            if parsed.user_agent and parsed.user_agent ~= "-" then
                stats.user_agents[parsed.user_agent] = (stats.user_agents[parsed.user_agent] or 0) + 1
            end
            
            -- Track hourly traffic
            if parsed.timestamp then
                local hour = parsed.timestamp:match("(%d+:%d+):")
                if hour then
                    stats.hourly_traffic[hour] = (stats.hourly_traffic[hour] or 0) + 1
                end
            end
            
            -- Track error messages (for custom logs)
            if parsed.level and (parsed.level == "ERROR" or parsed.level == "WARN") then
                table.insert(stats.error_messages, {
                    timestamp = parsed.timestamp,
                    level = parsed.level,
                    message = parsed.message
                })
            end
        else
            stats.error_lines = stats.error_lines + 1
        end
        
        if stats.total_lines % 10000 == 0 then
            logger.info("Processed %d lines...", stats.total_lines)
        end
    end
    
    file:close()
    
    logger.info("Analysis complete. Processed %d lines, parsed %d successfully", 
                stats.total_lines, stats.parsed_lines)
    
    return stats
end

function analyzer.get_top_items(table_data, count)
    count = count or 10
    
    local items = {}
    for key, value in pairs(table_data) do
        table.insert(items, {key = key, count = value})
    end
    
    table.sort(items, function(a, b) return a.count > b.count end)
    
    local result = {}
    for i = 1, math.min(count, #items) do
        table.insert(result, items[i])
    end
    
    return result
end

function analyzer.generate_report(stats, format)
    format = format or "text"
    
    if format == "json" then
        local json = require('libs.external.json')
        return json.encode({
            summary = {
                total_lines = stats.total_lines,
                parsed_lines = stats.parsed_lines,
                error_lines = stats.error_lines,
                parse_rate = stats.total_lines > 0 and (stats.parsed_lines / stats.total_lines) or 0
            },
            top_status_codes = analyzer.get_top_items(stats.status_codes),
            top_ips = analyzer.get_top_items(stats.ip_addresses),
            top_methods = analyzer.get_top_items(stats.methods),
            top_urls = analyzer.get_top_items(stats.urls),
            top_user_agents = analyzer.get_top_items(stats.user_agents, 5),
            hourly_traffic = stats.hourly_traffic,
            recent_errors = utils.filter(stats.error_messages, function(err) 
                return #stats.error_messages <= 20 or err.level == "ERROR"
            end)
        })
    else
        local report = {}
        
        table.insert(report, "=== LOG ANALYSIS REPORT ===")
        table.insert(report, "")
        table.insert(report, "Summary:")
        table.insert(report, string.format("  Total lines: %d", stats.total_lines))
        table.insert(report, string.format("  Parsed lines: %d", stats.parsed_lines))
        table.insert(report, string.format("  Error lines: %d", stats.error_lines))
        table.insert(report, string.format("  Parse rate: %.2f%%", 
            stats.total_lines > 0 and (stats.parsed_lines / stats.total_lines * 100) or 0))
        table.insert(report, "")
        
        -- Top status codes
        table.insert(report, "Top Status Codes:")
        local top_status = analyzer.get_top_items(stats.status_codes)
        for _, item in ipairs(top_status) do
            table.insert(report, string.format("  %s: %d", item.key, item.count))
        end
        table.insert(report, "")
        
        -- Top IP addresses
        table.insert(report, "Top IP Addresses:")
        local top_ips = analyzer.get_top_items(stats.ip_addresses)
        for _, item in ipairs(top_ips) do
            table.insert(report, string.format("  %s: %d", item.key, item.count))
        end
        table.insert(report, "")
        
        -- Top HTTP methods
        if next(stats.methods) then
            table.insert(report, "HTTP Methods:")
            local top_methods = analyzer.get_top_items(stats.methods)
            for _, item in ipairs(top_methods) do
                table.insert(report, string.format("  %s: %d", item.key, item.count))
            end
            table.insert(report, "")
        end
        
        -- Top URLs
        if next(stats.urls) then
            table.insert(report, "Top URLs:")
            local top_urls = analyzer.get_top_items(stats.urls)
            for _, item in ipairs(top_urls) do
                local url = item.key:sub(1, 50)
                if #item.key > 50 then url = url .. "..." end
                table.insert(report, string.format("  %s: %d", url, item.count))
            end
            table.insert(report, "")
        end
        
        -- Recent errors
        if #stats.error_messages > 0 then
            table.insert(report, "Recent Errors:")
            local recent = utils.filter(stats.error_messages, function(err, idx) 
                return idx <= 10 
            end)
            for _, err in ipairs(recent) do
                table.insert(report, string.format("  [%s] %s: %s", 
                    err.timestamp, err.level, err.message:sub(1, 100)))
            end
            table.insert(report, "")
        end
        
        return table.concat(report, "\n")
    end
end

function analyzer.watch_file(file_path, format_type, interval)
    interval = interval or 5
    
    local last_size = 0
    local last_position = 0
    
    logger.info("Watching file: %s (interval: %ds)", file_path, interval)
    
    while true do
        local attr = lfs.attributes(file_path)
        
        if attr and attr.size > last_size then
            local file = io.open(file_path, "r")
            if file then
                file:seek("set", last_position)
                
                local new_lines = 0
                for line in file:lines() do
                    local parsed = analyzer.parse_log_line(line, format_type)
                    if parsed then
                        if parsed.status and parsed.status >= 400 then
                            logger.warn("HTTP Error: %s %s -> %d", 
                                parsed.method or "?", parsed.url or "?", parsed.status)
                        elseif parsed.level and (parsed.level == "ERROR" or parsed.level == "WARN") then
                            logger.warn("Log %s: %s", parsed.level, parsed.message)
                        end
                    end
                    new_lines = new_lines + 1
                end
                
                last_position = file:seek()
                last_size = attr.size
                file:close()
                
                if new_lines > 0 then
                    logger.info("Processed %d new lines", new_lines)
                end
            end
        end
        
        os.execute("sleep " .. interval)
    end
end

-- CLI interface
local function main()
    if #arg < 1 then
        print("Usage: luajit log-analyzer.lua <file> [options]")
        print("Options:")
        print("  --format <type>    Log format: common, combined, nginx, apache, custom")
        print("  --output <format>  Output format: text, json")
        print("  --watch            Watch file for new entries")
        print("  --interval <sec>   Watch interval in seconds (default: 5)")
        print("  --save <file>      Save report to file")
        os.exit(1)
    end
    
    local file_path = arg[1]
    local format_type = "common"
    local output_format = "text"
    local watch_mode = false
    local watch_interval = 5
    local save_file = nil
    
    local i = 2
    while i <= #arg do
        if arg[i] == "--format" and arg[i+1] then
            format_type = arg[i+1]
            i = i + 2
        elseif arg[i] == "--output" and arg[i+1] then
            output_format = arg[i+1]
            i = i + 2
        elseif arg[i] == "--watch" then
            watch_mode = true
            i = i + 1
        elseif arg[i] == "--interval" and arg[i+1] then
            watch_interval = tonumber(arg[i+1]) or 5
            i = i + 2
        elseif arg[i] == "--save" and arg[i+1] then
            save_file = arg[i+1]
            i = i + 2
        else
            i = i + 1
        end
    end
    
    logger.set_level("INFO")
    
    if not lfs.attributes(file_path) then
        logger.error("File does not exist: %s", file_path)
        os.exit(1)
    end
    
    if watch_mode then
        analyzer.watch_file(file_path, format_type, watch_interval)
    else
        local stats = analyzer.analyze_file(file_path, format_type)
        local report = analyzer.generate_report(stats, output_format)
        
        if save_file then
            local file = io.open(save_file, "w")
            if file then
                file:write(report)
                file:close()
                logger.info("Report saved to: %s", save_file)
            else
                logger.error("Cannot write to file: %s", save_file)
            end
        else
            print(report)
        end
    end
end

if arg and #arg > 0 then
    main()
end

return analyzer