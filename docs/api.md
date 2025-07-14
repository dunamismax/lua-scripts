# API Documentation

## Shared Libraries

### libs.shared.utils

Utility functions for common tasks.

#### Functions

##### `table_merge(t1, t2)`
Merges two tables, with values from `t2` overriding `t1`.
```lua
local merged = utils.table_merge({a=1, b=2}, {b=3, c=4})
-- Result: {a=1, b=3, c=4}
```

##### `string_split(str, delimiter)`
Splits a string by delimiter.
```lua
local parts = utils.string_split("a,b,c", ",")
-- Result: {"a", "b", "c"}
```

##### `file_exists(path)`
Checks if a file exists.
```lua
if utils.file_exists("/path/to/file") then
    print("File exists")
end
```

##### `deep_copy(obj)`
Creates a deep copy of a table.
```lua
local copy = utils.deep_copy(original_table)
```

##### `trim(str)`
Removes whitespace from both ends of a string.
```lua
local clean = utils.trim("  hello world  ")
-- Result: "hello world"
```

##### `get_timestamp()`
Returns current timestamp as string.
```lua
local now = utils.get_timestamp()
-- Result: "2024-01-15 14:30:25"
```

##### `format_bytes(bytes)`
Formats byte count in human-readable format.
```lua
local size = utils.format_bytes(1024)
-- Result: "1.00 KB"
```

##### `escape_shell_arg(arg)`
Escapes argument for safe shell execution.
```lua
local safe = utils.escape_shell_arg("file with spaces.txt")
-- Result: "'file with spaces.txt'"
```

##### `map(tbl, func)`
Maps function over array.
```lua
local doubled = utils.map({1,2,3}, function(x) return x * 2 end)
-- Result: {2, 4, 6}
```

##### `filter(tbl, predicate)`
Filters array by predicate function.
```lua
local evens = utils.filter({1,2,3,4}, function(x) return x % 2 == 0 end)
-- Result: {2, 4}
```

### libs.shared.logger

Logging functionality with levels and colors.

#### Functions

##### `set_level(level)`
Sets minimum log level. Accepts "DEBUG", "INFO", "WARN", "ERROR" or numeric values.
```lua
logger.set_level("INFO")
logger.set_level(2) -- Same as "INFO"
```

##### `set_file(path)`
Sets log file path. Pass `nil` to disable file logging.
```lua
logger.set_file("/var/log/myapp.log")
logger.set_file(nil) -- Disable file logging
```

##### `set_colors(enabled)`
Enables or disables colored output.
```lua
logger.set_colors(false) -- Disable colors
```

##### `debug(message, ...)`
Logs debug message with optional formatting.
```lua
logger.debug("Processing item %d of %d", current, total)
```

##### `info(message, ...)`
Logs info message.
```lua
logger.info("Application started")
```

##### `warn(message, ...)`
Logs warning message.
```lua
logger.warn("Deprecated function used: %s", func_name)
```

##### `error(message, ...)`
Logs error message.
```lua
logger.error("Failed to connect: %s", error_msg)
```

##### `close()`
Closes log file if open.
```lua
logger.close()
```

### libs.shared.config

Configuration management with JSON storage.

#### Functions

##### `load(path, defaults)`
Loads configuration from file with defaults.
```lua
local config = config.load("/path/to/config.json", {
    timeout = 30,
    debug = false
})
```

##### `save(path, data)`
Saves configuration to JSON file.
```lua
config.save("/path/to/config.json", {
    timeout = 60,
    debug = true
})
```

##### `get_user_config_dir()`
Returns user-specific config directory.
```lua
local dir = config.get_user_config_dir()
-- Result: "/home/user/.config/lua-scripts"
```

##### `get_app_config_path(app_name)`
Returns path for app-specific config file.
```lua
local path = config.get_app_config_path("myapp")
-- Result: "/home/user/.config/lua-scripts/myapp.json"
```

## External Libraries

### libs.external.json

JSON encoding/decoding library.

#### Functions

##### `encode(value)`
Encodes Lua value as JSON string.
```lua
local json_str = json.encode({name = "John", age = 30})
```

##### `decode(json_string)`
Decodes JSON string to Lua value.
```lua
local data = json.decode('{"name":"John","age":30}')
```

### libs.external.lume

General-purpose utility library.

#### Key Functions

##### `map(t, fn)`
Returns new table with `fn` applied to each value.
```lua
local doubled = lume.map({1,2,3}, function(x) return x * 2 end)
```

##### `filter(t, fn)`
Returns new table with values where `fn` returns true.
```lua
local evens = lume.filter({1,2,3,4}, function(x) return x % 2 == 0 end)
```

##### `reduce(t, fn, first)`
Reduces table to single value using function.
```lua
local sum = lume.reduce({1,2,3,4}, function(a,b) return a + b end, 0)
```

##### `find(t, value)`
Returns first index where value is found.
```lua
local index = lume.find({"a", "b", "c"}, "b") -- Returns 2
```

##### `match(t, fn)`
Returns first value where function returns true.
```lua
local first_even = lume.match({1,3,4,5}, function(x) return x % 2 == 0 end)
```

##### `keys(t)`
Returns array of table keys.
```lua
local keys = lume.keys({a=1, b=2, c=3}) -- Returns {"a", "b", "c"}
```

##### `clone(t)`
Creates shallow copy of table.
```lua
local copy = lume.clone(original_table)
```

##### `merge(...)`
Merges multiple tables into new table.
```lua
local merged = lume.merge({a=1}, {b=2}, {c=3})
```

For complete lume documentation, see: https://github.com/rxi/lume

## System Dependencies

### LuaFileSystem (lfs)

File system operations.

#### Key Functions

##### `dir(path)`
Iterator over directory entries.
```lua
for file in lfs.dir("/path") do
    if file ~= "." and file ~= ".." then
        print(file)
    end
end
```

##### `attributes(path, attribute)`
Gets file attributes.
```lua
local attr = lfs.attributes("/path/to/file")
print("Size:", attr.size)
print("Modified:", os.date("%c", attr.modification))
```

##### `mkdir(path)`
Creates directory.
```lua
lfs.mkdir("/new/directory")
```

##### `rmdir(path)`
Removes empty directory.
```lua
lfs.rmdir("/empty/directory")
```

### LuaSocket

Network operations.

#### Key Modules

##### `socket.tcp()`
Creates TCP socket.
```lua
local tcp = socket.tcp()
tcp:connect("example.com", 80)
tcp:send("GET / HTTP/1.0\r\n\r\n")
local response = tcp:receive()
tcp:close()
```

##### `socket.dns`
DNS operations.
```lua
local ip = socket.dns.toip("example.com")
local hostname = socket.dns.tohostname("8.8.8.8")
```

##### `socket.http`
HTTP client.
```lua
local http = require('socket.http')
local body, status = http.request("http://example.com")
```

### argparse

Command-line argument parsing.

#### Basic Usage

```lua
local argparse = require('argparse')
local parser = argparse('script', 'Description')

parser:argument('input', 'Input file')
parser:option('-o --output', 'Output file')
parser:flag('-v --verbose', 'Verbose output')

local args = parser:parse()
```

For complete documentation, see: https://github.com/mpeterv/argparse