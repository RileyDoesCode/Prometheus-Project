-- This Script is Part of the Prometheus Obfuscator by Levno_710

--------------------------------------------------
-- ANSI color / style codes
--------------------------------------------------

local keys = {
    reset = 0,

    bright    = 1,
    dim       = 2,
    underline = 4,
    blink     = 5,
    reverse   = 7,
    hidden    = 8,

    black   = 30,
    red     = 31,
    green   = 32,
    yellow  = 33,
    blue    = 34,
    magenta = 35,
    cyan    = 36,
    grey    = 37,
    gray    = 37,

    pink  = 91,
    white = 97,

    blackbg   = 40,
    redbg     = 41,
    greenbg   = 42,
    yellowbg  = 43,
    bluebg    = 44,
    magentabg = 45,
    cyanbg    = 46,
    greybg    = 47,
    graybg    = 47,
    whitebg   = 107
}

--------------------------------------------------
-- Escape helpers
--------------------------------------------------

local escapeString = string.char(27) .. "[%dm"

local function escapeNumber(number)
    return escapeString:format(number)
end

--------------------------------------------------
-- Settings
--------------------------------------------------

local settings = {
    enabled = true
}

--------------------------------------------------
-- Color application
--------------------------------------------------

local function colors(str, ...)
    if not settings.enabled then
        return str
    end

    str = tostring(str or "")

    local escapes = {}

    for _, name in ipairs({...}) do
        table.insert(escapes, escapeNumber(keys[name]))
    end

    return escapeNumber(keys.reset)
        .. table.concat(escapes)
        .. str
        .. escapeNumber(keys.reset)
end

--------------------------------------------------
-- Callable module
--------------------------------------------------

return setmetatable(settings, {
    __call = function(_, ...)
        return colors(...)
    end
})
