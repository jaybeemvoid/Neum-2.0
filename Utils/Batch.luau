--!strict
local types = require("../types")

local exports = {}
exports.isBatching = false
exports.batchedUpdatesQueue = {}

function exports.batch(callback : () -> ())
	exports.isBatching = true
	
	callback()
	
	exports.isBatching = false
	
	local stream = (next(exports.batchedUpdatesQueue) :: any) :: types.InternalValueStream<unknown>
	while stream do
		--[[ MIGHT CAUSE BUGS ]]
		exports.batchedUpdatesQueue[stream] = nil
		
		((stream :: any) :: types.InternalValueStream<unknown>):run(0)
		
		stream = (next(exports.batchedUpdatesQueue) :: any) :: types.InternalValueStream<unknown>
	end
	
	table.clear(exports.batchedUpdatesQueue)
end

return exports
