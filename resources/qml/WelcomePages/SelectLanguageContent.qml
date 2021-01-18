// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3

import UM 1.3 as UM
import Cura 1.1 as Cura

//
// This component contains the content for the "Choose Language" page of the welcome on-boarding process.
//
Item
{
    UM.I18nCatalog { id: catalog; name: "cura" }

    Row {
        id: btnRow
        anchors.centerIn: parent
        height: parent.height * 0.5
        width: parent.width * 0.9
        spacing: parent.width * 0.1
        Button
        {
            id: ruButton
         //   anchors.left: parent.left
         //   anchors.verticalCenter: parent.verticalCenter

            width: btnRow.width * 0.4
            height: btnRow.height

            text: catalog.i18nc("@button", "Выбрать Русский язык")

            background: Rectangle {
                implicitWidth: 100
                implicitHeight: 40
                color: ruButton.down ? UM.Theme.getColor("primary_button_hover") : (ruButton.hovered  ? UM.Theme.getColor("secondary_button_hover") : UM.Theme.getColor("secondary_button"))
                border.color: "#26282a"
                border.width: 1
                radius: 4
            }

            contentItem: Text {
                width: ruButton.width
                height: ruButton.height
                text: ruButton.text
                font: UM.Theme.getFont("large")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked:
            {
                CuraApplication.setNeedToShowSelectLanguage(false)
                if (UM.Preferences.getValue("general/language") == "ru_RU") {
                    base.showNextPage()
                    return;
                }

                UM.Preferences.setValue("general/language", "ru_RU")
                CuraApplication.restartApplication()
            }
        }

        Button
        {
            id: enButton
            //anchors.right: parent.right
           // anchors.verticalCenter: parent.verticalCenter

            width: btnRow.width * 0.4
            height: btnRow.height

            text: catalog.i18nc("@button", "Select English")

            background: Rectangle {
                implicitWidth: 100
                implicitHeight: 40
                color: enButton.down ? UM.Theme.getColor("primary_button_hover") : (enButton.hovered  ? UM.Theme.getColor("secondary_button_hover") : UM.Theme.getColor("secondary_button"))
                border.color: "#26282a"
                border.width: 1
                radius: 4
            }

            contentItem: Text {
                width: enButton.width
                height: enButton.height
                text: enButton.text
                font: UM.Theme.getFont("large")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked:
            {
                CuraApplication.setNeedToShowSelectLanguage(false)
                if (UM.Preferences.getValue("general/language") == "en_US") {
                    base.showNextPage()
                    return;
                }

                UM.Preferences.setValue("general/language", "en_US")
                CuraApplication.restartApplication()
            }
        }
    }
}
