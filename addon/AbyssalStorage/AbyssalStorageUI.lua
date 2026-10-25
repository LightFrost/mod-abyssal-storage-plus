-- Abyssal Storage - UI Implementation

local ITEMS_PER_ROW = 12
local VISIBLE_ROWS = 8
local CELL_SIZE = 37
local CELL_SPACING = 3
local FRAME_WIDTH = 520
local FRAME_HEIGHT = 480
local FRAME_PADDING = 16
local SEARCH_HEIGHT = 24
local SEARCH_WIDTH = 220
local HEADER_HEIGHT = 32
local SCROLL_WIDTH = 16
local SCROLL_OUTSET = 19

AbyssalStorageDB = AbyssalStorageDB or {}

-- ============================================================================
-- Sorted/Filtered Item List
-- ============================================================================

local displayList = {} -- { {entry=N, count=N, name="...", icon="..."}, ... }
local searchFilter = ""
local selectedCategory = "All"

local CATEGORY_ORDER = {
    "All",
    "Cloth",
    "Leather",
    "Metal & Stone",
    "Herbs",
    "Elemental",
    "Enchanting",
    "Other",
}

local function GetItemCategory(itemType, itemSubType)
    if itemType ~= "Trade Goods" then
        return "Other"
    end

    itemSubType = itemSubType or ""
    if itemSubType == "Cloth" then return "Cloth" end
    if itemSubType == "Leather" then return "Leather" end
    if itemSubType == "Metal & Stone" then return "Metal & Stone" end
    if itemSubType == "Herb" then return "Herbs" end
    if itemSubType == "Elemental" then return "Elemental" end
    if itemSubType == "Enchanting" then return "Enchanting" end
    return "Other"
end

local function BuildDisplayList()
    wipe(displayList)
    for entry, count in pairs(AbyssalStorage.items) do
        local name, _, _, _, _, itemType, itemSubType, _, _, icon = GetItemInfo(entry)
        local category = GetItemCategory(itemType, itemSubType)
        local categoryMatches = selectedCategory == "All" or category == selectedCategory
        if name then
            if categoryMatches and (searchFilter == "" or name:lower():find(searchFilter:lower(), 1, true)) then
                table.insert(displayList, { entry = entry, count = count, name = name, icon = icon })
            end
        else
            -- Item not in client cache yet, show entry ID
            if categoryMatches and searchFilter == "" then
                table.insert(displayList, { entry = entry, count = count, name = "Item #" .. entry, icon = "Interface\\Icons\\INV_Misc_QuestionMark" })
            end
        end
    end
    table.sort(displayList, function(a, b) return a.name < b.name end)
end

-- ============================================================================
-- Main Frame
-- ============================================================================

local frame = CreateFrame("Frame", "AbyssalStorageFrame", UIParent)
frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
frame:SetPoint("CENTER")
frame:SetFrameStrata("MEDIUM")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)
frame:Hide()

-- Dark panel and the same gear-manager header used by MyAutoVendor.
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetTexture("Interface\\Buttons\\WHITE8X8")
bg:SetVertexColor(0.07, 0.07, 0.07, 0.96)

local header = frame:CreateTexture(nil, "ARTWORK")
header:SetPoint("TOPLEFT")
header:SetPoint("TOPRIGHT")
header:SetHeight(HEADER_HEIGHT)
header:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background")

-- ESC to close
tinsert(UISpecialFrames, "AbyssalStorageFrame")

-- Title
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
local titleFont, titleHeight, titleFlags = GameFontHighlightLarge:GetFont()
title:SetFont(titleFont, titleHeight + 2, titleFlags)
title:SetShadowOffset(1, -1)
title:SetPoint("TOP", frame, "TOP", 0, -9)
title:SetText("Abyssal Storage")
title:SetTextColor(1, 0.85, 0)

-- Close button
local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
closeBtn:SetFrameStrata("MEDIUM")

-- ============================================================================
-- Search Bar
-- ============================================================================

local searchBox = CreateFrame("EditBox", "AbyssalStorageSearchBox", frame)
searchBox:SetSize(SEARCH_WIDTH, SEARCH_HEIGHT)
searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING + 52, -(HEADER_HEIGHT + 12))
searchBox:SetFrameStrata("MEDIUM")
searchBox:SetAutoFocus(false)
searchBox:SetMaxLetters(64)
searchBox:SetFontObject(GameFontHighlightSmall)
searchBox:SetTextInsets(8, 8, 6, 6)
searchBox:SetTextColor(0.9, 0.9, 0.9)
searchBox:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
searchBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
searchBox:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
searchBox:EnableMouse(true)
searchBox:SetScript("OnMouseDown", function(self)
    self:SetFocus()
end)

local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchPlaceholder:SetPoint("TOPLEFT", searchBox, "TOPLEFT", 8, -6)
searchPlaceholder:SetText("Search items...")
searchPlaceholder:SetTextColor(0.45, 0.45, 0.45)

searchBox:SetScript("OnTextChanged", function(self)
    searchFilter = self:GetText() or ""
    if searchFilter == "" then
        searchPlaceholder:Show()
    else
        searchPlaceholder:Hide()
    end
    AbyssalStorage:UpdateUI()
end)
searchBox:SetScript("OnEditFocusGained", function(self)
    searchPlaceholder:Hide()
end)
searchBox:SetScript("OnEditFocusLost", function(self)
    if (self:GetText() or "") == "" then
        searchPlaceholder:Show()
    end
end)
searchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

