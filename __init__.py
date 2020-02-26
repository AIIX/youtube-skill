# -*- coding: utf-8 -*-

import time
import urllib
from os.path import dirname
import pafy
import sys
import json
import base64
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
from json_database import JsonStorage

__author__ = 'aix'

class YoutubeSkill(MycroftSkill):
    def __init__(self):
        super(YoutubeSkill, self).__init__(name="YoutubeSkill")
        self.nextpage_url = None
        self.previouspage_url = None
        self.live_category = None
        self.recentList = deque()
        self.recentPageObject = {}
        self.nextSongList = None
        self.lastSong = None
        self.videoPageObject = {}
        self.isTitle = None
        self.newsCategoryList = {}
        self.musicCategoryList = {}
        self.techCategoryList = {}
        self.polCategoryList = {}
        self.gamingCategoryList = {}
        self.searchCategoryList = {}
        self.storeDB = dirname(__file__) + '-recent.db'
        self.recent_db = JsonStorage(self.storeDB)
        self.ytkey = base64.b64decode("QUl6YVN5RE9tSXhSemI0RzFhaXFzYnBaQ3IwQTlFN1NrT0pVRURr")
        pafy.set_api_key(self.ytkey)
        
    def initialize(self):
        self.load_data_files(dirname(__file__))
        
        self.bus.on('youtube-skill.aiix.home', self.launcherId)
        
        youtubepause = IntentBuilder("YoutubePauseKeyword"). \
            require("YoutubePauseKeyword").build()
        self.register_intent(youtubepause, self.youtubepause)

        youtuberesume = IntentBuilder("YoutubeResumeKeyword"). \
            require("YoutubeResumeKeyword").build()
        self.register_intent(youtuberesume, self.youtuberesume)

        youtubesearchpage = IntentBuilder("YoutubeSearchPageKeyword"). \
            require("YoutubeSearchPageKeyword").build()
        self.register_intent(youtubesearchpage, self.youtubesearchpage)

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
        self.gui.register_handler('YoutubeSkill.ClearDB', self.clear_db)
        
    def launcherId(self, message):
        self.show_homepage({})

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
        LOG.info(text)
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
            LOG.info("I am in search Live")
            self.searchCategoryList["videoList"] = self.build_category_list(quote(query))
            self.gui["searchListBlob"] = self.searchCategoryList
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
        videoList = self.process_soup_additional(html)
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
        videoList = self.process_soup_additional(html)
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
        self.gui.clear()
        self.enclosure.display_manager.remove_active()
        utterance = message.data['videoname'].lower()
        self.youtube_play_video(utterance)
    
    def youtube_play_video(self, utterance):
        self.gui["setTitle"] = ""
        self.gui["video"] = ""
        self.gui["status"] = "stop"
        self.gui["currenturl"] = ""
        self.gui["videoListBlob"] = ""
        self.gui["recentListBlob"] = ""
        self.gui["videoThumb"] = ""
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
        try:
            vid = str(rfind[0].attrs['href'])
            veid = "https://www.youtube.com{0}".format(vid)
            LOG.info(veid)
            getvid = vid.split("v=")[1].split("&")[0]
        except:
            vid = str(rfind[1].attrs['href'])
            veid = "https://www.youtube.com{0}".format(vid)
            LOG.info(veid)
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
        if 'recentList' in self.recent_db.keys():
            recentVideoList = self.recent_db['recentList']
        else:
            recentVideoList = []
        recentVideoList.insert(0, {"videoID": getvid, "videoTitle": video.title, "videoImage": video.thumb})
        self.recent_db['recentList'] = recentVideoList
        self.recent_db.store()
        self.gui["recentListBlob"] = self.recent_db
        self.youtubesearchpagesimple(utterance)
        self.isTitle = video.title
        self.gui["recentListBlob"] = self.recent_db
        
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
        videoList = self.process_soup_additional(html)
        videoPageObject['videoList'] = videoList
        self.gui["videoListBlob"] = videoPageObject
        self.gui["recentListBlob"] = self.recent_db
        self.gui.show_page("YoutubeSearch.qml")
        
    def youtubesearchpagesimple(self, query):
        LOG.info(query)
        videoList = []
        videoList.clear()
        videoPageObject = {}
        vid = self.moreRandomListSearch(query)
        url = "https://www.youtube.com/results?search_query=" + vid
        response = urlopen(url)
        html = response.read()
        videoList = self.process_soup_additional(html)        
        videoPageObject['videoList'] = videoList
        self.gui["videoListBlob"] = videoPageObject
        self.gui["recentListBlob"] = self.recent_db
        
    def show_homepage(self, message):
        LOG.info("I AM IN HOME PAGE FUNCTION")
        self.gui.clear()
        self.enclosure.display_manager.remove_active()
        self.gui["loadingStatus"] = ""
        self.gui.show_page("YoutubeLogo.qml")
        self.process_home_page()

    def process_home_page(self):
        LOG.info("I AM IN HOME PROCESS PAGE FUNCTION")
        self.gui.show_page("YoutubeLogo.qml")
        self.gui["loadingStatus"] = "Fetching News"
        self.newsCategoryList['videoList'] = self.build_category_list("news")
        self.gui["loadingStatus"] = "Fetching Music"
        self.musicCategoryList['videoList'] = self.build_category_list("music")
        self.gui.clear()
        self.enclosure.display_manager.remove_active()
        self.show_search_page()
        self.techCategoryList['videoList'] = self.build_category_list("technology")
        self.gui["techListBlob"] = self.techCategoryList
        self.polCategoryList['videoList'] = self.build_category_list("politics")
        self.gui["polListBlob"] = self.polCategoryList
        self.gamingCategoryList['videoList'] = self.build_category_list("gaming")
        self.gui["gamingListBlob"] = self.gamingCategoryList     
        LOG.info("I AM NOW IN REMOVE LOGO PAGE FUNCTION")

    def show_search_page(self):
        LOG.info("I AM NOW IN SHOW SEARCH PAGE FUNCTION")
        LOG.info(self.techCategoryList)
        self.gui["newsListBlob"] = self.newsCategoryList
        self.gui["musicListBlob"] = self.musicCategoryList
        self.gui["techListBlob"] = self.techCategoryList
        self.gui["polListBlob"] = self.polCategoryList
        self.gui["gamingListBlob"] = self.gamingCategoryList
        self.gui["searchListBlob"] = ""
        self.gui["previousAvailable"] = False
        self.gui["nextAvailable"] = True
        self.gui["bgImage"] = self.live_category
        self.gui.show_page("YoutubeLiveSearch.qml", override_idle=True)
        

    def play_event(self, message):
        urlvideo = "http://www.youtube.com/watch?v={0}".format(message.data['vidID'])
        self.lastSong = message.data['vidID']
        video = pafy.new(urlvideo)
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
        if 'recentList' in self.recent_db.keys():
            recentVideoList = self.recent_db['recentList']
        else:
            recentVideoList = []
        recentVideoList.insert(0, {"videoID": str(message.data['vidID']), "videoTitle": str(message.data['vidTitle']), "videoImage": video.thumb})
        self.recent_db['recentList'] = recentVideoList
        self.recent_db.store()
        self.gui["recentListBlob"] = self.recent_db
        self.isTitle = video.title

    def stop(self):
        self.enclosure.bus.emit(Message("metadata", {"type": "stop"}))
        pass
    
    def process_soup(self, htmltype):
        videoList = []
        videoList.clear()
        soup = BeautifulSoup(htmltype)
        for vid in soup.findAll(attrs={'class': 'yt-uix-tile-link'}):
            if "googleads" not in vid['href'] and not vid['href'].startswith(
                    u"/user") and not vid['href'].startswith(u"/channel"):
                LOG.info(vid)
                videoID = vid['href'].split("v=")[1].split("&")[0]
                videoTitle = vid['title']
                videoImage = "https://i.ytimg.com/vi/{0}/hqdefault.jpg".format(videoID)
                videoList.append({"videoID": videoID, "videoTitle": videoTitle, "videoImage": videoImage})
                
        if len(videoList) > 1:
            self.nextSongList = videoList[1]
        else:
            self.nextSongList = videoList[0]
            
        return videoList
    
    def process_soup_additional(self, htmltype):
        videoList = []
        videoList.clear()
        soup = BeautifulSoup(htmltype)
        getVideoDetails = zip(soup.findAll(attrs={'class': 'yt-uix-tile-link'}), soup.findAll(attrs={'class': 'yt-lockup-byline'}), soup.findAll(attrs={'class': 'yt-lockup-meta-info'})) 
        for vid in getVideoDetails:
            if "googleads" not in vid[0]['href'] and not vid[0]['href'].startswith(
                u"/user") and not vid[0]['href'].startswith(u"/channel"):
                videoID = vid[0]['href'].split("v=")[1].split("&")[0]
                videoTitle = vid[0]['title']
                videoImage = "https://i.ytimg.com/vi/{0}/hqdefault.jpg".format(videoID)
                videoChannel = vid[1].contents[0].string
                videoUploadDate = vid[2].contents[0].string
                if "watching" in vid[2].contents[0].string:
                    videoViews = "Live"
                else:
                    try:
                        videoViews = vid[2].contents[1].string
                    except:
                        videoViews = "Playlist"

                videoList.append({"videoID": videoID, "videoTitle": videoTitle, "videoImage": videoImage, "videoChannel": videoChannel, "videoViews": videoViews, "videoUploadDate": videoUploadDate})

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
        try:
            self.youtubesearchpagesimple(message.data["title"])
        except:
            self.youtubesearchpagesimple(self.isTitle)
        
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
        self.isTitle = video.title

    def build_category_list(self, category):
        url = "https://www.youtube.com/results?search_query={0}".format(category)
        response = urlopen(url)
        html = response.read()
        videoList = self.process_soup_additional(html)
        return videoList
    
    def clear_db(self):
        LOG.info("In DB Clear")
        self.recent_db.clear()
        self.recent_db.store()
        self.gui["recentListBlob"] = ""


def create_skill():
    return YoutubeSkill()
