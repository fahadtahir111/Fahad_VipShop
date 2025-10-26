# FiveM VIP Shop Script

A comprehensive VIP shop system for FiveM with modern React UI, coins economy, and ox framework integration.

## Features

- 🛍️ **Advanced Shop System** - Categories for weapons, vehicles, items, and VIP packages
- 💰 **Coins Economy** - Earn coins through playtime and spend them in the shop
- 🎨 **Modern UI** - React-based interface with multiple themes and smooth animations
- 🔧 **ox Framework Integration** - Full compatibility with oxmysql, ox_inventory, and ox_lib
- 👑 **VIP System** - Time-based VIP packages with database tracking
- 📊 **Admin Panel** - Manage player coins and view purchase history
- 🎯 **Responsive Design** - Works perfectly on all screen sizes
- 🔔 **Smart Notifications** - ox_lib notification system integration

## Dependencies

- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_lib](https://github.com/overextended/ox_lib)

## Installation

1. **Download and extract** the script to your resources folder
2. **Install dependencies** if not already installed
3. **Add to server.cfg**:
   ```
   ensure oxmysql
   ensure ox_inventory
   ensure ox_lib
   ensure vipshop
   ```
4. **Configure database** - The script will automatically create required tables
5. **Add images** to the `images/` folder following the structure in config.lua
6. **Build the UI**:
   ```bash
   cd web
   npm install
   npm run build
   ```

## Configuration

Edit `config.lua` to customize:

- **Shop items and categories**
- **Coin rewards and pricing**
- **Theme colors and UI settings**
- **Admin permissions**
- **Notification settings**

## Usage

### For Players
- Use `/vipshop` command or press `F7` to open the shop
- Browse categories and purchase items with coins
- Earn coins automatically through playtime
- Switch between different UI themes

### For Admins
- Use `/addcoins [playerid] [amount]` to give coins to players
- Requires `vipshop.admin` ace permission
- View purchase history in the database

## Database Tables

The script creates these tables automatically:

- `user_coins` - Player coin balances and statistics
- `vip_purchases` - Purchase history tracking
- `user_vip` - VIP status and expiration dates

## API Exports

```lua
-- Open the shop for a player
exports.vipshop:OpenVIPShop()

-- Close the shop
exports.vipshop:CloseVIPShop()

-- Get player's current coins
local coins = exports.vipshop:GetPlayerCoins()
```

## Customization

### Adding New Items

1. Edit `config.lua` and add items to the appropriate category
2. Add item images to the `images/` folder
3. Ensure ox_inventory has the item configured

### Creating New Themes

Add new themes to `Config.Themes` in config.lua:

```lua
{
    id = 'custom',
    name = 'Custom Theme',
    primary = '#ff6b6b',
    secondary = '#4ecdc4',
    background = '#2c3e50',
    surface = '#34495e'
}
```

### Custom Vehicle Spawning

The script integrates with ox_inventory and supports custom vehicle metadata. Vehicles are spawned with proper positioning and can include fuel, engine health, and body damage values.

## Support

For issues and support:
1. Check the console for error messages
2. Ensure all dependencies are up to date
3. Verify database permissions
4. Check that ox_inventory items are properly configured

## License

This script is provided as-is for educational and development purposes.