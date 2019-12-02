import QtAV 1.6
import QtQuick.Layouts 1.4
import QtQuick 2.9
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

import QtQuick 2.8
import QtGraphicalEffects 1.0

Rectangle{
    property int imgRadius: Math.min(imgContainer.width, imgContainer.height) / 2
    property int borderWidth: 3

    id: imgContainer
    color: "#f2f2f2"
    border.color: "#385d8a"
    border.width: borderWidth
    radius: imgRadius

    Image {
        id: img
        anchors.fill: parent
        source: "https://www.gnu.org/graphics/nu-gnu.svg"
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Item {
                width: imgContainer.width
                height: imgContainer.height
                Rectangle{
                    id: rectContainer
                    width: parent.width
                    anchors.bottom: parent.bottom
                    clip: true
                    color: "transparent"
                    Rectangle {
                        id: rectMask
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: imgContainer.borderWidth
                        height: img.height - imgContainer.borderWidth * 2
                        radius: Math.max(0, imgContainer.imgRadius-imgContainer.borderWidth)
                    }
                    SequentialAnimation{
                        running: img.status == Image.Ready
                        loops: Animation.Infinite

                        NumberAnimation{
                            target: rectContainer
                            properties: "height"
                            from: 0
                            to: img.height
                            duration: 5000
                        }
                        PauseAnimation{
                            duration: 1000
                        }

                        NumberAnimation{
                            target: rectContainer
                            properties: "height"
                            from: img.height
                            to: 0
                            duration: 5000
                        }

                        PauseAnimation{
                            duration: 1000
                        }
                    }
                }
            }
        }
    }
}
