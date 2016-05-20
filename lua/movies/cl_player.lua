local instanceID = Movies.InstanceID

local self = {}
Movies.Player = Movies.MakeConstructor (self, entityID)

function self:ctor (playlistID)
	self.PlaylistID = playlistID
	self.Playlist = nil
	
	self.PlayerControl = Movies.PlayerControl (self.PlaylistID)

	self.RefCount = 0
	self.Entities = {}
	self.EntityID = entityID or -1
	self.Entity = ents.GetByIndex (self.EntityID)	-- main parent entity
	
	self.CurrentVideo = nil
	self.TargetVolume = -1
	
	-- Drawing
	self.DrawEntity = nil
	self.InDrawingHook = false
	
	self.MaximumRadius = 900
	
	self.TimerID = "MoviePlayer" .. tostring (self)
	timer.Create (self.TimerID, 0.5, 0, function ()
		-- unload player control if movie system has been reloaded
		if Movies.InstanceID ~= instanceID then
			self.PlayerControl:DestroyPlayer ()
			timer.Destroy (self.TimerID)
			return
		end
		
		-- attempt to link with playlist
		self:AcquirePlaylist ()
		
		-- remove inactive entities from list
		local toRemove = {}
		for entID, lastTime in pairs (self.Entities) do
			if CurTime () - lastTime > 1 then
				toRemove [#toRemove + 1] = entID
			end
		end
		
		for _, entID in ipairs (toRemove) do
			self.Entities [entID] = nil
			self.RefCount = self.RefCount - 1
		end
		
		-- if not being referenced by any active entities, disable
		if #toRemove > 0 and self.RefCount == 0 then
			self.PlayerControl:Disable ()
		end
	end)
	
	hook.Add (DrawOverTransparentProps and "PostDrawTranslucentRenderables" or "PostDrawOpaqueRenderables", self.TimerID, function ()
		if Movies.InstanceID ~= instanceID then
			hook.Remove (DrawOverTransparentProps and "PostDrawTranslucentRenderables" or "PostDrawOpaqueRenderables", self.TimerID)
			return
		end
		if not self.DrawEntity then return end
	
		self.InDrawingHook = true
		self:Draw (self.DrawEntity)
		self.DrawEntity = nil
		self.InDrawingHook = false
	end)
end

function self:AcquirePlaylist ()
	if self.Playlist then return true end
	
	self.Playlist = Movies.Playlists:GetPlaylist (self.PlaylistID)
	if not self.Playlist then return false end
	
	self.Playlist:AddEventListener ("VideoPaused", "Player", function (playlist)
		self.PlayerControl:Pause ()
	end)
	
	self.Playlist:AddEventListener ("VideoRemoved", "Player", function (playlist, video)
		if playlist:GetVideoCount () == 0 then
			self.PlayerControl:Stop ()
		end
	end)
	
	self.Playlist:AddEventListener ("VideoSeeked", "Player", function (playlist, video, time)
		self.PlayerControl:Seek (video, time)
	end)
	
	self.Playlist:AddEventListener ("VideoStarted", "Player", function (playlist, video, time)
		self.PlayerControl:Play ()
	end)
	
	return true
end

function self:Draw (entID)
	if not self.InDrawingHook then
		self.DrawEntity = entID
		return
	end
	
	self.PlayerControl:Draw (entID)
	self:UpdateVolume (screen)
end

function self:KeepAlive (entID)
	local entity = ents.GetByIndex (entID)
	if not entity or not entity:IsValid () then return end
	if (LocalPlayer ():GetPos () - entity:GetPos ()):Length () > self.MaximumRadius then return end
	
	if not self.Entities [entID] then		
		self.RefCount = self.RefCount + 1
		
		if self.RefCount == 1 then
			self.PlayerControl:Enable ()
		end
	end
	self.Entities [entID] = CurTime ()
	self:UpdateVolume (screen)
	self:UpdateClosestEntity ()
end

function self:KeepDead (entID)
	if not self.Entities [entID] then return end
		
	self.RefCount = self.RefCount - 1
	self.Entities [entID] = nil
	if self.EntityID == entID then
		self.Entity = nil
		self.EntityID = nil
	end
		
	if self.RefCount == 0 then
		self.PlayerControl:Disable ()
	end
end

function self:UpdateClosestEntity ()
	local closestEntity = nil
	local closestDistance = math.huge
	for entID, _ in pairs (self.Entities) do
		local entity = ents.GetByIndex (entID)
		if entity and entity:IsValid () then
			local distance = (entity:GetPos () - LocalPlayer ():GetPos ()):Length ()
			if distance < closestDistance then
				closestEntity = entity
				closestDistance = distance
			end
		end
	end
	
	self.Entity = closestEntity
	if self.Entity and self.Entity:IsValid () then
		self.EntityID = self.Entity:EntIndex ()
	end
end

function self:UpdateVolume (screen)
	local dist = math.huge
	if self.Entity and self.Entity:IsValid () then
		dist = (LocalPlayer ():GetPos () - self.Entity:GetPos ()):Length ()
	end
	
	local volume = 100
	if dist < self.MaximumRadius * 0.5 then
		volume = 100
	else
		dist = dist - self.MaximumRadius * 0.5
		volume = math.Clamp (100 - dist / self.MaximumRadius * 2 * 100, 0, 100)
	end
	
	if self.TargetVolume ~= volume then
		self.TargetVolume = volume
		self.PlayerControl:SetVolume (volume)		
	end
end

Movies.MoviePlayer = Movies.Player ("movies", entityID)
Movies.RadioPlayer = Movies.Player ("radio", entityID)
Movies.RadioPlayer.MaximumRadius = 380