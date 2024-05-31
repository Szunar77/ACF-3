local ACF      = ACF
local Vehicles = ACF.Classes.Vehicles

Vehicles.Register("HL2", {
    Name = "Half-Life 2 Seats",
})

do
    Vehicles.RegisterItem("WOOD-HL2", "HL2", {
        Name = "Wooden Chair",
        Description = "A Wooden Chair",
        Model = "models/nova/chair_wood01.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
    })

    Vehicles.RegisterItem("PLASTIC-HL2", "HL2", {
        Name = "Chair",
        Description = "A Plastic Chair",
        Model = "models/nova/chair_plastic01.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
    })

    Vehicles.RegisterItem("JEEP-HL2", "HL2", {
        Name = "Jeep Seat",
        Description = "A Seat from VALVe's Jeep",
        Model = "models/nova/jeep_seat.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
    })

    Vehicles.RegisterItem("AIRBOAT-HL2", "HL2", {
        Name = "Airboat Seat",
        Description = "A Seat from VALVe's Airboat",
        Model = "models/nova/airboat_seat.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
    })

    Vehicles.RegisterItem("OFFICE1-HL2", "HL2", {
        Name = "Office Chair",
        Description = "A Small Office Chair",
        Model = "models/nova/chair_office01.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
    })

    Vehicles.RegisterItem("OFFICE2-HL2", "HL2", {
        Name = "Big Office Chair",
        Description = "A Big Office Chair",
        Model = "models/nova/chair_office02.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
    })

    if IsMounted("ep2") then
        Vehicles.RegisterItem("JALOPY-HL2", "HL2", {
            Name = "Jalopy Seat",
            Description = "A Seat from VALVe's Jalopy",
            Model = "models/nova/jalopy_seat.mdl",
            Mass = 100,
            Preview = {
                FOV = 90,
            },
        })
    end
end

do -- PhoeniX-Storms Vehicles
    local function HandlePHXSeatAnimation(_, Player)
        return Player:SelectWeightedSequence(ACT_HL2MP_SIT)
    end

    local function HandlePHXVehicleAnimation(_, Player)
        return Player:SelectWeightedSequence(ACT_DRIVE_JEEP)
    end

    local function HandlePHXAirboatAnimation(_, Player)
        return Player:SelectWeightedSequence(ACT_DRIVE_AIRBOAT)
    end

    Vehicles.RegisterItem("CAR1-HL2", "HL2", {
        Name = "Car Seat",
        Description = "PHX Airboat Seat with Sitting Animation",
        Model = "models/props_phx/carseat2.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePHXSeatAnimation,
    })

    Vehicles.RegisterItem("CAR2-HL2", "HL2", {
        Name = "Car Seat 2",
        Description = "PHX Airboat Seat with Jeep animations",
        Model = "models/props_phx/carseat3.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePHXVehicleAnimation,
    })

    Vehicles.RegisterItem("CAR3-HL2", "HL2", {
        Name = "Car Seat 3",
        Description = "PHX Airboat Seat with Airboat animations",
        Model = "models/props_phx/carseat2.mdl",
        Mass = 100,
        Preview = {
            FOV = 90,
        },
        HandleAnimation = HandlePHXAirboatAnimation,
    })
end