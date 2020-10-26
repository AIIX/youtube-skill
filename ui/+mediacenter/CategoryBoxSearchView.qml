/*
 *  Copyright 2018 by Aditya Mehra <aix.m@outlook.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import QtQuick.Layouts 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.3
import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.components 2.0 as PlasmaComponents
import Mycroft 1.0 as Mycroft
import "+mediacenter/views" as Views
import "+mediacenter/delegates" as Delegates

Item {
    property var searchListModel: sessionData.searchListBlob.videoList
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    onFocusChanged: {
        if(focus){
            searchBarArea.forceActiveFocus()
        }
    }
    
    function searchYoutubeLiveResults(query){
        triggerGuiEvent("YoutubeSkill.SearchLive", {"Query": query})
    }
    
    Rectangle {
        id: searchBarArea
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.largeSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        height: Kirigami.Units.gridUnit * 3
        width: parent.width / 3
        radius: 12
        color: searchBarArea.activeFocus ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.95) : Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.95)
                
        Keys.onReturnPressed: {
            videoQueryBox.forceActiveFocus()
        }
        
        KeyNavigation.up: searchCatButton
        KeyNavigation.down: searchGridView
        
        RowLayout {
            anchors.fill: parent
            TextField {
                id: videoQueryBox
                Layout.leftMargin: Kirigami.Units.largeSpacing
                Layout.fillWidth: true
                placeholderText: "Search here..."
                Layout.fillHeight: true
                onAccepted: {
                    searchYoutubeLiveResults(videoQueryBox.text)
                }
                KeyNavigation.down: searchGridView
                KeyNavigation.right: searchVideoQuery
            }
            
            Kirigami.Icon {
                id: searchVideoQuery
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                Layout.fillHeight: true
                source: "search" 
                KeyNavigation.left: videoQueryBox
                KeyNavigation.down: searchGridView
                
                Keys.onReturnPressed: {
                    searchYoutubeLiveResults(videoQueryBox.text)
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        searchYoutubeLiveResults(videoQueryBox.text)
                    }
                }
                
                ColorOverlay {
                    anchors.fill: parent
                    source: searchVideoQuery
                    color: Kirigami.Theme.highlightColor
                    visible: searchVideoQuery.activeFocus ? 1 : 0
                }
            }
        }
    }

    Views.BigTileView {
        id: searchGridView
        anchors {
            top: searchBarArea.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: Kirigami.Units.largeSpacing
        }
        focus: true
        model: searchListModel
        Layout.fillWidth: true
        Layout.fillHeight: true
        cellWidth: view.width / 4
        // FIXME: componentize more all this stuff
        cellHeight: cellWidth / 1.8 + Kirigami.Units.gridUnit * 5
        title: count > 0 ? "Search Results" : " "
        delegate: Delegates.ListVideoCard {
            width: searchGridView.cellWidth
            height: searchGridView.cellHeight
        }
        
        KeyNavigation.up: searchBarArea
    }
}
