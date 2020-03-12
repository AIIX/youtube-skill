import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.11 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents
import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
    id: logoLoadingPage
    property string loadingStatus: sessionData.loadingStatus
    
    onLoadingStatusChanged: {
        loadingStatusArea.text = "Loading: " + loadingStatus
    }

    Control {
        id: statusArea
        anchors.fill: parent
        
        background: Image {
            source: "./youtube-logo-page.jpg"
        }
        
        contentItem: Item {
            AnimatedImage {
                id: busyIndicatorComponent
                anchors.bottom: parent.bottom
                anchors.bottomMargin: statusArea.height / 6
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -Kirigami.Units.gridUnit * 6
                width: Kirigami.Units.iconSizes.smallMedium
                height: Kirigami.Units.iconSizes.smallMedium
                playing: true
                source: "./images/spinner.gif"
            }
            
            Kirigami.Heading {
                id: loadingStatusArea
                anchors.left: busyIndicatorComponent.right
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.verticalCenter: busyIndicatorComponent.verticalCenter
                level: 2
                text: "Loading..."
            }
        }
    }
}
