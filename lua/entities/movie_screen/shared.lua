ENT.Type 		= "anim"
ENT.Base 		= "base_entity"

ENT.PrintName	= "Movie Screen"
ENT.Author		= ""
ENT.Contact		= ""

function ENT:GetScreen ()
	return Movies.GetScreen (self:EntIndex ())
end