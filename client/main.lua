--[[
    VIP Shop Client - Optimized & Secured
    Features:
    - Modern Lua security practices
    - Anti-hack measures
    - Rate limiting
    - Input validation
    - Memory optimization
]]

local ox_inventory = exports.ox_inventory
local ESX = exports['es_extended']:getSharedObject()

-- Secure state management
local State = {
    coins = 0,
    isOpen = false,
    lastUpdate = 0,
    lastOpenAttempt = 0,
    purchaseAttempts = 0,
    lastPurchaseTime = 0
}

-- Constants for security
local CONSTANTS = {
    COIN_UPDATE_INTERVAL = 30000,
    OPEN_COOLDOWN = 1000,
    PURCHASE_COOLDOWN = 2000,
    MAX_PURCHASE_ATTEMPTS = 5,
    ATTEMPT_RESET_TIME = 60000
}

-- Input validation utilities
local function ValidateInput(input, expectedType)
    if type(input) ~= expectedType then return false end
    if expectedType == 'string' and (input == '' or input == nil) then return false end
    if expectedType == 'number' and (input < 0 or input > 999999) then return false end
    return true
end

-- Rate limiting
local function IsRateLimited()
    local now = GetGameTimer()
    if now - State.lastOpenAttempt < CONSTANTS.OPEN_COOLDOWN then
        return true
    end
    State.lastOpenAttempt = now
    return false
end

-- Secure purchase validation
local function ValidatePurchaseData(data)
    if not data or type(data) ~= 'table' then return false end
    if not ValidateInput(data.id, 'string') then return false end
    if not ValidateInput(data.price, 'number') then return false end
    if not ValidateInput(data.type, 'string') then return false end
    
    -- Verify item exists in server config (client-side check for UX)
    for _, category in pairs(Config.Categories) do
        for _, item in ipairs(category.items) do
            if item.id == data.id and item.price == data.price and item.type == data.type then
                return true
            end
        end
    end
    return false
end

-- Initialize when player loads
RegisterNetEvent('esx:playerLoaded', function()
    Wait(2000) -- Wait for dependencies
    TriggerServerEvent('vipshop:playerLoaded')
end)

-- Secure command registration
RegisterCommand(Config.Command, function()
    if IsRateLimited() then
        lib.notify({
            title = 'VIP Shop',
            description = 'Please wait before opening the shop again',
            type = 'error'
        })
        return
    end
    OpenVIPShop()
end, false)

-- Key mapping
RegisterKeyMapping(Config.Command, 'Open VIP Shop', 'keyboard', 'F7')

-- Secure shop opening
function OpenVIPShop()
    if State.isOpen then
        return CloseVIPShop()
    end
    
    -- Security checks
    if IsPedInAnyVehicle(PlayerPedId(), false) or IsPauseMenuActive() then
        lib.notify({
            title = 'VIP Shop',
            description = 'You cannot open the shop right now',
            type = 'error'
        })
        return
    end

    State.isOpen = true
    SetNuiFocus(true, true)
    
    -- Request coins with rate limiting
    local now = GetGameTimer()
    if now - State.lastUpdate > CONSTANTS.COIN_UPDATE_INTERVAL then
        TriggerServerEvent('vipshop:getCoins')
        State.lastUpdate = now
    end

    -- Send minimal data to UI
    SendNUIMessage({
        action = 'openShop',
        categories = Config.Categories,
        themes = Config.Themes,
        playerCoins = State.coins
    })
end

-- Secure shop closing
function CloseVIPShop()
    if not State.isOpen then return end
    
    State.isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeShop' })
end

-- Secure NUI callbacks
RegisterNUICallback('closeShop', function(_, cb)
    CloseVIPShop()
    cb('ok')
end)

