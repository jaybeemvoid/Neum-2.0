--!strict

local LOGS = {
	invalidClass = `\n[Neum]:\ntype: WARNING\ncontent: Invalid className\ninfo: %s`,
	invalidPhase = `\n[Neum]:\ntype: ERROR\ncontent: Invalid phase\ninfo: %s`,
	noActiveScope = `\n[Neum]:\ntype: ERROR\ncontent: No active scope is found\ninfo: %s`,
	noActiveDerive = `\n[Neum]:\ntype: ERROR\ncontent: :Get() / X() methods have to be written inside derive statements\n`,
	failedComponentCreation= `\n[Neum]:\ntype: ERROR\ncontent: Failed to create component\ninfo: %s`,
	optimize_mode_callingState = `\n[Neum]:\ntype: ERROR\ncontent: Attempt to call state directly in optimize mode. Use Dep:Get()/:Peek()/:Set() in optimize mode instead.\n`,
	valueStreamAsValueForDependency = `\n[Neum]:\ntype: ERROR\ncontent: Can not set dependency value to valueStream object\n`,
	attemptToDeriveInstances = `\n[Neum]:\ntype: ERROR\ncontent: Derive operations can not return objects of type %s\n`,
	safe_mode_multiple_derives = `\ntype: ERROR\ncontent: Attempt to run multiple derive operations in a subArray\ninfo: Disable safe mode to processed`,
	invalidEffectCallback = `\n[Neum]:\ntype: ERROR\ncontent: Effect callback didn't execute successfully\n`,
	divisionByZero = `\n[Neum]:\ntype: ERROR\ncontent: Can not divide by zero`,
	attributeExists = `\n[Neum]:\ntype: WARNING\ncontent: Can not set attribute with name %s\n`,
	noDependencyProvided = `\n[Neum]:\ntype: ERROR\ncontent: No dependency was provided for reactive utils.`
}

return function(LogMsg : string, Data: string?)
	if not LOGS[LogMsg] then error(`Log message {LogMsg} is not found`, 2) return end
	
	--TODO...
	if LogMsg == "attributeExists" or LogMsg == "invalidClass" then
		warn(string.format(LOGS[LogMsg]), Data)
	else
		error(string.format(LOGS[LogMsg], Data), 2)
	end
end