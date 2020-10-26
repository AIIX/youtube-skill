import QtQuick 2.9
import QtQuick.Layouts 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.3
import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import Mycroft 1.0 as Mycroft


PlasmaComponents.ItemDelegate {
    id: delegate
    
//     readonly property Flickable gridView: {
//         var candidate = parent;
//         while (candidate) {
//             if (candidate instanceof Flickable) {
//                 return candidate;
//             }
//             candidate = candidate.parent;
//         }
//         return null;
//     }
    
    readonly property GridView gridView: GridView.view
    implicitWidth: gridView.cellWidth
    implicitHeight: gridView.cellHeight
    
    readonly property bool isCurrent: {
        gridView.currentIndex == index && activeFocus && !gridView.moving
    }

    z: isCurrent ? 2 : 0
    
    onClicked: {
        gridView.forceActiveFocus()
        gridView.currentIndex = index
    }

    Keys.onReturnPressed: {
        clicked();
    }
    
    leftPadding: Kirigami.Units.largeSpacing * 2
    topPadding: Kirigami.Units.largeSpacing * 2
    rightPadding: Kirigami.Units.largeSpacing * 2
    bottomPadding: Kirigami.Units.largeSpacing * 2

    leftInset: Kirigami.Units.largeSpacing
    topInset: Kirigami.Units.largeSpacing
    rightInset: Kirigami.Units.largeSpacing
    bottomInset: Kirigami.Units.largeSpacing
    
    contentItem: Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing
                    
                    Rectangle {
                        id: imgRoot
                        color: "transparent"
                        clip: true
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.topMargin: delegate.isCurrent ? -Kirigami.Units.largeSpacing * 2 : -Kirigami.Units.smallSpacing * 2
                        Layout.leftMargin: -Kirigami.Units.smallSpacing * 2
                        Layout.rightMargin: -Kirigami.Units.smallSpacing * 2
                        Layout.bottomMargin: -Kirigami.Units.smallSpacing
                        Layout.preferredHeight: parent.height - Kirigami.Units.gridUnit * 3
                        radius: 3
                        
                        layer.enabled: true
                        layer.effect: OpacityMask {
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
                
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        
                        ColumnLayout {
                            anchors.fill: parent
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
            }
        }
    
    background: Item {
        id: background

        Rectangle {
            id: shadowSource
            anchors {
                fill: frame
                margins: units.largeSpacing
            }
            color: "black"
            radius: frame.radius
            visible: false
        }

        FastBlur {
            anchors.fill: frame
            transparentBorder: true
            source: shadowSource
            radius: Kirigami.Units.largeSpacing * 2
            cached: true
            readonly property bool inView: delegate.x <= gridView.contentX + gridView.width && delegate.x + delegate.width >= gridView.contentX
            visible: inView
        }

        Rectangle {
            id: frame
            anchors {
                fill: parent
            }

            /* For some reason, putting the colors and animation in the states
             * and transition makes the color not load until the animations finish
             * during the startup of the homescreen containment.
             * Also for some reason, frame starts out white and fades into the correct color while
             * innerFrame starts out transparent (maybe?) and fades into the correct color.
             */
            color: delegate.isCurrent ? delegate.Kirigami.Theme.highlightColor : delegate.Kirigami.Theme.backgroundColor
            Behavior on color {
                ColorAnimation {
                    duration: Kirigami.Units.longDuration/2
                    easing.type: Easing.InOutQuad
                }
            }

            Rectangle {
                id: innerFrame
                anchors {
                    fill: parent
                    margins: units.smallSpacing
                }
                radius: frame.radius/2
                color: delegate.Kirigami.Theme.backgroundColor
            }

            states: [
                State {
                    when: delegate.isCurrent
                    PropertyChanges {
                        target: delegate
                        leftInset: Kirigami.Units.largeSpacing - innerFrame.anchors.margins
                        rightInset: Kirigami.Units.largeSpacing - innerFrame.anchors.margins
                        topInset: -Kirigami.Units.smallSpacing 
                        bottomInset: -Kirigami.Units.smallSpacing
                    }
                    PropertyChanges {
                        target: frame
                        radius: 6
                    }
                },
                State {
                    when: !delegate.isCurrent
                    PropertyChanges {
                        target: delegate
                        leftInset: Kirigami.Units.largeSpacing
                        rightInset: Kirigami.Units.largeSpacing
                        topInset: Kirigami.Units.largeSpacing
                        bottomInset: Kirigami.Units.largeSpacing
                    }
                    PropertyChanges {
                        target: frame
                        radius: 3
                    }
                }
            ]

            transitions: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "leftInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "rightInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "topInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "bottomInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "radius"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}

