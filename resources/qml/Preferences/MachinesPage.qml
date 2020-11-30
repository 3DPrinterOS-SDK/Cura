// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Window 2.1
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura


UM.ManagementPage
{
    id: base;

    title: catalog.i18nc("@title:tab", "Printers");
    model: Cura.GlobalStacksModel { }

    sectionRole: "discoverySource"

    activeId: Cura.MachineManager.activeMachine !== null ? Cura.MachineManager.activeMachine.id: ""
    activeIndex: activeMachineIndex()

    function activeMachineIndex()
    {
        for(var i = 0; i < model.count; i++)
        {
            if (model.getItem(i).id == base.activeId)
            {
                return i;
            }
        }
        return -1;
    }

    buttons: [
        Button
        {
            id: activateMenuButton
            text: catalog.i18nc("@action:button", "Activate");
            iconName: "list-activate";
            enabled: base.currentItem != null && base.currentItem.id != Cura.MachineManager.activeMaterialId
            onClicked: Cura.MachineManager.setActiveMachine(base.currentItem.id)
        },
        Button
        {
            id: addMenuButton
            text: catalog.i18nc("@action:button", "Add");
            iconName: "list-add";
            onClicked: Cura.Actions.addMachine.trigger()
        },
        Button
        {
            id: removeMenuButton
            text: catalog.i18nc("@action:button", "Remove");
            iconName: "list-remove";
            onClicked: confirmDialog.open();
        },
        Button
        {
            id: renameMenuButton
            text: catalog.i18nc("@action:button", "Rename");
            iconName: "edit-rename";
            enabled: base.currentItem != null && base.currentItem.metadata.group_name == null
            onClicked: renameDialog.open();
        }
    ]

    Item
    {
        visible: base.currentItem != null
        anchors.fill: parent

        Label
        {
            id: machineName
            text: base.currentItem && base.currentItem.name ? base.currentItem.name : ""
            font: UM.Theme.getFont("large_bold")
            width: parent.width
            elide: Text.ElideRight
        }

        Flow
        {
            id: machineActions
            visible: currentItem && currentItem.id == Cura.MachineManager.activeMachine.id
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: machineName.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height

            Repeater
            {
                id: machineActionRepeater
                model: base.currentItem ? Cura.MachineActionManager.getSupportedActions(Cura.MachineManager.getDefinitionByMachineId(base.currentItem.id)) : null

                Item
                {
                    width: Math.round(childrenRect.width + 2 * screenScaleFactor)
                    height: childrenRect.height
                    Button
                    {
                        text: machineActionRepeater.model[index].label
                        onClicked:
                        {
                            var currentItem = machineActionRepeater.model[index]
                            actionDialog.loader.manager = currentItem
                            actionDialog.loader.source = currentItem.qmlPath
                            actionDialog.title = currentItem.label
                            actionDialog.show()
                        }
                    }
                }
            }
        }

        UM.Dialog
        {
            id: actionDialog
            minimumWidth: UM.Theme.getSize("modal_window_minimum").width
            minimumHeight: UM.Theme.getSize("modal_window_minimum").height
            maximumWidth: minimumWidth * 3
            maximumHeight: minimumHeight * 3
            rightButtons: Button
            {
                text: catalog.i18nc("@action:button", "Close")
                iconName: "dialog-close"
                onClicked: actionDialog.reject()
            }
        }

        UM.I18nCatalog { id: catalog; name: "cura"; }

        // Confirmation dialog for removing a profile
        Dialog
        {
            id: confirmDialog

            title: catalog.i18nc("@title:window", "Confirm Remove")
            standardButtons: StandardButton.NoButton
            modality: Qt.ApplicationModal

            ColumnLayout {
                id: column
                width: parent ? parent.width : 100
                Label {
                    text: base.currentItem ? base.currentItem.removalWarning : "";
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    Button{
                        text: "Да"
                        onClicked: {
                            Cura.MachineManager.removeMachine(base.currentItem.id)

                            if (model.count === 1)
                            {
                                Cura.Actions.preferences.trigger()
                                return
                            }
                            if(!base.currentItem)
                            {
                                objectList.currentIndex = activeMachineIndex()
                            }
                            //Force updating currentItem and the details panel
                            objectList.onCurrentIndexChanged() // Reset selection.
                            confirmDialog.close();
                        }
                    }
                    Button{
                        text: "Нет"
                        onClicked: {
                            confirmDialog.close();
                        }
                    }
                }
            }
        }

        UM.RenameDialog
        {
            id: renameDialog;
            object: base.currentItem && base.currentItem.name ? base.currentItem.name : "";
            property var machine_name_validator: Cura.MachineNameValidator { }
            validName: renameDialog.newName.match(renameDialog.machine_name_validator.machineNameRegex) != null;
            onAccepted:
            {
                Cura.MachineManager.renameMachine(base.currentItem.id, newName.trim());
                //Force updating currentItem and the details panel
                objectList.onCurrentIndexChanged()
            }
        }

        Connections
        {
            target: Cura.MachineManager
            onGlobalContainerChanged:
            {
                objectList.currentIndex = activeMachineIndex()
                objectList.onCurrentIndexChanged()
            }
        }

    }
}
