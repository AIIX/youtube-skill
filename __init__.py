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

__author__ = 'aix'
 
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
            
    def getTitle(self, text):
        query = quote(text)
        url = "https://www.youtube.com/results?search_query=" + query
        response = urlopen(url)
        html = response.read()
        soup = BeautifulSoup(html)
        for vid in soup.findAll(attrs={'class': 'yt-uix-tile-link'}):
            if "googleads" not in vid['href'] and not vid['href'].startswith(
                    u"/user") and not vid['href'].startswith(u"/channel"):
                videoTitle = vid['title']
                return videoTitle

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
        self.gui["video"] = str(playurl)
        self.gui["status"] = str("play")
        self.gui["currenturl"] = str(vid)
        self.gui["currenttitle"] = self.getTitle(utterance)
        self.youtubesearchpagesimple(utterance)
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)
                
    def youtubepause(self, message):
        self.gui["status"] = str("pause")
        self.gui.show_page("YoutubePlayer.qml")
    
    def youtuberesume(self, message):
        self.gui["status"] = str("play")
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
        self.gui["videoListBlob"] = videoPageObject
        self.gui.show_page("YoutubeSearch.qml")
        
    def youtubesearchpagesimple(self, query):
        videoList = []
        videoList.clear()
        videoPageObject = {}
        vid = self.search(query)
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
        self.gui["videoListBlob"] = videoPageObject

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
        self.gui["video"] = str(playurl)
        self.gui["status"] = str("play")
        self.gui["currenturl"] = str(message.data['vidID'])
        self.gui["currenttitle"] = str(message.data['vidTitle'])
        videoTitleSearch = str(message.data['vidTitle']).join(str(message.data['vidTitle']).split()[:-1])
        self.youtubesearchpagesimple(videoTitleSearch)
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)

def create_skill():
    return YoutubeSkill()
