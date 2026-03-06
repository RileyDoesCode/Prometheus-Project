-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- ast.lua

local Ast = {}

local AstKind = {
	-- Misc
	TopNode = "TopNode",
	Block = "Block",

	-- Statements
	ContinueStatement = "ContinueStatement",
	BreakStatement = "BreakStatement",
	DoStatement = "DoStatement",
	WhileStatement = "WhileStatement",
	ReturnStatement = "ReturnStatement",
	RepeatStatement = "RepeatStatement",
	ForInStatement = "ForInStatement",
	ForStatement = "ForStatement",
	IfStatement = "IfStatement",
	FunctionDeclaration = "FunctionDeclaration",
	LocalFunctionDeclaration = "LocalFunctionDeclaration",
	LocalVariableDeclaration = "LocalVariableDeclaration",
	FunctionCallStatement = "FunctionCallStatement",
	PassSelfFunctionCallStatement = "PassSelfFunctionCallStatement",
	AssignmentStatement = "AssignmentStatement",

	-- LuaU Compound Statements
	CompoundAddStatement = "CompoundAddStatement",
	CompoundSubStatement = "CompoundSubStatement",
	CompoundMulStatement = "CompoundMulStatement",
	CompoundDivStatement = "CompoundDivStatement",
	CompoundModStatement = "CompoundModStatement",
	CompoundPowStatement = "CompoundPowStatement",
	CompoundConcatStatement = "CompoundConcatStatement",

	-- Assignment Index
	AssignmentIndexing = "AssignmentIndexing",
	AssignmentVariable = "AssignmentVariable",  

	-- Expression Nodes
	BooleanExpression = "BooleanExpression",
	NumberExpression = "NumberExpression",
	StringExpression = "StringExpression",
	NilExpression = "NilExpression",
	VarargExpression = "VarargExpression",
	OrExpression = "OrExpression",
	AndExpression = "AndExpression",
	LessThanExpression = "LessThanExpression",
	GreaterThanExpression = "GreaterThanExpression",
	LessThanOrEqualsExpression = "LessThanOrEqualsExpression",
	GreaterThanOrEqualsExpression = "GreaterThanOrEqualsExpression",
	NotEqualsExpression = "NotEqualsExpression",
	EqualsExpression = "EqualsExpression",
	StrCatExpression = "StrCatExpression",
	AddExpression = "AddExpression",
	SubExpression = "SubExpression",
	MulExpression = "MulExpression",
	DivExpression = "DivExpression",
	ModExpression = "ModExpression",
	NotExpression = "NotExpression",
	LenExpression = "LenExpression",
	NegateExpression = "NegateExpression",
	PowExpression = "PowExpression",
	IndexExpression = "IndexExpression",
	FunctionCallExpression = "FunctionCallExpression",
	PassSelfFunctionCallExpression = "PassSelfFunctionCallExpression",
	VariableExpression = "VariableExpression",
	FunctionLiteralExpression = "FunctionLiteralExpression",
	TableConstructorExpression = "TableConstructorExpression",

	-- Table Entry
	TableEntry = "TableEntry",
	KeyedTableEntry = "KeyedTableEntry",

	-- Misc
	NopStatement = "NopStatement",
	IfElseExpression = "IfElseExpression",
}

local astKindExpressionLookup = {
	[AstKind.BooleanExpression] = 0,
	[AstKind.NumberExpression] = 0,
	[AstKind.StringExpression] = 0,
	[AstKind.NilExpression] = 0,
	[AstKind.VarargExpression] = 0,
	[AstKind.OrExpression] = 12,
	[AstKind.AndExpression] = 11,
	[AstKind.LessThanExpression] = 10,
	[AstKind.GreaterThanExpression] = 10,
	[AstKind.LessThanOrEqualsExpression] = 10,
	[AstKind.GreaterThanOrEqualsExpression] = 10,
	[AstKind.NotEqualsExpression] = 10,
	[AstKind.EqualsExpression] = 10,
	[AstKind.StrCatExpression] = 9,
	[AstKind.AddExpression] = 8,
	[AstKind.SubExpression] = 8,
	[AstKind.MulExpression] = 7,
	[AstKind.DivExpression] = 7,
	[AstKind.ModExpression] = 7,
	[AstKind.NotExpression] = 5,
	[AstKind.LenExpression] = 5,
	[AstKind.NegateExpression] = 5,
	[AstKind.PowExpression] = 4,
	[AstKind.IndexExpression] = 1,
	[AstKind.AssignmentIndexing] = 1,
	[AstKind.FunctionCallExpression] = 2,
	[AstKind.PassSelfFunctionCallExpression] = 2,
	[AstKind.VariableExpression] = 0,
	[AstKind.AssignmentVariable] = 0,
	[AstKind.FunctionLiteralExpression] = 3,
	[AstKind.TableConstructorExpression] = 3,
}

