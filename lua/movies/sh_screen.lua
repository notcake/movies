local self = {}
Movies.Screen = Movies.MakeConstructor (self)

function self:ctor (entID)
	self.EntityID = entID
	
	self.PlaylistID = nil
	
	self.Centre = Vector (0, 0, 0)
	self.Down = Vector (0, 0, -1)
	self.Right = Vector (1, 0, 0)
	self.Width = 854 / 2
	self.Height = 480 / 2
	
	self.WorldMin = nil
	self.WorldMax = nil
end

function self:CalculateRenderBounds ()
	local topLeft = self.Centre - self.Right * self.Width / 2 - self.Down * self.Height / 2
	local topRight = self.Centre + self.Right * self.Width / 2 - self.Down * self.Height / 2
	local bottomLeft = self.Centre - self.Right * self.Width / 2 + self.Down * self.Height / 2
	local bottomRight = self.Centre + self.Right * self.Width / 2 + self.Down * self.Height / 2
	local points = {topLeft, topRight, bottomLeft, bottomRight}
	
	local min = Vector (math.huge, math.huge, math.huge)
	local max = Vector (-math.huge, -math.huge, -math.huge)
	
	for i = 1, 4 do
		local v = points [i]
		if v.x < min.x then min.x = v.x end
		if v.y < min.y then min.y = v.y end
		if v.z < min.z then min.z = v.z end
		if v.x > max.x then max.x = v.x end
		if v.y > max.y then max.y = v.y end
		if v.z > max.z then max.z = v.z end
	end
	
	self.WorldMin = min
	self.WorldMax = max
	
	return self.WorldMin, self.WorldMax
end

function self:CopyFrom (screen)
	self.PlaylistID = screen.PlaylistID
	
	self.Centre = screen.Centre
	self.Down = screen.Down
	self.Right = screen.Right
	self.Width = screen.Width
	self.Height = screen.Height
	
	self:CalculateRenderBounds ()
	if self:GetEntity () and self:GetEntity ():IsValid () and self:GetEntity ().UpdateRenderBounds then
		self:GetEntity ():UpdateRenderBounds ()
	end
end

function self:GetCentre ()
	return self.Centre
end

function self:GetDown ()
	return self.Down
end

function self:GetEntity ()
	return ents.GetByIndex (self.EntityID)
end

function self:GetHeight ()
	return self.Height
end

function self:GetNormal ()
	return self.Down:Cross (self.Right):GetNormalized ()
end

function self:GetNormalAngle ()
	return self:GetNormal ():Angle ()
end

function self:GetPlaylistID ()
	return self.PlaylistID
end

function self:GetRenderBounds ()
	if not self.WorldMin or not self.WorldMax then
		return self:CalculateRenderBounds ()
	end
	
	return self.WorldMin, self.WorldMax
end

function self:GetRight ()
	return self.Right
end

function self:GetWidth ()
	return self.Width
end

function self:IsBasisOrthogonal ()
	return math.abs (self.Right:Dot (self.Down)) < 0.001
end

function self:SetCentre (centre)
	self.Centre = centre
	
	self.WorldMin = nil
	self.WorldMax = nil
end

function self:SetDown (down)
	self.Down = down
	
	self.WorldMin = nil
	self.WorldMax = nil
end

function self:SetHeight (height)
	self.Height = height
	
	self.WorldMin = nil
	self.WorldMax = nil
end

function self:SetNormalAngle (angle)
	self.Right = -angle:Right ()
	self.Down = -angle:Up ()
	
	self.WorldMin = nil
	self.WorldMax = nil
end

function self:SetPlaylistID (playlistID)
	self.PlaylistID = playlistID
end

function self:SetRight (right)
	self.Right = right
	
	self.WorldMin = nil
	self.WorldMax = nil
end

function self:SetWidth (width)
	self.Width = width
	
	self.WorldMin = nil
	self.WorldMax = nil
end

function self:ReadData (umsg)
	self.PlaylistID = umsg:ReadString ()
	self.Centre = umsg:ReadVector ()
	self.Down = umsg:ReadVector ()
	self.Right = umsg:ReadVector ()
	self.Width = umsg:ReadFloat ()
	self.Height = umsg:ReadFloat ()
	
	self:CalculateRenderBounds ()
	if self:GetEntity () and self:GetEntity ():IsValid () and self:GetEntity ().UpdateRenderBounds then
		self:GetEntity ():UpdateRenderBounds ()
	end
end

function self:WriteData (umsg)
	umsg.Long (self.EntityID)
	
	umsg.String (self.PlaylistID or "")
	umsg.Vector (self.Centre)
	umsg.Vector (self.Down)
	umsg.Vector (self.Right)
	umsg.Float (self.Width)
	umsg.Float (self.Height)
end