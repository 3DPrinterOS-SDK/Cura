// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    implicitWidth: parent.width
    height: visible ? UM.Theme.getSize("print_setup_extruder_box").height : 0
    property var printerModel
    property var connectedPrinter: Cura.MachineManager.printerOutputDevices.length >= 1 ? Cura.MachineManager.printerOutputDevices[0] : null

    Rectangle
    {
        color: UM.Theme.getColor("main_background")
        anchors.fill: parent

        Label //Build plate label.
        {
            text: catalog.i18nc("@label", "Chamber")
            font: UM.Theme.getFont("default")
            color: UM.Theme.getColor("text")
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: UM.Theme.getSize("default_margin").width
        }

        Label //Target temperature.
        {
            id: chamberTargetTemperature
            text: printerModel != null ? printerModel.targetChamberTemperature + "°C" : ""
            font: UM.Theme.getFont("default_bold")
            color: UM.Theme.getColor("text_inactive")
            anchors.right: parent.right
            anchors.rightMargin: UM.Theme.getSize("default_margin").width
            anchors.bottom: chamberCurrentTemperature.bottom
        }
        Label //Current temperature.
        {
            id: chamberCurrentTemperature
            text: printerModel != null ? printerModel.chamberTemperature + "°C" : ""
            font: UM.Theme.getFont("large_bold")
            color: UM.Theme.getColor("text")
            anchors.right: chamberTargetTemperature.left
            anchors.top: parent.top
            anchors.margins: UM.Theme.getSize("default_margin").width
        }
    }
}