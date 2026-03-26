local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']
local lib = mods['adamant-Modpack_Lib']

config = chalk.auto('config.lua')
public.config = config

local backup, revert = lib.createBackupSystem()

-- =============================================================================
-- UTILITIES
-- =============================================================================


local function DeepCompare(a, b)
    if a == b then return true end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return false end
    for key, value in pairs(a) do
        if not DeepCompare(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

local function ListContainsEquivalent(list, template)
    if type(list) ~= "table" then return false end
    for _, entry in ipairs(list) do
        if DeepCompare(entry, template) then return true end
    end
    return false
end

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id       = "DisableSeleneBeforeBoon",
    name     = "Disable Selene Before First Boon",
    category = "Run Modifiers",
    group    = "NPCs & Routing",
    tooltip  = "Prevents Selene from spawning before the first boon is obtained.",
    default  = false,
    dataMutation = true,
    modpack = "h2-modpack",
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function apply()
    backup(NamedRequirementsData, "SpellDropRequirements")
    local additionalSpellReq = {
        Path = { "CurrentRun", "LootTypeHistory" },
        CountOf = {
            "AphroditeUpgrade", "ApolloUpgrade", "DemeterUpgrade",
            "HephaestusUpgrade", "HestiaUpgrade", "HeraUpgrade",
            "PoseidonUpgrade", "ZeusUpgrade", "AresUpgrade", "WeaponUpgrade"
        },
        Comparison = ">=",
        Value = 1
    }

    if NamedRequirementsData and NamedRequirementsData.SpellDropRequirements then
        local targetReqs = NamedRequirementsData.SpellDropRequirements
        if not ListContainsEquivalent(targetReqs, additionalSpellReq) then
            table.insert(targetReqs, additionalSpellReq)
        end
    end
end

local function registerHooks()
end

-- =============================================================================
-- Wiring
-- =============================================================================

public.definition.apply = apply
public.definition.revert = revert

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if lib.isEnabled(config, public.definition.modpack) then apply() end
        if public.definition.dataMutation and not lib.isCoordinated(public.definition.modpack) then
            SetupRunData()
        end
    end)
end)

local uiCallback = lib.standaloneUI(public.definition, config, apply, revert)
rom.gui.add_to_menu_bar(uiCallback)
