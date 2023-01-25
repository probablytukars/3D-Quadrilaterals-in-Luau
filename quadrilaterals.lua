local libs = script.Parent
local triangle = require(libs.Triangle)
local vectors = require(libs.Vectors)

local quadrilateral = {}

local function triangleUpVector(a, b, c)
	return vectors.normalize((b-a):Cross(b-c))
end

local function getGridPoints(positions, resolution)
	local p1, p2, p3, p4 = positions[1], positions[2], positions[3], positions[4]
	local gridPositions = {}
	for i = 0, resolution.X do
		local alphaOut = i / resolution.X
		local op1 = p1:Lerp(p2, alphaOut)
		local op2 = p4:Lerp(p3, alphaOut)
		for j = 0, resolution.Y do
			table.insert(gridPositions, op1:Lerp(op2, j / resolution.Y))
		end
	end
	return gridPositions
end

local function getPlane(positions, uv)
	local p1, p2, p3, p4 = positions[1], positions[2], positions[3], positions[4]
	local centroid = (((p1 + p3) / 2) + ((p2 + p4) / 2)) / 2
	local s1 = quadrilateral.surfaceNormal(positions)
	return centroid, s1
end

local function getQuadDrawDirection(centroid, surfaceNormal, positions)
	local h1 = vectors.heightFromPlane(centroid, surfaceNormal, positions[1])
	local h2 = vectors.heightFromPlane(centroid, surfaceNormal, positions[2])
	return h1 > h2
end

local function getQuadrilateralSurface(gridPositions, resolution, direction)
	local triangles = {}
	for i = 1, resolution.X do
		for j = 0, resolution.Y - 2 do
			local row1 = (resolution.Y * i) - (resolution.Y - 1) + j
			local row2 = (resolution.Y * i) + 1 + j
			local p1, p2 = row1, row1 + 1
			local p4, p3 = row2, row2 + 1
			if direction then
				table.insert(triangles, {p1, p2, p3})
				table.insert(triangles, {p1, p3, p4})
			else
				table.insert(triangles, {p1, p2, p4})
				table.insert(triangles, {p2, p3, p4})
			end
		end
	end

end

local function lineIntersection(p1, p2, p3, p4, maxDistance, epsilon)
	if not maxDistance then maxDistance = 1e-5 end
	local p13 = p1 - p3
	local p43 = p4 - p3
	local p21 = p2 - p1
	
	if p43.magnitude < epsilon or p21.magnitude < epsilon then
		return false
	end
	
	local d1343, d4321, d1321 = p13:Dot(p43), p43:Dot(p21), p13:Dot(p21)
	local d4343, d2121 = p43:Dot(p43), p21:Dot(p21)
	local denom = d2121 * d4343 - d4321 * d4321
	
	if math.abs(denom) < epsilon then
		return false
	end
	
	local numer = d1343 * d4321 - d1321 * d4343
	local mua = numer / denom
	local mub = (d1343 + d4321 * mua) / d4343
	
	local pA = p1 + mua * p21
	local pB = p3 + mub * p43
	local distance = (pA - pB).magnitude
	
	if distance <= maxDistance then
		if (mua >= 0 and mua <= 1) and (mub >= 0 and mub <= 1) then
			return true, (pA + pB) / 2
		end
	end
	return false
end

local function isSelfIntersecting(positions, epsilon)
	for i = 1, 2 do
		local v1, v2, v3, v4 = positions[1], positions[2 * i], positions[-i + 4], positions[-i + 5]
		local intersects, intersection = lineIntersection(v1, v2, v3, v4, 1e-5, epsilon)
		if intersects then
			local p1, p2, p3, p4 = positions[1], positions[-2 * i + 6], positions[i + 1], positions[i + 2]
			return true, {p1, p2, p3, p4, intersection}
		end
	end
	return false
end

local function getReflexAndOpposite(positions)
	local r1, r2, o1, o2 = positions[1], positions[2], positions[3], positions[4]
	
	local concave = false
	local angles = quadrilateral.getAngles(positions)
	
	for i = 1,4 do
		local pa, ca, na = angles[((i - 2) % 4) + 1], angles[i], angles[(i % 4) + 1]
		if ca > pa and ca > na then
			r1 = positions[i]
			r2 = positions[(i % 4) + 1]
			o1 = positions[((i + 1) % 4) + 1]
			o2 = positions[((i + 2) % 4) + 1]
			concave = true
		end
	end
	return r1, r2, o1, o2, concave
end

function quadrilateral.getAngles(positions)
	local r1, r2, o1, o2 = positions[1], positions[2], positions[3], positions[4]
	local angles = {}
	for i = 1, 4 do
		local pin, nin = (i-2)%4 + 1, (i)%4 + 1
		local a, b, c = positions[pin], positions[i], positions[nin]
		local v1, v2 = (a - b), (c - b)
		table.insert(angles, math.acos(v1:Dot(v2) / (v1.magnitude * v2.magnitude)))
	end
	return angles
end

function quadrilateral.surfaceNormal(positions)
	local p1, p2, p3, p4 = positions[1], positions[2], positions[3], positions[4]
	local n1, n2 = triangleUpVector(p1, p2, p3), triangleUpVector(p1, p3, p4)
	return vectors.slerp(n1, n2, 0.5)
end

function quadrilateral.getSurfacePoints(positions, resolution, epsilon)
	if not epsilon then epsilon = 1e-10 end
	local p1, p2, p3, p4 = positions[1], positions[2], positions[3], positions[4]
	local isCollinear = vectors.isCollinear(epsilon, p1, p2, p3, p4)
	if isCollinear then
		return nil
	end
	local verti, triangles
	
	local isPlanar, planeNormal = vectors.isCoplanar(epsilon, p1, p2, p3, p4)
	if isPlanar then
		local intersects, vertices = isSelfIntersecting(positions, epsilon)
		if intersects then
			verti = vertices
			triangles = {{1, 2, 5}, {3, 4, 5}}
		else
			local r1, r2, o1, o2 = getReflexAndOpposite(positions)
			verti = {r1, r2, o1, o2}
			triangles = {{1, 2, 3}, {1, 3, 4}}
		end
	else
		local centroid, surfaceNormal = getPlane(positions)
		local direction = getQuadDrawDirection(centroid, surfaceNormal, positions)
		verti = getGridPoints(positions, resolution)
		triangles = getQuadrilateralSurface(verti, resolution, direction)
	end
	return verti, triangles
end


function quadrilateral.drawQuadrilateral(positions, resolution, props, parent, epsilon)
	if not epsilon then epsilon = 1e-10 end
	local vertices, triangles = quadrilateral.getSurfacePoints(positions, resolution, epsilon)
	if vertices then
		for _, tri in pairs(triangles) do
			local a, b, c = unpack(tri)
			local p1, p2, p3 = vertices[a], vertices[b], vertices[c]
			triangle.draw(p1, p2, p3, 0, 1, props, parent)
		end
	else
		return nil
	end
end

return quadrilateral
