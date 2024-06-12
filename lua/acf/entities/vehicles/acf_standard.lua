local ACF      = ACF
local Vehicles = ACF.Classes.Vehicles

Vehicles.Register("ACF", {
    Name = "ACF Standard Vehicles",
})

do
    local function HandleACFPodAnimation(_, Player)
        return Player:LookupSequence("drive_pd")
    end

    Vehicles.RegisterItem("SEAT-ACF", "ACF", {
        Name = "Standard Pilot Seat",
        Description = "A generic seat for accurate damage modeling.",
        Model = "models/vehicles/pilot_seat.mdl",
        Mass = 250,
        Preview = {
            FOV = 100,
        },
    })

    Vehicles.RegisterItem("POD-ACF", "ACF", {
        Name = "Standard Prisoner Pod",
        Description = "Modified prisoner pod for more realistic player damage.",
        Model = "models/vehicles/driver_pod.mdl",
        Mass = 250,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandleACFPodAnimation,
    })
end