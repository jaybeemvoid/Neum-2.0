--!strict

local types = require("../types")
local globalData = require("../globalData")

local derive = require("../Core/Derive")
local component = require("../Core/Component")

local Logger = require("../Tools/Logger")

return function(dependency: types.Dependency<boolean>, target: any)
	if not dependency then Logger("noDependencyProvided") end
	dependency = (dependency :: any) :: types.InternalDependency<boolean>
	dependency:_addTrait(globalData.__trait_internal)

	local currentInstance: Instance?
	
	local cached = (component(target) :: any) :: () -> Instance
	
	return derive(function()
		local isVisible = dependency:Get()

		if isVisible then
			if not currentInstance then
				currentInstance = cached()
				
				return currentInstance
			else
				return nil
			end
		else
			if currentInstance then
				local subScope = (globalData.componentScopes :: {[Instance] : types.Scope})[currentInstance] :: types.InternalScope
				if not subScope then Logger("noActiveScope", "") end
				subScope:Clear()
				currentInstance = nil
			end
			return nil
		end
	end)
end