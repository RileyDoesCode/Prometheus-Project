-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- cli.lua
-- Contains the code for the Prometheus CLI

--------------------------------------------------
-- Configure package.path for requiring Prometheus
--------------------------------------------------

local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*[/%\\])")
end

package.path = script_path() .. "?.lua;" .. package.path

---@diagnostic disable-next-line: different-requires
local Prometheus = require("prometheus")
Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Info

--------------------------------------------------
-- Utility functions
--------------------------------------------------

local function file_exists(file)
    local f = io.open(file, "rb")
    if f then
        f:close()
    end
    return f ~= nil
end

function string.split(str, sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)

    str:gsub(pattern, function(c)
        fields[#fields + 1] = c
    end)

    return fields
end

local function lines_from(file)
    if not file_exists(file) then
        return {}
    end

    local lines = {}

    for line in io.lines(file) do
        lines[#lines + 1] = line
    end

    return lines
end

--------------------------------------------------
-- CLI state
--------------------------------------------------

local config
local sourceFile
local outFile
local luaVersion
local prettyPrint

Prometheus.colors.enabled = true

--------------------------------------------------
-- Argument parsing
--------------------------------------------------

local i = 1

while i <= #arg do
    local curr = arg[i]

    if curr:sub(1, 2) == "--" then

        --------------------------------------------------
        -- Preset
        --------------------------------------------------

        if curr == "--preset" or curr == "--p" then
            if config then
                Prometheus.Logger:warn("The config was set multiple times")
            end

            i = i + 1

            local preset = Prometheus.Presets[arg[i]]

            if not preset then
                Prometheus.Logger:error(
                    string.format("A Preset with the name \"%s\" was not found!", tostring(arg[i]))
                )
            end

            config = preset

        --------------------------------------------------
        -- Config file
        --------------------------------------------------

        elseif curr == "--config" or curr == "--c" then
            i = i + 1

            local filename = tostring(arg[i])

            if not file_exists(filename) then
                Prometheus.Logger:error(
                    string.format("The config file \"%s\" was not found!", filename)
                )
            end

            local content = table.concat(lines_from(filename), "\n")

            local func = loadstring(content)

            -- sandbox
            setfenv(func, {})

            config = func()

        --------------------------------------------------
        -- Output file
        --------------------------------------------------

        elseif curr == "--out" or curr == "--o" then
            i = i + 1

            if outFile then
                Prometheus.Logger:warn("The output file was specified multiple times!")
            end

            outFile = arg[i]

        --------------------------------------------------
        -- Misc options
        --------------------------------------------------

        elseif curr == "--nocolors" then
            Prometheus.colors.enabled = false

        elseif curr == "--Lua51" then
            luaVersion = "Lua51"

        elseif curr == "--LuaU" then
            luaVersion = "LuaU"

        elseif curr == "--pretty" then
            prettyPrint = true

        --------------------------------------------------
        -- Save errors option
        --------------------------------------------------

        elseif curr == "--saveerrors" then
            Prometheus.Logger.errorCallback = function(...)
                print(Prometheus.colors(Prometheus.Config.NameUpper .. ": " .. ..., "red"))

                local args = {...}
                local message = table.concat(args, " ")

                local fileName =
                    sourceFile:sub(-4) == ".lua"
                    and sourceFile:sub(1, -5) .. ".error.txt"
                    or sourceFile .. ".error.txt"

                local handle = io.open(fileName, "w")

                handle:write(message)
                handle:close()

                os.exit(1)
            end

        else
            Prometheus.Logger:warn(
                string.format("The option \"%s\" is not valid and therefore ignored", curr)
            )
        end

    else
        if sourceFile then
            Prometheus.Logger:error(
                string.format("Unexpected argument \"%s\"", arg[i])
            )
        end

        sourceFile = tostring(arg[i])
    end

    i = i + 1
end

--------------------------------------------------
-- Validation
--------------------------------------------------

if not sourceFile then
    Prometheus.Logger:error("No input file was specified!")
end

if not config then
    Prometheus.Logger:warn("No config was specified, falling back to Minify preset")
    config = Prometheus.Presets.Minify
end

config.LuaVersion = luaVersion or config.LuaVersion
config.PrettyPrint = prettyPrint ~= nil and prettyPrint or config.PrettyPrint

if not file_exists(sourceFile) then
    Prometheus.Logger:error(
        string.format("The File \"%s\" was not found!", sourceFile)
    )
end

--------------------------------------------------
-- Determine output file
--------------------------------------------------

if not outFile then
    if sourceFile:sub(-4) == ".lua" then
        outFile = sourceFile:sub(1, -5) .. ".obfuscated.lua"
    else
        outFile = sourceFile .. ".obfuscated.lua"
    end
end

--------------------------------------------------
-- Run pipeline
--------------------------------------------------

local source = table.concat(lines_from(sourceFile), "\n")

local pipeline = Prometheus.Pipeline:fromConfig(config)

local out = pipeline:apply(source, sourceFile)

Prometheus.Logger:info(
    string.format("Writing output to \"%s\"", outFile)
)

--------------------------------------------------
-- Write output
--------------------------------------------------

local handle = io.open(outFile, "w")

handle:write(out)

handle:close()
