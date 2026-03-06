-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- WatermarkCheck.lua
--
-- This Script provides a Step that will add a watermark check to the script

local Step = require("prometheus.step")
local Ast = require("prometheus.ast")
local Scope = require("prometheus.scope")
local Watermark = require("prometheus.steps.Watermark")

local WatermarkCheck = Step:extend()
WatermarkCheck.Description = "This Step adds a runtime check to ensure the watermark has not been removed or tampered with."
WatermarkCheck.Name = "WatermarkCheck"

WatermarkCheck.SettingsDescriptor = {
	Content = {
		name = "Content",
		description = "The Content of the WatermarkCheck",
		type = "string",
		default = "This Script is Part of the Prometheus Obfuscator by Levno_710",
	},
}

function WatermarkCheck:init(settings)
	-- No initialization needed
end

function WatermarkCheck:apply(ast, pipeline)
	local nameGen = type(pipeline.namegenerator) == "table" and pipeline.namegenerator.generateName or pipeline.namegenerator
	self.CustomVariable = "_" .. nameGen(math.random(10000000000, 100000000000))
	
	-- Dynamically enqueue the actual Watermark step to run after this one
	pipeline:addStep(Watermark:new(self))

	local body = ast.body
	local watermarkExpression = Ast.StringExpression(self.Content)
	local scope, variable = ast.globalScope:resolve(self.CustomVariable)
	local watermark = Ast.VariableExpression(ast.globalScope, variable)
	
	local notEqualsExpression = Ast.NotEqualsExpression(watermark, watermarkExpression)
	local ifBody = Ast.Block({Ast.ReturnStatement({})}, Scope:new(ast.body.scope))

	-- Injects: if _WATERMARK ~= "Content" then return end
	table.insert(body.statements, 1, Ast.IfStatement(notEqualsExpression, ifBody, {}, nil))
	
	return ast
end

return WatermarkCheck
