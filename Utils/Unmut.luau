--!strict
local globalData = require(script.Parent.Parent.globalData)
local types = require("../types")

return function<T>(
	obj : types.Dependency<T>
)
	local internalObj = (obj :: any) :: types.InternalDependency<unknown>

	if internalObj._immutable_ref then
		return (internalObj._immutable_ref :: any) :: types.Unmutref<T>
	end

	local unmutRef = {}
	unmutRef.__index = function(self, key)
		if key == "Set" then
			return nil
		else
			return internalObj[key]
		end
	end

	unmutRef.__call = function()
		if globalData.currentContext then
			return if internalObj.Get then internalObj:Get() else internalObj:get()
		else
			return if internalObj.Peek then internalObj:Peek() else internalObj:peek()
		end
	end

	local mirror = setmetatable({}, unmutRef)

	internalObj._immutable_ref = mirror

	return (mirror :: any) :: types.Unmutref<T>
end
