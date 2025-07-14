#!/usr/bin/env luajit

local function execute_command(cmd)
    print("Executing: " .. cmd)
    local success = os.execute(cmd)
    if not success then
        error("Failed to execute: " .. cmd)
    end
end

local function check_luajit()
    local handle = io.popen("luajit -v 2>&1")
    local result = handle:read("*a")
    handle:close()
    
    if result:match("LuaJIT") then
        print("✓ LuaJIT is installed")
        return true
    else
        print("✗ LuaJIT not found. Please install LuaJIT first.")
        return false
    end
end

local function install_dependencies()
    print("Installing Lua dependencies...")
    
    local deps = {
        "luafilesystem",
        "luasocket", 
        "argparse",
        "lua-cliargs"
    }
    
    for _, dep in ipairs(deps) do
        print("Installing " .. dep .. "...")
        execute_command("luarocks install " .. dep)
    end
end

local function setup_external_libs()
    print("Setting up external libraries...")
    
    os.execute("mkdir -p libs/external")
    
    local function download_file(url, path)
        execute_command("curl -L -o " .. path .. " " .. url)
    end
    
    download_file(
        "https://raw.githubusercontent.com/rxi/json.lua/master/json.lua",
        "libs/external/json.lua"
    )
    
    download_file(
        "https://raw.githubusercontent.com/rxi/lume/master/lume.lua", 
        "libs/external/lume.lua"
    )
    
    print("✓ External libraries downloaded")
end

local function main()
    print("=== Lua Scripts Monorepo Setup ===")
    
    if not check_luajit() then
        os.exit(1)
    end
    
    install_dependencies()
    setup_external_libs()
    
    print("\n✓ Setup complete!")
    print("Run 'luajit examples/hello.lua' to test the installation.")
end

main()