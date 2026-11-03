--!strict

local Core = script.Core
local types = Core.Parent.types

local Objects = script.Objects
local Utils = script.Utils

local Memory = Objects.Memory

local Create = require(Core.Create)
local Derive = require(Core.Derive)
local Dependency = require(Core.Dependency)
local Component = require(Core.Component)

local Scope = require(Memory.Scope)

local Batch = require(Utils.Batch).batch

local Pointer = require(Objects.Pointer)

local Unmut = require(Utils.Unmut)

local reveal = require(Utils.Reveal)
local case = require(Utils.Case)
local cleanup = require(Utils.Cleanup)

local cprops = require(Utils.CustomProp)

local globalData = require("@self/globalData")

local neum = {
	version = { Major = 0, Minor = 1, Patch = 0 },

	create = Create,
	component = Component,

	app = Scope.new,
	dependency = Dependency.new,
	derive = Derive,
	tween = require(Objects.Tween),

	batch = Batch,
	reveal = reveal,
	case = case,
	cleanup = cleanup,
	cprops = cprops,
	unmut = Unmut,
}

return setmetatable(neum, {
	__index = function(_, key)
		if key == "debug" then
			return globalData.debug
		elseif key == "optimize" then
			return globalData.optimize
		end
		return false
	end,
	__newindex = function(self, key, value)
		if key == "debug" then
			globalData.debug = value
		elseif key == "optimize" then
			globalData.optimize = value
		else
			rawset(self, key, value)
		end
	end,
})