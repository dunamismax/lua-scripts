#!/usr/bin/env luajit

local argparse = require('argparse')
local lfs = require('lfs')
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

local parser = argparse('file-manager', 'Advanced file management CLI tool')

parser:command_target("command")

local list_cmd = parser:command('list ls', 'List directory contents')
list_cmd:argument('path', 'Directory path'):default('.')
list_cmd:flag('-l --long', 'Long format listing')
list_cmd:flag('-a --all', 'Show hidden files')
list_cmd:flag('-h --human', 'Human readable sizes')

local copy_cmd = parser:command('copy cp', 'Copy files or directories')
copy_cmd:argument('source', 'Source path')
copy_cmd:argument('dest', 'Destination path')
copy_cmd:flag('-r --recursive', 'Copy directories recursively')
copy_cmd:flag('-v --verbose', 'Verbose output')

local move_cmd = parser:command('move mv', 'Move/rename files or directories')
move_cmd:argument('source', 'Source path')
move_cmd:argument('dest', 'Destination path')
move_cmd:flag('-v --verbose', 'Verbose output')

local delete_cmd = parser:command('delete rm', 'Delete files or directories')
delete_cmd:argument('path', 'Path to delete')
delete_cmd:flag('-r --recursive', 'Delete directories recursively')
delete_cmd:flag('-f --force', 'Force deletion without confirmation')

local search_cmd = parser:command('search find', 'Search for files')
search_cmd:argument('pattern', 'Search pattern (glob)')
search_cmd:argument('path', 'Search path'):default('.')
search_cmd:flag('-i --ignore-case', 'Case insensitive search')

local function format_permissions(mode)
    local perms = {'---', '--x', '-w-', '-wx', 'r--', 'r-x', 'rw-', 'rwx'}
    local result = ''
    
    if lfs.attributes(nil, 'mode') == 'directory' then
        result = 'd'
    else
        result = '-'
    end
    
    for i = 6, 0, -3 do
        local perm_index = bit.band(bit.rshift(mode, i), 7) + 1
        result = result .. perms[perm_index]
    end
    
    return result
end

local function list_directory(path, args)
    logger.info("Listing directory: %s", path)
    
    local files = {}
    
    for file in lfs.dir(path) do
        if args.all or not file:match('^%.') then
            local full_path = path .. '/' .. file
            local attr = lfs.attributes(full_path)
            
            if attr then
                table.insert(files, {
                    name = file,
                    path = full_path,
                    size = attr.size,
                    mode = attr.mode,
                    permissions = attr.permissions,
                    modification = attr.modification
                })
            end
        end
    end
    
    table.sort(files, function(a, b) return a.name < b.name end)
    
    for _, file in ipairs(files) do
        if args.long then
            local date = os.date("%Y-%m-%d %H:%M", file.modification)
            local size_str = args.human and utils.format_bytes(file.size) or tostring(file.size)
            local type_char = file.mode == 'directory' and 'd' or '-'
            
            print(string.format("%s %8s %s %s", 
                type_char, size_str, date, file.name))
        else
            local color = file.mode == 'directory' and '\27[34m' or '\27[0m'
            print(color .. file.name .. '\27[0m')
        end
    end
end

local function copy_file(source, dest, args)
    logger.info("Copying %s to %s", source, dest)
    
    local source_attr = lfs.attributes(source)
    if not source_attr then
        logger.error("Source does not exist: %s", source)
        return false
    end
    
    if source_attr.mode == 'directory' then
        if not args.recursive then
            logger.error("Use -r to copy directories")
            return false
        end
        
        lfs.mkdir(dest)
        for file in lfs.dir(source) do
            if file ~= '.' and file ~= '..' then
                local src_file = source .. '/' .. file
                local dst_file = dest .. '/' .. file
                copy_file(src_file, dst_file, args)
            end
        end
    else
        local src_file = io.open(source, 'rb')
        local dst_file = io.open(dest, 'wb')
        
        if not src_file then
            logger.error("Cannot read source: %s", source)
            return false
        end
        
        if not dst_file then
            logger.error("Cannot write destination: %s", dest)
            src_file:close()
            return false
        end
        
        local data = src_file:read('*a')
        dst_file:write(data)
        src_file:close()
        dst_file:close()
        
        if args.verbose then
            logger.info("Copied: %s", source)
        end
    end
    
    return true
end

local function search_files(pattern, path, args)
    logger.info("Searching for '%s' in %s", pattern, path)
    
    local function match_pattern(filename)
        if args.ignore_case then
            return filename:lower():match(pattern:lower())
        else
            return filename:match(pattern)
        end
    end
    
    local function search_recursive(dir)
        for file in lfs.dir(dir) do
            if file ~= '.' and file ~= '..' then
                local full_path = dir .. '/' .. file
                local attr = lfs.attributes(full_path)
                
                if attr then
                    if match_pattern(file) then
                        print(full_path)
                    end
                    
                    if attr.mode == 'directory' then
                        search_recursive(full_path)
                    end
                end
            end
        end
    end
    
    search_recursive(path)
end

local function main()
    logger.set_level("INFO")
    
    local args = parser:parse()
    
    if args.command == 'list' then
        list_directory(args.path, args)
    elseif args.command == 'copy' then
        copy_file(args.source, args.dest, args)
    elseif args.command == 'move' then
        local success = copy_file(args.source, args.dest, args)
        if success then
            os.remove(args.source)
            if args.verbose then
                logger.info("Moved: %s -> %s", args.source, args.dest)
            end
        end
    elseif args.command == 'delete' then
        if not args.force then
            io.write("Delete " .. args.path .. "? (y/N): ")
            local response = io.read()
            if response:lower() ~= 'y' and response:lower() ~= 'yes' then
                logger.info("Deletion cancelled")
                return
            end
        end
        
        local success = os.remove(args.path)
        if success then
            logger.info("Deleted: %s", args.path)
        else
            logger.error("Failed to delete: %s", args.path)
        end
    elseif args.command == 'search' then
        search_files(args.pattern, args.path, args)
    end
end

if not pcall(main) then
    logger.error("An error occurred during execution")
    os.exit(1)
end