Ast.AstKind = AstKind

function Ast.astKindExpressionToNumber(kind)
	return astKindExpressionLookup[kind] or 100
end

function Ast.ConstantNode(val)
	if val == nil then
		return Ast.NilExpression()
	end
	
	local valType = type(val)
	if valType == "string" then
		return Ast.StringExpression(val)
	elseif valType == "number" then
		return Ast.NumberExpression(val)
	elseif valType == "boolean" then
		return Ast.BooleanExpression(val)
	end
end

-- Shared function for AST nodes that need to resolve their variable name from a scope
local function sharedGetName(self)
	return self.scope:getVariableName(self.id)
end

-- Helper to safely fold binary operations
local function foldBinary(simplify, lhs, rhs, operation)
	if simplify and lhs.isConstant and rhs.isConstant then
		local success, val = pcall(operation, lhs.value, rhs.value)
		if success then
			return Ast.ConstantNode(val)
		end
	end
	return nil
end

-- Helper to safely fold unary operations
local function foldUnary(simplify, rhs, operation)
	if simplify and rhs.isConstant then
		local success, val = pcall(operation, rhs.value)
		if success then
			return Ast.ConstantNode(val)
		end
	end
	return nil
end


function Ast.NopStatement()
	return { kind = AstKind.NopStatement }
end

function Ast.IfElseExpression(condition, true_value, false_value)
	return {
		kind = AstKind.IfElseExpression,
		condition = condition,
		true_value = true_value,
		false_value = false_value
	}
end

-- Create Ast Top Node
function Ast.TopNode(body, globalScope)
	return {
		kind = AstKind.TopNode,
		body = body,
		globalScope = globalScope,
	}
end

function Ast.TableEntry(value)
	return {
		kind = AstKind.TableEntry,
		value = value,
	}
end

function Ast.KeyedTableEntry(key, value)
	return {
		kind = AstKind.KeyedTableEntry,
		key = key,
		value = value,
	}
end

function Ast.TableConstructorExpression(entries)
	return {
		kind = AstKind.TableConstructorExpression,
		entries = entries,
	}
end

-- Create Statement Block
function Ast.Block(statements, scope)
	return {
		kind = AstKind.Block,
		statements = statements,
		scope = scope,
	}
end

-- Create Break Statement
function Ast.BreakStatement(loop, scope)
	return {
		kind = AstKind.BreakStatement,
		loop = loop,
		scope = scope,
	}
end

-- Create Continue Statement
function Ast.ContinueStatement(loop, scope)
	return {
		kind = AstKind.ContinueStatement,
		loop = loop,
		scope = scope,
	}
end

function Ast.PassSelfFunctionCallStatement(base, passSelfFunctionName, args)
	return {
		kind = AstKind.PassSelfFunctionCallStatement,
		base = base,
		passSelfFunctionName = passSelfFunctionName,
		args = args,
	}
end

function Ast.AssignmentStatement(lhs, rhs)
	if #lhs < 1 then
		print(debug.traceback())
		error("Something went wrong!")
	end
	return {
		kind = AstKind.AssignmentStatement,
		lhs = lhs,
		rhs = rhs,
	}
end

function Ast.CompoundAddStatement(lhs, rhs)
	return { kind = AstKind.CompoundAddStatement, lhs = lhs, rhs = rhs }
