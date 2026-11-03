--!strict
local globalData = require(script.Parent.Parent.globalData)
local valueStream = require("../Objects/ValueStream").new

local types = require("../types")

return function
	<T>(executeFn : () -> T?, _internalTraits : number?) : types.ValueStream<T>
	local stream: any = valueStream(executeFn)
	--[[
		eager evaluate with traits of 0
	]]
		stream:run(_internalTraits or globalData.__trait_silent)
	return (stream :: any ) :: types.ValueStream<T>
end
