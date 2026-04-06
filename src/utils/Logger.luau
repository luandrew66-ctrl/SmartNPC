--[[
    SmartNPC :: Logger
    Debug logging with configurable levels.
]]

local Logger = {}
Logger.__index = Logger

Logger.LEVELS = { NONE = 0, ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4 }

local currentLevel = Logger.LEVELS.WARN
local PREFIX = "[SmartNPC]"

function Logger.setLevel(level: number)
    currentLevel = level
end

function Logger.debug(...)
    if currentLevel >= Logger.LEVELS.DEBUG then
        print(PREFIX, "[DEBUG]", ...)
    end
end

function Logger.info(...)
    if currentLevel >= Logger.LEVELS.INFO then
        print(PREFIX, "[INFO]", ...)
    end
end

function Logger.warn(...)
    if currentLevel >= Logger.LEVELS.WARN then
        warn(PREFIX, ...)
    end
end

function Logger.error(...)
    if currentLevel >= Logger.LEVELS.ERROR then
        warn(PREFIX, "[ERROR]", ...)
    end
end

return Logger
