// Copyright (c) 2019 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.2

import UM 1.3 as UM
import Cura 1.1 as Cura

//
// This component contains the content for the "Choose Language" page of the welcome on-boarding process.
//
Item
{
    UM.I18nCatalog { id: catalog; name: "cura" }

    Rectangle
    {
        anchors.centerIn: parent
        color: UM.Theme.getColor("main_background")
        width: parent.width * 0.25
        height: parent.height * 0.3

        Column
        {
            width: parent.width * 0.9
            anchors.centerIn: parent
            spacing: parent.width * 0.2

            Text {
                id: headText
                font: UM.Theme.getFont("medium")
                text: catalog.i18nc("@label", "Select language:")
            }

            Item {
                width: parent.width
                height: languageComboBox.height

                ComboBox
                {
                    id: languageComboBox
                    width: parent.width
                    model: ListModel
                    {
                        id: languageList

                        Component.onCompleted: {
							append({ text: "Русский", code: "ru_RU" })
                            append({ text: "English", code: "en_US" })
                        }
                    }

                    currentIndex:
                    {
                        var code = UM.Preferences.getValue("general/language");
                        for(var i = 0; i < languageList.count; ++i)
                        {
                            if(model.get(i).code == code)
                            {
                                return i
                            }
                        }
                    }

                    Component.onCompleted:
                    {
                        // Because ListModel is stupid and does not allow using qsTr() for values.
                        for(var i = 0; i < languageList.count; ++i)
                        {
                            languageList.setProperty(i, "text", catalog.i18n(languageList.get(i).text));
                        }

                        // Glorious hack time. ComboBox does not update the text properly after changing the
                        // model. So change the indices around to force it to update.
                        currentIndex += 1;
                        currentIndex -= 1;
                    }
                }
            }

            Row
            {
                id: btnRow
                spacing: parent.width * 0.05

                Button
                {
                    id: okBtn
                    text: catalog.i18nc("@button", "OK")
                    onClicked: {
                        CuraApplication.setNeedToShowSelectLanguage(false)
                        if (languageList.get(languageComboBox.currentIndex).code === UM.Preferences.getValue("general/language")) {
                            base.showNextPage()
                            return;
                        }

                        UM.Preferences.setValue("general/language", languageList.get(languageComboBox.currentIndex).code)
                        CuraApplication.restartApplication()
                    }
                }

                Button
                {
                    id: exitBtn
                    text: catalog.i18nc("@button", "Exit")
                    onClicked: {
                        CuraApplication.closeApplication()
                    }
                }
            }
        }
    }
    /*
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
    */
}
