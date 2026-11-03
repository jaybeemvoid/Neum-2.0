--!strict

local types = require("../../types")
local Logger = require("../../Tools/Logger")

local globalData = require("../../globalData")

local registeredCustomProps = require("../../Utils/CustomProp")

local typeof_func = typeof
local table_insert = table.insert
local table_find = table.find

local function unsafe_setProperty(
	instance : Instance, 
	property: string, 
	value : unknown
)

	(instance :: any)[property] = value
end

local function flattenContent(content: any, resultList: {Instance})
	if typeof_func(content) == "Instance" then
		table_insert(resultList, content)
	elseif typeof_func(content) == "table" then
		if content.__type == "ValueStream" then
			flattenContent(content:Peek(), resultList)
		else
			for _, child in content do
				flattenContent(child, resultList)
			end
		end
	end
	return resultList
end

local function updateChildSlot(parentInstance: Instance, oldContent: any, newContent: any)
	local oldList = flattenContent(oldContent, {})
	local newList = flattenContent(newContent, {})

	for _, oldItem in oldList do
		if not table_find(newList, oldItem) then
			oldItem.Parent = nil
		end
	end

	for _, newItem in newList do
		if newItem.Parent ~= parentInstance then
			newItem.Parent = parentInstance
		end
	end
end

function applyProperties
(
	props : types.Props, 
	instance : Instance
)
	
	for key, value in (props :: {[string | {[string] : any}] : unknown}) do
		--static child instantiation
		local valType = typeof_func(value)
		local keyType = typeof_func(key)

		if keyType == "string" and (valType ~= "function" and valType ~= "table") then
			unsafe_setProperty(instance, key :: any, value)
		elseif valType == "Instance" and key ~= "Parent" then
			value = value :: Instance
			value.Parent = instance
		elseif keyType == "number" and valType == "table" and #(value :: {Instance}) > 0 and not (value :: {types.ValueStream<unknown>})[1].__type then
			for _, nestedChild in value do
				updateChildSlot(instance, nil, nestedChild)
			end
		elseif keyType == "number" and valType == "table" and (value :: {type: string, execute : (...unknown) -> ()}).type == "__neum_cprop" then
			value = value :: {type: string, execute : (...unknown) -> ()}
			local activeScope = globalData.currentActiveScope
			if not activeScope then Logger("noActiveScope", "") end
			if value.execute then
				value.execute(instance, activeScope)
			end
		elseif valType == "function" then
			local currentActiveScope = (globalData.currentActiveScope :: any) :: types.InternalScope
			if not currentActiveScope then Logger("noActiveScope", "A scope is required to form connections") end
			currentActiveScope:__register((instance :: any)[key]:Connect(value))
		elseif valType == "table" and (value :: any).__type == "Tween" and keyType == "string" then
			value.mount(instance, key)
		elseif (valType == "table" and #((value :: {types.ValueStream<unknown>}) :: {types.InternalValueStream<unknown>}) > 0) or (valType == "table" and ((value :: any) :: types.InternalValueStream<unknown>).__type == "ValueStream" and keyType ~= "table") then
			value = (value :: {types.ValueStream<unknown>}) :: {types.InternalValueStream<unknown>}
			
			if #value == 1 and value[1].__type == "ValueStream" then
				--single derive in an array
				local stream = (value[1] :: any) :: types.ValueStream<unknown>
				local targetTable = (instance or {}) :: {[string]: any}

				if keyType == "number" then
					--parent handling
					local lastContent = stream:Peek()

					updateChildSlot(instance, nil, lastContent)

					stream:listen(function(newContent: any)
						updateChildSlot(instance, lastContent, newContent)
						lastContent = newContent
					end)
				else
					--regular properties handling
					local stringKey = key :: string

					stream:listen(function(newValue: any)
						targetTable[stringKey] = newValue
					end)

					targetTable[stringKey] = stream:Peek()
				end
			elseif valType == "table" and (((value :: any) :: types.ValueStream<unknown>) :: types.InternalValueStream<unknown>).__type == "ValueStream" then
				--single independent derive
				local stream = ((value :: any) :: types.ValueStream<unknown>) :: types.InternalValueStream<unknown>
				local targetTable = (instance or {}) :: {[string]: any}

				if keyType == "number" then
					local lastContent = stream:Peek()

					updateChildSlot(instance, nil, lastContent)

					stream:listen(function(newContent: any)
						updateChildSlot(instance, lastContent, newContent)
						lastContent = newContent
					end)
				else
					--regular properties handling
					local stringKey = key :: string

					stream:listen(function(newValue: any)
						targetTable[stringKey] = newValue
					end)
					
					targetTable[stringKey] = stream:Peek()
				end
			else
				if globalData.debug then
					Logger("safe_mode_multiple_derives")
				else
					--dynamic lists of elements
					for _, nestedDerivedChild in value do
						if typeof_func(nestedDerivedChild) == "table" and nestedDerivedChild.__type == "ValueStream" then
							local stream = (nestedDerivedChild :: any) :: types.ValueStream<unknown>
							local lastContent = stream:Peek()

							local lastContent = lastContent
							updateChildSlot(instance, nil, lastContent)

							stream:listen(function(newContent: any)
								updateChildSlot(instance, lastContent, newContent)
								lastContent = newContent
							end)
						elseif typeof_func(nestedDerivedChild) == "Instance" then
							nestedDerivedChild.Parent = instance
						end
					end
				end
			end
		end
	end
end

return applyProperties