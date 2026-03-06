-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- SplitStrings.lua
--
-- This Script provides a Simple Obfuscation Step for splitting Strings

local Step = require("prometheus.step")
local Ast = require("prometheus.ast")
local visitAst = require("prometheus.visitast")
local Parser = require("prometheus.parser")
local util = require("prometheus.util")
local enums = require("prometheus.enums")

local LuaVersion = enums.LuaVersion

local SplitStrings = Step:extend()
SplitStrings.Description = "This Step splits Strings to a specific or random length"
SplitStrings.Name = "Split Strings"

SplitStrings.SettingsDescriptor = {
	Treshold = {
		name = "Threshold",
		description = "The relative amount of nodes that will be affected",
		type = "number",
		default = 1,
		min = 0,
		max = 1,
	},
	MinLength = {
		name = "MinLength",
		description = "The minimal length for the chunks in that the Strings are splitted",
		type = "number",
		default = 5,
		min = 1,
		max = nil,
	},
	MaxLength = {
		name = "MaxLength",
		description = "The maximal length for the chunks in that the Strings are splitted",
		type = "number",
		default = 5,
		min = 1,
		max = nil,
	},
	ConcatenationType = {
		name = "ConcatenationType",
		description = "The Functions used for Concatenation. Note that when using custom, the String Array will also be Shuffled",
		type = "enum",
		values = {
			"strcat",
			"table",
			"custom",
		},
		default = "custom",
	},
	CustomFunctionType = {
		name = "CustomFunctionType",
		description = "The Type of Function code injection. This Option only applies when custom Concatenation is selected.\nNote that when chosing inline, the code size may increase significantly!",
		type = "enum",
		values = {
			"global",
			"local",
			"inline",
		},
		default = "global",
	},
	CustomLocalFunctionsCount = {
		name = "CustomLocalFunctionsCount",
		description = "The number of local functions per scope. This option only applies when CustomFunctionType = local",
		type = "number",
		default = 2,
		min = 1,
	}
}

function SplitStrings:init(settings) end

local function generateTableConcatNode(chunks, data)
	local chunkNodes = {}
	for _, chunk in ipairs(chunks) do
		table.insert(chunkNodes, Ast.TableEntry(Ast.StringExpression(chunk)))
	end
	local tb = Ast.TableConstructorExpression(chunkNodes)
	data.scope:addReferenceToHigherScope(data.tableConcatScope, data.tableConcatId)
	return Ast.FunctionCallExpression(Ast.VariableExpression(data.tableConcatScope, data.tableConcatId), {tb})	
end

local function generateStrCatNode(chunks)
	-- Put Together Expression for Concatenating String
	local generatedNode = nil
	for _, chunk in ipairs(chunks) do
		if generatedNode then
			generatedNode = Ast.StrCatExpression(generatedNode, Ast.StringExpression(chunk))
		else
			generatedNode = Ast.StringExpression(chunk)
		end
	end
	return generatedNode
end

