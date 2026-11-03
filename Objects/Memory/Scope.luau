--!strict
local globalData = require("../../globalData")
local types = require("../../types")

local insert = table.insert
local remove = table.remove

local typeof_func = typeof

local scope = {}
scope.__index = scope

function scope.new(fn: (() -> Instance)?) : types.Scope
	local self = setmetatable({
		__type = "Scope",
		_childScopes = {},
		_parentScope = nil,
		_cleanups = {},
	}, scope) :: types.InternalScope
	
	if fn then
		globalData.currentActiveScope = (self :: any)
		local rootComponent = fn()
		if typeof(rootComponent) == "Instance" then
			insert(self._cleanups, function()
				rootComponent:Destroy()
			end)
		end
		globalData.currentActiveScope = nil
	end

	return (self :: any) :: types.Scope
end

function scope:newSubScope() : types.Scope
	local activeScope: types.InternalScope? = globalData.currentActiveScope
	local subScope = scope.new() :: types.InternalScope;
	subScope._parentScope = activeScope;
	(activeScope :: types.InternalScope)._childScopes[subScope] = true
	--insert((activeScope :: any)._childScopes, subScope)
	return subScope
end

function scope:__register(object : Instance | types.ValueStream<unknown> | types.Dependency<unknown> | RBXScriptConnection | () -> ())
	--[[
		_NOTE_:
		children of a component root frame aren't assigned to the sub-scope
		because if the scope is freed the root frame will be freed too and so all
		children will be freed as well
		
		the dependencies and derives are already handled automatically
	]]
	
	local type_obj = typeof_func(object)
	
	if type_obj == "RBXScriptConnection" then
		insert(self._cleanups, function()
			((object :: any) :: RBXScriptConnection):Disconnect()
		end)
	elseif type_obj == "Instance" or type_obj == "table" then
		insert(self._cleanups, function()
			((object :: any) :: Instance):Destroy()
		end)
	elseif type_obj == "function" then
		insert((self._cleanups :: {
		RBXScriptConnection | () -> ()	
		}), (object :: () -> ()))
	end
end

function scope:Clear()
	local self = self :: types.InternalScope
	
	local parent = self._parentScope :: types.InternalScope
	if parent and parent._childScopes then
		
		parent._childScopes[self] = nil
	end
	
	self._parentScope = nil 
	
	for _, cleanup in self._cleanups do
		(cleanup :: () -> ())()
	end
	table.clear(self._cleanups)
	
	local childScopes = self._childScopes
	local childScope = next(childScopes)

	while childScope ~= nil do
		childScopes[childScope] = nil 

		(childScope :: types.Scope):Clear() 

		childScope = next(childScopes)
	end
	
	self = self :: any
	
	self._cleanups = nil
	self.__type = nil
	self._childScopes = nil

	setmetatable(self, nil)
end

return scope