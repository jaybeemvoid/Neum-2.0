--!strict
local globalData = require("../globalData")

local applyProperties = require("@self/ApplyProperties")
local types = require("../types")

local Logger = require("../Tools/Logger")

local Instance_new = Instance.new

local instance_cache: types.Map<string, (types.Props<string, unknown>) -> Instance> = {}

local function invalidClassFallback(properties: types.Props<string, unknown>?)
	return Instance_new("Frame")
end

local function create(className: string)
	local cachedBlueprint = instance_cache[className]
	if cachedBlueprint then
		return cachedBlueprint
	end
	
	if globalData.debug then
		local safetyCheck, inst = pcall(Instance_new, className)
		if not safetyCheck then
			Logger("invalidClass", `value: {className}`)
			instance_cache[className] = invalidClassFallback
			return invalidClassFallback
		else
			inst:Destroy()
		end
	end

	local function instantiate(properties : types.Props?)
		local instance = Instance_new(className)
		
		if properties ~= nil then
			applyProperties(properties, instance)
		end

		return instance
	end

	instance_cache[className] = instantiate
	return instantiate
end

return create :: types.CreateFn