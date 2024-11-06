// Copyright (c) 2022 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick
import QtQuick.Controls 2.4

import UM 1.5 as UM
import Cura 1.1 as Cura

import "../Menus"
import "../Dialogs"

Item
{
    id: menu
    width: parent.width
    height: applicationMenu.height

    MenuBar
    {
        id: applicationMenu
        width: parent.width
        height: UM.Theme.getSize("context_menu").height

        background: Rectangle {
            // color: UM.Theme.getColor("background_1")
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#181818" }
                GradientStop { position: 0.32; color: "#181818" }
                GradientStop { position: 0.54; color: Qt.rgba(3/255, 56/255, 74/255, 0.82) }
                GradientStop { position: 0.77; color: Qt.rgba(114/255, 35/255, 75/255, 0.87) }
                GradientStop { position: 0.90; color: Qt.rgba(0, 0, 0, 0.76) }
                GradientStop { position: 1.0; color: "#222222" }
            }
        }

        delegate: MenuBarItem
        {
            id: menuBarItem

            contentItem: UM.Label
            {
                text: menuBarItem.text.replace(new RegExp("&([A-Za-z])"), function (match, character)
                {
                    return `<u>${character}</u>`
                })
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
            leftPadding: UM.Theme.getSize("default_margin").width
            rightPadding: UM.Theme.getSize("default_margin").width
            background: Rectangle
            {

                color: menuBarItem.highlighted ? UM.Theme.getColor("background_2") : "transparent"
            }
        }

        FileMenu {}
        EditMenu {}
        ViewMenu {}
        SettingsMenu
        {
            //On MacOS, don't translate the "Settings" word.
            //Qt moves the "settings" entry to a different place, and if it got renamed can't find it again when it
            //attempts to delete the item upon closing the application, causing a crash.
            //In the new location, these items are translated automatically according to the system's language.
            //For more information, see:
            //- https://doc.qt.io/qt-5/macos-issues.html#menu-bar
            //- https://doc.qt.io/qt-5/qmenubar.html#qmenubar-as-a-global-menu-bar
            title: (Qt.platform.os == "osx") ? "&Settings" : catalog.i18nc("@title:menu menubar:toplevel", "&Settings")
        }
        ExtensionMenu { id: extensionMenu }
        PreferencesMenu {}
        HelpMenu {}
    }



    // ###############################################################################################
    // Definition of other components that are linked to the menus
    // ###############################################################################################

    WorkspaceSummaryDialog
    {
        id: saveWorkspaceDialog
        property var args
        onAccepted: UM.OutputDeviceManager.requestWriteToDevice("local_file", PrintInformation.jobName, args)
    }

    Cura.MessageDialog
    {
        id: newProjectDialog

        title: catalog.i18nc("@title:window", "New project")
        text: catalog.i18nc("@info:question", "Are you sure you want to start a new project? This will clear the build plate and any unsaved settings.")
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted:
        {
            CuraApplication.resetWorkspace()
            Cura.Actions.resetProfile.trigger()
            UM.Controller.setActiveStage("PrepareStage")
        }
    }

    // ###############################################################################################
    // Definition of all the connections
    // ###############################################################################################

    Connections
    {
        target: Cura.Actions.newProject
        function onTriggered()
        {
            if(Printer.platformActivity || Cura.MachineManager.hasUserSettings)
            {
                newProjectDialog.visible = true
            }
        }
    }

    // show the Toolbox
    Connections
    {
        target: Cura.Actions.browsePackages
        function onTriggered()
        {
            extensionMenu.extensionModel.callExtensionMethod("Marketplace", "show")
        }
    }

    // Show the Marketplace dialog at the materials tab
    Connections
    {
        target: Cura.Actions.marketplaceMaterials
        function onTriggered()
        {
            extensionMenu.extensionModel.callExtensionMethod("Marketplace", "show")
            extensionMenu.extensionModel.callExtensionMethod("Marketplace", "setVisibleTabToMaterials")
        }
    }
}
