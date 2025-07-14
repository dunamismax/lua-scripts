# Getting Started

This guide will help you set up and start using the Lua Scripts Monorepo.

## Prerequisites

1. **LuaJIT** - High-performance Lua interpreter
   ```bash
   # macOS (Homebrew)
   brew install luajit
   
   # Ubuntu/Debian
   sudo apt-get install luajit
   
   # Arch Linux
   sudo pacman -S luajit
   ```

2. **LuaRocks** - Lua package manager (optional but recommended)
   ```bash
   # macOS (Homebrew)
   brew install luarocks
   
   # Ubuntu/Debian
   sudo apt-get install luarocks
   
   # Or install via LuaJIT
   wget https://luarocks.org/releases/luarocks-3.9.2.tar.gz
   tar zxpf luarocks-3.9.2.tar.gz
   cd luarocks-3.9.2
   ./configure && make && sudo make install
   ```

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/lua-scripts.git
   cd lua-scripts
   ```

2. **Run the installation script:**
   ```bash
   luajit install.lua
   ```

   This will:
   - Verify LuaJIT installation
   - Install required dependencies via LuaRocks
   - Download external libraries (json.lua, lume.lua)

3. **Test the installation:**
   ```bash
   luajit examples/hello.lua
   ```

## Quick Start

### Running Applications

All applications are executable Lua scripts:

```bash
# File management CLI
luajit apps/cli/file-manager.lua list /home/user

# System information tool
luajit apps/cli/system-info.lua --cpu --memory

# JSON processor
luajit apps/cli/json-processor.lua query data.json "users.0.name"

# Network tools
luajit apps/cli/network-tools.lua ping google.com 80

# Task manager TUI
luajit apps/tui/task-manager.lua

# Directory synchronization
luajit apps/scripts/directory-sync.lua /source /destination --dry-run

# Log analyzer
luajit apps/scripts/log-analyzer.lua /var/log/nginx/access.log --format nginx
```

### Using Shared Libraries

```lua
#!/usr/bin/env luajit

-- Import shared utilities
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')
local config = require('libs.shared.config')

-- Import external libraries
local json = require('libs.external.json')
local lume = require('libs.external.lume')

-- Your script logic here
logger.info("Script started")
local data = {name = "test", value = 42}
print(json.encode(data))
```

## Directory Structure

```
lua-scripts/
├── apps/                 # Complete applications
│   ├── cli/             # Command-line tools
│   │   ├── file-manager.lua
│   │   ├── system-info.lua
│   │   ├── json-processor.lua
│   │   └── network-tools.lua
│   ├── tui/             # Terminal UI applications
│   │   └── task-manager.lua
│   └── scripts/         # Utility scripts
│       ├── directory-sync.lua
│       └── log-analyzer.lua
├── libs/                # Libraries and modules
│   ├── shared/          # Custom shared libraries
│   │   ├── utils.lua
│   │   ├── config.lua
│   │   └── logger.lua
│   └── external/        # External dependencies
│       ├── json.lua
│       └── lume.lua
├── examples/            # Example code
│   └── hello.lua
├── docs/               # Documentation
├── tests/              # Test suites
└── tools/              # Development tools
```

## Configuration

Applications can store configuration in:
- `~/.config/lua-scripts/` (Linux/macOS)
- `%USERPROFILE%\.config\lua-scripts\` (Windows)

Example configuration usage:
```lua
local config = require('libs.shared.config')

-- Load config with defaults
local app_config = config.load(config.get_app_config_path("myapp"), {
    debug = false,
    timeout = 30
})

-- Save config
app_config.last_run = os.time()
config.save(config.get_app_config_path("myapp"), app_config)
```

## Next Steps

- Explore the [API Documentation](api.md)
- Check out [Example Projects](examples.md)
- Learn about [Best Practices](best-practices.md)
- See [Contributing Guidelines](../CONTRIBUTING.md)