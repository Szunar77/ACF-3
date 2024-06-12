local ACF = ACF
local Vehicles = ACF.Classes.Vehicles

local CamOffset = Vector()

local function CreateCameraMenu(Menu)
    Menu:AddTitle("Camera Settings")

    Menu:AddLabel("Zoom Behavior:")
    local ZoomSelect = Menu:AddComboBox()
    ZoomSelect:AddChoice("Disabled", 0)
    ZoomSelect:AddChoice("Unsmoothed Zoom", 1)
    ZoomSelect:AddChoice("Smoothed Zoom", 2)
    ZoomSelect:ChooseOptionID(3)
    function ZoomSelect:OnSelect(_, _, Data)
        ACF.SetClientData("CamZoom", Data)
    end

    local CamMin = -250
    local CamMax = 250

    local CamX = Menu:AddSlider("X Offset", CamMin, CamMax)
    CamX:SetClientData("CamOffsetX", "OnValueChanged")
    CamX:DefineSetter(function(Panel, _, _, Value)
        local X = math.Round(Value)

        Panel:SetValue(X)

        CamOffset.x = X

        return X
    end)

    local CamY = Menu:AddSlider("Y Offset", CamMin, CamMax)
    CamY:SetClientData("CamOffsetY", "OnValueChanged")
    CamY:DefineSetter(function(Panel, _, _, Value)
        local Y = math.Round(Value)

        Panel:SetValue(Y)

        CamOffset.y = Y

        return Y
    end)

    local CamZ = Menu:AddSlider("Z Offset", CamMin, CamMax)
    CamZ:SetClientData("CamOffsetZ", "OnValueChanged")
    CamZ:DefineSetter(function(Panel, _, _, Value)
        local Z = math.Round(Value)

        Panel:SetValue(Z)

        CamOffset.z = Z

        return Z
    end)
end

local function CreateMenu(Menu)
    local Entries = Vehicles.GetEntries()

    ACF.SetToolMode("acf_menu", "Spawner", "Vehicle")

    ACF.SetClientData("PrimaryClass", "acf_vehicle")
    ACF.SetClientData("SecondaryClass", "N/A")

    Menu:AddTitle("Vehicle Settings")
    Menu:AddLabel("Warning: Experimental!\nVehicle entities are a work in progress and may lead to some strange events!\nReport any crashes or other issues if you come across them!")
    Menu:AddLabel("Vehicles serve as an all-in-one controller for your camera and vehicle controls. You can link them directly to engines, turret drives, and gearboxes to easily manipulate those entities.")

    local VehicleClass = Menu:AddComboBox()
    local VehicleList = Menu:AddComboBox()

    local Base           = Menu:AddCollapsible("Vehicle Information")
    local VehicleName    = Base:AddTitle()
    local VehicleDesc    = Base:AddLabel()
    local VehiclePreview = Base:AddModelPreview(nil, true)
    local VehicleStats   = Base:AddLabel()

    CreateCameraMenu(Menu)

    function VehicleClass:OnSelect(Index, _, Data)
        if self.Selected == Data then return end

        self.ListData.Index = Index
        self.Selected = Data

        ACF.LoadSortedList(VehicleList, Data.Items, "Name")
    end

    function VehicleList:OnSelect(Index, _, Data)
        if self.Selected == Data then return end

        self.ListData.Index = Index
        self.Selected = Data

        ACF.SetClientData("Vehicle", Data.ID)

        VehicleName:SetText(Data.Name or "No name provided.")
        VehicleDesc:SetText(Data.Description or "No description provided.")

        VehiclePreview:UpdateModel(Data.Model)
        VehiclePreview:UpdateSettings(Data.Preview)

        local Mass = ACF.GetProperMass(Data.Mass)
        VehicleStats:SetText("Mass : " .. Mass)
    end

    ACF.LoadSortedList(VehicleClass, Entries, "ID")
end

ACF.AddMenuItem(251, "Entities", "Vehicles", "joystick", CreateMenu)