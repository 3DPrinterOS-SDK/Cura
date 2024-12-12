# Copyright (c) 2017 fieldOfView
# This plugin is released under the terms of the LGPLv3 or higher.
USE_QT5 = False
try:
    from PyQt6.QtCore import QObject, QUrl, pyqtProperty, pyqtSignal, pyqtSlot
    from PyQt6.QtQml  import qmlRegisterSingletonType
except ImportError:
    from PyQt5.QtCore import QObject, QUrl, pyqtProperty, pyqtSignal, pyqtSlot
    from PyQt5.QtQml import qmlRegisterSingletonType
    USE_QT5 = True



from cura.CuraApplication import CuraApplication
from UM.Extension import Extension
from UM.PluginRegistry import PluginRegistry
from UM.Message import Message
from UM.Logger import Logger
from UM.Version import Version
#from UM.Application import Application

from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.SettingFunction import SettingFunction

from cura.Settings.CuraContainerStack import _ContainerIndexes as ContainerIndexes

from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("belt_printer_slicing")

#from UM.FlameProfiler import pyqtSlot

from . import BeltDecorator

from . import CuraApplicationPatches
from . import PatchedCuraActions
from . import BuildVolumePatches
from . import CuraEngineBackendPatches
from . import FlavorParserPatches

from UM.Backend.Backend import BackendState

import math
import os.path
import re
import json

from UM.Resources import Resources
Resources.addSearchPath(
    os.path.join(os.path.abspath(
        os.path.dirname(__file__))))  # Plugin translation file import

i18n_catalog = i18nCatalog("belt_printer_slicing")

