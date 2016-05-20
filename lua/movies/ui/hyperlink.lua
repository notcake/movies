local PANEL = {}

function PANEL:Init ()
	self:SetTextColor (Color (32, 32, 255, 255))
	self:SetFont ("DefaultUnderlined")
	self:SetCursor ("hand")
	
	self:SetMouseInputEnabled (true)
end

vgui.Register ("movie_hyperlink", PANEL, "DLabel")