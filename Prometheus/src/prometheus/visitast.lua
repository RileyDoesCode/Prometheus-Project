-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- util.lua (AST Visitor)
-- This file Provides a Utility function for visiting each node of an ast

local Ast = require("prometheus.ast")
local util = require("prometheus.util")

local AstKind = Ast.AstKind
local lookupify = util.lookupify
local unpack = table.unpack or unpack

local visitAst, visitBlock, visitStatement, visitExpression

function visitAst(ast, previsit, postvisit, data)
	ast.isAst = true
	data = data or {}
	data.scopeStack = {}
	data.functionData = {
		depth = 0,
		scope = ast.body.scope,
		node = ast,
	}
	data.scope = ast.globalScope
	data.globalScope = ast.globalScope
	
	if type(previsit) == "function" then
		local node, skip = previsit(ast, data)
		ast = node or ast
		if skip then
			return ast
		end
	end
	
	-- Is Function Block because global scope is treated like a Function
	visitBlock(ast.body, previsit, postvisit, data, true)
	
	if type(postvisit) == "function" then
		ast = postvisit(ast, data) or ast
	end
	return ast
end

local compoundStats = lookupify{
	AstKind.CompoundAddStatement,
	AstKind.CompoundSubStatement,
	AstKind.CompoundMulStatement,
	AstKind.CompoundDivStatement,
	AstKind.CompoundModStatement,
	AstKind.CompoundPowStatement,
	AstKind.CompoundConcatStatement,
}

