#!/usr/bin/env luajit

-- Simple hello world example demonstrating the tech stack

local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

print("=== Lua Scripts Monorepo Demo ===")
print()

-- Test basic utilities
print("1. Testing utility functions:")
local test_table1 = {a = 1, b = 2}
local test_table2 = {c = 3, b = 4}
local merged = utils.table_merge(test_table1, test_table2)

print("  Merged tables:", utils.table_to_string(merged))
print("  Current timestamp:", utils.get_timestamp())
print("  Format 1024 bytes:", utils.format_bytes(1024))
print()

-- Test logger
print("2. Testing logger:")
logger.set_level("INFO")
logger.info("This is an info message")
logger.warn("This is a warning message")
logger.error("This is an error message")
print()

-- Test JSON processing
print("3. Testing JSON processing:")
local json = require('libs.external.json')
local test_data = {
    name = "Test Project",
    version = "1.0.0",
    dependencies = {"luajit", "argparse", "luafilesystem"}
}

local json_string = json.encode(test_data)
print("  JSON encoded:", json_string)

local decoded = json.decode(json_string)
print("  Decoded name:", decoded.name)
print()

-- Test lume utilities
print("4. Testing lume utilities:")
local lume = require('libs.external.lume')

local numbers = {1, 2, 3, 4, 5}
local doubled = lume.map(numbers, function(x) return x * 2 end)
print("  Doubled numbers:", table.concat(doubled, ", "))

local even_numbers = lume.filter(numbers, function(x) return x % 2 == 0 end)
print("  Even numbers:", table.concat(even_numbers, ", "))
print()

-- Test file system operations
print("5. Testing file system:")
local lfs = require('lfs')

print("  Current directory:", lfs.currentdir())
local temp_dir = "/tmp/lua-test-" .. os.time()
lfs.mkdir(temp_dir)

local temp_file = temp_dir .. "/test.txt"
local file = io.open(temp_file, "w")
file:write("Hello from Lua!")
file:close()

if utils.file_exists(temp_file) then
    print("  Created test file successfully")
    local content = io.open(temp_file, "r"):read("*a")
    print("  File content:", content)
end

-- Cleanup
os.remove(temp_file)
lfs.rmdir(temp_dir)
print("  Cleaned up test files")
print()

print("✓ All tests completed successfully!")
print("The Lua Scripts Monorepo is ready to use.")

-- Function to add to utils for demonstration
function utils.table_to_string(t)
    local parts = {}
    for k, v in pairs(t) do
        table.insert(parts, k .. "=" .. tostring(v))
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end