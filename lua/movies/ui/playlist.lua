local PANEL = {}

function PANEL:Init ()
	self.Playlist = nil

	self:SetSize (math.max (640, ScrW () * 0.50), ScrH () * 0.50)
	self:Center ()
	
	self:MakePopup ()
	
	self.List = vgui.Create ("DPanelList", self)
	self.List:EnableVerticalScrollbar ()
	self.List:SetPadding (8)
	self.List:SetSpacing (8)
	
	self.Add = vgui.Create ("DButton", self)
	self.Add.DoClick = function (button)
		local playlistAdd = vgui.Create ("movie_playlist_add")
		playlistAdd:SetPlaylist (self.Playlist)
	end
	
	self.Created = true
end

function PANEL:PerformLayout ()
	DFrame.PerformLayout (self)
	if not self.Created then return end
	
	self.Add:SetSize (80, 28)
	self.Add:SetPos (self:GetWide () - self.Add:GetWide () - 8, self:GetTall () - self.Add:GetTall () - 8)
	
	self.List:SetPos (8, 28)
	self.List:SetSize (self:GetWide () - 16, self:GetTall () - self.Add:GetTall () - 44)
end

function PANEL:SetPlaylist (playlist)
	if self.Playlist then
		self.Playlist:RemoveEventListener ("VideoAdded", "UI")
		self.Playlist:RemoveEventListener ("VideoPaused", "UI")
		self.Playlist:RemoveEventListener ("VideoRemoved", "UI")
		self.Playlist:RemoveEventListener ("VideoSeeked", "UI")
		self.Playlist:RemoveEventListener ("VideoStarted", "UI")
	end

	self.Playlist = playlist
	self.Add:SetDisabled (playlist:IsFull ())
	
	if self.Playlist:GetPlaylistType () == Movies.PlaylistType.Video then
		self:SetTitle ("Movie Playlist")
		self.Add:SetText ("Add video...")
	else
		self:SetTitle ("Radio Playlist")
		self.Add:SetText ("Add song...")
	end
	
	self.Playlist:AddEventListener ("VideoAdded", "UI", function (playlist, video)
		if not self or not self:IsValid () then return end
		self:AddVideo (video)
		
		self.Add:SetDisabled (playlist:IsFull ())
	end)
	
	self.Playlist:AddEventListener ("VideoRemoved", "UI", function (playlist, video)
		if not self or not self:IsValid () then return end
		self.List:GetItems () [video:GetIndex ()]:Remove ()
		table.remove (self.List:GetItems (), video:GetIndex ())
		self.List:PerformLayout ()
		if self.List.VBar and self.List.VBar:IsValid () then
			self.List.VBar:SetScroll (self.List.VBar:GetScroll ())
		end
		
		self.Add:SetDisabled (false)
	end)
	
	self.Playlist:AddEventListener ("VideoPaused", "UI", function (playlist)
		if not self or not self:IsValid () then return end
		local item = self.List:GetItems () [playlist:GetPlayingVideoIndex ()]
		if not item then return end
		
		item:UpdateUI ()
	end)
	
	self.Playlist:AddEventListener ("VideoSeeked", "UI", function (playlist, video, time)
		if not self or not self:IsValid () then return end
		for _, item in ipairs (self.List:GetItems ()) do
			item:UpdateUI ()
		end
	end)
	
	self.Playlist:AddEventListener ("VideoStarted", "UI", function (playlist, video)
		if not self or not self:IsValid () then return end
		self.List:GetItems () [video:GetIndex ()]:UpdateUI ()
	end)
	
	
	for _, video in ipairs (self.Playlist.Videos) do
		self:AddVideo (video)
	end
end

function PANEL:AddVideo (video)
	local videoItem = vgui.Create ("movie_playlist_item")
	videoItem:SetPlaylist (self.Playlist)
	videoItem:SetVideo (video)
	videoItem:UpdateUI ()
	
	self.List:AddItem (videoItem)
end

vgui.Register ("movie_playlist", PANEL, "DFrame")