-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- prometheus.lua
-- Entrypoint for Prometheus

--------------------------------------------------
-- Resolve script directory
--------------------------------------------------

local function script_path()
    local source = debug.getinfo(2, "S").source:sub(2)
    return source:match("(.*[/%\\])") or ""
end

--------------------------------------------------
-- Temporarily extend package.path
--------------------------------------------------

local oldPkgPath = package.path
package.path = script_path() .. "?.lua;" .. package.path

--------------------------------------------------
-- math.random fix for Lua 5.1 (large ranges)
--------------------------------------------------

if not pcall(function()
    return math.random(1, 2^40)
end) then
    local oldMathRandom = math.random

    math.random = function(a, b)
        if not a and not b then
            return oldMathRandom()
        end

        if a and not b then
            return math.random(1, a)
        end

        if a > b then
            a, b = b, a
        end

        local diff = b - a
        assert(diff >= 0)

        if diff > 2^31 - 1 then
            return math.floor(oldMathRandom() * diff + a)
        else
            return oldMathRandom(a, b)
        end
    end
end

--------------------------------------------------
-- newproxy polyfill (Lua 5.2+ compatibility)
--------------------------------------------------

_G.newproxy = _G.newproxy or function(arg)
    if arg then
        return setmetatable({}, {})
    end
    return {}
end

--------------------------------------------------
-- Load Prometheus submodules
--------------------------------------------------

local Pipeline  = require("prometheus.pipeline")
local highlight = require("highlightlua")
local colors    = require("colors")
local Logger    = require("logger")
local Presets   = require("presets")
local Config    = require("config")
local util      = require("prometheus.util")

--------------------------------------------------
-- Restore package.path
--------------------------------------------------

package.path = oldPkgPath

--------------------------------------------------
-- Public API
--------------------------------------------------

return {
    Pipeline  = Pipeline,
    colors    = colors,
    Config    = util.readonly(Config), -- readonly export
    Logger    = Logger,
    highlight = highlight,
    Presets   = Presets
}
