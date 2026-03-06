-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- randomStrings.lua

local Ast = require("prometheus.ast")
local utils = require("prometheus.util")

local charset = utils.chararray("qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890")
local charsetLen = #charset

local function randomString(wordsOrLen)
	if type(wordsOrLen) == "table" then
		return wordsOrLen[math.random(1, #wordsOrLen)]
	end

	local len = wordsOrLen or math.random(2, 15)
	
	-- Use a table to build the string iteratively for significantly better performance
	local result = {}
	for i = 1, len do
		result[i] = charset[math.random(1, charsetLen)]
	end
	
	return table.concat(result)
end

local function randomStringNode(wordsOrLen)
	return Ast.StringExpression(randomString(wordsOrLen))
end

return {
	randomString = randomString,
	randomStringNode = randomStringNode,
}
