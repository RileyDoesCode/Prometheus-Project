-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- Library for Creating Random Literals

local Ast = require("prometheus.ast")
local RandomStrings = require("prometheus.randomStrings")

local RandomLiterals = {}

local function callNameGenerator(generator, ...)
	local func = type(generator) == "table" and generator.generateName or generator
	return func(...)
end

function RandomLiterals.String(pipeline)
	return Ast.StringExpression(callNameGenerator(pipeline.namegenerator, math.random(1, 4096)))
end

function RandomLiterals.Dictionary()
	return RandomStrings.randomStringNode(true)
end

function RandomLiterals.Number()
	return Ast.NumberExpression(math.random(-8388608, 8388607))
end

function RandomLiterals.Any(pipeline)
	local choice = math.random(1, 3)
	if choice == 1 then
		return RandomLiterals.String(pipeline)
	elseif choice == 2 then
		return RandomLiterals.Number()
	else
		return RandomLiterals.Dictionary()
	end
end

return RandomLiterals
