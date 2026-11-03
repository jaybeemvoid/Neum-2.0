--!strict
local globalData = require("../globalData")

local Logger = require("../Tools/Logger")
local types = require("../types")

return function(callback : () -> ())
	local currentActiveScope = (globalData.currentActiveScope :: any) :: types.InternalScope
	if not currentActiveScope then Logger("noActiveScope", "No scope is found") end
	currentActiveScope:__register(callback)
end