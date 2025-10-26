Config = {}

-- General Settings
Config.Command = 'vipshop'
Config.Currency = 'coins' -- coins, money, bank
Config.DefaultCoins = 100
Config.Debug = true

-- Notification settings
Config.Notifications = {
    position = 'top-right', -- ox_lib notification position
    duration = 5000
}

-- Shop Categories and Items
Config.Categories = {
    {
        id = 'weapons',
        name = 'Weapons',
        icon = 'fas fa-gun',
        items = {
            {
                id = 'weapon_carbinerifle',
                name = 'AK-47',
                description = 'Powerful assault rifle',
                price = 500,
                image = 'images/weapons/weapon_ak47.png',
                type = 'weapon',
                metadata = { durability = 100, serial = 'VIP-AK47' }
            },
            {
                id = 'weapon_pistol',
                name = 'Pistol',
                description = 'Standard sidearm',
                price = 150,
                image = 'images/weapons/WEAPON_PISTOL.png',
                type = 'weapon',
                metadata = { durability = 100, serial = 'VIP-PISTOL' }
            }
        }
    },
    {
        id = 'vehicles',
        name = 'Vehicles',
        icon = 'fas fa-car',
        items = {
            {
                id = 'adder',
                name = 'Adder',
                description = 'Super fast sports car',
                price = 2000,
                image = 'images/vehicles/adder.png',
                type = 'vehicle',
                model = 'adder',
                metadata = { fuel = 100, engine = 1000, body = 1000 }
            },
            {
                id = 'zentorno',
                name = 'Zentorno',
                description = 'Luxury supercar',
                price = 1800,
                image = 'images/vehicles/Zentorno.png',
                type = 'vehicle',
                model = 'zentorno',
                metadata = { fuel = 100, engine = 1000, body = 1000 }
            }
        }
    },
    {
        id = 'items',
        name = 'Items',
        icon = 'fas fa-box',
        items = {
            {
                id = 'bread',
                name = 'Bread',
                description = 'Fresh baked bread',
                price = 10,
                image = 'images/items/bread.png',
                type = 'item',
                amount = 5,
                metadata = { quality = 100 }
            },
            {
                id = 'water',
                name = 'Water',
                description = 'Clean drinking water',
                price = 5,
                image = 'images/items/water.png',
                type = 'item',
                amount = 3,
                metadata = { quality = 100 }
            }
        }
    }
}

-- Admin ace permission
Config.AdminAce = 'vipshop.admin'

-- UI Settings
Config.Themes = {
    {
        id = 'dark',
        name = 'Dark Theme',
        primary = '#6366f1',
        secondary = '#8b5cf6',
        background = '#1f2937',
        surface = '#374151'
    },
    {
        id = 'light',
        name = 'Light Theme',
        primary = '#3b82f6',
        secondary = '#8b5cf6',
        background = '#f9fafb',
        surface = '#ffffff'
    },
    {
        id = 'neon',
        name = 'Neon Theme',
        primary = '#00ff88',
        secondary = '#ff0080',
        background = '#0a0a0a',
        surface = '#1a1a1a'
    },
    {
        id = 'purple',
        name = 'Purple Theme',
        primary = '#8b5cf6',
        secondary = '#a855f7',
        background = '#1e1b4b',
        surface = '#312e81'
    }
}