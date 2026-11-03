local globalData = require("../globalData")
local types = require("../types")

local Logger = require("../Tools/Logger")

local exports = {}

type eventName = "Activated" | "MouseButton1Click" | 
"MouseButton1Down" | "MouseButton1Up" | "MouseButton2Click" | 
"MouseButton2Down" | "MouseButton2Up" | "MouseEnter" | 
"MouseLeave" | "InputBegan" | "InputChanged" | "InputEnded" | "FocusLost" | "Focused"

--properties that robloxS game engine changes frequently
type bindableProperties = 
	"AbsolutePosition" | "AbsoluteSize" | "TextContent" | "Text"

--[[
	phases:
	1 -> properties that doesn't depend on any other elements
	2 -> properties that depends on other elements like [children]
	3 -> listeners and [onEvent] after finishing the parenting phase completely
	4 -> ready phase
]]

function exports.onEvent(eventName : eventName) : types.SpecialKey
	return {
		__type = "SpecialKey",
		name = eventName,
		phase = 3,
		apply = function(self, instance : Instance, callback : (...unknown) -> ())
			local activeScope = globalData.currentActiveScope
			if activeScope then
				activeScope:__register(instance[eventName]:Connect(callback))
			else
				Logger("noActiveScope", "Connection failed to initialize")
			end
		end,
	}
end

-- a helper function to attach children
-- @ REMOVED the use of scope:__register() because it
-- causes outer scopes to have references to elements in inner scopes
--@DEPRECATED
local function attachChild(parentInstance : Instance, child : any)
	if not child then return end
	if typeof(child) == "Instance" then
		(child :: Instance).Parent = parentInstance
	elseif typeof(child) == "table" and child.__type == "ValueStream" then
		local stream = child :: types.ValueStream<Instance>
		local toRender: (Instance | {Instance})? = nil

		local parentScope = globalData.currentActiveScope

		stream:listen(function(newToRender : any)
			if toRender then
				local keepSet = {}
				if typeof(newToRender) == "table" and newToRender.__type ~= "ValueStream" then
					-- array of reactive elements
					for _, instance in newToRender do
						keepSet[instance] = true
					end
				elseif typeof(newToRender) == "Instance" then
					keepSet[newToRender] = true
				end

				local subScope: types.Scope? = globalData.componentScopes[toRender]
				if subScope then
					subScope:Clear()
					if typeof(toRender) == "Instance" then
						globalData.componentScopes[toRender] = nil
					elseif typeof(toRender) == "table" then
						for _, instance in toRender do
							globalData.componentScopes[instance] = nil
						end
					end
				else
					if typeof(toRender) == "Instance" then
						if not keepSet[toRender] then
							toRender:Destroy()
						end
					elseif typeof(toRender) == "table" then
						for _, instance in toRender do
							if not keepSet[instance] then
								instance:Destroy()
							else
								instance.Parent = nil
							end
						end
					end
				end
				toRender = nil
			end

			toRender = newToRender
			if newToRender then
				local cached = globalData.currentActiveScope
				globalData.currentActiveScope = parentScope
				attachChild(parentInstance, newToRender)
				globalData.currentActiveScope = cached
			end
		end)

		local cached = globalData.currentActiveScope
		globalData.currentActiveScope = parentScope

		local initialRender = stream:Peek()
		toRender = initialRender
		if initialRender then
			attachChild(parentInstance, initialRender)
		end

		globalData.currentActiveScope = cached

	elseif #child > 0 then
		for _, nestedChild in child do
			attachChild(parentInstance, nestedChild)
		end
	end
end

function exports.children()
	return {
		__type = "SpecialKey",
		name = "Children",
		phase = 2,
		apply = function(self, instance: Instance, value : unknown)
			if typeof(value) == "table" and value.__type ~= "ValueStream" then
				for _, val in value do
					attachChild(instance, val)
				end
			elseif typeof(value) == "table" and value.__type == "ValueStream" then
				attachChild(instance, value)
			else
				--components
				attachChild(instance, value)
			end
		end,
	}
end

function exports.reference()
	return {
		__type = "SpecialKey",
		name = "Reference",
		phase = 1,
		apply = function(self, instance : Instance, value : unknown)
			if typeof(value) == "table" and value.__type == "Pointer" or value.__type == "Dependency" then
				value:Set(instance)
			else
				value = instance
			end
		end,
	}
end

function exports.bind(bindingName : bindableProperties)
	return {
		__type = "SpecialKey",
		name = "propertyName",
		phase = 4,
		apply = function(self, instance : Instance, value : unknown)
			if typeof(value) == "table" and value.__type == "Dependency" then
				local currentActiveScope: types.Scope? = globalData.currentActiveScope
				if not currentActiveScope then return end
				
				if instance[bindingName] then
					currentActiveScope:__register(
						instance:GetPropertyChangedSignal(bindingName):Connect(function()
							value:Set(instance[bindingName])
						end)
					)
				else
					currentActiveScope:__register(
						instance:GetAttributeChangedSignal(bindingName):Connect(function()
							value:Set(instance:GetAttribute(bindingName))
						end)
					)
				end
			end
		end,
	}
end
-- bind deps to att
-- using binding right now to avoid overcomplications
--[[function exports.att(attName : bindableProperties)
	return {
		__type = "SpecialKey",
		name = "att",
		phase = 4,
		apply = function(self, instance : Instance, value : unknown)
			if typeof(value) == "table" and value.__type == "Dependency" then
				local currentActiveScope = globalData.currentActiveScope
				if not currentActiveScope then return end

				instance:GetAttributeChangedSignal(attName):Connect(function()
					value:Set(instance:GetAttribute(attName))
				end)
			end
		end,
	}
end--]]

return exports