local PANEL = {}
mat = Material ("vgui/white")

function PANEL:Init ()
	self.Icon = "play"
	self:SetText ("")
	
	self:SetSize (24, 24)
end

function PANEL:GetIcon ()
	return self.Icon
end

function PANEL:Paint ()
	local w = self:GetWide ()
	local h = self:GetTall ()
	local cx = w / 2
	local cy = h / 2
	
    derma.SkinHook ("Paint", "Button", self)
	
	surface.SetDrawColor (255, 255, 255, 255)
	if self.Icon == "play" then
		surface.SetMaterial (mat)
		surface.DrawPoly (
			{
				{x = cx - 6, y = cy - 6, u = 0, v = 0},
				{x = cx + 6, y = cy, u = 0, v = 0},
				{x = cx - 6, y = cy + 6, u = 0, v = 0}
			}
		)
	elseif self.Icon == "pause" then
		surface.DrawRect (cx - 4, cy - 6, 3, 12)
		surface.DrawRect (cx + 1, cy - 6, 3, 12)
	end
	
    derma.SkinHook ("PaintOver", "Button", self)
end

function PANEL:SetIcon (icon)
	self.Icon = icon
end

vgui.Register ("movie_play_button", PANEL, "DButton")