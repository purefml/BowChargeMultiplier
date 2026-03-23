local sdk = sdk
local imgui = imgui
local re = re

local title = "Bow Charge Multiplier"
local config_path = "BowChargeMultiplier.json"

local settings = {
    enabled = false,
    multiplier = 3.0
}

local function load_settings()
    local loaded = json.load_file(config_path)
    if loaded ~= nil then
        if type(loaded.enabled) == "boolean" then settings.enabled = loaded.enabled end
        if type(loaded.multiplier) == "number" then settings.multiplier = loaded.multiplier end
    end
end

local function save_settings()
    json.dump_file(config_path, settings)
end

load_settings()

local lastChargeTimers = setmetatable({}, {__mode = "k"})
local typeDef = sdk.find_type_definition("app.cHunterWp11Handling")
if not typeDef then
    log.error("app.cHunterWp11Handling not found")
    return
end

local updateCharge = typeDef:get_method("updateCharge(System.Boolean)")
if not updateCharge then
    updateCharge = typeDef:get_method("updateCharge")
end

if not updateCharge then
    log.error("Bow updateCharge method not found")
    return
end

sdk.hook(
    updateCharge,
    function(args)
        if not settings.enabled then return end

        local this = sdk.to_managed_object(args[2])
        if not this then return end
        
        local current = this:get_field("_ChargeTimer")
        if not current then return end

        local last = lastChargeTimers[this] or current
        local delta = current - last

        if delta > 0 then
            local newValue = current + delta * (settings.multiplier - 1)
            this:set_field("_ChargeTimer", newValue)
            lastChargeTimers[this] = newValue
        else
            lastChargeTimers[this] = current
        end
    end,
    function(retval) return retval end
)

re.on_draw_ui(function()
    if not imgui.tree_node(title) then
        return
    end

    local changed = false
    
    local changed_enabled
    changed_enabled, settings.enabled = imgui.checkbox("Enable Mod", settings.enabled)
    if changed_enabled then changed = true end

    imgui.separator()
    imgui.text("Presets:")
    
    if imgui.button("x1.5", 60, 25) then 
        settings.multiplier = 1.5 
        changed = true 
    end
    imgui.same_line()
    if imgui.button("x3.0", 60, 25) then 
        settings.multiplier = 3.0 
        changed = true 
    end
    imgui.same_line()
    if imgui.button("x5.0", 60, 25) then 
        settings.multiplier = 5.0 
        changed = true 
    end

    imgui.separator()
    
    local changed_mult
    changed_mult, settings.multiplier = imgui.slider_float("Charge Speed Multiplier", settings.multiplier, 1.0, 10.0, "x%.2f")
    if changed_mult then
        if settings.multiplier < 1.0 then settings.multiplier = 1.0 end
        changed = true
    end

    if changed then
        save_settings()
    end

    imgui.tree_pop()
end)

re.on_config_save(function()
    save_settings()
end)

log.info("Bow Charge Multiplier Loaded")