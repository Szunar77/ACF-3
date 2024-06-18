include("shared.lua")

local IsValid = IsValid
local LocalPlayer = LocalPlayer

local MouseScrollDelta = 0
-- local SmoothDistance = 0
local LastFOV = 0
-- local CurDistance = 150

local WorldCamMins = Vector(-4, -4, -4)
local WorldCamMaxs = Vector(4, 4, 4)

local function WorldUnclip(Vehicle, OriginPos)
    local CurPos = Vehicle:GetPos()

    local Trace = {
        start = CurPos,
        endpos = OriginPos,
        mask = MASK_SOLID_BRUSHONLY,
        mins = WorldCamMins,
        maxs = WorldCamMaxs,
    }

    local Result = util.TraceHull(Trace)

    if Result.Hit then
        return Result.HitPos
    end

    return OriginPos
end

hook.Add("InputMouseApply", "ACF_VehicleZoomScroll", function(Cmd)
    local Player = LocalPlayer()
    local Pod = Player:GetVehicle()
    if not IsValid(Pod) then return end

    local Vehicle = Pod:GetParent()
    if not IsValid(Vehicle) then return end
    if Vehicle:GetClass() ~= "acf_vehicle" then return end
    if Vehicle.CamZoom == 0 then return end

    local MouseWheel = -Cmd:GetMouseWheel()
    -- local test = math.max((math.abs(CurDistance) + math.abs(MouseWheel)) / 10, 10)
    --print(test)
    MouseScrollDelta = math.Clamp(MouseScrollDelta - MouseWheel * 2, 0, 100) -- -2000, 180)
    --print(MouseScrollDelta)
end)

hook.Add("CalcView", "ACF_CameraCalcView", function(Player, _, Angles, FOV)
    local Pod = Player:GetVehicle()
    if not IsValid(Pod) then
        MouseScrollDelta = 0
        --SmoothDistance = 0
        LastFOV = FOV
        return
    end

    local Vehicle = Pod:GetParent()
    if not IsValid(Vehicle) then return end
    if Vehicle:GetClass() ~= "acf_vehicle" then return end

    local EyeAng = Player:LocalEyeAngles()
    local CamOffset = Vehicle.CamOffset or vector_origin
    --local SmoothAng = LerpAngle(FrameTime(), EyeAng, )

    local CamZoom = Vehicle.CamZoom

    if CamZoom == 1 then
        FOV = FOV - math.Clamp(MouseScrollDelta, 0, FOV - 5)
    elseif CamZoom == 2 then
        FOV = Lerp(FrameTime() * 4, LastFOV, FOV - math.Clamp(MouseScrollDelta, 0, FOV - 5))
        LastFOV = FOV
    end
    --SmoothDistance = Lerp(FrameTime() * 4, SmoothDistance, FOV + MouseScrollDelta)
    local OriginPos = Vehicle:LocalToWorld(CamOffset - EyeAng:Forward() * 150)

    local View = {
        origin = WorldUnclip(Vehicle, OriginPos),
        angles = Angles,
        fov = FOV,
        drawviewer = true,
    }

    return View
end)

local HideInfo = ACF.HideInfoBubble
local WireRender = Wire_Render

function ENT:Draw()
    local NoHalo = LocalPlayer():InVehicle()
    self:DoNormalDraw(NoHalo, HideInfo())

    WireRender(self)
end

net.Receive("ACF_RequestVehicleInfo", function()
    local Pod = net.ReadEntity()
    local SequenceID = net.ReadInt(10)
    local Offset = net.ReadVector()
    local ZoomBehavior = net.ReadUInt(2)

    local Vehicle = Pod:GetParent()

    Pod.HandleAnimation = function() return SequenceID end
    Vehicle.CamOffset = Offset
    Vehicle.CamZoom = ZoomBehavior
end)