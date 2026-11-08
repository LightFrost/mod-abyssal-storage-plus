#ifndef ABYSSAL_STORAGE_PLUS_H
#define ABYSSAL_STORAGE_PLUS_H

#include "DataMap.h"
#include "Define.h"
#include <unordered_map>
#include <unordered_set>
#include <string>
#include <vector>

class Player;
struct ItemTemplate;

struct PendingDeposit
{
    uint32 itemEntry;
    uint32 count;
};

// Tracks one vault-pulled stack; baseline is bag count before the pull
struct MaterializedItem
{
    uint32 baseline = 0;
    uint32 amount = 0;
};

// Per-player transient state stored via DataMap
struct AbyssalPlayerData : public DataMap::Base
{
    bool autoStoreEnabled = true;
    bool isMaterializing = false; // true while materializing items (suppress auto-deposit)
    std::unordered_map<uint32, MaterializedItem> materializedItems; // entry -> tracking
    std::vector<PendingDeposit> pendingDeposits; // deferred auto-deposits
    uint32 pendingCrafts = 0;    // remaining crafts in a multi-craft batch
    uint32 pendingSpellId = 0;   // spell ID for multi-craft batch
};

AbyssalPlayerData* GetAbyssalData(Player* player);

class AbyssalStoragePlusMgr
{
public:
    static AbyssalStoragePlusMgr* instance();

    void LoadAccountData(uint32 accountId);
    void UnloadAccountData(uint32 accountId);

    void DepositItem(uint32 accountId, uint32 itemEntry, uint32 count);
    bool WithdrawItem(uint32 accountId, uint32 itemEntry, uint32 count);
    uint32 GetItemCount(uint32 accountId, uint32 itemEntry);
    std::unordered_map<uint32, uint32> GetAllItems(uint32 accountId);

    bool ShouldAutoStore(Player* player, ItemTemplate const* itemTemplate);
    bool ShouldAutoStore(Player* player, ItemTemplate const* itemTemplate,
                         std::unordered_map<uint32, uint32> const* reserved);
    bool IsItemRequiredByActiveQuest(Player* player, uint32 itemId);
    uint32 GetQuestReservedCount(Player* player, uint32 itemId);
    void GetQuestReservedCounts(Player* player, std::unordered_map<uint32, uint32>& out);

    bool IsBotAccount(Player* player);

    // Messaging helpers
    void SendAddonMessage(Player* player, std::string const& message);
    void SendFullSync(Player* player);
    void SendItemUpdate(Player* player, uint32 itemEntry, uint32 count);
    void SendItemDelete(Player* player, uint32 itemEntry);
    void BroadcastItemUpdate(uint32 accountId, uint32 itemEntry);
    void BroadcastFullSync(uint32 accountId);

    bool IsEnabled() const { return _enabled; }
    void SetEnabled(bool enabled) { _enabled = enabled; }

    bool IsAutoUnvaultQuestItemsEnabled() const { return _autoUnvaultQuestItems; }
    void SetAutoUnvaultQuestItems(bool enabled) { _autoUnvaultQuestItems = enabled; }

private:
    AbyssalStoragePlusMgr() = default;

    // accountId -> (itemEntry -> count)
    std::unordered_map<uint32, std::unordered_map<uint32, uint32>> _storage;
    std::unordered_set<uint32> _loadedAccounts; // accounts fully loaded from DB
    std::unordered_map<uint32, uint32> _accountRefs; // accountId -> online characters

    // accountId -> is random bot account (cached, avoids per-call DB lookups)
    std::unordered_map<uint32, bool> _botAccountCache;

    bool _enabled = true;
    bool _autoUnvaultQuestItems = true;
};

#define sAbyssalStoragePlusMgr AbyssalStoragePlusMgr::instance()

#endif // ABYSSAL_STORAGE_PLUS_H