-- Deposit All button
local depositBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
depositBtn:SetSize(90, SEARCH_HEIGHT)
depositBtn:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
depositBtn:SetFrameStrata("MEDIUM")
depositBtn:SetText("Deposit All")
depositBtn:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
depositBtn:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
depositBtn:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
depositBtn:GetNormalTexture():SetVertexColor(0.12, 0.12, 0.12, 0.9)
depositBtn:GetPushedTexture():SetVertexColor(0.18, 0.18, 0.18, 1)
depositBtn:GetHighlightTexture():SetVertexColor(0.25, 0.25, 0.25, 0.9)
depositBtn:GetFontString():SetTextColor(1, 0.85, 0)
depositBtn:SetScript("OnClick", function()
    AbyssalStorage:Deposit()
end)

local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
searchLabel:SetPoint("RIGHT", searchBox, "LEFT", -4, 0)
searchLabel:SetText("Search:")
searchLabel:SetTextColor(1, 0.85, 0)

-- Category filters, matching ReagentBankUI's category-first workflow.
local categoryButtons = {}
local categoryButtonWidth = 114
local categoryButtonHeight = 22
local categoryButtonGap = 6
for index, categoryName in ipairs(CATEGORY_ORDER) do
    local categoryButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    local categoryIndex = index - 1
    local categoryColumn = categoryIndex % 4
    local categoryRow = math.floor(categoryIndex / 4)
    categoryButton:SetSize(categoryButtonWidth, categoryButtonHeight)
    categoryButton:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING + categoryColumn * (categoryButtonWidth + categoryButtonGap), -(HEADER_HEIGHT + 60 + categoryRow * (categoryButtonHeight + 4)))
    categoryButton:SetFrameStrata("MEDIUM")
    categoryButton:SetText(categoryName)
    categoryButton:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
    categoryButton:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
    categoryButton:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    categoryButton:GetPushedTexture():SetVertexColor(0.18, 0.18, 0.18, 1)
    categoryButton:GetHighlightTexture():SetVertexColor(0.25, 0.25, 0.25, 0.9)
    categoryButton:SetScript("OnClick", function()
        selectedCategory = categoryName
        AbyssalStorage:UpdateUI()
    end)
    categoryButtons[categoryName] = categoryButton
end

-- ============================================================================
-- Scroll Frame + Grid
-- ============================================================================

local gridTop = HEADER_HEIGHT + 128
local gridArea = CreateFrame("Frame", nil, frame)
gridArea:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING, -gridTop)
gridArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(FRAME_PADDING + SCROLL_WIDTH), FRAME_PADDING)
gridArea:SetFrameStrata("MEDIUM")

-- Scroll bar (plain Slider, no template)
local scrollBar = CreateFrame("Slider", "AbyssalStorageScrollBar", frame)
scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(FRAME_PADDING + 2) + SCROLL_OUTSET, -(gridTop + 16))
scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(FRAME_PADDING + 2) + SCROLL_OUTSET, FRAME_PADDING + 16)
scrollBar:SetWidth(SCROLL_WIDTH)
scrollBar:SetFrameStrata("MEDIUM")
scrollBar:SetMinMaxValues(0, 0)
scrollBar:SetValueStep(1)
scrollBar:SetValue(0)
scrollBar:SetOrientation("VERTICAL")

local scrollBg = scrollBar:CreateTexture(nil, "BACKGROUND")
scrollBg:SetAllPoints()
scrollBg:SetTexture("Interface\\Buttons\\WHITE8X8")
scrollBg:SetVertexColor(0, 0, 0, 0.3)

local scrollThumb = scrollBar:CreateTexture(nil, "OVERLAY")
scrollThumb:SetTexture("Interface\\Buttons\\WHITE8X8")
scrollThumb:SetVertexColor(1, 0.85, 0, 0.75)
scrollThumb:SetSize(SCROLL_WIDTH, 24)
scrollBar:SetThumbTexture(scrollThumb)

scrollBar:SetScript("OnValueChanged", function(self, value)
    AbyssalStorage:UpdateGrid()
end)

local function ScrollBy(delta)
    local cur = scrollBar:GetValue()
    local minValue, maxValue = scrollBar:GetMinMaxValues()
    scrollBar:SetValue(math.max(minValue, math.min(maxValue, cur - delta)))
end

local function HandleMouseWheel(_, delta)
    ScrollBy(delta)
end

frame:EnableMouseWheel(true)
frame:SetScript("OnMouseWheel", HandleMouseWheel)
gridArea:EnableMouseWheel(true)
gridArea:SetScript("OnMouseWheel", HandleMouseWheel)
scrollBar:EnableMouseWheel(true)
scrollBar:SetScript("OnMouseWheel", HandleMouseWheel)

-- ============================================================================
-- Grid Cells
-- ============================================================================

local cells = {}

