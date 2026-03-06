-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- namegenerators/number.lua
--
-- This Script provides a function for the generation of simple up-counting names using hex numbers

return function(id, scope)
	-- Format as a lowercase hexadecimal string with a leading underscore (e.g., _a, _1f, _2b)
	return string.format("_%x", id)
end
