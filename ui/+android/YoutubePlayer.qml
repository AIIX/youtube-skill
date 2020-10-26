import QtMultimedia 5.12
import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.12 as Controls
import org.kde.kirigami 2.10 as Kirigami
import QtGraphicalEffects 1.0

import Mycroft 1.0 as Mycroft

import "." as Local

Mycroft.Delegate {
    id: root

    property var videoSource: sessionData.video
    property var videoStatus: sessionData.status
    property var videoThumb: sessionData.videoThumb
    property var videoTitle: sessionData.setTitle
    property var videoAuthor: sessionData.videoAuthor
    property var videoViewCount: sessionData.viewCount
    property var videoPublishDate: sessionData.publishedDate
    property var videoListModel: sessionData.videoListBlob.videoList
    property var nextSongBlob: sessionData.nextSongBlob

    //The player is always fullscreen
    fillWidth: true
    background: Rectangle {
        color: "black"
    }
    leftPadding: 0
    topPadding: 0
    rightPadding: 0
    bottomPadding: 0

    onEnabledChanged: syncStatusTimer.restart()
    onVideoSourceChanged: syncStatusTimer.restart()
    Component.onCompleted: {
        syncStatusTimer.restart()
    }
    
    Keys.onDownPressed: {
        controlBarItem.opened = true
        controlBarItem.forceActiveFocus()
    }
        
    onVideoTitleChanged: {
        triggerGuiEvent("YoutubeSkill.RefreshWatchList", {"title": videoTitle})
        if(videoTitle != ""){
            infomationBar.visible = true
        }
    }
    
    onFocusChanged: {
        console.log("here")
        if(focus && suggestions.visible){
            console.log("in suggestFocus 1")
            suggestions.forceActiveFocus();
        } else if(focus && !suggestions.visbile) {
            video.forceActiveFocus();
        }
    }
    
    Connections {
        target: window
        onVisibleChanged: {
            if(video.playbackState == MediaPlayer.PlayingState) {
                video.stop()
            }
        }
    }
    
    function getViewCount(value){
        return value.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,')
    }
    
    function setPublishedDate(publishDate){
        var date1 = new Date(publishDate).getTime();
        var date2 = new Date().getTime();
        console.log(date1)
        console.log(date2)
        
        var msec = date2 - date1;
        var mins = Math.floor(msec / 60000);
        var hrs = Math.floor(mins / 60);
        var days = Math.floor(hrs / 24);
        var yrs = Math.floor(days / 365);
        mins = mins % 60;
        hrs = hrs % 24;
        days = days % 365;
        var result = "Published: " + days + " days, " + hrs + " hours, " + mins + " minutes ago"
        return result
    }

    function listProperty(item){
        for (var p in item)
        {
            if( typeof item[p] != "function" )
                if(p != "objectName")
                    console.log(p + ":" + item[p]);
        }
    }
    
    // Sometimes can't be restarted reliably immediately, put it in a timer
    Timer {
        id: syncStatusTimer
        interval: 0
        onTriggered: {
            if (enabled && videoStatus == "play") {
                video.play();
            } else if (videoStatus == "stop") {
                video.stop();
            } else {
                video.pause();
            }
        }
    }
    
    Timer {
        id: delaytimer
    }

    function delay(delayTime, cb) {
            delaytimer.interval = delayTime;
            delaytimer.repeat = false;
            delaytimer.triggered.connect(cb);
            delaytimer.start();
    }
    
    controlBar: Local.SeekControl {
        id: seekControl
        anchors {
//             left: parent.left
//             right: parent.right
            bottom: parent.bottom
        }
        title: videoTitle  
        videoControl: video
        duration: video.duration
        playPosition: video.position
        onSeekPositionChanged: video.seek(seekPosition);
        z: 1000
    }
    
    Item {
        id: videoRoot
        anchors.fill: parent 
            
         Rectangle { 
            id: infomationBar 
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            visible: false
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
            implicitHeight: vidTitle.implicitHeight + Kirigami.Units.largeSpacing * 2
            z: 1001
            
            onVisibleChanged: {
                delay(15000, function() {
                    infomationBar.visible = false;
                })
            }
            
            Controls.Label {
                id: vidTitle
                visible: true
                maximumLineCount: 2
                wrapMode: Text.Wrap
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.verticalCenter: parent.verticalCenter
                text: videoTitle
                z: 100
            }
         }
            
        Image {
            id: thumbart
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: root.videoThumb 
            enabled: root.videoStatus == "stop" ? 1 : 0
            visible: root.videoStatus == "stop" ? 1 : 0
        }
        
        SuggestionArea {
            id: suggestions
            visible: false
            videoSuggestionList: videoListModel
            nxtSongBlob: nextSongBlob
            onVisibleChanged: {
                if(visible) {
                    suggestionListFocus = true
                } else {
                    video.focus = true
                }
            }
        }
        
        Video {
            id: video
            anchors.fill: parent
            focus: true
            autoLoad: true
            autoPlay: false
            Keys.onSpacePressed: video.playbackState == MediaPlayer.PlayingState ? video.pause() : video.play()
            KeyNavigation.up: closeButton
            //Keys.onLeftPressed: video.seek(video.position - 5000)
            //Keys.onRightPressed: video.seek(video.position + 5000)
            source: videoSource
            readonly property string currentStatus: root.enabled ? root.videoStatus : "pause"
            
            onFocusChanged: {
                if(focus){
                    console.log("focus in video")
                    if(suggestions.visbile){
                        console.log("in suggestFocus 2")
                        suggestions.forceActiveFocus();
                    }
                }
            }

            onCurrentStatusChanged: {print("OOO"+currentStatus)
                switch(currentStatus){
                    case "stop":
                        video.stop();
                        break;
                    case "pause":
                        video.pause()
                        break;
                    case "play":
                        video.play()
                        delay(6000, function() {
                            infomationBar.visible = false;
                        })
                        break;
                }
            }
            
            Keys.onReturnPressed: {
                video.playbackState == MediaPlayer.PlayingState ? video.pause() : video.play()
            }
                    
            Keys.onDownPressed: {
                controlBarItem.opened = true
                controlBarItem.forceActiveFocus()
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: { 
                    controlBarItem.opened = !controlBarItem.opened 
                }
            }
            
            onStatusChanged: {
                if(status == MediaPlayer.EndOfMedia) {
                    triggerGuiEvent("YoutubeSkill.NextAutoPlaySong", {})
                    suggestions.visible = true
                } else {
                    suggestions.visible = false
                }
            }
        }
    }
}
