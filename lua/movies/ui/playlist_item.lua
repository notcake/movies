local PANEL = {}

function PANEL:Init ()
	self.Playlist = nil
	self.Video = nil
	self.State = "novideo"
	
	self:SetTall (self:GetPreferredHeight ())
	
	self.Delete = vgui.Create ("DSysButton", self)
	self.Delete:SetType ("close")
	self.Delete:SetDrawBackground (false)
	self.Delete:SetDrawBorder (false)
	self.Delete:SetSize (16, 16)
	self.Delete.DoClick = function (button)
		if not self.Video then return end
		
		RunConsoleCommand ("movie_remove_video", self.Playlist:GetID (), tostring (self.Video:GetIndex ()))
	end

	self.Image = vgui.Create ("HTML", self)
	self.Image:SetSize (120, 90)
	self.Image:SetMouseInputEnabled (false)
	self.Title = vgui.Create ("DLabel", self)
	self.Title:SetFont ("TargetID")
	self.Title:SetTextColor (Color (255, 255, 255, 255))
	
	self.Description = vgui.Create ("DLabel", self)
	self.Description:SetWrap (true)
	self.Description:SetContentAlignment (7)
	
	self.Duration = vgui.Create ("DLabel", self)
	self.Duration:SetContentAlignment (5)
	self.Duration.Paint = function (label)
		draw.RoundedBoxEx (4, 0, 0, label:GetWide (), label:GetTall (), Color (0, 0, 0, 192), true, false, false, false)
	
		return DLabel.Paint (label)
	end
	
	self.Author = vgui.Create ("DLabel", self)
	
	self.Play = vgui.Create ("movie_play_button", self)
	self.Play:SetVisible (false)
	self.Play.DoClick = function (button)
		if not self.Video then return end
		
		local icon = button:GetIcon ()
		if icon == "play" then
			if not self.Playlist:IsPlayingVideo (self.Video) then
				RunConsoleCommand ("movie_seek_video", self.Playlist:GetID (), tostring (self.Video:GetIndex ()), "0")
			end
			RunConsoleCommand ("movie_play_video", self.Playlist:GetID ())
		elseif icon == "pause" then
			RunConsoleCommand ("movie_pause_video", self.Playlist:GetID ())
		end
	end
	self.Progress = vgui.Create ("movie_video_progress", self)
	self.Progress:SetVisible (false)
	self.Progress.OnMousePressed = function (progress)
		if not self.Video then return end
		
		local percentage = self.Progress:PercentageFromPosition (self.Progress:CursorPos ())
		RunConsoleCommand ("movie_seek_video", self.Playlist:GetID (), tostring (self.Video:GetIndex ()), tostring (percentage * self.Video:GetDuration ()))
	end
	
	self.Created = true
end

function PANEL:GetPreferredHeight ()
	return 106
end

function PANEL:OnCursorEntered ()
	self.Hovered = true
	
	self.Play:SetVisible (true)
	self.Delete:SetVisible (true)
end

function PANEL:OnCursorExited ()
end

function PANEL:PerformLayout ()
	if not self.Created then return end
	
	self.Delete:SetPos (self:GetWide () - self.Delete:GetWide (), 0)

	self.Image:SetPos (8, (self:GetTall () - self.Image:GetTall ()) * 0.5)
	
	self.Author:SizeToContents ()
	self.Author:SetPos (16 + self.Image:GetWide (), self:GetTall () - self.Author:GetTall () - 8)
	
	self.Title:SetPos (16 + self.Image:GetWide (), 8)
	self.Title:SetWide (self:GetWide () - self.Image:GetWide () - 24)
	self.Description:SetPos (16 + self.Image:GetWide (), 32)
	self.Description:SetWide (self:GetWide () - self.Image:GetWide () - 24)
	self.Description:SetTall (self:GetTall () - 40 - self.Author:GetTall ())
	
	self.Duration:SizeToContents ()
	self.Duration:SetWide (self.Duration:GetWide () + 4)
	self.Duration:SetTall (self.Duration:GetTall () + 4)
	self.Duration:SetPos (8 + self.Image:GetWide () - self.Duration:GetWide (), 8 + self.Image:GetTall () - self.Duration:GetTall ())
	
	self.Play:SetPos (8 + self.Image:GetWide () + 128, self:GetTall () - self.Play:GetTall () - 8)
	self.Progress:SetPos (8 + self.Image:GetWide () + 128 + self.Play:GetWide (), self:GetTall () - self.Progress:GetTall () - 8)
	self.Progress:SetSize (self:GetWide () - 8 - self.Image:GetWide () - 128 - self.Play:GetWide (), self.Play:GetTall ())
	
	if self.State == "novideo" then
		self.Description:SetVisible (false)
		self.Duration:SetVisible (false)
		self.Author:SetVisible (false)
		self.Image:SetVisible (false)
		
		self.Title:SetText ("Getting video information...")
		self.Title:SetTextColor (Color (192, 192, 192, 255))
	elseif self.State == "notfound" then
		self.Title:SetTextColor (Color (128, 0, 0, 255))
		self.Description:SetVisible (false)
		self.Duration:SetVisible (false)
		self.Author:SetVisible (false)
		self.Image:SetVisible (false)
	else
		self.Title:SetTextColor (Color (255, 255, 255, 255))
		self.Description:SetVisible (true)
		self.Duration:SetVisible (true)
		self.Author:SetVisible (true)
		self.Image:SetVisible (true)
	end
