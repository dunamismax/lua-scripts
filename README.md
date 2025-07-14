<p align="center">
  <img src="lua-new.png" alt="Lua Image" width="400" />
</p>

<p align="center">
  <a href="https://github.com/sawyer/lua-scripts">
    <img src="https://readme-typing-svg.demolab.com/?font=Fira+Code&size=24&pause=1000&color=000080&center=true&vCenter=true&width=800&lines=Lua+Scripts+Monorepo;Complete+Scripting+Development+Stack;CLI+%2B+TUI+%2B+Networking+%2B+Automation;From+System+Tools+to+Web+Services;Pure+Lua%2C+Maximum+Productivity." alt="Typing SVG" />
  </a>
</p>

<p align="center">
  <a href="https://luajit.org/"><img src="https://img.shields.io/badge/LuaJIT-2.1+-000080.svg?logo=lua" alt="LuaJIT Version"></a>
  <a href="https://github.com/mpeterv/argparse"><img src="https://img.shields.io/badge/argparse-0.7-blue.svg" alt="argparse"></a>
  <a href="https://github.com/tboox/ltui"><img src="https://img.shields.io/badge/LTUI-2.7-green.svg" alt="LTUI"></a>
  <a href="https://lunarmodules.github.io/luafilesystem/"><img src="https://img.shields.io/badge/LuaFileSystem-1.8-orange.svg" alt="LFS"></a>
  <a href="https://lunarmodules.github.io/luasocket/"><img src="https://img.shields.io/badge/LuaSocket-3.1-red.svg" alt="LuaSocket"></a>
  <a href="https://img.shields.io/github/license/sawyer/lua-scripts"><img src="https://img.shields.io/github/license/sawyer/lua-scripts" alt="License"></a>
  <a href="https://github.com/sawyer/lua-scripts/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"></a>
  <a href="https://github.com/sawyer/lua-scripts/stargazers"><img src="https://img.shields.io/github/stars/sawyer/lua-scripts" alt="GitHub Stars"></a>
</p>

---

## About This Project

A comprehensive, production-ready monorepo for modern scripting and automation using the complete Lua ecosystem. This repository demonstrates professional development workflows across CLI tools, terminal interfaces, networking applications, and system automation scripts.

**Key Features:**

- **Complete Tech Stack Coverage** - LuaJIT, argparse, LTUI, LuaFileSystem, LuaSocket, and more
- **Production-Grade Structure** - Shared libraries, utilities, and organized project templates
- **Working Demo Applications** - Fully functional examples for each application type
- **Developer-Friendly Tools** - Scripts for creating, building, and running applications
- **Comprehensive Documentation** - Guides, best practices, and API references
- **Cross-Platform Ready** - Support for Linux, macOS, Windows, and containerized environments

---

## Use This Template

This repository serves as a GitHub template, providing developers with a robust foundation for building Lua-based scripts, CLI tools, and automation systems. Rather than cloning, you can create your own repository instance with all essential infrastructure and demo applications pre-configured.

**To get started:**

1. Click the green **"Use this template"** button at the top right of this repository
2. Choose "Create a new repository"
3. Name your repository and set it to public or private
4. Click "Create repository from template"

This will create a new repository in your GitHub account with all the code, structure, and configuration files needed to start building applications immediately using the complete Lua scripting stack.

**Advantages of using the template:**

- Establishes a clean git history beginning with your initial commit
- Configures your repository as the primary origin (not a fork)
- Enables complete customization of repository name and description
- Provides full ownership and administrative control of the codebase

---

## Quick Start

### Prerequisites

