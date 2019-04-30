import QtMultimedia 5.9
import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.4 as Kirigami
import QtGraphicalEffects 1.0

import Mycroft 1.0 as Mycroft

import "." as Local

Mycroft.Delegate {
    id: root

    property var videoSource: sessionData.video
    property var videoStatus: sessionData.status

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
    controlBar: Local.SeekControl {
        id: seekControl
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        videoControl: video
        duration: video.duration
        playPosition: video.position
        onSeekPositionChanged: video.seek(seekPosition);
        z: 1000
    }

    Video {
        id: video
        anchors.fill: parent
        focus: true
        autoLoad: true
        autoPlay: false
        Keys.onSpacePressed: video.playbackState == MediaPlayer.PlayingState ? video.pause() : video.play()
        Keys.onLeftPressed: video.seek(video.position - 5000)
        Keys.onRightPressed: video.seek(video.position + 5000)
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
                    break;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: controlBarItem.opened = !controlBarItem.opened
        }
    }
}
