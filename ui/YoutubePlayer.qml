import QtMultimedia 5.9
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

    //graceTime: Infinity

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
    
    //back Key Button Handle
    Keys.onShiftPressed: {
        console.log(parent.currentIndex)
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
    
    Kirigami.Heading {
        id: vidTitle
        level: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Kirigami.Units.largeSpacing
        height: Kirigami.Units.gridUnit * 2
        visible: true
        text: videoTitle
        z: 100
    }

    Image {
        id: thumbart
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: root.videoThumb 
        enabled: root.videoStatus == "stop" ? 1 : 0
        visible: root.videoStatus == "stop" ? 1 : 0
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
                        vidTitle.visible = false;
                    })
                    break;
            }
        }
                
        Keys.onDownPressed: {
            controlBarItem.opened = true
            controlBarItem.forceActiveFocus()
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: controlBarItem.opened = !controlBarItem.opened
        }
    }
}
