include ("ui/hyperlink.lua")
include ("ui/play_button.lua")
include ("ui/playlist.lua")
include ("ui/playlist_add.lua")
include ("ui/playlist_item.lua")
include ("ui/video_progress.lua")
include ("ui/video_ytapi.lua")

function Movies.OpenUI (playlistID)
	if not Movies.Playlists:GetPlaylist (playlistID) then return end

	if not Movies.UI or not Movies.UI:IsValid () then
		Movies.UI = vgui.Create ("movie_playlist")
	end
	if not Movies.UI then return end
	
	Movies.UI:SetVisible (true)
	Movies.UI:SetPlaylist (Movies.Playlists:GetPlaylist (playlistID))
end

concommand.Add ("movie_open_ui", function (ply, _, args)
	Movies.OpenUI (args [1])
end)