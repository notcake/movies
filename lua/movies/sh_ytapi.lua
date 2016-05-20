function Movies.YoutubeQuery (videoID, callback)
	http.Get ("http://gdata.youtube.com/feeds/api/videos/" .. videoID .. "?v=2", "", function (contents, size)
		if size == 0 then
			callback (
				{
					VideoID = videoID,
					Exists = false
				}
			)
			return
		end
		
		local data = {
			VideoID = videoID,
			Exists = true
		}
		
		data.Title = contents:match ("<title>([^<]*)</title>") or ""
		data.Description = contents:match ("<media:description[^>]*>([^<]*)</media:description>") or ""
		data.Duration = tonumber (contents:match ("<yt:duration seconds='([0-9]*)'") or "0")
		data.Author = contents:match ("<author><name>([^<]*)</name>") or ""
		data.ViewCount = tonumber (contents:match ("viewCount='([0-9]+)'") or "0")
		
		data.SmallThumbnail = {}
		local thumbnailURL, height, width = contents:match ("<media:thumbnail url='([^']*/default%.jpg)' height='([0-9]+)' width='([0-9]+)'")
		data.SmallThumbnail.URL = thumbnailURL or ""
		data.SmallThumbnail.Width = tonumber (width) or 0
		data.SmallThumbnail.Height = tonumber (height) or 0
		
		callback (data)
	end)
end