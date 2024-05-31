local ACF      = ACF
local Vehicles = ACF.Classes.Vehicles

Vehicles.Register("ACF", {
    Name = "ACF Standard Vehicles",
})
--[[
list.Set( "Vehicles", "acf_vehicle", {
    -- Required information
    Name = "ACF Vehicle",
    Model = "",
    Class = "prop_vehicle_prisoner_pod",
    Category = "Armored Combat Framework",
    Offset = 16,
    KeyValues = {
        vehiclescript	=	"scripts/vehicles/prisoner_pod.txt",
        limitview		=	"0"
    },
    Spawnable = false,
} )
]]

do
    local function HandleACFPodAnimation(_, Player)
        return Player:LookupSequence("drive_pd")
    end

    Vehicles.RegisterItem("SEAT-ACF", "ACF", {
        Name = "Standard Pilot Seat",
        Description = "A generic seat for accurate damage modeling.",
        Model = "models/vehicles/pilot_seat.mdl",
        Mass = 100,
        Preview = {
            FOV = 100,
        },
    })

    Vehicles.RegisterItem("POD-ACF", "ACF", {
        Name = "Standard Driver Pod",
        Description = "Modified prisonpod for more realistic player damage.",
        Model = "models/vehicles/driver_pod.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandleACFPodAnimation,
    })
end