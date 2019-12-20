/*
 *  Copyright 2018 by Aditya Mehra <aix.m@outlook.com>
 *  Copyright 2018 Marco Martin <mart@kde.org>
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

Mycroft.Delegate {
    id: delegate
    property var videoListModel: sessionData.videoListBlob.videoList
    property bool busyIndicate: false
    
    skillBackgroundSource: sessionData.bgImage ? "https://source.unsplash.com/weekly?" + sessionData.bgImage : "https://source.unsplash.com/weekly?music"

    function searchYoutubeLiveResults(query){
        triggerGuiEvent("YoutubeSkill.SearchLive", {"Query": query})
    }
    
    Connections {
        target: Mycroft.MycroftController
        onIntentRecevied: {
            if(type == "speak") {
                busyIndicatorPop.close()
                busyIndicate = false
            }
        }
    }
    
    onVideoListModelChanged: {
        videoListView.model = videoListModel
    }
    
    onFocusChanged: {
        busyIndicatorPop.close()
        busyIndicate = false
        if(delegate.focus){
            console.log("focus is here")
        }
    }
    
    Keys.onBackPressed: {
        parent.parent.parent.currentIndex++
        parent.parent.parent.currentItem.contentItem.forceActiveFocus()
    }
    
    ColumnLayout {
        id: colLay1
        anchors.fill: parent
        
        RowLayout {
            id: searchVideoInputBox
            Layout.fillWidth: true
            Layout.alignment: Layout.AlignTop
            Layout.maximumHeight: Kirigami.Units.gridUnit * 3
            z: 120

            TextField {
                id: videoQueryBox
                Layout.fillWidth: true
                Layout.fillHeight: true
                onAccepted: {
                    searchYoutubeLiveResults(videoQueryBox.text)
                }
                
                KeyNavigation.up: closeButton
                KeyNavigation.down: videoListView
                KeyNavigation.right: searchVideoQuery
            }

            Button {
                id: searchVideoQuery
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                text: "Search"
                Layout.fillHeight: true
                highlighted: focus ? 1 : 0
                onClicked: {
                    searchYoutubeLiveResults(videoQueryBox.text)
                }
                
                KeyNavigation.left: videoQueryBox
                KeyNavigation.down: videoListView
            }
        }
                        
        Kirigami.Separator {
            id: sept1
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            z: 100
        }

    Views.TileView {
            id: videoListView
            focus: true
            clip: true
            property string currentVideoTitle
            property string currentVideoId
            delegate: Delegates.VideoCard{}
                    
            KeyNavigation.up: videoQueryBox
            KeyNavigation.down: controlBarItem
                    
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
    }

    controlBar: Control {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        padding: Kirigami.Units.largeSpacing
        
        onFocusChanged: {
            if(focus && previousButton.visible){
                previousButton.forceActiveFocus()
            } else if (focus && nextButton.visible) {
                nextButton.forceActiveFocus()
            }
        }
        
        background: LinearGradient {
            start: Qt.point(0, 0)
            end: Qt.point(0, height)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: "black" }
                GradientStop { position: 1.0; color: "black" }
            }
        }
        
        contentItem: RowLayout {            
            Button {
                id: previousButton
                text: "Previous Page"
                Layout.preferredWidth: nextButton.visible ? parent.width / 2 : parent.width
                Layout.fillHeight: true
                icon.name: "go-previous-symbolic"
                enabled: sessionData.previousAvailable
                visible: sessionData.previousAvailable
                highlighted: focus ? 1 : 0
                onClicked: {
                    triggerGuiEvent("YoutubeSkill.PreviousPage", {})
                }
                
                Keys.onReturnPressed: {
                    triggerGuiEvent("YoutubeSkill.PreviousPage", {})
                }
                
                KeyNavigation.right: nextButton
                KeyNavigation.up: videoListView
            }
            
            Button {
                id: nextButton
                text: "Next Page"
                enabled: sessionData.nextAvailable
                visible: sessionData.nextAvailable
                Layout.preferredWidth: previousButton.visible ? parent.width / 2 : parent.width
                Layout.fillHeight: true
                highlighted: focus ? 1 : 0
                icon.name: "go-next-symbolic"
                onClicked: {
                    triggerGuiEvent("YoutubeSkill.NextPage", {})
                }
                
                Keys.onReturnPressed: {
                    triggerGuiEvent("YoutubeSkill.NextPage", {})
                }
                
                KeyNavigation.up: videoListView
                KeyNavigation.left: previousButton
            }
        }
    }
    
    Popup {
        id: busyIndicatorPop
        width: parent.width
        height: parent.height
        background: Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
        }
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        
        BusyIndicator {
            running: busyIndicate
            anchors.centerIn: parent
        }
        
        onOpened: {
            busyIndicate = true
        }
        
        onClosed: {
            busyIndicate = false
        }
    }

    Component.onCompleted: {
        videoListView.forceActiveFocus()
    }
}

