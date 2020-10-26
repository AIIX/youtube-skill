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
    property bool busyIndicate: false
    
    fillWidth: true
    
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    skillBackgroundSource: sessionData.bgImage ? "https://source.unsplash.com/weekly?" + sessionData.bgImage : "https://source.unsplash.com/weekly?music"
    
    function highlightActiveCategory(cat){
        switch(cat){
            case "Home":
                historyCatButton.checked = false
                searchCatButton.checked = false
                homeCatButton.checked = true
                break;
            case "History":
                searchCatButton.checked = false
                homeCatButton.checked = false
                historyCatButton.checked = true
                break;
            case "Search":
                homeCatButton.checked = false
                historyCatButton.checked = false
                searchCatButton.checked = true
                break;
        }
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
    
    
    contentItem: ColumnLayout {
        id: colLay1
        
        Rectangle {
            color: Qt.rgba(0, 0, 0, 0.8)
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
                
                TopBarTabButton {
                    id: homeCatButton
                    KeyNavigation.right: historyCatButton
                    KeyNavigation.down: categoryLayout
                    checked: true
                    text: "Home"
                    onClicked: {
                        categoryLayout.pop(categoryLayout.find(function(item) {
    return item.name == "homeCat";}))
                        highlightActiveCategory("Home")
                    }
                }
                
                TopBarTabButton {
                    id: historyCatButton
                    KeyNavigation.left: homeCatButton
                    KeyNavigation.right: searchCatButton
                    KeyNavigation.down: categoryLayout
                    checked: false
                    text: "History"
                    onClicked: {
                        if(categoryLayout.depth >= 2) {
                            categoryLayout.pop(null)
                        }
                        categoryLayout.push(historyCat)
                        highlightActiveCategory("History")
                    }
                }
                
                TopBarTabButton {
                    id: searchCatButton
                    KeyNavigation.left: historyCatButton
                    KeyNavigation.down: categoryLayout
                    checked: false
                    text: "Search"
                    onClicked: {
                        if(categoryLayout.depth >= 2) {
                            categoryLayout.pop(null)
                        }
                        categoryLayout.push(searchCat)
                        highlightActiveCategory("Search")
                    }
                }
            }
        }
        
        Component {
            id: homeCat
            CategoryBoxHomeView {
                id: homeCatView
            }
        }
        
        Component {
            id: historyCat
            CategoryBoxHistoryView {
                id: historyCatView
            }
        }
        
        Component {
            id: searchCat
            CategoryBoxSearchView  {
                id: searchCatView
            }
        }
        
        StackView {
            id: categoryLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Component.onCompleted: {
                categoryLayout.push(homeCat)
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
}

