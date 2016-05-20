include ("sh_movies.lua")

AddCSLuaFile ("cl_movies.lua")
AddCSLuaFile ("cl_player.lua")
AddCSLuaFile ("cl_playercontrol.lua")
AddCSLuaFile ("cl_ui.lua")
AddCSLuaFile ("sh_eventprovider.lua")
AddCSLuaFile ("sh_movies.lua")
AddCSLuaFile ("sh_oop.lua")
AddCSLuaFile ("sh_playlist.lua")
AddCSLuaFile ("sh_playlists.lua")
AddCSLuaFile ("sh_screen.lua")
AddCSLuaFile ("sh_video.lua")
AddCSLuaFile ("sh_ytapi.lua")
AddCSLuaFile ("ui/hyperlink.lua")
AddCSLuaFile ("ui/play_button.lua")
AddCSLuaFile ("ui/playlist.lua")
AddCSLuaFile ("ui/playlist_add.lua")
AddCSLuaFile ("ui/playlist_item.lua")
AddCSLuaFile ("ui/video_progress.lua")
AddCSLuaFile ("ui/video_ytapi.lua")

function Movies.CreateScreen (pos)
	local screen = ents.Create ("movie_screen")
	if pos then
		screen:SetPos (pos)
	end
	screen:Spawn ()
	
	return screen
end

-- width and height are in world units.
Movies.Autospawn =
{
	["gm_flatgrass"] =
	{
		PlaylistID = "movies",
	
		Centre = Vector (0, 0, 96),
		Right = Vector (0, 1, 0),
		Down = Vector (0, 0, -1),
		Width = 854 * 0.4,
		Height = 480 * 0.4
	},
	["rp_downtown_v4c"] =
	{
		PlaylistID = "movies",
		
        Centre = Vector (-473.5, 1971, -85.5),
		Right = Vector (1, 0, 0),
		Down = Vector (0, 0, -1),
		Width = 854 * 0.5,
		Height = 480 * 0.5
	}
}

hook.Add ("Initialize", "MovieSpawnScreen", function ()
	if not Movies.MoviesEnabled then return end
	
	local map = game.GetMap ():lower ()
	local mapData = Movies.Autospawn [map]
	if not mapData then return end
	
	local screenEntity = Movies.CreateScreen (mapData.Centre)
	screen = Movies.GetScreen (screenEntity:EntIndex ())
	if not screen then return end
	
	screen:SetPlaylistID (mapData.PlaylistID)
	screen:SetCentre (mapData.Centre)
	screen:SetRight (mapData.Right)
	screen:SetDown (mapData.Down)
	screen:SetWidth (mapData.Width)
	screen:SetHeight (mapData.Height)
	
	umsg.Start ("movie_create_screen")
		screen:WriteData (umsg)
	umsg.End ()
end)

hook.Add ("ShowSpare1", "MovieUI", function (ply)
	if not Movies then return end
	
	if Movies.IsMovieManager (ply) then
		ply:ConCommand ("movie_open_ui movies")
		return true
	elseif Movies.IsRadioManager (ply) then
		ply:ConCommand ("movie_open_ui radio")
		return true
	end
end)

Movies.Playlists:AddEventListener ("PlaylistAdded", function (playlistCollection, playlist)
	playlist:AddEventListener ("VideoAdded", function (playlist, video)
		umsg.Start ("movie_video_added")
			umsg.String (playlist:GetID ())
			video:SendData (umsg)
		umsg.End ()
	end)

	playlist:AddEventListener ("VideoPaused", function (playlist)
		umsg.Start ("movie_video_paused")
			umsg.String (playlist:GetID ())
		umsg.End ()
	end)

	playlist:AddEventListener ("VideoRemoved", function (playlist, video)
		umsg.Start ("movie_video_removed")
			umsg.String (playlist:GetID ())
			umsg.Long (video:GetIndex ())
		umsg.End ()
	end)

	local lastNotify = CurTime ()
	playlist:AddEventListener ("VideoSeeked", function (playlist, video, time)
		umsg.Start ("movie_video_seeked")
			umsg.String (playlist:GetID ())
			umsg.Long (video:GetIndex ())
			umsg.Float (time)
		umsg.End ()
		
		if playlist:IsPlaying () and time == 0 then
			video:GetData (function (data)
				if CurTime () - lastNotify < 15 then return end
				lastNotify = CurTime ()
				if time == 0 then
					if playlist:GetPlaylistType () == Movies.PlaylistType.Video then
						Movies.NotifyAll (data.Title .. " is now playing in the theater!")
					else
						Movies.NotifyAll (data.Title .. " is now playing on the radio!")
					end
				end
			end)
		end
	end)

	playlist:AddEventListener ("VideoStarted", function (playlist, video, time)
		umsg.Start ("movie_video_started")
			umsg.String (playlist:GetID ())
		umsg.End ()
		
		video:GetData (function (data)
			if CurTime () - lastNotify < 15 then return end
			lastNotify = CurTime ()
			if time == 0 then
				if playlist:GetPlaylistType () == Movies.PlaylistType.Video then
					Movies.NotifyAll (data.Title .. " is now playing in the theater!")
				else
					Movies.NotifyAll (data.Title .. " is now playing on the radio!")
				end
			end
		end)
	end)
end)