local function CreateCell(index)
    local row = math.floor((index - 1) / ITEMS_PER_ROW)
    local col = (index - 1) % ITEMS_PER_ROW

    local cell = CreateFrame("Button", "AbyssalStorageCell" .. index, gridArea)
    cell:SetSize(CELL_SIZE, CELL_SIZE)
    cell:SetPoint("TOPLEFT", gridArea, "TOPLEFT", col * (CELL_SIZE + CELL_SPACING), -row * (CELL_SIZE + CELL_SPACING))
    cell:SetFrameStrata("MEDIUM")

    -- Icon
    local iconTex = cell:CreateTexture(nil, "ARTWORK")
    iconTex:SetSize(CELL_SIZE - 2, CELL_SIZE - 2)
    iconTex:SetPoint("CENTER")
    cell.icon = iconTex

    -- Count text
    local countText = cell:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    countText:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 2)
    countText:SetTextColor(1, 0.85, 0)
    cell.countText = countText

    -- Border (highlight)
    local highlight = cell:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetVertexColor(1, 0.85, 0, 0.18)

    -- Background
    local bg = cell:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.32)
    cell.bg = bg

    -- Tooltip
    cell:SetScript("OnEnter", function(self)
        if self.itemEntry then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self.itemEntry)
            GameTooltip:Show()
            local bags = GetItemCount and (GetItemCount(self.itemEntry, false) or 0) or 0
            local stored = self.itemCount or 0
            GameTooltip:AddDoubleLine("Bags", tostring(bags), 0.78, 0.82, 0.88, 1, 1, 1)
            GameTooltip:AddDoubleLine("Abyssal Storage", tostring(stored), 0.78, 0.82, 0.88, 0.2, 1, 0.6)
            GameTooltip:AddDoubleLine("Total", tostring(bags + stored), 1, 0.85, 0, 1, 0.85, 0)
            GameTooltip:Show()
        end
    end)
    cell:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Click — withdraw dialog; Shift-click — stack split
    cell:SetScript("OnClick", function(self)
        if self.itemEntry and self.itemCount then
            if IsShiftKeyDown() and self.itemCount > 1 then
                OpenStackSplitFrame(self.itemCount, self, "BOTTOMLEFT", "TOPLEFT")
            else
                AbyssalStorage:ShowWithdrawDialog(self.itemEntry, self.itemCount)
            end
        end
    end)

    -- Callback invoked by StackSplitFrame when user confirms a split amount
    cell.SplitStack = function(self, amount)
        if self.itemEntry and amount and amount > 0 then
            AbyssalStorage:ShowWithdrawDialog(self.itemEntry, amount)
        end
    end

    cell.itemEntry = nil
    cell.itemCount = nil

    return cell
end

-- Pre-create cells for visible area
for i = 1, ITEMS_PER_ROW * VISIBLE_ROWS do
    cells[i] = CreateCell(i)
end

-- ============================================================================
-- Withdraw Dialog
-- ============================================================================

