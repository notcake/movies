local PANEL = {}

local suggestedVideos =
{
	"http://www.youtube.com/watch?v=NjcdwY41jJE",
	"http://www.youtube.com/watch?v=qLs-7eyfQDM",
	"http://www.youtube.com/watch?v=na7rqE7JhIA",
	"http://www.youtube.com/watch?v=xVRzNPgQkQ0"
}

function PANEL:Init ()
	self.Playlist = nil

	self:SetTitle ("Add video...")

	self:SetSize (ScrW () * 0.5, 256)
	self:Center ()
	
	self:MakePopup ()
	
	self.URLLabel = vgui.Create ("DLabel", self)
	self.URLLabel:SetText ("Youtube URL:")
	self.URLLabel:SizeToContents ()
	
	self.URL = vgui.Create ("DTextEntry", self)
	self.URL:RequestFocus ()
	self.URL.OnTextChanged = function (textEntry)
		local valid, videoHost, videoID = Movies.ValidateURL (self.URL:GetText ())
		if valid then
			self.Add:SetDisabled (false)
			self.Video:SetVideo (videoID)
		else
			self.Add:SetDisabled (true)
			self.Video:Clear ()
		end
	end
	
	self.URLExample = vgui.Create ("DLabel", self)
	self.URLExample:SetText ("eg. ")
	self.URLExample:SizeToContents ()
	self.URLExampleLink = vgui.Create ("movie_hyperlink", self)
	self.URLExampleLink:SetText (table.Random (suggestedVideos))
	self.URLExampleLink:SizeToContents ()
	self.URLExampleLink.OnMousePressed = function (hyperlink)
		self.URL:SetText (self.URLExampleLink:GetText ())
		self.URL:OnTextChanged ()
	end
	
	self.Video = vgui.Create ("movie_video_ytapi", self)
	self.Video:SetHeight (self.Video:GetPreferredHeight ())
	
	self.Add = vgui.Create ("DButton", self)
	self.Add:SetSize (80, 32)
	self.Add:SetDisabled (true)
	self.Add:SetText ("Add")
	self.Add.DoClick = function (button)
		RunConsoleCommand ("movie_add_video", self.Playlist:GetID (), self.URL:GetText ())
		self:Remove ()
	end
	
	self:SetTall (64 + self.URL:GetTall () + self.URLExample:GetTall () + self.Video:GetTall () + self.Add:GetTall ())
	
	self.Created = true
end

function PANEL:PerformLayout ()
	DFrame.PerformLayout (self)
	if not self.Created then return end
	
	local x, y = 8, 28
	self.URLLabel:SizeToContents ()
	x = x + self.URLLabel:GetWide () + 8
	
	self.URL:SetPos (x, y)
	self.URL:SetWide (self:GetWide () - x - 8)
	self.URLLabel:SetPos (8, y + (self.URL:GetTall () - self.URLLabel:GetTall ()) * 0.5)
	y = y + self.URL:GetTall () + 4
	
	self.URLExample:SetPos (x + 8, y)
	self.URLExample:SizeToContents ()
	self.URLExampleLink:SetPos (x + 8 + self.URLExample:GetWide (), y)
	self.URLExampleLink:SizeToContents ()
	x = 8
	y = y + self.URLExample:GetTall () + 8
	
	self.Add:SetSize (80, 32)
	self.Add:SetPos (self:GetWide () - 8 - self.Add:GetWide (), self:GetTall () - 8 - self.Add:GetTall ())
	
	self.Video:SetPos (x, y)
	self.Video:SetWide (self:GetWide () - 16)
end

function PANEL:SetPlaylist (playlist)
	self.Playlist = playlist
	
	if self.Playlist:GetPlaylistType () == Movies.PlaylistType.Video then
		self:SetTitle ("Add video...")
	else
		self:SetTitle ("Add song...")
	end
end

vgui.Register ("movie_playlist_add", PANEL, "DFrame")