-- Database initialization
MySQL.ready(function()
    -- Create coins table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS user_coins (
            identifier VARCHAR(60) PRIMARY KEY,
            coins INT DEFAULT 0,
            total_earned INT DEFAULT 0,
            total_spent INT DEFAULT 0,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- Create purchase history table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS vip_purchases (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL,
            item_id VARCHAR(100) NOT NULL,
            item_name VARCHAR(255) NOT NULL,
            price INT NOT NULL,
            purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_identifier (identifier),
            INDEX idx_purchase_date (purchase_date)
        )
    ]])
    
    print('[VIPShop] Database tables initialized')
end)

-- Helper functions for coin operations
function GetPlayerCoins(identifier)
    local result = MySQL.prepare.await('SELECT coins, total_earned, total_spent FROM user_coins WHERE identifier = ?', { identifier })
    if result then
        return result.coins, result.total_earned, result.total_spent
    else
        -- Initialize new user
        MySQL.insert.await('INSERT INTO user_coins (identifier, coins) VALUES (?, ?)', {
            identifier, Config.DefaultCoins
        })
        return Config.DefaultCoins, 0, 0
    end
end

function UpdatePlayerCoins(identifier, amount, isSpending)
    if isSpending then
        return MySQL.update.await([[
            UPDATE user_coins 
            SET coins = coins - ?, 
                total_spent = total_spent + ?
            WHERE identifier = ? AND coins >= ?
        ]], { amount, amount, identifier, amount })
    else
        return MySQL.update.await([[
            UPDATE user_coins 
            SET coins = coins + ?, 
                total_earned = total_earned + ?
            WHERE identifier = ?
        ]], { amount, amount, identifier })
    end
end

function GetPlayerStats(identifier)
    return MySQL.single.await([[
        SELECT 
            coins,
            total_earned,
            total_spent,
            created_at,
            updated_at
        FROM user_coins 
        WHERE identifier = ?
    ]], { identifier })
end