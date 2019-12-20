import QtQuick 2.9
import QtQuick.Layouts 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.3
import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.components 2.0 as PlasmaComponents
import Mycroft 1.0 as Mycroft

ItemDelegate {
    id: delegate
    readonly property ListView listView: ListView.view
    
    implicitWidth: listView.cellWidth
    implicitHeight: listView.height
    
    property string videoTitle: modelData.videoTitle
    property string videoID: modelData.videoID
    z: listView.currentIndex == index ? 2 : 0
    
    background: Item {
        id: background
        property real extraMargin:  Math.round(listView.currentIndex == index && delegate.activeFocus ? Kirigami.Units.gridUnit/10 : Kirigami.Units.gridUnit/2)
        Behavior on extraMargin {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        PlasmaCore.FrameSvgItem {
            anchors {
                fill: frame
                leftMargin: -margins.left
                topMargin: -margins.top
                rightMargin: -margins.right
                bottomMargin: -margins.bottom
            }
            imagePath: Qt.resolvedUrl("./background.svg")
            prefix: "shadow"
        }
        PlasmaCore.FrameSvgItem {
            id: frame
            anchors {
                fill: parent
                margins: background.extraMargin
            }
            imagePath: Qt.resolvedUrl("./background.svg")

            width: listView.currentIndex == index && delegate.activeFocus ? parent.width : parent.width - Kirigami.Units.gridUnit
            height: listView.currentIndex == index && delegate.activeFocus ? parent.height : parent.height - Kirigami.Units.gridUnit
            opacity: 0.8
        }
    }
         
    contentItem: ColumnLayout {
        spacing: 0
        Image {
            id: videoImage
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            source: modelData.videoImage
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height - Kirigami.Units.gridUnit * 3.5
            fillMode: Image.Stretch
        }

        PlasmaComponents.Label {
            id: videoLabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            maximumLineCount: 3
            elide: Text.ElideRight
            color: PlasmaCore.ColorScope.textColor
            text: modelData.videoTitle
        }
    }
    
    Keys.onReturnPressed: {
        Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: modelData.videoID, vidTitle: modelData.videoTitle})
    }
        
    onClicked: {
        Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: modelData.videoID, vidTitle: modelData.videoTitle})
    }
}

