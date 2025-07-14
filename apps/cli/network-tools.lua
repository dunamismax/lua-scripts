#!/usr/bin/env luajit

local socket = require('socket')
local argparse = require('argparse')
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

local network = {}

function network.ping_host(host, port, timeout)
    timeout = timeout or 5
    
    local start_time = socket.gettime()
    local tcp = socket.tcp()
    tcp:settimeout(timeout)
    
    local success, err = tcp:connect(host, port)
    local end_time = socket.gettime()
    
    tcp:close()
    
    if success then
        return true, (end_time - start_time) * 1000 -- Return time in milliseconds
    else
        return false, err
    end
end

function network.port_scan(host, ports, timeout)
    timeout = timeout or 2
    local open_ports = {}
    local closed_ports = {}
    
    logger.info("Scanning %s for open ports...", host)
    
    for _, port in ipairs(ports) do
        local success, time_or_err = network.ping_host(host, port, timeout)
        
        if success then
            table.insert(open_ports, {port = port, response_time = time_or_err})
            logger.info("Port %d: OPEN (%.2fms)", port, time_or_err)
        else
            table.insert(closed_ports, port)
        end
    end
    
    return open_ports, closed_ports
end

function network.http_request(method, url, headers, body)
    local http = require('socket.http')
    local ltn12 = require('ltn12')
    
    headers = headers or {}
    headers["User-Agent"] = headers["User-Agent"] or "Lua Network Tools/1.0"
    
    local response_body = {}
    local response_headers = {}
    
    local result, status, response_headers = http.request({
        url = url,
        method = method:upper(),
        headers = headers,
        source = body and ltn12.source.string(body) or nil,
        sink = ltn12.sink.table(response_body)
    })
    
    return {
        success = result ~= nil,
        status = status,
        headers = response_headers,
        body = table.concat(response_body)
    }
end

function network.dns_lookup(hostname)
    local ip, err = socket.dns.toip(hostname)
    if ip then
        return {success = true, ip = ip}
    else
        return {success = false, error = err}
    end
end

function network.reverse_dns(ip)
    local hostname, err = socket.dns.tohostname(ip)
    if hostname then
        return {success = true, hostname = hostname}
    else
        return {success = false, error = err}
    end
end

function network.trace_route(host, max_hops)
    max_hops = max_hops or 30
    local hops = {}
    
    -- Note: This is a simplified traceroute. 
    -- A full implementation would require raw sockets or system calls
    logger.info("Tracing route to %s (simplified)", host)
    
    for i = 1, max_hops do
        local success, time = network.ping_host(host, 80, 3)
        
        if success then
            table.insert(hops, {
                hop = i,
                host = host,
                response_time = time
            })
            break
        else
            table.insert(hops, {
                hop = i,
                host = "*",
                response_time = nil
            })
        end
    end
    
    return hops
end

function network.bandwidth_test(host, port, duration)
    duration = duration or 10
    local total_bytes = 0
    local start_time = socket.gettime()
    
    logger.info("Starting bandwidth test to %s:%d", host, port)
    
    local tcp = socket.tcp()
    tcp:settimeout(1)
    
    local success, err = tcp:connect(host, port)
    if not success then
        return {success = false, error = err}
    end
    
    -- Send data for the specified duration
    while socket.gettime() - start_time < duration do
        local data = string.rep("X", 1024) -- 1KB chunks
        local bytes_sent, err = tcp:send(data)
        
        if bytes_sent then
            total_bytes = total_bytes + bytes_sent
        else
            break
        end
    end
    
    tcp:close()
    
    local elapsed = socket.gettime() - start_time
    local bandwidth = (total_bytes * 8) / elapsed / 1000000 -- Mbps
    
    return {
        success = true,
        total_bytes = total_bytes,
        duration = elapsed,
        bandwidth_mbps = bandwidth
    }
end

function network.simple_server(port, handler)
    local server = socket.bind("*", port)
    if not server then
        error("Cannot bind to port " .. port)
    end
    
    logger.info("Server listening on port %d", port)
    
    while true do
        local client = server:accept()
        if client then
            client:settimeout(10)
            
            local request = client:receive()
            if request then
                local response = handler(request)
                client:send(response)
            end
            
            client:close()
        end
    end
end

function network.whois_lookup(domain)
    -- Simple whois implementation using system command
    local handle = io.popen("whois " .. domain .. " 2>/dev/null")
    if not handle then
        return {success = false, error = "whois command not available"}
    end
    
    local result = handle:read("*a")
    handle:close()
    
    if result and result ~= "" then
        return {success = true, data = result}
    else
        return {success = false, error = "No whois data found"}
    end
end

-- CLI interface
local parser = argparse('network-tools', 'Network utilities and testing tools')

parser:command_target("command")

local ping_cmd = parser:command('ping', 'Ping a host on specific port')
ping_cmd:argument('host', 'Hostname or IP address')
ping_cmd:argument('port', 'Port number'):convert(tonumber)
ping_cmd:option('-t --timeout', 'Timeout in seconds'):default('5'):convert(tonumber)
ping_cmd:option('-c --count', 'Number of pings'):default('1'):convert(tonumber)

