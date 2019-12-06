import QtQuick 2.9
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft


RowLayout {
    id: countdownArea
    Layout.leftMargin: Kirigami.Units.largeSpacing
    Layout.bottomMargin: Kirigami.Units.largeSpacing
    property alias imageSource: img.source
    property alias nextSongTitle: nextSongLabel.text
    spacing: Kirigami.Units.largeSpacing
    
    Kirigami.Heading {
        level: 3
        Layout.alignment: Qt.AlignLeft
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        color: Kirigami.Theme.textColor
        text: "Next:"
    }
    
    Rectangle {
        Layout.preferredWidth: Kirigami.Units.iconSizes.huge + Kirigami.Units.smallSpacing
        Layout.preferredHeight: Kirigami.Units.iconSizes.huge + Kirigami.Units.smallSpacing
        Layout.alignment: Qt.AlignLeft
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.linkColor
        border.width: Kirigami.Units.smallSpacing
        radius: 250
        
        Image {
            id: img
            width: Kirigami.Units.iconSizes.huge
            height: Kirigami.Units.iconSizes.huge
            fillMode: Image.PreserveAspectCrop
            anchors.centerIn: parent
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: imgContainer
            }
        }
        
        Rectangle{
            id: imgContainer
            property int borderWidth: 3
            color: Kirigami.Theme.backgroundColor
            width: Kirigami.Units.iconSizes.huge
            height: Kirigami.Units.iconSizes.huge
            anchors.centerIn: parent
            border.color: Kirigami.Theme.linkColor
            border.width: borderWidth
            radius: 250
            visible: false
        }
    }
    
    Kirigami.Heading {
        id: nextSongLabel
        level: 3
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        color: Kirigami.Theme.textColor
    }
}
