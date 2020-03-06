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
import org.kde.mycroft.bigscreen 1.0 as BigScreen
import "+mediacenter/views" as Views
import "+mediacenter/delegates" as Delegates

Mycroft.Delegate {
    id: delegate
    property var newsListModel: sessionData.newsListBlob.videoList
    
    skillBackgroundSource: sessionData.bgImage ? "https://source.unsplash.com/weekly?" + sessionData.bgImage : "https://source.unsplash.com/weekly?music"
    
    onNewsListModelChanged: {
        videoListView.model = newsListModel
        videoListView.view.forceLayout()
        console.log(JSON.stringify(newsListModel))
    }
    
        ColumnLayout {
        id: contentLayout
        width: parent.width
        property Item currentSection
        y: currentSection ? -currentSection.y : 0
        Behavior on y {
            NumberAnimation {
                duration: Kirigami.Units.longDuration * 2
                easing.type: Easing.InOutQuad
            }
        }
        height: parent.height

    
        Views.ListTileView {
            id: videoListView
            focus: true
            clip: true
            property string currentVideoTitle
            property string currentVideoId
            title: "News"
            currentIndex: 0
            onActiveFocusChanged: {
                if(activeFocus){
                    contentLayout.currentSection = videoListView
                }
            }
            delegate: Delegates.ListVideoCard{}
                            
//             Keys.onReturnPressed: {
//                 busyIndicatorPop.open()
//                 if(focus){
//                     Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: currentVideoId, vidTitle: currentVideoTitle})
//                 }
//             }
                
//             onCurrentItemChanged: {
//                 console.log(videoListView.currentItem.videoTitle)
//             }
        }
    }

}

