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
    property var newsListModel: sessionData.newsListBlob.videoList
    property var musicListModel: sessionData.musicListBlob.videoList
    property var techListModel: sessionData.techListBlob.videoList
    property var polListModel: sessionData.polListBlob.videoList
    property var gamingListModel: sessionData.gamingListBlob.videoList
    property var searchListModel: sessionData.searchListBlob.videoList
    property bool busyIndicate: false
    
    skillBackgroundSource: sessionData.bgImage ? "https://source.unsplash.com/weekly?" + sessionData.bgImage : "https://source.unsplash.com/weekly?music"

    function searchYoutubeLiveResults(query){
        triggerGuiEvent("YoutubeSkill.SearchLive", {"Query": query})
        categoryLayout.currentIndex = 5
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
    
    onNewsListModelChanged: {
        newsCatView.model = newsListModel
    }
    
    onMusicListModelChanged: {
        musicCatView.model = musicListModel
    }
    
    onTechListModelChanged: {
        techCatView.model = techListModel
    }
    
    onPolListModelChanged: {
        polCatView.model = polListModel
    }
    
    onGamingListModelChanged: {
        gamingCatView.model = gamingListModel
    }
    
    onSearchListModelChanged: {
        searchCatView.model = searchListModel
        console.log("SearchListModelChanged")
        console.log(JSON.stringify(searchListModel))
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
            id: categoryRepeater
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Layout.maximumHeight: Kirigami.Units.gridUnit * 2
            
            Button {
                id: newsCatButton
                text: "News"
                Layout.fillWidth: true
                Layout.fillHeight: true
                KeyNavigation.right: musicCatButton
                KeyNavigation.down: videoQueryBox
                
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: newsCatButton.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                }
                
                onClicked: {
                    categoryLayout.currentIndex = 0
                }
                Keys.onReturnPressed: {
                    clicked();
                }
            }
            
            Button {
                id: musicCatButton
                text: "Music"
                Layout.fillWidth: true
                Layout.fillHeight: true
                KeyNavigation.right: techCatButton
                KeyNavigation.left: newsCatButton
                KeyNavigation.down: videoQueryBox
                
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: musicCatButton.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                }
                
                onClicked: {
                    categoryLayout.currentIndex = 1
                }
                Keys.onReturnPressed: {
                    clicked();
                }
            }
            
            Button {
                id: techCatButton
                text: "Technology"
                Layout.fillWidth: true
                Layout.fillHeight: true
                KeyNavigation.right: polCatButton
                KeyNavigation.left: musicCatButton
                KeyNavigation.down: videoQueryBox
                
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: techCatButton.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                }
                
                onClicked: {
                    categoryLayout.currentIndex = 2
                }
                Keys.onReturnPressed: {
                    clicked();
                }
                
            }
            
            Button {
                id: polCatButton
                text: "Politics"
                Layout.fillWidth: true
                Layout.fillHeight: true
                KeyNavigation.right: gamingCatButton
                KeyNavigation.left: techCatButton
                KeyNavigation.down: videoQueryBox
                
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: polCatButton.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                }
                
                onClicked: {
                    categoryLayout.currentIndex = 3
                }
                Keys.onReturnPressed: {
                    clicked();
                }
            }
            
            Button {
                id: gamingCatButton
                text: "Gaming"
                Layout.fillWidth: true
                Layout.fillHeight: true
                KeyNavigation.right: polCatButton
                KeyNavigation.left: searchCatButton
                KeyNavigation.down: videoQueryBox
                
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: gamingCatButton.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                }
                
                onClicked: {
                    categoryLayout.currentIndex = 4
                }
                Keys.onReturnPressed: {
                    clicked();
                }
            }
            
            Button {
                id: searchCatButton
                text: "Search"
                Layout.fillWidth: true
                Layout.fillHeight: true
                KeyNavigation.left: gamingCatButton
                KeyNavigation.down: videoQueryBox
                
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: searchCatButton.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                }
                
                onClicked: {
                    categoryLayout.currentIndex = 5
                }
                Keys.onReturnPressed: {
                    clicked();
                }
            }
        }
        
        RowLayout {
            id: searchVideoInputBox
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.maximumHeight: Kirigami.Units.gridUnit * 3
            z: 120

            TextField {
                id: videoQueryBox
                Layout.fillWidth: true
                Layout.fillHeight: true
                onAccepted: {
                    searchYoutubeLiveResults(videoQueryBox.text)
                }
                
                KeyNavigation.up: newsCatButton
                KeyNavigation.down: categoryLayout
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
                KeyNavigation.up: newsCatButton
                KeyNavigation.left: videoQueryBox
                KeyNavigation.down: categoryLayout
            }
        }
                        
        Kirigami.Separator {
            id: sept1
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            z: 100
        }
        
        StackLayout {
            id: categoryLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0
            
            onFocusChanged: {
                if(focus){
                    categoryLayout.itemAt(currentIndex).forceActiveFocus()
                }
            }
            
            CategoryBoxView {
                id: newsCatView
            }
            
            CategoryBoxView {
                id: musicCatView
            }
            
            CategoryBoxView {
                id: techCatView
            }
            
            CategoryBoxView {
                id: polCatView
            }
            
            CategoryBoxView {
                id: gamingCatView
            }
            
            CategoryBoxView  {
                id: searchCatView
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
        categoryLayout.itemAt(categoryLayout.currentIndex).forceActiveFocus()
    }
}