StaticPopupDialogs["ABYSSAL_WITHDRAW"] = {
    text = "Withdraw %s x%d from Abyssal Storage?",
    button1 = "Withdraw",
    button2 = "Cancel",
    OnAccept = function(self, data)
        AbyssalStorage:Withdraw(data.entry, data.count)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function AbyssalStorage:ShowWithdrawDialog(entry, count)
    local name, link = GetItemInfo(entry)
    local displayName = link or name or ("Item #" .. entry)
    local dialog = StaticPopup_Show("ABYSSAL_WITHDRAW", displayName, count)
    if dialog then
        dialog.data = { entry = entry, count = count }
    end
end

-- ============================================================================
-- Grid Update
-- ============================================================================

function AbyssalStorage:UpdateGrid()
    local scrollOffset = math.floor(scrollBar:GetValue())
    local startIndex = scrollOffset * ITEMS_PER_ROW + 1
    local totalCells = ITEMS_PER_ROW * VISIBLE_ROWS

    for i = 1, totalCells do
        local cell = cells[i]
        local dataIndex = startIndex + i - 1
        local data = displayList[dataIndex]

        if data then
            cell.icon:SetTexture(data.icon)
            cell.countText:SetText(data.count > 1 and data.count or "")
            cell.itemEntry = data.entry
            cell.itemCount = data.count
            cell:Show()
        else
            cell.icon:SetTexture(nil)
            cell.countText:SetText("")
            cell.itemEntry = nil
            cell.itemCount = nil
            cell:Hide()
        end
    end
end

function AbyssalStorage:UpdateUI()
    if AbyssalStorage.RefreshTradeSkill then
        AbyssalStorage:RefreshTradeSkill()
    end
    if not AbyssalStorageFrame:IsShown() then return end

    BuildDisplayList()

    for categoryName, categoryButton in pairs(categoryButtons) do
        local active = categoryName == selectedCategory
        categoryButton:GetNormalTexture():SetVertexColor(active and 0.55 or 0.12, active and 0.40 or 0.12, active and 0.10 or 0.12, 0.95)
        categoryButton:GetFontString():SetTextColor(active and 1 or 0.85, active and 0.85 or 0.85, active and 0.35 or 0.85)
    end

    local totalRows = math.ceil(#displayList / ITEMS_PER_ROW)
    local maxScroll = math.max(0, totalRows - VISIBLE_ROWS)
    scrollBar:SetMinMaxValues(0, maxScroll)

    -- Clamp scroll position so it doesn't point beyond the display list
    if scrollBar:GetValue() > maxScroll then
        scrollBar:SetValue(maxScroll)
    end
    if maxScroll > 0 then
        scrollBar:Show()
    else
        scrollBar:Hide()
    end

    -- Item count display
    if not frame.itemCountText then
        frame.itemCountText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
        frame.itemCountText:SetPoint("LEFT", depositBtn, "RIGHT", 10, 0)
    end
    frame.itemCountText:SetText(#displayList .. " items")

    self:UpdateGrid()
end

-- ============================================================================
-- Show/Hide with Bags (Shift+B)
-- ============================================================================

local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hookFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        hooksecurefunc("OpenAllBags", function()
            AbyssalStorageFrame:Show()
            AbyssalStorage:UpdateUI()
        end)
        hooksecurefunc("CloseAllBags", function()
            AbyssalStorageFrame:Hide()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

-- ============================================================================
-- TradeSkill Frame Hooks — Vault-aware recipe list and crafting
-- ============================================================================

local DEFAULT_TRADE_SKILL_ROWS = 8
local DEFAULT_TRADE_SKILL_HEIGHT = 16

local function GetTradeSkillDisplayedRows()
    local rows = tonumber(TRADE_SKILLS_DISPLAYED)
    if rows and rows > 0 then return math.floor(rows) end
    rows = 0
    while _G["TradeSkillSkill" .. (rows + 1)] do
        rows = rows + 1
    end
    if rows > 0 then return rows end
    return DEFAULT_TRADE_SKILL_ROWS
end

local function GetTradeSkillRowHeight()
    return tonumber(TRADE_SKILL_HEIGHT) or DEFAULT_TRADE_SKILL_HEIGHT
end

local tradeCache = {
    valid = false,
    version = -1,
    active = false,
    linked = false,
    nativeNum = 0,
    filtered = {},
    virtualByReal = {},
    counts = {},
    skillLine = nil,
    selectedVirtual = 0,
}

local customRequested = false
local customActive = false
local customUpdating = false
local lastLinked = nil
local tradeResetScroll = false
local tradeScrollToSelected = false
local lastTradeVaultVersion = -1
local tradeRefreshFrame
local tradeEmptyText
local tradeSkillHooked = false
local tradeDisabled = false
local tradeErrorReported = false

local origTradeSkillUpdate
local origTradeSkillEvent
local origOnlyShowMakeable
local origGetNumTradeSkills
local origGetTradeSkillInfo
local origGetTradeSkillSelectionIndex
local origGetTradeSkillReagentInfo
local origGetTradeSkillReagentItemLink
local origGetTradeSkillNumReagents
local origGetTradeSkillRecipeLink
local origDoTradeSkill
local origGetFirstTradeSkill

local reagentItemIds = {}
local reagentItemRetry = {}

local function InvalidateTradeCache()
    tradeCache.valid = false
end

local function GetVaultCountForReagent(reagentName, realIndex, reagentIndex)
    if not reagentName then return 0 end
    local entry = reagentItemIds[reagentName]
    if entry == nil then
        local now = GetTime()
        if (reagentItemRetry[reagentName] or 0) > now then return 0 end
        reagentItemRetry[reagentName] = now + 1
        if not origGetTradeSkillReagentItemLink or not realIndex or not reagentIndex then return 0 end
        local link = origGetTradeSkillReagentItemLink(realIndex, reagentIndex)
        entry = AbyssalStorage:EntryFromLink(link)
        if not entry then return 0 end
        reagentItemIds[reagentName] = entry
    end
    return AbyssalStorage.items[entry] or 0
end

local function ReportTradeError(err)
    tradeDisabled = true
    if tradeErrorReported then return end
    tradeErrorReported = true
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Abyssal Storage trade hook error: " .. tostring(err) .. " (vault features disabled; /reload to retry)|r")
end

local function GetRecipeCounts(realIndex)
    local name, skillType = origGetTradeSkillInfo(realIndex)
    if not name or skillType == "header" then return 0, 0 end
    local cached = tradeCache.counts[name]
    if cached then return cached.bag, cached.total end

    local bagMax = math.huge
    local totalMax = math.huge
    local numReagents = origGetTradeSkillNumReagents(realIndex) or 0
    for i = 1, numReagents do
        local reagentName, _, need, have = origGetTradeSkillReagentInfo(realIndex, i)
        if need and need > 0 and have then
            local vault = GetVaultCountForReagent(reagentName, realIndex, i)
            bagMax = math.min(bagMax, math.floor(have / need))
            totalMax = math.min(totalMax, math.floor((have + vault) / need))
        end
    end
    if bagMax == math.huge then
        local _, _, nativeAvailable = origGetTradeSkillInfo(realIndex)
        bagMax = tonumber(nativeAvailable) or 0
        totalMax = bagMax
    end
    tradeCache.counts[name] = { bag = bagMax, total = totalMax }
    return bagMax, totalMax
end

local function AddTradeEntry(realIndex)
    local virtualIndex = #tradeCache.filtered + 1
    tradeCache.filtered[virtualIndex] = realIndex
    tradeCache.virtualByReal[realIndex] = virtualIndex
end

local function EnsureTradeCache()
    local linked = IsTradeSkillLinked() and true or false
    local version = tonumber(AbyssalStorage.vaultVersion) or 0
    local nativeNum = tonumber(origGetNumTradeSkills()) or 0
    local lineName = GetTradeSkillLine()
    if tradeCache.version ~= version or tradeCache.skillLine ~= lineName then
        wipe(tradeCache.counts)
    end
    if tradeCache.valid and tradeCache.nativeNum ~= nativeNum then
        tradeCache.valid = false
    end
    if tradeCache.valid
        and tradeCache.version == version
        and tradeCache.active == customActive
        and tradeCache.linked == linked then
        return
    end

    wipe(tradeCache.filtered)
    wipe(tradeCache.virtualByReal)
    tradeCache.nativeNum = nativeNum
    tradeCache.version = version
    tradeCache.active = customActive
    tradeCache.linked = linked
    tradeCache.skillLine = lineName

    local i = 1
    while i <= tradeCache.nativeNum do
        local _, skillType, _, isExpanded = origGetTradeSkillInfo(i)
        if skillType == "header" then
            local header = i
            local childStart = i + 1
            local nextIndex = childStart
            local craftable = false
            while nextIndex <= tradeCache.nativeNum do
                local _, childType = origGetTradeSkillInfo(nextIndex)
                if not childType or childType == "header" then break end
                if customActive and isExpanded then
                    local _, totalMax = GetRecipeCounts(nextIndex)
                    if totalMax > 0 then craftable = true end
                end
                nextIndex = nextIndex + 1
            end
            local addHeader = not customActive or not isExpanded or craftable
            local addChildren = isExpanded and (not customActive or craftable)
            if addHeader then
                AddTradeEntry(header)
                if addChildren then
                    for childIndex = childStart, nextIndex - 1 do
                        if not customActive then
                            AddTradeEntry(childIndex)
                        else
                            local _, totalMax = GetRecipeCounts(childIndex)
                            if totalMax > 0 then AddTradeEntry(childIndex) end
                        end
                    end
                end
            end
            i = nextIndex
        else
            if not customActive then
                AddTradeEntry(i)
            else
                local _, totalMax = GetRecipeCounts(i)
                if totalMax > 0 then AddTradeEntry(i) end
            end
            i = i + 1
        end
    end
    tradeCache.valid = true
end

local function VirtualGetTradeSkillInfo(virtualIndex)
    local realIndex = tradeCache.filtered[virtualIndex]
    if not realIndex then return nil end
    local name, skillType, numAvailable, isExpanded, serviceType = origGetTradeSkillInfo(realIndex)
    numAvailable = tonumber(numAvailable) or 0
    if name and skillType == "header" then
        numAvailable = 0
    elseif name then
        local counts = tradeCache.counts[name]
        if counts and counts.total > numAvailable then
            numAvailable = counts.total
        end
    end
    return name, skillType, numAvailable, isExpanded, serviceType
end

local function PostTradeSelection(id, force)
    if tradeDisabled or IsTradeSkillLinked() then return end
    if customUpdating and not force then return end
    if not id or id <= 0 then return end
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then return end
    local name, skillType = origGetTradeSkillInfo(id)
    if not name or skillType == "header" then return end
    local numReagents = origGetTradeSkillNumReagents(id) or 0
    if numReagents <= 0 then return end

    local creatable = true
    for i = 1, numReagents do
        local reagentName, _, need, have = origGetTradeSkillReagentInfo(id, i)
        if reagentName and need then
            local total = (tonumber(have) or 0) + GetVaultCountForReagent(reagentName, id, i)
            local reagent = _G["TradeSkillReagent"..i]
            local nameText = _G["TradeSkillReagent"..i.."Name"]
            local countText = _G["TradeSkillReagent"..i.."Count"]
            if total < need then
                creatable = false
                if reagent then SetItemButtonTextureVertexColor(reagent, 0.5, 0.5, 0.5) end
                if nameText then nameText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b) end
            else
                if reagent then SetItemButtonTextureVertexColor(reagent, 1.0, 1.0, 1.0) end
                if nameText then nameText:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b) end
            end
            if countText then
                local shown = total
                if shown >= 100 then shown = "*" end
                countText:SetText(shown.." /"..need)
            end
        end
    end

    if TradeSkillCreateButton then
        if creatable then TradeSkillCreateButton:Enable() else TradeSkillCreateButton:Disable() end
    end
    if TradeSkillCreateAllButton then
        if creatable then TradeSkillCreateAllButton:Enable() else TradeSkillCreateAllButton:Disable() end
    end
end

local function GetTradeSkillSpellId(id)
    local link = origGetTradeSkillRecipeLink(id)
    if link then
        return tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
    end
    return nil
end

local function WrappedDoTradeSkill(id, repeatCount)
    if tradeDisabled or IsTradeSkillLinked() then
        return origDoTradeSkill(id, repeatCount)
    end
    if not id or id <= 0 then return end

    local name, skillType = origGetTradeSkillInfo(id)
    if not name or skillType == "header" then return end
    if (origGetTradeSkillNumReagents(id) or 0) == 0 then
        return origDoTradeSkill(id, repeatCount)
    end

    EnsureTradeCache()
    if customActive and not tradeCache.virtualByReal[id] then return end

    local counts = tradeCache.counts[name]
    if not counts then
        local bagMax, totalMax = GetRecipeCounts(id)
        counts = { bag = bagMax, total = totalMax }
        tradeCache.counts[name] = counts
    end

    repeatCount = tonumber(repeatCount) or 1
    repeatCount = math.floor(repeatCount)
    if repeatCount < 1 then repeatCount = 1 end

    local bagMax = counts.bag or 0
    local totalMax = counts.total or 0
    if totalMax < 1 then return end
    if repeatCount <= bagMax or totalMax <= bagMax then
        return origDoTradeSkill(id, repeatCount)
    end

    local spellId = GetTradeSkillSpellId(id)
    if not spellId then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Abyssal Storage: Could not find the recipe spell ID.|r")
        return
    end

    local craftCount = math.min(repeatCount, totalMax)
    AbyssalStorage:SendCommand("abs craft " .. spellId .. " " .. craftCount)
end

local function ApplyTradeScroll()
    if not TradeSkillListScrollFrame then return end
    local rows = GetTradeSkillDisplayedRows()
    local rowHeight = GetTradeSkillRowHeight()
    local maxOffset = math.max(0, #tradeCache.filtered - rows)
    local offset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame) or 0

    if tradeResetScroll then
        offset = 0
        tradeResetScroll = false
    elseif tradeScrollToSelected then
        local selectedVirtual = tradeCache.virtualByReal[origGetTradeSkillSelectionIndex()]
        if selectedVirtual then
            if selectedVirtual < offset + 1 then
                offset = selectedVirtual - 1
            elseif selectedVirtual > offset + rows then
                offset = selectedVirtual - rows
            end
        end
        tradeScrollToSelected = false
    end

    offset = math.max(0, math.min(maxOffset, offset))
    FauxScrollFrame_SetOffset(TradeSkillListScrollFrame, offset)

    local scrollBar = _G["TradeSkillListScrollFrameScrollBar"]
    if scrollBar then
        scrollBar:SetMinMaxValues(0, maxOffset * rowHeight)
        local value = offset * rowHeight
        if math.abs(scrollBar:GetValue() - value) > 0.01 then
            scrollBar:SetValue(value)
        end
    end
end

local function CacheVisibleCounts()
    local offset = 0
    if TradeSkillListScrollFrame and FauxScrollFrame_GetOffset then
        offset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame) or 0
    end
    for i = 1, GetTradeSkillDisplayedRows() do
        local realIndex = tradeCache.filtered[i + offset]
        if realIndex then GetRecipeCounts(realIndex) end
    end
    local selected = origGetTradeSkillSelectionIndex()
    if selected and selected > 0 then GetRecipeCounts(selected) end
end

local function EnsureVisibleSelection()
    if not customActive then return end
    local selected = origGetTradeSkillSelectionIndex()
    local selectedName, selectedType
    if selected > 0 then
        selectedName, selectedType = origGetTradeSkillInfo(selected)
    end
    if selectedName and selectedType ~= "header" and tradeCache.virtualByReal[selected] then
        return
    end

    local firstRecipe
    for _, realIndex in ipairs(tradeCache.filtered) do
        local _, skillType = origGetTradeSkillInfo(realIndex)
        if skillType ~= "header" then
            firstRecipe = realIndex
            break
        end
    end

    if not firstRecipe then
        TradeSkillFrame.numAvailable = 0
        return
    end

    local inputCount = 1
    if TradeSkillInputBox then
        inputCount = TradeSkillInputBox:GetNumber() or 1
    end

    TradeSkillFrame_SetSelection(firstRecipe)

    if TradeSkillInputBox then
        if inputCount < 1 then inputCount = 1 end
        TradeSkillInputBox:SetNumber(inputCount)
    end
    tradeScrollToSelected = true
end

local function UpdateTradeEmptyState()
    if not tradeEmptyText and TradeSkillFrame then
        tradeEmptyText = TradeSkillFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tradeEmptyText:SetPoint("CENTER", TradeSkillListScrollFrame, "CENTER", 0, 0)
        tradeEmptyText:SetTextColor(0.55, 0.55, 0.55)
        tradeEmptyText:SetText("No craftable recipes")
    end
    if not tradeEmptyText then return end
    if customActive and #tradeCache.filtered == 0 and tradeCache.nativeNum > 0 then
        tradeEmptyText:Show()
    else
        tradeEmptyText:Hide()
    end
end

local function UpdateTradeSkillInternal()
    if not TradeSkillFrame:IsShown() then
        return origTradeSkillUpdate()
    end

    local linked = IsTradeSkillLinked() and true or false
    local linkChanged = linked ~= lastLinked
    if linkChanged then
        lastLinked = linked
        customActive = (not linked) and customRequested or false
        InvalidateTradeCache()
        if linked then
            origOnlyShowMakeable(customRequested)
        else
            origOnlyShowMakeable(false)
            tradeResetScroll = true
        end
    end

    if linked then
        if linkChanged then
            local selection = origGetTradeSkillSelectionIndex()
            local name, skillType
            if selection > 0 then
                name, skillType = origGetTradeSkillInfo(selection)
            end
            if not name or skillType == "header" then
                selection = origGetFirstTradeSkill() or 0
                if selection > 0 then
                    TradeSkillFrame_SetSelection(selection)
                end
                FauxScrollFrame_SetOffset(TradeSkillListScrollFrame, 0)
                local scrollBar = _G["TradeSkillListScrollFrameScrollBar"]
                if scrollBar then scrollBar:SetValue(0) end
            end
        end
        tradeResetScroll = false
        tradeScrollToSelected = false
        UpdateTradeEmptyState()
        return origTradeSkillUpdate()
    end

    EnsureTradeCache()
    EnsureVisibleSelection()
    ApplyTradeScroll()
    CacheVisibleCounts()
    tradeCache.selectedVirtual = tradeCache.virtualByReal[origGetTradeSkillSelectionIndex()] or 0

    local savedNumTradeSkills = GetNumTradeSkills
    local savedTradeSkillInfo = GetTradeSkillInfo
    local savedSelectionIndex = GetTradeSkillSelectionIndex

    GetNumTradeSkills = function()
        return #tradeCache.filtered
    end
    GetTradeSkillInfo = VirtualGetTradeSkillInfo
    GetTradeSkillSelectionIndex = function()
        return tradeCache.virtualByReal[origGetTradeSkillSelectionIndex()] or 0
    end

    local ok, err = pcall(origTradeSkillUpdate)
    GetNumTradeSkills = savedNumTradeSkills
    GetTradeSkillInfo = savedTradeSkillInfo
    GetTradeSkillSelectionIndex = savedSelectionIndex
    if not ok then
        ReportTradeError(err)
        return
    end

    local offset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame) or 0
    for i = 1, GetTradeSkillDisplayedRows() do
        local button = _G["TradeSkillSkill" .. i]
        local realIndex = tradeCache.filtered[i + offset]
        if button and realIndex then
            button:SetID(realIndex)
        end
    end

    local selectedReal = origGetTradeSkillSelectionIndex()
    local selectedVirtual = tradeCache.virtualByReal[selectedReal]
    local selectedType
    if selectedReal > 0 then
        local _, skillType = origGetTradeSkillInfo(selectedReal)
        selectedType = skillType
    end
    if not selectedVirtual or selectedType == "header" then
        TradeSkillFrame.numAvailable = 0
        if TradeSkillCreateButton then TradeSkillCreateButton:Disable() end
        if TradeSkillCreateAllButton then TradeSkillCreateAllButton:Disable() end
    else
        local okPost, errPost = pcall(PostTradeSelection, selectedReal, true)
        if not okPost then ReportTradeError(errPost) end
    end

    UpdateTradeEmptyState()