end

function Ast.CompoundSubStatement(lhs, rhs)
	return { kind = AstKind.CompoundSubStatement, lhs = lhs, rhs = rhs }
end

function Ast.CompoundMulStatement(lhs, rhs)
	return { kind = AstKind.CompoundMulStatement, lhs = lhs, rhs = rhs }
end

function Ast.CompoundDivStatement(lhs, rhs)
	return { kind = AstKind.CompoundDivStatement, lhs = lhs, rhs = rhs }
end

function Ast.CompoundPowStatement(lhs, rhs)
	return { kind = AstKind.CompoundPowStatement, lhs = lhs, rhs = rhs }
end

function Ast.CompoundModStatement(lhs, rhs)
	return { kind = AstKind.CompoundModStatement, lhs = lhs, rhs = rhs }
end

function Ast.CompoundConcatStatement(lhs, rhs)
	return { kind = AstKind.CompoundConcatStatement, lhs = lhs, rhs = rhs }
end

function Ast.FunctionCallStatement(base, args)
	return {
		kind = AstKind.FunctionCallStatement,
		base = base,
		args = args,
	}
end

function Ast.ReturnStatement(args)
	return {
		kind = AstKind.ReturnStatement,
		args = args,
	}
end

function Ast.DoStatement(body)
	return {
		kind = AstKind.DoStatement,
		body = body,
	}
end

function Ast.WhileStatement(body, condition, parentScope)
	return {
		kind = AstKind.WhileStatement,
		body = body,
		condition = condition,
		parentScope = parentScope,
	}
end

function Ast.ForInStatement(scope, vars, expressions, body, parentScope)
	return {
		kind = AstKind.ForInStatement,
		scope = scope,
		ids = vars,
		vars = vars,
		expressions = expressions,
		body = body,
		parentScope = parentScope,
	}
end

function Ast.ForStatement(scope, id, initialValue, finalValue, incrementBy, body, parentScope)
	return {
		kind = AstKind.ForStatement,
		scope = scope,
		id = id,
		initialValue = initialValue,
		finalValue = finalValue,
		incrementBy = incrementBy,
		body = body,
		parentScope = parentScope,
	}
end

function Ast.RepeatStatement(condition, body, parentScope)
	return {
		kind = AstKind.RepeatStatement,
		body = body,
		condition = condition,
		parentScope = parentScope,
	}
end

function Ast.IfStatement(condition, body, elseifs, elsebody)
	return {
		kind = AstKind.IfStatement,
		condition = condition,
		body = body,
		elseifs = elseifs,
		elsebody = elsebody,
	}
end

function Ast.FunctionDeclaration(scope, id, indices, args, body)
	return {
		kind = AstKind.FunctionDeclaration,
		scope = scope,
		baseScope = scope,
		id = id,
		baseId = id,
		indices = indices,
		args = args,
		body = body,
		getName = sharedGetName,
	}
end

function Ast.LocalFunctionDeclaration(scope, id, args, body)
	return {
		kind = AstKind.LocalFunctionDeclaration,
		scope = scope,
		id = id,
		args = args,
		body = body,
		getName = sharedGetName,
	}
end

function Ast.LocalVariableDeclaration(scope, ids, expressions)
	return {
		kind = AstKind.LocalVariableDeclaration,
		scope = scope,
		ids = ids,
		expressions = expressions,
	}
end

function Ast.VarargExpression()
	return {
		kind = AstKind.VarargExpression,
		isConstant = false,
	}
end

function Ast.BooleanExpression(value)
	return {
		kind = AstKind.BooleanExpression,
		isConstant = true,
		value = value,
	}
end

function Ast.NilExpression()
	return {
		kind = AstKind.NilExpression,
		isConstant = true,
		value = nil,
	}
end

function Ast.NumberExpression(value)
	return {
		kind = AstKind.NumberExpression,
		isConstant = true,
		value = value,
	}
end

function Ast.StringExpression(value)
	return {
		kind = AstKind.StringExpression,
		isConstant = true,
		value = value,
	}
