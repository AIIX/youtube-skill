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
    property alias model: videoListView.model
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    onFocusChanged: {
        if(focus){
            console.log("here in focus")
            videoListView.forceActiveFocus()
        }
    }
    
    Views.TileView {
        id: videoListView
        focus: true
        clip: true
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: controlAreaButtons.top
        property string currentVideoTitle
        property string currentVideoId
        delegate: Delegates.VideoCard{}
        
        KeyNavigation.up: videoQueryBox
        KeyNavigation.down: nextPageAvailable ? nextButton : previousButton
                
        Keys.onReturnPressed: {
            busyIndicatorPop.open()
            if(focus){
                Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: currentVideoId, vidTitle: currentVideoTitle})
            }
        }
            
        onCurrentItemChanged: {
            currentVideoId = videoListView.currentItem.videoID
            currentVideoTitle = videoListView.currentItem.videoTitle
            console.log(videoListView.currentItem.videoTitle)
        }
    }
    
    RowLayout {
        id: controlAreaButtons
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Kirigami.Units.gridUnit * 2.5
        
        Button {
            id: previousButton
            text: "Previous Page"
            Layout.preferredWidth: nextButton.visible ? parent.width / 2 : parent.width
            Layout.fillHeight: true
            icon.name: "go-previous-symbolic"
            enabled: nextPageAvailable ? 0 : 1
            visible: nextPageAvailable ? 0 : 1
            
            background: Rectangle {
                color: previousButton.activeFocus ?  Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
            }
            
            onClicked: {
                triggerGuiEvent("YoutubeSkill.PreviousPage", {"Category": categoryName})
                busyIndicatorPop.open()
                nextButton.forceActiveFocus()
            }
            
            Keys.onReturnPressed: {
                triggerGuiEvent("YoutubeSkill.PreviousPage", {"Category": categoryName})
                busyIndicatorPop.open()
                nextButton.forceActiveFocus()
            }
            
            KeyNavigation.up: videoListView
        }
        
        Button {
            id: nextButton
            text: "Next Page"
            enabled: nextPageAvailable ? 1 : 0
            visible: nextPageAvailable ? 1 : 0
            Layout.preferredWidth: previousButton.visible ? parent.width / 2 : parent.width
            Layout.fillHeight: true
            icon.name: "go-next-symbolic"
            
            background: Rectangle {
                color: nextButton.activeFocus ?  Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
            }
            
            onClicked: {
                triggerGuiEvent("YoutubeSkill.NextPage", {"Category": categoryName})
                busyIndicatorPop.open()
                previousButton.forceActiveFocus()
            }
            
            Keys.onReturnPressed: {
                triggerGuiEvent("YoutubeSkill.NextPage", {"Category": categoryName})
                busyIndicatorPop.open()
                previousButton.forceActiveFocus()
            }
            
            KeyNavigation.up: videoListView
        }
    }
}