end

local function WrappedTradeSkillUpdate()
    if customUpdating then return end
    if tradeDisabled then
        pcall(origTradeSkillUpdate)
        return
    end
    customUpdating = true
    local ok, err = pcall(UpdateTradeSkillInternal)
    customUpdating = false
    if not ok then ReportTradeError(err) end
end

local function WrappedTradeSkillEvent(self, event, ...)
    if customUpdating then return end
    if tradeDisabled then
        pcall(origTradeSkillEvent, self, event, ...)
        return
    end
    if event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_FILTER_UPDATE" then
        InvalidateTradeCache()
    end
    local ok, err = pcall(origTradeSkillEvent, self, event, ...)
    if not ok then ReportTradeError(err) end
end

local function WrappedOnlyShowMakeableImpl(filter)
    local requested = filter and true or false
    local changed = requested ~= customRequested
    customRequested = requested

    if IsTradeSkillLinked() then
        customActive = false
        if changed then
            InvalidateTradeCache()
            tradeResetScroll = true
        end
        origOnlyShowMakeable(requested)
        return
    end

    customActive = requested
    if changed then
        InvalidateTradeCache()
        tradeResetScroll = true
    end
    origOnlyShowMakeable(false)

    if changed and TradeSkillFrame and TradeSkillFrame:IsShown() then
        TradeSkillFrame_Update()
    end
