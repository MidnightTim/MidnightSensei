--------------------------------------------------------------------------------
-- Midnight Sensei: BossBoard.lua
-- Personal all-time boss best leaderboard — Delves, Dungeons, Raids.
-- Tracks the highest score achieved per boss encounter (by bossID).
-- Individual only — no guild/friends display, but shared snapshots stored
-- in MidnightSenseiDB.bossBoardShared for recovery/comparison purposes.
--
-- Data source: MidnightSenseiCharDB.bests.bossBests[bossID]
-- Shared store: MidnightSenseiDB.bossBoardShared["Name-Realm|bossID"]
--
-- Columns: Date | Character | Spec | Diff/Boss | Score
-- Tabs:    Delves | Dungeons | Raids
-- Sort:    any column header clickable
--------------------------------------------------------------------------------

MidnightSensei           = MidnightSensei           or {}
MidnightSensei.BossBoard = MidnightSensei.BossBoard or {}

local MS        = MidnightSensei
local BB        = MS.BossBoard
local Core      = MS.Core or MidnightSensei.Core or {}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function BD(f, bg, border)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({ bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
                    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                    tile=true, tileSize=16, edgeSize=12,
                    insets={left=2,right=2,top=2,bottom=2} })
    local b = bg or {0.06,0.06,0.10,0.95}
    local e = border or {0.30,0.30,0.40,0.60}
    f:SetBackdropColor(b[1],b[2],b[3],b[4] or 1)
    f:SetBackdropBorderColor(e[1],e[2],e[3],e[4] or 1)
end

