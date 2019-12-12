# -*- coding: utf-8 -*-

import time
import urllib
from os.path import dirname
import pafy
import sys
import json
if sys.version_info[0] < 3:
    from urllib import quote
    from urllib2 import urlopen
else:
    from urllib.request import urlopen
    from urllib.parse import quote, urlencode
from adapt.intent import IntentBuilder
from bs4 import BeautifulSoup, SoupStrainer
from mycroft.skills.core import MycroftSkill, intent_handler, intent_file_handler
from mycroft.messagebus.message import Message
from mycroft.util.log import LOG
from collections import deque

__author__ = 'aix'

class YoutubeSkill(MycroftSkill):
    def __init__(self):
        super(YoutubeSkill, self).__init__(name="YoutubeSkill")
        self.process = None
        self.nextpage_url = None
        self.previouspage_url = None
        self.live_category = None
        self.recentList = deque()
        self.recentPageObject = {}
        self.nextSongList = None
        self.lastSong = None

    def initialize(self):
        self.load_data_files(dirname(__file__))
        
        self.bus.on('youtube-skill.home', self.launcherId)
        
        youtubepause = IntentBuilder("YoutubePauseKeyword"). \
            require("YoutubePauseKeyword").build()
        self.register_intent(youtubepause, self.youtubepause)

        youtuberesume = IntentBuilder("YoutubeResumeKeyword"). \
            require("YoutubeResumeKeyword").build()
        self.register_intent(youtuberesume, self.youtuberesume)

        youtubesearchpage = IntentBuilder("YoutubeSearchPageKeyword"). \
            require("YoutubeSearchPageKeyword").build()
        self.register_intent(youtubesearchpage, self.youtubesearchpage)

        youtubelivesearchpage = IntentBuilder("YoutubeLiveSearchPage"). \
            require("YoutubeLiveSearchPageKeyword").build()
        self.register_intent(youtubelivesearchpage, self.youtubelivesearchpage)

        youtubelauncherId = IntentBuilder("YoutubeLauncherId"). \
            require("YoutubeLauncherIdKeyword").build()
        self.register_intent(youtubelauncherId, self.launcherId)
        
        self.add_event('aiix.youtube-skill.playvideo_id', self.play_event)
        
        self.gui.register_handler('YoutubeSkill.SearchLive',
                                  self.searchLive)
        
        self.gui.register_handler('YoutubeSkill.NextPage', self.searchNextPage)
        self.gui.register_handler('YoutubeSkill.PreviousPage', self.searchPreviousPage)
        self.gui.register_handler('YoutubeSkill.NextAutoPlaySong', self.nextSongForAutoPlay)
        self.gui.register_handler('YoutubeSkill.RefreshWatchList', self.refreshWatchList)
        
    def launcherId(self, message):
        self.gui.show_page("YoutubeLogo.qml")
        self.youtubelivesearchpage({})

    def getListSearch(self, text):
        query = quote(text)
        url = "https://www.youtube.com/results?search_query=" + quote(query)
        response = urlopen(url)
        html = response.read()
        a_tag = SoupStrainer('a')
        soup = BeautifulSoup(html, 'html.parser', parse_only=a_tag)
        for vid in soup.findAll(attrs={'class': 'yt-uix-tile-link'}):
            if "googleads" not in vid['href'] and not vid['href'].startswith(
                    u"/user") and not vid['href'].startswith(u"/channel"):
                id = vid['href'].split("v=")[1].split("&")[0]
                return id

    def moreRandomListSearch(self, text):
        query = quote(text)
        try:
            querySplit = text.split()
            LOG.info(querySplit)
            searchQuery = "*," + quote(querySplit[0]) + quote(querySplit[1]) + ",*"
        
        except:
            LOG.info("fail")
            searchQuery = "*," + quote(query) + ",*"

        LOG.info(searchQuery)
        return searchQuery    
    

    def searchLive(self, message):
        videoList = []
        videoList.clear()
        videoPageObject = {}
        try:
            query = message.data["Query"]
            url = "https://www.youtube.com/results?search_query=" + quote(query)
            response = urlopen(url)
            html = response.read()
            buttons = self.process_additional_pages(html)
            nextbutton = buttons[-1]
            prevbutton = "results?search_query=" + quote(query)
            self.nextpage_url = "https://www.youtube.com/" + nextbutton['href']
            self.previouspage_url = "https://www.youtube.com/" + prevbutton
            videoList = self.process_soup(html)
            videoPageObject['videoList'] = videoList
            self.gui["videoListBlob"] = videoPageObject
            self.gui["previousAvailable"] = False
            self.gui["nextAvailable"] = True
            self.gui["bgImage"] = quote(query)
            self.gui.show_page("YoutubeLiveSearch.qml", override_idle=True)
        except:
            LOG.debug("error")
        
    def searchNextPage(self, message):
        self.gui.clear()
        self.enclosure.display_manager.remove_active()
        videoList = []
        videoList.clear()
        videoPageObject = {}
        url = self.nextpage_url 
        response = urlopen(url)
        html = response.read()
        videoList = self.process_soup(html)
        videoPageObject['videoList'] = videoList
        self.gui["videoListBlob"] = videoPageObject
        self.gui["previousAvailable"] = True
        self.gui["nextAvailable"] = False
        self.gui["bgImage"] = self.live_category
        self.gui.show_page("YoutubeLiveSearch.qml", override_idle=True)
        
    def searchPreviousPage(self, message):
        self.gui.clear()
        self.enclosure.display_manager.remove_active()
        videoList = []
        videoList.clear()
        videoPageObject = {}
        url = self.previouspage_url
        response = urlopen(url)
        html = response.read()
        videoList = self.process_soup(html)
        videoPageObject['videoList'] = videoList
        self.gui["videoListBlob"] = videoPageObject
        self.gui["previousAvailable"] = False
        self.gui["nextAvailable"] = True
        self.gui["bgImage"] = self.live_category
        self.gui.show_page("YoutubeLiveSearch.qml", override_idle=True)
            
    def getTitle(self, text):
        query = quote(text)
        url = "https://www.youtube.com/results?search_query=" + quote(query)
        response = urlopen(url)
        html = response.read()
        soup = BeautifulSoup(html)
        for vid in soup.findAll(attrs={'class': 'yt-uix-tile-link'}):
            if "googleads" not in vid['href'] and not vid['href'].startswith(
                    u"/user") and not vid['href'].startswith(u"/channel"):
                videoTitle = vid['title']
                return videoTitle


    @intent_file_handler('youtube.intent')
    def youtube(self, message):
        self.stop()
        utterance = message.data['videoname'].lower()
        url = "https://www.youtube.com/results?search_query=" + quote(utterance)
        response = urlopen(url)
        html = response.read()
        a_tag = SoupStrainer('a')
        soup = BeautifulSoup(html, 'html.parser', parse_only=a_tag)
        self.gui["video"] = ""
        self.gui["status"] = "stop"
        self.gui["currenturl"] = ""
        self.gui["videoListBlob"] = ""
        self.gui["recentListBlob"] = ""
        self.gui["videoThumb"] = ""
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)
        rfind = soup.findAll(attrs={'class': 'yt-uix-tile-link'})
        vid = str(rfind[0].attrs['href'])
        veid = "https://www.youtube.com{0}".format(vid)
        getvid = vid.split("v=")[1].split("&")[0]
        thumb = "https://img.youtube.com/vi/{0}/maxresdefault.jpg".format(getvid)
        self.gui["videoThumb"] = thumb
        self.lastSong = veid
        video = pafy.new(veid)
        playstream = video.streams[0]
        playurl = playstream.url
        self.gui["status"] = str("play")
        self.gui["video"] = str(playurl)
        self.gui["currenturl"] = str(vid)
        self.gui["currenttitle"] = video.title
        self.gui["setTitle"] = video.title
        self.gui["viewCount"] = video.viewcount
        self.gui["publishedDate"] = video.published
        self.gui["videoAuthor"] = video.username
        self.gui["videoListBlob"] = ""
        self.gui["recentListBlob"] = ""
        self.gui["nextSongTitle"] = ""
        self.gui["nextSongImage"] = ""
        self.gui["nextSongID"] = ""
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)
        self.gui["currenttitle"] = self.getTitle(utterance)
        self.recentList.appendleft({"videoID": getvid, "videoTitle": video.title, "videoImage": thumb})
        self.youtubesearchpagesimple(utterance)

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
        vid = self.getListSearch(utterance)
        url = "https://www.youtube.com/results?search_query=" + vid
        response = urlopen(url)
        html = response.read()
        videoList = self.process_soup(html)
        videoPageObject['videoList'] = videoList
        self.recentPageObject['recentList'] = list(self.recentList)
        self.gui["videoListBlob"] = videoPageObject
        self.gui["recentListBlob"] = self.recentPageObject
        self.gui.show_page("YoutubeSearch.qml")
        
    def youtubesearchpagesimple(self, query):
        videoList = []
        videoList.clear()
        videoPageObject = {}
        vid = self.moreRandomListSearch(query)
        url = "https://www.youtube.com/results?search_query=" + vid
        response = urlopen(url)
        html = response.read()
        videoList = self.process_soup(html)        
        videoPageObject['videoList'] = videoList
        self.gui["videoListBlob"] = videoPageObject
        self.recentPageObject['recentList'] = list(self.recentList)
        self.gui["recentListBlob"] = self.recentPageObject
        
    def youtubelivesearchpage(self, message):
        self.gui.clear()
        self.enclosure.display_manager.remove_active()
        videoPageObject = {}
        url = "https://www.youtube.com/results?search_query=news" 
        response = urlopen(url)
        html = response.read()
        buttons = self.process_additional_pages(html)
        nextbutton = buttons[-1]
        prevbutton = "results?search_query=news"
        self.nextpage_url = "https://www.youtube.com/" + nextbutton['href']
        self.previouspage_url = "https://www.youtube.com/" + prevbutton
        videoList = self.process_soup(html)
        videoPageObject['videoList'] = videoList
        self.gui["videoListBlob"] = videoPageObject
        self.gui["previousAvailable"] = False
        self.gui["nextAvailable"] = True
        self.gui["bgImage"] = self.live_category
        self.gui.show_page("YoutubeLiveSearch.qml", override_idle=True)

    def play_event(self, message):
        urlvideo = "http://www.youtube.com/watch?v={0}".format(message.data['vidID'])
        self.lastSong = message.data['vidID']
        video = pafy.new(urlvideo)
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
        self.gui["setTitle"] = video.title
        self.gui["viewCount"] = video.viewcount
        self.gui["publishedDate"] = video.published
        self.gui["videoAuthor"] = video.username
        self.gui["nextSongTitle"] = ""
        self.gui["nextSongImage"] = ""
        self.gui["nextSongID"] = ""
        videoTitleSearch = str(message.data['vidTitle']).join(str(message.data['vidTitle']).split()[:-1])
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)
        thumb = "https://img.youtube.com/vi/{0}/maxresdefault.jpg".format(message.data['vidID'])
        self.recentList.appendleft({"videoID": str(message.data['vidID']), "videoTitle": str(message.data['vidTitle']), "videoImage": thumb})
        self.recentPageObject['recentList'] = list(self.recentList)
        self.gui["recentListBlob"] = self.recentPageObject
        #self.youtubesearchpagesimple(videoTitleSearch)

    def stop(self):
        self.enclosure.bus.emit(Message("metadata", {"type": "stop"}))
        if self.process:
            self.process.terminate()
            self.process.wait()
        pass
    
    def process_soup(self, htmltype):
        videoList = []
        videoList.clear()
        soup = BeautifulSoup(htmltype)
        for vid in soup.findAll(attrs={'class': 'yt-uix-tile-link'}):
            if "googleads" not in vid['href'] and not vid['href'].startswith(
                    u"/user") and not vid['href'].startswith(u"/channel"):
                videoID = vid['href'].split("v=")[1].split("&")[0]
                videoTitle = vid['title']
                videoImage = "https://i.ytimg.com/vi/{0}/hqdefault.jpg".format(videoID)
                videoList.append({"videoID": videoID, "videoTitle": videoTitle, "videoImage": videoImage})
                
        if len(videoList) > 1:
            self.nextSongList = videoList[1]
        else:
            self.nextSongList = videoList[0]
            
        return videoList
    
    def process_additional_pages(self, htmltype):
        soup = BeautifulSoup(htmltype)
        buttons = soup.findAll('a',attrs={'class':"yt-uix-button vve-check yt-uix-sessionlink yt-uix-button-default yt-uix-button-size-default"})
        return buttons
    
    def nextSongForAutoPlay(self):
        self.gui["nextSongTitle"] = self.nextSongList["videoTitle"]
        self.gui["nextSongImage"] = self.nextSongList["videoImage"]
        self.gui["nextSongID"] = self.nextSongList["videoID"]
    
    def refreshWatchList(self, message):
        self.youtubesearchpagesimple(message.data["title"])
        
    @intent_file_handler('youtube-repeat.intent')
    def youtube_repeat_last(self):
        video = pafy.new(self.lastSong)
        thumb = video.thumb
        playstream = video.streams[0]
        playurl = playstream.url
        self.gui["status"] = str("play")
        self.gui["video"] = str(playurl)
        self.gui["currenturl"] = ""
        self.gui["currenttitle"] = video.title
        self.gui["setTitle"] = video.title
        self.gui["viewCount"] = video.viewcount
        self.gui["publishedDate"] = video.published
        self.gui["videoAuthor"] = video.username
        self.gui["videoListBlob"] = ""
        self.gui["recentListBlob"] = ""
        self.gui["nextSongTitle"] = ""
        self.gui["nextSongImage"] = ""
        self.gui["nextSongID"] = ""
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)
        self.youtubesearchpagesimple(video.title)
    
def create_skill():
    return YoutubeSkill()
