// Copyright (c) 2016 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.2 as UM

import Cura 1.0 as Cura

UM.PreferencesPage
{
    title: catalog.i18nc("@title:tab", "Setting Visibility");

    property QtObject settingVisibilityPresetsModel: CuraApplication.getSettingVisibilityPresetsModel()

    property int scrollToIndex: 0

    signal scrollToSection( string key )
    onScrollToSection:
    {
        settingsListView.positionViewAtIndex(definitionsModel.getIndex(key), ListView.Beginning)
    }

    function reset()
    {
        settingVisibilityPresetsModel.setActivePreset("basic")
    }
    resetEnabled: true;

    Item
    {
        id: base;
        anchors.fill: parent;

        CheckBox
        {
            id: toggleVisibleSettings
            anchors
            {
                verticalCenter: filter.verticalCenter;
                left: parent.left;
                leftMargin: UM.Theme.getSize("default_margin").width
            }
            text: catalog.i18nc("@label:textbox", "Check all")
            checkedState:
            {
                if(definitionsModel.visibleCount == definitionsModel.categoryCount)
                {
                    return Qt.Unchecked
                }
                else if(definitionsModel.visibleCount == definitionsModel.count)
                {
                    return Qt.Checked
                }
                else
                {
                    return Qt.PartiallyChecked
                }
            }
            partiallyCheckedEnabled: true

            MouseArea
            {
                anchors.fill: parent;
                onClicked:
                {
                    if(parent.checkedState == Qt.Unchecked || parent.checkedState == Qt.PartiallyChecked)
                    {
                        definitionsModel.setAllExpandedVisible(true)
                    }
                    else
                    {
                        definitionsModel.setAllExpandedVisible(false)
                    }
                }
            }
        }

        TextField
        {
            id: filter;

            anchors
            {
                top: parent.top
                left: toggleVisibleSettings.right
                leftMargin: UM.Theme.getSize("default_margin").width
                right: visibilityPreset.left
                rightMargin: UM.Theme.getSize("default_margin").width
            }

            placeholderText: catalog.i18nc("@label:textbox", "Filter...")

            onTextChanged: definitionsModel.filter = {"i18n_label": "*" + text}
        }

        ComboBox
        {
            id: visibilityPreset
            width: 150 * screenScaleFactor
            anchors
            {
                top: parent.top
                right: parent.right
            }

            model: settingVisibilityPresetsModel.items
            textRole: "name"

            currentIndex:
            {
                var idx = -1;
                for(var i = 0; i < settingVisibilityPresetsModel.items.length; ++i)
                {
                    if(settingVisibilityPresetsModel.items[i].presetId == settingVisibilityPresetsModel.activePreset)
                    {
                        idx = i;
                        break;
                    }
                }
                return idx;
            }

            onActivated:
            {
                var preset_id = settingVisibilityPresetsModel.items[index].presetId
                settingVisibilityPresetsModel.setActivePreset(preset_id)
            }
        }

        ScrollView
        {
            id: scrollView

            frameVisible: true

            anchors
            {
                top: filter.bottom;
                topMargin: UM.Theme.getSize("default_margin").height
                left: parent.left;
                right: parent.right;
                bottom: parent.bottom;
            }
            ListView
            {
                id: settingsListView

                model: UM.SettingDefinitionsModel
                {
                    id: definitionsModel
                    containerId: Cura.MachineManager.activeMachine != null ? Cura.MachineManager.activeMachine.definition.id: ""
                    showAll: true
                    exclude: ["command_line_settings", "machine_width", "machine_depth", "machine_shape", "machine_buildplate_type", "machine_height", "machine_heated_bed",
                     "machine_heated_build_volume", "machine_center_is_zero", "machine_extruder_count", "extruders_enabled_count", "machine_name", "machine_show_variants",
                     "material_guid", "material_diameter", "material_bed_temp_wait", "material_print_temp_wait", "material_print_temp_prepend", "material_bed_temp_prepend",
                     "machine_endstop_positive_direction_z", "machine_minimum_feedrate", "machine_feeder_wheel_diameter",
                     "machine_nozzle_tip_outer_diameter", "machine_nozzle_head_distance", "machine_nozzle_expansion_angle", "machine_heat_zone_length",
                     "machine_filament_park_distance", "machine_nozzle_temp_enabled", "machine_nozzle_heat_up_speed", "machine_nozzle_cool_down_speed",
                     "machine_min_cool_heat_time_window", "machine_gcode_flavor", "machine_firmware_retract", "machine_disallowed_areas", "nozzle_disallowed_areas",
                     "machine_head_polygon", "machine_head_with_fans_polygon", "gantry_height", "machine_nozzle_id", "machine_nozzle_size", "machine_nozzle_size",
                     "machine_use_extruder_offset_to_offset_coords", "extruder_prime_pos_z", "extruder_prime_pos_abs", "machine_max_feedrate_x", "machine_max_feedrate_y",
                     "machine_max_feedrate_z", "machine_max_feedrate_e", "machine_max_acceleration_x", "machine_max_acceleration_y", "machine_max_acceleration_z",
                     "machine_max_acceleration_e", "machine_acceleration", "machine_max_jerk_xy", "machine_max_jerk_z", "machine_max_jerk_e", "machine_steps_per_mm_x",
                     "machine_steps_per_mm_y", "machine_steps_per_mm_z", "machine_steps_per_mm_e", "machine_endstop_positive_direction_x", "machine_endstop_positive_direction_y"]
                    showAncestors: true
                    expanded: ["*"]
                    visibilityHandler: UM.SettingPreferenceVisibilityHandler {}
                }

                delegate: Loader
                {
                    id: loader

                    width: parent.width
                    height: model.type != undefined ? UM.Theme.getSize("section").height : 0

                    property var definition: model
                    property var settingDefinitionsModel: definitionsModel

                    asynchronous: true
                    active: model.type != undefined
                    sourceComponent:
                    {
                        switch(model.type)
                        {
                            case "category":
                                return settingVisibilityCategory
                            default:
                                return settingVisibilityItem
                        }
                    }
                }
            }
        }

        UM.I18nCatalog { id: catalog; name: "cura"; }
        SystemPalette { id: palette; }

        Component
        {
            id: settingVisibilityCategory;

            UM.SettingVisibilityCategory { }
        }

        Component
        {
            id: settingVisibilityItem;

            UM.SettingVisibilityItem { }
        }
    }
}
