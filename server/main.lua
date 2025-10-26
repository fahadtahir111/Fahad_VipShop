--[[
    VIP Shop Server - Optimized & Secured
    Features:
    - Modern Lua security practices
    - Anti-hack measures
    - Rate limiting
    - Input validation
    - Secure database operations
    - Memory optimization
]]

local ESX = exports['es_extended']:getSharedObject()
local ox_inventory = exports.ox_inventory

-- Secure state management
local State = {
    playerCoins = {},
    playerData = {},
    initializingPlayers = {},
    purchaseAttempts = {},
    lastCoinUpdate = {}
}

-- Security constants
local SECURITY = {
    MAX_PURCHASE_ATTEMPTS = 10,
    ATTEMPT_RESET_TIME = 300000, -- 5 minutes
    PURCHASE_COOLDOWN = 2000, -- 2 seconds
    MAX_COINS = 999999,
    MIN_COINS = 0,
    MAX_PRICE = 100000,
    MIN_PRICE = 1
}

-- Input validation utilities
local function ValidateInput(input, expectedType, min, max)
    if type(input) ~= expectedType then return false end
    if expectedType == 'string' and (input == '' or input == nil) then return false end
    if expectedType == 'number' then
        if min and input < min then return false end
        if max and input > max then return false end
    end
    return true
end

-- Secure event triggering
local function SafeTriggerClientEvent(eventName, target, ...)
    if not target or GetPlayerPing(target) <= 0 then
        if Config.Debug then
            print(('[VIPShop] Attempted to trigger event for invalid player: %s'):format(tostring(target)))
        end
        return false
    end
    TriggerClientEvent(eventName, target, ...)
    return true
end

-- Rate limiting for purchases
local function IsPurchaseRateLimited(source)
    local now = GetGameTimer()
    local attempts = State.purchaseAttempts[source] or 0
    
    if attempts >= SECURITY.MAX_PURCHASE_ATTEMPTS then
        if Config.Debug then
            print(('[VIPShop] Player %s rate limited for excessive purchase attempts'):format(source))
        end
        return true
    end
    
    State.purchaseAttempts[source] = attempts + 1
    
    -- Reset attempts after timeout
    SetTimeout(SECURITY.ATTEMPT_RESET_TIME, function()
        if State.purchaseAttempts[source] then
            State.purchaseAttempts[source] = math.max(0, State.purchaseAttempts[source] - 1)
        end
    end)
    
    return false
end

-- Secure player initialization
local function InitializePlayer(source)
    if not ValidateInput(source, 'number', 1, 255) then return false end
    
    -- Prevent re-initialization
    if State.initializingPlayers[source] or State.playerData[source] then
        if Config.Debug and State.initializingPlayers[source] then
            print(('[VIPShop] Initialization for player %s already in progress'):format(source))
        end
        return false
    end
    
    State.initializingPlayers[source] = true
    
    -- Wait for ESX player
    local xPlayer = ESX.GetPlayerFromId(source)
    local attempts = 0
    while not xPlayer and attempts < 10 do
        Wait(200)
        xPlayer = ESX.GetPlayerFromId(source)
        attempts = attempts + 1
    end
    
    if not xPlayer then
        if Config.Debug then
            print(('[VIPShop] Failed to load ESX player for source: %s'):format(source))
        end
        State.initializingPlayers[source] = nil
        return false
    end
    
    local identifier = xPlayer.identifier
    if not ValidateInput(identifier, 'string') then
        if Config.Debug then
            print(('[VIPShop] Invalid identifier for player: %s'):format(source))
        end
        State.initializingPlayers[source] = nil
        return false
    end
    
    -- Secure database initialization
    MySQL.update('INSERT IGNORE INTO user_coins (identifier, coins) VALUES (?, ?)', 
    {identifier, Config.DefaultCoins}, function()
        MySQL.single('SELECT coins FROM user_coins WHERE identifier = ?', {identifier}, function(result)
            if not result then
                print(('[VIPShop] ERROR: Failed to load coins for %s'):format(identifier))
                State.initializingPlayers[source] = nil
                return
            end
            
            State.playerCoins[source] = result.coins
            State.playerData[source] = {
                identifier = identifier,
                lastPurchase = 0,
                lastCoinUpdate = GetGameTimer(),
                source = source
            }
            
            State.initializingPlayers[source] = nil
            SafeTriggerClientEvent('vipshop:updateCoins', source, State.playerCoins[source])
            
            if Config.Debug then
                print(('[VIPShop] Player initialized: %s (%s) with %d coins'):format(
                    GetPlayerName(source), identifier, State.playerCoins[source]))
            end
        end)
    end)
    
    return true
