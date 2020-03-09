import QtQuick 2.9
import QtQuick.Layouts 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.3
import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.components 2.0 as PlasmaComponents
import Mycroft 1.0 as Mycroft
import org.kde.mycroft.bigscreen 1.0 as BigScreen


BigScreen.AbstractDelegate {
    id: delegate
    readonly property ListView listView: ListView.view
    
    implicitWidth: listView.cellWidth
    implicitHeight: listView.height - Kirigami.Units.largeSpacing * 2
    z: listView.currentIndex == index ? 2 : 0
    readonly property bool isCurrent: listView.currentIndex == index && activeFocus

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            id: imgRoot
            color: "transparent"
            clip: true
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.topMargin: -delegate.topPadding + delegate.topInset + delegate.borderSize
            Layout.leftMargin: -delegate.leftPadding + delegate.leftInset + delegate.borderSize
            Layout.rightMargin: -delegate.rightPadding + delegate.rightInset + delegate.borderSize
            //Layout.bottomMargin: -Kirigami.Units.smallSpacing
            Layout.preferredHeight: parent.height - Kirigami.Units.gridUnit * 3
            radius: 3

            layer.enabled: true
            layer.effect: OpacityMask {
                cached: true
                maskSource: Rectangle {
                    x: imgRoot.x; y: imgRoot.y
                    width: imgRoot.width
                    height: imgRoot.height
                    radius: imgRoot.radius
                }
            }

            Image {
                id: img
                source: modelData.videoImage
                width: parent.width
                height: parent.height
                y: -12
                opacity: 1
                fillMode: Image.Tile 

                Rectangle {
                    id: videoDurationTime
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: parent.width > Kirigami.Units.gridUnit * 15 ?  Kirigami.Units.gridUnit * 0.4 : Kirigami.Units.largeSpacing
                    anchors.right: parent.right
                    anchors.rightMargin: Kirigami.Units.gridUnit * 0.75
                    width: Kirigami.Units.gridUnit * 2.5 + Kirigami.Units.largeSpacing * 2
                    height: durationText.height
                    radius: Kirigami.Units.gridUnit * 0.5
                    color: Qt.rgba(0, 0, 0, 0.8)

                    PlasmaComponents.Label {
                        id: durationText
                        anchors.centerIn: parent
                        text: modelData.videoDuration
                        color: Kirigami.Theme.textColor
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                id: videoLabel
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                wrapMode: Text.Wrap
                level: 3
                //verticalAlignment: Text.AlignVCenter
                maximumLineCount: 1
                elide: Text.ElideRight
                color: PlasmaCore.ColorScope.textColor
                Component.onCompleted: {
                    text = modelData.videoTitle
                }
            }

            PlasmaComponents.Label {
                id: videoChannelName
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                maximumLineCount: 1
                elide: Text.ElideRight
                color: PlasmaCore.ColorScope.textColor
                text: modelData.videoChannel
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                
                PlasmaComponents.Label {
                    id: videoUploadDate
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    wrapMode: Text.WordWrap
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    color: PlasmaCore.ColorScope.textColor
                    text: modelData.videoUploadDate
                }

                PlasmaComponents.Label {
                    id: videoViews
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    wrapMode: Text.WordWrap
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    color: PlasmaCore.ColorScope.textColor
                    text: modelData.videoViews
                }
            }
        }
    }

    onClicked: {
        busyIndicatorPop.open()
        Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: modelData.videoID, vidTitle: modelData.videoTitle, vidImage: modelData.videoImage, vidChannel: modelData.videoChannel, vidViews: modelData.videoViews, vidUploadDate: modelData.videoUploadDate, vidDuration: modelData.videoDuration})
    }
}
