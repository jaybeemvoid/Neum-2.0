--!strict

local globalData = require("../globalData")
local types = require("../types")

local Pointer = {}
Pointer.__index = Pointer

function Pointer.new<T>(initialValue : T) : types.Pointer<T>
	local self = setmetatable({}, Pointer)

	self.__type = "Pointer"
	self._value = initialValue

	if globalData.currentActiveScope then
		globalData.currentActiveScope:__register(self)
	end

	return (self :: any) :: types.Pointer<T>
end

function Pointer:Get()
	return self._value
end

function Pointer:Set(newValue) : ()
	self._value = newValue :: unknown
end

function Pointer:Destroy() : ()
	self._value = nil
	self.__type = nil
	setmetatable(self, nil)
end

return Pointer