concommand.Add ("movie_add_video", function (ply, _, arg)
	if not Movies.CanControlMovies (ply) then return end
	
	local playlist = Movies.Playlists:GetPlaylist (arg [1])
	if not playlist then return end
	
	local url = arg [2]
	if not url then return end
	
	local valid, videoHost, videoID = Movies.ValidateURL (url)
	if not valid then return end
	
	local video = Movies.Video ()
	video:SetURL (url)
	video:GetData (function (data)
		if not data.Exists then return end
		playlist:Add (video)
		
		if playlist:GetPlaylistType () == Movies.PlaylistType.Video then
			Movies.Notify (ply, "Video added!")
		else
			Movies.Notify (ply, "Song added!")
		end
	end)
end)

concommand.Add ("movie_pause_video", function (ply, _, arg)
	if not Movies.CanControlMovies (ply) then return end
	
	local playlist = Movies.Playlists:GetPlaylist (arg [1])
	if not playlist then return end
	
	playlist:Pause ()
end)

concommand.Add ("movie_play_video", function (ply, _, arg)
	if not Movies.CanControlMovies (ply) then return end
	
	local playlist = Movies.Playlists:GetPlaylist (arg [1])
	if not playlist then return end
	
	playlist:Play ()
end)

concommand.Add ("movie_remove_video", function (ply, _, arg)
	if not Movies.CanControlMovies (ply) then return end
	
	local playlist = Movies.Playlists:GetPlaylist (arg [1])
	if not playlist then return end
	
	if not arg [2] or not tonumber (arg [2]) then return end
	
	playlist:RemoveByIndex (tonumber (arg [2]))
end)

concommand.Add ("movie_seek_video", function (ply, _, arg)
	if not Movies.CanControlMovies (ply) then return end
	
	local playlist = Movies.Playlists:GetPlaylist (arg [1])
	if not playlist then return end
	
	if not arg [2] or not arg [3] then return end
	if not tonumber (arg [2]) or not tonumber (arg [3]) then return end
	
	playlist:Seek (tonumber (arg [2]), tonumber (arg [3]))
end)

concommand.Add ("movie_request_playlists", function (ply)
	umsg.Start ("movie_playlists_clear", ply)
	umsg.End ()
	
	for id, playlist in pairs (Movies.Playlists.Playlists) do
		umsg.Start ("movie_playlist_added", ply)
			umsg.String (id)
			umsg.Long (playlist:GetPlaylistType ())
			umsg.Long (playlist:GetMaximumVideos ())
		umsg.End ()
	
		for _, video in ipairs (playlist.Videos) do
			umsg.Start ("movie_video_added", ply)
				umsg.String (id)
				video:SendData (umsg)
			umsg.End ()
		end
		
		umsg.Start ("movie_video_seeked", ply)
			umsg.String (id)
			umsg.Long (playlist:GetPlayingVideoIndex ())
			umsg.Float (playlist:GetPlayingPosition ())
		umsg.End ()
		
		if playlist:IsPlaying () then
			umsg.Start ("movie_video_started", ply)
				umsg.String (id)
			umsg.End ()
		end
	end
	
	-- send screens
	for _, screen in pairs (Movies.Screens) do
		umsg.Start ("movie_create_screen", ply)
			screen:WriteData (umsg)
		umsg.End ()
	end
end)

for _, screen in ipairs (ents.FindByClass ("movie_screen")) do
	Movies.RegisterScreen (screen:EntIndex ())
end

Movies.Playlists:CreatePlaylist ("movies", Movies.PlaylistType.Video)
Movies.Playlists:CreatePlaylist ("radio", Movies.PlaylistType.Music)