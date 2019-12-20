import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.10 as Kirigami

import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
 id: imageRoot
 
    Image {
        anchors.fill: parent
        source: "./youtube-logo-page.jpg"
    } 
}