end

function Ast.OrExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a or b end)
	if folded then return folded end

	return {
		kind = AstKind.OrExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.AndExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a and b end)
	if folded then return folded end

	return {
		kind = AstKind.AndExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.LessThanExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a < b end)
	if folded then return folded end

	return {
		kind = AstKind.LessThanExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.GreaterThanExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a > b end)
	if folded then return folded end

	return {
		kind = AstKind.GreaterThanExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.LessThanOrEqualsExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a <= b end)
	if folded then return folded end

	return {
		kind = AstKind.LessThanOrEqualsExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.GreaterThanOrEqualsExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a >= b end)
	if folded then return folded end

	return {
		kind = AstKind.GreaterThanOrEqualsExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.NotEqualsExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a ~= b end)
	if folded then return folded end

	return {
		kind = AstKind.NotEqualsExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.EqualsExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a == b end)
	if folded then return folded end

	return {
		kind = AstKind.EqualsExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.StrCatExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a .. b end)
	if folded then return folded end

	return {
		kind = AstKind.StrCatExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.AddExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a + b end)
	if folded then return folded end

	return {
		kind = AstKind.AddExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.SubExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a - b end)
	if folded then return folded end

	return {
		kind = AstKind.SubExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.MulExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a * b end)
	if folded then return folded end

	return {
		kind = AstKind.MulExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.DivExpression(lhs, rhs, simplify)
	if simplify and rhs.isConstant and lhs.isConstant and rhs.value ~= 0 then
		local success, val = pcall(function() return lhs.value / rhs.value end)
		if success then
			return Ast.ConstantNode(val)
		end
	end

	return {
		kind = AstKind.DivExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.ModExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a % b end)
	if folded then return folded end

	return {
		kind = AstKind.ModExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.NotExpression(rhs, simplify)
	local folded = foldUnary(simplify, rhs, function(a) return not a end)
	if folded then return folded end

	return {
		kind = AstKind.NotExpression,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.NegateExpression(rhs, simplify)
	local folded = foldUnary(simplify, rhs, function(a) return -a end)
	if folded then return folded end

	return {
		kind = AstKind.NegateExpression,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.LenExpression(rhs, simplify)
	local folded = foldUnary(simplify, rhs, function(a) return #a end)
	if folded then return folded end

	return {
		kind = AstKind.LenExpression,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.PowExpression(lhs, rhs, simplify)
	local folded = foldBinary(simplify, lhs, rhs, function(a, b) return a ^ b end)
	if folded then return folded end

	return {
		kind = AstKind.PowExpression,
		lhs = lhs,
		rhs = rhs,
		isConstant = false,
	}
end

function Ast.IndexExpression(base, index)
	return {
		kind = AstKind.IndexExpression,
		base = base,
		index = index,
		isConstant = false,
	}
end

function Ast.AssignmentIndexing(base, index)
	return {
		kind = AstKind.AssignmentIndexing,
		base = base,
		index = index,
		isConstant = false,
	}
end

function Ast.PassSelfFunctionCallExpression(base, passSelfFunctionName, args)
	return {
		kind = AstKind.PassSelfFunctionCallExpression,
		base = base,
		passSelfFunctionName = passSelfFunctionName,
		args = args,
	}
end

function Ast.FunctionCallExpression(base, args)
	return {
		kind = AstKind.FunctionCallExpression,
		base = base,
		args = args,
	}
end

function Ast.VariableExpression(scope, id)
	scope:addReference(id)
	return {
		kind = AstKind.VariableExpression, 
		scope = scope,
		id = id,
		getName = sharedGetName,
	}
end

function Ast.AssignmentVariable(scope, id)
	scope:addReference(id)
	return {
		kind = AstKind.AssignmentVariable, 
		scope = scope,
		id = id,
		getName = sharedGetName,
	}
end

function Ast.FunctionLiteralExpression(args, body)
	return {
		kind = AstKind.FunctionLiteralExpression,
		args = args,
		body = body,
	}
end

return Ast
