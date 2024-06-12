AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("ACF_RequestVehicleInfo")

local ACF          = ACF
local Contraption  = ACF.Contraption
local Utilities    = ACF.Utilities
local HookRun      = hook.Run
local IsValid      = IsValid
local MaxDistance  = ACF.LinkDistance * ACF.LinkDistance

local PlayerOutputBinds = {
	[IN_FORWARD] = "W",
	[IN_MOVELEFT] = "A",
	[IN_BACK] = "S",
	[IN_MOVERIGHT] = "D",

	[IN_JUMP] = "Space",
	-- ["noclip"] = "Noclip",
	[IN_SPEED] = "Shift",
	[IN_ZOOM] = "Zoom",
	[IN_WALK] = "Alt",
	[IN_DUCK] = "Duck",

	[IN_ATTACK] = "Mouse1",
	[IN_ATTACK2] = "Mouse2",
	[IN_RELOAD] = "R",

	[IN_WEAPON2] = "PrevWeapon",
	[IN_WEAPON1] = "NextWeapon",
	-- ["impulse 100"] = "Light",
}

do -- Spawning and Updating
	local Classes    = ACF.Classes
	local WireIO     = Utilities.WireIO
	local Vehicles   = Classes.Vehicles
	local Entities   = Classes.Entities
	-- CFW.addParentDetour("acf_vehicle", "Pod")

	local Inputs = {
	}
	local Outputs = {
		"W", "A", "S", "D", "Mouse1", "Mouse2",
		"R", "Space", "Shift", "Zoom", "Alt", "Duck", -- "Noclip",
		"Active",
		"CamAng (The direction of the camera.) [ANGLE]",
		"Entity (The vehicle itself.) [ENTITY]",
		"Driver (The player driving the vehicle.) [ENTITY]",
	}

	local function HandleDefaultSeatAnimation(_, Player)
		return Player:LookupSequence("sit_rollercoaster")
	end

	local function VerifyData(Data)
		if not Data.Vehicle then
			Data.Vehicle = Data.Component or Data.Id
		end

		do -- Clamp camera behavior
			local X = ACF.CheckNumber(Data.CamOffsetX, 0)
			local Y = ACF.CheckNumber(Data.CamOffsetY, -25)
			local Z = ACF.CheckNumber(Data.CamOffsetZ, 50)

			Data.CamOffset = Vector(X, Y, Z)

			Data.CamZoom = ACF.CheckNumber(Data.CamZoom, 2)
		end

		local Class = Classes.GetGroup(Vehicles, Data.Vehicle)

		if not Class then
			Data.Vehicle = "SEAT-ACF"

			Class = Classes.GetGroup(Vehicles, Data.Vehicle)
		end

		local Vehicle = Vehicles.GetItem(Class.ID, Data.Vehicle)

		if not Vehicle.HandleAnimation then
			Vehicle.HandleAnimation = HandleDefaultSeatAnimation
		end

		do
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			hook.Run("ACF_VerifyData", "acf_vehicle", Data, Class, Vehicle)
		end
	end

	local function UpdateVehicle(Entity, Data, Class, Vehicle)
		local Pod = Entity.Pod

		Contraption.SetModel(Entity, Vehicle.Model)
		Pod:SetModel(Vehicle.Model)
		--Pod:SetModelScale(0.01)
		Pod:PhysicsInit(SOLID_NONE)
		Pod:SetMoveType(MOVETYPE_NONE)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name      = Vehicle.Name
		Entity.ShortName = Vehicle.ID
		Entity.ClassData = Class
		Entity.Class     = Class.ID
		Entity.EntType   = Class.Name
		Entity.CamOffset = Data.CamOffset
		Entity.CamZoom   = Data.CamZoom

		-- Set the pod animation and update it briefly on the client
		Pod.HandleAnimation = Vehicle.HandleAnimation
		Pod:SetNoDraw(false)

		timer.Simple(0, function()
			net.Start("ACF_RequestVehicleInfo")
				net.WriteEntity(Pod)
				net.WriteInt(Vehicle.HandleAnimation(_, Entity:CPPIGetOwner()), 10)
				net.WriteVector(Entity.CamOffset)
				net.WriteInt(Entity.CamZoom, 3)
			net.Broadcast()

			Pod:SetNoDraw(true)
		end)

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Vehicle)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Vehicle)
	end

	function MakeACF_Vehicle(Player, Pos, Ang, Data)
		local CanSpawn = HookRun("ACF_PreEntitySpawn", "acf_vehicle", Player, Data)
		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_vehicle")
		if not IsValid(Entity) then return end

		local Pod = ents.Create("prop_vehicle_prisoner_pod")
		if not IsValid(Pod) then return end

		VerifyData(Data)

		local Class   = Classes.GetGroup(Vehicles, Data.Vehicle)
		local Vehicle = Vehicles.GetItem(Class.ID, Data.Vehicle)
		local Limit   = Class.LimitConVar.Name

		-- Entity:SetPlayer(Player)
		Entity.ACF = Entity.ACF or {}
		Entity:SetAngles(Ang)
		Entity:SetPos(Pos)
		Entity:Spawn()
		Entity:SetUseType(SIMPLE_USE)

		Entity.ACF          = Entity.ACF or {}
		Entity.Pod          = Pod
		Entity.Turrets      = {}
		Entity.Engines      = {}
		Entity.Gearboxes    = {}
		Entity.DataStore    = Entities.GetArguments("acf_vehicle")
		Entity.Throttle     = 0
		Entity.CanEnter     = true
		Entity.GearboxSetup = "Unknown"

		Pod:SetAngles(Ang)
		Pod:SetModel("models/vehicles/pilot_seat.mdl")
		Pod:SetPos(Pos)
		Pod:Spawn()
		Pod:SetParent(Entity)
		Pod:CPPISetOwner(Player)
		Pod:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
		Pod:SetKeyValue("limitview", 0)
		Pod:SetNoDraw(true)
		Pod.Vehicle = Entity
		Pod.ACF = Pod.ACF or {}
		Pod.ACF.LegalSeat = true

		Player:AddCleanup(Limit, Entity)
		Player:AddCount(Limit, Entity)

		UpdateVehicle(Entity, Data, Class, Vehicle)

		WireLib.TriggerOutput(Entity, "Entity", Entity)
		WireLib.TriggerOutput(Entity, "Driver", nil)
		WireLib.TriggerOutput(Entity, "CamAng", angle_zero)

		Entity:UpdateOverlay(true)

		Entity:CallOnRemove("ACF_RemoveVehiclePod", function(Ent)
			SafeRemoveEntity(Ent.Pod)
		end)

		ACF.CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_vehicle", MakeACF_Vehicle, "Vehicle")

	function ENT:Update(Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Vehicles, Data.Vehicle)
		local Vehicle = Vehicles.GetItem(Class.ID, Data.Vehicle)
		local OldClass = self.ClassData

		local CanUpdate, Reason = HookRun("ACF_PreEntityUpdate", "acf_vehicle", self, Data, Class, Vehicle)

		if CanUpdate == false then return CanUpdate, Reason end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_vehicle", self, OldClass)

		ACF.SaveEntity(self)

		UpdateVehicle(self, Data, Class, Vehicle)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Vehicle)
		end

		HookRun("ACF_OnEntityUpdate", "acf_vehicle", self, Data, Class, Vehicle)

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Vehicle updated successfully!"
	end

	ACF.RegisterClassLink("acf_vehicle", "acf_turret", function(Vehicle, Turret)
		if Vehicle.Turrets[Turret] then return false, "This vehicle is already linked to this turret." end
		-- if Turret.Vehicles[Vehicle] then return false, "This turret is already linked to this vehicle." end
		if Vehicle:GetPos():DistToSqr(Turret:GetPos()) > MaxDistance then return false, "This vehicle is too far away from this turret." end

		Vehicle.Turrets[Turret] = true
		-- Turret.Vehicles[Vehicle] = true

		Vehicle:UpdateOverlay()

		return true, "Vehicle linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_vehicle", "acf_turret", function(Vehicle, Turret)
		if not Vehicle.Turrets[Turret] then return false, "This vehicle is not linked to this turret." end
		-- if not Turret.Vehicles[Vehicle] then return false, "This turret is not linked to this vehicle." end

		Vehicle.Turrets[Turret] = nil
		Turret.Vehicles[Vehicle] = nil

		Vehicle:UpdateOverlay()

		return true, "Vehicle unlinked successfully!"
	end)

	ACF.RegisterClassLink("acf_vehicle", "acf_engine", function(Vehicle, Engine)
		if Vehicle.Engines[Engine] then return false, "This vehicle is already linked to this engine." end
		-- if Engine.Vehicles[Vehicle] then return false, "This engine is already linked to this vehicle." end
		if Vehicle:GetPos():DistToSqr(Engine:GetPos()) > MaxDistance then return false, "This vehicle is too far away from this engine." end

		Vehicle.Engines[Engine] = true
		-- Engine.Vehicles[Vehicle] = true

		Vehicle:UpdateOverlay()

		return true, "Vehicle linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_vehicle", "acf_engine", function(Vehicle, Engine)
		if not Vehicle.Engines[Engine] then return false, "This vehicle is not linked to this engine." end
		-- if not Engine.Vehicles[Vehicle] then return false, "This engine is not linked to this vehicle." end

		Vehicle.Engines[Engine] = nil
		-- Engine.Vehicles[Vehicle] = nil

		Vehicle:UpdateOverlay()

		return true, "Vehicle unlinked successfully!"
	end)

	ACF.RegisterClassLink("acf_vehicle", "acf_gearbox", function(Vehicle, Gearbox)
		if Vehicle.Gearboxes[Gearbox] then return false, "This vehicle is already linked to this gearbox." end
		-- if Gearbox.Vehicles[Vehicle] then return false, "This gearbox is already linked to this vehicle." end
		if Vehicle:GetPos():DistToSqr(Gearbox:GetPos()) > MaxDistance then return false, "This vehicle is too far away from this gearbox." end

		Vehicle.Gearboxes[Gearbox] = true
		-- Gearbox.Vehicles[Vehicle] = true

		Vehicle:AnalyzeGearboxes()
		Vehicle:UpdateOverlay()

		return true, "Vehicle linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_vehicle", "acf_gearbox", function(Vehicle, Gearbox)
		if not Vehicle.Gearboxes[Gearbox] then return false, "This vehicle is not linked to this gearbox." end
		-- if not Gearbox.Vehicles[Vehicle] then return false, "This gearbox is not linked to this vehicle." end

		Vehicle.Gearboxes[Gearbox] = nil
		-- Gearbox.Vehicles[Vehicle] = nil

		Vehicle:AnalyzeGearboxes()
		Vehicle:UpdateOverlay()

		return true, "Vehicle unlinked successfully!"
	end)