end

function PANEL:SetPlaylist (playlist)
	self.Playlist = playlist
	self.Progress:SetPlaylist (playlist)
	self:UpdateUI ()
end

function PANEL:SetVideo (video)
	self.Video = video
	self.Progress:SetVideo (video)
	
	self.Video:GetData (function (data)
		if not self or not self:IsValid () then return end
		
		self:UpdateData (data)
	end)
end

function PANEL:Think ()
	self.Hovered = true
	local panel = self
	local x, y = self:CursorPos ()
	while panel and panel:IsValid () do
		if x < 0 or y < 0 then self.Hovered = false end
		if x > panel:GetWide () or y > panel:GetTall () then self.Hovered = false end
		
		local dx, dy = panel:GetPos ()
		x = x + dx
		y = y + dy
		panel = panel:GetParent ()
	end

	if self.Hovered then return end
	if not self.Playlist:IsPlayingVideo (self.Video) then
		self.Play:SetVisible (false)
		self.Progress:SetVisible (false)
	end
	self.Delete:SetVisible (false)
end

function PANEL:UpdateData (data)
	if not data.Exists then
		self.State = "notfound"
		self.Title:SetText ("Video not found.")
		
		self:PerformLayout ()
		return
	end
	
	self.State = "video"
	
	self.Title:SetText (data.Title)
	self.Description:SetText (data.Description)
	
	self.Duration:SetText (Movies.FormatTime (data.Duration))
	
	local viewCount = tostring (data.ViewCount)
	local viewCountString = ""
	for i = 1, viewCount:len () do
		viewCountString = viewCount:sub (-i, -i) .. viewCountString
		if i % 3 == 0 and i ~= viewCount:len () then
			viewCountString = "," .. viewCountString
		end
	end
	
	self.Author:SetText ("by " .. data.Author .. "\n" .. viewCountString .. " views")
	
	self.Image:SetSize (data.SmallThumbnail.Width, data.SmallThumbnail.Height)
	self.Image:OpenURL ("google.com")
	timer.Simple (1,
		function ()
			self.Image:SetHTML (
			[[
				<html>
					<head>
					</head>
					<body style="overflow: hidden">
						<img src="]] .. data.SmallThumbnail.URL .. [[" style="position:absolute;top:0px;left:0px">
					</body>
				</html>
			]])
		end
	)
	
	self:PerformLayout ()
end

function PANEL:UpdateUI ()
	local playingVideo = false
	local playing = false
	if self.Playlist and self.Video then
		playingVideo = self.Playlist:IsPlayingVideo (self.Video)
		playing = self.Playlist:IsPlaying ()
	end
	
	if playingVideo then
		self.Play:SetVisible (true)
		self.Progress:SetVisible (true)
		if playing then
			self.Play:SetIcon ("pause")
		else
			self.Play:SetIcon ("play")
		end
	else
		self.Play:SetIcon ("play")
		self.Progress:SetVisible (false)
		if not self.Hovered then
			self.Play:SetVisible (false)
		end
	end
end

vgui.Register ("movie_playlist_item", PANEL, "DPanel")