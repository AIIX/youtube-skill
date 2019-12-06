import QtAV 1.6
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
    property var nextSongInformation
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    implicitHeight: suggestBoxLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
    
    onFocusChanged: {
        if(visible && focus){
            suggestListView.forceActiveFocus()
        }
    }
    
    onVideoSuggestionListChanged: {
        console.log(JSON.stringify(videoSuggestionList))
        suggestListView.forceLayout()
    }
    
    ColumnLayout {
        id: suggestBoxLayout
        anchors.fill: parent
        Views.ListTileView {
            id: suggestListView
            clip: true
            model: videoSuggestionList
            delegate: Delegates.SuggestVideoCard{}
        }
    }
}
