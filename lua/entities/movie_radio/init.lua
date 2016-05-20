AddCSLuaFile ("cl_init.lua")
AddCSLuaFile ("shared.lua")

include ("shared.lua")

function ENT:Initialize ()
	self:SetModel ("models/props_lab/citizenradio.mdl")
	
	self:PhysicsInit (SOLID_VPHYSICS)
	self:SetMoveType (MOVETYPE_VPHYSICS)
	self:SetSolid (SOLID_VPHYSICS)
	if self:GetPhysicsObject():IsValid () then
		self:GetPhysicsObject():Wake ()
	end
	
	self:SetUseType (SIMPLE_USE)
	self:SetNetworkedBool ("Playing", true)
end

function ENT:OnRemove ()
end

function ENT:Use (activator)
	self:SetNetworkedBool ("Playing", not self:GetNetworkedBool ("Playing", true))
	
	if not Movies then return end
	if not activator:IsPlayer () then return end
	
	if self:GetNetworkedBool ("Playing", true) then
		Movies.Notify (activator, "The radio is now turned on.")
	else
		Movies.Notify (activator, "The radio is now turned off.")
	end
end