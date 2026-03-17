-- =============================================================================
-- BOILERPLATE (do not modify)
-- =============================================================================

local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']

config = chalk.auto('config.lua')
public.config = config

local NIL = {}
local backups = {}

local function backup(tbl, key)
    if not backups[tbl] then backups[tbl] = {} end
    if backups[tbl][key] == nil then
        local v = tbl[key]
        backups[tbl][key] = v == nil and NIL or (type(v) == "table" and DeepCopyTable(v) or v)
    end
end

local function restore()
    for tbl, keys in pairs(backups) do
        for key, v in pairs(keys) do
            tbl[key] = v == NIL and nil or (type(v) == "table" and DeepCopyTable(v) or v)
        end
    end
end

local function isEnabled()
    return config.Enabled
end

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
    category = "RunModifiers",
    group    = "NPCs & Routing",
    tooltip  = "Prevents Selene from spawning before the first boon is obtained.",
    default  = false,
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

local function disable()
    restore()
end

local function registerHooks()
end

-- =============================================================================
-- PUBLIC API (do not modify)
-- =============================================================================

public.definition.enable = function()
    apply()
end

public.definition.disable = function()
    disable()
end

-- =============================================================================
-- LIFECYCLE (do not modify)
-- =============================================================================

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if config.Enabled then apply() end
    end)
end)

-- =============================================================================
-- STANDALONE UI (do not modify)
-- =============================================================================
-- When adamant-core is NOT installed, renders a minimal ImGui toggle.
-- When adamant-core IS installed, the core handles UI — this is skipped.

local imgui = rom.ImGui

local showWindow = false

rom.gui.add_imgui(function()
    if mods['adamant-Core'] then return end
    if not showWindow then return end

    if imgui.Begin(public.definition.name, true) then
        local val, chg = imgui.Checkbox("Enabled", config.Enabled)
        if chg then
            config.Enabled = val
            if val then apply() else disable() end
        end
        if imgui.IsItemHovered() and public.definition.tooltip ~= "" then
            imgui.SetTooltip(public.definition.tooltip)
        end
        imgui.End()
    else
        showWindow = false
    end
end)

rom.gui.add_to_menu_bar(function()
    if mods['adamant-Core'] then return end
    if imgui.BeginMenu("adamant") then
        if imgui.MenuItem(public.definition.name) then
            showWindow = not showWindow
        end
        imgui.EndMenu()
    end
end)
