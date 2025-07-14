#!/usr/bin/env luajit

local lfs = require('lfs')
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

local SCRIPT_NAME = {}

-- Add your script functions here
function SCRIPT_NAME.process_data(input_data)
    logger.info("Processing data...")
    
    -- Your processing logic here
    local result = input_data
    
    return result
end

function SCRIPT_NAME.main(input_path, output_path, options)
    options = options or {}
    
    logger.info("Starting SCRIPT_NAME")
    logger.info("Input: %s", input_path or "stdin")
    logger.info("Output: %s", output_path or "stdout")
    
    -- Validate input
    if input_path and not utils.file_exists(input_path) then
        error("Input file does not exist: " .. input_path)
    end
    
    -- Read input
    local input_data
    if input_path then
        local file = io.open(input_path, "r")
        input_data = file:read("*a")
        file:close()
    else
        input_data = io.read("*a")
    end
    
    -- Process data
    local result = SCRIPT_NAME.process_data(input_data)
    
    -- Write output
    if output_path then
        local file = io.open(output_path, "w")
        file:write(result)
        file:close()
        logger.info("Result written to: %s", output_path)
    else
        print(result)
    end
    
    logger.info("SCRIPT_NAME completed successfully")
end

-- CLI interface (if script is run directly)
local function main()
    if #arg < 1 then
        print("Usage: luajit SCRIPT_NAME.lua <input> [output] [options]")
        print("Options:")
        print("  --verbose    Verbose output")
        print("  --quiet      Minimal output")
        os.exit(1)
    end
    
    local input_path = arg[1]
    local output_path = arg[2]
    local options = {}
    
    -- Parse simple options
    for i = 3, #arg do
        if arg[i] == "--verbose" then
            logger.set_level("DEBUG")
        elseif arg[i] == "--quiet" then
            logger.set_level("ERROR")
        end
    end
    
    if not options.quiet then
        logger.set_level("INFO")
    end
    
    local success, error_msg = pcall(SCRIPT_NAME.main, input_path, output_path, options)
    
    if not success then
        logger.error("Script failed: %s", error_msg)
        os.exit(1)
    end
end

-- Only run main if script is executed directly
if arg and #arg > 0 then
    main()
end

return SCRIPT_NAME