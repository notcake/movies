local PANEL = {}

function PANEL:Init ()
	self.LastVideoLookup = ""
	self.LastVideoChangeTime = CurTime ()
	self.VideoID = nil
	self.State = "novideo"
	
	self.Image = vgui.Create ("HTML", self)
	self.Image:SetSize (120, 90)
	self.Image:SetMouseInputEnabled (false)
	self.Title = vgui.Create ("DLabel", self)
	self.Title:SetFont ("TargetID")
	self.Title:SetTextColor (Color (255, 255, 255, 255))
	
	self.Description = vgui.Create ("DLabel", self)
	self.Description:SetWrap (true)
	self.Description:SetContentAlignment (7)
	
	self.Duration = vgui.Create ("DLabel", self)
	self.Duration:SetContentAlignment (5)
	self.Duration.Paint = function (label)
		draw.RoundedBoxEx (4, 0, 0, label:GetWide (), label:GetTall (), Color (0, 0, 0, 192), true, false, false, false)
	
		return DLabel.Paint (label)
	end
	
	self.Author = vgui.Create ("DLabel", self)
	
	self.Created = true
end

function PANEL:Clear ()
	self.LastVideoLookup = ""
	self.LastVideoChangeTime = CurTime ()
	self.VideoID = nil
end

function PANEL:GetPreferredHeight ()
	return 106
end

function PANEL:PerformLayout ()
	if not self.Created then return end

	self.Image:SetPos (8, 8)
	
	self.Author:SizeToContents ()
	self.Author:SetPos (16 + self.Image:GetWide (), self:GetTall () - self.Author:GetTall () - 8)
	
	self.Title:SetPos (16 + self.Image:GetWide (), 8)
	self.Title:SetWide (self:GetWide () - self.Image:GetWide () - 24)
	self.Description:SetPos (16 + self.Image:GetWide (), 32)
	self.Description:SetWide (self:GetWide () - self.Image:GetWide () - 24)
	self.Description:SetTall (self:GetTall () - 40 - self.Author:GetTall ())
	
	self.Duration:SizeToContents ()
	self.Duration:SetWide (self.Duration:GetWide () + 4)
	self.Duration:SetTall (self.Duration:GetTall () + 4)
	self.Duration:SetPos (8 + self.Image:GetWide () - self.Duration:GetWide (), 8 + self.Image:GetTall () - self.Duration:GetTall ())
	
	if self.State == "novideo" then
		self.Description:SetVisible (false)
		self.Duration:SetVisible (false)
		self.Author:SetVisible (false)
		self.Image:SetVisible (false)
		
		self.Title:SetText ("Please enter a video")
		self.Title:SetTextColor (Color (192, 192, 192, 255))
	elseif self.State == "notfound" then
		self.Title:SetTextColor (Color (128, 0, 0, 255))
		self.Description:SetVisible (false)
		self.Duration:SetVisible (false)
		self.Author:SetVisible (false)
		self.Image:SetVisible (false)
	else
		self.Title:SetTextColor (Color (255, 255, 255, 255))
		self.Description:SetVisible (true)
		self.Duration:SetVisible (true)
		self.Author:SetVisible (true)
		self.Image:SetVisible (true)
	end
end

function PANEL:SetVideo (videoID)
	self.VideoID = videoID
	self.LastVideoChangeTime = CurTime ()
end

function PANEL:Think ()
	if not self.VideoID then return end
	if self.LastVideoLookup == self.VideoID then return end
	if CurTime () - self.LastVideoChangeTime < 1 then return end
	
	Movies.YoutubeQuery (self.VideoID, function (data)
		if not self or not self:IsValid () then return end
		if self.VideoID ~= data.VideoID then return end
		
		self:UpdateData (data)
	end)
	
	self.LastVideoLookup = self.VideoID
end

function PANEL:UpdateData (data)
	if not data.Exists then
		self.State = "notfound"
		self.Title:SetText ("Video not found.")
		
		self:PerformLayout ()
		return
	end
	
	self.State = "video"
	
	self.Title:SetText (data.Title)
	self.Description:SetText (data.Description)
	
	self.Duration:SetText (Movies.FormatTime (data.Duration))
	
	local viewCount = tostring (data.ViewCount)
	local viewCountString = ""
	for i = 1, viewCount:len () do
		viewCountString = viewCount:sub (-i, -i) .. viewCountString
		if i % 3 == 0 and i ~= viewCount:len () then
			viewCountString = "," .. viewCountString
		end
	end
	
	self.Author:SetText ("by " .. data.Author .. "\n" .. viewCountString .. " views")
	
	self.Image:SetSize (data.SmallThumbnail.Width, data.SmallThumbnail.Height)
	self.Image:SetHTML (
	[[
		<html>
			<head>
			</head>
			<body style="overflow: hidden">
				<img src="]] .. data.SmallThumbnail.URL .. [[" style="position:absolute;top:0px;left:0px">
			</body>
		</html>
	]])
	
	self:PerformLayout ()
end

vgui.Register ("movie_video_ytapi", PANEL, "DPanel")