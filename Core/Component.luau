--!strict

local globalData = require("../globalData")

local types = require("../types")
local Logger = require("../Tools/Logger")

--wrapper around instance creation + scope creation
--creates an instance with all its trackable objects within
--a scope called a subscope
local function construct(callback: (types.Props<string, any>) -> Instance)
	if typeof(callback) == "table" and (callback :: any).__type == "Component" then
		return callback :: any
	end

	return setmetatable({
		__type = "Component",
	}, {
		__call = function(_, props: types.Props<string, any>, ...)
			local activeScope: types.Scope = (globalData.currentActiveScope :: any) :: types.Scope
			if not activeScope then
				Logger("noActiveScope", "Components have to be created inside a scope")
			end

			local subScope = (activeScope :: any):newSubScope()
			local prevActiveScope = activeScope
			globalData.currentActiveScope = subScope

			local instance = nil
			if globalData.debug then
				local success, inst: (Instance | string) = pcall(callback :: any, props)
				if not success then
					subScope:Clear()
					Logger("failedComponentCreation", tostring(inst))
				end
				instance = inst
			else
				instance =  (callback :: (props : { [string] : any }) -> ())(props)
			end

			globalData.currentActiveScope = (prevActiveScope :: any)

			subScope:__register(instance)

			local conn
			--should've used weaktables here instead of a specific event
			--but they do not work with instances
			
			--this is responsible for cleaning up the component
			--from the lookup array after being destroyed
			conn = ((instance :: any) :: Instance):GetPropertyChangedSignal("Parent"):Connect(function()
				if not ((instance :: any) :: Instance).Parent then
					(globalData.componentScopes :: {[Instance] : types.Scope})[instance] = nil
					(conn :: RBXScriptConnection):Disconnect()
				end
			end);
			
			(globalData.componentScopes :: {[Instance] : types.Scope})[(instance :: any)] = subScope
			return instance
		end,
	}) 
end

return construct :: types.Component_Constructor