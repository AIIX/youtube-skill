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
import org.kde.mycroft.bigscreen 1.0 as BigScreen
import "+mediacenter/views" as Views
import "+mediacenter/delegates" as Delegates

Item {
    property var recentHomeModel: sessionData.recentHomeListBlob.recentList
    property var historyListModel: sessionData.recentListBlob.recentList
    property var newsListModel: sessionData.newsListBlob.videoList
    property var musicListModel: sessionData.musicListBlob.videoList
    property var techListModel: sessionData.techListBlob.videoList
    property var polListModel: sessionData.polListBlob.videoList
    property var gamingListModel: sessionData.gamingListBlob.videoList
    property var searchListModel: sessionData.searchListBlob.videoList
    property var trendListModel: sessionData.trendListBlob.videoList
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    onFocusChanged: {
        if(focus && recentListView.visible){
            recentListView.forceActiveFocus()
        } else if (focus && !recentListView.visible) {
            trendListView.forceActiveFocus()
        }
    }
    
    onNewsListModelChanged: {
       newsListView.view.forceLayout()
    }
    onMusicListModelChanged: {
       musicListView.view.forceLayout()
    }
    onTechListModelChanged: {
       techListView.view.forceLayout()
    }
    onPolListModelChanged: {
       polListView.view.forceLayout()
    }
    onGamingListModelChanged: {
       gamingListView.view.forceLayout()
    }
    onRecentHomeModelChanged: {
        recentListView.view.forceLayout()
    }
    onTrendListModelChanged: {
        trendListView.view.forceLayout()
    }
    
    ColumnLayout {
        id: contentLayout
        anchors {
            left: parent.left
            right: parent.right
            margins: Kirigami.Units.largeSpacing * 3
        }
        property Item currentSection
        readonly property int rowHeight: recentListView.cellWidth / 1.8 + Kirigami.Units.gridUnit * 7
        y: currentSection ? -currentSection.y : 0

        Behavior on y {
            NumberAnimation {
                duration: Kirigami.Units.longDuration * 2
                easing.type: Easing.InOutQuad
            }
        }

        spacing: Kirigami.Units.largeSpacing * 4

        BigScreen.TileView {
            id: recentListView
            focus: true
            model: recentHomeModel
            title: "Recently Watched"
            cellWidth: parent.width / 4
            delegate: Delegates.ListVideoCard{}
            visible: recentListView.view.count > 0 ? 1 : 0
            onActiveFocusChanged: {
                if(activeFocus){
                    contentLayout.currentSection = recentListView
                }
            }

            implicitHeight: contentLayout.rowHeight
            navigationUp: homeCatButton
            navigationDown: trendListView
        }

        BigScreen.TileView {
            id: trendListView
            focus: false
            model: trendListModel
            title: "Trending"
            cellWidth: parent.width / 4
            delegate: Delegates.ListVideoCard{}
            onActiveFocusChanged: {
                if(activeFocus){
                    contentLayout.currentSection = trendListView
                }
            }

            implicitHeight: contentLayout.rowHeight
            navigationUp: recentListView.visible ? recentListView : homeCatButton
            navigationDown: newsListView
        }

        BigScreen.TileView {
            id: newsListView
            focus: false
            model: newsListModel
            title: "News"
            cellWidth: parent.width / 4
            delegate: Delegates.ListVideoCard{}
            onActiveFocusChanged: {
                if(activeFocus){
                    contentLayout.currentSection = newsListView
                }
            }
            
            implicitHeight: contentLayout.rowHeight
            navigationUp: trendListView
            navigationDown: musicListView
        }
        
        BigScreen.TileView {
            id: musicListView
            focus: false
            model: musicListModel
            title: "Music"
            cellWidth: parent.width / 4
            delegate: Delegates.ListVideoCard{}
            onActiveFocusChanged: {
                if(activeFocus){
                    contentLayout.currentSection = musicListView
                }
            }

            implicitHeight: contentLayout.rowHeight
            navigationUp: newsListView
            navigationDown: techListView
        }
        
        BigScreen.TileView {
            id: techListView
            focus: false
            model: techListModel
            title: "Technology"
            cellWidth: parent.width / 4
            delegate: Delegates.ListVideoCard{}
            onActiveFocusChanged: {
                if(activeFocus){
                    contentLayout.currentSection = techListView
                }
            }

            implicitHeight: contentLayout.rowHeight
            navigationUp: musicListView
            navigationDown: polListView
        }
        
        BigScreen.TileView {
            id: polListView
            focus: false
            model: polListModel
            title: "Politics"
            cellWidth: parent.width / 4
            delegate: Delegates.ListVideoCard{}
            onActiveFocusChanged: {
                if(activeFocus){
                    contentLayout.currentSection = polListView
                }
            }

            implicitHeight: contentLayout.rowHeight
            navigationUp: techListView
            navigationDown: gamingListView
        }
        
        BigScreen.TileView {
            id: gamingListView
            focus: false
            model: gamingListModel
            title: "Gaming"
            cellWidth: parent.width / 4
            delegate: Delegates.ListVideoCard{}
            onActiveFocusChanged: {
                if(activeFocus){
                    contentLayout.currentSection = gamingListView
                }
            }

            implicitHeight: contentLayout.rowHeight
            navigationUp: polListView
            navigationDown: recentListView.visible ? recentListView : trendListView
        }
    }
}