end

-- Secure plate generation
local function GeneratePlate()
    local charset = {}
    for i = 48, 57 do table.insert(charset, string.char(i)) end  -- 0-9
    for i = 65, 90 do table.insert(charset, string.char(i)) end  -- A-Z
    
    math.randomseed(os.time() * (GetGameTimer() % 1000))
    local plate = ""
    for i = 1, 8 do
        plate = plate .. charset[math.random(1, #charset)]
    end
    return plate
end

-- Secure item validation
local function ValidateItemData(clientData)
    if not clientData or type(clientData) ~= 'table' then return nil end
    if not ValidateInput(clientData.id, 'string') then return nil end
    if not ValidateInput(clientData.price, 'number', SECURITY.MIN_PRICE, SECURITY.MAX_PRICE) then return nil end
    if not ValidateInput(clientData.type, 'string') then return nil end
    
    -- Find item in server config
    for _, category in pairs(Config.Categories) do
        for _, item in ipairs(category.items) do
            if item.id == clientData.id and item.price == clientData.price and item.type == clientData.type then
                return item -- Return server config data, not client data
            end
        end
    end
    return nil
end

-- Events
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    InitializePlayer(playerId)
end)

RegisterNetEvent('vipshop:playerLoaded', function()
    InitializePlayer(source)
end)

RegisterNetEvent('vipshop:getCoins', function()
    local source = source
    local data = State.playerData[source]
    
    if not data then
        if Config.Debug then
            print(('[VIPShop] Player data not found for source %s on getCoins'):format(source))
        end
        InitializePlayer(source)
        return
    end
    
    -- Secure database query
    MySQL.single('SELECT coins FROM user_coins WHERE identifier = ?', {data.identifier}, function(result)
        if result then
            State.playerCoins[source] = result.coins
            data.lastCoinUpdate = GetGameTimer()
            SafeTriggerClientEvent('vipshop:updateCoins', source, State.playerCoins[source])
        else
            State.playerCoins[source] = 0
            SafeTriggerClientEvent('vipshop:updateCoins', source, 0)
            if Config.Debug then
                print(('[VIPShop] Could not find coins for %s'):format(data.identifier))
            end
        end
    end)
end)

RegisterNetEvent('vipshop:purchaseItem', function(clientItemData)
    local source = source
    local now = os.time()
    local data = State.playerData[source]
    
    if Config.Debug then
        print(('[VIPShop] Purchase attempt from %s: %s'):format(source, json.encode(clientItemData)))
    end
    
    -- Basic validation
    if not data then
        return SafeTriggerClientEvent('vipshop:purchaseFailed', source, 'Player not initialized')
    end
    
    -- Rate limiting
    if IsPurchaseRateLimited(source) then
        return SafeTriggerClientEvent('vipshop:purchaseFailed', source, 'Too many purchase attempts')
    end
    
    -- Anti-spam check
    if (data.lastPurchase or 0) > now - (SECURITY.PURCHASE_COOLDOWN / 1000) then
        return SafeTriggerClientEvent('vipshop:purchaseFailed', source, 'Please wait between purchases')
    end
    data.lastPurchase = now
    
    -- Validate item data
    local itemData = ValidateItemData(clientItemData)
    if not itemData then
        if Config.Debug then
            print(('[VIPShop] Invalid item data from %s'):format(source))
        end
        return SafeTriggerClientEvent('vipshop:purchaseFailed', source, 'Invalid item')
    end
    
    -- Check coins
    local currentCoins = State.playerCoins[source] or 0
    if Config.Debug then
        print(('[VIPShop] Player %s has %d coins, item costs %d'):format(source, currentCoins, itemData.price))
    end
    
    if currentCoins < itemData.price then
        return SafeTriggerClientEvent('vipshop:purchaseFailed', source, 'Insufficient coins')
    end
    
    -- Pre-flight inventory check
    if itemData.type == 'item' or itemData.type == 'weapon' then
        if not ox_inventory:CanCarryItem(source, itemData.id, itemData.amount or 1, itemData.metadata or {}) then
            return SafeTriggerClientEvent('vipshop:purchaseFailed', source, 'Inventory is full')
        end
    end
    
    -- Secure transaction
    MySQL.update('UPDATE user_coins SET coins = coins - ? WHERE identifier = ? AND coins >= ?', 
    {itemData.price, data.identifier, itemData.price}, function(rowsChanged)
        if rowsChanged > 0 then
            State.playerCoins[source] = currentCoins - itemData.price
            SafeTriggerClientEvent('vipshop:updateCoins', source, State.playerCoins[source])
            
            local function handleSuccess(message)
                MySQL.insert('INSERT INTO vip_purchases (identifier, item_id, item_name, price) VALUES (?, ?, ?, ?)', 
                {data.identifier, itemData.id, itemData.name, itemData.price})
                SafeTriggerClientEvent('vipshop:purchaseSuccess', source, itemData.name)
                lib.notify(source, { title = 'VIP Shop', description = message, type = 'success' })
                if Config.Debug then
                    print(('[VIPShop] %s purchased %s for %d coins'):format(data.identifier, itemData.name, itemData.price))
                end
            end
            
            local function handleFailure(message)
                -- Refund coins
                MySQL.update('UPDATE user_coins SET coins = coins + ? WHERE identifier = ?', 
                {itemData.price, data.identifier})
                State.playerCoins[source] = currentCoins
                SafeTriggerClientEvent('vipshop:updateCoins', source, State.playerCoins[source])
                SafeTriggerClientEvent('vipshop:purchaseFailed', source, message)
            end
            
            if itemData.type == 'weapon' or itemData.type == 'item' then
                local success = ox_inventory:AddItem(source, itemData.id, itemData.amount or 1, itemData.metadata or {})
                if success then
                    handleSuccess((itemData.type == 'weapon' and 'Weapon' or 'Item') .. ' purchased')
                else
                    handleFailure('Could not add item to inventory')
                end
            elseif itemData.type == 'vehicle' then
                local plate = GeneratePlate()
                local vehicleProps = { 
                    model = itemData.model, 
                    plate = plate, 
                    fuel = itemData.metadata and itemData.metadata.fuel or 100, 
                    engine = itemData.metadata and itemData.metadata.engine or 1000, 
                    body = itemData.metadata and itemData.metadata.body or 1000 
                }
                MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)', 
                {data.identifier, plate, json.encode(vehicleProps), 'car', 1}, function()
                    SafeTriggerClientEvent('vipshop:spawnVehicle', source, itemData.model, plate)
                    handleSuccess(('Vehicle %s purchased with plate %s'):format(itemData.name, plate))
                end)
            else
                handleFailure('Unknown item type')
            end
        else
            SafeTriggerClientEvent('vipshop:purchaseFailed', source, 'Transaction failed, please try again')
        end
    end)
