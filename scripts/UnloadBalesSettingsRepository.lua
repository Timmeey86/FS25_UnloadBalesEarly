---@class UnloadBalesSettingsRepository
---This class is responsible for reading and writing settings
UnloadBalesSettingsRepository = {
	MAIN_KEY = "UnloadBalesEarly",
	OVERLOAD_THRESHOLD_KEY = "overloadingThreshold",
	UNLOADING_THRESHOLD_KEY = "unloadingThreshold"
}

---Writes the settings to our own XML file
---@param settings UnloadBalesSettings @The settings object
function UnloadBalesSettingsRepository.storeSettings(settings)
	local xmlPath = UnloadBalesSettingsRepository.getXmlFilePath()
	if xmlPath == nil then
		Logging.warning(MOD_NAME .. ": Could not store settings.") -- another warning has been logged before this
		return
	end

	-- Create an empty XML file in memory
	local xmlFileId = createXMLFile("UnloadBalesEarly", xmlPath, UnloadBalesSettingsRepository.MAIN_KEY)

	-- Add XML data in memory
	setXMLInt(xmlFileId, UnloadBalesSettingsRepository.getPathForStateAttribute(UnloadBalesSettingsRepository.OVERLOAD_THRESHOLD_KEY), settings.overloadingThreshold or -1)
	setXMLInt(xmlFileId, UnloadBalesSettingsRepository.getPathForStateAttribute(UnloadBalesSettingsRepository.UNLOADING_THRESHOLD_KEY), settings.unloadingThreshold or -1)

	-- Write the XML file to disk
	saveXMLFile(xmlFileId)
end

---Reads settings from an existing XML file, if such a file exists
---@return UnloadBalesSettings @The settings object (default, if nothing was loaded from file)
function UnloadBalesSettingsRepository.restoreSettings()
	local settings = UnloadBalesSettings.new()

	local xmlPath = UnloadBalesSettingsRepository.getXmlFilePath()
	if xmlPath == nil then
		-- This is a valid case when a new game was started. The savegame path will only be available after saving once
		return settings
	end

	-- Abort if no settings have been saved yet
	if not fileExists(xmlPath) then
		print(MOD_NAME .. ": No settings found, using default settings")
		return settings
	end

	-- Load the XML if possible
	local xmlFileId = loadXMLFile("UnloadBalesEarly", xmlPath)
	if xmlFileId == 0 then
		Logging.warning(MOD_NAME .. ": Failed reading from XML file")
		return settings
	end

	-- Read the values from memory
	settings.overloadingThreshold = getXMLInt(xmlFileId, UnloadBalesSettingsRepository.getPathForStateAttribute(UnloadBalesSettingsRepository.OVERLOAD_THRESHOLD_KEY)) or settings.overloadingThreshold
	settings.unloadingThreshold = getXMLInt(xmlFileId, UnloadBalesSettingsRepository.getPathForStateAttribute(UnloadBalesSettingsRepository.UNLOADING_THRESHOLD_KEY)) or settings.unloadingThreshold
	if settings.overloadingThreshold == -1 then
		settings.overloadingThreshold = nil
	end
	if settings.unloadingThreshold == -1 then
		settings.unloadingThreshold = nil
	end
	print(MOD_NAME .. ": Successfully restored settings")

	return settings
end

---Builds an XML path for a "state" attribute like a true/false switch or a selection of predefined values, but not a custom text, for example
---@param property string @The name of the XML property.
---@param parentProprety string|nil @The name of the parent proprety
---@return string @The path to the XML attribute
function UnloadBalesSettingsRepository.getPathForStateAttribute(property, parentProprety)
	return ("%s.%s#%s"):format(parentProprety or UnloadBalesSettingsRepository.MAIN_KEY, property, "state")
end
function UnloadBalesSettingsRepository.getPathForValue(property, parentProperty)
	return ("%s.%s"):format(parentProperty or UnloadBalesSettingsRepository.MAIN_KEY, property)
end
---Builds a path to the XML file.
---@return string|nil @The path to the XML file
function UnloadBalesSettingsRepository.getXmlFilePath()
	if g_currentMission.missionInfo then
		local savegameDirectory = g_currentMission.missionInfo.savegameDirectory
		if savegameDirectory ~= nil then
			return ("%s/%s.xml"):format(savegameDirectory, MOD_NAME)
		-- else: Save game directory is nil if this is a brand new save
		end
	else
		Logging.warning(MOD_NAME .. ": Could not get path to UnloadBalesEarly.xml settings file since g_currentMission.missionInfo is nil.")
	end
	return nil
end