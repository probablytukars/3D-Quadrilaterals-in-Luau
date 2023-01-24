local instance = {}

function instance.new(toInstance: string, parent: Instance, properties): Instance
	local newInstance = Instance.new(toInstance)
	if properties then
		for propName, Value in next, properties do
			newInstance[propName] = Value
		end
	end
	if parent ~= nil then
		newInstance.Parent = parent
	end
	return newInstance
end

return instance
