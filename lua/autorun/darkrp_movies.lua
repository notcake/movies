if SERVER then
	AddCSLuaFile ("autorun/darkrp_movies.lua")
	include ("movies/sv_movies.lua")
else
	include ("movies/cl_movies.lua")
end