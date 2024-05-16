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

	local function findOtherSideOfSphere(point, dir, ent)
		local radius = ent:Radius()
		local center = ent:GetPos()

		local displacement = point - origin

		local ie     = ray:Dot(displacement)^2 - displacement:LengthSqr()
		local exit   = ray:Dot(point - center) + sqrt(ie)
		local length = (point - exit):Length() * 25.4

		return exit, length
	end

	local function findOtherSideOfPoly(Ent, Origin, Dir)
		local Mesh = Ent:GetPhysicsObject():GetMeshConvexes()
		local Min  = math.huge

		for K in pairs(Mesh) do -- Loop over mesh
			local Hull = Mesh[K]

			for I = 1, #Hull, 3 do -- Loop over each tri (groups of 3)
				-- Points on tri
				local P1     = Ent:LocalToWorld(Hull[I].pos)
				local P2     = Ent:LocalToWorld(Hull[I + 1].pos)
				local P3     = Ent:LocalToWorld(Hull[I + 2].pos)

				-- Two edges to test with
				local Edge1  = P2 - P1
				local Edge2  = P3 - P1

				-- Plane facing the wrong way?
				if Dir:Dot(Edge1:Cross(Edge2)) > 0 then  continue end

				-- Ray is perpendicular to plane?
				local H = Dir:Cross(Edge2)
				local A = Edge1:Dot(H)

				if A > -0.0001 and A < 0.0001 then continue end

				-- Ray passes through the triangle?
				local F = 1 / A
				local S = Origin - P1 -- Displacement from to origin from P1
				local U = F * S:Dot(H)

				if U < 0 or U > 1 then continue end

				local Q = S:Cross(Edge1)
				local V = F * Dir:Dot(Q)

				if V < 0 or U + V > 1 then continue end

				-- Ray intersects triangle
				-- Length of ray to intersection
				local T = F * Edge2:Dot(Q)

				if T > 0.0001 and T < Min then Min = T end
			end
		end

		return Origin + Dir * Min
	end

	function ACF.getTraceDepth(trace)
		-- Traces from the surface of an object to the furthest tri on the opposite side
		-- Stops at any other object that is intersecting inside

		local ent    = trace.Entity
		local origin = trace.StartPos
		local enter  = trace.HitPos
		local rayDir = (enter - trace.StartPos):GetNormalized()

		local tempFilter = {}; for k, v in pairs(trace.Filter) do filter[k] = v end -- Shallow copy of the original filter (presumably a projectile trace) prevents two overlapping cubes from infinitely intersecting

		local opposite = ent._IsSpherical and findOtherSideOfSphere(enter, rayDir, ent:GetPos()) or findOtherSideOfPoly(ent, origin, rayDir)
		local exit     = ACF.trace({start = enter, endpos = opposite, filter = tempFilter}).HitPos -- Not strictly an exit... may have run into an intersecting entity
		local length   = (exit - enter):Length() * 25.4 -- Inches to mm

		return exit, length
	end
end
