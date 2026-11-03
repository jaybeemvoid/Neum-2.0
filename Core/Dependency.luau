--!strict
local batch = require("../Utils/Batch")
local globalData = require("../globalData")
local types = require("../types")

local Logger = require("../Tools/Logger")

local insert = table.insert

local Dependency = {}
Dependency.__index = Dependency

function Dependency.new<T>
(
	initialValue : T
) : types.Dependency<T>
	
	local self = (setmetatable({
		__type = "Dependency",
		_dependants = {},
		_value = initialValue,
		_traits = globalData.__trait_silent,
		_immutable_ref = nil
	}, Dependency) :: any) :: types.InternalDependency<T>
	
	if globalData.currentActiveScope then
		globalData.currentActiveScope:__register(self)
	end
	
	return (self :: any) :: types.Dependency<T>
end

function Dependency:_addTrait(trait : number)
	self._traits = bit32.bor(self._traits, trait)
end

function Dependency:Get()
	local activeStream = (globalData.currentContext :: any) :: types.InternalValueStream<unknown>
	if not activeStream then Logger("noActiveDerive") end
	if not self._dependants[activeStream] then
		self._dependants[activeStream] = true
	end
	return self._value
end

function Dependency:__call(val : unknown)
	if globalData.optimize then
		Logger("optimize_mode_callingState")
	end

	if val ~= nil then
		self:Set(val)
	else
		if globalData.currentContext then
			return self:Get()
		else
			return self:Peek()
		end
	end
end

function Dependency:Peek()
	return self._value
end

function Dependency:Set(newValue : (newValue: unknown) -> () | unknown) : ()
	if type(newValue) == "function" then
		local newValue = (newValue :: any)(self._value)
		if newValue == self._value then return end
	elseif type(newValue) == "table" and newValue.__type == "ValueStream" then
		Logger("valueStreamAsValueForDependency")
	else
		if newValue == self._value then return end
		self._value = newValue
	end
	if not next(self._dependants) then 
		return 
	end
	
	local orderedUpdates: {any} = {}
	local seen = {}
	
	--visit all dependant nodes recursively and
	--only insert nodes that are not duplicates
	
	-- B -> A
	-- C -> A
	-- D -> B & C
	-- A goes through its dependants and sees that B and C share the same listener
	-- it only adds it once because of the [seen] checks
	local function visit(node)
		if seen[node] then return end
		seen[node] = true
		
		for dependant in (node._dependants :: {[types.InternalValueStream<unknown>]: boolean}) do
			visit(dependant)
		end
		
		insert(orderedUpdates, 1, node)
	end
	
	for dependant in (self._dependants) do
		visit(dependant)
	end
	
	if batch.isBatching then
		local queue = batch.batchedUpdatesQueue
		for i = 1, #orderedUpdates do
			queue[orderedUpdates[i]] = (true :: any)
		end
	else
		for i = 1, #orderedUpdates do
			orderedUpdates[i]:run(self._traits)
		end
	end
end

function Dependency:Destroy()
	self._dependants = nil
	self._value = nil
	self.__type = nil
	setmetatable(self, nil)
end

return Dependency