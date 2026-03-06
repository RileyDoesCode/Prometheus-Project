-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- step.lua
--
-- This file Provides the base class for Obfuscation Steps

local logger = require("logger")
local util = require("prometheus.util")

local lookupify = util.lookupify

local Step = {}

Step.SettingsDescriptor = {}
Step.Name = "Abstract Step"
Step.Description = "Abstract Step"

function Step:new(settings)
	local instance = {}
	setmetatable(instance, self)
	self.__index = self
	
	settings = type(settings) == "table" and settings or {}
	
	for key, data in pairs(self.SettingsDescriptor) do
		local val = settings[key]
		
		if val == nil then
			if data.default == nil then
				logger:error(string.format("The Setting \"%s\" was not provided for the Step \"%s\"", key, self.Name))
			end
			instance[key] = data.default
		else
			if data.type == "enum" then
				local lookup = lookupify(data.values)
				if not lookup[val] then
					logger:error(string.format("Invalid value for the Setting \"%s\" of the Step \"%s\". It must be one of the following: %s", key, self.Name, table.concat(data.values, ", ")))
				end
				instance[key] = val
			elseif type(val) ~= data.type then
				logger:error(string.format("Invalid value for the Setting \"%s\" of the Step \"%s\". It must be a %s", key, self.Name, data.type))
			else
				if data.min and val < data.min then
					logger:error(string.format("Invalid value for the Setting \"%s\" of the Step \"%s\". It must be at least %d", key, self.Name, data.min))
				end
				
				if data.max and val > data.max then
					logger:error(string.format("Invalid value for the Setting \"%s\" of the Step \"%s\". The biggest allowed value is %d", key, self.Name, data.max))
				end
				
				instance[key] = val
			end
		end
	end
	
	instance:init()

	return instance
end

function Step:init()
	logger:error("Abstract Steps cannot be Created")
end

function Step:extend()
	local ext = {}
	setmetatable(ext, self)
	self.__index = self
	return ext
end

function Step:apply(ast, pipeline)
	logger:error("Abstract Steps cannot be Applied")
end

return Step
