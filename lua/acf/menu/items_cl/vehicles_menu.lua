local ACF = ACF
local Vehicles = ACF.Classes.Vehicles

local function CreateMenu(Menu)
    local Entries = Vehicles.GetEntries()

    ACF.SetToolMode("acf_menu", "Spawner", "Vehicle")

    Menu:AddTitle("Vehicle Settings")
    Menu:AddLabel("Warning: Experimental!\nVehicle entities are a work in progress and may lead to some strange events!\nReport any crashes or other issues if you come across them!")
    Menu:AddLabel("Vehicles serve as an all-in-one controller for your camera and vehicle controls. You can link them directly to engines, turret drives, and gearboxes to easily manipulate those entities.")

    local VehicleClass = Menu:AddComboBox()
    local VehicleList = Menu:AddComboBox()

    local Base = Menu:AddCollapsible("Vehicle Information")
    local VehicleName = Base:AddTitle()
    local VehicleDesc = Base:AddLabel()
    local VehiclePreview = Base:AddModelPreview(nil, true)

    ACF.SetClientData("PrimaryClass", "acf_vehicle")
    ACF.SetClientData("SecondaryClass", "N/A")

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
    end

    ACF.LoadSortedList(VehicleClass, Entries, "ID")
end

ACF.AddMenuItem(251, "Entities", "Vehicles", "joystick", CreateMenu)