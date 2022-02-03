import bs4
import re
import json
import datetime
from .session.session import session

class YoutubeSearcher:
    def __init__(self, location_code=None, user_agent=None):
        if location_code:
            self.location_code = location_code
        else:
            self.location_code = "US"
        
        # TODO make compatibile with mobile user_agents
        if user_agent:
            self.user_agent = user_agent
        else:
            self.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.110 Safari/537.36"
        
        self.base_url = "https://www.youtube.com"
        self.headers = {
            'User-Agent': self.user_agent
        }
        self.featured_channel = {"videos": [], "playlists": []}
        self.data = {}
        self.videos = []
        self.playlists = []
        self.related_to_search = []
        self.related_queries = []
        self.radio = []
        self.movies = []
        self.promoted = []
        self.videos_on_page = []
        self.corrected_query = None
        self.contents = None
        self.primary_contents = None
        self.secondary_contents = None
        self.primary_contents_page = None
    
    def search_youtube(self, query, render="all"):
        self.featured_channel = {"videos": [], "playlists": []}
        self.data = {}
        self.videos = []
        self.playlists = []
        self.related_to_search = []
        self.related_queries = []
        self.radio = []
        self.movies = []
        self.promoted = []
        self.videos_on_page = []
        self.corrected_query = None
        self.contents = None
        self.primary_contents = None
        self.secondary_contents = None
        self.primary_contents_page = None

        params = {"search_query": query,
                  "gl": self.location_code}
        
        # TODO dont cache if no results found
        html = session.get(self.base_url + "/results", cookies={'CONSENT': 'YES+42'},
                           headers=self.headers, params=params).text
        soup = bs4.BeautifulSoup(html, 'html.parser')
        results = self.santize_soup_result(soup)
        data = {"query": query, "corrected_query": query}
        
        contents = results['contents']['twoColumnSearchResultsRenderer']

        content_checker = contents["primaryContents"]["sectionListRenderer"]["contents"][0]['itemSectionRenderer']['contents']
        if "shelfRenderer" in content_checker:
            self.primary_contents = contents["primaryContents"]["sectionListRenderer"]["contents"][0]['itemSectionRenderer']['contents'][0]['shelfRenderer']['content']['verticalListRenderer']['items']
        else:
            self.primary_contents = contents["primaryContents"]["sectionListRenderer"]["contents"][0]['itemSectionRenderer']['contents']

        self.contents = contents

        if render == "all":
            self.prepare_feature_channel_info()
            self.prepare_videos_info()
            self.prepare_playlistRender_info()
            self.prepare_horizontalCardList_info()
            self.prepare_radioRenderer_info()
            self.prepare_movieRenderer_info()
            self.prepare_carouselAdRenderer_info()
            self.prepare_autoCorrectedQuery_info()
            self.prepare_searchPyRenderer_info()
            self.filter_for_secondaryContents()
            
            self.data["videos"] = self.videos
            self.data["playlists"] = self.playlists
            self.data["featured_channel"] = self.featured_channel
            self.data["related_videos"] = self.related_to_search
            self.data["related_queries"] = self.related_queries
            self.data["full_movies"] = self.movies
            self.data["promoted"] = self.promoted
            
        if render == "featured": 
            self.prepare_feature_channel_info()
            self.prepare_videos_info()
            self.filter_for_secondaryContents()
            self.data["featured_channel"] = self.featured_channel
            
        if render == "videos":
            self.prepare_videos_info()
            self.data["videos"] = self.videos
            
        if render == "related":
            self.prepare_videos_info()
            self.prepare_horizontalCardList_info()
            self.data["related_videos"] = self.related_to_search
            self.data["related_queries"] = self.related_queries
        
        return self.data
    
    def page_search(self, page_type="trending"):
        params = {"gl": self.location_code}
        
        # TODO dont cache if no results found
        if page_type == "news":
            page = "news"
        elif page_type == "music":
            page = "music"
        elif page_type ==  "entertainment":
            page = "entertainment"
        else:
            page = "feed/trending"
        
        html = session.get(self.base_url + "/" + page, cookies={'CONSENT': 'YES+42'},
                           headers=self.headers, params=params).text
        soup = bs4.BeautifulSoup(html, 'html.parser')
        #print(soup)
        results = self.santize_soup_result(soup)
        
        contents = results['contents']['twoColumnBrowseResultsRenderer']
        self.primary_contents_page = contents['tabs'][0]['tabRenderer']['content'][
           'sectionListRenderer']['contents']
    
        if page == "feed/trending":
            self.prepare_pageTrending_info()
        else:
            self.prepare_pageRequested_info()
        
        self.data["page_videos"] = self.videos_on_page
        
        return self.data
    
    def watchlist_search(self, video_id=None):
        related_vids_on_page = []
        params = {"gl": self.location_code}
        base_url = "https://www.youtube.com/watch?v="
        html = session.get(base_url + video_id, cookies={'CONSENT': 'YES+42'},
                           headers=self.headers, params=params).text
        soup = bs4.BeautifulSoup(html, 'html.parser')
        results = self.santize_soup_result(soup)
        contents = results['contents']['twoColumnWatchNextResults']['secondaryResults']['secondaryResults']['results']
        for x in range(len(contents)):
            if "compactVideoRenderer" in contents[x]:
                vid = contents[x]["compactVideoRenderer"]
                thumb = vid["thumbnail"]['thumbnails']
                
                #Get video view count or live watch count
                if "simpleText" in vid["shortViewCountText"]:
                    views = vid["shortViewCountText"]["simpleText"]
                else:
                    views = vid["shortViewCountText"]["runs"][0]["text"] + " " +  vid["shortViewCountText"]["runs"][1]["text"]
                            
                #Get video published_time assume if not available video is Live
                if "publishedTimeText" in vid:
                    published_time = vid["publishedTimeText"]["simpleText"]
                else:
                    published_time = "Live"
                
                title = vid["title"]["simpleText"]
                
                if 'descriptionSnippet' in vid:
                    desc = " ".join([
                        r["text"] for r in vid['descriptionSnippet']["runs"]])
                else:  # ocasionally happens
                    desc = title
                
                #Length filter for live video
                if "lengthText" in vid:
                    length_caption = \
                        vid["lengthText"]['accessibility']["accessibilityData"][
                            "label"]
                    length_txt = vid["lengthText"]['simpleText']
                else:
                    length_caption = "Live"
                    length_txt = "Live"
                        
                if "longBylineText" in vid:
                    owner_txt = vid["longBylineText"]["runs"][0]["text"]
                        
                videoId = vid['videoId']
                url = \
                    vid['navigationEndpoint']['commandMetadata'][
                        'webCommandMetadata']['url']
                
                related_vids_on_page.append(
                    {
                        "url": base_url + vid['videoId'],
                        "title": title,
                        "length": length_txt,
                        "length_human": length_caption,
                        "views": views,
                        "published_time": published_time,
                        "videoId": videoId,
                        "thumbnails": thumb,
                        "description": desc,
                        "channel_name": owner_txt
                    }
                )
                    
        
        self.data["watchlist_videos"] = related_vids_on_page
        return self.data
                        
    def santize_soup_result(self, soup_blob):
        # Make sure we always get the correct blob and santize it
        blob = soup_blob.find('script', text=re.compile("ytInitialData"))
        #print(blob)
        json_data = str(blob)[str(blob).find('{\"responseContext\"'):str(blob).find('module={}')]
        json_data = re.split(r"\};", json_data)[0]
        #print(json_data)
        results = json.loads(json_data+"}")
        return results

    def prepare_feature_channel_info(self):
        # because order is not assured we need to make 2 passes over the data
        for vid in self.primary_contents:
            if 'channelRenderer' in vid:
                vid = vid['channelRenderer']
                user = \
                    vid['navigationEndpoint']['commandMetadata']['webCommandMetadata'][
                'url']
                
                self.featured_channel["title"] = vid["title"]["simpleText"]
                
                if 'descriptionSnippet' in vid:
                    d = [r["text"] for r in vid['descriptionSnippet']["runs"]]
                else:
                    d = vid["title"]["simpleText"].split(" ")
                
                self.featured_channel["description"] = " ".join(d)
                self.featured_channel["user_url"] = self.base_url + user
    
    def prepare_videos_info(self):
        for vid in self.primary_contents:
            if 'videoRenderer' in vid:
                vid = vid['videoRenderer']
                thumb = vid["thumbnail"]['thumbnails']
                
                if "shortViewCountText" in vid:
                #Get video view count or live watch count
                    if "simpleText" in vid["shortViewCountText"]:
                        views = vid["shortViewCountText"]["simpleText"]
                    else:
                        views = vid["shortViewCountText"]["runs"][0]["text"] + " " +  vid["shortViewCountText"]["runs"][1]["text"]
                else:
                    views = " "
                
                #Get video published_time assume if not available video is Live
                if "publishedTimeText" in vid:
                    published_time = vid["publishedTimeText"]["simpleText"]
                else:
                    published_time = "Live"
                    
                title = " ".join([r["text"] for r in vid['title']["runs"]])
                if 'descriptionSnippet' in vid:
                    desc = " ".join([
                        r["text"] for r in vid['descriptionSnippet']["runs"]])
                else:  # ocasionally happens
                    desc = title
                    
                #Length filter for live video
                if "lengthText" in vid:
                    length_caption = \
                        vid["lengthText"]['accessibility']["accessibilityData"][
                            "label"]
                    length_txt = vid["lengthText"]['simpleText']
                else:
                    length_caption = "Live"
                    length_txt = "Live"

                videoId = vid['videoId']
                url = \
                    vid['navigationEndpoint']['commandMetadata'][
                        'webCommandMetadata']['url']
                
                if "ownerText" in vid:
                    owner_txt = vid["ownerText"]["runs"][0]["text"]
                
                self.videos.append(
                    {
                        "url": self.base_url + url,
                        "title": title,
                        "length": length_txt,
                        "length_human": length_caption,
                        "views": views,
                        "published_time": published_time,
                        "videoId": videoId,
                        "thumbnails": thumb,
                        "description": desc,
                        "channel_name": owner_txt
                    }
                )
            elif 'shelfRenderer' in vid:
                entries = vid['shelfRenderer']
                #most recent from channel {title_from_step_above}
                #related to your search
                
                if "simpleText" in entries["title"]:
                    category = entries["title"]["simpleText"]
                else:
                    category = entries["title"]["runs"][0]["text"]
                
                #TODO category localization
                #this comes in lang from your ip address
                #not good to use as dict keys, can assumptions be made about
                #ordering and num of results? last item always seems to be
                #related artists and first (if any) featured channel
                ch = self.featured_channel.get("title", "")
                
                for vid in entries["content"]["verticalListRenderer"]['items']:
                    vid = vid['videoRenderer']
                    thumb = vid["thumbnail"]['thumbnails']
                    d = [r["text"] for r in vid['title']["runs"]]
                    title = " ".join(d)
                    
                    #Get video view count or live watch count
                    if "simpleText" in vid["shortViewCountText"]:
                        views = vid["viewCountText"]["simpleText"]
                    else:
                        views = vid["shortViewCountText"]["runs"][0]["text"] + " " +  vid["shortViewCountText"]["runs"][1]["text"]
                        
                    if "publishedTimeText" in vid:
                        published_time = vid["publishedTimeText"]["simpleText"]
                    else:
                        published_time = "Live"
                    
                    #Length filter for live video
                    if "lengthText" in vid:
                        length_caption = \
                            vid["lengthText"]['accessibility']["accessibilityData"][
                                "label"]
                        length_txt = vid["lengthText"]['simpleText']
                    else:
                        length_caption = "Live"
                        length_txt = "Live"
                    
                    if "ownerText" in vid:
                        owner_txt = vid["ownerText"]["runs"][0]["text"]

                    videoId = vid['videoId']
                    url = vid['navigationEndpoint']['commandMetadata'][
                        'webCommandMetadata']['url']
                    if ch and category.endswith(ch):
                        self.featured_channel["videos"].append(
                            {
                                "url": self.base_url + url,
                                "title": title,
                                "length": length_txt,
                                "length_human": length_caption,
                                "views": views,
                                "published_time": published_time,
                                "videoId": videoId,
                                "thumbnails": thumb,
                                "channel_name": owner_txt
                            }
                        )
                    else:
                        self.related_to_search.append(
                            {
                                "url": self.base_url + url,
                                "title": title,
                                "length": length_txt,
                                "length_human": length_caption,
                                "views": views,
                                "published_time": published_time,
                                "videoId": videoId,
                                "thumbnails": thumb,
                                "reason": category,
                                "channel_name": owner_txt
                            }
                        )

    def prepare_playlistRender_info(self):
        for vid in self.primary_contents:
            if 'playlistRenderer' in vid:
                vid = vid['playlistRenderer']
                playlist = {
                    "title": vid["title"]["simpleText"]
                }
                vid = vid['navigationEndpoint']
                playlist["url"] = \
                    self.base_url + vid['commandMetadata']['webCommandMetadata']['url']
                playlist["videoId"] = vid['watchEndpoint']['videoId']
                playlist["playlistId"] = vid['watchEndpoint']['playlistId']
                self.playlists.append(playlist)

    def prepare_horizontalCardList_info(self):
        for vid in self.primary_contents:
            if 'horizontalCardListRenderer' in vid:
                for vid in vid['horizontalCardListRenderer']['cards']:
                    vid = vid['searchRefinementCardRenderer']
                    url = \
                        vid['searchEndpoint']['commandMetadata'][
                            "webCommandMetadata"]["url"]
                    self.related_queries.append({
                        "title": vid['searchEndpoint']['searchEndpoint']["query"],
                        "url": self.base_url + url,
                        "thumbnails": vid["thumbnail"]['thumbnails']
                    })
    
    def prepare_radioRenderer_info(self):
        for vid in self.primary_contents:
            if 'radioRenderer' in vid:
                vid = vid['radioRenderer']
                title = vid["title"]["simpleText"]
                thumb = vid["thumbnail"]['thumbnails']
                vid = vid['navigationEndpoint']
                url = vid['commandMetadata']['webCommandMetadata']['url']
                videoId = vid['watchEndpoint']['videoId']
                playlistId = vid['watchEndpoint']['playlistId']
                self.radio.append({
                    "title": title,
                    "thumbnails": thumb,
                    "url": self.base_url + url,
                    "videoId": videoId,
                    "playlistId": playlistId
                })

    def prepare_movieRenderer_info(self):
        for vid in self.primary_contents:
            if 'movieRenderer' in vid:
                vid = vid['movieRenderer']
                title = " ".join([r["text"] for r in vid['title']["runs"]])
                thumb = vid["thumbnail"]['thumbnails']
                videoId = vid['videoId']
                meta = vid['bottomMetadataItems']
                meta = [m["simpleText"] for m in meta]
                desc = " ".join([r["text"] for r in vid['descriptionSnippet']["runs"]])
                url = vid['navigationEndpoint']['commandMetadata']['webCommandMetadata']['url']
                
                movies.append({
                    "title": title,
                    "thumbnails": thumb,
                    "url": self.base_url + url,
                    "videoId": videoId,
                    "metadata": meta,
                    "description": desc
                })

    def prepare_carouselAdRenderer_info(self):
        for vid in self.primary_contents:
            if 'carouselAdRenderer' in vid:
                vid = vid["carouselAdRenderer"]
                # skip ads
    
    def prepare_autoCorrectedQuery_info(self):
        for vid in self.primary_contents:
            if 'showingResultsForRenderer' in vid:
                q = vid['showingResultsForRenderer']['correctedQuery']
                self.corrected_query = " ".join([r["text"] for r in q["runs"]])

    def prepare_searchPyRenderer_info(self):
        for vid in self.primary_contents:
            if 'searchPyvRenderer' in vid:
                for entry in vid['searchPyvRenderer']['ads']:
                    entry = entry['promotedVideoRenderer']
                    desc = entry["description"]['simpleText']
                    title = entry['longBylineText']['runs'][0]["text"]
                    url = self.base_url + entry['longBylineText']['runs'][0][
                        'navigationEndpoint']['browseEndpoint']['canonicalBaseUrl']
                    self.promoted.append({
                        "title": title,
                        "description": desc,
                        "url": url
                    })

    def filter_for_secondaryContents(self):
        if self.contents.get("secondaryContents"):
            self.secondary_contents = \
                self.contents["secondaryContents"]["secondarySearchContainerRenderer"][
                    "contents"][0]["universalWatchCardRenderer"]
            self.prepare_secondaryContentsRender()
        

    def prepare_secondaryContentsRender(self):
            for vid in self.secondary_contents["sections"]:
                entries = vid['watchCardSectionSequenceRenderer']
                for entry in entries['lists']:
                    if 'verticalWatchCardListRenderer' in entry:
                        for vid in entry['verticalWatchCardListRenderer']["items"]:
                            vid = vid['watchCardCompactVideoRenderer']
                            thumbs = vid['thumbnail']['thumbnails']
                            
                            d = [r["text"] for r in vid['title']["runs"]]
                            title = " ".join(d)
                            url = vid['navigationEndpoint']['commandMetadata'][
                                'webCommandMetadata']['url']
                            videoId = vid['navigationEndpoint']['watchEndpoint'][
                                'videoId']
                            playlistId = \
                                vid['navigationEndpoint']['watchEndpoint']['playlistId']
                            length_caption = \
                                vid["lengthText"]['accessibility'][
                                    "accessibilityData"]["label"]
                            length_txt = vid["lengthText"]['simpleText']

                            #TODO investigate
                            #These seem to always be from featured channel
                            #playlistId doesnt match any extracted playlist
                            self.featured_channel["videos"].append({
                                "url": self.base_url + url,
                                "title": title,
                                "length": length_txt,
                                "length_human": length_caption,
                                "videoId": videoId,
                                "playlistId": playlistId,
                                "thumbnails": thumbs
                            })
                    elif 'horizontalCardListRenderer' in entry:
                        for vid in entry['horizontalCardListRenderer']['cards']:
                            vid = vid['searchRefinementCardRenderer']
                            playlistId = \
                                vid['searchEndpoint']['watchPlaylistEndpoint'][
                                    'playlistId']
                            thumbs = vid['thumbnail']['thumbnails']
                            url = vid['searchEndpoint']['commandMetadata'][
                                'webCommandMetadata']['url']
                            d = [r["text"] for r in vid['query']["runs"]]
                            title = " ".join(d)
                            self.featured_channel["playlists"].append({
                                "url": self.base_url + url,
                                "title": title,
                                "thumbnails": thumbs,
                                "playlistId": playlistId
                            })

    def prepare_pageTrending_info(self):
        for items in self.primary_contents_page:
            if 'itemSectionRenderer' in items:
                i_items = items['itemSectionRenderer']['contents'][0]['shelfRenderer']['content']
                if 'expandedShelfContentsRenderer' in i_items:
                    page_items = items['itemSectionRenderer']['contents'][0]['shelfRenderer']['content']['expandedShelfContentsRenderer']['items']
                else:
                    page_items = []

                for x in range(len(page_items)):
                    if 'videoRenderer' in page_items[x]:
                        vid = page_items[x]['videoRenderer']
                        thumb = vid["thumbnail"]['thumbnails']
                        
                        #Get video view count or live watch count
                        try:
                            if "simpleText" in vid["shortViewCountText"]:
                                views = vid["shortViewCountText"]["simpleText"]
                            else:
                                views = vid["shortViewCountText"]["runs"][0]["text"] + " " +  vid["shortViewCountText"]["runs"][1]["text"]
                        except:
                            views = "Live"
                            
                        #Get video published_time assume if not available video is Live
                        try:
                            if "publishedTimeText" in vid:
                                published_time = vid["publishedTimeText"]["simpleText"]
                            else:
                                published_time = "Live"
                        except:
                            published_time = "Now Streaming"
                        
                        title = " ".join([r["text"] for r in vid['title']["runs"]])
                        
                        if 'descriptionSnippet' in vid:
                            desc = " ".join([
                                r["text"] for r in vid['descriptionSnippet']["runs"]])
                        else:  # ocasionally happens
                            desc = title
                        
                        #Length filter for live video
                        if "lengthText" in vid:
                            length_caption = \
                                vid["lengthText"]['accessibility']["accessibilityData"][
                                    "label"]
                            length_txt = vid["lengthText"]['simpleText']
                        else:
                            length_caption = "Live"
                            length_txt = "Live"
                        
                        if "ownerText" in vid:
                            owner_txt = vid["ownerText"]["runs"][0]["text"]
                        
                        videoId = vid['videoId']
                        url = \
                            vid['navigationEndpoint']['commandMetadata'][
                                'webCommandMetadata']['url']
                        self.videos_on_page.append(
                            {
                                "url": self.base_url + url,
                                "title": title,
                                "length": length_txt,
                                "length_human": length_caption,
                                "views": views,
                                "published_time": published_time,
                                "videoId": videoId,
                                "thumbnails": thumb,
                                "description": desc,
                                "channel_name": owner_txt
                            }
                        )

    def prepare_pageRequested_info(self):
        for items in self.primary_contents_page:
            if 'itemSectionRenderer' in items:
                page_items = items['itemSectionRenderer']['contents'][0]['shelfRenderer']['content']['horizontalListRenderer']['items']
                for x in range(len(page_items)):
                    if 'gridVideoRenderer' in page_items[x]:
                        vid = page_items[x]['gridVideoRenderer']
                        thumb = vid["thumbnail"]['thumbnails']
                        
                        #Get video view count or live watch count
                        if "shortViewCountText" in vid:
                            if "simpleText" in vid["shortViewCountText"]:
                                views = vid["shortViewCountText"]["simpleText"]
                            else:
                                views = vid["shortViewCountText"]["runs"][0]["text"] + " " +  vid["shortViewCountText"]["runs"][1]["text"]
                        else:
                            views = "unavailable"
                            
                        #Get video published_time assume if not available video is Live
                        if "publishedTimeText" in vid:
                            published_time = vid["publishedTimeText"]["simpleText"]
                        else:
                            published_time = "Live"
                        
                        #title = " ".join([r["text"] for r in vid['title']["runs"]])
                        title = vid['title']['simpleText']
                        
                        if 'descriptionSnippet' in vid:
                            desc = " ".join([
                                r["text"] for r in vid['descriptionSnippet']["runs"]])
                        else:  # ocasionally happens
                            desc = title
                        
                        #Length filter for live video
                        overlayInformation = vid['thumbnailOverlays'][0]
                        if "thumbnailOverlayTimeStatusRenderer" in overlayInformation:
                            length_caption = \
                                overlayInformation['thumbnailOverlayTimeStatusRenderer']['text']['accessibility']["accessibilityData"][
                                    "label"]
                            length_txt = overlayInformation['thumbnailOverlayTimeStatusRenderer']['text']['simpleText']
                        else:
                            length_caption = "Live"
                            length_txt = "Live"
                        
                        videoId = vid['videoId']
                        url = \
                            vid['navigationEndpoint']['commandMetadata'][
                                'webCommandMetadata']['url']
                        self.videos_on_page.append(
                            {
                                "url": self.base_url + url,
                                "title": title,
                                "length": length_txt,
                                "length_human": length_caption,
                                "views": views,
                                "published_time": published_time,
                                "videoId": videoId,
                                "thumbnails": thumb,
                                "description": desc
                            }
                        )

    def extract_video_meta(self, url):
        params = {"gl": "US"}
        html = session.get(url, cookies={'CONSENT': 'YES+42'},
                           headers=self.headers, params=params).text
        soup = bs4.BeautifulSoup(html, 'html.parser')
        results = self.santize_soup_result(soup)
        contents = results['contents']['twoColumnWatchNextResults']['results']['results']['contents'][0]['videoPrimaryInfoRenderer']
        secondaryContents = results['contents']['twoColumnWatchNextResults']['results']['results']['contents'][1]['videoSecondaryInfoRenderer']
        title = contents['title']['runs'][0]['text']
        try:
            viewCount = contents['viewCount']['videoViewCountRenderer']['viewCount']['simpleText']
        except:
            viewCount = "Live"
        author = secondaryContents['owner']['videoOwnerRenderer']['title']['runs'][0]['text']
        try:
            actualDate = contents['dateText']['simpleText'] + "  12:00AM"
            publishedDate = datetime.datetime.strptime(actualDate, '%d %b %Y %I:%M%p')
        except:
            publishedDate = "Live"
        
        vidmetadata = {
            "title": title,
            "views": viewCount,
            "published_time": publishedDate,
            "channel_name": author
        }
        return vidmetadata
