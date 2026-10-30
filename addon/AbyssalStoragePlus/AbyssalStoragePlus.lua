-- Abyssal Storage Plus - Core Logic
AbyssalStoragePlus = AbyssalStoragePlus or {}
AbyssalStoragePlus.items = {} -- { [itemEntry] = count }
AbyssalStoragePlus.vaultVersion = 0
AbyssalStoragePlus.PREFIX = "ABYS"
AbyssalStoragePlusDB = AbyssalStoragePlusDB or {}

BINDING_HEADER_ABYSSALSTORAGEPLUS = "Abyssal Storage Plus"
BINDING_NAME_ABYSSALSTORAGEPLUS_DEPOSITALL = "Deposit All"

local function ApplyDefaultDepositBinding()
    if AbyssalStoragePlusDB.depositBindingInitialized then return end

    if GetBindingKey("ABYSSALSTORAGEPLUS_DEPOSITALL") then
        AbyssalStoragePlusDB.depositBindingInitialized = true
        return
    end

    local applied = true
    if GetBindingAction("CTRL-B") == "" then
        if SetBinding("CTRL-B", "ABYSSALSTORAGEPLUS_DEPOSITALL") then
            SaveBindings(GetCurrentBindingSet())
        else
            applied = false
        end
    end

    if applied then
        AbyssalStoragePlusDB.depositBindingInitialized = true
    end
end

-- ============================================================================
-- Utility
-- ============================================================================

local function ParseItemEntry(str)
    return tonumber(str)
end

-- Simple timer for 3.3.5 (no C_Timer)
local timerFrame = CreateFrame("Frame")
local activeTimers = {}
timerFrame:SetScript("OnUpdate", function(self, elapsed)
    local i = 1
    while i <= #activeTimers do
        local t = activeTimers[i]
        t.remaining = t.remaining - elapsed
        if t.remaining <= 0 then
            table.remove(activeTimers, i)
            local ok, err = pcall(t.callback)
            if not ok then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Abyssal Storage Plus timer error: " .. tostring(err) .. "|r")
            end
        else
            i = i + 1
        end
    end
    if #activeTimers == 0 then
        self:Hide()
    end
end)
timerFrame:Hide()

function AbyssalStoragePlus.SetTimer(delay, callback)
    table.insert(activeTimers, { remaining = delay, callback = callback })
    timerFrame:Show()
end

function AbyssalStoragePlus.CancelTimers()
    wipe(activeTimers)
    timerFrame:Hide()
end

-- Extract item entry from an item link: |Hitem:12345:...|h[Name]|h
function AbyssalStoragePlus:EntryFromLink(link)
    if not link then return nil end
    local entry = link:match("item:(%d+)")
    return entry and tonumber(entry) or nil
end

function AbyssalStoragePlus:GetItemCount(entry)
    return self.items[entry] or 0
end

-- cursor trick reuses native item sounds; skips if busy
function AbyssalStoragePlus:PlayItemSound(entry, bag, slot)
    if GetCursorInfo() then return end

    if bag and slot then
        PickupContainerItem(bag, slot)
    else
        if not GetItemInfo(entry) then return end
        PickupItem(entry)
    end

    ClearCursor()
end

-- ============================================================================
-- Server Communication
-- ============================================================================

function AbyssalStoragePlus:SendCommand(cmd)
    SendChatMessage("." .. cmd, "SAY")
end

function AbyssalStoragePlus:Withdraw(entry, count)
    self:PlayItemSound(entry)
    self:SendCommand("asp withdraw " .. entry .. " " .. (count or 0))
end

function AbyssalStoragePlus:Deposit()
    self._depositAllPending = true
    self:SendCommand("asp deposit")
end

function AbyssalStoragePlus:DepositItem(entry, count, bag, slot)
    self:PlayItemSound(entry, bag, slot)
    local cmd = "asp deposit " .. entry .. " " .. (count or 0)
    if bag and slot then
        cmd = cmd .. " " .. bag .. " " .. slot
    end
    self:SendCommand(cmd)
end

function AbyssalStoragePlus:RequestSync()
    self:SendCommand("asp sync")
end

-- ============================================================================
-- Message Parsing
-- ============================================================================

-- msg is the body (arg2 from CHAT_MSG_ADDON), e.g. "SYNC:entry,count;..."
function AbyssalStoragePlus:HandleMessage(msg)
    if not msg then return end

    local cmd = msg:match("^(%u+):")
    local payload = msg:match("^%u+:(.*)")

    if not cmd then return end

    if cmd == "SYNC" then
        self:HandleSync(payload)
    elseif cmd == "UPD" then
        self:HandleUpdate(payload)
    elseif cmd == "DEL" then
        self:HandleDelete(payload)
    elseif cmd == "ERR" then
        self:HandleError(payload)
    end
end