local scan_cmd = parser:command('scan', 'Port scan a host')
scan_cmd:argument('host', 'Hostname or IP address')
scan_cmd:option('-p --ports', 'Port range (e.g., 80,443,22-25)'):default('80,443,22,21,25,53,110,143,993,995')
scan_cmd:option('-t --timeout', 'Timeout per port'):default('2'):convert(tonumber)

local http_cmd = parser:command('http', 'Make HTTP request')
http_cmd:argument('method', 'HTTP method'):choices({'GET', 'POST', 'PUT', 'DELETE', 'HEAD'})
http_cmd:argument('url', 'URL to request')
http_cmd:option('-H --header', 'HTTP header (key:value)'):count("*")
http_cmd:option('-d --data', 'Request body data')
http_cmd:flag('-v --verbose', 'Verbose output')

local dns_cmd = parser:command('dns', 'DNS lookup')
dns_cmd:argument('hostname', 'Hostname to resolve')
dns_cmd:flag('-r --reverse', 'Reverse DNS lookup (IP to hostname)')

local trace_cmd = parser:command('trace', 'Trace route to host')
trace_cmd:argument('host', 'Hostname or IP address')
trace_cmd:option('-m --max-hops', 'Maximum hops'):default('30'):convert(tonumber)

local server_cmd = parser:command('server', 'Start simple echo server')
server_cmd:argument('port', 'Port to listen on'):convert(tonumber)

local whois_cmd = parser:command('whois', 'Whois lookup')
whois_cmd:argument('domain', 'Domain name to lookup')

local function parse_ports(port_string)
    local ports = {}
    
    for part in port_string:gmatch("[^,]+") do
        if part:match("(%d+)-(%d+)") then
            local start_port, end_port = part:match("(%d+)-(%d+)")
            for i = tonumber(start_port), tonumber(end_port) do
                table.insert(ports, i)
            end
        else
            table.insert(ports, tonumber(part))
        end
    end
    
    return ports
end

local function parse_headers(header_list)
    local headers = {}
    
    for _, header in ipairs(header_list) do
        local key, value = header:match("([^:]+):(.+)")
        if key and value then
            headers[utils.trim(key)] = utils.trim(value)
        end
    end
    
    return headers
end

local function main()
    logger.set_level("INFO")
    
    local args = parser:parse()
    
    if args.command == "ping" then
        for i = 1, args.count do
            local success, time_or_err = network.ping_host(args.host, args.port, args.timeout)
            
            if success then
                logger.info("Reply from %s:%d time=%.2fms", args.host, args.port, time_or_err)
            else
                logger.error("Request to %s:%d failed: %s", args.host, args.port, time_or_err)
            end
            
            if i < args.count then
                socket.sleep(1)
            end
        end
        
    elseif args.command == "scan" then
        local ports = parse_ports(args.ports)
        local open_ports, closed_ports = network.port_scan(args.host, ports, args.timeout)
        
        if #open_ports > 0 then
            print("\nOpen ports:")
            for _, port_info in ipairs(open_ports) do
                print(string.format("  %d/tcp (%.2fms)", port_info.port, port_info.response_time))
            end
        else
            print("No open ports found")
        end
        
    elseif args.command == "http" then
        local headers = parse_headers(args.header)
        local response = network.http_request(args.method, args.url, headers, args.data)
        
        if response.success then
            if args.verbose then
                print("Status: " .. response.status)
                print("Headers:")
                for k, v in pairs(response.headers) do
                    print("  " .. k .. ": " .. v)
                end
                print()
            end
            print(response.body)
        else
            logger.error("HTTP request failed: %s", response.status)
        end
        
    elseif args.command == "dns" then
        if args.reverse then
            local result = network.reverse_dns(args.hostname)
            if result.success then
                print(args.hostname .. " -> " .. result.hostname)
            else
                logger.error("Reverse DNS failed: %s", result.error)
            end
        else
            local result = network.dns_lookup(args.hostname)
            if result.success then
                print(args.hostname .. " -> " .. result.ip)
            else
                logger.error("DNS lookup failed: %s", result.error)
            end
        end
        
    elseif args.command == "trace" then
        local hops = network.trace_route(args.host, args.max_hops)
        
        print("Traceroute to " .. args.host .. ":")
        for _, hop in ipairs(hops) do
            if hop.response_time then
                print(string.format("%2d  %s  %.2fms", hop.hop, hop.host, hop.response_time))
            else
                print(string.format("%2d  %s", hop.hop, hop.host))
            end
        end
        
    elseif args.command == "server" then
        local function echo_handler(request)
            local timestamp = utils.get_timestamp()
            logger.info("Request received: %s", request or "nil")
            return "Echo: " .. (request or "nil") .. " (" .. timestamp .. ")\n"
        end
        
        network.simple_server(args.port, echo_handler)
        
    elseif args.command == "whois" then
        local result = network.whois_lookup(args.domain)
        
        if result.success then
            print(result.data)
        else
            logger.error("Whois lookup failed: %s", result.error)
        end
    end
end

if not pcall(main) then
    logger.error("An error occurred during execution")
    os.exit(1)
end