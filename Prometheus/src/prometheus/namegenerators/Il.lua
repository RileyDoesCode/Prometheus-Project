-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- namegenerators/il.lua
--
-- This Script provides a function for the generation of weird names consisting of I, l, and 1

local util = require("prometheus.util")
local chararray = util.chararray

local MIN_CHARACTERS = 5
local MAX_INITIAL_CHARACTERS = 10

local offset = 0
local VarDigits = chararray("Il1")
local VarStartDigits = chararray("Il")

local function generateName(id, scope)
	id = id + offset
	
	local startLen = #VarStartDigits
	local d = id % startLen
	id = (id - d) / startLen
	
	-- Using a table for faster iterative string building
	local result = { VarStartDigits[d + 1] }
	
	local digitsLen = #VarDigits
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
	offset = math.random(3 ^ MIN_CHARACTERS, 3 ^ MAX_INITIAL_CHARACTERS)
end

return {
	generateName = generateName, 
	prepare = prepare
}
