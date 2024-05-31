local ACF      = ACF
local Vehicles = ACF.Classes.Vehicles

Vehicles.Register("MISC", {
    Name = "Third-Party Vehicles",
})

-- Racing Seats (https://steamcommunity.com/sharedfiles/filedetails/?id=471435979)
if util.IsValidModel("models/lubprops/seat/raceseat.mdl") then
    Vehicles.RegisterItem("RACE1-MISC", "MISC", {
        Name = "Driver Racing Seat",
        Description = "A racing seat suited for drivers.",
        Model = "models/lubprops/seat/raceseat.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
    })

    Vehicles.RegisterItem("RACE2-MISC", "MISC", {
        Name = "Passenger Racing Seat",
        Description = "A racing seat suited for passengers.",
        Model = "models/lubprops/seat/raceseat2.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
    })
end

-- Modular Crew Seat (https://steamcommunity.com/sharedfiles/filedetails/?id=3191007861)
if util.IsValidModel("models/liddul/crewseat.mdl") then
    Vehicles.RegisterItem("CREW-MISC", "MISC", {
        Name = "Modular Crew Seat",
        Description = "A crew seat with modular bodygroups.",
        Model = "models/liddul/crewseat.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
    })
end