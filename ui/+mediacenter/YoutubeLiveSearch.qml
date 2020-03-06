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
    property var recentHomeModel: sessionData.recentHomeListBlob.recentList
    property var historyListModel: sessionData.recentListBlob.recentList
    property var newsListModel: sessionData.newsListBlob.videoList
    property var musicListModel: sessionData.musicListBlob.videoList
    property var techListModel: sessionData.techListBlob.videoList
    property var polListModel: sessionData.polListBlob.videoList
    property var gamingListModel: sessionData.gamingListBlob.videoList
    property var searchListModel: sessionData.searchListBlob.videoList
    property var trendListModel: sessionData.trendListBlob.videoList
    property bool busyIndicate: false
    
    fillWidth: true
    
    topPadding: 0
    
    skillBackgroundSource: sessionData.bgImage ? "https://source.unsplash.com/weekly?" + sessionData.bgImage : "https://source.unsplash.com/weekly?music"
        
    Connections {
        target: Mycroft.MycroftController
        onIntentRecevied: {
            if(type == "speak") {
                busyIndicatorPop.close()
                busyIndicate = false
            }
        }
    }
    
    onRecentHomeModelChanged: {
        homeCatView.recentModel = recentHomeModel
    }
    
    onTrendListModelChanged: {
        homeCatView.trendModel = trendListModel
    }
    
    onNewsListModelChanged: {
        homeCatView.newsModel = newsListModel
    }
    
    onMusicListModelChanged: {
        homeCatView.musicModel = musicListModel
    }
    
    onTechListModelChanged: {
        homeCatView.techModel = techListModel
    }
    
    onPolListModelChanged: {
        homeCatView.polModel = polListModel
    }
    
    onGamingListModelChanged: {
        homeCatView.gamingModel = gamingListModel
    }
    
    onHistoryListModelChanged: {
        historyCatView.model = historyListModel
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
            color: Qt.rgba(0, 0, 0, 0.95)
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3 
            Layout.maximumHeight: Kirigami.Units.gridUnit * 4
            z: 100
            
            RowLayout {
                id: categoryRepeater
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: parent.width / 2
                anchors.leftMargin: Kirigami.Units.gridUnit
                anchors.rightMargin: Kirigami.Units.gridUnit
                
                Button {
                    id: homeCatButton
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    KeyNavigation.right: historyCatButton
                    KeyNavigation.down: categoryLayout
                    
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
                    
                    onClicked: {
                        categoryLayout.currentIndex = 0
                    }
                    Keys.onReturnPressed: {
                        clicked()
                    }
                }
                
                Button {
                    id: historyCatButton
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    KeyNavigation.left: homeCatButton
                    KeyNavigation.right: searchCatButton
                    KeyNavigation.down: categoryLayout
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: historyCatButton.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    }
                    
                    contentItem: Item {
                        Kirigami.Heading {
                            id: contentHistory
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            maximumLineCount: 1
                            text: "History"
                            level: 1
                        }
                        
                        Kirigami.Separator {
                            id: contentHistorySept
                            anchors.top: contentHistory.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            color: Kirigami.Theme.highlightColor
                            width: parent.width
                            height: 2
                            opacity: categoryLayout.currentIndex == 1 ? 1 : 0
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
                    id: searchCatButton
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    KeyNavigation.left: historyCatButton
                    KeyNavigation.down: categoryLayout
                    
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: searchCatButton.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                    }
                    
                    contentItem: Item {
                        Kirigami.Heading {
                            id: contentSearch
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            maximumLineCount: 1
                            text: "Search"
                            level: 1
                        }
                        
                        Kirigami.Separator {
                            id: contentSearchSept
                            anchors.top: contentSearch.bottom
                            anchors.topMargin: Kirigami.Units.smallSpacing
                            color: Kirigami.Theme.highlightColor
                            width: parent.width
                            height: 2
                            opacity: categoryLayout.currentIndex == 2 ? 1 : 0
                        }
                    }
                    
                    onClicked: {
                        categoryLayout.currentIndex = 2
                    }
                    Keys.onReturnPressed: {
                        clicked();
                    }
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
            
            CategoryBoxHistoryView {
                id: historyCatView
                property string categoryName: "History"
                property bool nextPageAvailable: sessionData.newsNextAvailable
            }
            
            CategoryBoxSearchView  {
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

