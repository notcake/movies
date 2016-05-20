include ("sh_movies.lua")
include ("cl_ui.lua")
include ("cl_playercontrol.lua")
include ("cl_player.lua")

concommand.Add ("movie_screen_pos", function (ply)
	local tr = ply:GetEyeTrace ()
	if not tr.Hit then
		print ("You're not looking at a wall or you are too far away from it.")
		return
	end
	local normal = tr.HitNormal
	print ("Centre = Vector (" .. tr.HitPos.x .. ", " .. tr.HitPos.y .. ", " .. tr.HitPos.z .. ")")
end)

usermessage.Hook ("movie_create_screen", function (umsg)
	local entID = umsg:ReadLong ()
	Movies.RegisterScreen (entID):ReadData (umsg)
end)

usermessage.Hook ("movie_destroy_screen", function (umsg)
	local entID = umsg:ReadLong ()
	Movies.UnregisterScreen (entID)
end)

usermessage.Hook ("movie_playlist_added", function (umsg)
	local playlist = Movies.Playlists:CreatePlaylist (umsg:ReadString ())
	playlist:SetPlaylistType (umsg:ReadLong ())
	playlist:SetMaximumVideos (umsg:ReadLong ())
end)

usermessage.Hook ("movie_playlist_clear", function (umsg)
	local playlist = Movies.Playlists:GetOrCreatePlaylist (umsg:ReadString ())
	playlist:Clear ()
end)

usermessage.Hook ("movie_playlists_clear", function (umsg)
	Movies.Playlists:Clear ()
end)

usermessage.Hook ("movie_video_added", function (umsg)
	local playlist = Movies.Playlists:GetOrCreatePlaylist (umsg:ReadString ())
	
	local video = Movies.Video ()
	video:ReadData (umsg)
	
	playlist:Add (video)
end)

usermessage.Hook ("movie_video_paused", function (umsg)
	local playlist = Movies.Playlists:GetOrCreatePlaylist (umsg:ReadString ())
	playlist:Pause ()
end)

usermessage.Hook ("movie_video_removed", function (umsg)
	local playlist = Movies.Playlists:GetOrCreatePlaylist (umsg:ReadString ())
	playlist:RemoveByIndex (umsg:ReadLong ())
end)

usermessage.Hook ("movie_video_seeked", function (umsg)
	local playlist = Movies.Playlists:GetOrCreatePlaylist (umsg:ReadString ())
	local index = umsg:ReadLong ()
	local time = umsg:ReadFloat ()
	playlist:Seek (index, time)
end)

usermessage.Hook ("movie_video_started", function (umsg)
	local playlist = Movies.Playlists:GetOrCreatePlaylist (umsg:ReadString ())
	playlist:Play ()
end)

hook.Add ("InitPostEntity", "MoviesRequestPlaylists", function ()
	RunConsoleCommand ("movie_request_playlists")
	timer.Destroy ("MoviesRequestPlaylists")
	hook.Remove ("InitPostEntity", "MoviesRequestPlaylists")
end)

timer.Create ("MoviesRequestPlaylists", 1, 1, function ()
	RunConsoleCommand ("movie_request_playlists")
	timer.Destroy ("MoviesRequestPlaylists")
	hook.Remove ("InitPostEntity", "MoviesRequestPlaylists")
end)