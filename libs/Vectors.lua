local vectors = {}

function vectors.slerp(a, b, alpha)
	if (a == b) then return a end
	local theta = math.acos(a:Dot(b))
	local p1 = (math.sin((1 - alpha) * theta) / math.sin(theta)) * a
	local p2 = (math.sin(alpha * theta) / math.sin(theta)) * b
	return p1 + p2
end

function vectors.normalize(ve, tr)
	local unitvec = ve.unit
	if ve == ve then
		return unitvec
	else
		if tr == nil then tr = Vector3.new(0,0,0) end
		return tr
	end
end

function vectors.isCollinear(epsilon, ...)
	local vec = {...}
	if #vec == 1 then return nil
	elseif #vec == 2 then return true else
		local first = (vec[1] - vec[2]).unit
		local collinear = true
		for i = 3, #vec do
			local tvec = (vec[i] - vec[i-1]).unit
			if math.abs(first:Dot(tvec)) < (1-epsilon) then
				collinear = false
				break
			end
		end
		if collinear then
			return collinear, first
		else
			return false, nil
		end
	end
end

function vectors.isCoplanar(epsilon, ...)
	local vec = {...}
	if #vec < 3 then
		return true, nil
	else
		local normal = vectors.normalize((vec[2] - vec[1]):Cross(vec[3] - vec[1]))
		for i = 4, #vec do
			local vector = vec[i] - vec[1]
			local dot = normal:Dot(vector)
			if math.abs(dot) > epsilon then
				return false
			end
		end
		return true, normal
	end
end

function vectors.heightFromPlane(centroid, normal, position)
	return (position - centroid):Dot(normal)
end

