import QtAV 1.7
import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0

import Mycroft 1.0 as Mycroft

import "." as Local

Mycroft.Delegate {
    id: root

    property var videoSource: sessionData.video
    property var videoStatus: sessionData.status
    property var videoThumb: sessionData.videoThumb
    property var videoTitle: sessionData.currenttitle
    property var videoAuthor: sessionData.videoAuthor
    property var videoViewCount: sessionData.viewCount
    property var videoPublishDate: sessionData.publishedDate
    property var videoListModel: sessionData.videoListBlob.videoList
    
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
    Component.onCompleted: syncStatusTimer.restart()
    
    Keys.onShiftPressed: {
        console.log(parent.currentIndex)
    }
    
    function getViewCount(value){
        return value.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,')
    }
    
    function setPublishedDate(publishDate){
        if(publishDate){
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
        } else {
            return ""
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
            left: parent.left
            right: parent.right
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
        focus: true
        
        Rectangle { 
            id: infomationBar 
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
            implicitHeight: infoLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
            z: 1001
            
            onVisibleChanged: {
                delay(15000, function() {
                    infomationBar.visible = false;
                })
            }
            
            RowLayout {
                id: infoLayout
                anchors.fill: parent
                
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    
                    Kirigami.Heading {
                        id: vidTitle
                        level: 2
                        height: Kirigami.Units.gridUnit * 2
                        visible: true
                        text: "Title: " + videoTitle
                        z: 100
                    }
                    
                    Kirigami.Heading {
                        id: vidAuthor
                        level: 2
                        height: Kirigami.Units.gridUnit * 2
                        visible: true
                        text: "Published By: " + videoAuthor
                        z: 100
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    
                    Kirigami.Heading {
                        id: vidCount
                        level: 2
                        height: Kirigami.Units.gridUnit * 2
                        visible: true
                        text: "Views: " + getViewCount(videoViewCount)
                        z: 100
                    }
                    
                    Kirigami.Heading {
                        id: vidPublishDate
                        level: 2
                            height: Kirigami.Units.gridUnit * 2
                        visible: true
                        text: setPublishedDate(videoPublishDate)
                        z: 100
                    }
                }
            }
        }
        
        SuggestionArea {
            id: suggestArea
            videoSuggestionList: sessionData.videoListBlob.videoList
            z: 2000
            visible: false
        }
        
        Image {
            id: thumbart
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: root.videoThumb 
            enabled: root.videoStatus == "stop" ? 1 : 0
            visible: root.videoStatus == "stop" ? 1 : 0
        }
        
        VideoOutput2 {
            opengl: true
            fillMode: VideoOutput.PreserveAspectFit
            source: video
            anchors.fill: parent
        }

        AVPlayer {
            id: video
            autoLoad: true
            autoPlay: false
            source: videoSource
            videoCodecPriority: ["FFmpeg", "VAAPI"]

            readonly property string currentStatus: root.enabled ? root.videoStatus : "pause"

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
                    delay(15000, function() {
                        infomationBar.visible = false;
                    })
                    break;
                }
            }
        }
        
        KeyNavigation.up: closeButton
        Keys.onSpacePressed: { 
            video.playbackState == MediaPlayer.PlayingState ? video.pause() : video.play()
            infomationBar.visible = true
        }
        Keys.onDownPressed: {
            controlBarItem.opened = true
            controlBarItem.forceActiveFocus()
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                infomationBar.visible = true;
                controlBarItem.opened = !controlBarItem.opened 
            }
        }
    }
}