class BeltPlugin(QObject,Extension):
    def __init__(self, parent = None) -> None:
        QObject.__init__(self, parent)
        Extension.__init__(self)
        plugin_path = os.path.dirname(os.path.abspath(__file__))

        self._application = CuraApplication.getInstance()
        
        self._qml_folder = "qml" if not USE_QT5 else "qml_qt5"

        self._build_volume_patches = None
        self._cura_engine_backend_patches = None
        self._material_manager_patches = None
        self._global_container_stack = None
        self._settings_dialog = None

        self._preferences = self._application.getPreferences()
        #Belt Plugin environment variable#############################
        # self._preferences.addPreference("BeltPlugin/on_plugin", False) #Belt Plugin ON:True,OFF:False
        #
        # self._preferences.addPreference("BeltPlugin/gantry_angle", 45)
        #
        # self._preferences.addPreference("BeltPlugin/support_gantry_angle_bias", 45)
        # self._preferences.addPreference("BeltPlugin/support_minimum_island_area", 3.0)
        #
        # self._preferences.addPreference("BeltPlugin/repetitions", 1)
        # self._preferences.addPreference("BeltPlugin/repetitions_distance", 300)
        #
        # #TODO Allow user to be set
        # self._preferences.addPreference("BeltPlugin/repetitions_gcode", "\nG92 E0   ; Set Extruder to zero\nG1 E-4 F3900  ; Retract 4mm at 65mm/s\nG92 Z0   ; Set Belt to zero\nG1 Z{belt_repetitions_distance}   ; Advance belt between repetitions\nG92 Z0   ; Set Belt to zero again\n\n;˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄ - repetition - ˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄\n\nM107    ; Start with the fan off\nG0 X170 ; Move X to the center\nG1 Y1   ; Move y to the belt\nG1 E0   ; Move extruder back to 0\nG92 E-5 ; Add 5mm restart distance\n\n")
        #
        # #TODO Raft setting Default Cura
        # self._preferences.addPreference("BeltPlugin/raft", False)
        # self._preferences.addPreference("BeltPlugin/raft_margin", 0.0)
        # self._preferences.addPreference("BeltPlugin/raft_thickness", 0.8)
        # self._preferences.addPreference("BeltPlugin/raft_gap", 0.5)
        # self._preferences.addPreference("BeltPlugin/raft_speed", 18.0)
        # self._preferences.addPreference("BeltPlugin/raft_flow", 1.0)
        #
        #
        # self._preferences.addPreference("BeltPlugin/belt_wall_enabled", False)
        # self._preferences.addPreference("BeltPlugin/belt_wall_speed", 600.0)
        # self._preferences.addPreference("BeltPlugin/belt_wall_flow", 1.0)
        #
        # self._preferences.addPreference("BeltPlugin/z_offset_gap", 0.25)
        #
        # self._preferences.addPreference("BeltPlugin/secondary_fans_enabled", False)
        # self._preferences.addPreference("BeltPlugin/secondary_fans_speed", 0)
        #
        # #Not setting user
        # self._preferences.addPreference("BeltPlugin/z_offset", 0.2)
        # self._preferences.addPreference("BeltPlugin/view_depth", 160)
        #
        # ###########################################
        # self.setMenuName("Belt Extension")
        # self.addMenuItem("Setting", self.showSettings)

        self._scene_root = self._application.getController().getScene().getRoot()
        self._scene_root.addDecorator(BeltDecorator.BeltDecorator())
        self._application.getOutputDeviceManager().writeStarted.connect(self._filterGcode)
        self._application.pluginsLoaded.connect(self._onPluginsLoaded)
        self._application.globalContainerStackChanged.connect(self._onGlobalContainerStackChanged)
        self._onGlobalContainerStackChanged()

        self._force_visibility_update = True

        # disable update checker plugin (because it checks the wrong version)
        plugin_registry = PluginRegistry.getInstance()
        if "UpdateChecker" not in plugin_registry._disabled_plugins:
           Logger.log("d", "Disabling Update Checker plugin")
           plugin_registry._disabled_plugins.append("UpdateChecker")

    def _onPluginsLoaded(self) -> None:
        # make sure the we connect to engineCreatedSignal later than PrepareStage does, so we can substitute our own sidebar
        Logger.log("d", "Load belt plugin")
        self._application.engineCreatedSignal.connect(self._onEngineCreated)

        # Hide nozzle in simulation view
        self._application.getController().activeViewChanged.connect(self._onActiveViewChanged)
        preferences = self._application.getPreferences()
        preferences.preferenceChanged.connect(self._onPreferencesChanged)

    def _onEngineCreated(self) -> None:

        # Apply patches
        Logger.log("d", "Apply Patches")
        self._cura_application_patches = CuraApplicationPatches.CuraApplicationPatches(self._application)
        Logger.log("d", "Apply Build Volume")
        self._build_volume_patches = BuildVolumePatches.BuildVolumePatches(self._application.getBuildVolume())
        self._cura_engine_backend_patches = CuraEngineBackendPatches.CuraEngineBackendPatches(self._application.getBackend())
        # self._print_information_patches = PrintInformationPatches.PrintInformationPatches(self._application.getPrintInformation())
        self._output_device_patches = {}
        self._application._cura_actions = PatchedCuraActions.PatchedCuraActions()
        self._application._qml_engine.rootContext().setContextProperty("CuraActions", self._application._cura_actions)
        self._application.getBackend().slicingStarted.connect(self._onSlicingStarted)
        gcode_reader_plugin = PluginRegistry.getInstance().getPluginObject("GCodeReader")
        self._flavor_parser_patches = {}
        if gcode_reader_plugin:
            for (parser_name, parser_object) in gcode_reader_plugin._flavor_readers_dict.items():
                self._flavor_parser_patches[parser_name] = FlavorParserPatches.FlavorParserPatches(parser_object)
        self._fixVisibilityPreferences(forced = self._force_visibility_update)
        #

    def _onGlobalContainerStackChanged(self):
        if self._global_container_stack:
            self._global_container_stack.propertyChanged.disconnect(self._onSettingValueChanged)

        self._global_container_stack = self._application.getGlobalContainerStack()

        if self._global_container_stack:
            self._global_container_stack.propertyChanged.connect(self._onSettingValueChanged)
            gantry_angle = self._global_container_stack.getProperty("belt_gantry_angle", "value")
            # print("on_glob: gantry_angle: " + gantry_angle)
            # HACK: Move belt_settings to the top of the list of settings
            definition_container = self._global_container_stack.getBottom()
            if definition_container._definitions[0].key != "belt_settings":
                for index, definition in enumerate(definition_container._definitions):
                    if definition.key == "belt_settings":
                        definition_container._definitions.insert(0, definition_container._definitions.pop(index))

            # HOTFIXES for Blackbelt stacks
            if gantry_angle and self._application._machine_manager:
                extruder_stack = self._application.getMachineManager()._active_container_stack

                if extruder_stack:
                    # Make sure the extruder material diameter matches the global material diameter
                    material_diameter = extruder_stack.getProperty("material_diameter", "value")
                    if material_diameter:
                        definition_changes_container = extruder_stack.definitionChanges
                        if "material_diameter" not in definition_changes_container.getAllKeys():
                            # Make sure there is a definition_changes container to store the machine settings
                            if definition_changes_container == ContainerRegistry.getInstance().getEmptyInstanceContainer():
                                print("extruder_stack.getId: " + extruder_stack.getId)
                                definition_changes_container = CuraStackBuilder.createDefinitionChangesContainer(
                                    extruder_stack, extruder_stack.getId() + "_settings")

                            definition_changes_container.setProperty("material_diameter", "value", material_diameter)

                        # Make sure approximate diameters are in check
                        approximate_diameter = str(round(material_diameter))
                        extruder_stack.setMetaDataEntry("approximate_diameter", approximate_diameter)
                        self._global_container_stack.setMetaDataEntry("approximate_diameter", approximate_diameter)

                    # Make sure the extruder quality is a blackbelt quality profile
                    if extruder_stack.quality != self._application.empty_quality_container and extruder_stack.quality.getDefinition().getId() != "blackbelt":
                        qualityList = ContainerRegistry.getInstance().findContainers(id = "belt_normal")
                        if qualityList:
                            belt_normal_quality = qualityList[0]                        
                            extruder_stack.setQuality(belt_normal_quality)
                            self._global_container_stack.setQuality(belt_normal_quality)

        self._adjustLayerViewNozzle()
    def _onSlicingStarted(self) -> None:
        self._scene_root.callDecoration("calculateTransformData")

    def _onActiveVariantChanged(self):
        if not self._global_container_stack:
            return
        extruder_stack = self._application.getMachineManager()._active_container_stack
        if not extruder_stack:
            return

        gantry_angle = self._global_container_stack.getProperty("belt_gantry_angle", "value")
        print("_onActiveVariantChanged: gantry_angle " + gantry_angle)
        if not gantry_angle:
            return

        if self._global_container_stack.variant != extruder_stack.variant:
            self._global_container_stack.setVariant(extruder_stack.variant)

    def _onActiveQualityChanged(self):
        # HOTFIX: make sure global quality is correctly set
        if not self._global_container_stack:
            return
        extruder_stack = self._application.getMachineManager()._active_container_stack
        if not extruder_stack:
            return


        gantry_angle = self._global_container_stack.getProperty("belt_gantry_angle", "value")
        print("_onActiveQualityChanged: gantry_angle " + gantry_angle)
        if not gantry_angle:
            return

        if extruder_stack.quality.getMetaDataEntry("global_quality", False) or not self._global_container_stack.quality.getMetaDataEntry("global_quality", False):
            qualityList = ContainerRegistry.getInstance().findContainers(id = "belt_global_normal")
            if qualityList:
                belt_global_quality = qualityList[0]
                self._global_container_stack.setQuality(belt_global_quality)

            qualityList = ContainerRegistry.getInstance().findContainers(id = "belt_normal")
            if qualityList:
                belt_quality = qualityList[0]
                extruder_stack.setQuality(belt_quality)

    def _onSettingValueChanged(self, key, property_name):
        if property_name != "value" or not self._global_container_stack.hasProperty("belt_gantry_angle", "value"):
            return

        elif key == "belt_gantry_angle":
            # Setting the gantry angle changes the build volume.
            # Force rebuilding the build volume by reloading the global container stack.
            # This is a bit of a hack, but it seems quick enough.
            self._application.globalContainerStackChanged.emit()

    def _onPreferencesChanged(self, preference):
        if preference == "general/visible_settings":
            self._fixVisibilityPreferences()

    def _fixVisibilityPreferences(self, forced = False):
        # Fix setting visibility preferences
        preferences = self._application.getPreferences()
        visible_settings = preferences.getValue("general/visible_settings")
        if not visible_settings:
            # Wait until the default visible settings have been set
            return

        if "belt_settings" in visible_settings and not forced:
            return

        if self._application.getSettingVisibilityPresetsModel():
            self._application.getSettingVisibilityPresetsModel().setActivePreset("blackbelt")

        visible_settings_changed = False
        default_visible_settings = [
            "belt_settings", "belt_repetitions",  "belt_repetitions_distance",
            "belt_raft", "belt_raft_margin", "belt_raft_thickness", "belt_raft_gap", "belt_raft_speed",
            "belt_raft_flow", "belt_wall_enabled", "belt_wall_speed", "belt_wall_flow",
            "belt_support_gantry_angle_bias", "belt_support_minimum_island_area"
        ]
        for key in default_visible_settings:
            if key not in visible_settings:
                visible_settings += ";%s" % key
                visible_settings_changed = True

        if visible_settings_changed:
            preferences.setValue("general/visible_settings", visible_settings)

    def _onActiveViewChanged(self) -> None:
        self._adjustLayerViewNozzle()

    def _adjustLayerViewNozzle(self) -> None:
        global_stack = self._application.getGlobalContainerStack()
        if not global_stack:
            return

        view = self._application.getController().getActiveView()
        if view and view.getPluginId() == "SimulationView":
            gantry_angle = global_stack.getProperty("belt_gantry_angle", "value")
            if gantry_angle and float(gantry_angle) > 0:
                view.getNozzleNode().setParent(None)
            else:
                view.getNozzleNode().setParent(self._application.getController().getScene().getRoot())


    def _filterGcode(self, output_device) -> None:
        global_stack = self._application.getGlobalContainerStack()
        gantry_angle = global_stack.getProperty("belt_gantry_angle", "value")
        Logger.log("i", "gantry_angle : " + str(gantry_angle))
        if not gantry_angle:
            return
        scene = self._application.getController().getScene()
        gcode_dict = getattr(scene, "gcode_dict", {})
        if not gcode_dict: # this also checks for an empty dict
            Logger.log("w", "Scene has no gcode to process")
            return
        dict_changed = False

        enable_secondary_fans = global_stack._extruders["0"].getProperty("belt_secondary_fans_enabled", "value")
        if enable_secondary_fans:
            secondary_fans_speed = global_stack._extruders["0"].getProperty("belt_secondary_fans_speed", "value") / 100

        enable_belt_wall = global_stack.getProperty("belt_wall_enabled", "value")
        if enable_belt_wall:
            belt_wall_flow = global_stack.getProperty("belt_wall_flow", "value") / 100
            belt_wall_speed = global_stack.getProperty("belt_wall_speed", "value") * 60
            minimum_y = global_stack._extruders["0"].getProperty("wall_line_width_0", "value") * 0.6 #  0.5 would be non-tolerant

        repetitions = global_stack.getProperty("belt_repetitions", "value") or 1
        if repetitions > 1:
            repetitions_distance = global_stack.getProperty("belt_repetitions_distance", "value")
            repetitions_gcode = global_stack.getProperty("belt_repetitions_gcode", "value")

        for plate_id in gcode_dict:
            gcode_list = gcode_dict[plate_id]
            if not gcode_list:
                continue

            if ";BELTPROCESSED" in gcode_list[0]:
                Logger.log("e", "Already post processed")
                continue
            
            # put a print settings summary at the top
            # note: this simplified view is only valid for single extrusion printers
            setting_values = {}
            setting_summary = ";Setting summary:\n"
            for stack in [global_stack._extruders["0"], global_stack]:
                for index, container in enumerate(stack.getContainers()):
                    if index == ContainerIndexes.Definition:
                        continue
                    for key in container.getAllKeys():
                        if key not in setting_values:
                            value = container.getProperty(key, "value")
                            if not global_stack.getProperty(key, "settable_per_extruder"):
                                value = global_stack.getProperty(key, "value")
                            if isinstance(value, SettingFunction):
                                value = value(stack)
                            definition = container.getInstance(key).definition
                            if definition.type == "str":
                                value = value.replace("\n", "\\n")
                                if len(value) > 40:
                                    value = "[not shown for brevity]"
                            setting_values[key] = value

            for definition in global_stack.getBottom().findDefinitions():
                if definition.type == "category":
                    setting_summary += ";  CATEGORY: %s\n" % definition.label
                elif definition.key in setting_values:
                    setting_summary += ";    %s: %s\n" % (definition.label, setting_values[definition.key])
            gcode_list[0] += setting_summary

            
            init_layer_bed_temp = global_stack.getProperty("material_bed_temperature_layer_0", "value")
            layer_bed_temp = global_stack.getProperty("material_bed_temperature", "value")
            
            # Remove the m140 disabled bed temp codes
            temp_search_regex = re.compile(r"M140\s+S0\b")
            for layer_number, layer in enumerate(gcode_list):
                gcode_list[layer_number] = re.sub(temp_search_regex, lambda m: "----DISABLE BED---140 S0", layer) #Replace all.
            
            # replace all bed temps (for some reason we get a strange bed temp at the start of the script with this plugin, this is to fix that)
            temp_search_regex = re.compile(r"M140\s+S(\d*\.?\d*)")
            for layer_number, layer in enumerate(gcode_list):
                layer_temp = layer_bed_temp
                if layer_number == 0: 
                    layer_temp = init_layer_bed_temp
                gcode_list[layer_number] = re.sub(temp_search_regex, lambda m: "M140 S%d" % (int(layer_temp)), layer) #Replace all.

            # Put disabled bed temps back
            temp_search_regex = re.compile(r"----DISABLE BED---140 S0\b")
            for layer_number, layer in enumerate(gcode_list):
                gcode_list[layer_number] = re.sub(temp_search_regex, lambda m: "M140 S0", layer) #Replace all.

            # secondary fans should similar things as print cooling fans
            if enable_secondary_fans:
                search_regex = re.compile(r"M106\s+S(\d*\.?\d*)")

                for layer_number, layer in enumerate(gcode_list):
                    gcode_list[layer_number] = re.sub(search_regex, lambda m: "M106 P1 S%d\nM106 S%s" % (int(min(255, float(m.group(1)) * secondary_fans_speed)), m.group(1)), layer) #Replace all.
            
            # z_offset change
            _wall_line_width_0 = float(global_stack._extruders["0"].getProperty("wall_line_width_0", "value"))
            _xy_offset = float(global_stack._extruders["0"].getProperty("xy_offset", "value"))

            # Logger.log("d", "wall_line_width_0: " + str(_wall_line_width_0) + " xy_offset: " + str(_xy_offset))
            # _belt_z_offset_gap = float(self._preferences.getValue("BeltPlugin/z_offset_gap"))
            # _gantry_angle = float(self._preferences.getValue("BeltPlugin/gantry_angle"))
            #
            # # _belt_z_offset = round( ( _wall_line_width_0 / 2.0) - (_belt_z_offset_gap / math.sin(math.radians(_gantry_angle))) - _xy_offset, 4)
            # Logger.log("d", "belt_z_offset" + str(_belt_z_offset))
            # gcode_list[1] = gcode_list[1].replace("{belt_z_offset}", str(_belt_z_offset))
            # gcode_list[-1] = gcode_list[-1].replace("{belt_z_offset}", str(_belt_z_offset))

            # adjust walls that touch the belt
            if enable_belt_wall:
                #wall_line_width_0
                y = None
                last_y = None
                e = None
                last_e = None
                f = None

                speed_regex = re.compile(r" F\d*\.?\d*")
                extrude_regex = re.compile(r" E-?\d*\.?\d*")
                move_parameters_regex = re.compile(r"([YEF]-?\d*\.?\d+)")

                for layer_number, layer in enumerate(gcode_list):
                    if layer_number < 2 or layer_number > len(gcode_list) - 1:
                        # gcode_list[0]: curaengine header
                        # gcode_list[1]: start gcode
                        # gcode_list[2] - gcode_list[n-1]: layers
                        # gcode_list[n]: end gcode
                        continue

                    lines = layer.splitlines()
                    for line_number, line in enumerate(lines):
                        line_has_e = False
                        line_has_axis = False

                        gcode_command = line.split(' ', 1)[0]
                        if gcode_command not in ["G0", "G1", "G92"]:
                            continue

                        result = re.findall(move_parameters_regex, line)
                        if not result:
                            continue

                        for match in result:
                            parameter = match[:1]
                            value = float(match[1:])
                            if parameter == "Y":
                                y = value
                                line_has_axis = True
                            elif parameter == "E":
                                e = value
                                line_has_e = True
                            elif parameter == "F":
                                f = value
                            elif parameter in "XZ":
                                line_has_axis = True

                        if gcode_command != "G92" and line_has_axis and line_has_e and f is not None and y is not None and y <= minimum_y and last_y is not None and last_y <= minimum_y:
                            if f > belt_wall_speed:
                                # Remove pre-existing move speed and add our own
                                line = re.sub(speed_regex, r"", line)

                            if belt_wall_flow != 1.0 and last_y is not None:
                                new_e = last_e + (e - last_e) * belt_wall_flow
                                line = re.sub(extrude_regex, " E%f" % new_e, line)
                                line += " ; Adjusted E for belt wall\nG92 E%f ; Reset E to pre-compensated value" % e

                            if f > belt_wall_speed:
                                g_type = int(line[1:2])
                                line = "G%d F%d ; Belt wall speed\n%s\nG%d F%d ; Restored speed" % (g_type, belt_wall_speed, line, g_type, f)

                            lines[line_number] = line

                        last_y = y
                        last_e = e

                    edited_layer = "\n".join(lines) + "\n"
                    gcode_list[layer_number] = edited_layer

            # HOTFIX: remove finalize bits before end gcode
            end_gcode = gcode_list[len(gcode_list)-1]
            end_gcode = end_gcode.replace("M140 S0\nM203 Z5\nM107", "") # TODO: regex magic
            gcode_list[len(gcode_list)-1] = end_gcode

            # make repetitions
            if repetitions > 1 and len(gcode_list) > 2:
                # gcode_list[0]: curaengine header
                # gcode_list[1]: start gcode
                # gcode_list[2] - gcode_list[n-1]: layers
                # gcode_list[n]: end gcode
                layers = gcode_list[2:-1]
                layers.append(repetitions_gcode.replace("{belt_repetitions_distance}", str(repetitions_distance)))
                gcode_list[2:-1] = (layers * int(repetitions))[0:-1]

            gcode_list[0] += ";BELTPROCESSED\n"
            gcode_dict[plate_id] = gcode_list
            dict_changed = True

        if dict_changed:
            setattr(scene, "gcode_dict", gcode_dict)

    # def showSettings(self) -> None:
    #     path = os.path.join(os.path.dirname(os.path.abspath(__file__)), self._qml_folder, "BeltSettings.qml")
    #
    #     self._settings_dialog = self._application.createQmlComponent(path, {"manager": self})
    #     if self._settings_dialog:
    #         self._settings_dialog.show()
    
    @pyqtSlot()
    def resetSlice(self) -> None:
        _background = self._application.getBackend()
        _background.backendStateChange.emit(BackendState.NotStarted)
