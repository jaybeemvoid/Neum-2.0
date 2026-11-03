--!strict
local globalData = require("../globalData")

local types = require("../types")
local Logger = require("../Tools/Logger")

const cp_symbol = "__neum_cprop"

local cprops = {}

type insertMultiArg = {
	type: string,
	execute: (instance: Instance, activeScope: types.Scope, arg1: any, arg2: any) -> (),
}

function cprops.insertMutliArg(cp_name: string, callback: (instance : Instance, activeScope: types.Scope, arg1: any, arg2: any) -> ())
	cprops[cp_name] = function(arg1)
		return function(arg2)
			return {
				type = cp_symbol,
				execute = function(instance : Instance)
					callback(instance, globalData.currentActiveScope :: any, arg1, arg2)
				end,
			} :: insertMultiArg
		end
	end
end

type insertSingleArg = {
	type: string,
	execute: (instance: Instance, activeScope: types.Scope) -> (),
}

function cprops.insertSingleArg(cp_name: string, callback: (instance : Instance, activeScope : types.Scope, arg : types.Dependency<unknown>) -> ())
	cprops[cp_name] = function(arg1)
		return {
			type = cp_symbol,
			execute = function(instance: Instance, activeScope: types.Scope)
				callback(instance, activeScope, arg1)
			end
		} :: insertSingleArg
	end
end

cprops.insertMutliArg("bindProp", function(instance : Instance, scope : types.Scope, propName : string, dep : types.Dependency<unknown>)
	if not scope then Logger("noActiveScope", "") end
	((scope :: any) :: types.InternalScope):__register(
		instance:GetPropertyChangedSignal(propName):Connect(function()
			dep:Set((instance :: any)[propName])
		end)
	)
end)

cprops.insertMutliArg("bindAtt", function(instance: Instance, scope: types.Scope, attName: string, dep: types.Dependency<unknown>)
	if not scope then Logger("noActiveScope", "") end
	((scope :: any) :: types.InternalScope):__register(
		instance:GetAttributeChangedSignal(attName):Connect(function()
			local currentVal = instance:GetAttribute(attName)
			dep:Set(currentVal)
		end)
	)
end)

type attribute_value = string | boolean | number | UDim | UDim2 | CFrame | BrickColor | Color3 | Vector2 | Vector3 | NumberSequence | NumberRange | Rect | Font | Instance

cprops.insertMutliArg("setAtt", function(instance : Instance, scope : types.Scope, attName : string, value : attribute_value)
	if not scope then Logger("noActiveScope", "") end
	if globalData.debug and instance:GetAttribute(attName) then
		Logger("attributeExists")
		return
	end
	instance:SetAttribute(attName, value)
end)

cprops.insertSingleArg("getInstance", function(instance : Instance, scope : types.Scope, dep: types.Dependency<unknown>)
	if not scope then Logger("noActiveScope", "") end
	dep:Set(instance :: any)
end)

cprops.insertSingleArg("getScope", function
(
	_ : Instance,
	scope : types.Scope,
	state: types.Dependency<unknown>
)
	if not scope then Logger("noActiveScope", "Sub-scope doesn't exist") end
	state:Set(scope :: any)
end)

return cprops