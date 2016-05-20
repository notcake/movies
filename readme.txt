Movie team definition is in lua/movies/sh_movies.lua

Screen spawn position is in lua/movies/sv_movies.lua
Use movie_screen_pos in the console to print out the coordinates of the point on the wall you're looking at.

Copy lua/movies/player.html to your own website.
Update PlayerURL at the top of lua/movies/cl_player.lua to point at player.html on your website.


Adjusting video quality and lagginess:
lua/movies/cl_playercontrol.lua:
Find self.ResolutionIndex, read instructions.


Gmod only allows drawing the video underneath all transparent props or over all transparent props.
DrawOverTransparentProps in lua/movies/cl_player.lua controls this

Movies.MoviesEnabled and Movies.RadioEnabled in lua/movies/sh_movies.lua control whether the radio and movie systems are turned on.