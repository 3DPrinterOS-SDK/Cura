// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    id: recommendedPrintSetup

    height: childrenRect.height + 2 * padding

    property Action configureSettings

    property bool settingsEnabled: Cura.ExtruderManager.activeExtruderStackId || extrudersEnabledCount.properties.value == 1
    property real padding: UM.Theme.getSize("thick_margin").width

    Column
    {
        spacing: UM.Theme.getSize("wide_margin").height

        anchors
        {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: parent.padding
        }

        // TODO
        property real firstColumnWidth: Math.round(width / 3)

        RecommendedQualityProfileSelector
        {
            width: parent.width
            // TODO Create a reusable component with these properties to not define them separately for each component
            labelColumnWidth: parent.firstColumnWidth
        }

        RecommendedInfillDensitySelector
        {
            width: parent.width
            // TODO Create a reusable component with these properties to not define them separately for each component
            labelColumnWidth: parent.firstColumnWidth
        }

        RecommendedSupportSelector
        {
            width: parent.width
            // TODO Create a reusable component with these properties to not define them separately for each component
            labelColumnWidth: parent.firstColumnWidth
        }

        Item
        {
            id: zHopHeightRow
            height: childrenRect.height
            width: parent.width
            visible: extrudersEnabledCount.properties.value == 2
            property real labelColumnWidth: parent.firstColumnWidth

            Label
            {
                id: zHopHeightRowTitle
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: UM.Theme.getSize("default_margin").width * 2.5
                text: catalog.i18nc("@label", "Z Hop Height")
                font: UM.Theme.getFont("medium")
                width: labelColumnWidth
            }

            Item {
                id: zHopHeightTextEdit
                anchors {
                    left: zHopHeightRowTitle.right
                    right: parent.right
                    leftMargin: UM.Theme.getSize("default_margin").width * 2.7
//                    rightMargin: UM.Theme.getSize("default_margin").width * 3.4
                    verticalCenter: parent.verticalCenter
                }
                TextField
                {
                    id: zHopHeightTextField
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    style: UM.Theme.styles.text_field
                    validator : RegExpValidator { regExp : /[0-9]+\.[0-9]+/ }
                    text: zHopHeightValue.properties.value
                    onTextChanged: zHopHeightTextField.setPropertyValue("value", zHopHeightTextField.text)
                }
            }
        }

        RecommendedAdhesionSelector
        {
            width: parent.width
            // TODO Create a reusable component with these properties to not define them separately for each component
            labelColumnWidth: parent.firstColumnWidth
        }
    }

    UM.SettingPropertyProvider
    {
        id: zHopHeightValue
        containerStack: Cura.MachineManager.activeMachine
        key: "retraction_hop"
        watchedProperties: [ "value", "enabled", "description" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: extrudersEnabledCount
        containerStack: Cura.MachineManager.activeMachine
        key: "extruders_enabled_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
