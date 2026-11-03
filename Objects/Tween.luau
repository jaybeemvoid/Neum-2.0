local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Derive = require("../Core/Derive")

local tweens = {}

local function lerp(current, target, alpha)
	local t = typeof(current)
	if t == "number" then
		return current + (target - current) * alpha
	elseif t == "UDim2" or t == "Color3" or t == "Vector3" or t == "Vector2" then
		return current:Lerp(target, alpha)
	end
	return target
end

RunService:BindToRenderStep("_neum_tween", Enum.RenderPriority.Last.Value, function(dt)
    if #tweens <= 0 then return end

    for _, tweenData in ipairs(tweens) do
        if tweenData.isTweening then
            tweenData.elapsedTime = tweenData.elapsedTime + dt
            local linearAlpha = math.clamp(tweenData.elapsedTime / tweenData.Duration, 0, 1)

            local easedAlpha = TweenService:GetValue(linearAlpha, tweenData.EasingStyle, tweenData.EasingDirection)

            tweenData.instance[tweenData.property] = lerp(tweenData.fromValue, tweenData.targetValue, easedAlpha)

            if linearAlpha >= 1 then
                tweenData.isTweening = false
            end
        end
    end
end)

return function(dependency, info : { EasingStyle: Enum.EasingStyle, EasingDirection: Enum.EasingDirection, Duration: number })
	return {
		__type = "Tween",

		mount = function(instance, propName)
			local initialVal = instance[propName]

			local tweenData = {
				instance = instance,
				property = propName,

				fromValue = initialVal,
				targetValue = initialVal,

				elapsedTime = 0,
				Duration = info.Duration or 1,
				isTweening = false,

				EasingStyle = info.EasingStyle or Enum.EasingStyle.Linear,
				EasingDirection = info.EasingDirection or Enum.EasingDirection.In,
			}

			table.insert(tweens, tweenData)

			Derive(function()
				local newTarget = dependency:Get()
				if newTarget ~= tweenData.targetValue then
					tweenData.fromValue = tweenData.instance[tweenData.property]
					tweenData.targetValue = newTarget
					tweenData.elapsedTime = 0
					tweenData.isTweening = true
				end
			end)
		end,
	}
end