end

local function WrappedOnlyShowMakeable(filter)
    if tradeDisabled then
        pcall(origOnlyShowMakeable, filter)
        return
    end
    local ok, err = pcall(WrappedOnlyShowMakeableImpl, filter)
    if not ok then ReportTradeError(err) end
end

local function RefreshTradeSkillNowImpl()
    if tradeRefreshFrame then tradeRefreshFrame:Hide() end
    lastTradeVaultVersion = AbyssalStorage.vaultVersion or 0
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() or IsTradeSkillLinked() then
        return
    end

    InvalidateTradeCache()

    local selected = origGetTradeSkillSelectionIndex()
    local name, skillType
    if selected > 0 then
        name, skillType = origGetTradeSkillInfo(selected)
    end
    if not name or skillType == "header" then
        selected = origGetFirstTradeSkill() or 0
        if selected > 0 then tradeScrollToSelected = true end
    end

    if selected > 0 then
        local inputCount = 1
        if TradeSkillInputBox then
            inputCount = TradeSkillInputBox:GetNumber() or 1
        end
        TradeSkillFrame_SetSelection(selected)
        if TradeSkillInputBox then
            if inputCount < 1 then inputCount = 1 end
            TradeSkillInputBox:SetNumber(inputCount)
        end
    end

    TradeSkillFrame_Update()
