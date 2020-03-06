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
    
    topPadding: 0
    
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
        homeCatView.model = newsListModel
        console.log(JSON.stringify(newsListModel))
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
        
        Rectangle {
            color: Qt.rgba(0, 0, 0, 0.8)
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3 
            Layout.maximumHeight: Kirigami.Units.gridUnit * 4
            
            RowLayout {
                id: categoryRepeater
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.gridUnit
                anchors.rightMargin: Kirigami.Units.gridUnit
                
                Button {
                    id: homeCatButton
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    KeyNavigation.right: newsCatButton
                    KeyNavigation.down: videoQueryBox
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: homeCatButton.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    }
                    
                    contentItem: Item {
                        Kirigami.Heading {
                            id: contentHome
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            maximumLineCount: 1
                            text: "Home"
                            level: 1
                        }
                        
                        Kirigami.Separator {
                            id: contentHomeSept
                            anchors.top: contentHome.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            color: Kirigami.Theme.highlightColor
                            width: parent.width
                            height: 2
                            opacity: categoryLayout.currentIndex == 0 ? 1 : 0
                        }
                    }
                    
                    onClicked: {}
                    Keys.onReturnPressed: {}
                }
                
                Button {
                    id: newsCatButton
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    KeyNavigation.right: musicCatButton
                    KeyNavigation.down: videoQueryBox
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: newsCatButton.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    }
                    
                    contentItem: Item {
                        Kirigami.Heading {
                            id: contentNews
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            maximumLineCount: 1
                            text: "News"
                            level: 1
                        }
                        
                        Kirigami.Separator {
                            id: contentNewsSept
                            anchors.top: contentNews.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            color: Kirigami.Theme.highlightColor
                            width: parent.width
                            height: 2
                            opacity: categoryLayout.currentIndex == 1 ? 1 : 0
                        }
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
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    KeyNavigation.right: techCatButton
                    KeyNavigation.left: newsCatButton
                    KeyNavigation.down: videoQueryBox
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: musicCatButton.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    }
                    
                    contentItem: Item {
                        Kirigami.Heading {
                            id: contentMusic
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            maximumLineCount: 1
                            text: "Music"
                            level: 1
                        }
                        
                        Kirigami.Separator {
                            id: contentMusicSept
                            anchors.top: contentMusic.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            color: Kirigami.Theme.highlightColor
                            width: parent.width
                            height: 2
                            opacity: categoryLayout.currentIndex == 2 ? 1 : 0
                        }
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
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    KeyNavigation.right: polCatButton
                    KeyNavigation.left: musicCatButton
                    KeyNavigation.down: videoQueryBox
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: techCatButton.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    }
                    
                    contentItem: Item {
                        Kirigami.Heading {
                            id: contentTech
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            maximumLineCount: 1
                            text: "Technology"
                            level: 1
                        }
                        
                        Kirigami.Separator {
                            id: contentTechSept
                            anchors.top: contentTech.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            color: Kirigami.Theme.highlightColor
                            width: parent.width
                            height: 2
                            opacity: categoryLayout.currentIndex == 3 ? 1 : 0
                        }
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
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    KeyNavigation.right: gamingCatButton
                    KeyNavigation.left: techCatButton
                    KeyNavigation.down: videoQueryBox
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: polCatButton.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    }
                    
                    contentItem: Item {
                        Kirigami.Heading {
                            id: contentPol
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            maximumLineCount: 1
                            text: "Politics"
                            level: 1
                        }
                        
                        Kirigami.Separator {
                            id: contentPolSept
                            anchors.top: contentPol.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            color: Kirigami.Theme.highlightColor
                            width: parent.width
                            height: 2
                            opacity: categoryLayout.currentIndex == 4 ? 1 : 0
                        }
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
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    KeyNavigation.right: videoQueryBox
                    KeyNavigation.left: polCatButton
                    KeyNavigation.down: videoQueryBox
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: gamingCatButton.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    }
                    
                    contentItem: Item {
                        Kirigami.Heading {
                            id: contentGaming
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            maximumLineCount: 1
                            text: "Gaming"
                            level: 1
                        }
                        
                        Kirigami.Separator {
                            id: contentGamingSept
                            anchors.top: contentGaming.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            color: Kirigami.Theme.highlightColor
                            width: parent.width
                            height: 2
                            opacity: categoryLayout.currentIndex == 5 ? 1 : 0
                        }
                    }
                    
                    onClicked: {
                        categoryLayout.currentIndex = 4
                    }
                    Keys.onReturnPressed: {
                        clicked();
                    }
                }
                
//                 Button {
//                     id: searchCatButton
//                     text: "Search"
//                     Layout.fillWidth: true
//                     Layout.fillHeight: true
//                     KeyNavigation.left: gamingCatButton
//                     KeyNavigation.down: videoQueryBox
//                     
//                     background: Rectangle {
//                         Kirigami.Theme.colorSet: Kirigami.Theme.Button
//                         color: searchCatButton.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
//                     }
//                     
//                     onClicked: {
//                         categoryLayout.currentIndex = 5
//                     }
//                     Keys.onReturnPressed: {
//                         clicked();
//                     }
//                 }

                TextField {
                    id: videoQueryBox
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                    placeholderText: "Search here..."
                    Layout.fillHeight: true
                    onAccepted: {
                        searchYoutubeLiveResults(videoQueryBox.text)
                    }
                    
                    KeyNavigation.up: newsCatButton
                    KeyNavigation.down: categoryLayout
                    KeyNavigation.right: searchVideoQuery
                }

                Kirigami.Icon {
                    id: searchVideoQuery
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    Layout.fillHeight: true
                    source: "search"                    
//                     onClicked: {
//                         searchYoutubeLiveResults(videoQueryBox.text)
//                     }
                    KeyNavigation.up: newsCatButton
                    KeyNavigation.left: videoQueryBox
                    KeyNavigation.down: categoryLayout
                }
            }
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
            
            CategoryBoxHomeView {
                id: homeCatView
            }
            
            CategoryBoxView {
                id: newsCatView
                property string categoryName: "News"
                property bool nextPageAvailable: sessionData.newsNextAvailable
            }
            
            CategoryBoxView {
                id: musicCatView
                property string categoryName: "Music"
                property bool nextPageAvailable: sessionData.musicNextAvailable
            }
            
            CategoryBoxView {
                id: techCatView
                property string categoryName: "Technology"
                property bool nextPageAvailable: sessionData.techNextAvailable
            }
            
            CategoryBoxView {
                id: polCatView
                property string categoryName: "Politics"
                property bool nextPageAvailable: sessionData.polNextAvailable
            }
            
            CategoryBoxView {
                id: gamingCatView
                property string categoryName: "Gaming"
                property bool nextPageAvailable: sessionData.gamingNextAvailable
            }
            
            CategoryBoxView  {
                id: searchCatView
                property string categoryName: "Search"
                property bool nextPageAvailable
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

