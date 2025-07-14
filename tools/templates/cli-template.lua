#!/usr/bin/env luajit

local argparse = require('argparse')
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

local CLI_NAME = {}

-- Add your CLI functions here
function CLI_NAME.main_function()
    logger.info("CLI_NAME is running...")
    -- Implementation goes here
end

-- CLI interface
local parser = argparse('CLI_NAME', 'Description of your CLI tool')

parser:argument('input', 'Input parameter')
parser:option('-o --output', 'Output file')
parser:flag('-v --verbose', 'Verbose output')
parser:flag('-q --quiet', 'Quiet mode')

local function main()
    local args = parser:parse()
    
    -- Set logging level based on flags
    if args.quiet then
        logger.set_level("ERROR")
    elseif args.verbose then
        logger.set_level("DEBUG")
    else
        logger.set_level("INFO")
    end
    
    logger.info("Starting CLI_NAME with input: %s", args.input)
    
    -- Call your main function
    CLI_NAME.main_function()
    
    if args.output then
        logger.info("Output will be saved to: %s", args.output)
    end
    
    logger.info("CLI_NAME completed successfully")
end

if not pcall(main) then
    logger.error("An error occurred during execution")
    os.exit(1)
end