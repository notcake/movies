AddCSLuaFile ("cl_init.lua")
AddCSLuaFile ("shared.lua")

include ("shared.lua")

function ENT:Initialize ()
	self:DrawShadow (false)
	Movies.RegisterScreen (self:EntIndex ())
end

function ENT:OnRemove ()
	Movies.UnregisterScreen (self:EntIndex ())
end