local self = {}

Movies.Video = Movies.MakeConstructor (self)

function self:ctor (id)
	self.Playlist = nil

	self.Index = 0
	self.ID = id
	self.URL = ""
	self.VideoHost = ""
	self.VideoID = ""
	self.Duration = 0
	
	self.Data = nil
end

function self:ClearData ()
	self.Data = nil
end

function self:GetData (callback)
	if self.Data then
		callback (self.Data)
		return
	end
	
	local videoID = self.VideoID
	Movies.YoutubeQuery (self.VideoID, function (data)
		if self.VideoID ~= videoID then return end
		
		self.Data = data
		self.Duration = self.Data.Duration
		callback (self.Data)
	end)
end

function self:GetDuration ()
	return self.Duration
end

function self:GetIndex ()
	return self.Index
end

function self:GetPlaylist ()
	return self.Playlist
end

function self:GetURL ()
	return self.URL
end

function self:GetVideoID ()
	return self.VideoID
end

function self:ReadData (umsg)
	self:SetURL (umsg:ReadString ())
	self.Duration = umsg:ReadFloat ()
end

function self:SendData (umsg)
	umsg.String (self.URL)
	umsg.Float (self.Duration)
end

function self:SetPlaylist (playlist)
	self.Playlist = playlist
end

function self:SetURL (url)
	self.URL = url
	
	local _, videoHost, videoID = Movies.ValidateURL (url)
	self.VideoHost = videoHost
	self.VideoID = videoID
end