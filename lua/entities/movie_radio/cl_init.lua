ENT.Spawnable			= false
ENT.AdminSpawnable		= false

include ("shared.lua")

function ENT:Initialize()
end

function ENT:Draw ()
	self:DrawModel ()
	
	surface.SetFont ("HUDNumber5")
	local textWidth, textHeight = surface.GetTextSize ("Radio")

	local pos = self:GetPos () + self:GetAngles ():Up () * 15
	local ang = self:GetAngles ()
	ang:RotateAroundAxis (ang:Forward (), 90)
	ang:RotateAroundAxis (ang:Right (), CurTime () * -180)
	
	if LocalPlayer and LocalPlayer () and LocalPlayer ():IsValid () then
		if (pos - LocalPlayer ():EyePos ()):Dot (ang:Up ()) > 0 then
			ang:RotateAroundAxis (ang:Right (), 180)
		end
	end
	
	cam.Start3D2D (pos, ang, 0.1)
		draw.WordBox (20, -textWidth * 0.5 - 20, -100, "Radio", "HUDNumber5", Color (0, 0, 140, 100), Color (255, 255, 255, 255))
	cam.End3D2D ()
end

function ENT:OnRemove ()
end

function ENT:Think ()
	if not Radio then return end
	if self:GetNetworkedBool ("Playing", true) then
		Radio.RadioPlayer:KeepAlive (self:EntIndex ())
	else
		Radio.RadioPlayer:KeepDead (self:EntIndex ())
	end
	Radio.RadioPlayer:UpdateVolume ()
end