function visitBlock(block, previsit, postvisit, data, isFunctionBlock)
	block.isBlock = true
	block.isFunctionBlock = isFunctionBlock or false
	data.scope = block.scope
	local parentBlockData = data.blockData
	data.blockData = {}
	table.insert(data.scopeStack, block.scope)
	
	if type(previsit) == "function" then
		local node, skip = previsit(block, data)
		block = node or block
		if skip then
			data.scope = table.remove(data.scopeStack)
			return block
		end
	end
	
	-- Optimized array rebuilding (O(N) instead of O(N^2) table shifts)
	local newStatements = {}
	for _, statement in ipairs(block.statements) do
		local returnedStatements = {visitStatement(statement, previsit, postvisit, data)}
		for _, retStat in ipairs(returnedStatements) do
			newStatements[#newStatements + 1] = retStat
		end
	end
	block.statements = newStatements

	if type(postvisit) == "function" then
		block = postvisit(block, data) or block
	end
	
	data.scope = table.remove(data.scopeStack)
	data.blockData = parentBlockData
	return block
end

function visitStatement(statement, previsit, postvisit, data)
	statement.isStatement = true
	
	if type(previsit) == "function" then
		local node, skip = previsit(statement, data)
		statement = node or statement
		if skip then
			return statement
		end
	end
	
	local kind = statement.kind
	
	-- Visit Child Nodes of Statement
	if kind == AstKind.ReturnStatement then
		for i, expression in ipairs(statement.args) do
			statement.args[i] = visitExpression(expression, previsit, postvisit, data)
		end
	elseif kind == AstKind.PassSelfFunctionCallStatement or kind == AstKind.FunctionCallStatement then
		statement.base = visitExpression(statement.base, previsit, postvisit, data)
		for i, expression in ipairs(statement.args) do
			statement.args[i] = visitExpression(expression, previsit, postvisit, data)
		end
	elseif kind == AstKind.AssignmentStatement then
		for i, primaryExpr in ipairs(statement.lhs) do
			statement.lhs[i] = visitExpression(primaryExpr, previsit, postvisit, data)
		end
		for i, expression in ipairs(statement.rhs) do
			statement.rhs[i] = visitExpression(expression, previsit, postvisit, data)
		end
	elseif kind == AstKind.FunctionDeclaration or kind == AstKind.LocalFunctionDeclaration then
		local parentFunctionData = data.functionData
		data.functionData = {
			depth = parentFunctionData.depth + 1,
			scope = statement.body.scope,
			node = statement,
		}
		statement.body = visitBlock(statement.body, previsit, postvisit, data, true)
		data.functionData = parentFunctionData
	elseif kind == AstKind.DoStatement then
		statement.body = visitBlock(statement.body, previsit, postvisit, data, false)
	elseif kind == AstKind.WhileStatement then
		statement.condition = visitExpression(statement.condition, previsit, postvisit, data)
		statement.body = visitBlock(statement.body, previsit, postvisit, data, false)
	elseif kind == AstKind.RepeatStatement then
		statement.body = visitBlock(statement.body, previsit, postvisit, data)
		statement.condition = visitExpression(statement.condition, previsit, postvisit, data)
	elseif kind == AstKind.ForStatement then
		statement.initialValue = visitExpression(statement.initialValue, previsit, postvisit, data)
		statement.finalValue = visitExpression(statement.finalValue, previsit, postvisit, data)
		statement.incrementBy = visitExpression(statement.incrementBy, previsit, postvisit, data)
		statement.body = visitBlock(statement.body, previsit, postvisit, data, false)
	elseif kind == AstKind.ForInStatement then
		for i, expression in ipairs(statement.expressions) do
			statement.expressions[i] = visitExpression(expression, previsit, postvisit, data)
		end
		visitBlock(statement.body, previsit, postvisit, data, false)
	elseif kind == AstKind.IfStatement then
		statement.condition = visitExpression(statement.condition, previsit, postvisit, data)
		statement.body = visitBlock(statement.body, previsit, postvisit, data, false)
		for _, eif in ipairs(statement.elseifs) do
			eif.condition = visitExpression(eif.condition, previsit, postvisit, data)
			eif.body = visitBlock(eif.body, previsit, postvisit, data, false)
		end
		if statement.elsebody then
			statement.elsebody = visitBlock(statement.elsebody, previsit, postvisit, data, false)
		end
	elseif kind == AstKind.LocalVariableDeclaration then
		for i, expression in ipairs(statement.expressions) do
			statement.expressions[i] = visitExpression(expression, previsit, postvisit, data)
		end
	elseif compoundStats[kind] then
		statement.lhs = visitExpression(statement.lhs, previsit, postvisit, data)
		statement.rhs = visitExpression(statement.rhs, previsit, postvisit, data)
	end

	if type(postvisit) == "function" then
		local statements = {postvisit(statement, data)}
		if #statements > 0 then
			return unpack(statements)
		end
	end
	
	return statement
end

local binaryExpressions = lookupify{
	AstKind.OrExpression,
	AstKind.AndExpression,
	AstKind.LessThanExpression,
	AstKind.GreaterThanExpression,
	AstKind.LessThanOrEqualsExpression,
	AstKind.GreaterThanOrEqualsExpression,
	AstKind.NotEqualsExpression,
	AstKind.EqualsExpression,
	AstKind.StrCatExpression,
	AstKind.AddExpression,
	AstKind.SubExpression,
	AstKind.MulExpression,
	AstKind.DivExpression,
	AstKind.ModExpression,
	AstKind.PowExpression,
}

function visitExpression(expression, previsit, postvisit, data)
	expression.isExpression = true
	
	if type(previsit) == "function" then
		local node, skip = previsit(expression, data)
		expression = node or expression
		if skip then
			return expression
		end
	end
	
	local kind = expression.kind
	
	if binaryExpressions[kind] then
		expression.lhs = visitExpression(expression.lhs, previsit, postvisit, data)
		expression.rhs = visitExpression(expression.rhs, previsit, postvisit, data)
	end
	
	if kind == AstKind.NotExpression or kind == AstKind.NegateExpression or kind == AstKind.LenExpression then
		expression.rhs = visitExpression(expression.rhs, previsit, postvisit, data)
	end
	
	if kind == AstKind.PassSelfFunctionCallExpression or kind == AstKind.FunctionCallExpression then
		expression.base = visitExpression(expression.base, previsit, postvisit, data)
		for i, arg in ipairs(expression.args) do
			expression.args[i] = visitExpression(arg, previsit, postvisit, data)
		end
	end
	
	if kind == AstKind.FunctionLiteralExpression then
		local parentFunctionData = data.functionData
		data.functionData = {
			depth = parentFunctionData.depth + 1,
			scope = expression.body.scope,
			node = expression,
		}
		expression.body = visitBlock(expression.body, previsit, postvisit, data, true)
		data.functionData = parentFunctionData
	end
	
	if kind == AstKind.TableConstructorExpression then
		for _, entry in ipairs(expression.entries) do
			if entry.kind == AstKind.KeyedTableEntry then
				entry.key = visitExpression(entry.key, previsit, postvisit, data)
			end
			entry.value = visitExpression(entry.value, previsit, postvisit, data)
		end
	end
	
	if kind == AstKind.IndexExpression or kind == AstKind.AssignmentIndexing then
		expression.base = visitExpression(expression.base, previsit, postvisit, data)
		expression.index = visitExpression(expression.index, previsit, postvisit, data)
	end
	
	if kind == AstKind.IfElseExpression then
		-- Bugfix: true_expr/false_expr were used instead of the proper true_value/false_value
		expression.condition = visitExpression(expression.condition, previsit, postvisit, data)
		expression.true_value = visitExpression(expression.true_value, previsit, postvisit, data)
		expression.false_value = visitExpression(expression.false_value, previsit, postvisit, data)
	end

	if type(postvisit) == "function" then
		expression = postvisit(expression, data) or expression
	end
	
	return expression
end

return visitAst
