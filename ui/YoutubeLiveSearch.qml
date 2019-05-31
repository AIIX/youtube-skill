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

import QtQuick 2.4
import QtQuick.Layouts 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.2
import org.kde.kirigami 2.4 as Kirigami

import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
    id: delegate
    property var videoListModel: sessionData.videoListBlob.videoList
    
    skillBackgroundSource: sessionData.bgImage ? "https://source.unsplash.com/1920x1080/?+" + sessionData.bgImage : "https://source.unsplash.com/1920x1080/?+music"

    function searchYoutubeLiveResults(query){
        triggerGuiEvent("YoutubeSkill.SearchLive", {"Query": query})
    }
    
    onVideoListModelChanged: {
        videoListView.model = videoListModel
    }

    RowLayout {
        id: searchVideoInputBox
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Kirigami.Units.gridUnit * 3

        TextField {
            id: videoQueryBox
            Layout.fillWidth: true
            Layout.fillHeight: true
            onAccepted: {
                searchYoutubeLiveResults(videoQueryBox.text)
            }
        }

        Button {
            id: searchVideoQuery
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
            text: "Search"
            Layout.fillHeight: true
            onClicked: {
                searchYoutubeLiveResults(videoQueryBox.text)
            }
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

    Kirigami.CardsGridView {
        id: videoListView
        anchors.top: sept1.bottom
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        maximumColumnWidth: Kirigami.Units.gridUnit * 12
        cellHeight: Kirigami.Units.gridUnit * 15
        bottomMargin: Kirigami.Units.largeSpacing
        visible: true
        enabled: true
        clip: true

        delegate: Kirigami.AbstractCard {
            showClickFeedback: true
            Layout.fillWidth: true
            implicitHeight: delegateItem.implicitHeight + Kirigami.Units.largeSpacing * 3
            contentItem: Item {
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight

                ColumnLayout {
                    id: delegateItem
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    spacing: Kirigami.Units.largeSpacing

                    Image {
                        id: videoImage
                        source: modelData.videoImage
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Layout.fillWidth: true
                        fillMode: Image.PreserveAspectCrop
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                        color: Kirigami.Theme.linkColor
                    }

                    Label {
                        id: videoLabel
                        Layout.fillWidth: true
                        text: modelData.videoTitle
                        wrapMode: Text.WordWrap
                        Component.onCompleted: {
                            console.log(modelData.videoTitle)
                        }
                    }
                }
            }
            onClicked: {
                Mycroft.MycroftController.sendRequest("aiix.youtube-skill.playvideo_id", {vidID: modelData.videoID, vidTitle: modelData.videoTitle})
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
                onClicked: {
                    triggerGuiEvent("YoutubeSkill.PreviousPage", {})
                }
            }
            
            Button {
                id: nextButton
                text: "Next Page"
                enabled: sessionData.nextAvailable
                visible: sessionData.nextAvailable
                Layout.preferredWidth: previousButton.visible ? parent.width / 2 : parent.width
                Layout.fillHeight: true
                icon.name: "go-next-symbolic"
                onClicked: {
                    triggerGuiEvent("YoutubeSkill.NextPage", {})
                }
            }
        }
    }
}

