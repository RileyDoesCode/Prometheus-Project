-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- Vmify.lua
--
-- This Script provides a Complex Obfuscation Step that will compile the entire script to a fully custom bytecode that does not share its instructions
-- with Lua, making it much harder to crack than other Lua obfuscators.

local Step = require("prometheus.step")
local Compiler = require("prometheus.compiler.compiler")

local Vmify = Step:extend()
Vmify.Description = "This Step will Compile your script into a fully-custom (not half-custom like other Lua obfuscators) Bytecode Format and emit a VM for executing it."
Vmify.Name = "Vmify"

Vmify.SettingsDescriptor = {}

function Vmify:init(settings)
	-- No initialization needed
end

function Vmify:apply(ast, pipeline)
	-- Create Compiler
	local compiler = Compiler:new()
	
	-- Compile the Script into a bytecode VM
	return compiler:compile(ast)
end

return Vmify
