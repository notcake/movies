local PANEL = {}

function PANEL:Init ()
	self.Playlist = nil
	self.Video = nil
end

function PANEL:Paint ()
	local time = 0
	local duration = 0
	
	if self.Playlist and self.Video then
		if self.Playlist:IsPlayingVideo (self.Video) then
			time = self.Playlist:GetPlayingPosition ()
		end
		duration = self.Video:GetDuration ()
	end
	
	local percentage = time / duration
	if duration == 0 then percentage = 0 end
	percentage = math.Clamp (percentage, 0, 1)
	
	local cy = self:GetTall () / 2
	local left = 4
	local right = self:GetWide () - 4
	local w = right - left
	
	draw.RoundedBox (4, left, cy - 4, w, 8, Color (128, 128, 128, 255))
	draw.RoundedBox (4, left, cy - 4, math.max (6, w * percentage), 8, Color (128, 0, 0, 255))
	
	if self.Hovered then
		surface.SetFont ("Default")
		local percentage = self:PercentageFromPosition (self:CursorPos ())
		local mid = percentage * w + 4
		
		local time = Movies.FormatTime (duration * percentage)
		surface.SetFont ("Default")
		local textw, texth = surface.GetTextSize (time)
		if mid - textw / 2 < 4 then
			mid = 4 + textw / 2
		end
		if mid + textw / 2 > self:GetWide () - 4 then
			mid = self:GetWide () - 4 - textw / 2
		end
		draw.DrawText (time, "Default", mid, cy - texth / 2 - 1, Color (255, 255, 255, 255), TEXT_ALIGN_CENTER)
	end
end

function PANEL:PercentageFromPosition (x)
	local w = self:GetWide () - 8
	x = x - 4
	return math.Clamp (x / w, 0, 1)
end

function PANEL:SetPlaylist (playlist)
	self.Playlist = playlist
end

function PANEL:SetVideo (video)
	self.Video = video
end

vgui.Register ("movie_video_progress", PANEL)