local function TF(parent, size, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts/FRIZQT__.TTF", size or 11, "")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetTextColor(0.92, 0.90, 0.88, 1)
    return fs
end

local COLOR = {
    BG          = {0.04,0.04,0.06,0.92},
    BORDER_GOLD = {1.00,0.65,0.00,0.90},
    BORDER      = {0.30,0.30,0.40,0.60},
    TITLE       = {1.00,0.65,0.00,1.00},
    ACCENT      = {0.00,0.82,1.00,1.00},
    TEXT_DIM    = {0.55,0.53,0.50,1.00},
    ROW_EVEN    = {0.08,0.08,0.12,0.50},
    ROW_ODD     = {0.04,0.04,0.06,0.30},
    ROW_HOVER   = {0.15,0.15,0.22,0.80},
    TAB_ACTIVE  = {0.20,0.18,0.24,1.00},
    TAB_IDLE    = {0.10,0.10,0.14,1.00},
}

local CLASS_COLORS = {
    WARRIOR={0.78,0.61,0.43}, PALADIN={0.96,0.55,0.73}, HUNTER={0.67,0.83,0.45},
    ROGUE={1.00,0.96,0.41},   PRIEST={1.00,1.00,1.00},  DEATHKNIGHT={0.77,0.12,0.23},
    SHAMAN={0.00,0.44,0.87},  MAGE={0.41,0.80,0.94},    WARLOCK={0.58,0.51,0.79},
    MONK={0.00,1.00,0.59},    DRUID={1.00,0.49,0.04},   DEMONHUNTER={0.64,0.19,0.79},
    EVOKER={0.20,0.58,0.50},
}
local function ClassColor(cn)
    if not cn then return {0.9,0.9,0.9} end
    return CLASS_COLORS[cn:upper():gsub(" ","")] or {0.9,0.9,0.9}
end

local function GHex(score)
    if not score or score == 0 then return "aaaaaa" end
    if score >= 90 then return "33ee33"
    elseif score >= 80 then return "88cc44"
    elseif score >= 70 then return "cccc33"
    elseif score >= 60 then return "ee8833"
    else return "ee3333" end
end

-- Format timestamp as MM/DD/YYYY
local function FmtDate(ts)
    if not ts or ts == 0 then return "--" end
    return date("%m/%d/%Y", ts)
end

-- Build a concise diff/boss label from an entry
local function DiffBossLabel(entry)
    local parts = {}
    local diff = entry.diffLabel
    -- Prefer M+ notation from keystoneLevel if available
    if entry.keystoneLevel and entry.keystoneLevel > 0 then
        diff = "M+" .. entry.keystoneLevel
    end
    if diff and diff ~= "" and diff ~= "World" and diff ~= "0" then
        table.insert(parts, diff)
    end
    if entry.instanceName and entry.instanceName ~= "" then
        table.insert(parts, entry.instanceName)
    end
    if entry.bossName and entry.bossName ~= "" then
        table.insert(parts, entry.bossName)
    end
    return #parts > 0 and table.concat(parts, " - ") or "--"
end

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
local bbFrame    = nil
local activeTab  = "dungeon"  -- dungeon | raid | delve
local sortKey    = "score"    -- date | char | spec | boss | score
local sortAsc    = false      -- false = descending (highest score first by default)
local rowFrames  = {}

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------
local function GetBossBests()
    local cdb = MidnightSenseiCharDB
    if not cdb or not cdb.bests or not cdb.bests.bossBests then return {} end
    return cdb.bests.bossBests
end

local function GetFilteredEntries()
    local all = GetBossBests()
    local result = {}
    for bossID, entry in pairs(all) do
        if entry.encType == activeTab then
            local e = {}
            for k, v in pairs(entry) do e[k] = v end
            e.bossID = bossID
            table.insert(result, e)
        end
    end

    -- Sort
    table.sort(result, function(a, b)
        local av, bv
        if sortKey == "date" then
            av = a.bestTimestamp or 0
            bv = b.bestTimestamp or 0
        elseif sortKey == "char" then
            av = (a.charName or ""):lower()
            bv = (b.charName or ""):lower()
            if sortAsc then return av < bv else return av > bv end
        elseif sortKey == "spec" then
            av = ((a.specName or "") .. (a.className or "")):lower()
            bv = ((b.specName or "") .. (b.className or "")):lower()
            if sortAsc then return av < bv else return av > bv end
        elseif sortKey == "boss" then
            av = (a.bossName or ""):lower()
            bv = (b.bossName or ""):lower()
            if sortAsc then return av < bv else return av > bv end
        else  -- score
            av = a.bestScore or 0
            bv = b.bestScore or 0
        end
        if sortAsc then return av < bv else return av > bv end
    end)

    return result
end

--------------------------------------------------------------------------------
-- Shared snapshot — store to account-wide DB for recovery
-- Key format: "Name-Realm|bossID"
-- Always keeps the higher score
--------------------------------------------------------------------------------
local function UpdateSharedSnapshot()
    if not MidnightSenseiDB then return end
    MidnightSenseiDB.bossBoardShared = MidnightSenseiDB.bossBoardShared or {}
    local shared = MidnightSenseiDB.bossBoardShared

    local charName  = UnitName("player") or "?"
    local realmName = GetRealmName() or "?"
    local prefix    = charName .. "-" .. realmName .. "|"

    local bests = GetBossBests()
    for bossID, entry in pairs(bests) do
        local key      = prefix .. bossID
        local existing = shared[key]
        if not existing or (entry.bestScore or 0) > (existing.bestScore or 0) then
            shared[key] = {
                charName      = charName,
                realmName     = realmName,
                bossID        = bossID,
                bossName      = entry.bossName      or "?",
                instanceName  = entry.instanceName  or "",
                encType       = entry.encType       or "normal",
                diffLabel     = entry.diffLabel     or "",
                keystoneLevel = entry.keystoneLevel or nil,
                specName      = entry.specName      or "?",
                className     = entry.className     or "?",
                bestScore     = entry.bestScore     or 0,
                bestGrade     = entry.bestGrade     or "--",
                bestTimestamp = entry.bestTimestamp or 0,
            }
        end
    end
end

-- Called at login to push local bests into the shared store
Core.On(Core.EVENTS.SESSION_READY, function()
    C_Timer.After(3.0, UpdateSharedSnapshot)
end)

-- Called after each boss fight grade is recorded
Core.On(Core.EVENTS.GRADE_CALCULATED, function(result)
    if result and result.isBoss then
        C_Timer.After(0.5, function()
            UpdateSharedSnapshot()
            BB.RefreshUI()
        end)
    end
end)

--------------------------------------------------------------------------------
-- Debug: ingest from encounters history into bossBests
-- Scans CharDB.encounters for boss fights and seeds bossBests from them.
-- Only updates if the encounter score is higher than existing entry.
--------------------------------------------------------------------------------
function BB.IngestFromHistory()
    local cdb = MidnightSenseiCharDB
    if not cdb then
        print("|cffFF4444Midnight Sensei:|r No CharDB found.")
        return
    end

    local encounters = cdb.encounters or {}
    cdb.bests = cdb.bests or {}
    cdb.bests.bossBests = cdb.bests.bossBests or {}
    local bossBests = cdb.bests.bossBests

    -- Resolve current character identity once — used as fallback for legacy
    -- encounters that predate specName/className/charName fields on the result struct.
    -- Since this is CharDB (per-character), charName is always the current player.
    -- specName/className are best-effort from the current active spec.
    local fallbackChar  = UnitName("player") or "?"
    local fallbackSpec  = Core.ActiveSpec and Core.ActiveSpec.name      or "?"
    local fallbackClass = Core.ActiveSpec and Core.ActiveSpec.className or "?"

    local added, updated, skipped = 0, 0, 0

    for _, enc in ipairs(encounters) do
        -- Only boss fights with a valid bossID and a recorded score
        if enc.isBoss and enc.bossID and (enc.finalScore or 0) > 0 then
            local bid      = tostring(enc.bossID)
            local s        = enc.finalScore or 0
            local existing = bossBests[bid]

            -- Resolve identity fields — prefer stored values, fall back to
            -- current session data for legacy records that predate these fields
            local charName  = enc.charName  or fallbackChar
            local specName  = enc.specName  or fallbackSpec
            local className = enc.className or fallbackClass

            if not existing then
                bossBests[bid] = {
                    bossName      = enc.bossName      or "?",
                    instanceName  = enc.instanceName  or "",
                    encType       = enc.encType       or "normal",
                    diffLabel     = enc.diffLabel     or "",
                    keystoneLevel = enc.keystoneLevel or nil,
                    charName      = charName,
                    specName      = specName,
                    className     = className,
                    bestScore     = s,
                    bestGrade     = enc.finalGrade    or "--",
                    bestTimestamp = enc.timestamp     or 0,
                    bestWeekKey   = enc.weekKey       or "",
                    killCount     = 1,
                    firstSeen     = enc.timestamp     or 0,
                }
                added = added + 1
            else
                existing.killCount = (existing.killCount or 0) + 1
                if s > (existing.bestScore or 0) then
                    existing.bestScore     = s
                    existing.bestGrade     = enc.finalGrade   or "--"
                    existing.bestTimestamp = enc.timestamp    or 0
                    existing.bestWeekKey   = enc.weekKey      or ""
                    existing.diffLabel     = enc.diffLabel    or existing.diffLabel
                    existing.keystoneLevel = enc.keystoneLevel or existing.keystoneLevel
                    existing.instanceName  = enc.instanceName or existing.instanceName
                    -- Only update identity fields if the encounter has them explicitly —
                    -- don't overwrite a known value with a fallback
                    if enc.charName  then existing.charName  = enc.charName  end
                    if enc.specName  then existing.specName  = enc.specName  end
                    if enc.className then existing.className = enc.className end
                    updated = updated + 1
                else
                    -- Even if score isn't better, patch in identity if missing
                    if not existing.charName  or existing.charName  == "?" then existing.charName  = charName  end
                    if not existing.specName  or existing.specName  == "?" then existing.specName  = specName  end
                    if not existing.className or existing.className == "?" then existing.className = className end
                    skipped = skipped + 1
                end
            end
        end
    end

    UpdateSharedSnapshot()
    BB.RefreshUI()

    print(string.format(
        "|cff00D1FFMidnight Sensei Boss Board:|r Ingest complete — added: %d  updated: %d  skipped: %d",
        added, updated, skipped))
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local FW, FH = 620, 520

local function CreateRow(parent, idx)
    if rowFrames[idx] then return rowFrames[idx] end
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(24)
    row:SetPoint("LEFT",  parent, "LEFT",  0, 0)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    -- DATE
    row.dateText  = TF(row, 9, "LEFT")
    row.dateText:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.dateText:SetWidth(80)
    row.dateText:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)

    -- CHARACTER
    row.charText  = TF(row, 10, "LEFT")
    row.charText:SetPoint("LEFT", row, "LEFT", 88, 0)
    row.charText:SetWidth(110)

    -- SPEC
    row.specText  = TF(row, 9, "LEFT")
    row.specText:SetPoint("LEFT", row, "LEFT", 202, 0)
    row.specText:SetWidth(90)
    row.specText:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)

    -- DIFF / BOSS
    row.bossText  = TF(row, 9, "LEFT")
    row.bossText:SetPoint("LEFT", row, "LEFT", 296, 0)
    row.bossText:SetWidth(240)
    row.bossText:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
    row.bossText:SetWordWrap(false)

    -- SCORE
    row.scoreText = TF(row, 11, "RIGHT")
    row.scoreText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.scoreText:SetWidth(60)

    rowFrames[idx] = row
    return row
