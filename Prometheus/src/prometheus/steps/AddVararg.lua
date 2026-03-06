-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- AddVararg.lua
--
-- This Script provides a Simple Obfuscation Step that adds a vararg parameter to all functions.

local Step = require("prometheus.step")
local Ast = require("prometheus.ast")
local visitast = require("prometheus.visitast")
local AstKind = Ast.AstKind

local AddVararg = Step:extend()
AddVararg.Description = "This Step Adds Vararg to all Functions"
AddVararg.Name = "Add Vararg"

AddVararg.SettingsDescriptor = {}

function AddVararg:init(settings)
	-- No initialization needed
end

-- Cache the target node kinds for faster O(1) lookups during traversal
local TARGET_KINDS = {
	[AstKind.FunctionDeclaration] = true,
	[AstKind.LocalFunctionDeclaration] = true,
	[AstKind.FunctionLiteralExpression] = true,
}

function AddVararg:apply(ast)
	visitast(ast, nil, function(node)
		if TARGET_KINDS[node.kind] then
			local args = node.args
			local numArgs = #args
			
			-- If there are no arguments, or the last argument is not a vararg, append one
			if numArgs < 1 or args[numArgs].kind ~= AstKind.VarargExpression then
				args[numArgs + 1] = Ast.VarargExpression()
			end
		end
	end)
end

return AddVararg
