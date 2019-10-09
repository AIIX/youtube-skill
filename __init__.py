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
    from urllib.parse import quote, urlencode
from adapt.intent import IntentBuilder
from bs4 import BeautifulSoup, SoupStrainer
from mycroft.skills.core import MycroftSkill, intent_handler, intent_file_handler
from mycroft.messagebus.message import Message
from mycroft.util.log import LOG

__author__ = 'aix'

class YoutubeSkill(MycroftSkill):
    def __init__(self):
        super(YoutubeSkill, self).__init__(name="YoutubeSkill")
        self.process = None
        self.nextpage_url = None
        self.previouspage_url = None
        self.live_category = None

    def initialize(self):
        self.load_data_files(dirname(__file__))

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
        
    def launcherId(self, message):
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

    def searchLive(self, message):
        videoList = []
        videoList.clear()
        videoPageObject = {}
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
        self.gui["videoThumb"] = ""
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True) 
        rfind = soup.findAll(attrs={'class': 'yt-uix-tile-link'})
        vid = str(rfind[0].attrs['href'])
        veid = "https://www.youtube.com{0}".format(vid)
        getvid = vid.split("v=")[1].split("&")[0]
        thumb = "https://img.youtube.com/vi/{0}/maxresdefault.jpg".format(getvid)
        self.gui["videoThumb"] = thumb
        video = pafy.new(veid)
        playstream = video.streams[0]
        playurl = playstream.url
        self.gui["video"] = str(playurl)
        self.gui["status"] = str("play")
        self.gui["currenturl"] = str(vid)
        self.gui["currenttitle"] = ""
        self.gui["videoListBlob"] = ""
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)
        self.gui["currenttitle"] = self.getTitle(utterance)
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
        self.gui["videoListBlob"] = videoPageObject
        self.gui.show_page("YoutubeSearch.qml")
        
    def youtubesearchpagesimple(self, query):
        videoList = []
        videoList.clear()
        videoPageObject = {}
        vid = self.getListSearch(query)
        url = "https://www.youtube.com/results?search_query=" + vid
        response = urlopen(url)
        html = response.read()
        videoList = self.process_soup(html)        
        videoPageObject['videoList'] = videoList
        self.gui["videoListBlob"] = videoPageObject
        
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
        videoTitleSearch = str(message.data['vidTitle']).join(str(message.data['vidTitle']).split()[:-1])
        self.youtubesearchpagesimple(videoTitleSearch)
        self.gui.show_pages(["YoutubePlayer.qml", "YoutubeSearch.qml"], 0, override_idle=True)

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
        return videoList
    
    def process_additional_pages(self, htmltype):
        soup = BeautifulSoup(htmltype)
        buttons = soup.findAll('a',attrs={'class':"yt-uix-button vve-check yt-uix-sessionlink yt-uix-button-default yt-uix-button-size-default"})
        return buttons
    
def create_skill():
    return YoutubeSkill()
