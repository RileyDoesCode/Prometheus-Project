-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- namegenerators/mangled_shuffled.lua
--
-- This Script provides a function for the generation of mangled names with shuffled character order

local util = require("prometheus.util")
local chararray = util.chararray

local VarDigits = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
local VarStartDigits = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

-- Cache lengths globally since shuffling changes the order, but not the size
local startLen = #VarStartDigits
local digitsLen = #VarDigits

local function generateName(id, scope)
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

local function prepare(ast)
	util.shuffle(VarDigits)
	util.shuffle(VarStartDigits)
end

return {
	generateName = generateName, 
	prepare = prepare
}
