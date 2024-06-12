local ACF      = ACF
local Vehicles = ACF.Classes.Vehicles

local function HandlePHXSeatAnimation(_, Player)
    return Player:SelectWeightedSequence(ACT_HL2MP_SIT)
end

local function HandlePodAnim(_, Player)
    return Player:LookupSequence("drive_pd")
end

do
    Vehicles.Register("PLYSTR", {
        Name = "Playerstart Chairs",
    })

    local function HandlePHXVehicleAnimation(_, Player)
        return Player:SelectWeightedSequence(ACT_DRIVE_JEEP)
    end

    local function HandlePHXAirboatAnimation(_, Player)
        return Player:SelectWeightedSequence(ACT_DRIVE_AIRBOAT)
    end

    Vehicles.RegisterItem("JEEP-PLYSTR", "PLYSTR", {
        Name = "Jeep Pose",
        Description = "jeep pose",
        Model = "models/chairs_playerstart/jeeppose.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePHXVehicleAnimation,
    })

    Vehicles.RegisterItem("AIRBOAT-PLYSTR", "PLYSTR", {
        Name = "Airboat Pose",
        Description = "airboat pose",
        Model = "models/chairs_playerstart/airboatpose.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePHXAirboatAnimation,
    })

    Vehicles.RegisterItem("SIT-PLYSTR", "PLYSTR", {
        Name = "Sitting Pose",
        Description = "sitting pose",
        Model = "models/chairs_playerstart/sitposealt.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePHXSeatAnimation,
    })

    Vehicles.RegisterItem("POD-PLYSTR", "PLYSTR", {
        Name = "Pod Pose",
        Description = "pod pose",
        Model = "models/chairs_playerstart/podpose.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePodAnim,
    })
end

do
    Vehicles.Register("PLYEXP", {
        Name = "Playerstart Chairs (Experimental)",
    })

    Vehicles.RegisterItem("SIT-PLYEXP", "PLYEXP", {
        Name = "Sitting Pose (Alt Physics)",
        Description = "sitting pose 2",
        Model = "models/chairs_playerstart/sitpose.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePHXSeatAnimation,
    })

    Vehicles.RegisterItem("STAND-PLYEXP", "PLYEXP", {
        Name = "Standing Pose",
        Description = "standing pose",
        Model = "models/chairs_playerstart/standingpose.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePodAnim,
    })

    Vehicles.RegisterItem("PRONE-PLYEXP", "PLYEXP", {
        Name = "Prone Pose",
        Description = "prone pose",
        Model = "models/chairs_playerstart/pronepose.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePodAnim,
    })
end