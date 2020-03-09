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

url = "https://www.youtube.com/watch?v=0DdoGPav3fc"
response = urlopen(url)
html = response.read()
soup = BeautifulSoup(html)
currentVideoSection = soup.find('div', attrs={'class': 'watch-sidebar'})
getVideoDetails = zip(currentVideoSection.findAll(attrs={'class': 'yt-uix-sessionlink'}), currentVideoSection.findAll(attrs={'class': 'attribution'}), currentVideoSection.findAll(attrs={'class': 'yt-uix-simple-thumb-wrap'}), currentVideoSection.findAll(attrs={'class': 'video-time'}), currentVideoSection.findAll(attrs={'class': 'view-count'}))
for vid in getVideoDetails:
    if "googleads" not in vid[0]['href'] and not vid[0]['href'].startswith(
        u"/user") and not vid[0]['href'].startswith(u"/channel") and "title" in vid[0].attrs:
        videoID = vid[0]['href'].split("v=")[1].split("&")[0]
        videoTitle = vid[0]['title']
        videoImage = "https://i.ytimg.com/vi/{0}/hqdefault.jpg".format(videoID)
        videoChannel = vid[1].contents[0].string
        videoUploadDate = " "
        videoDuration = vid[3].contents[0].string
        videoViews = vid[4].text
        print({"videoID": videoID, "videoTitle": videoTitle, "videoImage": videoImage, "videoChannel": videoChannel, "videoViews": videoViews, "videoUploadDate": videoUploadDate, "videoDuration": videoDuration})
