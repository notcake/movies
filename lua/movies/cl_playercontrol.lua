local instanceID = Movies.InstanceID

local self = {}
Movies.PlayerControl = Movies.MakeConstructor (self)

-- local PlayerURL = "http://dl.dropbox.com/u/7290193/Garrysmod/rpland/player.html"
local PlayerURL = "http://www.rpland.org/player.html"
local UseMaterial = false
local DrawOverTransparentProps = false

Movies.PlayerResolutions =
{
	[0] = {w =  320, h =  179},
	[1] = {w =  285, h =  160},
	[2] = {w =  427, h =  240},
	[3] = {w =  640, h =  360},
	[4] = {w =  853, h =  480},
	[5] = {w = 1280, h =  720},
	[6] = {w = 1920, h = 1080}
}

function self:ctor (playlistID)
	self.PlaylistID = playlistID
	self.Playlist = nil

	--[[
		ResolutionIndex controls the video quality and lag.
		Higher Values mean better quality videos, but more fps lag.
		Range goes from 0 to 6. You may enter your own resolution in
		entry 0 of Movies.PlayerSizes above and set SizeIndex to 0. w : h is recommended to
		have a 16 : 9 ratio.
	]]
	self.ResolutionIndex = 0

	self.HTMLPanelContainer = nil
	self.HTMLPanel = nil

	self.CurrentVideo = nil
	
	self.Creating = false
	self.Created = false
	self.Disabled = true
end

function self:_CheckPlayer ()
	if Movies.InstanceID ~= instanceID then return end
	if not self.Creating then return end
	if self.Created then return end

	self.EntireWaitStartTime = self.EntireWaitStartTime or CurTime ()
	self.WaitStartTime = self.WaitStartTime or CurTime ()
	if CurTime () - self.EntireWaitStartTime > 60 then
		ErrorNoHalt ("Radio System: Unable to load Youtube player API.\n")
		self.EntireWaitStartTime = nil
	end
	if CurTime () - self.WaitStartTime > 5 then
		self.WaitStartTime = nil
		self.HTMLPanel:OpenURL (PlayerURL)
		return
	else
		timer.Simple (0.5, function ()
			self:_CheckPlayer ()
		end)
	end
	
	self.HTMLPanel.OpeningURL = function (htmlPanel, url)
		if url == "http://done/" then
			self.Creating = false
			self.Created = true
			self.Disabled = false
			self:ResizePlayer (self.HTMLPanel:GetSize ())
			
			self:_ResumePlaylist ()
			
			return true
		end
	end
	
	self.HTMLPanel:Exec (
		[[
			if (window.youTubePlayer != undefined)
			{
				window.location = "http://done";
			}
		]]
	)
end

function self:_ResumePlaylist ()
	if Radio.InstanceID ~= instanceID then return end

	if not self:AcquirePlaylist () then
		timer.Simple (0, function ()
			self:_ResumePlaylist ()
		end)
		return
	end
			
	local video = self.Playlist:GetPlayingVideo ()
	local time = self.Playlist:GetPlayingPosition ()
	local playing = self.Playlist:IsPlaying ()
	
	if not video then
		self:Stop ()
		return
	end
	
	self:Seek (video, time)
	if playing then
		self:Play ()
	end
end

function self:AcquirePlaylist ()
	if self.Playlist then return true end
	
	self.Playlist = Movies.Playlists:GetPlaylist (self.PlaylistID)
	if not self.Playlist then return false end
	
	return true
end

function self:CreatePlayer ()
	if self.HTMLPanel and self.HTMLPanel:IsValid () then return end
	if self.Creating then return end
	
	self.Creating = true
	
	self.HTMLPanelContainer = vgui.Create ("Panel")
	self.HTMLPanelContainer:SetSize (1, 1)
	
	self.HTMLPanel = vgui.Create ("HTML", self.HTMLPanelContainer)
	self.HTMLPanel:SetSize (self:GetSize ())
	self.HTMLPanel:SetMouseInputEnabled (false)
	if UseMaterial then
		self.HTMLPanel:SetPaintedManually (true)
	end
	self.HTMLPanel.FinishedURL = function ()
		self:_CheckPlayer ()
	end
	
	self.HTMLPanel:OpenURL (PlayerURL)
end

