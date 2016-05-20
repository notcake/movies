local self = {}
Movies.PlaylistCollection = Movies.MakeConstructor (self)

function self:ctor (id)
	Movies.EventProvider (self)
	
	self.Playlists = {}
	self.PlaylistCount = 0
end

function self:Add (playlist)
	if self.Playlists [playlist:GetID ()] then return end
	
	self.Playlists [playlist:GetID ()] = playlist
	self.PlaylistCount = self.PlaylistCount + 1
	
	self:DispatchEvent ("PlaylistAdded", playlist)
end

function self:Clear ()
	self.Playlists = {}
	self:DispatchEvent ("Cleared")
end

function self:CreatePlaylist (id, playlistType)
	if self.Playlists [id] then return end
	
	local playlist = Movies.Playlist (id, playlistType)
	self:Add (playlist)
	return playlist
end

function self:GetPlaylist (id)
	return self.Playlists [id]
end

function self:GetOrCreatePlaylist (id)
	if not self.Playlists [id] then
		self:CreatePlaylist (id)
	end
	
	return self.Playlists [id]
end

function self:GetPlaylistCount ()
	return #self.Playlists
end

function self:RemoveByID (id)
	if not self.Playlists [id] then return end
	
	local playlist = self.Playlists [id]
	self.Playlists [id] = nil
	self.PlaylistCount = self.PlaylistCount - 1
	
	self:DispatchEvent ("PlaylistRemoved", playlist)
end

Movies.Playlists = Movies.PlaylistCollection ()
