import QtQuick 2.4
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as Controls
import QtQuick.Templates 2.2 as Templates
import QtGraphicalEffects 1.0
import QtMultimedia 5.9
import org.kde.kirigami 2.4 as Kirigami
import Mycroft 1.0 as Mycroft

Item {
    id: seekControl
    property bool opened: false
    property int duration: 0
    property int playPosition: 0
    property int seekPosition: 0
    property bool enabled: true
    property bool seeking: false
    property Video videoControl

    clip: true
    implicitHeight: mainLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
    opacity: opened

    Behavior on opacity {
        OpacityAnimator {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutCubic
        }
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: seekControl.opened = false;
    }
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
        }
        height: parent.height
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
        y: opened ? 0 : parent.height

        Behavior on y {
            YAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            id: mainLayout
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            Controls.RoundButton {
                id: backButton
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Layout.preferredWidth
                icon.name: "go-previous-symbolic"
                z: 1000
                onClicked: {
                    Mycroft.MycroftController.sendRequest("mycroft.gui.screen.close", {});
                    video.stop();
                }
            }
            Controls.RoundButton {
                id: button
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Layout.preferredWidth
                icon.name: videoControl.playbackState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                z: 1000
                onClicked: {
                    video.playbackState === MediaPlayer.PlayingState ? video.pause() : video.play();
                    hideTimer.restart();
                }
            }

            Templates.Slider {
                id: slider
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: Kirigami.Units.gridUnit
                value: seekControl.playPosition
                from: 0
                to: seekControl.duration
                z: 1000
                onMoved: {
                    seekControl.seekPosition = value;
                    hideTimer.restart();
                }
                handle: Rectangle {
                    x: slider.position * (parent.width - width)
                    implicitWidth: Kirigami.Units.gridUnit
                    implicitHeight: implicitWidth
                    radius: width
                }
                background: Item {
                    Rectangle {
                        id: groove
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                        }
                        radius: height
                        height: Math.round(Kirigami.Units.gridUnit/3)
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            radius: height
                            color: Kirigami.Theme.highlightColor
                            width: slider.position * (parent.width - slider.handle.width/2) + slider.handle.width/2
                        }
                    }

                    Controls.Label {
                        anchors {
                            left: parent.left
                            top: groove.bottom
                            topMargin: Kirigami.Units.smallSpacing
                        }
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        text: formatTime(playPosition)
                        color: "white"
                    }

                    Controls.Label {
                        anchors {
                            right: parent.right
                            top: groove.bottom
                            topMargin: Kirigami.Units.smallSpacing
                        }
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        text: formatTime(duration)
                    }
                }
            }
        }
    }

    function formatTime(timeInMs) {
        if (!timeInMs || timeInMs <= 0) return "0:00"
        var seconds = timeInMs / 1000;
        var minutes = Math.floor(seconds / 60)
        seconds = Math.floor(seconds % 60)
        if (seconds < 10) seconds = "0" + seconds;
        return minutes + ":" + seconds
    }
}
