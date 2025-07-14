#!/usr/bin/env luajit

local argparse = require('argparse')
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

local parser = argparse('system-info', 'System information gathering tool')

parser:flag('-c --cpu', 'Show CPU information')
parser:flag('-m --memory', 'Show memory information')
parser:flag('-d --disk', 'Show disk usage')
parser:flag('-n --network', 'Show network interfaces')
parser:flag('-p --processes', 'Show running processes')
parser:flag('-j --json', 'Output in JSON format')
parser:flag('-w --watch', 'Watch mode (refresh every 2 seconds)')
parser:option('-i --interval', 'Watch interval in seconds'):default('2')

local function execute_command(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return utils.trim(result)
end

local function get_cpu_info()
    local info = {}
    
    if os.execute("which lscpu > /dev/null 2>&1") == 0 then
        local output = execute_command("lscpu")
        for line in output:gmatch("[^\r\n]+") do
            local key, value = line:match("([^:]+):%s*(.+)")
            if key and value then
                info[utils.trim(key)] = utils.trim(value)
            end
        end
    elseif os.execute("which sysctl > /dev/null 2>&1") == 0 then
        info["CPU Model"] = execute_command("sysctl -n machdep.cpu.brand_string")
        info["CPU Cores"] = execute_command("sysctl -n hw.ncpu")
        info["CPU Frequency"] = execute_command("sysctl -n hw.cpufrequency_max") .. " Hz"
    else
        info["CPU Info"] = "Unable to detect CPU information"
    end
    
    local load_avg = execute_command("uptime | grep -o 'load average.*' | cut -d':' -f2")
    if load_avg and load_avg ~= "" then
        info["Load Average"] = utils.trim(load_avg)
    end
    
    return info
end

local function get_memory_info()
    local info = {}
    
    if os.execute("which free > /dev/null 2>&1") == 0 then
        local output = execute_command("free -h")
        local lines = utils.string_split(output, "\n")
        if lines[2] then
            local mem_parts = utils.string_split(lines[2], "%s+")
            info["Total"] = mem_parts[2] or "Unknown"
            info["Used"] = mem_parts[3] or "Unknown"
            info["Free"] = mem_parts[4] or "Unknown"
            info["Available"] = mem_parts[7] or "Unknown"
        end
    elseif os.execute("which vm_stat > /dev/null 2>&1") == 0 then
        local page_size = tonumber(execute_command("vm_stat | grep 'page size' | grep -o '[0-9]*'")) or 4096
        local pages_free = tonumber(execute_command("vm_stat | grep 'Pages free' | grep -o '[0-9]*'")) or 0
        local pages_active = tonumber(execute_command("vm_stat | grep 'Pages active' | grep -o '[0-9]*'")) or 0
        local pages_inactive = tonumber(execute_command("vm_stat | grep 'Pages inactive' | grep -o '[0-9]*'")) or 0
        
        local total_mem = tonumber(execute_command("sysctl -n hw.memsize")) or 0
        local free_mem = pages_free * page_size
        local used_mem = (pages_active + pages_inactive) * page_size
        
        info["Total"] = utils.format_bytes(total_mem)
        info["Used"] = utils.format_bytes(used_mem)
        info["Free"] = utils.format_bytes(free_mem)
    else
        info["Memory Info"] = "Unable to detect memory information"
    end
    
    return info
end

local function get_disk_info()
    local info = {}
    
    local output = execute_command("df -h")
    local lines = utils.string_split(output, "\n")
    
    for i = 2, #lines do
        local parts = utils.string_split(lines[i], "%s+")
        if #parts >= 6 then
            info[parts[6]] = {
                filesystem = parts[1],
                size = parts[2],
                used = parts[3],
                available = parts[4],
                use_percent = parts[5]
            }
        end
    end
    
    return info
end

local function get_network_info()
    local info = {}
    
    if os.execute("which ip > /dev/null 2>&1") == 0 then
        local output = execute_command("ip addr show")
        local current_interface = nil
        
        for line in output:gmatch("[^\r\n]+") do
            local interface = line:match("^%d+:%s*([^:]+):")
            if interface then
                current_interface = utils.trim(interface)
                info[current_interface] = {}
            elseif current_interface then
                local ip = line:match("inet%s+([^/]+)")
                if ip then
                    info[current_interface].ipv4 = ip
                end
                
                local ip6 = line:match("inet6%s+([^/]+)")
                if ip6 then
                    info[current_interface].ipv6 = ip6
                end
            end
        end
    elseif os.execute("which ifconfig > /dev/null 2>&1") == 0 then
        local output = execute_command("ifconfig")
        local current_interface = nil
        
        for line in output:gmatch("[^\r\n]+") do
            local interface = line:match("^([^%s:]+):")
            if interface then
                current_interface = interface
                info[current_interface] = {}
            elseif current_interface then
                local ip = line:match("inet%s+([%d%.]+)")
                if ip then
                    info[current_interface].ipv4 = ip
                end
                
                local ip6 = line:match("inet6%s+([^%s]+)")
                if ip6 then
                    info[current_interface].ipv6 = ip6
                end
            end
        end
    end
    
    return info
end

local function get_process_info()
    local info = {}
    
    local output = execute_command("ps aux | head -10")
    local lines = utils.string_split(output, "\n")
    
    for i = 2, #lines do
        local parts = utils.string_split(lines[i], "%s+")
        if #parts >= 11 then
            table.insert(info, {
                user = parts[1],
                pid = parts[2],
                cpu = parts[3],
                memory = parts[4],
                command = table.concat(parts, " ", 11)
            })
        end
    end
    
    return info
end

local function print_section(title, data, json_mode)
    if json_mode then
        return data
    end
    
    print("\n=== " .. title .. " ===")
    
    if type(data) == "table" then
        if title == "Disk Usage" then
            for mount, info in pairs(data) do
                print(string.format("%-20s %8s %8s %8s %8s %s", 
                    mount, info.size, info.used, info.available, info.use_percent, info.filesystem))
            end
        elseif title == "Network Interfaces" then
            for interface, info in pairs(data) do
                print(string.format("%-15s IPv4: %-15s IPv6: %s", 
                    interface, info.ipv4 or "none", info.ipv6 or "none"))
            end
        elseif title == "Top Processes" then
            print(string.format("%-10s %5s %5s %5s %s", "USER", "PID", "CPU%", "MEM%", "COMMAND"))
            for _, proc in ipairs(data) do
                print(string.format("%-10s %5s %5s %5s %s", 
                    proc.user, proc.pid, proc.cpu, proc.memory, proc.command:sub(1, 40)))
            end
        else
            for key, value in pairs(data) do
                print(string.format("%-20s: %s", key, tostring(value)))
            end
        end
    else
        print(tostring(data))
    end
end

local function collect_all_info(args)
    local system_info = {}
    
    if args.cpu then
        system_info.cpu = get_cpu_info()
    end
    
    if args.memory then
        system_info.memory = get_memory_info()
    end
    
    if args.disk then
        system_info.disk = get_disk_info()
    end
    
    if args.network then
        system_info.network = get_network_info()
    end
    
    if args.processes then
        system_info.processes = get_process_info()
    end
    
    if not (args.cpu or args.memory or args.disk or args.network or args.processes) then
        system_info.cpu = get_cpu_info()
        system_info.memory = get_memory_info()
        system_info.disk = get_disk_info()
    end
    
    return system_info
end

local function main()
    logger.set_level("ERROR")
    
    local args = parser:parse()
    
    repeat
        local system_info = collect_all_info(args)
        
        if args.json then
            local json = require('libs.external.json')
            print(json.encode(system_info))
        else
            os.execute("clear")
            print("System Information - " .. utils.get_timestamp())
            
            if system_info.cpu then
                print_section("CPU Information", system_info.cpu, false)
            end
            
            if system_info.memory then
                print_section("Memory Information", system_info.memory, false)
            end
            
            if system_info.disk then
                print_section("Disk Usage", system_info.disk, false)
            end
            
            if system_info.network then
                print_section("Network Interfaces", system_info.network, false)
            end
            
            if system_info.processes then
                print_section("Top Processes", system_info.processes, false)
            end
        end
        
        if args.watch then
            os.execute("sleep " .. args.interval)
        end
    until not args.watch
end

if not pcall(main) then
    logger.error("An error occurred during execution")
    os.exit(1)
end