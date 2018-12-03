# -*- coding: utf-8 -*-

import time
import urllib
from os.path import dirname
import pafy
import sys
if sys.version_info[0] < 3:
    from urllib import quote
    from urllib2 import urlopen
else:
    from urllib.request import urlopen
    from urllib.parse import quote
from adapt.intent import IntentBuilder
from bs4 import BeautifulSoup
from mycroft.skills.core import MycroftSkill
from mycroft.messagebus.message import Message

__author__ = 'augustnmonteiro'
 
class YoutubeSkill(MycroftSkill):
    def __init__(self):
        super(YoutubeSkill, self).__init__(name="YoutubeSkill")
        self.process = None

    def initialize(self):
        self.load_data_files(dirname(__file__))

        youtube = IntentBuilder("YoutubeKeyword"). \
            require("YoutubeKeyword").build()
        self.register_intent(youtube, self.youtube)
        
        youtubepause = IntentBuilder("YoutubePauseKeyword"). \
            require("YoutubePauseKeyword").build()
        self.register_intent(youtubepause, self.youtubepause)
        
        youtuberesume = IntentBuilder("YoutubeResumeKeyword"). \
            require("YoutubeResumeKeyword").build()
        self.register_intent(youtuberesume, self.youtuberesume)
        
        youtubesearchpage = IntentBuilder("YoutubeSearchPageKeyword"). \
            require("YoutubeSearchPageKeyword").build()
        self.register_intent(youtubesearchpage, self.youtubesearchpage)
        
        self.add_event('aiix.youtube-skill.playvideo_id', self.play_event)
        
    def search(self, text):
        query = quote(text)
        url = "https://www.youtube.com/results?search_query=" + query
        response = urlopen(url)
        html = response.read()
        soup = BeautifulSoup(html)
        for vid in soup.findAll(attrs={'class': 'yt-uix-tile-link'}):
            if "googleads" not in vid['href'] and not vid['href'].startswith(
                    u"/user") and not vid['href'].startswith(u"/channel"):
                id = vid['href'].split("v=")[1].split("&")[0]
                return id

    def youtube(self, message):
        self.stop()
        utterance = message.data.get('utterance').lower()
        utterance = utterance.replace(
            message.data.get('YoutubeKeyword'), '')
        vid = self.search(utterance)
        urlvideo = "http://www.youtube.com/watch?v={0}".format(vid)
        video = pafy.new(urlvideo)
        print(video.streams)
        for vid_type in video.streams:
            if (vid_type._extension == 'mp4'):
                try:
                    if(vid_type._resolution == '480x360'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '426x240'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '320x180'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '640x342'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '640x360'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '256x144'):
                        playurl = vid_type.url
                    elif (vid_type._resolution == '176x144'):
                        playurl = vid_type.url
                except:
                    playstream = video.getbest(preftype="mp4", ftypestrict=True)
                    playurl = playstream.url
            
        self.speak("Playing")
        #self.enclosure.bus.emit(Message("metadata", {"type": "youtube-skill", "title": "text", "video": str(playurl), "status": str("none")}))
        self.gui["video"] = str(playurl)
        self.gui["status"] = str("none")
        self.gui.show_page("YoutubePlayer.qml")
        
    def youtubepause(self, message):
        #self.enclosure.bus.emit(Message("metadata", {"type": "youtube-skill", "status": str("pause")}))
        self.gui["status"] = str("pause")
        self.gui.show_page("YoutubePlayer.qml")
    
    def youtuberesume(self, message):
        #self.enclosure.bus.emit(Message("metadata", {"type": "youtube-skill", "status": str("resume")}))
        self.gui["status"] = str("resume")
        self.gui.show_page("YoutubePlayer.qml")
        
    def youtubesearchpage(self, message):
        self.stop()
        videoList = []
        videoList.clear()
        videoPageObject = {}
        utterance = message.data.get('utterance').lower()
        utterance = utterance.replace(
            message.data.get('YoutubeSearchPageKeyword'), '')
        vid = self.search(utterance)
        url = "https://www.youtube.com/results?search_query=" + vid
        response = urlopen(url)
        html = response.read()
        soup = BeautifulSoup(html)            
        for vid in soup.findAll(attrs={'class': 'yt-uix-tile-link'}):
            if "googleads" not in vid['href'] and not vid['href'].startswith(
                    u"/user") and not vid['href'].startswith(u"/channel"):
                videoID = vid['href'].split("v=")[1].split("&")[0]
                videoTitle = vid['title']
                videoImage = "https://i.ytimg.com/vi/{0}/hqdefault.jpg".format(videoID)
                videoList.append({"videoID": videoID, "videoTitle": videoTitle, "videoImage": videoImage})
        videoPageObject['videoList'] = videoList
        #self.enclosure.bus.emit(Message("metadata", {"type": "youtube-skill/search-page", "videoListBlob": videoPageObject}))
        self.gui["videoListBlob"] = videoPageObject
        self.gui.show_page("YoutubeSearch.qml")

    def stop(self):
        self.enclosure.bus.emit(Message("metadata", {"type": "stop"}))
        if self.process:
            self.process.terminate()
            self.process.wait()
        pass

    def play_event(self, message):
        urlvideo = "http://www.youtube.com/watch?v={0}".format(message.data['vidID'])
        video = pafy.new(urlvideo)
        print(video.streams)
        for vid_type in video.streams:
            if (vid_type._extension == 'mp4'):
                try:
                    if(vid_type._resolution == '480x360'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '426x240'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '320x180'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '640x342'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '640x360'):
                        playurl = vid_type._url
                    elif (vid_type._resolution == '256x144'):
                        playurl = vid_type.url
                    elif (vid_type._resolution == '176x144'):
                        playurl = vid_type.url
                except:
                    playstream = video.getbest(preftype="mp4", ftypestrict=True)
                    playurl = playstream.url
            
        self.speak("Playing")
        #self.enclosure.bus.emit(Message("metadata", {"type": "youtube-skill", "title": "text", "video": str(playurl), "status": str("none")}))
        self.gui["video"] = str(playurl)
        self.gui["status"] = str("none")
        self.gui.show_page("YoutubePlayer.qml")
        
def create_skill():
    return YoutubeSkill()
