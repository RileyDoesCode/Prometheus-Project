-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- test.lua
-- This script contains the code for the Prometheus CLI

---------------------------------------------------------------------
-- Resolve Script Directory
---------------------------------------------------------------------

local function script_path()
    local source = debug.getinfo(2, "S").source
    local path = source:sub(2)

    return path:match("(.*[/%\\])") or ""
end

---------------------------------------------------------------------
-- Configure package.path for requiring Prometheus
---------------------------------------------------------------------

package.path = script_path() .. "?.lua;" .. package.path

---------------------------------------------------------------------
-- Start CLI
---------------------------------------------------------------------

require("src.cli")
