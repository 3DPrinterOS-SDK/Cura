// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura

//
//  Adhesion
//
Item
{
    id: enableAdhesionRow
    height: childrenRect.height

    property real labelColumnWidth: Math.round(width / 3)
    property var curaRecommendedMode: Cura.RecommendedMode {}

    Cura.IconWithText
    {
        id: enableAdhesionRowTitle
        anchors.top: parent.top
        anchors.left: parent.left
        source: UM.Theme.getIcon("Adhesion")
        text: catalog.i18nc("@label", "Brim")
        font: UM.Theme.getFont("medium")
        width: labelColumnWidth
        iconSize: UM.Theme.getSize("medium_button_icon").width
    }

    Item
    {
        id: enableAdhesionContainer
        height: enableAdhesionRowTitle.height

        anchors
        {
            left: enableAdhesionRowTitle.right
            right: parent.right
            verticalCenter: enableAdhesionRowTitle.verticalCenter
        }

        CheckBox
        {
            id: enableAdhesionCheckBox
            anchors.verticalCenter: parent.verticalCenter

            property alias _hovered: adhesionMouseArea.containsMouse

            //: Setting enable printing build-plate adhesion helper checkbox
            style: UM.Theme.styles.checkbox
            enabled: recommendedPrintSetup.settingsEnabled

            visible: platformAdhesionType.properties.enabled == "True"
            checked: platformAdhesionType.properties.value != "skirt" && platformAdhesionType.properties.value != "none"

            MouseArea
            {
                id: adhesionMouseArea
                anchors.fill: parent
                hoverEnabled: true

                onClicked:
                {
                    curaRecommendedMode.setAdhesion(!parent.checked)
                }

                onEntered:
                {
                    base.showTooltip(enableAdhesionCheckBox, Qt.point(-enableAdhesionContainer.x - UM.Theme.getSize("thick_margin").width, 0),
                        catalog.i18nc("@label", "Enable printing a brim or raft. This will add a flat area around or under your object which is easy to cut off afterwards."));
                }
                onExited: base.hideTooltip()
            }
        }

        Text {
            id: adhDesc
            anchors {
                left: enableAdhesionCheckBox.right
                leftMargin: UM.Theme.getSize("narrow_margin").width
                verticalCenter: parent.verticalCenter
            }
//                width: labelColumnWidth - UM.Theme.getSize("medium_button_icon").width - UM.Theme.getSize("narrow_margin").width
            font: UM.Theme.getFont("small")
            text: catalog.i18nc("@label", "Stronger bed adhesion")
        }
    }

    Item
    {
        id: fuzzySkinContainer
        height: visible ? enableFuzzySkin.height : 0
        visible: Cura.MachineManager.activeIntentCategory === "visual"
        anchors {
            top: enableAdhesionContainer.bottom
            topMargin: UM.Theme.getSize("narrow_margin").width
            left: parent.left
        }

        Cura.IconWithText
        {
            id: enableFuzzySkinText
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: parent.visible
            source: UM.Theme.getIcon("FuzzySkin")
            text: catalog.i18nc("@label", "Fuzzy Skin")
            font: UM.Theme.getFont("medium")
            width: labelColumnWidth
            iconSize: UM.Theme.getSize("medium_button_icon").width
        }

        Item
        {
            id: enableFuzzySkin
            height: visible ? enableFuzzySkinCheckBox.height : 0
            visible: Cura.MachineManager.activeIntentCategory === "visual"
            anchors
            {
                left: enableFuzzySkinText.right
                right: parent.right
                verticalCenter: fuzzySkinContainer.verticalCenter
            }

            CheckBox
            {
                id: enableFuzzySkinCheckBox
                anchors.verticalCenter: parent.verticalCenter

                property alias _hovered: enableFuzzySkinMouseArea.containsMouse

                style: UM.Theme.styles.checkbox
                enabled: recommendedPrintSetup.settingsEnabled

                checked: fuzzySkinValue.properties.value == "True"

                MouseArea
                {
                    id: enableFuzzySkinMouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: fuzzySkinValue.setPropertyValue("value", fuzzySkinValue.properties.value != "True")

                    onEntered:
                    {
                        base.showTooltip(enableFuzzySkinCheckBox, Qt.point(-enableFuzzySkinCheckBox.x - UM.Theme.getSize("thick_margin").width, 0),
                            catalog.i18nc("@label", fuzzySkinValue.properties.description))
                    }
                    onExited: base.hideTooltip()
                }
            }

            Text {
                id: fuzzyDesc
                anchors {
                    left: enableFuzzySkinCheckBox.right
                    leftMargin: UM.Theme.getSize("narrow_margin").width
                    verticalCenter: parent.verticalCenter
                }
//                width: labelColumnWidth - UM.Theme.getSize("medium_button_icon").width - UM.Theme.getSize("narrow_margin").width
                font: UM.Theme.getFont("small")
                text: catalog.i18nc("@label", "Rough surface")
            }
        }
    }

    Item
    {
        id: draftShieldContainer
        height: visible ? draftShieldEnabledItem.height : 0
        visible: Cura.MachineManager.activeIntentCategory === "hightemp"
        anchors {
            top: enableAdhesionContainer.bottom
            topMargin: UM.Theme.getSize("narrow_margin").width
            left: parent.left
        }

        Cura.IconWithText
        {
            id: draftShieldText
            visible: parent.visible
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            source: UM.Theme.getIcon("DraftShield")
            text: catalog.i18nc("@label", "Draft Shield")
            font: UM.Theme.getFont("medium")
            width: labelColumnWidth
            iconSize: UM.Theme.getSize("medium_button_icon").width
        }

//        Text {
//            id: draftShieldText
//            anchors {
//                top: parent.top
//                left: parent.left
//                leftMargin: UM.Theme.getSize("medium_button_icon").width + UM.Theme.getSize("narrow_margin").width
//                verticalCenter: parent.verticalCenter
//            }
//            width: labelColumnWidth - UM.Theme.getSize("medium_button_icon").width - UM.Theme.getSize("narrow_margin").width
//            font: UM.Theme.getFont("medium")
//            text: catalog.i18nc("@label", "Draft Shield")
//        }

        Item
        {
            id: draftShieldEnabledItem
            height: visible ? draftShieldCheckBox.height : 0
            visible: Cura.MachineManager.activeIntentCategory === "hightemp"
            anchors
            {
                left: draftShieldText.right
                right: parent.right
                verticalCenter: draftShieldContainer.verticalCenter
            }

            CheckBox
            {
                id: draftShieldCheckBox
                anchors.verticalCenter: parent.verticalCenter

                property alias _hovered: draftShieldMouseArea.containsMouse

                style: UM.Theme.styles.checkbox
                enabled: recommendedPrintSetup.settingsEnabled

                checked: draftShieldEnabled.properties.value == "True"

                MouseArea
                {
                    id: draftShieldMouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: draftShieldEnabled.setPropertyValue("value", draftShieldEnabled.properties.value != "True")

                    onEntered:
                    {
                        base.showTooltip(draftShieldCheckBox, Qt.point(-draftShieldCheckBox.x - UM.Theme.getSize("thick_margin").width, 0),
                            catalog.i18nc("@label", draftShieldEnabled.properties.description))
                    }
                    onExited: base.hideTooltip()
                }
            }

            Text {
                id: draftShieldDescText
                anchors {
                    left: draftShieldCheckBox.right
                    leftMargin: UM.Theme.getSize("narrow_margin").width
                    verticalCenter: parent.verticalCenter
                }
//                width: labelColumnWidth - UM.Theme.getSize("medium_button_icon").width - UM.Theme.getSize("narrow_margin").width
                font: UM.Theme.getFont("small")
                text: catalog.i18nc("@label", "Prevent heavy shrinkage")
            }
        }
    }

    UM.SettingPropertyProvider
    {
        id: platformAdhesionType
        containerStack: Cura.MachineManager.activeMachine
        removeUnusedValue: false //Doesn't work with settings that are resolved.
        key: "adhesion_type"
        watchedProperties: [ "value", "resolve", "enabled" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: fuzzySkinValue
        containerStack: Cura.MachineManager.activeStack
        removeUnusedValue: false //Doesn't work with settings that are resolved.
        key: "magic_fuzzy_skin_enabled"
        watchedProperties: [ "value", "description", "enabled" ]
        storeIndex: 0
    }

    UM.SettingPropertyProvider
    {
        id: draftShieldEnabled
        containerStack: Cura.MachineManager.activeMachine
        removeUnusedValue: false //Doesn't work with settings that are resolved.
        key: "draft_shield_enabled"
        watchedProperties: [ "value", "description", "enabled" ]
        storeIndex: 0
    }
}