end

do
	function ENT:Use(Activator)
		if not IsValid(Activator) then return end
		if not self.CanEnter then return end

		Activator:EnterVehicle(self.Pod)
		--Activator:SetEyeAngles(self:GetAngles())
		--Activator:SetLocalPos(Vector(0, 0, 7))
		--Activator:SetParent(self)

		WireLib.TriggerOutput(self, "Active", 1)
		WireLib.TriggerOutput(self, "Driver", Activator)

		for Turret in pairs(self.Turrets) do
			Turret:TriggerInput("Active", true)
		end

		for Engine in pairs(self.Engines) do
			Engine:TriggerInput("Active", true)
		end
	end

	-- function ENT:ACF_Activate(Recalc) end

	-- function ENT:ACF_OnDamage(DmgResult, DmgInfo) end

	function ENT:UpdateOverlayText()
		--[[
		local Turrets = self.Turrets
		local Engines = self.Engines
		local Gearboxes = self.Gearboxes

		if not next(Turrets) and not next(Engines) and not next(Gearboxes) then
			return "Disconnected"
		end

		local OverlayText = ""

		if next(Turrets) then
			OverlayText = OverlayText .. "Turrets: "

			for Turret in pairs(Turrets) do
				OverlayText = OverlayText .. tostring(Turret) .. "\n"
			end
		end

		if next(Engines) then
			OverlayText = OverlayText .. "Engines: "

			for Engine in pairs(Engines) do
				OverlayText = OverlayText .. tostring(Engine) .. "\n"
			end
		end

		if next(Gearboxes) then
			OverlayText = OverlayText .. "Gearboxes: "

			for Gearbox in pairs(Gearboxes) do
				OverlayText = OverlayText .. tostring(Gearbox) .. "\n"
			end
		end
		]]
		local OverlayText = "Detected Engine Setup: "
		local EngineCount = table.Count(self.Engines)

		if EngineCount == 0 then
			OverlayText = OverlayText .. "Unknown\n"
		elseif EngineCount == 1 then
			OverlayText = OverlayText .. "Single\n"
		else
			OverlayText = OverlayText .. "Multi\n"
		end

		local GearboxSetup = self.GearboxSetup or "Unknown"
		OverlayText = OverlayText .. "Detected Gearbox Setup: " .. GearboxSetup

		return OverlayText
	end
