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


GridView {
    id: view
    cellWidth: parent.width >= 1500 ? parent.width / 5 : parent.width / 3
    cellHeight: parent.width >= 1500 ? parent.height / 2 : parent.height / 3
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    //z: activeFocus ? 10: 1
    keyNavigationEnabled: true
    highlightFollowsCurrentItem: true
    snapMode: ListView.SnapToItem
    cacheBuffer: width
    highlightMoveDuration: Kirigami.Units.longDuration
    
    PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {
        id: scrollBar
        opacity: 0
        interactive: false
        onOpacityChanged: disappearTimer.restart()
        Timer {
            id: disappearTimer
            interval: 1000
            onTriggered: scrollBar.opacity = 0;
        }
        Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
    }
    
    Behavior on y {
            NumberAnimation {
                duration: Kirigami.Units.longDuration * 2
                easing.type: Easing.InOutQuad
            }
    }

    move: Transition {
        SmoothedAnimation {
            property: "x"
            duration: Kirigami.Units.longDuration
        }
    }
}