end

function AbyssalStorage:RefreshTradeSkillNow()
    if tradeDisabled then return end
    local ok, err = pcall(RefreshTradeSkillNowImpl)
    if not ok then ReportTradeError(err) end
end

function AbyssalStorage:RefreshTradeSkill()
    if tradeDisabled or not origGetNumTradeSkills then return end
    local version = self.vaultVersion or 0
    if version == lastTradeVaultVersion then return end
    lastTradeVaultVersion = version
    InvalidateTradeCache()

    if not TradeSkillFrame or not TradeSkillFrame:IsShown() or IsTradeSkillLinked() then
        if tradeRefreshFrame then tradeRefreshFrame:Hide() end
        return
    end

    if not tradeRefreshFrame then
        tradeRefreshFrame = CreateFrame("Frame")
        tradeRefreshFrame:Hide()
        tradeRefreshFrame.elapsed = 0
        tradeRefreshFrame:SetScript("OnUpdate", function(timer, elapsed)
            timer.elapsed = timer.elapsed + elapsed
            if timer.elapsed < 0.1 then return end
            timer.elapsed = 0
            timer:Hide()
            AbyssalStorage:RefreshTradeSkillNow()
        end)
    end

    tradeRefreshFrame.elapsed = 0
    tradeRefreshFrame:Show()
