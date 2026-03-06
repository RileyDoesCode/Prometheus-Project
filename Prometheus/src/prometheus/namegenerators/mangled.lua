-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- namegenerators/mangled.lua
--
-- This Script provides a function for the generation of mangled names

local util = require("prometheus.util")
local chararray = util.chararray

local VarDigits = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
local VarStartDigits = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

-- Cache lengths globally since they are static in this generator
local startLen = #VarStartDigits
local digitsLen = #VarDigits

return function(id, scope)
	local d = id % startLen
	id = (id - d) / startLen
	
	-- Initialize table with the starting character
	local result = { VarStartDigits[d + 1] }
	
	while id > 0 do
		d = id % digitsLen
		id = (id - d) / digitsLen
		result[#result + 1] = VarDigits[d + 1]
	end
	
	return table.concat(result)
end