end

do
	hook.Add("PlayerLeaveVehicle", "ACF_OnVehicleExit", function(_, Vehicle)
		local VehicleEnt = Vehicle.Vehicle
		if not IsValid(VehicleEnt) then return end

		WireLib.TriggerOutput(VehicleEnt, "Active", 0)
		WireLib.TriggerOutput(VehicleEnt, "Driver", nil)
		WireLib.TriggerOutput(VehicleEnt, "CamAng", angle_zero)

		for Turret in pairs(VehicleEnt.Turrets) do
			Turret:TriggerInput("Active", false)
		end

		for Engine in pairs(VehicleEnt.Engines) do
			Engine:TriggerInput("Active", false)
		end

		for _, Output in pairs(PlayerOutputBinds) do
			WireLib.TriggerOutput(VehicleEnt, Output, 0)
		end
	end)
end

do
	function ENT:Enable()
		self.CanEnter = true
	end

	function ENT:Disable()
		self.CanEnter = false
	end
end

do
	function ENT:AnalyzeGearboxes()
		local Count = table.Count(self.Gearboxes)
		local SetupText = ""

		if Count == 1 then
			SetupText = "Single"
			local Gearbox = next(self.Gearboxes)

			if Gearbox.DualClutch then
				SetupText = SetupText .. " w/ Dual Clutch"
			end

			self.GearboxSetup = SetupText

			return SetupText
		end

		SetupText = "Unknown"
		self.GearboxSetup = SetupText

		return SetupText
	end

	--[[
		SelectPower = (A | D) ? TurnPower : BrakePower
        Power       = UseWeldLatch & KPH <= OverturnSpeed ? 1 : SelectPower
        ClutchL     = (Space | A) * Power
        ClutchR     = (Space | D) * Power
        WeldLatchL  = UseWeldLatch * KPH <= OverturnSpeed * (Space | A)
        WeldLatchR  = UseWeldLatch * KPH <= OverturnSpeed * (Space | D)

        if (W | S){
            MaxGear = W ? ForwardGears : ForwardGears + ReverseGears
            MinGear = W ? 1 : 1 + ForwardGears

            if (KPH < MinGearingSpeed | Gear < MinGear){ Gear = MinGear }
            elseif (Gear < MaxGear & RPM >= MaxRPM){ Gear++ }
            elseif (Gear > MinGear & RPM <= MinRPM){ Gear-- }
        }elseif (!Throttle & KPH <= MinGearingSpeed & ->KPH){
            Gear       = 1
            ClutchL    = ClutchR = Power
            WeldLatchL = WeldLatchR = UseWeldLatch
        }else{
            Gear = 1
        }
	]]
	function ENT:ProcessGearboxes(Driver)
		local Gearboxes = self.Gearboxes
		if not next(Gearboxes) then return end

		local InForward = Driver:KeyDown(IN_FORWARD)
		local InBackward = Driver:KeyDown(IN_BACK)
		local InLeft = Driver:KeyDown(IN_MOVELEFT)
		local InRight = Driver:KeyDown(IN_MOVERIGHT)
		local InSpace = Driver:KeyDown(IN_JUMP)
		local InMovement = InForward or InBackward or InLeft or InRight

		local BrakePower = 20
		local TurnPower = 6
		local ForwardGears = 5
		local ReverseGears = 2
		local MinGearingSpeed = 3
		local Power = (InLeft or InRight) and TurnPower or BrakePower
		local ClutchL = ((InSpace or InLeft) and 1 * Power) or 0 * Power
		local ClutchR = ((InSpace or InRight) and 1 * Power) or 0 * Power
		local KPH = self:GetVelocity():Length() * 3600 * 0.0000254 * 0.75

		for Gearbox in pairs(Gearboxes) do
			Gearbox:TriggerInput("Left Clutch", ClutchL)
			Gearbox:TriggerInput("Right Clutch", ClutchR)

			if InForward or InBackward then
				local MaxGear = InForward and ForwardGears or (ForwardGears + ReverseGears)
				local MinGear = InForward and 1 or 1 + ForwardGears
				local Gear = Gearbox.Gear

				if KPH < MinGearingSpeed or Gear < MinGear then
					Gearbox:TriggerInput("Gear", MinGear)
				elseif Gear < MaxGear and true then
					Gearbox:TriggerInput("Gear", Gear + 1)
				elseif Gear > MinGear and true then
					Gearbox:TriggerInput("Gear", Gear - 1)
				end
			elseif not InMovement and KPH <= MinGearingSpeed then
				Gearbox:TriggerInput("Gear", 1)
				Gearbox:TriggerInput("Left Clutch", Power)
				Gearbox:TriggerInput("Right Clutch", Power)
			else
				Gearbox:TriggerInput("Gear", 1)
			end

			--Gearbox:TriggerInput("Left Brake", InSpace and 1 or 0)
			--Gearbox:TriggerInput("Right Brake", InSpace and 1 or 0)
		end
	end
