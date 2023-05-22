// Copyright (c) 2020 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls 2.3 as Controls2

import UM 1.2 as UM
import Cura 1.0 as Cura


//
//  Dual setting
//
Item
{
    id: dualSettingsRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)

    visible: primeTowerEnabled.properties.enabled == "True"

    Cura.IconWithText
    {
        id: dualSettingsRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("DualExtrusion")
        text: catalog.i18nc("@label", "Dual Setting")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width
    }

    Item
    {
        id: primeTowerItem
        height: enablePrimeTower.height
        anchors {
            top: dualSettingsRowTitle.bottom
            topMargin: UM.Theme.getSize("narrow_margin").width
            left: parent.left
        }

        Text {
            id: enablePrimeTowerText
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: UM.Theme.getSize("medium_button_icon").width + UM.Theme.getSize("narrow_margin").width
            }
            width: labelColumnWidth - UM.Theme.getSize("medium_button_icon").width - UM.Theme.getSize("narrow_margin").width
            font: UM.Theme.getFont("medium")
            text: catalog.i18nc("@label", "Prime Tower")
        }

        Item
        {
            id: enablePrimeTower
            height: enablePrimeTowerCheckBox.height

            anchors
            {
                left: enablePrimeTowerText.right
                right: parent.right
                verticalCenter: enablePrimeTowerText.verticalCenter
            }

            CheckBox
            {
                id: enablePrimeTowerCheckBox
                anchors.verticalCenter: parent.verticalCenter

                property alias _hovered: enablePrimeTowerMouseArea.containsMouse

                style: UM.Theme.styles.checkbox
                enabled: recommendedPrintSetup.settingsEnabled

                visible: primeTowerEnabled.properties.enabled == "True"
                checked: primeTowerEnabled.properties.value == "True"

                MouseArea
                {
                    id: enablePrimeTowerMouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: primeTowerEnabled.setPropertyValue("value", primeTowerEnabled.properties.value != "True")

                    onEntered:
                    {
                        base.showTooltip(enablePrimeTowerCheckBox, Qt.point(-enablePrimeTowerCheckBox.x - UM.Theme.getSize("thick_margin").width, 0),
                            catalog.i18nc("@label", "Print a tower next to the print which serves to prime the material after each nozzle switch."))
                    }
                    onExited: base.hideTooltip()
                }
            }

            Text {
                id: primeTowerDesc
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: enablePrimeTowerCheckBox.right
                    leftMargin: UM.Theme.getSize("narrow_margin").width
                }
//                width: labelColumnWidth - UM.Theme.getSize("medium_button_icon").width - UM.Theme.getSize("narrow_margin").width
                font: UM.Theme.getFont("small")
                text: catalog.i18nc("@label", "Use when filaments not fully dry")
            }
        }
    }

    Item
    {
        id: zHopHeightItem

        anchors {
            top: primeTowerItem.bottom
            topMargin: UM.Theme.getSize("narrow_margin").width * 1.25
            left: parent.left
        }

        height: zHopHeightTextField.height

        Text {
            id: zHopHeightText
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: UM.Theme.getSize("medium_button_icon").width + UM.Theme.getSize("narrow_margin").width
            }
            width: labelColumnWidth - UM.Theme.getSize("medium_button_icon").width - UM.Theme.getSize("narrow_margin").width
            font: UM.Theme.getFont("medium")
            text: catalog.i18nc("@label", "Z Hop Height")
        }

        Item {
            id: zHopHeightTextEdit
            height: parent.height
            anchors
            {
                left: zHopHeightText.right
                right: parent.right
                verticalCenter: zHopHeightText.verticalCenter
            }

            TextField
            {
                id: zHopHeightTextField
                anchors.verticalCenter: parent.verticalCenter
                style: UM.Theme.styles.text_field
                validator : RegExpValidator { regExp : /[0-9]+\.[0-9]+/ }
                text: zHopHeightValue.properties.value
                onTextChanged: zHopHeightValue.setPropertyValue("value", zHopHeightTextField.text)
            }
        }
    }


//    property var extruderModel: CuraApplication.getExtrudersModel()



    UM.SettingPropertyProvider
    {
        id: primeTowerEnabled
        containerStack: Cura.MachineManager.activeMachine
        key: "prime_tower_enable"
        watchedProperties: [ "value", "enabled", "description" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: zHopHeightValue
        containerStack: Cura.MachineManager.activeMachine
        key: "retraction_hop"
        watchedProperties: [ "value", "enabled", "description" ]
        storeIndex: 0
    }
}
