import pafy
import sys
import json
if sys.version_info[0] < 3:
    from urllib import quote
    from urllib2 import urlopen
else:
    from urllib.request import urlopen
    from urllib.parse import quote, urlencode
from bs4 import BeautifulSoup, SoupStrainer

url = "https://www.youtube.com/results?search_query=news"
response = urlopen(url)
html = response.read()
soup = BeautifulSoup(html)
getVideoDetails = zip(soup.findAll(attrs={'class': 'yt-uix-tile-link'}), soup.findAll(attrs={'class': 'yt-lockup-byline'}), soup.findAll(attrs={'class': 'yt-lockup-meta-info'}), soup.findAll(attrs={'class': 'video-time'})) 
for vid in getVideoDetails:
    if "googleads" not in vid[0]['href'] and not vid[0]['href'].startswith(
        u"/user") and not vid[0]['href'].startswith(u"/channel"):
        videoID = vid[0]['href'].split("v=")[1].split("&")[0]
        videoTitle = vid[0]['title']
        videoImage = "https://i.ytimg.com/vi/{0}/hqdefault.jpg".format(videoID)
        videoChannel = vid[1].contents[0].string
        videoUploadDate = vid[2].contents[0].string
        videoDuration = vid[3].contents[0].string
        if "watching" in vid[2].contents[0].string:
            videoViews = "Live"
        else:
            try:
                videoViews = vid[2].contents[1].string
            except:
                videoViews = "Playlist"
        print({"videoID": videoID, "videoTitle": videoTitle, "videoImage": videoImage, "videoChannel": videoChannel, "videoViews": videoViews, "videoUploadDate": videoUploadDate, "videoDuration": videoDuration})
