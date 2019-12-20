import QtQuick 2.9
import QtQuick.Layouts 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.3
import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.components 2.0 as PlasmaComponents
import Mycroft 1.0 as Mycroft


Item {
    id: delegate
    readonly property GridView gridView: GridView.view
    
    implicitWidth: gridView.cellWidth
    implicitHeight: gridView.cellHeight
    property string videoTitle: modelData.videoTitle
    property string videoID: modelData.videoID
    z: gridView.currentIndex == index ? 2 : 0
    property bool checked: gridView.currentIndex == index
    
    PlasmaComponents3.ItemDelegate {
        anchors.centerIn: parent
        implicitWidth: gridView.cellWidth - Kirigami.Units.largeSpacing * 2.5
        implicitHeight: gridView.cellHeight - Kirigami.Units.largeSpacing * 2.5
        
        leftPadding: frame.margins.left + background.extraMargin
        topPadding: frame.margins.top + background.extraMargin
        rightPadding: frame.margins.right + background.extraMargin
        bottomPadding: frame.margins.bottom + background.extraMargin
         
        background: Item {
        id: background
        property real extraMargin:  Math.round(gridView.currentIndex == index && delegate.activeFocus ? -Kirigami.Units.gridUnit/2 : Kirigami.Units.gridUnit/2)
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
            
            width: gridView.currentIndex == index && delegate.activeFocus ? delegate.width : parent.width
            height: gridView.currentIndex == index && delegate.activeFocus ? delegate.height : parent.height
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

            Kirigami.Separator {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.linkColor
            }

            PlasmaComponents.Label {
                id: videoLabel
                Layout.fillWidth: true
                Layout.fillHeight: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                maximumLineCount: 3
                elide: Text.ElideRight
                color: PlasmaCore.ColorScope.textColor
                text: modelData.videoTitle
            }
        }
        
        onClicked: {
            Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: modelData.videoID, vidTitle: modelData.videoTitle})
        }
    }
}
