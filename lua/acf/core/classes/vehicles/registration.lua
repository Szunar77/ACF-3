-- Localize global variables
local ACF     = ACF
local Classes = ACF.Classes
local Vehicles = Classes.Vehicles
local Entries = {}

function Vehicles.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	if not Group.LimitConVar then
		Group.LimitConVar = {
			Name   = "_acf_vehicle",
			Amount = 16,
			Text   = "Maximum amount of ACF vehicles a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	return Group
end

function Vehicles.RegisterItem(ID, ClassID, Data)
	return Classes.AddGroupItem(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Vehicles, Entries)