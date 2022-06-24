# -*- coding: utf-8 -*-

import time
import urllib
from os.path import dirname, join
import sys
import json
import base64
import re
import timeago, datetime
import dateutil.parser
import requests
import yt_dlp
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
from .tempfix.search.searcher import YoutubeSearcher
from yt_dlp import YoutubeDL

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
        self.trendCategoryList = {}
        self.newsCategoryList = {}
        self.musicCategoryList = {}
        self.techCategoryList = {}
        self.polCategoryList = {}
        self.gamingCategoryList = {}
        self.searchCategoryList = {}
        self.recentCategoryList = {}
        self.recentWatchListObj = {}
        self.storeDB = None
        self.recent_db = None
        self.quackAPIWorker="J0dvb2dsZWJvdC8yLjEgKCtodHRwOi8vd3d3Lmdvb2dsZS5jb20vYm90Lmh0bWwpJw=="
        self.quackagent = {'User-Agent' : base64.b64decode(self.quackAPIWorker)}
        self.yts = YoutubeSearcher()

    def initialize(self):
        self.load_data_files(dirname(__file__))
        self.storeDB = join(self.file_system.path, 'youtube-recent.db')
        self.recent_db = JsonStorage(self.storeDB)
        
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
        self.gui.register_handler('YoutubeSkill.ReplayLast', self.youtube_repeat_last)


    def get_best_video_url(self, video_id):
        # Use dlp to get the best video of type mp4 url from a video ID
        ydl_opts = { 'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' }
        try:
            ydl = YoutubeDL(ydl_opts)
            info = ydl.extract_info(video_id, download=False)
            video_container = []
            best_format = None
            for f in info['formats']:
                if f['acodec'] != 'none' and f['vcodec'] != 'none':
                    video_container.append(f)
            # sort video_container based on format_note using sorting table:
            if 'format_note' in video_container[0]:    
                sort_table = ["1080p", "720p", "480p", "360p", "240p", "144p"]
                video_container = sorted(video_container, key=lambda f: sort_table.index(f['format_note']))
                best_format = video_container[0].get('url')
                return best_format
            else: 
            # sort video_container based on format_id using sorting table in descending order:
                video_container = sorted(video_container, key=lambda f: f['format_id'], reverse=True)
                best_format = video_container[0].get('url')
                return best_format
        except Exception as e:
            LOG.error("Error: " + str(e))
            return None

    def extract_video_meta_from_dlp(self, video_id):
        # extract video information like title, views, published time and channel name
        ydl_opts = { 'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' }
        ydl = YoutubeDL(ydl_opts)
        info = ydl.extract_info(video_id, download=False)
        video_info = {}
        video_info['title'] = info['title']
        video_info['views'] = info['view_count']
        video_info['published'] = info['upload_date']
        video_info['channel'] = info['uploader']
        return video_info

    def launcherId(self, message):
        self.show_homepage({})
    
    @intent_file_handler('youtubeopenapp.intent')
    def launch_home_and_search_category(self, message):
        self.speak("Loading Up Youtube For You")
        self.show_homepage({})

    def getListSearch(self, text):
        query = quote(text)
        url = "https://www.youtube.com/results?search_query=" + quote(query)
        response = requests.get(url, headers=self.quackagent)
        html = response.text
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
        getCategory = message.data["Category"]
        LOG.info(getCategory)
        if getCategory == "News":
            LOG.info("In Category News")
            newsAdditionalPages = self.process_additional_pages("news")
            self.newsCategoryList['videoList'] = self.build_category_list_from_url("https://www.youtube.com" + newsAdditionalPages[0])
            self.gui["newsNextAvailable"] = False
            self.gui["newsListBlob"] = self.newsCategoryList
        if getCategory == "Music":
            LOG.info("In Category Music")
            musicAdditionalPages = self.process_additional_pages("music")
            self.musicCategoryList['videoList'] = self.build_category_list_from_url("https://www.youtube.com" + musicAdditionalPages[0])
            self.gui["musicNextAvailable"] = False
            self.gui["musicListBlob"] = self.musicCategoryList
        if getCategory == "Technology":
            LOG.info("In Category Technology")
            technologyAdditionalPages = self.process_additional_pages("technology")
            self.techCategoryList['videoList'] = self.build_category_list_from_url("https://www.youtube.com" + technologyAdditionalPages[0])
            self.gui["techNextAvailable"] = False
            self.gui["techListBlob"] = self.techCategoryList
        if getCategory == "Politics":
            LOG.info("In Category Politics")
            politicsAdditionalPages = self.process_additional_pages("politics")
            self.polCategoryList['videoList'] = self.build_category_list_from_url("https://www.youtube.com" + politicsAdditionalPages[0])
            self.gui["polNextAvailable"] = False
            self.gui["polListBlob"] = self.polCategoryList
        if getCategory == "Gaming":
            LOG.info("In Category Gaming")
            gamingAdditionalPages = self.process_additional_pages("gaming")
            self.gamingCategoryList['videoList'] = self.build_category_list_from_url("https://www.youtube.com" + gamingAdditionalPages[0])
            self.gui["gamingNextAvailable"] = False
            self.gui["gamingListBlob"] = self.gamingCategoryList
        if getCategory == "Search":
            LOG.info("In Search")
        
    def searchPreviousPage(self, message):
        getCategory = message.data["Category"]
        LOG.info(getCategory)
        if getCategory == "News":
            LOG.info("In Category News")
            newsAdditionalPages = self.process_additional_pages("news")
            self.newsCategoryList['videoList'] = self.build_category_list_from_url(newsAdditionalPages[1])
            self.gui["newsNextAvailable"] = True
            self.gui["newsListBlob"] = self.newsCategoryList
        if getCategory == "Music":
            LOG.info("In Category Music")
            musicAdditionalPages = self.process_additional_pages("music")
            self.musicCategoryList['videoList'] = self.build_category_list_from_url(musicAdditionalPages[1])
            self.gui["musicNextAvailable"] = True
            self.gui["musicListBlob"] = self.musicCategoryList
        if getCategory == "Technology":
            LOG.info("In Category Technology")
            technologyAdditionalPages = self.process_additional_pages("technology")
            self.techCategoryList['videoList'] = self.build_category_list_from_url(technologyAdditionalPages[1])
            self.gui["techNextAvailable"] = True
            self.gui["techListBlob"] = self.techCategoryList
        if getCategory == "Politics":
            LOG.info("In Category Politics")
            politicsAdditionalPages = self.process_additional_pages("politics")
            self.polCategoryList['videoList'] = self.build_category_list_from_url(politicsAdditionalPages[1])
            self.gui["polNextAvailable"] = True
            self.gui["polListBlob"] = self.polCategoryList
        if getCategory == "Gaming":
            LOG.info("In Category Gaming")
            gamingAdditionalPages = self.process_additional_pages("gaming")
            self.gamingCategoryList['videoList'] = self.build_category_list_from_url(gamingAdditionalPages[1])
            self.gui["gamingNextAvailable"] = True
            self.gui["gamingListBlob"] = self.gamingCategoryList
        if getCategory == "Search":
            LOG.info("In Search")
            
    def getTitle(self, text):
        query = quote(text)
        url = "https://www.youtube.com/results?search_query=" + quote(query)
        response = requests.get(url, headers=self.quackagent)
        html = response.text
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
        response = requests.get(url, headers=self.quackagent)
        html = response.text
        a_tag = SoupStrainer('a')
        soup = BeautifulSoup(html, 'html.parser', parse_only=a_tag)
        self.gui["video"] = ""
        self.gui["status"] = "stop"
        self.gui["currenturl"] = ""
        self.gui["videoListBlob"] = ""
        self.gui["recentListBlob"] = ""
        self.gui["videoThumb"] = ""
        video_query_str = str(quote(utterance))
        #print(video_query_str)
        abc = self.yts.search_youtube(video_query_str, render="videos")
        vid = abc['videos'][0]['url']
        stream_url = self.get_best_video_url(vid)
        if stream_url is not None:
            getvid = vid.split("v=")[1].split("&")[0]
            thumb = "https://img.youtube.com/vi/{0}/0.jpg".format(getvid)
            self.gui["videoThumb"] = thumb
            self.lastSong = vid
            self.gui["status"] = str("play")
            self.gui["video"] = str(stream_url)
            self.gui["currenturl"] = str(vid)
            self.gui["currenttitle"] = abc['videos'][0]['title']
            self.gui["setTitle"] = abc['videos'][0]['title']
            self.gui["viewCount"] = abc['videos'][0]['views']
            self.gui["publishedDate"] = abc['videos'][0]['published_time']
            self.gui["videoAuthor"] = abc['videos'][0]['channel_name']
            self.gui["videoListBlob"] = ""
            self.gui["recentListBlob"] = ""
            self.gui["nextSongBlob"] = ""
            self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)
            #self.gui.show_page("YoutubeSearch.qml", override_idle=True)
            self.gui["currenttitle"] = self.getTitle(utterance)
            LOG.info("Video Published On")
            recentVideoDict = {"videoID": getvid, "videoTitle": abc['videos'][0]['title'], "videoImage": thumb, "videoChannel": abc['videos'][0]['channel_name'], "videoViews": abc['videos'][0]['views'], "videoUploadDate": abc['videos'][0]['published_time'], "videoDuration": abc['videos'][0]['length']}
            self.buildHistoryModel(recentVideoDict)
            self.gui["recentListBlob"] = self.recent_db
            self.youtubesearchpagesimple(getvid)
            self.isTitle = abc['videos'][0]['title']
            self.gui["recentListBlob"] = self.recent_db
        else:
            self.speak("Sorry, I can't find the video.")

    def process_ytl_stream(self, streams):
        _videostreams = []
        for z in range(len(streams)):
            if streams[z].get("vcodec") != "none":
               if streams[z].get("acodec") != "none":
                   _videostreams.append(streams[z])

        for a in range(len(_videostreams)):
            if _videostreams[a]["format_note"] == "720p":
                return _videostreams[a]["url"]
            elif _videostreams[a]["format_note"] == "480p":
                return _videostreams[a]["url"]
            elif _videostreams[a]["format_note"] == "360p":
                return _videostreams[a]["url"]
            elif _videostreams[a]["format_note"] == "240p":
                return _videostreams[a]["url"]
            elif _videostreams[a]["format_note"] == "144p":
                return _videostreams[a]["url"]
        
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
        response = requests.get(url, headers=self.quackagent)
        html = response.text
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
        yts = YoutubeSearcher()
        vidslist = yts.watchlist_search(video_id=query)
        for x in range(len(vidslist['watchlist_videos'])):
            videoID = vidslist['watchlist_videos'][x]['videoId']
            videoTitle = vidslist['watchlist_videos'][x]['title']
            videoImage = "https://img.youtube.com/vi/{0}/0.jpg".format(videoID)
            videoUploadDate = vidslist['watchlist_videos'][x]['published_time']
            videoDuration = vidslist['watchlist_videos'][x]['length']
            videoViews = vidslist['watchlist_videos'][x]['views']
            videoChannel = vidslist['watchlist_videos'][x]['channel_name']
            videoList.append({"videoID": videoID, "videoTitle": videoTitle, "videoImage": videoImage, "videoChannel": videoChannel, "videoViews": videoViews, "videoUploadDate": videoUploadDate, "videoDuration": videoDuration})
        
        videoPageObject['videoList'] = videoList
        self.gui["videoListBlob"] = videoPageObject
        self.gui["recentListBlob"] = self.recent_db
        
    def show_homepage(self, message):
        LOG.info("I AM IN HOME PAGE FUNCTION")
        self.gui.clear()

        self.gui["loadingStatus"] = ""
        self.gui.show_page("YoutubeLogo.qml")
        self.process_home_page()

    def process_home_page(self):
        LOG.info("I AM IN HOME PROCESS PAGE FUNCTION")
        self.gui["loadingStatus"] = "Fetching Trends"
        self.trendCategoryList['videoList'] = self.build_category_list_from_url("https://www.youtube.com/feed/trending")
        if self.trendCategoryList['videoList']:
            LOG.info("Trends Not Empty")
        else:
            LOG.info("Trying To Rebuild Trends List")
            self.trendCategoryList['videoList'] = self.build_category_list_from_url("https://www.youtube.com/feed/trending")
        self.gui["loadingStatus"] = "Fetching News"
        self.newsCategoryList['videoList'] = self.build_category_list("news")
        if self.newsCategoryList['videoList']:
            LOG.info("News Not Empty")
        else:
            LOG.info("Trying To Rebuild News List")
            self.newsCategoryList['videoList'] = self.build_category_list("news")
        
        self.build_recent_watch_list(20)
        self.gui.clear()

        self.show_search_page()
        
        self.musicCategoryList['videoList'] = self.build_category_list("music")
        if self.musicCategoryList['videoList']:
            LOG.info("Music Not Empty")
        else:
            LOG.info("Trying To Rebuild Music List")
            self.musicCategoryList['videoList'] = self.build_category_list("music")
        self.gui["musicListBlob"] = self.musicCategoryList
        
        self.techCategoryList['videoList'] = self.build_category_list("technology")
        if self.techCategoryList['videoList']:
            LOG.info("Tech Not Empty")
        else:
            LOG.info("Trying To Rebuild Tech List")
            self.techCategoryList['videoList'] = self.build_category_list("technology")
        self.gui["techListBlob"] = self.techCategoryList
        
        self.polCategoryList['videoList'] = self.build_category_list("politics")
        if self.polCategoryList['videoList']:
            LOG.info("Pol Not Empty")
        else:
            LOG.info("Trying To Rebuild Pol List")
            self.polCategoryList['videoList'] = self.build_category_list("politics")            
        self.gui["polListBlob"] = self.polCategoryList
        
        self.gamingCategoryList['videoList'] = self.build_category_list("gaming")
        if self.gamingCategoryList['videoList']:
            LOG.info("Gaming Not Empty")
        else:
            LOG.info("Trying To Rebuild Pol List")
            self.gamingCategoryList['videoList'] = self.build_category_list("gaming")
        self.gui["gamingListBlob"] = self.gamingCategoryList
        
        LOG.info("I AM NOW IN REMOVE LOGO PAGE FUNCTION")

    def show_search_page(self):
        LOG.info("I AM NOW IN SHOW SEARCH PAGE FUNCTION")
        LOG.info(self.techCategoryList)
        self.gui["recentHomeListBlob"] = self.recentWatchListObj
        self.gui["recentListBlob"] = self.recent_db 
        self.gui["trendListBlob"] = self.trendCategoryList
        self.gui["newsListBlob"] = self.newsCategoryList
        self.gui["newsNextAvailable"] = True
        self.gui["musicListBlob"] = self.musicCategoryList
        self.gui["musicNextAvailable"] = True
        self.gui["techListBlob"] = self.techCategoryList
        self.gui["techNextAvailable"] = True
        self.gui["polListBlob"] = self.polCategoryList
        self.gui["polNextAvailable"] = True
        self.gui["gamingListBlob"] = self.gamingCategoryList
        self.gui["gamingNextAvailable"] = True
        self.gui["searchListBlob"] = ""
        self.gui["previousAvailable"] = False
        self.gui["nextAvailable"] = True
        self.gui["bgImage"] = self.live_category
        self.gui.show_page("YoutubeLiveSearch.qml", override_idle=True)
        

    def play_event(self, message):
        urlvideo = "http://www.youtube.com/watch?v={0}".format(message.data['vidID'])
        self.lastSong = message.data['vidID']
        try:
            video = self.yts.extract_video_meta(urlvideo)
            self.gui["publishedDate"] = self.build_upload_date_non_vui(video.get('published_time'))
        except:
            video = self.extract_video_meta_from_dlp(urlvideo)
            self.gui["publishedDate"] = video.get('published')
        playurl = self.get_best_video_url(urlvideo)
        if playurl is not None:
            self.speak("Playing")
            self.gui["video"] = str(playurl)
            self.gui["status"] = str("play")
            self.gui["currenturl"] = str(message.data['vidID'])
            self.gui["currenttitle"] = str(message.data['vidTitle'])
            #print(video.keys())
            self.gui["setTitle"] = video.get('title')
            self.gui["viewCount"] = video.get('views')
            self.gui["videoAuthor"] = video.get('channel_name')
            self.gui["nextSongBlob"] = ""
            videoTitleSearch = str(message.data['vidTitle']).join(str(message.data['vidTitle']).split()[:-1])
            self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)
            thumb = "https://img.youtube.com/vi/{0}/maxresdefault.jpg".format(message.data['vidID'])
            recentVideoDict = {"videoID": message.data['vidID'], "videoTitle": message.data['vidTitle'], "videoImage": message.data['vidImage'], "videoChannel": message.data['vidChannel'], "videoViews": message.data['vidViews'], "videoUploadDate": message.data['vidUploadDate'], "videoDuration": message.data['vidDuration']}
            self.buildHistoryModel(recentVideoDict)
            self.gui["recentListBlob"] = self.recent_db
            self.youtubesearchpagesimple(message.data['vidID'])
            self.isTitle = video.get('title')
        else:
            self.speak("Sorry, I can't find the video.")

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
        getVideoDetails = zip(soup.findAll(attrs={'class': 'yt-uix-tile-link'}), soup.findAll(attrs={'class': 'yt-lockup-byline'}), soup.findAll(attrs={'class': 'yt-lockup-meta-info'}), soup.findAll(attrs={'class': 'video-time'}))
        for vid in getVideoDetails:
            if "googleads" not in vid[0]['href'] and not vid[0]['href'].startswith(
                u"/user") and not vid[0]['href'].startswith(u"/channel") and not vid[0]['href'].startswith('/news') and not vid[0]['href'].startswith('/music') and not vid[0]['href'].startswith('/technology') and not vid[0]['href'].startswith('/politics') and not vid[0]['href'].startswith('/gaming'):
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

                videoList.append({"videoID": videoID, "videoTitle": videoTitle, "videoImage": videoImage, "videoChannel": videoChannel, "videoViews": videoViews, "videoUploadDate": videoUploadDate, "videoDuration": videoDuration})

        return videoList
    
    def process_additional_pages(self, category):
        url = "https://www.youtube.com/results?search_query={0}".format(category)
        response = requests.get(url, headers=self.quackagent)
        html = response.text
        soup = BeautifulSoup(html)
        buttons = soup.findAll('a', attrs={'class':"yt-uix-button vve-check yt-uix-sessionlink yt-uix-button-default yt-uix-button-size-default"})
        try:
            nPage = buttons[0]['href']
        except:
            nPage = self.process_additional_pages_fail(category)
        pPage = url
        addPgObj = [nPage, pPage]
        
        return addPgObj
    
    def process_additional_pages_fail(self, category):
        url = None
        if category == "news":
            url = "/results?search_query=world+news"
        if category == "music":
            url = "/results?search_query=latest+music"
        if category == "technology":
            url = "/results?search_query=latest+tech"
        if category == "politics":
            url = "/results?search_query=latest+politics"
        if category == "gaming":
            url = "/results?search_query=latest+games"

        return url
                    
    
    def nextSongForAutoPlay(self):
        self.gui["nextSongBlob"] = self.nextSongList
        
    def refreshWatchList(self, message):
        print("Currently Disabled, Skipping Step")        
        #try:
            #print("todo")
            #self.youtubesearchpagesimple(self.lastSong)
        #except:
            #self.youtubesearchpagesimple(self.lastSong)
        
    @intent_file_handler('youtube-repeat.intent')
    def youtube_repeat_last(self):
        urlvideo = "http://www.youtube.com/watch?v={0}".format(self.lastSong)        
        video = self.yts.extract_video_meta(urlvideo)
        playurl = self.get_best_video_url(urlvideo)        
        self.gui["status"] = str("play")
        self.gui["video"] = str(playurl)
        self.gui["currenturl"] = ""
        self.gui["currenttitle"] = video.get('title')
        self.gui["setTitle"] = video.get('title')
        self.gui["viewCount"] = video.get('views')
        self.gui["publishedDate"] = self.build_upload_date_non_vui(video.get('published_time'))
        self.gui["videoAuthor"] = video.get('channel_name')
        self.gui["videoListBlob"] = ""
        self.gui["recentListBlob"] = ""
        self.gui["nextSongTitle"] = ""
        self.gui["nextSongImage"] = ""
        self.gui["nextSongID"] = ""
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)
        self.youtubesearchpagesimple(self.lastSong)
        self.isTitle = video.get('title')

    def build_category_list(self, category):
        LOG.info("Building For Category" + category)
        videoList = []
        yts = YoutubeSearcher()
        vidslist = yts.search_youtube(category, render="videos")
        for x in range(len(vidslist['videos'])):
            videoID = vidslist['videos'][x]['videoId']
            videoTitle = vidslist['videos'][x]['title']
            videoImage = vidslist['videos'][x]['thumbnails'][0]['url']
            vidImgFix = str(videoImage).split("?")[0]
            videoUploadDate = vidslist['videos'][x]['published_time']
            videoDuration = vidslist['videos'][x]['length']
            videoViews = vidslist['videos'][x]['views']
            videoChannel = vidslist['videos'][x]['channel_name']
            videoList.append({"videoID": videoID, "videoTitle": videoTitle, "videoImage": vidImgFix, "videoChannel": videoChannel, "videoViews": videoViews, "videoUploadDate": videoUploadDate, "videoDuration": videoDuration})
        
        return videoList
    
    def build_category_list_from_url(self, category):
        videoList = []
        yts = YoutubeSearcher()
        vidslist = yts.page_search(page_type=category)
        for x in range(len(vidslist['page_videos'])):
            videoID = vidslist['page_videos'][x]['videoId']
            videoTitle = vidslist['page_videos'][x]['title']
            videoImage = vidslist['page_videos'][x]['thumbnails'][0]['url']
            vidImgFix = str(videoImage).split("?")[0]
            videoUploadDate = vidslist['page_videos'][x]['published_time']
            videoDuration = vidslist['page_videos'][x]['length']
            videoViews = vidslist['page_videos'][x]['views']
            videoChannel = vidslist['page_videos'][x]['channel_name']
            videoList.append({"videoID": videoID, "videoTitle": videoTitle, "videoImage": vidImgFix, "videoChannel": videoChannel, "videoViews": videoViews, "videoUploadDate": videoUploadDate, "videoDuration": videoDuration})
        
        return videoList
    
    def clear_db(self):
        LOG.info("In DB Clear")
        self.recent_db.clear()
        self.recent_db.store()
        self.gui["recentListBlob"] = ""
        
    def buildHistoryModel(self, dictItem):
        LOG.info("In Build History Model")
        if 'recentList' in self.recent_db.keys():
            myCheck = self.checkIfHistoryItem(dictItem)
            if myCheck == True:
                LOG.info("In true")
                #LOG.info(dictItem)
                self.moveHistoryEntry(dictItem)
            elif myCheck == False:
                LOG.info("In false")
                #LOG.info(dictItem)
                self.addHistoryEntry(dictItem)
        
        else:
            recentListItem = []
            recentListItem.insert(0, dictItem)
            self.recent_db['recentList'] = recentListItem
            LOG.info("In Build History Recent Not Found Creating")
            self.recent_db.store()
            self.build_recent_watch_list(20)
            self.gui["recentHomeListBlob"] = self.recentWatchListObj

    def checkIfHistoryItem(self, dictItem):
        hasHistoryItem = False
        for dict_ in [x for x in self.recent_db['recentList'] if x["videoID"] == dictItem["videoID"]]:
            hasHistoryItem = True
        return hasHistoryItem

    def moveHistoryEntry(self, dictItem):
        res = [i for i in self.recent_db['recentList'] if not (i['videoID'] == dictItem["videoID"])]
        self.recent_db['recentList'] = res
        self.recent_db['recentList'].insert(0, dictItem)
        self.recent_db.store()
        self.build_recent_watch_list(20)
        self.gui["recentHomeListBlob"] = self.recentWatchListObj
        
    def addHistoryEntry(self, dictItem):
        self.recent_db['recentList'].insert(0, dictItem)
        self.recent_db.store()
        self.build_recent_watch_list(20)
        self.gui["recentHomeListBlob"] = self.recentWatchListObj

    def build_recent_watch_list(self, count):
        if 'recentList' in self.recent_db.keys():
            recentWatchListRaw = self.recent_db['recentList']
            recentWatchListModded = recentWatchListRaw[0:count]
            self.recentWatchListObj['recentList'] = recentWatchListModded
        else:
            emptyList = []
            self.recentWatchListObj['recentList'] = emptyList
            
    def build_upload_date(self, update):
        now = datetime.datetime.now() + datetime.timedelta(seconds = 60 * 3.4)
        date = dateutil.parser.parse(update)
        naive = date.replace(tzinfo=None)
        dtstring = timeago.format(naive, now)
        return dtstring
    
    def build_upload_date_non_vui(self, update):
        if update == "Live":
            return update
        else:
            now = datetime.datetime.now() + datetime.timedelta(seconds = 60 * 3.4)
            date = update
            naive = date.replace(tzinfo=None)
            dtstring = timeago.format(naive, now)
            return dtstring
    
    def add_view_string(self, viewcount):
        val = viewcount
        count = re.sub("(\d)(?=(\d{3})+(?!\d))", r"\1,", "%d" % val)
        views = count + " views"
        LOG.info(views)
        return views

    def process_soup_watchlist(self, html):
        videoList = []
        videoList.clear()
        soup = BeautifulSoup(html)
        currentVideoSection = soup.find('div', attrs={'class': 'watch-sidebar'})
        getVideoDetails = zip(currentVideoSection.findAll(attrs={'class': 'yt-uix-sessionlink'}), currentVideoSection.findAll(attrs={'class': 'attribution'}), currentVideoSection.findAll(attrs={'class': 'yt-uix-simple-thumb-wrap'}), currentVideoSection.findAll(attrs={'class': 'video-time'}), currentVideoSection.findAll(attrs={'class': 'view-count'}))
        for vid in getVideoDetails:
            if "googleads" not in vid[0]['href'] and not vid[0]['href'].startswith(
                u"/user") and not vid[0]['href'].startswith(u"/channel") and not vid[0]['href'].startswith('/news') and not vid[0]['href'].startswith('/music') and not vid[0]['href'].startswith('/technology') and not vid[0]['href'].startswith('/politics') and not vid[0]['href'].startswith('/gaming') and "title" in vid[0].attrs:
                videoID = vid[0]['href'].split("v=")[1].split("&")[0]
                videoTitle = vid[0]['title']
                videoImage = "https://i.ytimg.com/vi/{0}/hqdefault.jpg".format(videoID)
                videoChannel = vid[1].contents[0].string
                videoUploadDate = " "
                videoDuration = vid[3].contents[0].string
                videoViews = vid[4].text

                videoList.append({"videoID": videoID, "videoTitle": videoTitle, "videoImage": videoImage, "videoChannel": videoChannel, "videoViews": videoViews, "videoUploadDate": videoUploadDate, "videoDuration": videoDuration})

        return videoList


def create_skill():
    return YoutubeSkill()
