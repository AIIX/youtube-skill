import QtMultimedia 5.12
import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.12 as Controls
import org.kde.kirigami 2.10 as Kirigami
import QtQuick.Templates 2.2 as Templates
import QtGraphicalEffects 1.0

import Mycroft 1.0 as Mycroft

Item {
    id: seekControl
    property bool opened: false
    property int duration: 0
    property int playPosition: 0
    property int seekPosition: 0
    property bool enabled: true
    property bool seeking: false
    property var videoControl
    property string title

    clip: true
    implicitWidth: parent.width
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
    
    onFocusChanged: {
        if(focus) {
            backButton.forceActiveFocus()
        }
    }

    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: { 
            seekControl.opened = false;
            videoRoot.forceActiveFocus();
        }
    }
    
    Rectangle {
        width: parent.width
        height: parent.height
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
        //color: "white"
        y: opened ? 0 : parent.height

        Behavior on y {
            YAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
        
        ColumnLayout {
            id: mainLayout
            
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            
            RowLayout {
                id: mainLayout2
                Layout.fillHeight: true
                Controls.RoundButton {
                    id: backButton                        
                    height: Kirigami.Units.gridUnit * 2
                    Layout.preferredWidth: parent.width > 600 ? Kirigami.Units.iconSizes.large : Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Layout.preferredWidth
                    highlighted: focus ? 1 : 0
                    icon.name: "go-previous-symbolic"
                    z: 1000
                    onClicked: {
                        Mycroft.MycroftController.sendRequest("mycroft.gui.screen.close", {});
                        video.stop();
                    }
                    KeyNavigation.up: video
                    KeyNavigation.right: button
                    Keys.onReturnPressed: {
                        hideTimer.restart();
                        Mycroft.MycroftController.sendRequest("mycroft.gui.screen.close", {});
                        video.stop(); 
                    }
                    onFocusChanged: {
                        hideTimer.restart();
                    }
                }
                Controls.RoundButton {
                    id: button
                    Layout.preferredWidth: parent.width > 600 ? Kirigami.Units.iconSizes.large : Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Layout.preferredWidth
                    highlighted: focus ? 1 : 0
                    icon.name: videoControl.playbackState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                    z: 1000
                    onClicked: {
                        video.playbackState === MediaPlayer.PlayingState ? video.pause() : video.play();
                        hideTimer.restart();
                    }
                    KeyNavigation.up: video
                    KeyNavigation.left: backButton
                    KeyNavigation.right: slider
                    Keys.onReturnPressed: {
                        video.playbackState === MediaPlayer.PlayingState ? video.pause() : video.play();
                        hideTimer.restart();
                    }
                    onFocusChanged: {
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
                    property bool navSliderItem
                    property int minimumValue: 0
                    property int maximumValue: 20
                    onMoved: {
                        seekControl.seekPosition = value;
                        hideTimer.restart();
                    }
                    
                    onNavSliderItemChanged: {
                        if(slider.navSliderItem){
                            recthandler.color = "red"
                        } else if (slider.focus) {
                            recthandler.color = Kirigami.Theme.linkColor
                        }
                    }
                    
                    onFocusChanged: {
                        if(!slider.focus){
                            recthandler.color = Kirigami.Theme.textColor
                        } else {
                            recthandler.color = Kirigami.Theme.linkColor
                        }
                    }
                    
                    handle: Rectangle {
                        id: recthandler
                        x: slider.position * (parent.width - width)
                        implicitWidth: Kirigami.Units.gridUnit
                        implicitHeight: implicitWidth
                        radius: width
                        color: Kirigami.Theme.textColor
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
                KeyNavigation.up: video
                KeyNavigation.left: button
                Keys.onReturnPressed: {
                    hideTimer.restart();
                    if(!navSliderItem){
                            navSliderItem = true   
                        } else {
                            navSliderItem = false
                        }
                    }
                
                Keys.onLeftPressed: {
                        console.log("leftPressedonSlider")
                        hideTimer.restart();
                        if(navSliderItem) {
                            video.seek(video.position - 5000)
                        } else {
                            button.forceActiveFocus()
                        }
                }
                
                Keys.onRightPressed: {
                        hideTimer.restart();
                        if(navSliderItem) {
                            video.seek(video.position + 5000)
                        }
                    }
                }
                
                Controls.RoundButton {
                    id: infoButton                        
                    height: Kirigami.Units.gridUnit * 2
                    Layout.preferredWidth: parent.width > 600 ? Kirigami.Units.iconSizes.large : Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Layout.preferredWidth
                    highlighted: focus ? 1 : 0
                    icon.name: "documentinfo"
                    z: 1000
                    onClicked: {
                        videoInformationPop.open()
                        hideTimer.restart();
                    }
                    KeyNavigation.up: video
                    KeyNavigation.left: slider
                    Keys.onReturnPressed: {
                        clicked()
                    }
                    onFocusChanged: {
                        hideTimer.restart();
                    }
                }
            }
        }
    }
    
    Controls.Popup {
        id: videoInformationPop
        width: parent.width - Kirigami.Units.gridUnit * 4
        height: width
        parent: root
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        dim: true
        
        background: Rectangle {
            color: Qt.rgba(0,0,0,0.8)
        }
        
        contentItem: Item {
            ColumnLayout {
                id: informationColumn
                width: parent.width
                spacing: Kirigami.Units.largeSpacing
                
                Controls.Label {
                    id: vidTitle
                    visible: true
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    Layout.maximumWidth: parent.width
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    text: "Title: " + videoTitle
                    z: 100
                }
                
                Controls.Label {
                    id: vidAuthor
                    visible: true
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    Layout.maximumWidth: parent.width
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    text: "Published By: " + videoAuthor
                    z: 100
                }
                
                Controls.Label {
                    id: vidCount
                    visible: true
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    Layout.maximumWidth: parent.width
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    text: "Views: " + getViewCount(videoViewCount)
                    z: 100
                }
                
                Controls.Label {
                    id: vidPublishDate
                    visible: true
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    Layout.maximumWidth: parent.width
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    text: setPublishedDate(videoPublishDate)
                    z: 100
                }
            }
            
            Controls.Button {
                id: closeInformationBarButton
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height * 0.15
                text: "Close"
                icon.name: "dialog-close"
                onClicked: {
                    videoInformationPop.close()
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
