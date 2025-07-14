# Contributing to Lua Scripts Monorepo

Thank you for your interest in contributing! This document provides guidelines for contributing to the Lua Scripts Monorepo.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/lua-scripts.git`
3. Set up the development environment: `make dev-setup`
4. Create a feature branch: `git checkout -b feature/your-feature-name`

## Development Guidelines

### Code Style

- Use 4 spaces for indentation (no tabs)
- Follow Lua naming conventions:
  - `snake_case` for functions and variables
  - `PascalCase` for modules/classes
  - `UPPER_CASE` for constants
- Keep lines under 100 characters when possible
- Use descriptive variable and function names

### File Organization

- **CLI applications**: Place in `apps/cli/`
- **TUI applications**: Place in `apps/tui/`
- **Utility scripts**: Place in `apps/scripts/`
- **Shared libraries**: Place in `libs/shared/`
- **Examples**: Place in `examples/`
- **Documentation**: Place in `docs/`

### Code Quality

1. **Run tests**: `make test`
2. **Lint code**: `make lint` (requires luacheck)
3. **Format code**: `make format` (requires lua-format)

### Adding New Applications

#### CLI Applications

1. Use the template: `make new-cli`
2. Follow the argparse pattern for argument parsing
3. Include proper error handling and logging
4. Add usage examples in comments

#### Scripts

1. Use the template: `make new-script`
2. Make scripts both importable and executable
3. Support standard input/output when appropriate
4. Include comprehensive error checking

#### Shared Libraries

1. Place in `libs/shared/`
2. Follow the existing module pattern
3. Include comprehensive documentation
4. Add unit tests if applicable

### Documentation

- Update `README.md` if adding major features
- Add API documentation to `docs/api.md`
- Include usage examples
- Document any new dependencies

## Commit Guidelines

### Commit Message Format

```
type(scope): description

Optional body explaining the change in detail.

Optional footer with breaking change info.
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

### Examples

```
feat(cli): add network monitoring tool

Add new CLI tool for monitoring network connections and bandwidth.
Includes ping, traceroute, and speed test functionality.

feat(utils): add file watching utilities

Add file system watching utilities to shared library.
Supports polling and event-based watching.

fix(logger): resolve timestamp formatting issue

Fix issue where timestamps were not displaying correctly
in UTC timezone.

docs(api): update configuration documentation

Add examples for new configuration options and clarify
the config file format.
```

## Testing

### Running Tests

```bash
# Run basic tests
make test

# Run specific application
luajit apps/cli/file-manager.lua list .

# Test with different inputs
echo '{"test": true}' | luajit apps/cli/json-processor.lua query - "test"
```

### Adding Tests

- Add test files to `tests/` directory
- Use descriptive test names
- Test both success and error cases
- Include edge cases

## Dependencies

### Adding New Dependencies

1. Prefer pure Lua libraries when possible
2. Check that dependencies work with LuaJIT
3. Update `install.lua` if needed
4. Update `luarocks.lua` configuration
5. Document in `README.md` and getting started guide

### Allowed Dependencies

- **Core**: LuaJIT (required)
- **System**: LuaFileSystem, LuaSocket
- **CLI**: argparse, lua_cliargs
- **TUI**: LTUI
- **Utilities**: Pure Lua libraries only

## Review Process

1. Ensure all tests pass
2. Update documentation as needed
3. Submit pull request with clear description
4. Address any review feedback
5. Maintain backwards compatibility when possible

## Code Examples

### CLI Application Structure

```lua
#!/usr/bin/env luajit

local argparse = require('argparse')
local utils = require('libs.shared.utils')
local logger = require('libs.shared.logger')

local app = {}

function app.main_logic(args)
    -- Implementation here
end

local parser = argparse('myapp', 'Description')
-- Add arguments...

local function main()
    local args = parser:parse()
    logger.set_level(args.verbose and "DEBUG" or "INFO")
    app.main_logic(args)
end

if not pcall(main) then
    logger.error("Application failed")
    os.exit(1)
end
```

### Shared Library Structure

```lua
local mylib = {}

function mylib.public_function(param)
    return mylib._private_helper(param)
end

function mylib._private_helper(param)
    -- Private implementation
    return result
end

return mylib
```

## Questions?

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Join discussions in pull requests
- Read the documentation in `docs/`

Thank you for contributing!