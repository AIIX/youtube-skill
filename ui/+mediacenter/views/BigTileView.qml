/*
 *  Copyright 2019 Aditya Mehra <aix.m@outlook.com>
 *  Copyright 2019 Marco Martin <mart@kde.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.12
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as Controls
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.5 as Kirigami


FocusScope {
    id: root
    signal activated
    property string title
    property alias view: view
    property alias delegate: view.delegate
    property alias model: view.model
    property alias count: view.count
    property alias currentIndex: view.currentIndex
    property alias currentItem: view.currentItem
    Layout.fillWidth: true
    implicitHeight: view.implicitHeight + header.implicitHeight
    property alias cellWidth: view.cellWidth
    
    property Item navigationUp
    property Item navigationDown

    Kirigami.Heading {
        id: header
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        text: title
        layer.enabled: true
        color: "white"
    }
    
    GridView {
        id: view
        anchors {
                left: parent.left
                right: parent.right
                top: header.baseline
                bottom: parent.bottom
                topMargin: Kirigami.Units.largeSpacing*2
                leftMargin: -Kirigami.Units.largeSpacing
        }
        focus: true
        z: activeFocus ? 10: 1 
        cellWidth: parent.width / 4
        cellHeight: parent.height / 1.5
        keyNavigationEnabled: true
        highlightFollowsCurrentItem: true
        snapMode: ListView.SnapToItem
        cacheBuffer: width
        highlightMoveDuration: Kirigami.Units.longDuration

        Behavior on y {
            NumberAnimation {
                duration: Kirigami.Units.longDuration * 2
                easing.type: Easing.InOutQuad
            }
        }
        
        onCurrentItemChanged: {
            y = -currentItem.y
        }
        
        move: Transition {
            SmoothedAnimation {
                property: "x"
                duration: Kirigami.Units.longDuration
            }
        }

        KeyNavigation.left: root
        KeyNavigation.right: root
    }
}
