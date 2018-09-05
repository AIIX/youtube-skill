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
from firebase import firebase
from mycroft.skills.core import MycroftSkill
from mycroft.messagebus.message import Message

__author__ = 'augustnmonteiro'

firebase = firebase.FirebaseApplication(
    'https://youtubecontrol.firebaseio.com', None)
 
class YoutubeSkill(MycroftSkill):
    def __init__(self):
        super(YoutubeSkill, self).__init__(name="YoutubeSkill")
        self.process = None

    def initialize(self):
        self.load_data_files(dirname(__file__))

        youtube = IntentBuilder("YoutubeKeyword"). \
            require("YoutubeKeyword").build()
        self.register_intent(youtube, self.youtube)

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
        i = firebase.get('/i/' + self.settings.get("code"), None)
        if not i["connected"]:
            i["connected"] = True
            firebase.put('/i', self.settings.get("code"), i)
            self.speak("Connecting")
            time.sleep(2)

        self.speak("Playing")
        urlvideo = "http://www.youtube.com/watch?v={0}".format(vid)
        video = pafy.new(urlvideo)
        best = video.getbest()
        playurl = best.url
        self.enclosure.bus.emit(Message("metadata", {"type": "video", "title": "text", "video": str(playurl)}))

    def stop(self):
        if self.process:
            self.process.terminate()
            self.process.wait()
        pass


def create_skill():
    return YoutubeSkill()
