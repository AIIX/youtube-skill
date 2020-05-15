import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft
import "+mediacenter/views" as Views
import "+mediacenter/delegates" as Delegates
import org.kde.mycroft.bigscreen 1.0 as BigScreen

Rectangle {
    id: suggestionBox
    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
    property var videoSuggestionList
    property alias suggestionListFocus: suggestListView.focus
    property var nxtSongBlob
    property int countdownSeconds: 15
    property int seconds: countdownSeconds
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    implicitHeight: suggestBoxLayout.implicitHeight + Kirigami.Units.largeSpacing * 4
    
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
    
    ColumnLayout {
        id: suggestBoxLayout
        anchors.fill: parent
        BigScreen.TileView {
            id: suggestListView
            clip: true
            model: videoSuggestionList
            delegate: Delegates.ListVideoCard{}
            title: "Watch Next"
            Layout.margins: Kirigami.Units.largeSpacing * 2
            cellWidth: parent.width / 4
            navigationDown: stopNextAutoplay
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
            Controls.Button {
                id: stopNextAutoplay
                Layout.preferredWidth: parent.width / 3
                Layout.fillHeight: true
                text: "Cancel Autoplay"
                
                KeyNavigation.up: suggestListView
                
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
