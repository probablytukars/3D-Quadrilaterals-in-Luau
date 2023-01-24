local instance = require(script.Parent.Instance)
local vectors = require(script.Parent.Vectors)
local tri = {}

function tri.draw(a, b, c, thick, k, props, parent, upv)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	
	if (abd > acd and abd > bcd) then
		c, a = a, c
	elseif (acd > bcd and acd > abd) then
		a, b = b, a
	end
	
	ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	local right = ac:Cross(ab).unit
	
	local m = 1
	if upv ~= nil then
		if right:Dot(upv) > right:Dot(-upv) then
			m = -1
		end
	end

	local up = bc:Cross(right).unit
	local back = bc.unit
	local height = math.abs(ab:Dot(up))
	local wedge1 = instance.new("WedgePart", parent, props)
	local wedge2 = instance.new("WedgePart", parent, props)
	
	wedge1.Size = Vector3.new(thick, height, math.abs(ab:Dot(back)))
	wedge1.CFrame = CFrame.fromMatrix(
		(a + b)/2  - right*thick/2*k*m,
		right, up, back
	)
	wedge2.Size = Vector3.new(thick, height, math.abs(ac:Dot(back)))
	wedge2.CFrame = CFrame.fromMatrix(
		(a + c)/2 - right*thick/2*k*m,
		-right, up, -back
	)
end

return tri
