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
import QtQuick.Controls 2.2
import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
    id: delegate

    property var videoListModel: sessionData.videoListBlob.videoList
    property var currentSongUrl: sessionData.currenturl
    property var currenttitle: sessionData.currenttitle
    property Component highlighter: PlasmaComponents.Highlight{}
    property Component emptyHighlighter: Item{}

    skillBackgroundSource: "https://source.unsplash.com/weekly?music"
    
    onVideoListModelChanged: {
        leftSearchView.forceLayout()
    }

    Keys.onBackPressed: {
        parent.parent.parent.currentIndex--
        parent.parent.parent.currentItem.contentItem.forceActiveFocus()
    }
    
    ColumnLayout {
        id: recentlyPlayerColumn
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            id: watchItemList
            text: "Watch More.."
            level: 3
        }
        
        Kirigami.Separator {
            id: sept2
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            z: 100
        }
        
        ListView {
            id: leftSearchView
            keyNavigationEnabled: true
            highlight: focus ? highlighter : emptyHighlighter
            model: videoListModel
            focus: false
            interactive: true
            bottomMargin: delegate.controlBarItem.height + Kirigami.Units.largeSpacing
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing
            currentIndex: 0
            highlightRangeMode: ListView.StrictlyEnforceRange
            snapMode: ListView.SnapToItem
            
            delegate: Control {
                width: parent.width
                height: Kirigami.Units.gridUnit * 4
                
                background: PlasmaCore.FrameSvgItem {
                id: frame
                anchors {
                    fill: parent
                }
                imagePath: "widgets/background"
                
                width: parent.width
                height: parent.height
                opacity: 0.9
                }

                
                contentItem: Item {
                    width: parent.width
                    height: parent.height

                    RowLayout {
                        id: delegateItem
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.largeSpacing

                        Image {
                            id: videoImage
                            source: modelData.videoImage
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                            Layout.alignment: Qt.AlignHCenter
                            fillMode: Image.Stretch
                        }

                        Label {
                            id: videoLabel
                            Layout.fillWidth: true
                            text: modelData.videoTitle
                            wrapMode: Text.WordWrap
                        }
                    }
                }
                             
                Keys.onReturnPressed: {
                    Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: modelData.videoID, vidTitle: modelData.videoTitle})
                }
            }
        }
    }
    
    Component.onCompleted: {
        leftSearchView.forceActiveFocus()
    }
}

