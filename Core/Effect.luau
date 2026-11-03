--!strict
local globalData = require("../globalData")

local Logger = require("../Tools/Logger")

local effect = {}
effect.__index = effect

function effect.new(callback : () -> ())
	local self = setmetatable({}, effect)
	
	self.__type = "Effect"
	self.callback = callback
	self._scope = nil
	
	if globalData.currentActiveScope then
		globalData.currentActiveScope:__register(self)
		self._scope = globalData.currentActiveScope
	end
	
	return self
end

function effect:run()
	local cachedContext = globalData.currentContext
	local cachedScope = globalData.currentActiveScope
	globalData.currentContext = self
	globalData.currentActiveScope = self._scope
	
	if globalData.debug then
		local sucess, _ = pcall(self.callback)
		globalData.currentContext = cachedContext
		globalData.currentActiveScope = cachedScope
		if not sucess then
			Logger("invalidEffectCallback")
		end
	else
		self.callback()
		globalData.currentContext = cachedContext
		globalData.currentActiveScope = cachedScope
	end
end

function effect:Destroy()
	self.callback = nil
	self.__type = nil
	self._scope = nil
end

return effect