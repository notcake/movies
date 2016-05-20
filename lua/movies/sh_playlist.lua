local instanceID = Movies.InstanceID

local self = {}
Movies.Playlist = Movies.MakeConstructor (self)

Movies.PlaylistType = 
{
	Video = 1,
	Music = 2
}
local PlaylistType = Movies.PlaylistType

function self:ctor (id, playlistType)
	Movies.EventProvider (self)
	
	self.ID = id
	self.PlaylistType = playlistType or Movies.PlaylistType.Video
	self.MaximumVideos = 4
	self.Videos = {}
	
	self.CurrentVideoIndex = -1
	self.VideoStartTime = 0
	self.VideoEndTime = 0
	self.VideoPosition = 0
	self.Playing = false
	
	if SERVER then
		self.TimerID = "MoviePlaylist" .. tostring (self)
		timer.Create (self.TimerID, 1, 0, function ()
			if Movies.InstanceID ~= instanceID then
				timer.Destroy (self.TimerID)
				return
			end
			
			if not self:IsPlaying () then return end
			
			if CurTime () > self.VideoEndTime + 5 then
				if self.CurrentVideoIndex == #self.Videos then
					self:Seek (1, 0)
				else
					self:Seek (self.CurrentVideoIndex + 1, 0)
				end
			end
		end)
	end
end

function self:Add (video)
	if self.MaximumVideos ~= 0 and #self.Videos >= self.MaximumVideos then return end

	self.Videos [#self.Videos + 1] = video
	video.Index = #self.Videos
	
	self:DispatchEvent ("VideoAdded", video)
	
	if self:GetVideoCount () == 1 then
		self:Seek (1, 0)
	end
end

function self:Clear ()
	self.Videos = {}
	self:DispatchEvent ("Cleared")
end

function self:GetID ()
	return self.ID
end

function self:GetMaximumVideos ()
	return self.MaximumVideos
end

function self:GetPlayingPosition ()
	if not self:IsPlaying () then
		return self.VideoPosition
	end
	
	return CurTime () - self.VideoStartTime
end

function self:GetPlayingVideo ()
	return self.Videos [self.CurrentVideoIndex]
end

function self:GetPlayingVideoIndex ()
	return self.CurrentVideoIndex
end

function self:GetPlaylistType ()
	return self.PlaylistType
end

function self:GetVideo (index)
	return self.Videos [index]
end

function self:GetVideoCount ()
	return #self.Videos
end

function self:IsFull ()
	if self.MaximumVideos == 0 then return false end
	return #self.Videos >= self.MaximumVideos
end

function self:IsPlaying ()
	return self.Playing
end

function self:IsPlayingVideo (video)
	return self:GetPlayingVideoIndex () == video:GetIndex ()
end

function self:Play ()
	if self:IsPlaying () then return end
	if not self:GetPlayingVideo () then return end
	self.Playing = true
	
	if self.VideoPosition > self:GetPlayingVideo ():GetDuration () then
		self:Seek (self:GetPlayingVideoIndex (), 0)
	end
	self.VideoStartTime = CurTime () - self.VideoPosition
	self.VideoEndTime = CurTime () - self.VideoPosition + self:GetPlayingVideo ():GetDuration ()
	
	self:DispatchEvent ("VideoStarted", self:GetPlayingVideo (), self.VideoPosition)
end

function self:Pause ()
	if not self:IsPlaying () then return end
	
	self.VideoPosition = self:GetPlayingPosition ()
	self.Playing = false
	
	self:DispatchEvent ("VideoPaused")
end

function self:RemoveByIndex (index)
	local video = self.Videos [index]
	if not video then return end
	
	table.remove (self.Videos, index)
	
	-- reindex videos
	for i = index, #self.Videos do
		self.Videos [i].Index = self.Videos [i].Index - 1
	end
	
	self:DispatchEvent ("VideoRemoved", video)
	
	if #self.Videos == 0 then
		self:Pause ()
	elseif self.CurrentVideoIndex > index then
		self.CurrentVideoIndex = self.CurrentVideoIndex - 1
	elseif self.CurrentVideoIndex == index then
		self.CurrentVideoIndex = -1
		if index > #self.Videos then
			if #self.Videos == 0 then
				self:Pause ()
			else
				self:Seek (1, 0)
			end
		else
			self:Seek (index, 0)
		end
	end
end

function self:Seek (index, time)
	if index <= 0 then return end
	if index > #self.Videos then return end
	if time < 0 then return end
	
	if self.CurrentVideoIndex == index and time == self:GetPlayingPosition () then return end

	self.CurrentVideoIndex = index
	self.VideoStartTime = CurTime () - time
	self.VideoEndTime = CurTime () - time + self:GetPlayingVideo ():GetDuration ()
	self.VideoPosition = time
	
	self:DispatchEvent ("VideoSeeked", self:GetPlayingVideo (), time)
end

function self:SetMaximumVideos (maximum)
	self.MaximumVideos = maximum
end

function self:SetPlaylistType (playlistType)
	self.PlaylistType = playlistType
end