- **[LuaJIT](https://luajit.org/)** - High-performance Lua interpreter
- **[LuaRocks](https://luarocks.org/)** - Lua package manager (recommended)
- **System Dependencies** - curl, git, make

### Quick Setup

```bash
# 1. Clone and enter the repository
git clone https://github.com/sawyer/lua-scripts.git
cd lua-scripts

# 2. Install dependencies
luajit install.lua

# 3. Test installation
luajit examples/hello.lua

# 4. Try the applications
luajit apps/cli/file-manager.lua list .
luajit apps/cli/system-info.lua --cpu --memory
luajit apps/cli/json-processor.lua query data.json "users.0.name"
```

---

## Architecture

### Project Structure

```
lua-scripts/
├── apps/                 # Complete applications
│   ├── cli/             # Command-line tools (file-manager, system-info, json-processor, network-tools)
│   ├── tui/             # Terminal UI apps (task-manager with LTUI concepts)
│   └── scripts/         # Utility scripts (directory-sync, log-analyzer)
├── libs/                # Libraries and modules
│   ├── shared/          # Custom shared libraries (utils, logger, config)
│   └── external/        # External dependencies (json.lua, lume.lua)
├── examples/            # Working demonstrations and tutorials
├── docs/                # Comprehensive documentation
├── tools/               # Development and build automation
└── Makefile             # Build automation and shortcuts
```

---

<details>
<summary><strong>Click to expand: Technology Stack Details</strong></summary>

Below is a comprehensive, refined technology stack for scripting and command-line application development using the Lua programming language. This stack is designed as a complete toolkit for creating powerful and portable scripts, command-line interfaces (CLIs), and text-based user interfaces (TUIs). Lua is celebrated for its simplicity, performance, and ease of integration, making this stack ideal for a wide range of projects, from simple automation scripts to complex terminal applications.

### **Core Runtime: The Foundation of Your Scripts**

The high-performance core remains the essential starting point for fast and efficient script execution.

- [**LuaJIT**](https://luajit.org/luajit.html)
  - **Role:** High-Performance Lua Interpreter
  - **Description:** A Just-In-Time (JIT) compiler and high-performance interpreter for the Lua language. It significantly boosts execution speed, which is critical for demanding scripts and applications. LuaJIT is the foundation of this stack, enabling the performance required for modern scripting.

### **Interface Development: From Simple to Interactive**

This section covers the spectrum of user interaction, from basic command-line arguments to rich, interactive terminal applications.

- [**argparse**](https://github.com/mpeterv/argparse)
  - **Role:** Feature-Rich Command-Line Parser
  - **Description:** The go-to library for creating professional CLI tools. Inspired by Python's `argparse`, it supports positional arguments, options, and sub-commands while automatically generating help and usage messages.
- [**LTUI**](https://github.com/tboox/ltui)
  - **Role:** Text-Based User Interface (TUI) Framework
  - **Description:** A cross-platform library for building sophisticated text-based interfaces with components like windows, buttons, and dialogs. It allows you to create interactive and user-friendly terminal applications that go beyond simple command-line flags.

### **Core Libraries: The Scripting Workhorse**

This expanded section provides a powerful set of libraries for handling the most common scripting tasks, from system interaction to data manipulation.

### **System & File Operations**

- [**LuaFileSystem (LFS)**](https://keplerproject.github.io/luafilesystem/manual.html)
  - **Role:** Portable Filesystem Operations
  - **Description:** An indispensable library that provides a platform-independent way to work with directories, file attributes, and paths. LFS is essential for any script that needs to create, move, or query files and directories.
- [**luaposix**](https://github.com/luaposix/luaposix)
  - **Role:** Advanced System Interaction
  - **Description:** A comprehensive binding to the POSIX API, unlocking the full power of the operating system for your scripts. It provides advanced features like process management, pipes, signals, and user/group manipulation, making it invaluable for system administration and automation.

### **Data Handling & Serialization**

- [**lua-cjson**](https://www.kyne.com.au/~mark/software/lua-cjson.php)
  - **Role:** High-Performance JSON Library
  - **Description:** A fast C-based library for encoding and decoding JSON. Its superior performance makes it the standard choice for scripts that interact heavily with web APIs or process large JSON datasets.
- [**LuaExpat**](https://matthewwild.co.uk/projects/luaexpat/)
  - **Role:** XML Parsing
  - **Description:** A lightweight and efficient SAX-based XML parser built on the standard Expat library. It's ideal for scripts that need to process XML configuration files or data feeds without the overhead of a large DOM-based parser.
- [**lyaml**](https://github.com/gvvaughan/lyaml)
  - **Role:** YAML Processing
  - **Description:** A fast YAML library that binds to the native `libyaml`. It allows for easy parsing and emission of YAML, a popular data format for configuration files in modern development and DevOps workflows.

### **Networking & Concurrency**

- [**LuaSocket**](https://lunarmodules.github.io/luasocket/introduction.html)
  - **Role:** Low-Level Networking Library
  - **Description:** The foundational library for network programming in Lua, providing direct access to TCP and UDP protocols. It's the essential building block for any script that needs to make network connections.
- [**lua-http**](https://daurnimator.github.io/lua-http/)
  - **Role:** High-Level HTTP & WebSocket Library
  - **Description:** A powerful, modern library for making HTTP requests. It simplifies interacting with web services and APIs by handling the complexities of HTTP/1.1, HTTP/2, and TLS (HTTPS), making it perfect for automation scripts.
- [**Copas**](https://keplerproject.github.io/copas/)
  - **Role:** Asynchronous Task Dispatcher
  - **Description:** A library that simplifies creating concurrent, non-blocking network scripts using Lua coroutines. It's ideal for tasks that need to handle multiple network requests or connections simultaneously without the complexity of multithreading.

### **Text Processing**

- [**LPeg**](http://www.inf.puc-rio.br/~roberto/lpeg/)
  - **Role:** Pattern-Matching Library
  - **Description:** A powerful and efficient library for pattern matching, created by Lua's lead architect. LPeg provides a formal and composable alternative to regular expressions, making it an exceptional tool for complex text parsing, log analysis, and implementing custom data formats.

### **Utility & Helpers**

- [**lume**](https://github.com/rxi/lume)
  - **Role:** General-Purpose Utility Library
  - **Description:** A collection of essential, well-tested helper functions that extends Lua's standard library. Lume provides a lightweight, focused set of tools for common tasks involving math, table manipulation, and functional programming.

### **Development, Tooling, & Quality Assurance**

A professional scripting workflow requires robust tools for managing dependencies, ensuring code quality, and distributing your work.

### **Package Management**

- [**LuaRocks**](https://luarocks.org/learn)
  - **Role:** Package Manager
  - **Description:** The premier package manager for the Lua ecosystem. LuaRocks allows you to easily find, install, and manage the libraries in this stack, streamlining project setup and dependency management.

### **Code Quality**

- [**luacheck**](https://github.com/mpeterv/luacheck)
  - **Role:** Static Analyzer & Linter
  - **Description:** A tool that analyzes your code to detect issues like unused variables and syntax errors before you run your script. Integrating a linter is a best practice for maintaining high-quality, bug-free code.
- [**busted**](https://lunarmodules.github.io/busted/)
  - **Role:** Unit Testing Framework
  - **Description:** The most popular testing framework for Lua, enabling you to write and run automated tests for your script's logic. Adopting unit testing is critical for ensuring your scripts are correct and reliable.

### **Build & Distribution**

- [**luastatic**](https://github.com/ers35/luastatic)
  - **Role:** Single-File Executable Builder
  - **Description:** A tool to bundle a Lua script and all its dependencies (both Lua and C) into a single, standalone executable. This is essential for distributing your scripts and CLI tools to users who do not have a Lua interpreter or the required libraries installed.

</details>

---

## Demo Applications

This monorepo includes multiple fully functional demo applications showcasing each technology:

### 🗂️ **File Manager CLI** (argparse + LFS)

Professional file management tool with list, copy, move, delete, and search operations. Features progress reporting, recursive operations, and human-readable output.

### 📊 **System Monitor** (CLI + JSON)

Real-time system information tool displaying CPU, memory, disk, and network statistics with JSON export capability and watch mode.

### 📝 **JSON Processor** (json.lua)

Advanced JSON manipulation tool supporting query, merge, validate, filter, and transformation operations with JSONPath-like syntax.

### 🌐 **Network Tools** (LuaSocket)

Comprehensive networking utilities including ping, port scanning, HTTP requests, DNS lookup, traceroute, and simple servers.

### ✅ **Task Manager TUI** (LTUI concepts)

Interactive terminal-based task management system with keyboard navigation, status tracking, and persistent storage.

### 🔄 **Directory Sync** (LFS + automation)

Intelligent file synchronization with hash comparison, differential updates, and dry-run capabilities for backup and deployment.

### 📋 **Log Analyzer** (parsing + analysis)

Multi-format log parsing and analysis tool supporting Apache, Nginx, and custom formats with statistics generation and real-time monitoring.

---

## Development

### Creating New Applications

```bash
# Use convenient Make targets
make new-cli     # Create new CLI application
make new-script  # Create new utility script

# Use templates directly
cp tools/templates/cli-template.lua apps/cli/my-tool.lua
cp tools/templates/script-template.lua apps/scripts/my-script.lua
```

### Development Workflow

```bash
# Development setup with linting and formatting tools
make dev-setup

# Run all tests and examples
make test

# Format and lint code
make format
make lint

# Check dependencies
make check-deps
```

### Building and Distribution

```bash
# Create distribution package
make package

# Clean temporary files
make clean

# Run specific examples
make run-examples
```

---

## Shared Libraries Usage

The monorepo provides battle-tested libraries for common scripting patterns:

```lua
-- Utility functions and data manipulation
local utils = require('libs.shared.utils')
local merged = utils.table_merge(table1, table2)
local parts = utils.string_split("a,b,c", ",")

-- Professional logging with levels and colors
local logger = require('libs.shared.logger')
logger.set_level("INFO")
logger.info("Application started: %s", app_name)
logger.error("Connection failed: %s", error_msg)

-- Configuration management with JSON storage
local config = require('libs.shared.config')
local app_config = config.load(config.get_app_config_path("myapp"), {
    timeout = 30,
    debug = false
})

-- JSON processing and data interchange
local json = require('libs.external.json')
local data = json.decode(json_string)
local formatted = json.encode(data)

-- Functional programming utilities
local lume = require('libs.external.lume')
local doubled = lume.map({1,2,3}, function(x) return x * 2 end)
local evens = lume.filter({1,2,3,4}, function(x) return x % 2 == 0 end)
```

---

## Documentation

- **[Getting Started Guide](docs/getting-started.md)** - Complete setup and first application tutorial
- **[API Documentation](docs/api.md)** - Comprehensive library and function references
- **[Best Practices](docs/best-practices.md)** - Professional development patterns and conventions
- **[Contributing Guide](CONTRIBUTING.md)** - Development workflow and contribution guidelines

---

## Support This Project

If you find this project valuable for your scripting and automation journey, consider supporting its continued development:

<p align="center">
  <a href="https://www.buymeacoffee.com/sawyer" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" />
  </a>
</p>

---

## Let's Connect

<p align="center">
  <a href="https://twitter.com/sawyer" target="_blank"><img src="https://img.shields.io/badge/Twitter-%231DA1F2.svg?&style=for-the-badge&logo=twitter&logoColor=white" alt="Twitter"></a>
  <a href="https://bsky.app/profile/sawyer.bsky.social" target="_blank"><img src="https://img.shields.io/badge/Bluesky-blue?style=for-the-badge&logo=bluesky&logoColor=white" alt="Bluesky"></a>
  <a href="https://reddit.com/user/sawyer" target="_blank"><img src="https://img.shields.io/badge/Reddit-%23FF4500.svg?&style=for-the-badge&logo=reddit&logoColor=white" alt="Reddit"></a>
  <a href="https://discord.com/users/sawyer" target="_blank"><img src="https://img.shields.io/badge/Discord-sawyer-7289DA.svg?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"></a>
</p>

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <strong>Built with Lua</strong><br>
  <sub>A comprehensive foundation for scripting and automation across all platforms</sub>
</p>
