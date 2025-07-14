local logger = {}

local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

local LEVEL_NAMES = {
    [1] = "DEBUG",
    [2] "INFO",
    [3] = "WARN", 
    [4] = "ERROR"
}

local LEVEL_COLORS = {
    [1] = "\27[36m",  -- Cyan
    [2] = "\27[32m",  -- Green  
    [3] = "\27[33m",  -- Yellow
    [4] = "\27[31m"   -- Red
}

local RESET_COLOR = "\27[0m"

local current_level = LOG_LEVELS.INFO
local log_file = nil
local use_colors = true

function logger.set_level(level)
    if type(level) == "string" then
        level = LOG_LEVELS[level:upper()]
    end
    if level then
        current_level = level
    end
end

function logger.set_file(path)
    if log_file then
        log_file:close()
    end
    
    if path then
        log_file = io.open(path, "a")
        if not log_file then
            error("Cannot open log file: " .. path)
        end
    else
        log_file = nil
    end
end

function logger.set_colors(enabled)
    use_colors = enabled
end

local function format_message(level, message, ...)
    local utils = require('libs.shared.utils')
    local timestamp = utils.get_timestamp()
    local level_name = LEVEL_NAMES[level]
    
    if select('#', ...) > 0 then
        message = string.format(message, ...)
    end
    
    return string.format("[%s] %s: %s", timestamp, level_name, message)
end

local function log(level, message, ...)
    if level < current_level then
        return
    end
    
    local formatted = format_message(level, message, ...)
    
    if use_colors and not log_file then
        local color = LEVEL_COLORS[level] or ""
        print(color .. formatted .. RESET_COLOR)
    else
        print(formatted)
    end
    
    if log_file then
        log_file:write(formatted .. "\n")
        log_file:flush()
    end
end

function logger.debug(message, ...)
    log(LOG_LEVELS.DEBUG, message, ...)
end

function logger.info(message, ...)
    log(LOG_LEVELS.INFO, message, ...)
end

function logger.warn(message, ...)
    log(LOG_LEVELS.WARN, message, ...)
end

function logger.error(message, ...)
    log(LOG_LEVELS.ERROR, message, ...)
end

function logger.close()
    if log_file then
        log_file:close()
        log_file = nil
    end
end

return logger