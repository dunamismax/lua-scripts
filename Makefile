# Lua Scripts Monorepo Makefile

.PHONY: install test clean format lint help run-examples

# Default target
all: install test

# Install dependencies and setup environment
install:
	@echo "Installing Lua Scripts Monorepo..."
	luajit install.lua
	@echo "Installation complete!"

# Run all tests
test:
	@echo "Running tests..."
	luajit examples/hello.lua
	@echo "Testing CLI tools..."
	@luajit apps/cli/file-manager.lua list . > /dev/null && echo "✓ file-manager works"
	@luajit apps/cli/system-info.lua --cpu > /dev/null && echo "✓ system-info works"
	@echo "Basic tests passed!"

# Clean temporary files and logs
clean:
	@echo "Cleaning up..."
	find . -name "*.log" -delete
	find . -name "*.tmp" -delete
	find /tmp -name "lua-test-*" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "Cleanup complete!"

# Format Lua files (requires lua-format if available)
format:
	@if command -v lua-format >/dev/null 2>&1; then \
		echo "Formatting Lua files..."; \
		find . -name "*.lua" -not -path "./libs/external/*" -exec lua-format -i {} \; ; \
		echo "Formatting complete!"; \
	else \
		echo "lua-format not found. Skipping formatting."; \
		echo "Install with: luarocks install --server=https://luarocks.org/dev luaformatter"; \
	fi

# Lint Lua files (requires luacheck if available)
lint:
	@if command -v luacheck >/dev/null 2>&1; then \
		echo "Linting Lua files..."; \
		luacheck . --exclude-files libs/external/ --ignore 631; \
		echo "Linting complete!"; \
	else \
		echo "luacheck not found. Skipping linting."; \
		echo "Install with: luarocks install luacheck"; \
	fi

# Run example applications
run-examples:
	@echo "Running examples..."
	@echo "\n=== Hello World Example ==="
	luajit examples/hello.lua
	@echo "\n=== File Manager Demo ==="
	luajit apps/cli/file-manager.lua list . | head -10
	@echo "\n=== System Info Demo ==="
	luajit apps/cli/system-info.lua --cpu --memory
	@echo "\n=== JSON Processor Demo ==="
	echo '{"test": "value", "number": 42}' | luajit -e 'local json=require("libs.external.json"); local data=json.decode(io.read("*a")); print("Parsed:", data.test, data.number)'

# Development setup
dev-setup: install
	@echo "Setting up development environment..."
	@if ! command -v luacheck >/dev/null 2>&1; then \
		echo "Installing luacheck..."; \
		luarocks install luacheck; \
	fi
	@if ! command -v lua-format >/dev/null 2>&1; then \
		echo "Installing lua-format..."; \
		luarocks install --server=https://luarocks.org/dev luaformatter; \
	fi
	@echo "Development setup complete!"

# Create new CLI application template
new-cli:
	@read -p "Enter CLI app name: " name; \
	if [ -z "$$name" ]; then \
		echo "Name cannot be empty"; \
		exit 1; \
	fi; \
	cp tools/templates/cli-template.lua apps/cli/$$name.lua; \
	sed -i.bak "s/CLI_NAME/$$name/g" apps/cli/$$name.lua; \
	rm apps/cli/$$name.lua.bak; \
	chmod +x apps/cli/$$name.lua; \
	echo "Created apps/cli/$$name.lua"

# Create new script template
new-script:
	@read -p "Enter script name: " name; \
	if [ -z "$$name" ]; then \
		echo "Name cannot be empty"; \
		exit 1; \
	fi; \
	cp tools/templates/script-template.lua apps/scripts/$$name.lua; \
	sed -i.bak "s/SCRIPT_NAME/$$name/g" apps/scripts/$$name.lua; \
	rm apps/scripts/$$name.lua.bak; \
	chmod +x apps/scripts/$$name.lua; \
	echo "Created apps/scripts/$$name.lua"

# Package for distribution
package:
	@echo "Creating distribution package..."
	tar -czf lua-scripts-$(shell date +%Y%m%d).tar.gz \
		--exclude='.git' \
		--exclude='*.log' \
		--exclude='*.tmp' \
		--exclude='lua-scripts-*.tar.gz' \
		.
	@echo "Package created: lua-scripts-$(shell date +%Y%m%d).tar.gz"

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	@command -v luajit >/dev/null 2>&1 || (echo "✗ LuaJIT not found" && exit 1)
	@echo "✓ LuaJIT found: $$(luajit -v 2>&1 | head -1)"
	@command -v luarocks >/dev/null 2>&1 && echo "✓ LuaRocks found: $$(luarocks --version | head -1)" || echo "⚠ LuaRocks not found (optional)"
	@luajit -e "require('lfs')" 2>/dev/null && echo "✓ LuaFileSystem available" || echo "✗ LuaFileSystem missing"
	@luajit -e "require('socket')" 2>/dev/null && echo "✓ LuaSocket available" || echo "✗ LuaSocket missing"
	@luajit -e "require('argparse')" 2>/dev/null && echo "✓ argparse available" || echo "✗ argparse missing"

# Show help
help:
	@echo "Lua Scripts Monorepo - Available Commands:"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make install     - Install dependencies and setup environment"
	@echo "  make dev-setup   - Install + development tools (luacheck, lua-format)"
	@echo "  make check-deps  - Check if all dependencies are available"
	@echo ""
	@echo "Testing & Quality:"
	@echo "  make test        - Run basic tests"
	@echo "  make lint        - Lint Lua files (requires luacheck)"
	@echo "  make format      - Format Lua files (requires lua-format)"
	@echo ""
	@echo "Development:"
	@echo "  make new-cli     - Create new CLI application from template"
	@echo "  make new-script  - Create new script from template"
	@echo "  make run-examples- Run example applications"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean       - Clean temporary files and logs"
	@echo "  make package     - Create distribution package"
	@echo ""
	@echo "Examples:"
	@echo "  luajit apps/cli/file-manager.lua list ."
	@echo "  luajit apps/cli/system-info.lua --cpu --memory"
	@echo "  luajit apps/cli/json-processor.lua query data.json 'users.0.name'"
	@echo "  luajit apps/cli/network-tools.lua ping google.com 80"