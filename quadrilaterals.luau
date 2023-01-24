local libs = script.Parent
local triangle = require(libs.Triangle)
local vectors = require(libs.Vectors)
local math2 = require(libs.Math2)
local tables = require(libs.Tables)

local quadrilateral = {}

local function triangleUpVector(a, b, c)
	return vectors.normalize((b-a):Cross(b-c))
end

local function getGridPoints(positions, resolution)
	local gridPositions = {}
	for i = 0, resolution.X do
		local axisPositions = {}
		local alphaOut = i / resolution.X
		local op1 = positions.p1:Lerp(positions.p2, alphaOut)
		local op2 = positions.p4:Lerp(positions.p3, alphaOut)
		for j = 0, resolution.Y do
			table.insert(axisPositions, op1:Lerp(op2, j / resolution.Y))
		end
		table.insert(gridPositions, axisPositions)
	end
	return gridPositions
end

local function getPlane(positions, uv)
	local p1, p2, p3, p4 = positions.p1, positions.p2, positions.p3, positions.p4
	local centroid = (((p1 + p3) / 2) + ((p2 + p4) / 2)) / 2
	local s1 = quadrilateral.surfaceNormal(positions)
	return centroid, s1
end

local function getQuadDrawDirection(centroid, surfaceNormal, positions)
	local h1 = vectors.heightFromPlane(centroid, surfaceNormal, positions.p1)
	local h2 = vectors.heightFromPlane(centroid, surfaceNormal, positions.p2)
	return h1 > h2
end

local function getQuadrilateralSurface(gridPositions, resolution, direction)
	local triangles = {}
	for i = 1, resolution.X do
		local rowFirst = gridPositions[i]
		local rowSecond = gridPositions[i + 1]
		for j = 1, resolution.Y do
			local p1, p2 = rowFirst[j], rowFirst[j + 1]
			local p4, p3 = rowSecond[j], rowSecond[j + 1]
			if direction then
				table.insert(triangles, {p1, p2, p3})
				table.insert(triangles, {p1, p3, p4})
			else
				table.insert(triangles, {p1, p2, p4})
				table.insert(triangles, {p2, p3, p4})
			end
		end
	end
	return triangles
end

local function lineIntersection(p1, p2, p3, p4)
	local p13 = p1 - p3
	local p43 = p4 - p3
	local p21 = p2 - p1
	
	if p43.magnitude < 1e-5 or p21.magnitude < 1e-5 then
		return false
	end
	
	local d1343, d4321, d1321 = p13:Dot(p43), p43:Dot(p21), p13:Dot(p21)
	local d4343, d2121 = p43:Dot(p43), p21:Dot(p21)
	local denom = d2121 * d4343 - d4321 * d4321
	
	if math.abs(denom) < 1e-5 then
		return false
	end
	
	local numer = d1343 * d4321 - d1321 * d4343
	local mua = numer / denom
	local mub = (d1343 + d4321 * mua) / d4343
	
	if (mua >= 0 and mua <= 1) and (mub >= 0 and mub <= 1) then
		local intersection = p1 + mua * p21
		return true, intersection
	end
	return false
end

local function isSelfIntersecting(positions)
	local p1, p2, p3, p4 = positions.p1, positions.p2, positions.p3, positions.p4
	local vertices = {p1, p2, p3, p4}
	for i = 1, 2 do
		local v1, v2, v3, v4 = vertices[1], vertices[2 * i], vertices[-i + 4], vertices[-i + 5]
		print(1, 2 * i, -i + 4, -i + 5)
		local intersects, intersection = lineIntersection(v1, v2, v3, v4)
		if intersects then
			return true, intersection, {v1, v2, v3, v4}
		end
	end
	return false
end

local function getReflexAndOpposite(positions)
	local p1, p2, p3, p4 = positions.p1, positions.p2, positions.p3, positions.p4
	local pos = {positions.p1, positions.p2, positions.p3, positions.p4}
	local concave = false
	
	local r1, r2, o1, o2 = pos[1], pos[2], pos[3], pos[4]
	local angles = {}
	for i = 1, 4 do
		local pin, nin = tables.indexWrapped(i-1, 4), tables.indexWrapped(i+1, 4)
		local a, b, c = pos[pin], pos[i], pos[nin]
		local v1, v2 = (a - b), (c - b)
		table.insert(angles, math.acos(v1:Dot(v2) / (v1.magnitude * v2.magnitude)))
	end
	
	for i = 1,4 do
		local pa, ca, na = angles[((i - 2) % 4) + 1], angles[i], angles[(i % 4) + 1]
		if ca > pa and ca > na then
			r1 = pos[i]
			r2 = pos[(i % 4) + 1]
			o1 = pos[((i + 1) % 4) + 1]
			o2 = pos[((i + 2) % 4) + 1]
			concave = true
		end
	end
	return r1, r2, o1, o2, concave
end

function quadrilateral.surfaceNormal(positions)
	local p1, p2, p3, p4 = positions.p1, positions.p2, positions.p3, positions.p4
	local n1, n2 = triangleUpVector(p1, p2, p3), triangleUpVector(p1, p3, p4)
	return vectors.slerp(n1, n2, 0.5)
end

function quadrilateral.getSurfacePoints(positions, resolution, epsilon)
	local p1, p2, p3, p4 = positions.p1, positions.p2, positions.p3, positions.p4
	local isCollinear = vectors.isCollinear(epsilon, p1, p2, p3, p4)
	if isCollinear then
		return nil
	end
	local direction = nil
	local triangles = nil
	
	local isPlanar, planeNormal = vectors.isCoplanar(epsilon, p1, p2, p3, p4)
	if isPlanar then
		local intersects, intersection, vertices = isSelfIntersecting(positions)
		if intersects then
			triangles = {{vertices[1], vertices[4], intersection}, {vertices[2], vertices[3], intersection}}
		else
			local r1, r2, o1, o2, concave = getReflexAndOpposite(positions)
			triangles = {{r1, r2, o1}, {r1, o1, o2}}
		end
	else
		local centroid, surfaceNormal = getPlane(positions)
		local direction = getQuadDrawDirection(centroid, surfaceNormal, positions)
		local gridPositions = getGridPoints(positions, resolution)
		triangles = getQuadrilateralSurface(gridPositions, resolution, direction)
	end
	return triangles, isPlanar, direction
end


function quadrilateral.drawQuadrilateral(positions, resolution, props, parent, epsilon)
	if not epsilon then epsilon = 1e-5 end
	local triangles, isPlanar, direction = quadrilateral.getSurfacePoints(positions, resolution, epsilon)
	if triangles then
		for _, tri in pairs(triangles) do
			local a, b, c = unpack(tri)
			triangle.draw(a, b, c, 0, 1, props, parent)
		end
	else
		return nil
	end
end

return quadrilateral
