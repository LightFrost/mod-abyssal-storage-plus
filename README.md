# mod-abyssal-storage

Account-wide interdimensional vault for trade goods in AzerothCore (WoW 3.3.5).

Automatically deposits trade goods into a shared vault accessible by all characters on the account. Integrates with crafting and quests so vault materials are used seamlessly.

## Features

- **Auto-deposit**: Trade goods are automatically vaulted when picked up
- **Crafting integration**: Recipe counts and material totals in profession crafting interfaces are updated to include abyssal storage material counts. The required materials are automatically pulled from abyssal storage when crafting.
- **Vault-aware filtering**: The "Have Materials" checkbox filters craftable recipes from bags plus abyssal storage.
- **Quest integration**: Quest-required items are pulled from the vault automatically on turn-in
- **Multi-craft**: "Create All" uses vault materials across the full batch
- **Grid UI**: Searchable item grid with tooltips.
- **Real-time sync**: Vault state syncs on login and updates incrementally
- **Tools protected**: Profession tools and other outliers in the profession category are excluded from Deposit All (runed rods, Gnomish Army Knife, Jeweler's Kit e.t.c).

## Opening the Vault

- Right-clicking the backpack icon
- Left-click the minimap icon (drag it to reposition)
- Type `/abs`
- Press Open All Bags Keybind (default `Shift-B`); the vault opens alongside your bags

## Depositing Materials
- Items should automatically get deposited on pickup
- Click "Deposit All" in the abyssal storage interface
- Right-click the minimap icon to Deposit All
- Deposit All is available under **Key Bindings > AddOns > Abyssal Storage**. New installs default to `Ctrl-B` if that key is unbound. 

<img width="692" height="641" alt="mod-abyssal-storage" src="https://github.com/user-attachments/assets/803f2527-a286-4335-9ad9-487205ae8392" />

## Commands

| Command | Description |
|---|---|
| `/abs` | Toggle the vault UI |
| `/abs deposit` | Deposit all trade goods from inventory |
| `/abs withdraw <itemId> [count]` | Withdraw items (omit count for all) |
| `/abs sync` | Force re-sync from server |

## Configuration

In `mod_abyssal_storage.conf`:

```
AbyssalStorage.Enable = 1
```

## Installation

1. Clone into `modules/mod-abyssal-storage`
2. Re-run CMake and build
3. Copy `conf/mod_abyssal_storage.conf.dist` to your server's config directory
4. Run `data/sql/db-characters/abyssal_storage.sql` against your characters database
5. Copy the `addon/AbyssalStorage` folder into your WoW `Interface/AddOns` directory
