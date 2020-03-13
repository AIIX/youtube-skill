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
    
    implicitWidth: listView.cellWidth
    height: parent.height

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Item {
            id: imgRoot
            //clip: true
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.topMargin: -delegate.topPadding + delegate.topInset + extraBorder
            Layout.leftMargin: -delegate.leftPadding + delegate.leftInset + extraBorder
            Layout.rightMargin: -delegate.rightPadding + delegate.rightInset + extraBorder
            // Any width times 0.5625 is a 16:9 ratio
            // Adding baseRadius is needed to prevent the bottom from being rounded
            Layout.preferredHeight: width * 0.5625 + delegate.baseRadius
            // FIXME: another thing copied from AbstractDelegate
            property real extraBorder: 0

            layer.enabled: true
            layer.effect: OpacityMask {
                cached: true
                maskSource: Rectangle {
                    x: imgRoot.x;
                    y: imgRoot.y
                    width: imgRoot.width
                    height: imgRoot.height
                    radius: delegate.baseRadius
                }
            }

            Image {
                id: img
                source: modelData.videoImage
                anchors {
                    fill: parent
                    // To not round under
                    bottomMargin: delegate.baseRadius
                }
                opacity: 1
                fillMode: Image.PreserveAspectCrop

                Rectangle {
                    id: videoDurationTime
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Kirigami.Units.largeSpacing
                    anchors.right: parent.right
                    anchors.rightMargin: Kirigami.Units.largeSpacing
                    // FIXME: kind of hacky to get the padding around the text right
                    width: durationText.width + Kirigami.Units.largeSpacing
                    height: Kirigami.Units.gridUnit
                    radius: delegate.baseRadius
                    color: Qt.rgba(0, 0, 0, 0.8)

                    PlasmaComponents.Label {
                        id: durationText
                        anchors.centerIn: parent
                        text: modelData.videoDuration
                        color: Kirigami.Theme.textColor
                    }
                }
            }
            
            states: [
                State {
                    when: delegate.isCurrent
                    PropertyChanges {
                        target: imgRoot
                        extraBorder: delegate.borderSize
                    }
                },
                State {
                    when: !delegate.isCurrent
                    PropertyChanges {
                        target: imgRoot
                        extraBorder: 0
                    }
                }
            ]
            transitions: Transition {
                onRunningChanged: {
                    // Optimize when animating the thumbnail
                    img.smooth = !running
                }
                NumberAnimation {
                    property: "extraBorder"
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Compensate for blank space created from not rounding thumbnail bottom corners
            Layout.topMargin: -delegate.baseRadius
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                id: videoLabel
                Layout.fillWidth: true
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
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                maximumLineCount: 1
                elide: Text.ElideRight
                color: PlasmaCore.ColorScope.textColor
                text: modelData.videoChannel
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    id: videoViews
                    Layout.alignment: Qt.AlignLeft
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    elide: Text.ElideRight
                    color: PlasmaCore.ColorScope.textColor
                    text: modelData.videoViews
                }

                PlasmaComponents.Label {
                    id: videoUploadDate
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    color: PlasmaCore.ColorScope.textColor
                    text: modelData.videoUploadDate
                }
            }
        }
    }

    onClicked: {
        busyIndicatorPop.open()
        Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: modelData.videoID, vidTitle: modelData.videoTitle, vidImage: modelData.videoImage, vidChannel: modelData.videoChannel, vidViews: modelData.videoViews, vidUploadDate: modelData.videoUploadDate, vidDuration: modelData.videoDuration})
    }
}
