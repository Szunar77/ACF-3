local ACF = ACF

local function BaseMenu(Parent)
	local ctrl	= vgui.Create("Panel",Parent)
	Parent.Base = ctrl
	ctrl:Dock(FILL)
	ctrl:DockMargin(6,6,6,6)

	ctrl.Paint = function(_, w, h)
		surface.SetDrawColor(65,65,65)
		surface.DrawRect(0,0,w,h)

		return true
	end

	--[[
	local LeftBase = vgui.Create("DTree")
	local RightBase = vgui.Create("Panel")
	RightBase.Paint = function(_, w, h)
		surface.SetDrawColor(127,65,65)
		surface.DrawRect(0,0,w,h)

		return true
	end

	local ToolBar = vgui.Create("Panel", RightBase)
	ToolBar:SetSize(1,120)
	ToolBar:SetMouseInputEnabled(true)
	ToolBar:DockMargin(0,0,0,6)
	ToolBar:Dock(TOP)
	ToolBar.SampleMouse = function(self, x)
		if not self:IsHovered() then return false end
		-- LocalCursorPos
	end
	ToolBar.Paint = function(self, w, h)
		local RidgeWidth = math.min(w - 200, 400)
		surface.SetDrawColor(65,65,127)
		draw.NoTexture()
		local Poly = {
			{x = 0, y = 0},
			{x = RidgeWidth + 100, y = 0},
			{x = RidgeWidth, y = h},
			{x = 0, y = h}
		}
		surface.DrawRect(0,0,w,40)
		surface.DrawPoly(Poly)


		return true
	end

	local Divider = vgui.Create("DHorizontalDivider", ctrl)
	Divider:Dock(FILL)
	Divider:SetLeftWidth(300)
	Divider:SetLeft(LeftBase)
	Divider:SetRight(RightBase)
	]]--

	return ctrl
end
local function Regenerate(Panel)
	Panel.Base:Remove()
	BaseMenu(Panel)
end

spawnmenu.AddCreationTab("ACF", function()
	local Menu_BasePanel = vgui.Create("Panel")
	Menu_BasePanel.Paint = function() return true end

	BaseMenu(Menu_BasePanel)

	ACF.TabMenu = Menu_BasePanel

	return Menu_BasePanel
end, "icon16/cog.png", 15)

concommand.Add("acf_reload_tab_menu", function()
	if not IsValid(ACF.TabMenu) then return end

	Regenerate(ACF.TabMenu)
end)