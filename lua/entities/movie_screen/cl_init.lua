ENT.Spawnable			= false
ENT.AdminSpawnable		= false

include ("shared.lua")

function ENT:Initialize()
	self:DrawShadow (false)
	self.RenderBoundsSet = false
end

function ENT:Draw ()
	if not Movies then return end
	if not self.RenderBoundsSet then
		self:UpdateRenderBounds ()
	end
	
	Movies.MoviePlayer:KeepAlive (self:EntIndex ())
	Movies.MoviePlayer:Draw (self:EntIndex ())
	
	-- self:DrawModel ()
end

function ENT:UpdateRenderBounds ()
	if not Movies then return end
	local screen = Movies.GetScreen (self:EntIndex ())
	if not screen then return end
	
	self.RenderBoundsSet = true
	self:SetRenderBoundsWS (screen:GetRenderBounds ())
end

function ENT:OnRemove ()
end