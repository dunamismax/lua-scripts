local config = {}

local function load_json_config(path)
    local json = require('libs.external.json')
    local file = io.open(path, "r")
    if not file then
        return {}
    end
    
    local content = file:read("*a")
    file:close()
    
    local success, result = pcall(json.decode, content)
    if success then
        return result
    else
        error("Invalid JSON in config file: " .. path)
    end
end

local function save_json_config(path, data)
    local json = require('libs.external.json')
    local file = io.open(path, "w")
    if not file then
        error("Cannot write to config file: " .. path)
    end
    
    file:write(json.encode(data))
    file:close()
end

function config.load(path, defaults)
    defaults = defaults or {}
    local utils = require('libs.shared.utils')
    
    if utils.file_exists(path) then
        local loaded = load_json_config(path)
        return utils.table_merge(defaults, loaded)
    else
        return defaults
    end
end

function config.save(path, data)
    save_json_config(path, data)
end

function config.get_user_config_dir()
    local home = os.getenv("HOME") or os.getenv("USERPROFILE")
    if not home then
        error("Cannot determine user home directory")
    end
    
    local config_dir
    if os.getenv("XDG_CONFIG_HOME") then
        config_dir = os.getenv("XDG_CONFIG_HOME") .. "/lua-scripts"
    else
        config_dir = home .. "/.config/lua-scripts"
    end
    
    os.execute("mkdir -p " .. config_dir)
    return config_dir
end

function config.get_app_config_path(app_name)
    return config.get_user_config_dir() .. "/" .. app_name .. ".json"
end

return config