end

local function HookTradeSkill()
    if not TradeSkillFrame or tradeSkillHooked then return end
    tradeSkillHooked = true

    origTradeSkillUpdate = TradeSkillFrame_Update
    origTradeSkillEvent = TradeSkillFrame_OnEvent
    origOnlyShowMakeable = TradeSkillOnlyShowMakeable
    origGetNumTradeSkills = GetNumTradeSkills
    origGetTradeSkillInfo = GetTradeSkillInfo
    origGetTradeSkillSelectionIndex = GetTradeSkillSelectionIndex
    origGetTradeSkillReagentInfo = GetTradeSkillReagentInfo
    origGetTradeSkillReagentItemLink = GetTradeSkillReagentItemLink
    origGetTradeSkillNumReagents = GetTradeSkillNumReagents
    origGetTradeSkillRecipeLink = GetTradeSkillRecipeLink
    origDoTradeSkill = DoTradeSkill
    origGetFirstTradeSkill = GetFirstTradeSkill

    customRequested = TradeSkillFrameAvailableFilterCheckButton
        and TradeSkillFrameAvailableFilterCheckButton:GetChecked()
        and true or false
    lastLinked = IsTradeSkillLinked() and true or false
    customActive = (not lastLinked) and customRequested or false

    TradeSkillFrame_Update = WrappedTradeSkillUpdate
    TradeSkillFrame_OnEvent = WrappedTradeSkillEvent
    TradeSkillOnlyShowMakeable = WrappedOnlyShowMakeable
    DoTradeSkill = WrappedDoTradeSkill

    TradeSkillFrame:SetScript("OnEvent", WrappedTradeSkillEvent)

    hooksecurefunc("ExpandTradeSkillSubClass", InvalidateTradeCache)
    hooksecurefunc("CollapseTradeSkillSubClass", InvalidateTradeCache)
    hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
        local ok, err = pcall(PostTradeSelection, id)
        if not ok then ReportTradeError(err) end
    end)

    if TradeSkillRankFrame then
        TradeSkillRankFrame:SetScript("OnEvent", function()
            if not customUpdating then TradeSkillFrame_Update() end
        end)
    end

    TradeSkillFrame:HookScript("OnShow", function()
        lastTradeVaultVersion = -1
        InvalidateTradeCache()
    end)
    TradeSkillFrame:HookScript("OnHide", function()
        tradeResetScroll = false
        tradeScrollToSelected = false
        if tradeRefreshFrame then tradeRefreshFrame:Hide() end
        InvalidateTradeCache()
    end)
end

local tradeHookFrame = CreateFrame("Frame")
tradeHookFrame:RegisterEvent("ADDON_LOADED")
tradeHookFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == "Blizzard_TradeSkillUI" then
        HookTradeSkill()
        if tradeSkillHooked then
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end)
if TradeSkillFrame then
    HookTradeSkill()
    tradeHookFrame:UnregisterEvent("ADDON_LOADED")
end

-- ============================================================================
-- Request item info for all vault items on show
-- ============================================================================

AbyssalStorageFrame:SetScript("OnShow", function(self)
    -- Slight delay to let item info queries return
    AbyssalStorage.SetTimer(0.5, function()
        AbyssalStorage:UpdateUI()
    end)
    AbyssalStorage:UpdateUI()
end)

-- ============================================================================
-- Minimap Button
-- ============================================================================

local minimapButton = CreateFrame("Button", "AbyssalStorageMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:RegisterForDrag("LeftButton")
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local minimapBg = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapBg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
minimapBg:SetAllPoints()

local minimapIcon = minimapButton:CreateTexture(nil, "ARTWORK")
minimapIcon:SetTexture("Interface\\Icons\\INV_Enchant_VoidSphere")
minimapIcon:SetSize(20, 20)
minimapIcon:SetPoint("CENTER")
minimapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapBorder:SetSize(54, 54)
minimapBorder:SetPoint("TOPLEFT")

local minimapHighlight = minimapButton:CreateTexture(nil, "HIGHLIGHT")
minimapHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapHighlight:SetBlendMode("ADD")
minimapHighlight:SetAllPoints()

local function UpdateMinimapButtonPosition()
    local angle = math.rad(AbyssalStorageDB.minimapAngle or 220)
    local radius = 80
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

minimapButton:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale
        AbyssalStorageDB.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
        UpdateMinimapButtonPosition()
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

minimapButton:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        AbyssalStorage:Deposit()
        return
    end

    if AbyssalStorageFrame:IsShown() then
        AbyssalStorageFrame:Hide()
    else
        AbyssalStorageFrame:Show()
        AbyssalStorage:UpdateUI()
    end
end)

minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Abyssal Storage")
    GameTooltip:AddLine("Left-click: Open", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: Deposit All", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: Move", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

UpdateMinimapButtonPosition()