end

do
	local Clock = Utilities.Clock

	function ENT:Think()
		local Pod = self.Pod
		local Driver = Pod:GetDriver()
		if not IsValid(Driver) then return end

		local CamAng = Driver:LocalEyeAngles()
		WireLib.TriggerOutput(self, "CamAng", CamAng)

		local Turrets = self.Turrets

		-- Perform turret outputs
		if next(Turrets) then
			local InputAngle = Pod:LocalToWorldAngles(CamAng)

			for Turret, _ in pairs(Turrets) do
				Turret:InputDirection(InputAngle)
			end
		end

		local Engines = self.Engines

		-- Perform engine outputs
		if next(Engines) then
			local IsInMovement = Driver:KeyDown(IN_FORWARD) or Driver:KeyDown(IN_MOVELEFT) or Driver:KeyDown(IN_MOVERIGHT) or Driver:KeyDown(IN_BACK)
			local Throttle = IsInMovement and 100 or 0

			for Engine in pairs(Engines) do
				Engine:TriggerInput("Throttle", Throttle)
			end
		end

		-- Perform gearbox outputs
		self:ProcessGearboxes(Driver)

		-- Perform player key outputs
		for Bind, Output in pairs(PlayerOutputBinds) do
			WireLib.TriggerOutput(self, Output, Driver:KeyDown(Bind) and 1 or 0)
		end

		self:NextThink(Clock.CurTime)

		return true
	end
