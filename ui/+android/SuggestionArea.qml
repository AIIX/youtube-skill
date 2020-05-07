import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft
import "+mediacenter/views" as Views
import "+mediacenter/delegates" as Delegates
import org.kde.mycroft.bigscreen 1.0 as BigScreen

Controls.Control {
    id: suggestionBox
    property var videoSuggestionList
    property alias suggestionListFocus: suggestListView.focus
    property var nxtSongBlob
    property int countdownSeconds: 15
    property int seconds: countdownSeconds
    implicitWidth: parent.width
    anchors.top: parent.top
    anchors.topMargin: Kirigami.Units.gridUnit
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Kirigami.Units.gridUnit * 2
    property bool busyIndicate: false

    onFocusChanged: {
        if(visible && focus){
                suggestListView.forceActiveFocus()
        }
    }
    
    onNxtSongBlobChanged: {
        nextSongCdBar.imageSource = nxtSongBlob.videoImage
        nextSongCdBar.nextSongTitle = nxtSongBlob.videoTitle
    }
    
    onVideoSuggestionListChanged: {
        console.log(JSON.stringify(videoSuggestionList))
        suggestListView.view.forceLayout()
    }
    
    onVisibleChanged: {
        if(visible) {
            autoPlayTimer.start()
        }
    }
    
    Connections {
        target: Mycroft.MycroftController
        onIntentRecevied: {
            if(type == "speak") {
                busyIndicatorPop.close()
                busyIndicate = false
            }
        }
    }

    Timer {
        id: autoPlayTimer
        interval: 1000
        repeat: true
        onTriggered: {
            suggestionBox.seconds--;
            autoplayTimeHeading.text = "Next Video In: " + suggestionBox.seconds
            if(suggestionBox.seconds == 0) {
                running = false;
                suggestionBox.seconds = suggestionBox.countdownSeconds
                Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: nxtSongBlob.videoID, vidTitle: nxtSongBlob.videoTitle, vidImage: nxtSongBlob.videoImage, vidChannel: nxtSongBlob.videoChannel, vidViews: nxtSongBlob.videoViews, vidUploadDate: nxtSongBlob.videoUploadDate, vidDuration: nxtSongBlob.videoDuration})
            }
        }
    }
    
    background: Rectangle {
         color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
    }
    
    contentItem: Item {     
        
        BigScreen.TileView {
            id: suggestListView
            clip: false
            model: videoSuggestionList
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: Kirigami.Units.largeSpacing * 2
            width: parent.width
            height: cellWidth + Kirigami.Units.gridUnit * 1.5
            delegate: Delegates.ListVideoCard{}
            cellWidth: parent.width / 4
            title: "Watch Next"
            visible: suggestionBox.visible
            navigationDown: replayButton
        }
        
        ColumnLayout {
            id: suggestBoxLayout
            anchors {
                left: parent.left
                right: parent.right
                top: suggestListView.bottom
                bottom: parent.bottom
            }
                
            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
            }
            
            RowLayout{
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                
                Views.CountdownBar {
                    id: nextSongCdBar
                    Layout.preferredWidth: parent.width / 3
                    Layout.fillHeight: true
                }
                Kirigami.Separator {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                }
                
                RowLayout {
                    Layout.preferredWidth: parent.width / 3
                    Layout.fillHeight: true
                    
                    Controls.Button {
                        id: replayButton
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "Replay Video"
                        
                        KeyNavigation.up: suggestListView
                        KeyNavigation.right: stopNextAutoplay
                        
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
                            if(autoplayTimeHeading.visible){
                                autoPlayTimer.stop()
                                autoplayTimeHeading.visible = false
                                stopNextAutoplay.text = "Next Video"
                                suggestionBox.seconds = suggestionBox.countdownSeconds
                            }
                            triggerGuiEvent("YoutubeSkill.ReplayLast", {})
                        }
                    }
                    
                    Controls.Button {
                        id: stopNextAutoplay
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "Cancel Autoplay"
                        
                        KeyNavigation.up: suggestListView
                        KeyNavigation.left: replayButton
                        
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
                    }
                }
            
                Kirigami.Separator {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                }
                
                Kirigami.Heading {
                    id: autoplayTimeHeading
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.preferredWidth: parent.width / 3
                    Layout.fillHeight: true
                    level: 3
                }
            }
        }
    }
    
    Controls.Popup {
        id: busyIndicatorPop
        width: parent.width
        height: parent.height
        background: Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
        }
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        
        Controls.BusyIndicator {
            running: busyIndicate
            anchors.centerIn: parent
        }
        
        onOpened: {
            busyIndicate = true
            autoPlayTimer.stop()
            autoplayTimeHeading.visible = false
            stopNextAutoplay.text = "Next Video"
            suggestionBox.seconds = suggestionBox.countdownSeconds
        }
        
        onClosed: {
            busyIndicate = false
        }
    }
}
