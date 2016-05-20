Movies = {}
Movies.Screens = {}
Movies.InstanceID = CurTime ()

Movies.RadioEnabled = true
Movies.MoviesEnabled = true

include ("sh_oop.lua")
include ("sh_eventprovider.lua")
include ("sh_playlist.lua")
include ("sh_playlists.lua")
include ("sh_screen.lua")
include ("sh_video.lua")
include ("sh_ytapi.lua")

hook.Add ("Initialize", "MovieDarkRPTeam", function ()
	if AddExtraTeam then
		if Movies.MoviesEnabled then
			TEAM_MOVIE = AddExtraTeam ("Movie Manager", Color (0, 128, 128, 255), "models/player/hostage/hostage_04.mdl",
[[Put on entertaining movies for players to watch.

Press F3 to bring up the movie menu.]],
			{}, "movie", 1, 45, 0, false, false)
		end
		
		if Movies.RadioEnabled then
			TEAM_RADIO = AddExtraTeam ("Radio Host", Color (0, 128, 128, 255), "models/player/hostage/hostage_04.mdl",
[[As a radio host you control what songs play on the 
radio by pressing F3.]],
			{}, "radiohost", 1, 45, 0, false, false)
		end
	end
	
	if Movies.RadioEnabled then
		local item =
		{
			name = "Radio",
			ent = "movie_radio",
			model = "models/props_lab/citizenradio.mdl",
			price = 300,
			max = 2,
			cmd = "/buyradio"
		}
		if AddEntity then
			AddEntity (item.name, item.ent, item.model, item.price, item.max, item.cmd)
		end
		if AddChatCommand then
			local upvalueName, upvalue = debug.getupvalue (AddChatCommand, 1)
			if upvalueName == "ChatCommands" then
				AddChatCommand ("/buyradio", 
					function (ply, args)
						if RPArrestedPlayers[ply:SteamID()] then return "" end
						local cmdname = string.gsub(item.ent, " ", "_")
						local disabled = tobool(GetConVarNumber("disable"..cmdname))
						if disabled then
							Notify(ply, 1, 4, string.format(LANGUAGE.disabled, item.cmd, ""))
							return "" 
						end
						
						local max = GetConVarNumber("max"..cmdname)

						if not max or max == 0 then max = tonumber(item.max) end
						if ply["max"..cmdname] and tonumber(ply["max"..cmdname]) >= tonumber(max) then
							Notify(ply, 1, 4, string.format(LANGUAGE.limit, item.cmd))
							return ""
						end
						
						local price = GetConVarNumber(cmdname.."_price")
						if price == 0 then 
							price = item.price
						end
						
						if not ply:CanAfford(price) then
							Notify(ply, 1, 4,  string.format(LANGUAGE.cant_afford, item.cmd))
							return ""
						end
						ply:AddMoney(-price)
						
						local trace = {}
						trace.start = ply:EyePos()
						trace.endpos = trace.start + ply:GetAimVector() * 85
						trace.filter = ply
						
						local tr = util.TraceLine(trace)
						
						local itemName = item.name
						local item = ents.Create(item.ent)
						item.dt = item.dt or {}
						item.dt.owning_ent = ply
						item:SetPos(tr.HitPos)
						item.SID = ply.SID
						item.onlyremover = true
						item:Spawn()
						Notify(ply, 0, 4, string.format(LANGUAGE.you_bought_x, itemName, CUR..price))
						if not ply["max"..cmdname] then
							ply["max"..cmdname] = 0
						end
						ply["max"..cmdname] = ply["max"..cmdname] + 1
						return ""
					end
				)
			end
		end
	end
end)

function Movies.CanControlMovies (ply)
	if not ply or not ply:IsValid () then return true end -- console
	return Movies.IsMovieManager (ply) or Movies.IsRadioManager (ply) or ply:IsAdmin ()
end

function Movies.FormatTime (time)
	time = time or 0
	local hours = math.floor (time / 3600)
	if hours > 0 then
		return Movies.FormatTimeHHMMSS (time)
	else
		return Movies.FormatTimeMMSS (time)
	end
end

function Movies.FormatTimeHHMMSS (time)
	return string.format ("%.2d:%.2d:%.2d", math.floor (time / 3600), math.floor ((time % 3600) / 60), math.floor (time % 60))
end

function Movies.FormatTimeMMSS (time)
	return string.format ("%.2d:%.2d", math.floor (time / 60), math.floor (time % 60))
end

function Movies.GetScreen (entID)
	return Movies.Screens [entID]
end

function Movies.IsMovieManager (ply)
	if not Movies.MoviesEnabled then return false end
	if not TEAM_MOVIE then return true end
	return ply:Team () == TEAM_MOVIE
end

function Movies.IsRadioManager (ply)
	if not Movies.RadioEnabled then return false end
	if not TEAM_RADIO then return true end
	return ply:Team () == TEAM_RADIO
end

function Movies.Notify (ply, message)
	if Notify then
		Notify (ply, NOTIFY_GENERIC, 4, message)
	else
		ply:PrintMessage (HUD_PRINTTALK, message)
	end
end

function Movies.NotifyAll (message)
	if NotifyAll then
		NotifyAll (NOTIFY_GENERIC, 4, message)
	else
		for _, ply in ipairs (player.GetAll ()) do
			ply:PrintMessage (HUD_PRINTTALK, message)
		end
	end
end

function Movies.RegisterScreen (entID)
	local ent = ents.GetByIndex (entID)
	local screen = Movies.Screen (entID)
	if ent and ent:IsValid () and ent.Screen then
		screen:CopyFrom (ent.Screen)
	end
	
	Movies.Screens [entID] = screen
	
	if SERVER then
		umsg.Start ("movie_create_screen")
			screen:WriteData (umsg)
		umsg.End ()
	end
	
	if ent then
		ent.Screen = screen
	end
	
	return screen
end

function Movies.UnregisterScreen (entID)
	if not Movies.Screens [entID] then return end
	
	if SERVER then
		umsg.Start ("movie_destroy_screen")
			umsg.Long (entID)
		umsg.End ()
	end
	
	Movies.Screens [entID] = nil
end

-- returns valid, video_host, video_id
function Movies.ValidateURL (url)
	if not url then return false, nil, nil end
	url = url:Trim ()
	
	if not url:lower ():find ("youtube.com", 1, true) then return false, nil, nil end
	
	local videoID = url:match ("v=([a-zA-Z0-9_%-]*)")
	if not videoID then
		videoID = url:match ("/v/([a-zA-Z0-9_%-]*)")
	end
	if not videoID or videoID == "" then return false, nil, nil end
	
	return true, "youtube", videoID
end