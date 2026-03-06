-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- test.lua
-- Performs tests using all Lua files inside the ./tests directory

-- Require Prometheus
local Prometheus = require("src.prometheus")

-- Enable Debugging
-- Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Debug

---------------------------------------------------------------------
-- Configuration
---------------------------------------------------------------------

local noColors       = false  -- Disable ANSI colors in console output
local isWindows      = true   -- Determines if tests run on Windows or Linux
local ciMode         = false  -- CI mode: throw error when tests fail
local iterationCount = 20     -- Number of executions per test/preset

---------------------------------------------------------------------
-- Parse CLI Arguments
---------------------------------------------------------------------

for _, currArg in pairs(arg) do
	if currArg == "--Linux" then
		isWindows = false
	end

	if currArg == "--CI" then
		ciMode = true
	end

	local iterationValue = currArg:match("^%-%-iterations=(%d+)$")
	if iterationValue then
		iterationCount = math.max(tonumber(iterationValue), 1)
	end
end

---------------------------------------------------------------------
-- Prometheus Setup
---------------------------------------------------------------------

Prometheus.colors.enabled = not noColors

local pipeline = Prometheus.Pipeline:new({
	Seed = 0,          -- 0 = use time as seed
	VarNamePrefix = "" -- No custom prefix
})

-- Name generators:
-- Mangled           -> a, b, c...
-- MangledShuffled   -> shuffled characters (recommended)
-- Il                -> IlIIl1llI11l1 style
-- Number            -> _1, _2 (not recommended)
pipeline:setNameGenerator("MangledShuffled")

---------------------------------------------------------------------
-- Utility Functions
---------------------------------------------------------------------

local function describePlatform()
	return isWindows and "Windows" or "Linux"
end

local function scandir(directory)
	local files = {}
	local popen = io.popen

	local command = isWindows
		and ('dir "' .. directory .. '" /b')
		or ('ls -a "' .. directory .. '"')

	local pfile = popen(command)

	for filename in pfile:lines() do
		if filename:sub(-4) == ".lua" then
			files[#files + 1] = filename
		end
	end

	pfile:close()
	return files
end

local function shallowcopy(orig)
	if type(orig) ~= "table" then
		return orig
	end

	local copy = {}
	for k, v in pairs(orig) do
		copy[k] = v
	end

	return copy
end

local function validate(a, b)
	local outa = ""
	local outb = ""

	local enva = shallowcopy(getfenv(a))
	local envb = shallowcopy(getfenv(b))

	enva.print = function(...)
		for _, v in ipairs({...}) do
			outa = outa .. tostring(v)
		end
	end

	envb.print = function(...)
		for _, v in ipairs({...}) do
			outb = outb .. tostring(v)
		end
	end

	setfenv(a, enva)
	setfenv(b, envb)

	if not pcall(a) then
		error("Expected Reference Program not to Fail!")
	end

	if not pcall(b) then
		return false, outa, nil
	end

	return outa == outb, outa, outb
end

---------------------------------------------------------------------
-- Test Execution
---------------------------------------------------------------------

print(string.format(
	"Performing Prometheus Tests (iterations=%d per file/preset, platform=%s)...",
	iterationCount,
	describePlatform()
))

local presets  = Prometheus.Presets
local testdir  = "./tests/"
local failures = 0

Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Error

for _, filename in ipairs(scandir(testdir)) do
	local path = testdir .. filename
	local file = io.open(path, "r")

	local code = file:read("*a")
	print(Prometheus.colors("[CURRENT] ", "magenta") .. filename)

	for name, preset in pairs(presets) do

		-- Remove AntiTamper step for tests
		for i = #preset.Steps, 1, -1 do
			if preset.Steps[i].Name == "AntiTamper" then
				table.remove(preset.Steps, i)
			end
		end

		for iteration = 1, iterationCount do
			pipeline = Prometheus.Pipeline:fromConfig(preset)

			local obfuscated = pipeline:apply(code)

			local funca = loadstring(code)
			local funcb = loadstring(obfuscated)

			if not funcb then
				print(Prometheus.colors("[FAILED]  ", "red") ..
					"(" .. filename .. "): " .. name .. ", Invalid Lua!")
				print("[SOURCE]", obfuscated)

				failures = failures + 1
			else
				local validated, outa, outb = validate(funca, funcb)

				if not validated then
					print(Prometheus.colors("[FAILED]  ", "red") ..
						"(" .. filename .. "): " .. name)

					print("[OUTA]    ", outa)
					print("[OUTB]    ", outb)
					print("[SOURCE]", obfuscated)

					failures = failures + 1
				end
			end
		end
	end

	file:close()
end

---------------------------------------------------------------------
-- Final Result
---------------------------------------------------------------------

if failures < 1 then
	print(Prometheus.colors("[PASSED]  ", "green") .. "All tests passed!")
	return 0
else
	print(Prometheus.colors("[FAILED]  ", "red") .. "Some tests failed!")

	if ciMode then
		error("Test Failed!")
	end

	return -1
end
