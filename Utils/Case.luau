--!strict
local types = require("../types")

local globalData = require("../globalData")

local derive = require("../Core/Derive")
local component = require("../Core/Component")

local Logger = require("../Tools/Logger")

return function
(
	dependency: types.Dependency<unknown>, 
	cases : {[any] : () -> Instance}, 
	defCase : (() -> Instance)?
) : types.ValueStream<Instance?>?
	if not dependency then Logger("noDependencyProvided") end
	dependency = (dependency :: any) :: types.InternalDependency<unknown>
	dependency:_addTrait(globalData.__trait_internal)
	
	local currentInstance : Instance? = nil
	local cached = {}
	
	for key, target in cases do
		cached[key] = (component(target :: any)) :: () -> Instance
	end
	
	local fallback = defCase and (component((defCase :: any)) :: () -> Instance) or nil
	
	return derive(function()
		local activeKey = dependency:Get()
		
		local target = cached[activeKey] or fallback
		if target then
			if currentInstance then
				local subScope = (globalData.componentScopes :: {[Instance] : types.Scope})[currentInstance] :: types.InternalScope
				if not subScope then Logger("noActiveScope", "") end
	
				subScope:Clear()
				currentInstance = nil
			end
			
			currentInstance = ((target :: any) :: () -> Instance)()
			return currentInstance
		else
			if currentInstance then
				local subScope = (globalData.componentScopes :: {[Instance] : types.Scope})[currentInstance]
				if not subScope then Logger("noActiveScope", "") end
				subScope:Clear()
				currentInstance = nil
				return nil
			end
		end
		
		return nil
	end, globalData.__trait_internal)
end