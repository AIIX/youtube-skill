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

    background: Rectangle {
        color: "black"
    }

    onEnabledChanged: {
        if (enabled && status == "play") {
            player.play();
        } else {
            player.pause();
        }
    }
    Component.onCompleted: {
        if (enabled && status == "play") {
            player.play();
        } else if (status == "stop") {
            player.stop();
        } else {
            player.pause();
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
    }

    Video {
        id: video
        anchors.fill: parent
        focus: true
        autoPlay: true
        Keys.onSpacePressed: video.playbackState == MediaPlayer.PlayingState ? video.pause() : video.play()
        Keys.onLeftPressed: video.seek(video.position - 5000)
        Keys.onRightPressed: video.seek(video.position + 5000)
        source: videoSource
        readonly property string currentStatus: root.enabled ? root.videoStatus : "pause"

        onCurrentStatusChanged: {
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
