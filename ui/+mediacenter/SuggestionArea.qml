import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft
import "+mediacenter/views" as Views
import "+mediacenter/delegates" as Delegates

Rectangle {
    id: suggestionBox
    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.6)
    property var videoSuggestionList
    property alias suggestionListFocus: suggestListView.focus
    property var nxtSongTitle
    property var nxtSongImage
    property var nxtSongID
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
    
    onNxtSongIDChanged: {
        nextSongCdBar.imageSource = nxtSongImage
        nextSongCdBar.nextSongTitle = nxtSongTitle
    }
    
    onVideoSuggestionListChanged: {
        console.log(JSON.stringify(videoSuggestionList))
        suggestListView.forceLayout()
    }
    
    onVisibleChanged: {
        if(visible){
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
            if(suggestionBox.seconds == 0){
                running = false;
                suggestionBox.seconds = suggestionBox.countdownSeconds
                console.log(nxtSongID)
                Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: nxtSongID, vidTitle: nxtSongTitle})
            }
        }
    }
    
    ColumnLayout {
        id: suggestBoxLayout
        anchors.fill: parent
        Views.ListTileView {
            id: suggestListView
            clip: true
            model: videoSuggestionList
            delegate: Delegates.SuggestVideoCard{}
            
            KeyNavigation.up: closeButton
            KeyNavigation.down: stopNextAutoplay
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
                text: "Cancle Autoplay"
                
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
                        stopNextAutoplay.text = "Cancle Autoplay"
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
                        stopNextAutoplay.text = "Cancle Autoplay"
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
