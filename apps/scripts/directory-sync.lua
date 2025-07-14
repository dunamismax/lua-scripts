#!/usr/bin/env luajit

local lfs = require('lfs')
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

local sync = {}

function sync.get_file_hash(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    
    local content = file:read("*a")
    file:close()
    
    -- Simple hash function (in production, use a proper hash library)
    local hash = 0
    for i = 1, #content do
        hash = (hash * 31 + content:byte(i)) % 2^32
    end
    
    return tostring(hash)
end

function sync.get_directory_tree(path)
    local tree = {}
    
    local function scan_directory(dir, relative_path)
        relative_path = relative_path or ""
        
        for entry in lfs.dir(dir) do
            if entry ~= "." and entry ~= ".." then
                local full_path = dir .. "/" .. entry
                local rel_path = relative_path == "" and entry or relative_path .. "/" .. entry
                local attr = lfs.attributes(full_path)
                
                if attr then
                    if attr.mode == "directory" then
                        tree[rel_path] = {
                            type = "directory",
                            modification = attr.modification
                        }
                        scan_directory(full_path, rel_path)
                    else
                        tree[rel_path] = {
                            type = "file",
                            size = attr.size,
                            modification = attr.modification,
                            hash = sync.get_file_hash(full_path)
                        }
                    end
                end
            end
        end
    end
    
    scan_directory(path)
    return tree
end

function sync.compare_trees(source_tree, dest_tree)
    local changes = {
        new_files = {},
        modified_files = {},
        deleted_files = {},
        new_directories = {},
        deleted_directories = {}
    }
    
    -- Find new and modified files/directories
    for path, source_info in pairs(source_tree) do
        local dest_info = dest_tree[path]
        
        if not dest_info then
            if source_info.type == "file" then
                table.insert(changes.new_files, path)
            else
                table.insert(changes.new_directories, path)
            end
        elseif source_info.type == "file" and dest_info.type == "file" then
            if source_info.hash ~= dest_info.hash or 
               source_info.modification > dest_info.modification then
                table.insert(changes.modified_files, path)
            end
        end
    end
    
    -- Find deleted files/directories
    for path, dest_info in pairs(dest_tree) do
        if not source_tree[path] then
            if dest_info.type == "file" then
                table.insert(changes.deleted_files, path)
            else
                table.insert(changes.deleted_directories, path)
            end
        end
    end
    
    return changes
end

function sync.copy_file(source, dest)
    local source_file = io.open(source, "rb")
    if not source_file then
        return false, "Cannot read source file: " .. source
    end
    
    -- Ensure destination directory exists
    local dest_dir = dest:match("(.+)/[^/]+$")
    if dest_dir then
        os.execute("mkdir -p " .. utils.escape_shell_arg(dest_dir))
    end
    
    local dest_file = io.open(dest, "wb")
    if not dest_file then
        source_file:close()
        return false, "Cannot write destination file: " .. dest
    end
    
    local data = source_file:read("*a")
    dest_file:write(data)
    
    source_file:close()
    dest_file:close()
    
    -- Copy file attributes
    local attr = lfs.attributes(source)
    if attr then
        lfs.touch(dest, attr.access, attr.modification)
    end
    
    return true
end

function sync.create_directory(path)
    local success = lfs.mkdir(path)
    return success, success and nil or ("Failed to create directory: " .. path)
end

function sync.delete_file(path)
    local success = os.remove(path)
    return success, success and nil or ("Failed to delete file: " .. path)
end

function sync.delete_directory(path)
    -- Remove all contents first
    for entry in lfs.dir(path) do
        if entry ~= "." and entry ~= ".." then
            local full_path = path .. "/" .. entry
            local attr = lfs.attributes(full_path)
            
            if attr then
                if attr.mode == "directory" then
                    sync.delete_directory(full_path)
                else
                    os.remove(full_path)
                end
            end
        end
    end
    
    local success = lfs.rmdir(path)
    return success, success and nil or ("Failed to delete directory: " .. path)
end

function sync.apply_changes(source_dir, dest_dir, changes, options)
    options = options or {}
    local dry_run = options.dry_run or false
    local verbose = options.verbose or false
    
    local stats = {
        files_copied = 0,
        files_updated = 0,
        files_deleted = 0,
        directories_created = 0,
        directories_deleted = 0,
        errors = {}
    }
    
    -- Create new directories
    for _, rel_path in ipairs(changes.new_directories) do
        local dest_path = dest_dir .. "/" .. rel_path
        
        if verbose then
            logger.info("Create directory: %s", rel_path)
        end
        
        if not dry_run then
            local success, err = sync.create_directory(dest_path)
            if success then
                stats.directories_created = stats.directories_created + 1
            else
                table.insert(stats.errors, err)
            end
        else
            stats.directories_created = stats.directories_created + 1
        end
    end
    
    -- Copy new files
    for _, rel_path in ipairs(changes.new_files) do
        local source_path = source_dir .. "/" .. rel_path
        local dest_path = dest_dir .. "/" .. rel_path
        
        if verbose then
            logger.info("Copy file: %s", rel_path)
        end
        
        if not dry_run then
            local success, err = sync.copy_file(source_path, dest_path)
            if success then
                stats.files_copied = stats.files_copied + 1
            else
                table.insert(stats.errors, err)
            end
        else
            stats.files_copied = stats.files_copied + 1
        end
    end
    
    -- Update modified files
    for _, rel_path in ipairs(changes.modified_files) do
        local source_path = source_dir .. "/" .. rel_path
        local dest_path = dest_dir .. "/" .. rel_path
        
        if verbose then
            logger.info("Update file: %s", rel_path)
        end
        
        if not dry_run then
            local success, err = sync.copy_file(source_path, dest_path)
            if success then
                stats.files_updated = stats.files_updated + 1
            else
                table.insert(stats.errors, err)
            end
        else
            stats.files_updated = stats.files_updated + 1
        end
    end
    
    -- Delete files (if enabled)
    if options.delete then
        for _, rel_path in ipairs(changes.deleted_files) do
            local dest_path = dest_dir .. "/" .. rel_path
            
            if verbose then
                logger.info("Delete file: %s", rel_path)
            end
            
            if not dry_run then
                local success, err = sync.delete_file(dest_path)
                if success then
                    stats.files_deleted = stats.files_deleted + 1
                else
                    table.insert(stats.errors, err)
                end
            else
                stats.files_deleted = stats.files_deleted + 1
            end
        end
        
        -- Delete directories (if enabled)
        for _, rel_path in ipairs(changes.deleted_directories) do
            local dest_path = dest_dir .. "/" .. rel_path
            
            if verbose then
                logger.info("Delete directory: %s", rel_path)
            end
            
            if not dry_run then
                local success, err = sync.delete_directory(dest_path)
                if success then
                    stats.directories_deleted = stats.directories_deleted + 1
                else
                    table.insert(stats.errors, err)
                end
            else
                stats.directories_deleted = stats.directories_deleted + 1
            end
        end
    end
    
    return stats
end

function sync.synchronize(source_dir, dest_dir, options)
    options = options or {}
    
    logger.info("Starting synchronization: %s -> %s", source_dir, dest_dir)
    
    if not lfs.attributes(source_dir) then
        error("Source directory does not exist: " .. source_dir)
    end
    
    -- Create destination directory if it doesn't exist
    if not lfs.attributes(dest_dir) then
        local success = lfs.mkdir(dest_dir)
        if not success then
            error("Cannot create destination directory: " .. dest_dir)
        end
    end
    
    logger.info("Scanning source directory...")
    local source_tree = sync.get_directory_tree(source_dir)
    
    logger.info("Scanning destination directory...")
    local dest_tree = sync.get_directory_tree(dest_dir)
    
    logger.info("Comparing directories...")
    local changes = sync.compare_trees(source_tree, dest_tree)
    
    local total_changes = #changes.new_files + #changes.modified_files + 
                         #changes.deleted_files + #changes.new_directories + 
                         #changes.deleted_directories
    
    if total_changes == 0 then
        logger.info("No changes detected. Directories are in sync.")
        return {
            files_copied = 0,
            files_updated = 0,
            files_deleted = 0,
            directories_created = 0,
            directories_deleted = 0,
            errors = {}
        }
    end
    
    logger.info("Changes detected:")
    logger.info("  New files: %d", #changes.new_files)
    logger.info("  Modified files: %d", #changes.modified_files)
    logger.info("  New directories: %d", #changes.new_directories)
    if options.delete then
        logger.info("  Deleted files: %d", #changes.deleted_files)
        logger.info("  Deleted directories: %d", #changes.deleted_directories)
    end
    
    if options.dry_run then
        logger.info("DRY RUN - No changes will be made")
    end
    
    local stats = sync.apply_changes(source_dir, dest_dir, changes, options)
    
    logger.info("Synchronization complete:")
    logger.info("  Files copied: %d", stats.files_copied)
    logger.info("  Files updated: %d", stats.files_updated)
    logger.info("  Files deleted: %d", stats.files_deleted)
    logger.info("  Directories created: %d", stats.directories_created)
    logger.info("  Directories deleted: %d", stats.directories_deleted)
    logger.info("  Errors: %d", #stats.errors)
    
    for _, error in ipairs(stats.errors) do
        logger.error(error)
    end
    
    return stats
end

-- CLI interface
local function main()
    if #arg < 2 then
        print("Usage: luajit directory-sync.lua <source> <destination> [options]")
        print("Options:")
        print("  --dry-run     Show what would be done without making changes")
        print("  --delete      Delete files in destination that don't exist in source")
        print("  --verbose     Verbose output")
        print("  --quiet       Minimal output")
        os.exit(1)
    end
    
    local source_dir = arg[1]
    local dest_dir = arg[2]
    
    local options = {
        dry_run = false,
        delete = false,
        verbose = false,
        quiet = false
    }
    
    for i = 3, #arg do
        if arg[i] == "--dry-run" then
            options.dry_run = true
        elseif arg[i] == "--delete" then
            options.delete = true
        elseif arg[i] == "--verbose" then
            options.verbose = true
        elseif arg[i] == "--quiet" then
            options.quiet = true
        end
    end
    
    if options.quiet then
        logger.set_level("ERROR")
    elseif options.verbose then
        logger.set_level("DEBUG")
    else
        logger.set_level("INFO")
    end
    
    local success, result = pcall(sync.synchronize, source_dir, dest_dir, options)
    
    if not success then
        logger.error("Synchronization failed: %s", result)
        os.exit(1)
    end
    
    if #result.errors > 0 then
        os.exit(1)
    end
end

if arg and #arg > 0 then
    main()
end

return sync