function AbyssalStoragePlus:HandleSync(payload)
    if not payload or payload == "" then
        self.items = {}
        self.vaultVersion = self.vaultVersion + 1
        if self.UpdateUI then self:UpdateUI() end
        return
    end

    -- Parse "entry1,count1;entry2,count2;..."
    -- SYNC messages may arrive in multiple packets — merge instead of replace
    -- We track sync state: first SYNC clears, subsequent ones merge
    if not self._syncActive then
        self.items = {}
        self.vaultVersion = self.vaultVersion + 1
        self._syncActive = true
    end

    for pair in payload:gmatch("[^;]+") do
        local entry, count = pair:match("(%d+),(%d+)")
        if entry and count then
            self.items[tonumber(entry)] = tonumber(count)
            self.vaultVersion = self.vaultVersion + 1
        end
    end

    -- Debounce UI update for multi-packet syncs
    AbyssalStoragePlus.CancelTimers()
    AbyssalStoragePlus.SetTimer(0.1, function()
        AbyssalStoragePlus._syncActive = false
        if AbyssalStoragePlus.UpdateUI then AbyssalStoragePlus:UpdateUI() end
    end)
end

function AbyssalStoragePlus:HandleUpdate(payload)
    if not payload then return end
    local entry, count = payload:match("(%d+),(%d+)")
    if entry and count then
        entry = tonumber(entry)
        count = tonumber(count)
        if count > 0 then
            self.items[entry] = count
        else
            self.items[entry] = nil
        end
        self.vaultVersion = self.vaultVersion + 1
        -- Skip UI refresh during multi-packet SYNC to avoid flashing incomplete data
        if not self._syncActive and self.UpdateUI then self:UpdateUI() end
    end
end

function AbyssalStoragePlus:HandleDelete(payload)
    if not payload then return end
    local entry = tonumber(payload)
    if entry then
        self.items[entry] = nil
        self.vaultVersion = self.vaultVersion + 1
        if not self._syncActive and self.UpdateUI then self:UpdateUI() end
    end
end

function AbyssalStoragePlus:HandleError(payload)
    if payload then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Abyssal Storage Plus: " .. payload .. "|r")
    end
end

-- ============================================================================
-- Event Frame
-- ============================================================================

if RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(AbyssalStoragePlus.PREFIX)
end

local eventFrame = CreateFrame("Frame", "AbyssalStoragePlusEventFrame", UIParent)
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
    if event == "CHAT_MSG_ADDON" then
        -- arg1 = prefix ("ABYS"), arg2 = message body
        if arg1 == AbyssalStoragePlus.PREFIX then
            AbyssalStoragePlus:HandleMessage(arg2)
        end
    elseif event == "CHAT_MSG_SYSTEM" then
        if AbyssalStoragePlus._depositAllPending then
            local count = arg1 and arg1:match("Deposited (%d+) item stacks")
            if count then
                AbyssalStoragePlus._depositAllPending = false
                if tonumber(count) > 0 then PlaySound("PutDownBag") end
            end
        end
    elseif event == "PLAYER_LOGIN" then
        AbyssalStoragePlus:RequestSync()
        ApplyDefaultDepositBinding()
    end
end)

-- ============================================================================
-- Slash Commands
-- ============================================================================

SLASH_ABYSSAL1 = "/asp"
SLASH_ABYSSAL2 = "/abyssal"
SlashCmdList["ABYSSAL"] = function(msg)
    if msg == "" or msg == "show" then
        if AbyssalStoragePlusFrame then
            if AbyssalStoragePlusFrame:IsShown() then
                AbyssalStoragePlusFrame:Hide()
            else
                AbyssalStoragePlusFrame:Show()
                AbyssalStoragePlus:UpdateUI()
                if AbyssalStoragePlus.UpdateUI then
                    AbyssalStoragePlus:UpdateUI()
                end
            end
        end
    elseif msg == "deposit" then
        AbyssalStoragePlus:Deposit()
    elseif msg == "sync" then
        AbyssalStoragePlus:RequestSync()
    else
        local cmd, rest = msg:match("^(%S+)%s*(.*)")
        if cmd == "deposit" then
            local entry, count = rest:match("(%d+)%s*(%d*)")
            if entry then
                AbyssalStoragePlus:DepositItem(tonumber(entry), tonumber(count) or 0)
            else
                AbyssalStoragePlus:Deposit()
            end
        elseif cmd == "withdraw" then
            local entry, count = rest:match("(%d+)%s*(%d*)")
            if entry then
                AbyssalStoragePlus:Withdraw(tonumber(entry), tonumber(count) or 0)
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Usage: /asp withdraw <itemEntry> [count]|r")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffAbyssal Storage Plus Commands:|r")
            DEFAULT_CHAT_FRAME:AddMessage("  /asp - Toggle storage window")
            DEFAULT_CHAT_FRAME:AddMessage("  /asp deposit - Deposit all trade goods")
            DEFAULT_CHAT_FRAME:AddMessage("  Right-click bag materials - Deposit that stack")
            DEFAULT_CHAT_FRAME:AddMessage("  /asp sync - Re-sync from server")
            DEFAULT_CHAT_FRAME:AddMessage("  /asp withdraw <id> [count] - Withdraw items")
        end
    end
end
