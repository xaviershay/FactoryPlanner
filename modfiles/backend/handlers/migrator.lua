-- This code handles the general migration process of the mod's global table
-- It decides whether and which migrations should be applied, in appropriate order

local migrator = {}

---@alias MigrationMasterList { [integer]: { version: VersionString, migration: Migration } }
---@alias Migration { global: function, player_table: function, subfactory: function, packed_subfactory: function }
---@alias MigrationObject PlayerTable | Factory | PackedFactory

-- Returns a table containing all existing migrations in order
local migration_masterlist = {  ---@type MigrationMasterList
    [1] = {version="0.18.20", migration=require("backend.migrations.migration_0_18_20")},
    [2] = {version="0.18.27", migration=require("backend.migrations.migration_0_18_27")},
    [3] = {version="0.18.29", migration=require("backend.migrations.migration_0_18_29")},
    [4] = {version="0.18.38", migration=require("backend.migrations.migration_0_18_38")},
    [5] = {version="0.18.42", migration=require("backend.migrations.migration_0_18_42")},
    [6] = {version="0.18.45", migration=require("backend.migrations.migration_0_18_45")},
    [7] = {version="0.18.48", migration=require("backend.migrations.migration_0_18_48")},
    [8] = {version="0.18.49", migration=require("backend.migrations.migration_0_18_49")},
    [9] = {version="0.18.51", migration=require("backend.migrations.migration_0_18_51")},
    [10] = {version="1.0.6", migration=require("backend.migrations.migration_1_0_6")},
    [11] = {version="1.1.5", migration=require("backend.migrations.migration_1_1_5")},
    [12] = {version="1.1.6", migration=require("backend.migrations.migration_1_1_6")},
    [13] = {version="1.1.8", migration=require("backend.migrations.migration_1_1_8")},
    [14] = {version="1.1.14", migration=require("backend.migrations.migration_1_1_14")},
    [15] = {version="1.1.19", migration=require("backend.migrations.migration_1_1_19")},
    [16] = {version="1.1.21", migration=require("backend.migrations.migration_1_1_21")},
    [17] = {version="1.1.25", migration=require("backend.migrations.migration_1_1_25")},
    [18] = {version="1.1.26", migration=require("backend.migrations.migration_1_1_26")},
    [19] = {version="1.1.27", migration=require("backend.migrations.migration_1_1_27")},
    [20] = {version="1.1.42", migration=require("backend.migrations.migration_1_1_42")},
    [21] = {version="1.1.43", migration=require("backend.migrations.migration_1_1_43")},
    [22] = {version="1.1.59", migration=require("backend.migrations.migration_1_1_59")},
    [23] = {version="1.1.61", migration=require("backend.migrations.migration_1_1_61")},
    [24] = {version="1.1.65", migration=require("backend.migrations.migration_1_1_65")},
    [25] = {version="1.1.66", migration=require("backend.migrations.migration_1_1_66")},
    [26] = {version="1.1.67", migration=require("backend.migrations.migration_1_1_67")},
}

-- ** LOCAL UTIL **
-- Compares two mod versions, returns true if v1 is an earlier version than v2 (v1 < v2)
-- Version numbers have to be of the same structure: same amount of numbers, separated by a '.'
---@param v1 VersionString
---@param v2 VersionString
---@return boolean
local function compare_versions(v1, v2)
    local split_v1 = util.split_string(v1, ".")
    local split_v2 = util.split_string(v2, ".")

    for i = 1, #split_v1 do
        if split_v1[i] == split_v2[i] then
            -- continue
        elseif split_v1[i] < split_v2[i] then
            return true
        else
            return false
        end
    end
    return false  -- return false if both versions are the same
end

-- Applies given migrations to the object
---@param migrations Migration[]
---@param function_name string
---@param object MigrationObject?
---@param player LuaPlayer?
local function apply_migrations(migrations, function_name, object, player)
    for _, migration in ipairs(migrations) do
        local migration_function = migration[function_name]

        if migration_function ~= nil then
            migration_function(object, player)  ---@type string
        end
    end
end

-- Determines whether a migration needs to take place, and if so, returns the appropriate range of the
-- migration_masterlist. If the version changed, but no migrations apply, it returns an empty array.
---@param previous_version VersionString
---@return Migration[]
local function determine_migrations(previous_version)
    local migrations = {}

    local found = false
    for _, migration in ipairs(migration_masterlist) do
        if compare_versions(previous_version, migration.version) then found = true end
        if found then table.insert(migrations, migration.migration) end
    end

    return migrations
end


-- ** TOP LEVEL **
-- Applies any appropriate migrations to the global table
function migrator.migrate_global()
    local migrations = determine_migrations(global.installed_mods["factoryplanner"])
    apply_migrations(migrations, "global", nil, nil)
end

-- Applies any appropriate migrations to the given factory
---@param player LuaPlayer
function migrator.migrate_player_table(player)
    local player_table = util.globals.player_table(player)
    if player_table ~= nil then  -- don't apply migrations to new players
        local migrations = determine_migrations(global.installed_mods["factoryplanner"])

        apply_migrations(migrations, "player_table", player_table, player)

        for subfactory in player_table.district:iterator() do
            apply_migrations(migrations, "subfactory", subfactory, player)
        end
    end
end

-- Applies any appropriate migrations to the given export_table's subfactories
---@param export_table ExportTable
function migrator.migrate_export_table(export_table)
    local migrations = determine_migrations(export_table.export_modset["factoryplanner"])
    for _, packed_subfactory in pairs(export_table.subfactories) do
        -- This migration type won't need the player argument, and removing it allows
        -- us to run imports without having a player attached
        apply_migrations(migrations, "packed_subfactory", packed_subfactory, nil)
    end
end

return migrator