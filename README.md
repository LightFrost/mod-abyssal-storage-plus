# mod-abyssal-storage-plus

**This mod is based on [mod-abyssal-storage](https://github.com/thanhtong89/mod-abyssal-storage)**  
If migrating from this mod, just replace the module & addon with mine. It still uses the same SQL database table name `abyssal_storage` so if you had items stored already, they will still be there.

---

**Account-wide interdimensional vault for all profession materials in AzerothCore (WoW WotLK 3.3.5)**

### How it works
**Storing** - Automatically deposits looted/created profession materials into a shared account-wide vault. Your vaulted materials are visible and easily managed via the included addon.
<br>
**Crafting** - The profession crafting interface displays your vaulted materials seemlessly. Crafting automatically pulls required materials from the vault into your bags for that craft, Cancelling a craft returns the materials to the vault.

<br>

<table>
  <tr>
    <td background-color="#14eebf">  

 ![New Feature](https://img.shields.io/badge/The%20Main%20Differences%20Include-blue)  
- <kbd>**MAJOR UPDATE**</kbd> A rewrite of how vaulted materials are handled in the crafting interface. Now completely integrates vaulted materials into the default UI instead of using an overlay.
  - <kbd>**OLD**</kbd> Only showed vaulted materials as an overlay if you clicked on each recipe one by one. Didn't show many of a recipe you could craft with vaulted materials, or have a working "Have Materials" filter. 
  - <kbd>**NEW PLUS**</kbd> Now completely takes into account vaulted materials in the base blizzard UI, functions just like if you had those materials in your bags, so things like material counts, how many of a recipe you can craft and the "Have Materials" checkbox all work seamlessly with the vault.
   
     **BEFORE:** <img width="194" height="81" alt="TitaniumBarOLD1" src="https://github.com/user-attachments/assets/9f6fad52-d4bd-4cdb-b772-966f2233b494" />
     **AFTER:** <img width="193" height="78" alt="TitaniumBar 9" src="https://github.com/user-attachments/assets/d61ae12a-1a1c-4502-a7a7-e10b87fb37cf" />

- Cancelling a craft now instantly returns the materials to your vault if they were unvaulted
- Added a new clean **modern interface** which is the default, see screenshots below, you can switch between Modern/Classic anytime by clicking the switch icon in top-left.
- Improved abyssal storage addon interface and functionality (Classic UI). Thanks to [Tntdruid](https://github.com/Tntdruid) for some of his contributions.
- Now able to easily deposit per-material via right-click when abyssal storage interface is open (Deposit All was the only option before). Also added per item SFX feedback when depositing/withdrawing (same used for banks).
- No longer vaults profession tools on deposit all (if I missed anything, create an issue)
- Keybinds + Minimap icon allowing easier depositing/withdrawing
- If you use playerbots fork, automatically checks for and skips rndbots, significantly reducing unnecessary database queries. Altbots still included. 

*Currently working on other improvements, stay tuned*
    </td>
  </tr>
</table>

## Features
- **Auto-deposit**: Profession materials are automatically vaulted when picked up
- <kbd>**NEW**</kbd> **Crafting integration**: Seamlessly integrates vaulted materials when crafting, both the material counts and craftable recipe amounts take into account all vault stored materials, tested on default Blizzard interface and elvUI. Example screenshots below
- <kbd>**NEW**</kbd> **Vault-aware filtering**: The "Have Materials" checkbox filters craftable recipes based on total material counts in bags and abyssal storage plus
- **Quest integration**: Quest-required items are pulled from the vault automatically on turn-in
- **Multi-craft**: "Create All" uses vault materials across the full batch
- **Grid UI**: Searchable item grid with tooltips
- **Real-time sync**: Vault state syncs on login and updates incrementally
- <kbd>**NEW**</kbd> **Tools protected** : Profession tools and other outliers in the profession category are excluded from Deposit All (runed rods, Gnomish Army Knife, Jeweler's Kit etc.)

## Opening the Vault
- Right-clicking the backpack
- Type `/asp`
- Press Open All Bags Keybind (default `Shift-B`); the vault opens alongside your bags
- <kbd>**NEW**</kbd> Left-click the minimap icon (drag it to reposition)

## Depositing Materials
- Items should automatically get deposited on pickup
- Click "Deposit All" in the abyssal storage interface
- <kbd>**NEW**</kbd> Right-click a material in your bags while the vault is open
- <kbd>**NEW**</kbd> Right-click the addon's minimap icon to Deposit All
- <kbd>**NEW**</kbd> Deposit All is available under **Key Bindings > AddOns > Abyssal Storage Plus**
   - New installs default to `Ctrl-B` if that key is unbound

## Withdrawing Materials
- Right-click a stored material in the vault to withdraw the full stored amount
- Shift-left-click a stored material to withdraw a specific amount

## Abyssal Storage Plus Interface

### <kbd>**NEW**</kbd> Modern UI (You can Toggle Between Modern/Classic Any time by clicking the icon in the top-left)
<img width="959" height="718" alt="Window 1586 01-11-2026 (World_of_Warcraft)" src="https://github.com/user-attachments/assets/9c404bdb-e81b-493b-a3d6-52214dce5d71" />

### Blizzard Frames + Classic UI
<img width="1449" height="713" alt="BlizzardUI-Abyssal-Storage" src="https://github.com/user-attachments/assets/7f448223-55c3-44e0-a718-aa4182c56402" />

### ElvUI Frames + Classic UI
<img width="1583" height="562" alt="ElvUI-Abyssal-Storage" src="https://github.com/user-attachments/assets/a9e4ff26-75f8-4f6e-9fef-4c6e6ebf54e8" />


## Commands
| Command | Description |
|---|---|
| `/asp` | Toggle the vault UI |
| `/asp deposit` | Deposit all trade goods from inventory |
| `/asp deposit <itemId> [count]` | Deposit one material type |
| `/asp withdraw <itemId> [count]` | Withdraw items (omit count for all) |
| `/asp sync` | Force re-sync from server |

## Configuration
In `mod_abyssal_storage_plus.conf`:

```
AbyssalStoragePlus.Enable = 1
```

## Installation
1. Clone into `modules/mod-abyssal-storage-plus`
2. Re-run  CMake and build 
3. rename `mod_abyssal_storage_plus.conf.dist` to `mod_abyssal_storage_plus.conf` & make sure it is in your server `/configs/` directory
4. The `abyssal_storage` table should be automatically created in your `acore_characters` database on server start. If the table is missing, run `data/sql/db-characters/abyssal_storage_plus.sql` against your `acore_characters` database
5. Copy the `addon/AbyssalStoragePlus` folder into your WoW `Interface/AddOns` directory
