// Copyright (c) 2021 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.15

import UM 1.4 as UM
import Cura 1.1 as Cura

Popup
{
    id: applicationSwitcherPopup

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    opacity: opened ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 100 } }
    padding: UM.Theme.getSize("wide_margin").width

    contentItem: Grid
    {
        id: ultimakerPlatformLinksGrid
        columns: 3
        spacing: UM.Theme.getSize("default_margin").width

        Repeater
        {
            model:
            [
                {
                    displayName: "Material Lab", //Not translated, since it's a brand name.
                    thumbnail: UM.Theme.getIcon("Shop", "high"),
                    description: catalog.i18nc("@tooltip:button", "Material lab."),
                    link: "https://www.lugolabs.xyz/material_lab",
                    DFAccessRequired: false
                },
                {
                    displayName: "Modeling Lab", //Not translated, since it's a brand name.
                    thumbnail: UM.Theme.getIcon("Knowledge"),
                    description: catalog.i18nc("@tooltip:button", "Modeling lab."),
                    link: "https://www.lugolabs.xyz/modeling_lab",
                    DFAccessRequired: false
                },
                {
                    displayName: catalog.i18nc("@label:button", "Printing Tips"),
                    thumbnail: UM.Theme.getIcon("Help", "high"),
                    description: catalog.i18nc("@tooltip:button", "Printing tips."),
                    link: "https://www.lugolabs.xyz/printing_tips",
                    DFAccessRequired: false
                },
                {
                    displayName: catalog.i18nc("@label:button", "User Support"),
                    thumbnail: UM.Theme.getIcon("Speak", "high"),
                    description: catalog.i18nc("@tooltip:button", "User support."),
                    link: "https://www.lugolabs.xyz/user_support",
                    DFAccessRequired: false
                },
                {
                    displayName: catalog.i18nc("@label:button", "Maintenance"),
                    thumbnail: UM.Theme.getIcon("Bug", "high"),
                    description: catalog.i18nc("@tooltip:button", "Maintenance."),
                    link: "https://www.lugolabs.xyz/maintenance",
                    DFAccessRequired: false
                },
                {
                    displayName: "LUGOlabs Online", //Not translated, since it's a URL.
                    thumbnail: UM.Theme.getIcon("Browser"),
                    description: catalog.i18nc("@tooltip:button", "LUGOlabs Online."),
                    link: "https://www.lugolabs.xyz/online",
                    DFAccessRequired: false
                }
            ]

            delegate: ApplicationButton
            {
                displayName: modelData.displayName
                iconSource: modelData.thumbnail
                tooltipText: modelData.description
                isExternalLink: true
                visible: modelData.DFAccessRequired ? Cura.API.account.isLoggedIn & Cura.API.account.additionalRights["df_access"] : true

                onClicked: Qt.openUrlExternally(modelData.link)
            }
        }
    }

    background: UM.PointingRectangle
    {
        color: UM.Theme.getColor("tool_panel_background")
        borderColor: UM.Theme.getColor("lining")
        borderWidth: UM.Theme.getSize("default_lining").width

        // Move the target by the default margin so that the arrow isn't drawn exactly on the corner
        target: Qt.point(width - UM.Theme.getSize("default_margin").width - (applicationSwitcherButton.width / 2), -10)

        arrowSize: UM.Theme.getSize("default_arrow").width
    }
}
