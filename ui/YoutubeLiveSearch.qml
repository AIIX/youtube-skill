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

Mycroft.Delegate {
    id: delegate
    property var videoListModel: sessionData.videoListBlob.videoList
    
    skillBackgroundSource: sessionData.bgImage ? "https://source.unsplash.com/weekly?" + sessionData.bgImage : "https://source.unsplash.com/weekly?music"

    function searchYoutubeLiveResults(query){
        triggerGuiEvent("YoutubeSkill.SearchLive", {"Query": query})
    }
    
    onVideoListModelChanged: {
        videoListView.model = videoListModel
    }
    
    onFocusChanged: {
        if(delegate.focus){
            console.log("focus is here")
        }
    }
    
    RowLayout {
        id: searchVideoInputBox
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Kirigami.Units.gridUnit * 1
        height: Kirigami.Units.gridUnit * 3

        TextField {
            id: videoQueryBox
            Layout.fillWidth: true
            Layout.fillHeight: true
            onAccepted: {
                searchYoutubeLiveResults(videoQueryBox.text)
            }
            
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
        anchors.top: searchVideoInputBox.bottom
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
    }

   GridView {
        id: videoListView
        anchors.top: sept1.bottom
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        cellWidth: videoListView.width / 5
        cellHeight: videoListView.height / 3
        bottomMargin: Kirigami.Units.largeSpacing
        visible: true
        enabled: true
        focus: true
        highlight: PlasmaComponents.Highlight{}
        highlightFollowsCurrentItem: true
        clip: true
        property string currentVideoTitle
        property string currentVideoId
        delegate: PlasmaComponents3.ItemDelegate {
                    width: videoListView.cellWidth - Kirigami.Units.largeSpacing * 2
                    height: videoListView.cellHeight - Kirigami.Units.largeSpacing * 2
                    property string videoTitle: modelData.videoTitle
                    property string videoID: modelData.videoID
                    
                    background: PlasmaCore.FrameSvgItem {
                        id: frame
                        imagePath: "widgets/background"
                    }

                    contentItem: ColumnLayout {
                        Image {
                            id: videoImage
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            source: modelData.videoImage
                            Layout.fillWidth: true
                            Layout.preferredHeight: parent.height - Kirigami.Units.gridUnit * 3.5
                            fillMode: Image.Stretch
                        }

                        Kirigami.Separator {
                            Layout.fillWidth: true
                            color: Kirigami.Theme.linkColor
                        }

                        PlasmaComponents.Label {
                            id: videoLabel
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignTop
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            color: PlasmaCore.ColorScope.textColor
                            text: modelData.videoTitle
                        }
                    }
                    
                    onClicked: {
                        Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: modelData.videoID, vidTitle: modelData.videoTitle})
                    }
                }
                
        KeyNavigation.up: videoQueryBox
        KeyNavigation.down: controlBarItem
                
        Keys.onReturnPressed: {
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

    Component.onCompleted: {
        videoListView.forceActiveFocus()
    }
}

