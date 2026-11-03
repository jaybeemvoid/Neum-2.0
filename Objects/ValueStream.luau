--!strict
local globalData = require("../globalData")

local Logger = require("../Tools/Logger")

local insert = table.insert

local valueStream = {}
valueStream.__index = valueStream

local types = require(script.Parent.Parent.types)

function valueStream.new<T>(executeFn : () -> T)
	local self = (setmetatable({
		__type = "ValueStream",
		_fn = executeFn,
		_dependants = {},
		_dependOn = {},
		_value = nil,
		_uiUpdates = {},
		_scope = nil,
	}, valueStream) :: any) :: types.InternalValueStream<T>
	
	if globalData.currentActiveScope then
		globalData.currentActiveScope:__register(self)
		self._scope = globalData.currentActiveScope
	end
	
	return (self :: any) :: types.ValueStream<T>
end

function valueStream:run(traits : number) : ()
	local self = (self :: any) :: types.InternalValueStream<unknown>
	
	local cachedContext = globalData.currentContext
	globalData.currentContext = (self :: any)
	
	local cachedScope = globalData.currentActiveScope
	
	globalData.currentActiveScope = (self._scope :: any)
	
	local newValue = self._fn()
	
	if typeof(newValue) == "Instance" and bit32.band(traits, globalData.__trait_internal) == 0 then
		Logger("attemptToDeriveInstances", typeof(newValue))
	end
	
	globalData.currentActiveScope = cachedScope
	globalData.currentContext = cachedContext
	
	if newValue == self._value then 
		return
	end

	self._value = newValue
	
	if bit32.band(traits, globalData.__trait_silent) ~= 0 then
		for dependant in self._dependants do
			self:evaluate(dependant)
		end
	end
	
	for i = 1, #self._uiUpdates do
		(self._uiUpdates[i] :: (newVal : unknown) -> ())(newValue)
	end
end

function valueStream:evaluate(node : types.ValueStream<unknown>)
	(node :: types.InternalValueStream<unknown>):run(0)
end

function valueStream:__register(stream : types.ValueStream<unknown>)
	if not self._dependants[stream] then
		self._dependants[stream] = true
	end
end

function valueStream:Get()
	local self = (self :: any) :: types.InternalValueStream<unknown>
	
	local activeStream = (globalData.currentContext :: any) :: types.InternalValueStream<unknown>
	if not activeStream then Logger("noActiveDerive") end
	self:__register(activeStream)
	return self._value
end

function valueStream:Peek()
	local self = (self :: any) :: types.InternalValueStream<unknown>
	return self._value
end

function valueStream:listen(callback)
	local self = (self :: any) :: types.InternalValueStream<unknown>
	insert(self._uiUpdates, callback)
end

function valueStream:__getScope()
	local self = (self :: any) :: types.InternalValueStream<unknown>
	return self._scope
end

function valueStream:Destroy()
	local self = (self :: any) :: types.InternalValueStream<unknown>
	
	if next(self._dependOn) then
		for dep in self._dependOn do
			dep = (dep :: any) :: types.InternalDependency<unknown>
			dep._dependants[self] = nil
		end
	end
	
	self._value = nil
	
	self = self :: any
	
	self._dependants = nil
	self._fn = nil
	self.__type = nil
	self._scope = nil
	
	setmetatable(self, nil)
end

return valueStream