end)

-- Secure admin command
lib.addCommand('addcoins', {
    help = 'Add coins to a player',
    params = {
        { name = 'target', type = 'playerId', help = 'Target player ID' },
        { name = 'amount', type = 'number', help = 'Amount of coins to add (1-10000)' }
    },
    restricted = Config.AdminAce
}, function(source, args)
    local amount = tonumber(args.amount)
    if not ValidateInput(amount, 'number', 1, 10000) then
        return lib.notify(source, {
            title = 'VIP Shop',
            description = 'Amount must be between 1-10000',
            type = 'error'
        })
    end
    
    local target = tonumber(args.target)
    if not ValidateInput(target, 'number', 1, 255) or not State.playerData[target] then
        return lib.notify(source, {
            title = 'VIP Shop',
            description = 'Player not found',
            type = 'error'
        })
    end
    
    MySQL.update('UPDATE user_coins SET coins = coins + ? WHERE identifier = ?', 
    {amount, State.playerData[target].identifier}, function(rowsChanged)
        if rowsChanged > 0 then
            State.playerCoins[target] = (State.playerCoins[target] or 0) + amount
            SafeTriggerClientEvent('vipshop:updateCoins', target, State.playerCoins[target])
            
            lib.notify(source, {
                title = 'VIP Shop',
                description = ('Added %d coins to %s'):format(amount, GetPlayerName(target)),
                type = 'success'
            })
            
            lib.notify(target, {
                title = 'VIP Shop',
                description = ('You received %d coins from admin'):format(amount),
                type = 'success'
            })
        else
            lib.notify(source, {
                title = 'VIP Shop',
                description = 'Failed to add coins',
                type = 'error'
            })
        end
    end)
end)

