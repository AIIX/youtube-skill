import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft
import "+mediacenter/views" as Views
import "+mediacenter/delegates" as Delegates
import org.kde.mycroft.bigscreen 1.0 as BigScreen

Controls.Popup {
    id: suggestionBox
    property var nxtSongBlob
    property int countdownSeconds: 15
    property int seconds: countdownSeconds
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    
    onVisibleChanged: {
        if(visible) {
            autoPlayTimer.start()
            replayButton.forceActiveFocus()
        } else {
            autoPlayTimer.stop()
            root.forceActiveFocus()
        }
    }
    
    onClosed: {
        root.forceActiveFocus()
    }
    
    onOpened: {
        replayButton.forceActiveFocus()
    }
    
    onNxtSongBlobChanged: {
        nextSongCdBar.imageSource = nxtSongBlob.videoImage
        nextSongCdBar.nextSongTitle = nxtSongBlob.videoTitle
    }
        
    Timer {
        id: autoPlayTimer
        interval: 1000
        repeat: true
        onTriggered: {
            suggestionBox.seconds--;
            autoplayTimeHeading.text = "Playing In: " + suggestionBox.seconds
            if(suggestionBox.seconds == 0) {
                running = false;
                suggestionBox.seconds = suggestionBox.countdownSeconds
                Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: nxtSongBlob.videoID, vidTitle: nxtSongBlob.videoTitle, vidImage: nxtSongBlob.videoImage, vidChannel: nxtSongBlob.videoChannel, vidViews: nxtSongBlob.videoViews, vidUploadDate: nxtSongBlob.videoUploadDate, vidDuration: nxtSongBlob.videoDuration})
            }
        }
    }
    
    background: Rectangle {
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.5)
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 2
            verticalOffset: 2
        }
    }
            
    contentItem: Item {
        
        Controls.Label {
            id: headerAreaSuggestPg
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            text: "Press 'esc' or the [←] Back button to close"
            Layout.alignment: Qt.AlignRight
        }
            
        Kirigami.Separator {
            id: headrSeptBml
            anchors.top: headerAreaSuggestPg.bottom
            width: parent.width
            height: 1
        }
        
        Item {
            anchors {
                left: parent.left
                right: parent.right
                top: headrSeptBml.bottom
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.largeSpacing
                bottom: btnAreaSuggestions.top
            }
            
            Views.CountdownBar {
                id: nextSongCdBar
                anchors.left: parent.left
                width: parent.width / 2
                height: parent.height
            }
            
            Kirigami.Heading {
                id: autoplayTimeHeading
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                width: parent.width / 2
                height: parent.height
                level: 3
            }
        }
        
        Item {
            id: btnAreaSuggestions
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: parent.height * 0.3
            
            Controls.Button {
                id: replayButton
                width: parent.width / 2
                height: parent.height
                anchors.left: parent.left
                text: "Replay Video"
                
                KeyNavigation.right: stopNextAutoplay
                KeyNavigation.up: stopNextAutoplay
                KeyNavigation.down: stopNextAutoplay
                
                Keys.onLeftPressed: {
                    root.movePageLeft()
                }
                
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: replayButton.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                    border.color: Kirigami.Theme.textColor
                    border.width: 1
                }
                
                onClicked: {
                    if(autoplayTimeHeading.visible){
                        autoPlayTimer.stop()
                        autoplayTimeHeading.visible = false
                        stopNextAutoplay.text = "Next Video"
                        suggestionBox.seconds = suggestionBox.countdownSeconds
                    }
                    triggerGuiEvent("YoutubeSkill.ReplayLast", {})
                }
                
                Keys.onReturnPressed: {
                    clicked()
                }
            }
            
            Controls.Button {
                id: stopNextAutoplay
                width: parent.width / 2
                height: parent.height
                anchors.right: parent.right
                text: "Cancel Autoplay"
                
                KeyNavigation.left: replayButton
                KeyNavigation.up: replayButton
                KeyNavigation.down: replayButton
                
                Keys.onRightPressed: {
                    root.movePageRight()
                }
                
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: stopNextAutoplay.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                    border.color: Kirigami.Theme.textColor
                    border.width: 1
                }
                
                onClicked: {
                    if(autoplayTimeHeading.visible){
                        autoPlayTimer.stop()
                        autoplayTimeHeading.visible = false
                        stopNextAutoplay.text = "Next Video"
                        suggestionBox.seconds = suggestionBox.countdownSeconds
                    } else {
                        suggestionBox.seconds = suggestionBox.countdownSeconds
                        autoPlayTimer.start()
                        autoplayTimeHeading.visible = true
                        stopNextAutoplay.text = "Cancel Autoplay"
                    }
                }
                
                Keys.onReturnPressed: {
                    clicked()
                }
            }
        }
    }
}
