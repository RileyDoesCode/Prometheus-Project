-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- NumbersToExpressions.lua
--
-- This Script provides an Obfuscation Step that converts Number Literals to expressions
local unpack = unpack or table.unpack

local Step = require("prometheus.step")
local Ast = require("prometheus.ast")
local Scope = require("prometheus.scope")
local visitast = require("prometheus.visitast")
local util     = require("prometheus.util")

local AstKind = Ast.AstKind

local NumbersToExpressions = Step:extend()
NumbersToExpressions.Description = "This Step Converts number Literals to Expressions"
NumbersToExpressions.Name = "Numbers To Expressions"

NumbersToExpressions.SettingsDescriptor = {
	Treshold = {
		name = "Threshold",
		type = "number",
		default = 1,
		min = 0,
		max = 1,
	},
	InternalTreshold = {
		name = "InternalThreshold",
		type = "number",
		default = 0.2,
		min = 0,
		max = 0.8,
	}
}

-- Cache generators to avoid redefining closures
local GENERATORS = {
	-- Addition
	function(self, val, depth)
		local val2 = math.random(-1048576, 1048576) -- -2^20 to 2^20
		local diff = val - val2
		
		-- Fast numeric precision check instead of slow string conversions
		if diff + val2 ~= val then
			return false
		end
		
		return Ast.AddExpression(self:CreateNumberExpression(val2, depth), self:CreateNumberExpression(diff, depth), false)
	end, 
	-- Subtraction
	function(self, val, depth)
		local val2 = math.random(-1048576, 1048576)
		local diff = val + val2
		
		-- Fast numeric precision check
		if diff - val2 ~= val then
			return false
		end
		
		return Ast.SubExpression(self:CreateNumberExpression(diff, depth), self:CreateNumberExpression(val2, depth), false)
	end
}

function NumbersToExpressions:init(settings)
	-- No instance-specific initialization needed
end

function NumbersToExpressions:CreateNumberExpression(val, depth)
	if (depth > 0 and math.random() >= self.InternalTreshold) or depth > 15 then
		return Ast.NumberExpression(val)
	end

	-- Zero-allocation randomized picking (since there are only 2 generators)
	local choice = math.random(1, 2)
	local node = GENERATORS[choice](self, val, depth + 1)
	
	if not node then
		-- Fallback to the other generator if the first one failed precision checks
		node = GENERATORS[3 - choice](self, val, depth + 1)
	end

	if node then
		return node
	end

	return Ast.NumberExpression(val)
end

function NumbersToExpressions:apply(ast)
	visitast(ast, nil, function(node, data)
		if node.kind == AstKind.NumberExpression and math.random() <= self.Treshold then
			return self:CreateNumberExpression(node.value, 0)
		end
	end)
end

return NumbersToExpressions