function self:DestroyPlayer ()
	if self.Creating then
		timer.Simple (1, function ()
			self:DestroyPlayer ()
		end)
		return
	end

	if self.HTMLPanel then
		self.HTMLPanel:Remove ()
		self.HTMLPanel = nil
	end
	if self.HTMLPanelContainer then
		self.HTMLPanelContainer:Remove ()
		self.HTMLPanelContainer = nil
	end
	
	self.TargetVolume = -1
	
	self.CurrentVideo = nil
	
	self.Creating = false
	self.Created = false
	self.Disabled = true
end

function self:Disable ()
	self:Pause ()
	self.Disabled = true
end

function self:Enable ()
	if not self:IsCreated () then
		self:CreatePlayer ()
		return
	end

	self.Disabled = false
	self:_ResumePlaylist ()
end

function self:Draw (entID)
	local screen = Movies.GetScreen (entID)
	if not screen then return end
	if not self.Disabled then
		if not self.HTMLPanel or not self.HTMLPanel:IsValid () then return end
	end
	
	local htmlMaterial = nil
	if not self.Disabled and UseMaterial then
		htmlMaterial = self.HTMLPanel:GetHTMLMaterial ()
		if not htmlMaterial then return end
	end
	
	local w, h = self:GetSize ()
	local scale = math.min (screen:GetWidth () / w, screen:GetHeight () / h)
	local centre = screen:GetCentre ()
	local right = screen:GetRight ()
	local down = screen:GetDown ()
	
	local angle = screen:GetNormalAngle ()
	angle.y = angle.y + 90
	angle.r = angle.r + 90
	
	cam.Start3D2D (centre - w / 2 * right * scale - h / 2 * down * scale, angle, scale)
		if self.Disabled then
			surface.SetDrawColor (Color (0, 0, 0, 255))
			surface.DrawRect (0, 0, self:GetSize ())
		elseif UseMaterial then
			local texture = htmlMaterial:GetMaterialTexture ("$basetexture")
			local tw = texture:GetActualWidth ()
			local th = texture:GetActualHeight ()
		
			render.SetMaterial (htmlMaterial)
			render.DrawQuad (
				Vector (0, 0, 0),
				Vector (tw, 0, 0),
				Vector (tw, th, 0),
				Vector (0, th, 0)
			)
		else
			self.HTMLPanel:PaintManual ()
		end
	cam.End3D2D ()
end

function self:GetSize ()
	return Movies.PlayerResolutions [self.ResolutionIndex].w, Movies.PlayerResolutions [self.ResolutionIndex].h
end

function self:IsCreated ()
	return self.Created
end

function self:IsDisabled ()
	return self.Disabled
end

function self:Pause ()
	if not self.Created then return end
	self.HTMLPanel:Exec ("youTubePlayer.pauseVideo ();")
end

function self:Play ()
	if not self.Created or self.Disabled then return end
	self.HTMLPanel:Exec ("youTubePlayer.playVideo ();")
end

function self:Resize (w, h)
	if not self.Created then return end
	self.HTMLPanel:SetSize (w, h)
	self.HTMLPanel:Exec ("youTubePlayer.width = " .. tostring (w) .. ";")
	self.HTMLPanel:Exec ("youTubePlayer.height = " .. tostring (h) .. ";")
end

function self:ResizePlayer (w, h)
	if not self.Created then return end
	self.HTMLPanel:Exec ("youTubePlayer.width = " .. tostring (w) .. ";")
	self.HTMLPanel:Exec ("youTubePlayer.height = " .. tostring (h) .. ";")
end

function self:Seek (video, time)
	if not self.Created or self.Disabled then return end
	
	if self.CurrentVideo ~= video then
		self.CurrentVideo = video
		self.HTMLPanel:Exec ("youTubePlayer.cueVideoById (\"" .. video:GetVideoID () .. "\", " .. tostring (time) .. ");")
		
		if self.Playlist:IsPlaying () then
			self:Play ()
		end
	else
		self.HTMLPanel:Exec ("youTubePlayer.seekTo (\"" .. tostring (time) .. "\");")
		if not self.Playlist:IsPlaying () then
			self:Pause ()
		end
	end
end

function self:SetVolume (volume)
	if not self.Created then return end
	volume = math.floor (volume)
	
	self.HTMLPanel:Exec ("youTubePlayer.setVolume (" .. tostring (volume) .. ");")
end

function self:Stop ()
	if not self.Created then return end
	self.HTMLPanel:Exec ("youTubePlayer.stopVideo ();")
	self.HTMLPanel:Exec ("youTubePlayer.cueVideoById (\"\", 0);")
end