-- Test command to check coins
lib.addCommand('checkcoins', {
    help = 'Check your current coin balance',
    params = {}
}, function(source, args)
    local data = State.playerData[source]
    if not data then
        return lib.notify(source, {
            title = 'VIP Shop',
            description = 'Player not initialized',
            type = 'error'
        })
    end
    
    local coins = State.playerCoins[source] or 0
    lib.notify(source, {
        title = 'VIP Shop',
        description = ('You have %d coins'):format(coins),
        type = 'inform'
    })
    
    if Config.Debug then
        print(('[VIPShop] Player %s checked coins: %d'):format(source, coins))
    end
end)

-- Test command to give coins (for debugging)
lib.addCommand('givecoins', {
    help = 'Give yourself test coins (debug only)',
    params = {
        { name = 'amount', type = 'number', help = 'Amount of coins to give (1-1000)' }
    }
}, function(source, args)
    if not Config.Debug then
        return lib.notify(source, {
            title = 'VIP Shop',
            description = 'This command is only available in debug mode',
            type = 'error'
        })
    end
    
    local amount = tonumber(args.amount) or 100
    if not ValidateInput(amount, 'number', 1, 1000) then
        return lib.notify(source, {
            title = 'VIP Shop',
            description = 'Amount must be between 1-1000',
            type = 'error'
        })
    end
    
    local data = State.playerData[source]
    if not data then
        return lib.notify(source, {
            title = 'VIP Shop',
            description = 'Player not initialized',
            type = 'error'
        })
    end
    
    MySQL.update('UPDATE user_coins SET coins = coins + ? WHERE identifier = ?', 
    {amount, data.identifier}, function(rowsChanged)
        if rowsChanged > 0 then
            State.playerCoins[source] = (State.playerCoins[source] or 0) + amount
            SafeTriggerClientEvent('vipshop:updateCoins', source, State.playerCoins[source])
            
            lib.notify(source, {
                title = 'VIP Shop',
                description = ('You received %d test coins'):format(amount),
                type = 'success'
            })
            
            print(('[VIPShop] Debug: Player %s received %d test coins'):format(source, amount))
        else
            lib.notify(source, {
                title = 'VIP Shop',
                description = 'Failed to give coins',
                type = 'error'
            })
        end
    end)
end)

-- Secure data synchronization
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        
        for source, data in pairs(State.playerData) do
            if data and GetPlayerPing(source) > 0 then
                MySQL.single('SELECT coins FROM user_coins WHERE identifier = ?', {data.identifier}, function(result)
                    if result and State.playerCoins[source] and State.playerCoins[source] ~= result.coins then
                        if Config.Debug then
                            print(('[VIPShop] Auto-refreshing coins for %s. Old: %s, New: %s'):format(data.identifier, State.playerCoins[source], result.coins))
                        end
                        State.playerCoins[source] = result.coins
                        data.lastCoinUpdate = GetGameTimer()
                        SafeTriggerClientEvent('vipshop:updateCoins', source, State.playerCoins[source])
                    end
                end)
            end
        end
    end
end)

-- Secure cleanup
AddEventHandler('playerDropped', function()
    local source = source
    State.playerCoins[source] = nil
    State.playerData[source] = nil
    State.initializingPlayers[source] = nil
    State.purchaseAttempts[source] = nil
    State.lastCoinUpdate[source] = nil
    
    if Config.Debug then
        print(('[VIPShop] Cleaned up data for player: %s'):format(source))
    end
end)

-- Secure utility functions
local function IsPlayerAdmin(playerId)
    return IsPlayerAceAllowed(playerId, Config.AdminAce)
end

-- Secure initialization
CreateThread(function()
    while not ESX do
        Wait(100)
    end
    
    -- Test database connection
    MySQL.single('SELECT 1 as test', {}, function(result)
        if result then
            print('[VIPShop] Database connection successful')
        else
            print('[VIPShop] ERROR: Database connection failed')
        end
    end)
    
    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        InitializePlayer(playerId)
    end
    
    print('[VIPShop] Script successfully initialized with security measures')
end)