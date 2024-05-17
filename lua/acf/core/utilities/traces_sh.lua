local ACF = ACF

do -- Visual clip compatibility
	local function checkClip(entity, clip, Center, pos)
		if clip.physics then return false end -- Physical clips will be ignored, we can't hit them anyway

		local normal = entity:LocalToWorldAngles(clip.n or clip[1]):Forward()
		local origin = Center + normal * (clip.d or clip[2])

		return normal:Dot((origin - pos):GetNormalized()) > 0
	end

	function ACF.CheckClips(ent, pos)
		if not IsValid(ent) then return false end
		if not ent.ClipData then return false end -- Doesn't have clips
		if ent:GetClass() ~= "prop_physics" then return false end -- Only care about props
		if SERVER and not ent:GetPhysicsObject():GetVolume() then return false end -- Spherical collisions applied to it

		-- Compatibility with Proper Clipping tool: https://github.com/DaDamRival/proper_clipping
		-- The bounding box center will change if the entity is physically clipped
		-- That's why we'll use the original OBBCenter that was stored on the entity
		local center = ent:LocalToWorld(ent.OBBCenterOrg or ent:OBBCenter())

		for _, clip in ipairs(ent.ClipData) do
			if checkClip(ent, clip, center, pos) then return true end
		end

		return false
	end
end

do -- ACF.trace
	-- Automatically filters out and retries when hitting a clipped portion of a prop
	-- Does NOT modify the original filter
	local util = util
	local sqrt = math.sqrt
	local v0   = Vector()

	local function doRecursiveTrace(traceData)
		local Output = traceData.output

		util.TraceLine(traceData)

		if Output.HitNonWorld and ACF.CheckClips(Output.Entity, Output.HitPos) then
			local Filter = traceData.filter

			Filter[#Filter + 1] = Output.Entity

			doRecursiveTrace(traceData)
		end
	end

	function ACF.trace(traceData)
		local Original = traceData.output
		local Output   = {}

		traceData.output = Output

		util.TraceLine(traceData)

		-- Check for clips or to filter this entity
		if Output.HitNonWorld and (ACF.CheckClips(Output.Entity, Output.HitPos) or ACF.GlobalFilter[Output.Entity:GetClass()]) then
			local OldFilter = traceData.filter
			local Filter    = { Output.Entity }

			for _, V in ipairs(OldFilter) do Filter[#Filter + 1] = V end

			traceData.filter = Filter

			doRecursiveTrace(traceData)

			traceData.filter = OldFilter
		end

		if Original then
			for K in pairs(Original) do Original[K] = nil end
			for K, V in pairs(Output) do Original[K] = V end

			traceData.output = Original
		end

		return Output
	end

	local function findOtherSideOfSphere(ent, rayOrigin, rayDir)
		local radius = ent:Radius()
		local center = ent:GetPos()

		local displacement = rayOrigin - center

		local ie     = ray:Dot(displacement)^2 - displacement:LengthSqr()
		local exit   = ray:Dot(displacement) + sqrt(ie)
		local length = (point - exit):Length() * 25.4

		return exit, length, point + dir * radius * 2, radius * 2
	end

	local function rayIntersectTri(rayOrigin, rayNormal, p1, edge1, edge2)

		if rayNormal:Dot(edge1:Cross(edge2)) > 0 then return false end -- Plane facing the wrong way

		local h = rayNormal:Cross(edge2)
		local a = edge1:Dot(h)

		if a > -0.001 and a < 0.001 then return false end -- Ray is perpendicular to plane

		local f = 1 / a
		local s = rayOrigin - p1 -- Displacement from to origin from p1
		local u = f * s:Dot(h)

		if u < 0 or u > 1 then return false end

		local q = s:Cross(edge1)
		local v = f * rayNormal:Dot(q)

		if v < 0 or u + v > 1 then return false end

		-- Ray intersects triangle
		-- Length of ray to intersection
		local t = f * edge2:Dot(q)

		if t < 0.001 then return false end -- Ray is too close

		return t
	end

	local function findOtherSideOfPoly(ent, rayOrigin, rayNormal, surfaceNormal)
		local nominalPos    = v0
		local nominalLen    = math.huge
		local incidentalPos = v0
		local incidentalLen = math.huge

		debugoverlay.Line(rayOrigin + Vector(0, 0, 1), rayOrigin + Vector(0, 0, 1) + rayNormal * 12, 0.05, Color(255, 160, 0), true)
		debugoverlay.Line(rayOrigin + Vector(0, 0, 1), rayOrigin + Vector(0, 0, 1) + surfaceNormal * 12, 0.05, Color(160, 255, 0), true)

		for _, hull in pairs(ent:GetPhysicsObject():GetMeshConvexes()) do -- Loop over mesh
			for i = 1, #hull, 3 do -- Loop over each tri (groups of 3)
				-- Points on tri
				local p1 = ent:LocalToWorld(hull[i].pos)
				local p2 = ent:LocalToWorld(hull[i + 1].pos)
				local p3 = ent:LocalToWorld(hull[i + 2].pos)

				-- Two edges to test with
				local edge1  = p2 - p1
				local edge2  = p3 - p1

				incTest = rayIntersectTri(rayOrigin, rayNormal, p1, edge1, edge2)
				nomTest = rayIntersectTri(rayOrigin, surfaceNormal, p1, edge1, edge2)

				if incTest and incTest < incidentalLen then incidentalLen = incTest end
				if nomTest and nomTest < nominalLen then nominalLen = nomTest end
			end
		end

		return rayOrigin + rayNormal * incidentalLen, incidentalLen, rayOrigin + surfaceNormal * nominalLen, nominalLen
	end

	local output = {nominal = 0, incidental = 0, normalPos = false, incidentalPos = false}

	function ACF.getThickness(entity, rayPos, rayNormal, surfaceNormal)
		-- Traces from the surface of an object to the furthest tri on the opposite side
		-- Stops at any other object that is intersecting inside

		if not IsValid(entity) or entity:IsWorld() then
			output.nominal       = 0
			output.incidental    = 0
			output.normalPos     = pos
			output.incidentalPos = pos
		else
			surfaceNormal = -surfaceNormal

			local ip, il, np, nl = findOtherSideOfPoly(entity, rayPos, rayNormal, surfaceNormal)
			local exit = ACF.trace({start = rayPos, endpos = ip, filter = {entity}}).HitPos -- Not strictly an exit... may have run into an intersecting entity inside

			output.nominal       = nl * 25.4
			output.incidental    = (exit - rayPos):Length() * 25.4
			output.normalPos     = np
			output.incidentalPos = ip
		end

		return output
	end
end

if SERVER then
	function test()
		timer.Create("peee", 0.02, 0, function()
			local trace = eye()

			if trace.HitNonWorld then
				local depth = ACF.getThickness(trace.Entity, trace.HitPos, (trace.HitPos - trace.StartPos):GetNormalized(), trace.HitNormal)

				debugoverlay.Line(trace.HitPos, depth.incidentalPos, 0.05, Color(200, 50, 50), true)
				debugoverlay.Line(trace.HitPos, depth.normalPos, 0.05, Color(50, 200, 50), true)

				debugoverlay.Cross(trace.HitPos, 6, 0.05, Color(255, 255, 255), true)
				debugoverlay.Cross(depth.incidentalPos, 3, 0.05, Color(255, 0, 0 ), true)
				debugoverlay.Cross(depth.normalPos, 3, 0.05, Color(0, 255, 0), true)
			end
		end)
	end
end