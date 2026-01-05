# Simple Profession Filter

A minimalist profession filtering addon for World of Warcraft Classic Era that enhances the default profession interface with powerful search and filtering capabilities.

## Features

### 🔍 Smart Search
- **Search by recipe name** - Find recipes quickly by typing their name
- **Search by materials** - Type any reagent name to find all recipes that use it
- **Shift+Click insertion** - Shift+Click any item (bag, chat, recipe) to insert its name into the search box
  - *New:* Works even if the search box is not focused (frame must be open)
  - *New:* Automatically replaces current text with the clicked item name
- **Real-time filtering** - Results update as you type
- **Clear button** - Quickly clear your search with one click

### ✨ Advanced Filtering
- **Skill up filter** - Show only recipes that will increase your skill
- **Have materials filter** - Show only recipes you have materials for
- **Enchanting Categories** - Dedicated slot-based filtering (Boots, Bracer, Weapon, etc.) with support for most official WoW languages.
- **Combined filters** - Use multiple filters together for precise results

### ⚙️ Settings & Persistence
- **Options Panel** - Integrated into the Blizzard Options menu
- **Slash Commands** - Use `/spf` to open settings directly
- **Filter Persistence** - Optional setting to remember your search text and checkbox selections across sessions
- **Customizable Focus** - Toggle whether Shift+Click works with or without explicit focus

### 🎨 Clean Interface
- **Compact design** - Fits seamlessly into the default UI

### 🔧 Compatibility
- **Leatrix Plus integration** - Automatically detects and respects Leatrix Plus settings

## Installation

### Manual Installation
1. Download the latest release
2. Extract the `SimpleProfessionFilter` folder
3. Place it in `World of Warcraft\_classic_era_\Interface\AddOns\`
4. Restart WoW or reload UI (`/reload`)

## Usage

1. Open any profession window (Blacksmithing, Alchemy, Enchanting, etc.)
2. Use the search box to find recipes by name or material
3. Toggle "Skill up" to show only recipes that increase your skill
4. Toggle "Have mats" to show only craftable recipes
5. Click the X button or press ESC to clear your search
6. **Shift+Click** items in your bag or chat to instantly search for them
7. Access settings via **Escape > Options > AddOns > Simple Profession Filter** or type `/spf`

### Examples
- Type `"copper"` to find all recipes using Copper Bar or Copper Ore
- Type `"heavy"` to find Heavy Armor Kit, Heavy Leather, etc.
- Enable "Skill up" + "Have mats" to see what you can craft for skill points

## Screenshots

### Default UI (Blizzard)

![TradeSkill Default](https://i.ibb.co/C535wcKF/Blizz-default.png)
![Enchanting Default](https://i.ibb.co/j9G1QR6D/Blizz-ench-default.png)

### Search Feature

![Search Filter](https://i.ibb.co/hJtmDt84/Blizz-search.png)

### Filters

![Have Materials Filter](https://i.ibb.co/KpFLqTN2/Blizz-have-mats.png)
![Skill Up Filter](https://i.ibb.co/FLX5LvHK/Blizz-skill-up.png)

### With Leatrix Plus

![LP Default](https://i.ibb.co/3926cS5b/LP-default.png)
![LP Enchanting](https://i.ibb.co/wNJKtfXD/LP-ench-default.png)
![LP Search](https://i.ibb.co/9kzNjk7q/LP-search.png)
![LP Have Materials](https://i.ibb.co/Q7X1vbNS/LP-have-mats.png)
![LP Skill Up](https://i.ibb.co/gMqsZpjT/LP-skill-up.png)

## Compatibility Notes

SimpleProfessionFilter is designed to be lightweight and compatible with most profession-related addons. If you encounter any issues, please report them on GitHub.

## Technical Details

- **Interface Version**: 11508 (Classic Era 1.15.x)
- **Memory Usage**: ~80 KB
- **Performance**: High-performance filtering with localized globals and weak-keyed caching

### Contributing
Contributions are welcome! Please feel free to submit issues or pull requests.

## Credits

- **Author**: KrevenRess
- **Made with**: ❤️ from 🇺🇦 Ukraine

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**For World of Warcraft Classic Era**  
*A lightweight, powerful profession filtering solution*