RegisterNUICallback('purchaseItem', function(data, cb)
    -- Anti-spam protection
    local now = GetGameTimer()
    if now - State.lastPurchaseTime < CONSTANTS.PURCHASE_COOLDOWN then
        cb({ success = false, message = 'Please wait between purchases' })
        return
    end
    
    if Config.Debug then
        print('[VIPShop] Purchase attempt:', json.encode(data))
    end
    
    -- Validate purchase data
    if not ValidatePurchaseData(data) then
        if Config.Debug then
            print('[VIPShop] Purchase validation failed')
        end
        cb({ success = false, message = 'Invalid purchase data' })
        return
    end
    
    -- Forward to server for actual purchase
    TriggerServerEvent('vipshop:purchaseItem', data)
    State.lastPurchaseTime = now
    cb('ok')
end)

-- Secure event handlers
RegisterNetEvent('vipshop:updateCoins', function(coins)
    if not ValidateInput(coins, 'number') then return end
    
    State.coins = coins
    State.lastUpdate = GetGameTimer()
    
    if State.isOpen then
        SendNUIMessage({
            action = 'updateCoins',
            coins = coins
        })
    end
    
    if Config.Debug then
        print('[VIPShop] Coins updated:', coins)
    end
end)

RegisterNetEvent('vipshop:purchaseSuccess', function(itemName)
    if not ValidateInput(itemName, 'string') then return end
    
    if State.isOpen then
        SendNUIMessage({
            action = 'purchaseSuccess',
            message = ('Successfully purchased %s'):format(itemName)
        })
    end
    
    lib.notify({
        title = 'VIP Shop',
        description = ('Successfully purchased %s'):format(itemName),
        type = 'success',
        position = Config.Notifications.position,
        duration = Config.Notifications.duration
    })
end)

RegisterNetEvent('vipshop:purchaseFailed', function(message)
    if not ValidateInput(message, 'string') then return end
    
    if State.isOpen then
        SendNUIMessage({
            action = 'purchaseFailed',
            message = message
        })
    end
    
    lib.notify({
        title = 'VIP Shop',
        description = message,
        type = 'error',
        position = Config.Notifications.position,
        duration = Config.Notifications.duration
    })
end)

-- Secure vehicle spawning
RegisterNetEvent('vipshop:spawnVehicle', function(vehicleModel, plate)
    if not ValidateInput(vehicleModel, 'string') or not ValidateInput(plate, 'string') then return end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Secure spawn location calculation
    local forwardVector = GetEntityForwardVector(playerPed)
    local spawnCoords = coords + (forwardVector * 3.0)
    
    local found, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 10.0, false)
    if not found then
        groundZ = coords.z
    end
    
    -- Secure model loading with timeout
    if not lib.requestModel(vehicleModel, 10000) then
        lib.notify({
            title = 'VIP Shop',
            description = 'Failed to load vehicle model',
            type = 'error'
        })
        return
    end
    
    -- Create vehicle with security checks
    local vehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, groundZ, heading, true, false)
    if not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'VIP Shop',
            description = 'Failed to create vehicle',
            type = 'error'
        })
        return
    end
    
    -- Secure vehicle setup
    SetVehicleNumberPlateText(vehicle, plate)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleDoorsLocked(vehicle, 0)
    
    lib.notify({
        title = 'VIP Shop',
        description = ('Vehicle purchased successfully! Plate: %s'):format(plate),
        type = 'success',
        position = Config.Notifications.position,
        duration = Config.Notifications.duration
    })
    
    SetModelAsNoLongerNeeded(vehicleModel)
end)

-- Secure input handling
CreateThread(function()
    while true do
        Wait(0)
        if State.isOpen and IsControlJustPressed(0, 322) then -- ESC key
            CloseVIPShop()
        end
    end
end)

-- Periodic coin updates with security
CreateThread(function()
    while true do
        Wait(CONSTANTS.COIN_UPDATE_INTERVAL)
        if ESX.IsPlayerLoaded() then
            TriggerServerEvent('vipshop:getCoins')
        end
    end
end)

-- Secure exports
exports('OpenVIPShop', OpenVIPShop)
exports('CloseVIPShop', CloseVIPShop)
exports('GetPlayerCoins', function()
    return State.coins
end)