end

local function PopulateRows(scrollChild, entries)
    for _, r in ipairs(rowFrames) do r:Hide() end

    -- Lazy-create a persistent empty state label — avoids leaking a new
    -- FontString on every refresh call when the tab has no entries
    if not scrollChild.emptyLabel then
        scrollChild.emptyLabel = TF(scrollChild, 10, "CENTER")
        scrollChild.emptyLabel:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  0, -20)
        scrollChild.emptyLabel:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -20)
        scrollChild.emptyLabel:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
    end

    if #entries == 0 then
        scrollChild.emptyLabel:SetText("No boss encounters recorded for this content type yet.")
        scrollChild.emptyLabel:Show()
        scrollChild:SetHeight(60)
        return
    end

    scrollChild.emptyLabel:Hide()
    local yOff = 0

    for i, entry in ipairs(entries) do
        local row = CreateRow(scrollChild, i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  0, -yOff)
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOff)

        local bgc = (i % 2 == 0) and COLOR.ROW_EVEN or COLOR.ROW_ODD
        row:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",tile=true,tileSize=16})
        row:SetBackdropColor(bgc[1], bgc[2], bgc[3], bgc[4] or 0.5)

        -- DATE
        row.dateText:SetText(FmtDate(entry.bestTimestamp))

        -- CHARACTER
        local cc = ClassColor(entry.className)
        row.charText:SetText("|cff"..string.format("%02x%02x%02x",
            math.floor(cc[1]*255), math.floor(cc[2]*255), math.floor(cc[3]*255))..
            (entry.charName or "?").."|r")

        -- SPEC
        row.specText:SetText((entry.specName or "?"))

        -- DIFF / BOSS
        row.bossText:SetText(DiffBossLabel(entry))

        -- SCORE
        local s = entry.bestScore or 0
        local g = entry.bestGrade or "?"
        row.scoreText:SetText("|cff"..GHex(s)..g.."  "..s.."|r")

        -- Hover highlight
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(r)
            r:SetBackdropColor(COLOR.ROW_HOVER[1], COLOR.ROW_HOVER[2], COLOR.ROW_HOVER[3], COLOR.ROW_HOVER[4])
            -- Tooltip with full details
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:SetText((entry.bossName or "?"), 1, 0.82, 0)
            if entry.instanceName and entry.instanceName ~= "" then
                GameTooltip:AddLine(entry.instanceName, 0.8, 0.8, 0.8)
            end
            GameTooltip:AddLine("Best: " .. (entry.bestGrade or "?") .. "  " .. s, 0.2, 0.9, 0.2)
            GameTooltip:AddLine("Date: " .. FmtDate(entry.bestTimestamp), 0.6, 0.6, 0.6)
            if (entry.killCount or 0) > 0 then
                GameTooltip:AddLine("Kills tracked: " .. entry.killCount, 0.6, 0.6, 0.6)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(r)
            r:SetBackdropColor(bgc[1], bgc[2], bgc[3], bgc[4] or 0.5)
            GameTooltip:Hide()
        end)

        row:Show()
        yOff = yOff + 24
    end

    scrollChild:SetHeight(math.max(yOff + 8, 60))