local customVariants = 2
local custom1Code = [=[
function custom(table)
	local stringTable, str = table[#table], ""
	for i=1,#stringTable, 1 do
		str = str .. stringTable[table[i]]
	end
	return str
end
]=]

local custom2Code = [=[
function custom(tb)
	local str = ""
	for i=1, #tb / 2, 1 do
		str = str .. tb[#tb / 2 + tb[i]]
	end
	return str
end
]=]

local function generateCustomNodeArgs(chunks, data, variant)
	local shuffled = {}
	local shuffledIndices = {}
	for i = 1, #chunks do
		shuffledIndices[i] = i
	end
	util.shuffle(shuffledIndices)
	
	for i, v in ipairs(shuffledIndices) do
		shuffled[v] = chunks[i]
	end
	
	-- Custom Function Type 1
	if variant == 1 then
		local args = {}
		local tbNodes = {}
		
		for _, v in ipairs(shuffledIndices) do
			table.insert(args, Ast.TableEntry(Ast.NumberExpression(v)))
		end
		
		for _, chunk in ipairs(shuffled) do
			table.insert(tbNodes, Ast.TableEntry(Ast.StringExpression(chunk)))
		end
		
		local tb = Ast.TableConstructorExpression(tbNodes)
		table.insert(args, Ast.TableEntry(tb))
		return {Ast.TableConstructorExpression(args)}
		
	-- Custom Function Type 2
	else
		local args = {}
		for _, v in ipairs(shuffledIndices) do
			table.insert(args, Ast.TableEntry(Ast.NumberExpression(v)))
		end
		for _, chunk in ipairs(shuffled) do
			table.insert(args, Ast.TableEntry(Ast.StringExpression(chunk)))
		end
		return {Ast.TableConstructorExpression(args)}
	end
end

local function generateCustomFunctionLiteral(parentScope, variant)
	local parser = Parser:new({
		LuaVersion = LuaVersion.Lua51
	})

	local codeToParse = variant == 1 and custom1Code or custom2Code
	local funcDeclNode = parser:parse(codeToParse).body.statements[1]
	local funcBody = funcDeclNode.body
	local funcArgs = funcDeclNode.args
	funcBody.scope:setParent(parentScope)
	return Ast.FunctionLiteralExpression(funcArgs, funcBody)
end

local function generateGlobalCustomFunctionDeclaration(ast, data)
	local parser = Parser:new({
		LuaVersion = LuaVersion.Lua51
	})
	
	local codeToParse = data.customFunctionVariant == 1 and custom1Code or custom2Code
	local astScope = ast.body.scope
	local funcDeclNode = parser:parse(codeToParse).body.statements[1]
	local funcBody = funcDeclNode.body
	local funcArgs = funcDeclNode.args
	funcBody.scope:setParent(astScope)
	
	return Ast.LocalVariableDeclaration(astScope, {data.customFuncId}, {Ast.FunctionLiteralExpression(funcArgs, funcBody)})
end

function SplitStrings:variant()
	return math.random(1, customVariants)
end

function SplitStrings:apply(ast, pipeline)
	local data = {}
	
	if self.ConcatenationType == "table" then
		local scope = ast.body.scope
		local id = scope:addVariable()
		data.tableConcatScope = scope
		data.tableConcatId = id
	elseif self.ConcatenationType == "custom" then
		data.customFunctionType = self.CustomFunctionType
		if data.customFunctionType == "global" then
			local scope = ast.body.scope
			local id = scope:addVariable()
			data.customFuncScope = scope
			data.customFuncId = id
			data.customFunctionVariant = self:variant()
		end
	end
	
	local customLocalFunctionsCount = self.CustomLocalFunctionsCount
	
	visitAst(ast, function(node, data) 
		-- Previsit Function
		
		-- Create Local Function declarations
		if self.ConcatenationType == "custom" and data.customFunctionType == "local" and node.kind == Ast.AstKind.Block and node.isFunctionBlock then
			data.functionData.localFunctions = {}
			for i = 1, customLocalFunctionsCount do
				local scope = data.scope
				local id = scope:addVariable()
				local variant = self:variant()
				table.insert(data.functionData.localFunctions, {
					scope = scope,
					id = id,
					variant = variant,
					used = false,
				})
			end
		end

		-- Move string chunking logic here, so we can properly skip traversing the generated chunks
		if node.kind == Ast.AstKind.StringExpression and math.random() <= self.Treshold then
			local str = node.value
			local strLen = #str
			local chunks = {}
			local i = 1
			
			-- Split String into Parts of length between MinLength and MaxLength
			while i <= strLen do
				local len = math.random(self.MinLength, self.MaxLength)
				table.insert(chunks, string.sub(str, i, i + len - 1))
				i = i + len
			end
			
			if #chunks > 1 then
				if self.ConcatenationType == "strcat" then
					node = generateStrCatNode(chunks)
				elseif self.ConcatenationType == "table" then
					node = generateTableConcatNode(chunks, data)
				elseif self.ConcatenationType == "custom" then
					if self.CustomFunctionType == "global" then
						local args = generateCustomNodeArgs(chunks, data, data.customFunctionVariant)
						data.scope:addReferenceToHigherScope(data.customFuncScope, data.customFuncId)
						node = Ast.FunctionCallExpression(Ast.VariableExpression(data.customFuncScope, data.customFuncId), args)
					elseif self.CustomFunctionType == "local" then
						local lfuncs = data.functionData.localFunctions
						local idx = math.random(1, #lfuncs)
						local func = lfuncs[idx]
						local args = generateCustomNodeArgs(chunks, data, func.variant)
						func.used = true
						data.scope:addReferenceToHigherScope(func.scope, func.id)
						node = Ast.FunctionCallExpression(Ast.VariableExpression(func.scope, func.id), args)
					elseif self.CustomFunctionType == "inline" then
						local variant = self:variant()
						local args = generateCustomNodeArgs(chunks, data, variant)
						local literal = generateCustomFunctionLiteral(data.scope, variant)
						node = Ast.FunctionCallExpression(literal, args)
					end
				end
			end
			
			return node, true -- true to skip traversing the newly generated concatenation AST nodes
		end
		
	end, function(node, data)
		-- PostVisit Function
		
		-- Create actual function literals for local customFunctionType
		if self.ConcatenationType == "custom" and data.customFunctionType == "local" and node.kind == Ast.AstKind.Block and node.isFunctionBlock then
			for _, func in ipairs(data.functionData.localFunctions) do
				if func.used then
					local literal = generateCustomFunctionLiteral(func.scope, func.variant)
					table.insert(node.statements, 1, Ast.LocalVariableDeclaration(func.scope, {func.id}, {literal}))
				end
			end
		end
		
	end, data)
	
	if self.ConcatenationType == "table" then
		local globalScope = data.globalScope
		local tableScope, tableId = globalScope:resolve("table")
		ast.body.scope:addReferenceToHigherScope(globalScope, tableId)
		table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(data.tableConcatScope, {data.tableConcatId}, 
		{Ast.IndexExpression(Ast.VariableExpression(tableScope, tableId), Ast.StringExpression("concat"))}))
	elseif self.ConcatenationType == "custom" and self.CustomFunctionType == "global" then
		table.insert(ast.body.statements, 1, generateGlobalCustomFunctionDeclaration(ast, data))
	end
end

return SplitStrings
