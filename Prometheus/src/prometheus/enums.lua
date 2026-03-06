-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- enums.lua
-- This file Provides some enums used by the Obfuscator

local chararray = require("prometheus.util").chararray

local Enums = {}

Enums.LuaVersion = {
	LuaU  = "LuaU",
	Lua51 = "Lua51",
}

-- Cache shared constant tables to reduce memory footprint and module loading time
local sharedSymbolChars       = chararray("+-*/%^#=~<>(){}[];:,.")
local sharedIdentChars        = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789")
local sharedNumberChars       = chararray("0123456789")
local sharedHexNumberChars    = chararray("0123456789abcdefABCDEF")
local sharedBinaryNumberChars = {"0", "1"}
local sharedDecimalExponent   = {"e", "E"}
local sharedHexadecimalNums   = {"x", "X"}
local sharedBinaryNums        = {"b", "B"}

local sharedEscapeSequences = {
	["a"]  = "\a",
	["b"]  = "\b",
	["f"]  = "\f",
	["n"]  = "\n",
	["r"]  = "\r",
	["t"]  = "\t",
	["v"]  = "\v",
	["\\"] = "\\",
	["\""] = "\"",
	["\'"] = "\'",
}

-- Version-specific definitions
local lua51Keywords = {
	"and",    "break",  "do",    "else",     "elseif", 
	"end",    "false",  "for",   "function", "if",   
	"in",     "local",  "nil",   "not",      "or",
	"repeat", "return", "then",  "true",     "until",    "while"
}

local lua51Symbols = {
	"+",  "-",  "*",  "/",  "%",  "^",  "#",
	"==", "~=", "<=", ">=", "<",  ">",  "=",
	"(",  ")",  "{",  "}",  "[",  "]",
	";",  ":",  ",",  ".",  "..", "...",
}

local luauKeywords = {
	"and",    "break",  "do",    "else",     "elseif", "continue",
	"end",    "false",  "for",   "function", "if",   
	"in",     "local",  "nil",   "not",      "or",
	"repeat", "return", "then",  "true",     "until",    "while"
}

local luauSymbols = {
	"+",  "-",  "*",  "/",  "%",  "^",  "#",
	"==", "~=", "<=", ">=", "<",  ">",  "=",
	"+=", "-=", "/=", "%=", "^=", "..=", "*=",
	"(",  ")",  "{",  "}",  "[",  "]",
	";",  ":",  ",",  ".",  "..", "...",
	"::", "->", "?",  "|",  "&", 
}

Enums.Conventions = {
	[Enums.LuaVersion.Lua51] = {
		Keywords                    = lua51Keywords,
		SymbolChars                 = sharedSymbolChars,
		MaxSymbolLength             = 3,
		Symbols                     = lua51Symbols,

		IdentChars                  = sharedIdentChars,
		NumberChars                 = sharedNumberChars,
		HexNumberChars              = sharedHexNumberChars,
		BinaryNumberChars           = sharedBinaryNumberChars,
		DecimalExponent             = sharedDecimalExponent,
		HexadecimalNums             = sharedHexadecimalNums,
		BinaryNums                  = sharedBinaryNums,
		DecimalSeperators           = false,
		
		EscapeSequences             = sharedEscapeSequences,
		NumericalEscapes            = true,
		EscapeZIgnoreNextWhitespace = true,
		HexEscapes                  = true,
		UnicodeEscapes              = true,
	},
	[Enums.LuaVersion.LuaU] = {
		Keywords                    = luauKeywords,
		SymbolChars                 = sharedSymbolChars,
		MaxSymbolLength             = 3,
		Symbols                     = luauSymbols,

		IdentChars                  = sharedIdentChars,
		NumberChars                 = sharedNumberChars,
		HexNumberChars              = sharedHexNumberChars,
		BinaryNumberChars           = sharedBinaryNumberChars,
		DecimalExponent             = sharedDecimalExponent,
		HexadecimalNums             = sharedHexadecimalNums,
		BinaryNums                  = sharedBinaryNums,
		DecimalSeperators           = {"_"},
		
		EscapeSequences             = sharedEscapeSequences,
		NumericalEscapes            = true,
		EscapeZIgnoreNextWhitespace = true,
		HexEscapes                  = true,
		UnicodeEscapes              = true,
	},
}

return Enums