end

local function RefreshContent()
    if not bbFrame or not bbFrame.scrollChild then return end
    local entries = GetFilteredEntries()
    PopulateRows(bbFrame.scrollChild, entries)

    -- Update tab highlights
    if bbFrame.tabBtns then
        for _, tb in ipairs(bbFrame.tabBtns) do
            local active = (tb.tabKey == activeTab)
            BD(tb, active and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
            tb.fs:SetTextColor(
                active and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1],
                active and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2],
                active and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3], 1)
        end
    end

    -- Update sort header highlights
    if bbFrame.sortBtns then
        for _, sb in ipairs(bbFrame.sortBtns) do
            local active = (sb.sortKey == sortKey)
            BD(sb, active and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
            sb.fs:SetTextColor(
                active and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1],
                active and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2],
                active and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3], 1)
        end
    end

    -- Entry count in footer
    if bbFrame.countText then
        bbFrame.countText:SetText(#entries .. " boss" .. (#entries == 1 and "" or "es") .. " recorded")
    end
end

function BB.RefreshUI()
    if bbFrame and bbFrame:IsShown() then RefreshContent() end
end

local function CreateBossBoardFrame()
    if bbFrame then return bbFrame end

    local f = CreateFrame("Frame", "MidnightSenseiBossBoard", UIParent, "BackdropTemplate")
    f:SetSize(FW, FH)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    BD(f, COLOR.BG, COLOR.BORDER_GOLD)

    -- ── Title bar ────────────────────────────────────────────────────────────
    local tBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    tBar:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    tBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    tBar:SetHeight(28)
    BD(tBar, {0.10,0.10,0.16,0.98}, COLOR.BORDER_GOLD)

    local title = TF(tBar, 13, "CENTER")
    title:SetPoint("LEFT",  tBar, "LEFT",  6, 0)
    title:SetPoint("RIGHT", tBar, "RIGHT", -26, 0)
    title:SetTextColor(COLOR.TITLE[1], COLOR.TITLE[2], COLOR.TITLE[3], 1)
    title:SetText("Midnight Sensei - Boss Board")

    local xBtn = CreateFrame("Button", nil, tBar)
    xBtn:SetSize(20, 20)
    xBtn:SetPoint("RIGHT", tBar, "RIGHT", -4, 0)
    local xFs = TF(xBtn, 13, "CENTER") ; xFs:SetPoint("CENTER")
    xFs:SetText("|cffFF4444X|r")
    xBtn:SetScript("OnClick", function() f:Hide() end)

    -- ── Tab row (y = -30) ────────────────────────────────────────────────────
    local tabDefs = {
        { key="dungeon", label="Dungeons" },
        { key="raid",    label="Raids"    },
        { key="delve",   label="Delves"   },
    }
    local tabW = math.floor(FW / #tabDefs)
    f.tabBtns = {}
    for i, td in ipairs(tabDefs) do
        local tb = CreateFrame("Button", nil, f, "BackdropTemplate")
        tb:SetSize(tabW, 24)
        tb:SetPoint("TOPLEFT", f, "TOPLEFT", (i-1)*tabW, -28)
        BD(tb, COLOR.TAB_IDLE, COLOR.BORDER)
        tb.tabKey = td.key
        tb.fs = TF(tb, 10, "CENTER") ; tb.fs:SetPoint("CENTER")
        tb.fs:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
        tb.fs:SetText(td.label)
        tb:SetScript("OnClick", function()
            activeTab = td.key
            RefreshContent()
        end)
        table.insert(f.tabBtns, tb)
    end

    -- ── Sort header row (y = -52) ─────────────────────────────────────────────
    local hdr = CreateFrame("Frame", nil, f)
    hdr:SetPoint("TOPLEFT",  f, "TOPLEFT",   4, -52)
    hdr:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -52)
    hdr:SetHeight(22)

    f.sortBtns = {}
    local function SortHdr(label, key, anchor, x, w)
        local btn = CreateFrame("Button", nil, hdr, "BackdropTemplate")
        btn:SetSize(w, 20)
        btn:SetPoint(anchor, hdr, anchor, x, 0)
        BD(btn, COLOR.TAB_IDLE, COLOR.BORDER)
        btn.fs = TF(btn, 9, "CENTER") ; btn.fs:SetPoint("CENTER")
        btn.fs:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
        btn.fs:SetText(label)
        btn.sortKey = key
        btn:SetScript("OnClick", function()
            if sortKey == key then
                sortAsc = not sortAsc  -- toggle direction on same column
            else
                sortKey = key
                sortAsc = (key == "char" or key == "spec" or key == "boss")
            end
            RefreshContent()
        end)
        btn:SetScript("OnEnter", function()
            BD(btn, COLOR.TAB_ACTIVE, COLOR.BORDER)
            btn.fs:SetTextColor(COLOR.ACCENT[1], COLOR.ACCENT[2], COLOR.ACCENT[3], 1)
        end)
        btn:SetScript("OnLeave", function()
            local active = (btn.sortKey == sortKey)
            BD(btn, active and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
            btn.fs:SetTextColor(
                active and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1],
                active and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2],
                active and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3], 1)
        end)
        table.insert(f.sortBtns, btn)
        return btn
    end

    -- Column widths mirror the row layout above
    SortHdr("DATE",       "date",  "LEFT",   4,  80)
    SortHdr("CHARACTER",  "char",  "LEFT",  88, 110)
    SortHdr("SPEC",       "spec",  "LEFT", 202,  90)
    SortHdr("DIFF / BOSS","boss",  "LEFT", 296, 240)
    SortHdr("SCORE",      "score", "RIGHT", -4,  60)

    -- ── Scroll frame (starts at y = -74) ─────────────────────────────────────
    local sf = CreateFrame("ScrollFrame", "MidnightSenseiBBScroll", f,
                            "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     f, "TOPLEFT",   4, -74)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -22, 34)

    local sc = CreateFrame("Frame", nil, sf)
    sc:SetWidth(sf:GetWidth()) ; sc:SetHeight(200)
    sf:SetScrollChild(sc)
    f.scrollChild = sc

    -- ── Footer ───────────────────────────────────────────────────────────────
    local footerText = TF(f, 9, "LEFT")
    footerText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 10)
    footerText:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
    footerText:SetText("Boss kills only  -  level 80+  -  /ms bossboard")
    f.countText = TF(f, 9, "RIGHT")
    f.countText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 10)
    f.countText:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    closeBtn:SetSize(68, 20)
    closeBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 8)
    BD(closeBtn, COLOR.TAB_IDLE, COLOR.BORDER)
    local cFs = TF(closeBtn, 10, "CENTER") ; cFs:SetPoint("CENTER")
    cFs:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:SetScript("OnEnter", function()
        BD(closeBtn, COLOR.TAB_ACTIVE, COLOR.BORDER)
        cFs:SetTextColor(COLOR.ACCENT[1], COLOR.ACCENT[2], COLOR.ACCENT[3], 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        BD(closeBtn, COLOR.TAB_IDLE, COLOR.BORDER)
        cFs:SetTextColor(0.92, 0.90, 0.88, 1)
    end)

    bbFrame = f
    return f
end

function BB.Show()
    local f = CreateBossBoardFrame()
    RefreshContent()
    f:Show()
end

function BB.Toggle()
    local f = CreateBossBoardFrame()
    if f:IsShown() then f:Hide() else BB.Show() end
end

--------------------------------------------------------------------------------
-- Slash commands wired in via Core.lua: /ms bossboard, /ms bb
-- Debug ingest: /ms debug bossboard ingest
--------------------------------------------------------------------------------