end

do	-- Dupe Support
	function ENT:PreEntityCopy()
		local Turrets   = self.Turrets
		local Engines   = self.Engines
		local Gearboxes = self.Gearboxes

		if next(Turrets) then
			local Entities = {}

			for Turret in pairs(Turrets) do
				Entities[#Entities + 1] = Turret:EntIndex()
			end

			duplicator.StoreEntityModifier(self, "ACFTurrets", Entities)
		end

		if next(Engines) then
			local Entities = {}

			for Engine in pairs(Engines) do
				Entities[#Entities + 1] = Engine:EntIndex()
			end

			duplicator.StoreEntityModifier(self, "ACFEngines", Entities)
		end

		if next(Gearboxes) then
			local Entities = {}

			for Gearbox in pairs(Gearboxes) do
				Entities[#Entities + 1] = Gearbox:EntIndex()
			end

			duplicator.StoreEntityModifier(self, "ACFGearboxes", Entities)
		end

		-- Wire dupe info
		self.BaseClass.PreEntityCopy(self)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		local EntMods = Ent.EntityMods

		if EntMods.ACFTurrets then
			for _, EntID in pairs(EntMods.ACFTurrets) do
				self:Link(CreatedEntities[EntID])
			end

			EntMods.ACFTurrets = nil
		end

		if EntMods.ACFEngines then
			for _, EntID in pairs(EntMods.ACFEngines) do
				self:Link(CreatedEntities[EntID])
			end

			EntMods.ACFEngines = nil
		end

		if EntMods.ACFGearboxes then
			for _, EntID in pairs(EntMods.ACFGearboxes) do
				self:Link(CreatedEntities[EntID])
			end

			EntMods.ACFGearboxes = nil
		end

		EntMods.Pod:SetNoDraw(true)

		self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
	end
end