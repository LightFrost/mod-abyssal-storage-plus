# mod-abyssal-storage-plus

Account-wide interdimensional vault for all profession materials in AzerothCore (WoW WotLK 3.3.5).

Automatically deposits profession materials into a shared vault accessible by all characters on the account. Integrates with crafting and quests so vault materials are used seamlessly.

**This is mod is based on [mod-abyssal-storage](https://github.com/thanhtong89/mod-abyssal-storage)**  

<table>
  <tr>
    <td background-color="#14eebf">  

 ![New Feature](https://img.shields.io/badge/The%20Main%20Differences%20Include-blue)  
- A rewrite of how materials are handled in the crafting interface. Now completely integrates into the default UI instead of using an overlay, which made it difficult to see what recipes you had materials for at a glance. Basically, the interface now visually shows all your vaulted materials directly, just like if you had the materials in your bags.
- Improved abyssal storage addon interface and functionality. Thanks to [Tntdruid](https://github.com/Tntdruid) for some of his contributions. (May get reworked later)
- Now able to easily deposit per-material via right-click when interface is open (Deposit All was the only option before). Also added per item SFX feedback when depositing/withdrawing (same used for banks).
- No longer vaults profession tools on deposit all (if I missed anything, create an issue)
- Keybinds + Minimap icon allowing easier depositing/withdrawing
- If you use playerbots fork, automatically checks for and skips rndbots, significantly reducing unnecessary database queries. Altbots still included. 

*Currently working on other improvements, stay tuned*
    </td>
  </tr>
</table>


## Features
- **Auto-deposit**: Profession materials are automatically vaulted when picked up
- <kbd>**NEW**</kbd> **Crafting integration**: Seamlessly integrates vaulted materials when crafting, both the material counts and craftable recipe amounts take into account all vault stored materials, tested on default Blizzard interface and elvUI. Example screenshots below.
- <kbd>**NEW**</kbd> **Vault-aware filtering**: The "Have Materials" checkbox filters craftable recipes based on total material counts in bags and abyssal storage plus.
- **Quest integration**: Quest-required items are pulled from the vault automatically on turn-in
- **Multi-craft**: "Create All" uses vault materials across the full batch
- **Grid UI**: Searchable item grid with tooltips.
- **Real-time sync**: Vault state syncs on login and updates incrementally
- <kbd>**NEW**</kbd> **Tools protected** : Profession tools and other outliers in the profession category are excluded from Deposit All (runed rods, Gnomish Army Knife, Jeweler's Kit e.t.c).

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
- <kbd>**NEW**</kbd> Deposit All is available under **Key Bindings > AddOns > Abyssal Storage Plus**. New installs default to `Ctrl-B` if that key is unbound. 

## Withdrawing Materials
- Right-click a stored material in the vault to withdraw the full stored amount
- Shift-left-click a stored material to withdraw a specific amount

<img width="692" height="641" alt="mod-abyssal-storage-plus" src="https://github.com/user-attachments/assets/803f2527-a286-4335-9ad9-487205ae8392" />

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
