--------------------------------------------------------------------------------
-- Midnight Sensei: UI.lua
-- All displayed strings use "Midnight Sensei" (with space).
-- Frame/variable identifiers remain camelCase for Lua compatibility.
-- Font: always MakeFont() — never SetNormalFontObject (causes blocky font).
--------------------------------------------------------------------------------

MidnightSensei    = MidnightSensei    or {}
MidnightSensei.UI = MidnightSensei.UI or {}

local MS   = MidnightSensei
local UI   = MS.UI
local Core = MS.Core or MidnightSensei.Core or {}  -- fallback guards against load-order races

--------------------------------------------------------------------------------
-- Colour palette
--------------------------------------------------------------------------------
local C = {
    BG          = {0.04, 0.04, 0.07, 0.92},
    BG_LIGHT    = {0.08, 0.08, 0.13, 0.92},
    BORDER      = {0.25, 0.25, 0.35, 0.70},
    BORDER_GOLD = {1.00, 0.65, 0.00, 0.90},
    TITLE_BG    = {0.10, 0.10, 0.16, 0.98},
    TITLE       = {1.00, 0.65, 0.00, 1.00},
    ACCENT      = {0.00, 0.82, 1.00, 1.00},
    TEXT        = {0.92, 0.90, 0.88, 1.00},
    TEXT_DIM    = {0.55, 0.53, 0.50, 1.00},
    ROW_EVEN    = {0.07, 0.07, 0.11, 0.55},
    ROW_ODD     = {0.04, 0.04, 0.07, 0.30},
    ROW_HOVER   = {0.15, 0.15, 0.22, 0.80},
    SEP         = {0.25, 0.25, 0.35, 0.50},
    GREEN       = {0.20, 0.90, 0.20, 1.00},
    RED         = {1.00, 0.25, 0.25, 1.00},
}

--------------------------------------------------------------------------------
-- Shared helpers
--------------------------------------------------------------------------------
local function ApplyBackdrop(f, bg, border)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    local b = bg or C.BG ; local e = border or C.BORDER
    f:SetBackdropColor(b[1], b[2], b[3], b[4] or 1)
    f:SetBackdropBorderColor(e[1], e[2], e[3], e[4] or 1)
end

-- Single font creation function — NEVER use SetNormalFontObject (causes
-- blocky/squared font rendering). Always use this helper.
local function MakeFont(parent, size, justify, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont("Fonts/FRIZQT__.TTF", size or 11, "")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3], 1)
    return fs
end

local function MakeButton(parent, w, h, label)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    ApplyBackdrop(btn, C.BG_LIGHT, C.BORDER)
    local fs = MakeFont(btn, 10, "CENTER")
    fs:SetPoint("CENTER")
    fs:SetText(label)
    btn.label = fs
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.ROW_HOVER[1], C.ROW_HOVER[2], C.ROW_HOVER[3], C.ROW_HOVER[4])
        GameTooltip:Hide()   -- suppress any stray WoW tooltip
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C.BG_LIGHT[1], C.BG_LIGHT[2], C.BG_LIGHT[3], C.BG_LIGHT[4] or 1)
    end)
    return btn
end

-- Close button using MakeFont (no GameFontNormal — avoids blocked font)
local function MakeCloseBtn(parent, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(18, 18)
    ApplyBackdrop(btn, {0.15, 0.05, 0.05, 0.90}, C.BORDER_GOLD)
    local fs = MakeFont(btn, 11, "CENTER")
    fs:SetPoint("CENTER")
    fs:SetText("X")
    fs:SetTextColor(1, 0.4, 0.4, 1)
    btn:SetScript("OnEnter", function()
        fs:SetTextColor(1, 0.7, 0.7, 1)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnLeave", function()
        fs:SetTextColor(1, 0.4, 0.4, 1)
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Standard title bar factory
local function MakeTitleBar(parent, titleStr, dragTarget)
    dragTarget = dragTarget or parent
    local tBar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    tBar:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, 0)
    tBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    tBar:SetHeight(26)
    ApplyBackdrop(tBar, C.TITLE_BG, C.BORDER_GOLD)
    tBar:EnableMouse(true)
    tBar:RegisterForDrag("LeftButton")
    tBar:SetScript("OnDragStart", function() dragTarget:StartMoving() end)
    tBar:SetScript("OnDragStop",  function() dragTarget:StopMovingOrSizing() end)

    local title = MakeFont(tBar, 12, "CENTER")
    title:SetPoint("CENTER")
    title:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3], 1)
    title:SetText(titleStr)

    local xBtn = MakeCloseBtn(tBar, function() parent:Hide() end)
    xBtn:SetPoint("RIGHT", tBar, "RIGHT", -4, 0)
    return tBar
end

local function GradeHex(score)
    if not score or score == 0 then return "888888" end
    if score >= 90 then return "22ee22"
    elseif score >= 80 then return "77cc33"
    elseif score >= 70 then return "cccc22"
    elseif score >= 60 then return "ee8822"
    else return "ee2222" end
end

local function FormatDuration(secs)
    if not secs then return "--" end
    return string.format("%d:%02d", math.floor(secs/60), math.floor(secs%60))
end

local function TimeAgo(ts)
    if not ts or ts == 0 then return "" end
    local d = time() - ts
    if d < 60 then return "just now"
    elseif d < 3600 then return math.floor(d/60) .. "m ago"
    elseif d < 86400 then return math.floor(d/3600) .. "h ago"
    else return math.floor(d/86400) .. "d ago" end
end

-- Truncate a string to at most maxChars *visible* characters, appending ".."
-- if truncated. WoW colour codes (|cXXXXXXXX…|r) are not counted toward the
-- limit so coloured boss names don't get cut prematurely.
local function TruncateLabel(s, maxChars)
    if not s or s == "" then return s end
    local plain = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    if #plain <= maxChars then return s end
    local visible = 0
    local i = 1
    local cutPos = #s
    while i <= #s do
        if s:sub(i, i+1) == "|c" then
            i = i + 10
        elseif s:sub(i, i+1) == "|r" then
            i = i + 2
        else
            visible = visible + 1
            if visible >= maxChars - 2 then
                cutPos = i
                break
            end
            i = i + 1
        end
    end
    return s:sub(1, cutPos) .. ".."
end

local function HudVisibility()
    return Core.GetSetting("hudVisibility") or "always"
end

--------------------------------------------------------------------------------
-- Click-catcher (used by all context menus to dismiss on click-away)
--------------------------------------------------------------------------------
local ctxCatcher = CreateFrame("Frame", "MidnightSenseiCtxCatcher", UIParent)
ctxCatcher:SetAllPoints(UIParent)
ctxCatcher:SetFrameStrata("HIGH")
ctxCatcher:EnableMouse(false)
ctxCatcher:Hide()

local function OpenCtxMenu(menu, x, y)
    local scale = UIParent:GetEffectiveScale()
    menu:ClearAllPoints()
    -- Keep menu on screen
    local mx = math.min(x / scale, UIParent:GetWidth()  - menu:GetWidth()  - 4)
    local my = math.max(y / scale, menu:GetHeight() + 4)
    menu:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", mx, my)
    menu:Show()
    ctxCatcher:EnableMouse(true)
    ctxCatcher:Show()
end

local function CloseAllMenus()
    -- Forward declaration refs filled below
    if _G.MidnightSenseiCtxMenu    and _G.MidnightSenseiCtxMenu:IsShown()    then _G.MidnightSenseiCtxMenu:Hide()    end
    if _G.MidnightSenseiMainCtx    and _G.MidnightSenseiMainCtx:IsShown()    then _G.MidnightSenseiMainCtx:Hide()    end
    ctxCatcher:EnableMouse(false)
    ctxCatcher:Hide()
end

ctxCatcher:SetScript("OnMouseDown", CloseAllMenus)

--------------------------------------------------------------------------------
-- Context Menu builder
--------------------------------------------------------------------------------
local function BuildCtxMenu(name, items)
    -- items = { {label, fn}, ... }
    local h = 10 + #items * 24
    local menu = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetSize(164, h)
    ApplyBackdrop(menu, {0.06, 0.06, 0.10, 0.98}, C.BORDER_GOLD)

    for i, item in ipairs(items) do
        local btn = CreateFrame("Button", nil, menu)
        btn:SetSize(144, 22)
        btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, -(i-1)*24 - 5)
        local fs = MakeFont(btn, 11, "LEFT")
        fs:SetPoint("LEFT", btn, "LEFT", 4, 0)
        fs:SetText(item.label or "")
        btn.fs  = fs
        btn.key = item.key
        btn:SetScript("OnEnter", function()
            fs:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
            GameTooltip:Hide()
        end)
        btn:SetScript("OnLeave", function()
            fs:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3], 1)
        end)
        btn:SetScript("OnClick", function()
            menu:Hide()
            CloseAllMenus()
            if item.fn then item.fn() end
        end)
        if item.isRef then menu[item.key] = btn end
    end

    menu:SetScript("OnHide", CloseAllMenus)
    return menu
end

--------------------------------------------------------------------------------
-- History row context menu
--------------------------------------------------------------------------------
local histCtxMenu   -- forward declare so closures below can reference it
histCtxMenu = BuildCtxMenu("MidnightSenseiCtxMenu", {
    { label = "Inspect Details", fn = function()
        if histCtxMenu._enc then UI.ShowEncounterDetail(histCtxMenu._enc) end
    end },
    { label = "Delete Entry", fn = function()
        local idx = histCtxMenu._idx
        if idx and MidnightSenseiCharDB and MidnightSenseiCharDB.encounters then
            table.remove(MidnightSenseiCharDB.encounters, idx)
            UI.RefreshHistory()
        end
    end },
    { label = "Cancel" },
})

local function ShowHistCtxMenu(enc, idx)
    histCtxMenu._enc = enc
    histCtxMenu._idx = idx
    local x, y = GetCursorPosition()
    OpenCtxMenu(histCtxMenu, x, y)
end

--------------------------------------------------------------------------------
-- Encounter Detail popup
--------------------------------------------------------------------------------
local detailFrame = nil

function UI.ShowEncounterDetail(enc)
    if not enc then return end
    if not detailFrame then
        detailFrame = CreateFrame("Frame", "MidnightSenseiDetail", UIParent, "BackdropTemplate")
        detailFrame:SetSize(360, 340)
        detailFrame:SetPoint("CENTER")
        detailFrame:SetFrameStrata("DIALOG")
        detailFrame:SetMovable(true)
        detailFrame:SetClampedToScreen(true)
        detailFrame:EnableMouse(true)
        detailFrame:RegisterForDrag("LeftButton")
        detailFrame:SetScript("OnDragStart", function(f) f:StartMoving() end)
        detailFrame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
        ApplyBackdrop(detailFrame, C.BG, C.BORDER_GOLD)
        MakeTitleBar(detailFrame, "Midnight Sensei - Encounter Detail")

        local sf = CreateFrame("ScrollFrame", nil, detailFrame, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     detailFrame, "TOPLEFT",  10, -34)
        sf:SetPoint("BOTTOMRIGHT", detailFrame, "BOTTOMRIGHT", -26, 36)
        local sc = CreateFrame("Frame", nil, sf)
        sc:SetWidth(sf:GetWidth()) ; sc:SetHeight(10)
        sf:SetScrollChild(sc)

        detailFrame.content = MakeFont(sc, 10, "LEFT")
        detailFrame.content:SetPoint("TOPLEFT",  sc, "TOPLEFT",  4, -4)
        detailFrame.content:SetPoint("TOPRIGHT", sc, "TOPRIGHT", -4, -4)
        detailFrame.content:SetWordWrap(true)
        detailFrame.content:SetSpacing(2)
        detailFrame._sc = sc

        local closeBtn = MakeButton(detailFrame, 60, 22, "Close")
        closeBtn:SetPoint("BOTTOM", detailFrame, "BOTTOM", 0, 8)
        closeBtn:SetScript("OnClick", function() detailFrame:Hide() end)
    end

    local hex   = GradeHex(enc.finalScore)
    local char  = enc.charName and (enc.charName .. (enc.realmName and ("-"..enc.realmName) or "")) or "?"

    -- Build a rich encounter type descriptor
    local typeMap = { dungeon="Dungeon", raid="Raid", delve="Delve", normal="World" }
    local encLabel
    if enc.isBoss then
        local diff = enc.diffLabel and enc.diffLabel ~= "" and (" " .. enc.diffLabel) or ""
        local ks   = enc.keystoneLevel and (" M+" .. enc.keystoneLevel) or ""
        encLabel = "|cffFF6600[Boss] " .. (enc.bossName or "?") .. diff .. ks .. "|r"
    else
        local cat  = typeMap[enc.encType] or "Combat"
        local diff = enc.diffLabel and enc.diffLabel ~= "" and (" " .. enc.diffLabel) or ""
        local ks   = enc.keystoneLevel and (" M+" .. enc.keystoneLevel) or ""
        encLabel = "|cff888888" .. cat .. diff .. ks .. "|r"
    end

    local lines = {
        "|cff00D1FF" .. (enc.specName or "?") .. " " .. (enc.className or "?") .. "|r",
        char .. "  -  " .. (enc.timestamp and date("%b %d %Y  %H:%M", enc.timestamp) or "?"),
        encLabel,
        "Duration: " .. FormatDuration(enc.duration) ..
            "    Grade: |cff" .. hex .. (enc.finalGrade or "?") .. "|r" ..
            "  (" .. (enc.gradeLabel or "") .. ")",
        "Score: " .. (enc.finalScore or 0),
        " ",
    }
    if enc.componentScores then
        table.insert(lines, "|cffFFD700Component Scores:|r")
        for k, v in pairs(enc.componentScores) do
            if k ~= "_final" then
                local lbl = k:gsub("(%l)(%u)", "%1 %2"):gsub("^%l", string.upper)
                table.insert(lines, string.format("  %-24s %d", lbl, math.floor(v or 0)))
            end
        end
        table.insert(lines, " ")
    end
    if enc.feedback and #enc.feedback > 0 then
        table.insert(lines, "|cffFFD700Feedback:|r")
        for _, fb in ipairs(enc.feedback) do
            table.insert(lines, "  - " .. fb)
        end
    end

    detailFrame.content:SetText(table.concat(lines, "\n"))
    C_Timer.After(0.05, function()
        if detailFrame._sc and detailFrame.content then
            detailFrame._sc:SetHeight(detailFrame.content:GetStringHeight() + 20)
        end
    end)
    detailFrame:Show()
end

--------------------------------------------------------------------------------
-- Sparkline
--------------------------------------------------------------------------------
local function DrawSparkline(parent, scores, w, h)
    if parent.sparkBars then
        for _, b in ipairs(parent.sparkBars) do b:Hide() end
    end
    parent.sparkBars = {}
    if not scores or #scores == 0 then return end
    local n    = math.min(#scores, 20)
    local barW = math.max(3, math.floor(w / n) - 1)
    local xOff = 0
    for i = #scores - n + 1, #scores do
        local s    = scores[i] or 0
        local barH = math.max(1, math.floor((s/100) * h))
        local bar  = parent:CreateTexture(nil, "OVERLAY")
        bar:SetSize(barW, barH)
        bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOff, 0)
        local r, g, b = 0.80, 0.20, 0.20
        if     s >= 90 then r,g,b = 0.20,0.90,0.20
        elseif s >= 75 then r,g,b = 0.50,0.80,0.25
        elseif s >= 60 then r,g,b = 1.00,0.70,0.15 end
        bar:SetColorTexture(r, g, b, 0.85)
        table.insert(parent.sparkBars, bar)
        xOff = xOff + barW + 1
    end
end

--------------------------------------------------------------------------------
-- Grade History
--------------------------------------------------------------------------------
local historyFrame    = nil
local historyFilter   = { mode = "current" }  -- mode: "current"|"all"|"spec"
                                               -- spec: specName string
local function GetCurrentCharKey()
    local n = UnitName("player") or "?"
    local r = GetRealmName() or "?"
    return n .. "-" .. r
end

local function FilterEncounters(encounters)
    local result  = {}
    local charKey = GetCurrentCharKey()
    for _, enc in ipairs(encounters) do
        if historyFilter.mode == "current" then
            -- Include if charName matches, OR if charName is missing (legacy encounter)
            local encKey = (enc.charName and enc.charName ~= "?")
                and (enc.charName .. "-" .. (enc.realmName or "?"))
                or nil
            if encKey == nil or encKey == charKey then
                table.insert(result, enc)
            end
        elseif historyFilter.mode == "boss" then
            if enc.isBoss then
                table.insert(result, enc)
            end
        elseif historyFilter.mode == "spec" then
            if enc.specName == historyFilter.spec then
                table.insert(result, enc)
            end
        end
    end
    return result
end

local function BuildHistoryRows(scrollChild, encounters, rowFrames)
    for _, r in ipairs(rowFrames) do r:Hide() end
    local yOff = 0
    -- Show newest first
    for i = #encounters, math.max(1, #encounters - 99), -1 do
        local enc  = encounters[i]
        local rowN = #encounters - i + 1
        local row  = rowFrames[rowN]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            row:SetHeight(28)
            row:EnableMouse(true)

            row.gradeText = MakeFont(row, 14, "CENTER")
            row.gradeText:SetPoint("LEFT", row, "LEFT", 8, 0)
            row.gradeText:SetWidth(30)

            row.charText  = MakeFont(row, 9, "LEFT")
            row.charText:SetPoint("LEFT", row, "LEFT", 42, 0)
            row.charText:SetWidth(90)
            row.charText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)

            row.specText  = MakeFont(row, 10, "LEFT")
            row.specText:SetPoint("LEFT", row, "LEFT", 136, 0)
            row.specText:SetWidth(130)

            row.scoreText = MakeFont(row, 11, "RIGHT")
            row.scoreText:SetPoint("RIGHT", row, "RIGHT", -126, 0)
            row.scoreText:SetWidth(34)

            row.durText   = MakeFont(row, 9, "RIGHT")
            row.durText:SetPoint("RIGHT", row, "RIGHT", -48, 0)
            row.durText:SetWidth(40)
            row.durText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)

            row.timeText  = MakeFont(row, 9, "RIGHT")
            row.timeText:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            row.timeText:SetWidth(44)
            row.timeText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)

            rowFrames[rowN] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  0, -yOff)
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOff)

        local bgc = (rowN % 2 == 0) and C.ROW_EVEN or C.ROW_ODD
        row:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile=true, tileSize=16 })
        row:SetBackdropColor(bgc[1], bgc[2], bgc[3], bgc[4] or 0.5)

        local hex = GradeHex(enc.finalScore)
        row.gradeText:SetText("|cff" .. hex .. (enc.finalGrade or "?") .. "|r")
        row.charText:SetText(enc.charName or "?")

        -- Spec column: show boss name on boss fights, spec+diff otherwise
        -- [K] green = kill, [W] red = wipe; nil isKill (legacy) treated as kill
        local specLabel
        if enc.isBoss and enc.bossName and enc.bossName ~= "" then
            local ks = enc.keystoneLevel and (" M+"..enc.keystoneLevel) or ""
            local diff = (not enc.keystoneLevel and enc.diffLabel
                         and enc.diffLabel ~= "" and enc.diffLabel ~= "World")
                         and (" "..enc.diffLabel) or ""
            local bTag = (enc.isKill == false) and "|cffFF4444[W]|r " or "|cff55DD55[K]|r "
            specLabel = bTag .. enc.bossName .. diff .. ks
        else
            local bossTag  = enc.isBoss and ((enc.isKill == false) and "|cffFF4444[W]|r " or "|cff55DD55[K]|r ") or ""
            local diffSuffix = ""
            if enc.keystoneLevel then
                diffSuffix = " M+" .. enc.keystoneLevel
            elseif enc.diffLabel and enc.diffLabel ~= "" and enc.diffLabel ~= "World" then
                diffSuffix = " " .. enc.diffLabel
            end
            specLabel = bossTag .. (enc.specName or "?") .. diffSuffix
        end
        row.specText:SetText(TruncateLabel(specLabel, 28))

        row.scoreText:SetText(tostring(enc.finalScore or 0))
        row.durText:SetText(FormatDuration(enc.duration))
        row.timeText:SetText(TimeAgo(enc.timestamp))

        row:SetScript("OnEnter", function(r)
            r:SetBackdropColor(C.ROW_HOVER[1], C.ROW_HOVER[2], C.ROW_HOVER[3], C.ROW_HOVER[4])
        end)
        row:SetScript("OnLeave", function(r)
            r:SetBackdropColor(bgc[1], bgc[2], bgc[3], bgc[4] or 0.5)
        end)

        local capturedEnc = enc
        local capturedIdx = i
        row:SetScript("OnMouseDown", function(_, btn)
            if btn == "RightButton" then ShowHistCtxMenu(capturedEnc, capturedIdx)
            elseif btn == "LeftButton" then UI.ShowEncounterDetail(capturedEnc) end
        end)

        row:Show()
        yOff = yOff + 28
    end
    scrollChild:SetHeight(math.max(yOff + 8, 80))
end

local function RefreshHistoryContent()
    if not historyFrame then return end
    local allEnc  = (MidnightSenseiCharDB and MidnightSenseiCharDB.encounters) or {}
    local filtered = FilterEncounters(allEnc)

    -- Sparkline (all for this char/filter)
    local sparkScores = {}
    for _, enc in ipairs(filtered) do table.insert(sparkScores, enc.finalScore or 0) end
    DrawSparkline(historyFrame.sparkContainer, sparkScores,
                  historyFrame.sparkContainer:GetWidth() - 8,
                  historyFrame.sparkContainer:GetHeight() - 4)

    -- Stats — avg/best/worst computed from kills only; wipes excluded (nil = legacy = kill)
    if #filtered > 0 then
        local tot, best, worst, killCount = 0, 0, 100, 0
        for _, enc in ipairs(filtered) do
            if enc.isKill ~= false then
                local s = enc.finalScore or 0
                killCount = killCount + 1
                tot   = tot + s
                if s > best  then best  = s end
                if s < worst then worst = s end
            end
        end
        local wipes  = #filtered - killCount
        local avg    = killCount > 0 and math.floor(tot / killCount) or 0
        local suffix = wipes > 0
            and ("  -  |cffFF6644" .. wipes .. " wipe" .. (wipes == 1 and "" or "s") .. "|r")
            or ""
        historyFrame.statsText:SetText(
            #filtered .. " fights  -  Avg: " .. avg ..
            "  -  Best: |cff" .. GradeHex(best)  .. best  .. "|r" ..
            "  -  Worst: |cff" .. GradeHex(worst) .. worst .. "|r" .. suffix)
    else
        historyFrame.statsText:SetText("No encounters match the current filter.")
    end

    BuildHistoryRows(historyFrame.scrollChild, filtered, historyFrame.rowFrames)

    -- Update filter button labels
    if historyFrame.filterBtns then
        for _, fb in ipairs(historyFrame.filterBtns) do
            local active = (fb.filterKey == historyFilter.mode)
            fb.label:SetTextColor(
                active and C.ACCENT[1]    or C.TEXT_DIM[1],
                active and C.ACCENT[2]    or C.TEXT_DIM[2],
                active and C.ACCENT[3]    or C.TEXT_DIM[3], 1)
            ApplyBackdrop(fb,
                active and {0.12,0.12,0.20,0.95} or C.BG_LIGHT,
                C.BORDER)
        end
    end
end

function UI.RefreshHistory()
    if historyFrame and historyFrame:IsShown() then RefreshHistoryContent() end
end

function UI.ShowHistory()
    if not historyFrame then
        historyFrame = CreateFrame("Frame", "MidnightSenseiHistory", UIParent, "BackdropTemplate")
        historyFrame:SetSize(490, 520)
        historyFrame:SetPoint("CENTER", UIParent, "CENTER", -340, 0)
        historyFrame:SetFrameStrata("HIGH")
        historyFrame:SetMovable(true)
        historyFrame:SetClampedToScreen(true)
        historyFrame:EnableMouse(true)
        ApplyBackdrop(historyFrame, C.BG, C.BORDER_GOLD)
        MakeTitleBar(historyFrame, "Midnight Sensei - Grade History")

        -- Sparkline
        local sparkLabel = MakeFont(historyFrame, 9, "LEFT")
        sparkLabel:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", 12, -34)
        sparkLabel:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
        sparkLabel:SetText("Trend (last 20):")

        local sparkContainer = CreateFrame("Frame", nil, historyFrame, "BackdropTemplate")
        sparkContainer:SetSize(460, 32)
        sparkContainer:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", 12, -46)
        ApplyBackdrop(sparkContainer, {0.02,0.02,0.04,0.80}, C.BORDER)
        historyFrame.sparkContainer = sparkContainer

        -- Stats row
        historyFrame.statsText = MakeFont(historyFrame, 10, "LEFT")
        historyFrame.statsText:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", 12, -86)
        historyFrame.statsText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)

        -- Filter bar
        local filterLabel = MakeFont(historyFrame, 9, "LEFT")
        filterLabel:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", 12, -104)
        filterLabel:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
        filterLabel:SetText("Filter:")

        historyFrame.filterBtns = {}
        local filterDefs = {
            { label = "This Character", key = "current" },
            { label = "[Boss] Only",    key = "boss"    },
        }
        -- Add per-spec filters dynamically when populating
        local xFilterOff = 48
        for _, fd in ipairs(filterDefs) do
            local fw = (fd.key == "boss") and 90 or 110
            local fb = MakeButton(historyFrame, fw, 18, fd.label)
            fb:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", xFilterOff, -105)
            fb.filterKey = fd.key
            local capturedKey = fd.key
            fb:SetScript("OnClick", function()
                historyFilter.mode = capturedKey
                historyFilter.spec = nil
                RefreshHistoryContent()
            end)
            table.insert(historyFrame.filterBtns, fb)
            xFilterOff = xFilterOff + fw + 6
        end
        historyFrame.specFilterStart = xFilterOff

        -- Column headers
        local hdrRow = CreateFrame("Frame", nil, historyFrame)
        hdrRow:SetPoint("TOPLEFT",  historyFrame, "TOPLEFT",  8,  -126)
        hdrRow:SetPoint("TOPRIGHT", historyFrame, "TOPRIGHT", -20, -126)
        hdrRow:SetHeight(16)
        local function Hdr(t, anchor, x, w)
            local fs = MakeFont(hdrRow, 9, anchor)
            fs:SetPoint(anchor, hdrRow, anchor, x, 0)
            fs:SetWidth(w)
            fs:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
            fs:SetText(t)
        end
        Hdr("GR",         "LEFT",   8,  28)
        Hdr("CHARACTER",  "LEFT",  42,  88)
        Hdr("SPEC / DIFF","LEFT", 134, 136)
        Hdr("SCORE",      "RIGHT", -126, 34)
        Hdr("DUR",        "RIGHT",  -48, 40)
        Hdr("WHEN",       "RIGHT",   -2, 44)

        -- Scroll frame
        local scroll = CreateFrame("ScrollFrame", "MidnightSenseiHistoryScroll",
                                   historyFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",     historyFrame, "TOPLEFT",  8,  -144)
        scroll:SetPoint("BOTTOMRIGHT", historyFrame, "BOTTOMRIGHT", -22, 38)

        local scrollChild = CreateFrame("Frame", nil, scroll)
        scrollChild:SetWidth(scroll:GetWidth()) ; scrollChild:SetHeight(200)
        scroll:SetScrollChild(scrollChild)
        historyFrame.scrollChild = scrollChild
        historyFrame.rowFrames   = {}

        -- Footer
        local lbBtn = MakeButton(historyFrame, 110, 22, "Leaderboard ->")
        lbBtn:SetPoint("BOTTOMRIGHT", historyFrame, "BOTTOMRIGHT", -10, 10)
        lbBtn:SetScript("OnClick", function() Core.Call(MS.Leaderboard, "Toggle") end)
    end

    historyFrame:Show()
    RefreshHistoryContent()
end

--------------------------------------------------------------------------------
-- Main HUD Frame
--------------------------------------------------------------------------------
local mainFrame = nil

-- Forward-declared so the reviewBtn closure inside CreateMainFrame can
-- reference it before the function body is defined below.
local ShowResultPanel

local function ApplyHudVisibility(event)
    -- event: "show" (manual), "combat_start", "combat_end", "init"
    if not mainFrame then return end
    local vis = HudVisibility()
    if vis == "hide" then
        mainFrame:Hide() ; return
    end
    if vis == "always" then
        mainFrame:Show() ; return
    end
    if vis == "combat" then
        if event == "combat_start" then mainFrame:Show()
        elseif event == "combat_end" then mainFrame:Hide()
        elseif event == "show" then mainFrame:Show()  -- manual override
        end
        return
    end
end

local function PopulateHudFromResult(result)
    if not mainFrame then return end
    if result then
        -- gradeColor stored in SavedVariables may lose its table structure on reload
        local gc = result.gradeColor
        if type(gc) ~= "table" or not gc[1] then
            local _, col = Core.GetGrade(result.finalScore)
            gc = col or {0.6, 0.6, 0.6}
        end
        mainFrame.gradeText:SetText(result.finalGrade or "?")
        mainFrame.gradeText:SetTextColor(gc[1], gc[2], gc[3], 1)
        mainFrame.scoreText:SetText(tostring(result.finalScore or 0))
        mainFrame.scoreText:SetTextColor(gc[1], gc[2], gc[3], 1)
        local bossTag = (result.isBoss and result.bossName)
            and ("|cffFF6600[Boss] " .. result.bossName .. "|r  ")
            or ""
        mainFrame.labelText:SetText(bossTag .. (result.gradeLabel or ""))
        mainFrame.labelText:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
        mainFrame.reviewBtn:Show()
    else
        mainFrame.gradeText:SetText("")
        mainFrame.scoreText:SetText("")
        mainFrame.labelText:SetText("No fight recorded yet")
        mainFrame.labelText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
        mainFrame.reviewBtn:Hide()
    end
end

local function CreateMainFrame()
    if mainFrame then return mainFrame end

    mainFrame = CreateFrame("Frame", "MidnightSenseiMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(260, 130)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER",
        Core.GetSetting("anchorX") or 0,
        Core.GetSetting("anchorY") or -200)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetMovable(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(f)
        if not Core.GetSetting("lockWindow") then f:StartMoving() end
    end)
    mainFrame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local x, y = f:GetCenter()
        local cx, cy = UIParent:GetCenter()
        Core.SetSetting("anchorX", math.floor(x - cx))
        Core.SetSetting("anchorY", math.floor(y - cy))
    end)
    ApplyBackdrop(mainFrame)

    -- Title strip
    local titleStrip = mainFrame:CreateTexture(nil, "BACKGROUND")
    titleStrip:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  2, -2)
    titleStrip:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    titleStrip:SetHeight(20)
    titleStrip:SetColorTexture(0.10, 0.10, 0.16, 0.95)

    local titleText = MakeFont(mainFrame, 10, "CENTER")
    titleText:SetPoint("TOP", mainFrame, "TOP", 0, -6)
    titleText:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3], 1)
    titleText:SetText("Midnight Sensei")

    -- Grade (large, left)
    mainFrame.gradeText = MakeFont(mainFrame, 32, "CENTER")
    mainFrame.gradeText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -22)
    mainFrame.gradeText:SetWidth(52)
    mainFrame.gradeText:SetText("")
    mainFrame.gradeText:SetTextColor(0.55, 0.55, 0.55, 1)

    -- Score (right of grade)
    mainFrame.scoreText = MakeFont(mainFrame, 20, "LEFT")
    mainFrame.scoreText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 68, -26)
    mainFrame.scoreText:SetText("")
    mainFrame.scoreText:SetTextColor(0.55, 0.55, 0.55, 1)

    -- Label (encouraging text / status)
    mainFrame.labelText = MakeFont(mainFrame, 9, "LEFT")
    mainFrame.labelText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 68, -50)
    mainFrame.labelText:SetText("No fight recorded yet")
    mainFrame.labelText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)

    -- Spec text
    mainFrame.specText = MakeFont(mainFrame, 9, "LEFT")
    mainFrame.specText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 68, -62)
    mainFrame.specText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
    mainFrame.specText:SetText(Core.GetSpecInfoString())

    -- Fight timer (top-right) — shifted left to make room for X and cog
    mainFrame.timerText = MakeFont(mainFrame, 9, "RIGHT")
    mainFrame.timerText:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -38, -6)
    mainFrame.timerText:SetWidth(70)
    mainFrame.timerText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)

    -- Cog button — opens context menu (replaces right-click)
    local cogBtn = CreateFrame("Button", nil, mainFrame)
    cogBtn:SetSize(12, 12)
    cogBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -22, -5)
    cogBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    cogBtn:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 1)
    cogBtn:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton")
    cogBtn:GetHighlightTexture():SetVertexColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
    cogBtn:SetScript("OnClick", function() UI.ShowMainCtxMenu() end)
    cogBtn:SetScript("OnEnter", function()
        cogBtn:GetNormalTexture():SetVertexColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
        GameTooltip:SetOwner(cogBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Menu", 0, 0.82, 1)
        GameTooltip:Show()
    end)
    cogBtn:SetScript("OnLeave", function()
        cogBtn:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 1)
        GameTooltip:Hide()
    end)

    -- X button — closes/hides the HUD
    local xBtn = CreateFrame("Button", nil, mainFrame)
    xBtn:SetSize(16, 16)
    xBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -4, -3)
    local xFs = MakeFont(xBtn, 11, "CENTER")
    xFs:SetPoint("CENTER")
    xFs:SetText("|cffaaaaaaX|r")
    xBtn:SetScript("OnClick", function() mainFrame:Hide() end)
    xBtn:SetScript("OnEnter", function()
        xFs:SetTextColor(1, 0.3, 0.3, 1)
        GameTooltip:SetOwner(xBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Hide HUD", 1, 0.3, 0.3)
        GameTooltip:Show()
    end)
    xBtn:SetScript("OnLeave", function()
        xFs:SetTextColor(0.67, 0.67, 0.67, 1)
        GameTooltip:Hide()
    end)

    -- Separator
    local sep = mainFrame:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("BOTTOMLEFT",  mainFrame, "BOTTOMLEFT",  4, 28)
    sep:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -4, 28)
    sep:SetHeight(1)
    sep:SetColorTexture(C.SEP[1], C.SEP[2], C.SEP[3], C.SEP[4])

    -- Review Fight — sits in the middle content area, hidden until a fight completes
    local reviewBtn = MakeButton(mainFrame, 90, 18, "Review Fight")
    reviewBtn:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 30)
    reviewBtn:SetScript("OnClick", function()
        local enc = (MS.Analytics and MS.Analytics.GetLastEncounter
                     and MS.Analytics.GetLastEncounter())
                    or (MS.Analytics and MS.Analytics.LastResult)
        if enc then
            -- Use _G reference so we get the current resultFrame value at click
            -- time regardless of declaration order in the file
            local rf = _G["MidnightSenseiResult"]
            if rf and rf:IsShown() then
                rf:Hide()
            else
                ShowResultPanel(enc)
            end
        end
    end)
    reviewBtn:Hide()
    mainFrame.reviewBtn = reviewBtn

    -- Boss Board button — bottom left, always visible
    local bbBtn = MakeButton(mainFrame, 108, 22, "Boss Board")
    bbBtn:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 4, 4)
    bbBtn:SetScript("OnClick", function()
        if MS.BossBoard and MS.BossBoard.Toggle then
            MS.BossBoard.Toggle()
        end
    end)
    bbBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Boss Board", 0, 0.82, 1)
        GameTooltip:AddLine("Personal all-time boss best scores", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    bbBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Leaderboard button — always visible in bottom right
    local lbBtn = MakeButton(mainFrame, 90, 22, "Leaderboard")
    lbBtn:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -4, 4)
    lbBtn:SetScript("OnClick", function()
        if MS.Leaderboard and MS.Leaderboard.Toggle then
            MS.Leaderboard.Toggle()
        end
    end)
    lbBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Leaderboard", 0, 0.82, 1)
        GameTooltip:AddLine("Guild / Party / Friends / Delves", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    lbBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Verify bar — anchored below mainFrame; shown only when verify mode is active
    local vBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    vBar:SetSize(260, 24)
    vBar:SetPoint("TOPLEFT", mainFrame, "BOTTOMLEFT", 0, -2)
    vBar:SetPoint("TOPRIGHT", mainFrame, "BOTTOMRIGHT", 0, -2)
    ApplyBackdrop(vBar, {0.04, 0.10, 0.04, 0.95}, {0.2, 0.6, 0.2, 0.8})

    local vBarLbl = MakeFont(vBar, 9, "LEFT")
    vBarLbl:SetPoint("LEFT", vBar, "LEFT", 8, 0)
    vBarLbl:SetTextColor(0.40, 1.00, 0.40, 1)
    vBarLbl:SetText("Verify Mode On")

    local vBarBtn = MakeButton(vBar, 84, 18, "View Report")
    vBarBtn:SetPoint("RIGHT", vBar, "RIGHT", -4, 0)
    vBarBtn:SetScript("OnClick", function()
        if MS.UI and MS.UI.ToggleVerifyExport then
            MS.UI.ToggleVerifyExport()
        end
    end)

    vBar:SetShown(MS.Core and MS.Core.VerifyMode or false)
    mainFrame.verifyBar = vBar

    -- Timer tick
    Core.RegisterTick("hud_timer", 0.5, function()
        if not mainFrame or not mainFrame:IsShown() then return end
        if Core.InCombat then
            local e = GetTime() - Core.CombatStart
            mainFrame.timerText:SetText("|cffFF4444* " .. FormatDuration(e) .. "|r")
        else
            mainFrame.timerText:SetText("")
        end
    end)

    mainFrame:Hide()
    return mainFrame
end

--------------------------------------------------------------------------------
-- Main HUD right-click menu
--------------------------------------------------------------------------------
local mainCtxMenu = nil
function UI.ShowMainCtxMenu()
    if not mainCtxMenu then
        mainCtxMenu = CreateFrame("Frame", "MidnightSenseiMainCtx", UIParent, "BackdropTemplate")
        mainCtxMenu:SetFrameStrata("TOOLTIP")
        mainCtxMenu:SetSize(164, 182)
        ApplyBackdrop(mainCtxMenu, {0.06,0.06,0.10,0.98}, C.BORDER_GOLD)

        local function AddItem(lbl, yOff, fn, key)
            local item = CreateFrame("Button", nil, mainCtxMenu)
            item:SetSize(144, 22)
            item:SetPoint("TOPLEFT", mainCtxMenu, "TOPLEFT", 10, yOff)
            local fs = MakeFont(item, 11, "LEFT")
            fs:SetPoint("LEFT", item, "LEFT", 4, 0)
            fs:SetText(lbl)
            item.fs = fs
            item:SetScript("OnEnter", function()
                fs:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
                GameTooltip:Hide()
            end)
            item:SetScript("OnLeave", function()
                fs:SetTextColor(C.TEXT[1], C.TEXT[2], C.TEXT[3], 1)
            end)
            item:SetScript("OnClick", function()
                mainCtxMenu:Hide()
                CloseAllMenus()
                if fn then fn() end
            end)
            if key then mainCtxMenu[key] = item end
            return item
        end

        mainCtxMenu.lockItem = AddItem("Lock Position", -10, function()
            Core.SetSetting("lockWindow", not Core.GetSetting("lockWindow"))
        end, "lockItem")

        AddItem("Grade History",  -34, function() UI.ShowHistory() end)
        AddItem("Leaderboard",    -58, function() Core.Call(MS.Leaderboard, "Toggle") end)
        AddItem("Boss Board",     -82, function() Core.Call(MS.BossBoard, "Toggle") end)
        AddItem("Options",       -106, function() UI.OpenOptions() end)
        AddItem("My Spell List", -130, function() UI.ShowSpellList() end)
        AddItem("Help / FAQ",    -154, function() UI.ShowFAQ() end)
        AddItem("Credits",       -178, function() UI.ShowCredits() end)
        AddItem("Debug Tools",   -202, function() UI.ShowDebugWindow() end)
        AddItem("Close HUD",     -226, function()
            if mainFrame then mainFrame:Hide() end
        end)

        mainCtxMenu:SetSize(164, 254)
        mainCtxMenu:SetScript("OnHide", CloseAllMenus)
    end

    if mainCtxMenu.lockItem then
        local locked = Core.GetSetting("lockWindow")
        mainCtxMenu.lockItem.fs:SetText(locked and "Unlock Position" or "Lock Position")
    end

    local x, y = GetCursorPosition()
    OpenCtxMenu(mainCtxMenu, x, y)
end

--------------------------------------------------------------------------------
-- Post-fight results panel
--------------------------------------------------------------------------------
local resultFrame = nil

-- Post-fight results panel (assigned here to fill forward declaration above)
ShowResultPanel = function(result)
    if not result then return end

    if not resultFrame then
        resultFrame = CreateFrame("Frame", "MidnightSenseiResult", UIParent, "BackdropTemplate")
        resultFrame:SetSize(320, 400)
        -- Anchor to the right of the HUD so it never overlaps it
        if mainFrame and mainFrame:IsShown() then
            resultFrame:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 8, 0)
        else
            resultFrame:SetPoint("CENTER", UIParent, "CENTER", 160, 60)
        end
        resultFrame:SetFrameStrata("DIALOG")
        resultFrame:SetMovable(true)
        resultFrame:SetClampedToScreen(true)
        resultFrame:EnableMouse(true)
        resultFrame:RegisterForDrag("LeftButton")
        resultFrame:SetScript("OnDragStart", function(f) f:StartMoving() end)
        resultFrame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
        ApplyBackdrop(resultFrame, C.BG, C.BORDER_GOLD)
        MakeTitleBar(resultFrame, "Midnight Sensei - Fight Complete")

        resultFrame.gradeText = MakeFont(resultFrame, 44, "CENTER")
        resultFrame.gradeText:SetPoint("TOP", resultFrame, "TOP", 0, -40)
        resultFrame.gradeText:SetWidth(200)

        resultFrame.labelText = MakeFont(resultFrame, 12, "CENTER")
        resultFrame.labelText:SetPoint("TOP", resultFrame, "TOP", 0, -88)
        resultFrame.labelText:SetWidth(280)

        resultFrame.scoreText = MakeFont(resultFrame, 12, "CENTER")
        resultFrame.scoreText:SetPoint("TOP", resultFrame, "TOP", 0, -106)
        resultFrame.scoreText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)

        resultFrame.specText  = MakeFont(resultFrame, 10, "CENTER")
        resultFrame.specText:SetPoint("TOP", resultFrame, "TOP", 0, -122)
        resultFrame.specText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)

        local sep = resultFrame:CreateTexture(nil, "ARTWORK")
        sep:SetPoint("LEFT",  resultFrame, "LEFT",  12, 0)
        sep:SetPoint("RIGHT", resultFrame, "RIGHT", -12, 0)
        sep:SetHeight(1) ; sep:SetPoint("TOP", resultFrame, "TOP", 0, -136)
        sep:SetColorTexture(C.SEP[1], C.SEP[2], C.SEP[3], C.SEP[4])

        local sf = CreateFrame("ScrollFrame", nil, resultFrame, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     resultFrame, "TOPLEFT",  10, -144)
        sf:SetPoint("BOTTOMRIGHT", resultFrame, "BOTTOMRIGHT", -22, 36)
        local sc = CreateFrame("Frame", nil, sf)
        sc:SetWidth(sf:GetWidth()) ; sc:SetHeight(200)
        sf:SetScrollChild(sc)

        resultFrame.feedbackText = MakeFont(sc, 10, "LEFT")
        resultFrame.feedbackText:SetPoint("TOPLEFT",  sc, "TOPLEFT",  4, -4)
        resultFrame.feedbackText:SetPoint("TOPRIGHT", sc, "TOPRIGHT", -4, -4)
        resultFrame.feedbackText:SetWordWrap(true)
        resultFrame.feedbackText:SetSpacing(2)
        resultFrame._sc = sc

        local histBtn = MakeButton(resultFrame, 90, 22, "History")
        histBtn:SetPoint("BOTTOMLEFT", resultFrame, "BOTTOMLEFT", 10, 8)
        histBtn:SetScript("OnClick", function()
            resultFrame:Hide()
            UI.ShowHistory()
        end)

        local lbBtn = MakeButton(resultFrame, 90, 22, "Leaderboard")
        lbBtn:SetPoint("BOTTOM", resultFrame, "BOTTOM", 0, 8)
        lbBtn:SetScript("OnClick", function()
            resultFrame:Hide()
            Core.Call(MS.Leaderboard, "Toggle")
        end)

        local closeBtn = MakeButton(resultFrame, 70, 22, "Close")
        closeBtn:SetPoint("BOTTOMRIGHT", resultFrame, "BOTTOMRIGHT", -10, 8)
        closeBtn:SetScript("OnClick", function() resultFrame:Hide() end)

        -- Version watermark — small, dim, sits above the Close button, clear of the scrollbar arrow
        local verLabel = MakeFont(resultFrame, 8, "RIGHT")
        verLabel:SetPoint("BOTTOMRIGHT", resultFrame, "BOTTOMRIGHT", -88, 34)
        verLabel:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 0.5)
        resultFrame._verLabel = verLabel
    end

    -- Update version label from stored result — shows version that generated this feedback
    if resultFrame._verLabel then
        local v = result.addonVersion or Core.VERSION or "?"
        resultFrame._verLabel:SetText("v" .. v)
    end

    local hex = GradeHex(result.finalScore)
    local gc  = result.gradeColor or {0.6, 0.6, 0.6}
    resultFrame.gradeText:SetText("|cff" .. hex .. (result.finalGrade or "?") .. "|r")
    resultFrame.labelText:SetText(result.gradeLabel or "")
    resultFrame.labelText:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
    resultFrame.scoreText:SetText("Score: " .. (result.finalScore or 0) ..
                                  "   Duration: " .. FormatDuration(result.duration))
    resultFrame.specText:SetText((result.specName or "?") .. " " .. (result.className or ""))

    local fbLines = {}
    if result.feedback and #result.feedback > 0 then
        for i, line in ipairs(result.feedback) do
            table.insert(fbLines, i .. ".  " .. line)
        end
    else
        table.insert(fbLines, "Clean fight - nothing major to flag.")
    end
    table.insert(fbLines, " ")
    table.insert(fbLines, "|cffFFD700Component Scores:|r")
    if result.componentScores then
        for k, v in pairs(result.componentScores) do
            if k ~= "_final" then
                local lbl = k:gsub("(%l)(%u)", "%1 %2"):gsub("^%l", string.upper)
                table.insert(fbLines, string.format("  %-22s %d", lbl, math.floor(v or 0)))
            end
        end
    end

    resultFrame.feedbackText:SetText(table.concat(fbLines, "\n"))
    C_Timer.After(0.05, function()
        if resultFrame._sc and resultFrame.feedbackText then
            resultFrame._sc:SetHeight(resultFrame.feedbackText:GetStringHeight() + 20)
        end
    end)
    resultFrame:Show()
end

--------------------------------------------------------------------------------
-- Options panel
--------------------------------------------------------------------------------
local optionsFrame = nil

function UI.OpenOptions()
    if not optionsFrame then
        optionsFrame = CreateFrame("Frame", "MidnightSenseiOptions", UIParent, "BackdropTemplate")
        optionsFrame:SetSize(310, 460)   -- taller to fit new sections
        optionsFrame:SetPoint("CENTER")
        optionsFrame:SetFrameStrata("HIGH")
        optionsFrame:SetMovable(true)
        optionsFrame:SetClampedToScreen(true)
        optionsFrame:EnableMouse(true)
        optionsFrame:RegisterForDrag("LeftButton")
        optionsFrame:SetScript("OnDragStart", function(f) f:StartMoving() end)
        optionsFrame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
        ApplyBackdrop(optionsFrame, C.BG, C.BORDER_GOLD)
        MakeTitleBar(optionsFrame, "Midnight Sensei - Options")

        local function SectionLabel(text, yOff)
            local fs = MakeFont(optionsFrame, 9, "LEFT")
            fs:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 14, yOff)
            fs:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
            fs:SetText(text)
        end

        local function RadioGroup(options, settingKey, yOff, width)
            local btns = {}
            for i, opt in ipairs(options) do
                local btn = MakeButton(optionsFrame, width or 82, 22, opt.label)
                btn:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 14 + (i-1)*(width+6 or 88), yOff)
                btn.optKey = opt.key
                btn:SetScript("OnClick", function()
                    Core.SetSetting(settingKey, opt.key)
                    for _, b in ipairs(btns) do
                        local active = (b.optKey == opt.key)
                        ApplyBackdrop(b, active and {0.12,0.12,0.20,0.95} or C.BG_LIGHT, C.BORDER)
                        b.label:SetTextColor(
                            active and C.ACCENT[1] or C.TEXT[1],
                            active and C.ACCENT[2] or C.TEXT[2],
                            active and C.ACCENT[3] or C.TEXT[3], 1)
                    end
                    if settingKey == "hudVisibility" then ApplyHudVisibility("show") end
                end)
                table.insert(btns, btn)
            end
            return btns
        end

        local function AddToggle(label, settingKey, yOff, subLabel)
            local cb = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 14, yOff)
            cb:SetChecked(Core.GetSetting(settingKey) == true)
            cb:SetScript("OnClick", function(self)
                Core.SetSetting(settingKey, self:GetChecked())
            end)
            local fs = MakeFont(optionsFrame, 11, "LEFT")
            fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            fs:SetText(label)
            if subLabel then
                local sub = MakeFont(optionsFrame, 9, "LEFT")
                sub:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 38, yOff - 14)
                sub:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
                sub:SetText(subLabel)
            end
            return cb
        end

        -- ── HUD Visibility ────────────────────────────────────────────────
        SectionLabel("HUD Visibility:", -38)
        optionsFrame.visBtns = RadioGroup({
            { label = "Always",    key = "always" },
            { label = "In Combat", key = "combat" },
            { label = "Hide",      key = "hide"   },
        }, "hudVisibility", -54, 82)

        -- ── General Behaviour ─────────────────────────────────────────────
        SectionLabel("Behaviour:", -90)
        AddToggle("Show post-fight Review button on HUD", "showPostFight",  -106)
        AddToggle("Lock HUD position",                    "lockWindow",     -130)
        AddToggle("Encounter condition adjustment",       "encounterAdjust",-154)
        AddToggle("Debug mode (shows LB rejection msgs)", "debugMode",      -178)

        -- ── Leaderboard (boss-only is hardcoded, no toggle needed) ──────────
        SectionLabel("Leaderboard:", -292)
        local lbNote = MakeFont(optionsFrame, 9, "LEFT")
        lbNote:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 14, -306)
        lbNote:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -14, -306)
        lbNote:SetWordWrap(true)
        lbNote:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
        lbNote:SetText("Weekly average always counts boss encounters only. Trash pulls and target dummies are never included.")

        -- ── Close + Report ────────────────────────────────────────────────
        local closeBtn = MakeButton(optionsFrame, 60, 22, "Close")
        closeBtn:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOM", -4, 10)
        closeBtn:SetScript("OnClick", function() optionsFrame:Hide() end)

        local reportBtn = MakeButton(optionsFrame, 110, 22, "Report Issues")
        reportBtn:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOM", 4, 10)
        reportBtn:SetScript("OnClick", function() UI.ShowReportPopup() end)
    end

    -- Sync all radio group states on open
    local curVis = HudVisibility()
    for _, vb in ipairs(optionsFrame.visBtns or {}) do
        local active = (vb.optKey == curVis)
        ApplyBackdrop(vb, active and {0.12,0.12,0.20,0.95} or C.BG_LIGHT, C.BORDER)
        vb.label:SetTextColor(
            active and C.ACCENT[1] or C.TEXT[1],
            active and C.ACCENT[2] or C.TEXT[2],
            active and C.ACCENT[3] or C.TEXT[3], 1)
    end

    optionsFrame:Show()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Bug Report popup
-- Shows a selectable URL box pointing to the GitHub issues page.
-- WoW addons cannot open browsers directly; the standard pattern is a
-- pre-filled EditBox so the player can Ctrl+A / Ctrl+C and paste into a browser.
--------------------------------------------------------------------------------
local REPORT_URL = "https://github.com/MidnightTim/MidnightSensei/issues"

-- Register a StaticPopup so the editbox is a native WoW UI element that
-- automatically handles focus, selection, and copy correctly.
StaticPopupDialogs["MIDNIGHT_SENSEI_REPORT"] = {
    text          = "|cff00D1FFMidnight Sensei|r — Report a Bug\n\n" ..
                    "Copy the link below and paste it into your browser.\n" ..
                    "|cff888888Ctrl+A to select all, then Ctrl+C to copy.|r",
    button1       = "Close",
    hasEditBox    = true,
    editBoxWidth  = 320,
    maxLetters    = 0,
    timeout       = 0,
    whileDead     = true,
    hideOnEscape  = true,
    preferredIndex = 3,
    OnShow = function(self)
        self.EditBox:SetText(REPORT_URL)
        self.EditBox:SetFocus()
        self.EditBox:HighlightText()
        self.EditBox:SetScript("OnTextChanged", function(eb)
            if eb:GetText() ~= REPORT_URL then
                eb:SetText(REPORT_URL)
                eb:HighlightText()
            end
        end)
    end,
    OnAccept = function(self)
        self:Hide()
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
    end,
}

function UI.ShowReportPopup()
    StaticPopup_Show("MIDNIGHT_SENSEI_REPORT")
end

--------------------------------------------------------------------------------
-- Verify Export Window
-- Large scrollable multi-line editbox for copying verify report text.
-- Built as a custom frame since StaticPopup editboxes are too small.
--------------------------------------------------------------------------------
local verifyExportFrame = nil

function UI.ShowVerifyExport(text)
    if not verifyExportFrame then
        local f = CreateFrame("Frame", "MidnightSenseiVerifyExport", UIParent, "BackdropTemplate")
        f:SetSize(540, 400)
        f:SetPoint("CENTER")
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:EnableMouse(true)
        if f.SetBackdrop then
            f:SetBackdrop({
                bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile=true, tileSize=16, edgeSize=12,
                insets={left=2,right=2,top=2,bottom=2}
            })
            f:SetBackdropColor(0.06,0.06,0.10,0.97)
            f:SetBackdropBorderColor(1.00,0.65,0.00,0.90)
        end

        -- Title bar / drag
        local tBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
        tBar:SetPoint("TOPLEFT",  f,"TOPLEFT",  0, 0)
        tBar:SetPoint("TOPRIGHT", f,"TOPRIGHT", 0, 0)
        tBar:SetHeight(26)
        if tBar.SetBackdrop then
            tBar:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",
                              edgeFile="Interface/Tooltips/UI-Tooltip-Border",
                              tile=true,tileSize=16,edgeSize=12,
                              insets={left=2,right=2,top=2,bottom=2}})
            tBar:SetBackdropColor(0.10,0.10,0.18,1)
            tBar:SetBackdropBorderColor(1.00,0.65,0.00,0.90)
        end
        tBar:EnableMouse(true)
        tBar:RegisterForDrag("LeftButton")
        tBar:SetScript("OnDragStart", function() f:StartMoving() end)
        tBar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

        local title = tBar:CreateFontString(nil,"OVERLAY")
        title:SetFont("Fonts/FRIZQT__.TTF", 12, "")
        title:SetPoint("CENTER", tBar, "CENTER")
        title:SetTextColor(1.00,0.65,0.00,1)
        title:SetText("Midnight Sensei — Verify Report")

        local xBtn = CreateFrame("Button", nil, tBar)
        xBtn:SetSize(18,18)
        xBtn:SetPoint("RIGHT", tBar, "RIGHT", -4, 0)
        local xFs = xBtn:CreateFontString(nil,"OVERLAY")
        xFs:SetFont("Fonts/FRIZQT__.TTF",11,"")
        xFs:SetPoint("CENTER")
        xFs:SetText("X")
        xFs:SetTextColor(1,0.4,0.4,1)
        xBtn:SetScript("OnClick", function() f:Hide() end)

        -- Instruction text
        local hint = f:CreateFontString(nil,"OVERLAY")
        hint:SetFont("Fonts/FRIZQT__.TTF", 9, "")
        hint:SetPoint("TOPLEFT",  f,"TOPLEFT",  10, -32)
        hint:SetPoint("TOPRIGHT", f,"TOPRIGHT", -10,-32)
        hint:SetTextColor(0.55,0.53,0.50,1)
        hint:SetJustifyH("LEFT")
        hint:SetText("Ctrl+A to select all  ·  Ctrl+C to copy  ·  Paste into a GitHub comment")

        -- Scrollable editbox
        local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     f,"TOPLEFT",   10, -46)
        sf:SetPoint("BOTTOMRIGHT", f,"BOTTOMRIGHT",-28, 36)

        local eb = CreateFrame("EditBox", nil, sf)
        eb:SetMultiLine(true)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(sf:GetWidth())
        eb:SetAutoFocus(false)
        eb:SetTextInsets(4,4,4,4)
        eb:EnableMouse(true)
        -- Read-only feel: restore text if edited
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)

        -- Close button
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        closeBtn:SetSize(80,22)
        closeBtn:SetPoint("BOTTOM", f,"BOTTOM", 0, 8)
        closeBtn:SetText("Close")
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        f.editBox = eb
        verifyExportFrame = f
    end

    -- Strip WoW colour codes for clean plain-text export
    local plain = text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|n","\n")
    verifyExportFrame.editBox:SetText(plain)
    verifyExportFrame.editBox:SetFocus()
    verifyExportFrame.editBox:HighlightText()
    verifyExportFrame:Show()
end

function UI.ToggleVerifyExport()
    if verifyExportFrame and verifyExportFrame:IsShown() then
        verifyExportFrame:Hide()
    elseif MS.Core and MS.Core.SlashHandler then
        MS.Core.SlashHandler("verify report")
    end
end

--------------------------------------------------------------------------------
-- Debug Window
--------------------------------------------------------------------------------
-- My Spell List window
--------------------------------------------------------------------------------
-- C_Traits strict check — mirrors Analytics.IsTalentActive(spellID, true).
-- Returns true only if an active talent tree node resolves to spellID.
-- No IsPlayerSpell fallback, so cross-spec grayed spells can't trigger it.
local function UiTalentCheck(spellID)
    if C_Traits and C_Traits.GetNodeInfo then
        local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID
                         and C_ClassTalents.GetActiveConfigID()
        if configID then
            local config = C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(configID)
            if config and config.treeIDs then
                for _, treeID in ipairs(config.treeIDs) do
                    local nodes = C_Traits.GetTreeNodes and C_Traits.GetTreeNodes(treeID)
                    if nodes then
                        for _, nodeID in ipairs(nodes) do
                            local node = C_Traits.GetNodeInfo(configID, nodeID)
                            if node and node.activeRank and node.activeRank > 0 then
                                local entry = node.activeEntry
                                if entry then
                                    local def = C_Traits.GetEntryInfo and C_Traits.GetEntryInfo(configID, entry.entryID)
                                    if def and def.definitionID then
                                        local defInfo = C_Traits.GetDefinitionInfo and C_Traits.GetDefinitionInfo(def.definitionID)
                                        if defInfo and defInfo.spellID == spellID then
                                            return true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local spellListFrame = nil

function UI.ShowSpellList()
    if spellListFrame then
        spellListFrame:SetShown(not spellListFrame:IsShown())
        if spellListFrame:IsShown() then UI.RefreshSpellList() end
        return
    end

    spellListFrame = CreateFrame("Frame", "MidnightSenseiSpellList", UIParent, "BackdropTemplate")
    spellListFrame:SetSize(310, 460)
    spellListFrame:SetPoint("CENTER")
    spellListFrame:SetFrameStrata("DIALOG")
    spellListFrame:SetMovable(true)
    spellListFrame:SetClampedToScreen(true)
    spellListFrame:EnableMouse(true)
    spellListFrame:RegisterForDrag("LeftButton")
    spellListFrame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    spellListFrame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
    ApplyBackdrop(spellListFrame, C.BG, C.BORDER_GOLD)
    MakeTitleBar(spellListFrame, "Midnight Sensei - My Spell List")

    -- Spec label
    local specLabel = MakeFont(spellListFrame, 11, "CENTER")
    specLabel:SetPoint("TOPLEFT",  spellListFrame, "TOPLEFT",  10, -32)
    specLabel:SetPoint("TOPRIGHT", spellListFrame, "TOPRIGHT", -10, -32)
    specLabel:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
    spellListFrame.specLabel = specLabel

    -- Subtitle
    local sub = MakeFont(spellListFrame, 10, "CENTER")
    sub:SetPoint("TOPLEFT",  spellListFrame, "TOPLEFT",  10, -46)
    sub:SetPoint("TOPRIGHT", spellListFrame, "TOPRIGHT", -10, -46)
    sub:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
    sub:SetText("Spells shown here are what Midnight Sensei is currently monitoring.")
    spellListFrame.sub = sub

    -- Scroll frame
    local sf = CreateFrame("ScrollFrame", nil, spellListFrame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     spellListFrame, "TOPLEFT",   10, -62)
    sf:SetPoint("BOTTOMRIGHT", spellListFrame, "BOTTOMRIGHT", -26, 36)
    local sc = CreateFrame("Frame", nil, sf)
    sc:SetWidth(sf:GetWidth())
    sc:SetHeight(10)
    sf:SetScrollChild(sc)
    spellListFrame._sc = sc

    -- Close button
    local closeBtn = MakeButton(spellListFrame, 60, 22, "Close")
    closeBtn:SetPoint("BOTTOM", spellListFrame, "BOTTOM", 0, 8)
    closeBtn:SetScript("OnClick", function() spellListFrame:Hide() end)

    UI.RefreshSpellList()
end

function UI.RefreshSpellList()
    if not spellListFrame or not spellListFrame:IsShown() then return end

    local sc = spellListFrame._sc
    -- Clear existing rows
    for _, child in ipairs({sc:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    for _, child in ipairs({sc:GetRegions()}) do child:Hide() end

    local spec = Core.ActiveSpec
    if not spec then
        local lbl = MakeFont(sc, 11, "CENTER")
        lbl:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, -10)
        lbl:SetPoint("TOPRIGHT", sc, "TOPRIGHT",  0, -10)
        lbl:SetText("No spec detected. Enter a fight first.")
        lbl:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
        sc:SetHeight(40)
        spellListFrame.specLabel:SetText("")
        return
    end

    -- Class / spec header — className is stamped onto ActiveSpec by DetectSpec()
    local className = spec.className or "Unknown Class"
    spellListFrame.specLabel:SetText(className .. " - " .. (spec.name or "Unknown Spec")
        .. "  |cff888888(" .. (spec.role or "") .. ")|r")

    local yOff = -4
    local ICON_SIZE = 20
    local ROW_H     = 26
    local COL_W     = sc:GetWidth() or 264

    -- Helper: draw a section header
    local function SectionHeader(title)
        local sep = sc:CreateTexture(nil, "ARTWORK")
        sep:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, yOff - 2)
        sep:SetPoint("TOPRIGHT", sc, "TOPRIGHT", 0, yOff - 2)
        sep:SetHeight(1)
        sep:SetColorTexture(C.SEP[1], C.SEP[2], C.SEP[3], C.SEP[4])
        yOff = yOff - 5

        local hdr = MakeFont(sc, 11, "LEFT")
        hdr:SetPoint("TOPLEFT", sc, "TOPLEFT", 2, yOff)
        hdr:SetText(title)
        hdr:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3], 1)
        yOff = yOff - 18
    end

    -- Helper: draw one spell row — only called for active/baseline spells
    local function SpellRow(spellID, label, note, rowIdx)
        local bg = sc:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, yOff)
        bg:SetPoint("TOPRIGHT", sc, "TOPRIGHT", 0, yOff)
        bg:SetHeight(ROW_H)
        local rc = (rowIdx % 2 == 0) and C.ROW_EVEN or C.ROW_ODD
        bg:SetColorTexture(rc[1], rc[2], rc[3], rc[4])

        -- Spell icon
        local tex = sc:CreateTexture(nil, "ARTWORK")
        tex:SetSize(ICON_SIZE, ICON_SIZE)
        tex:SetPoint("TOPLEFT", sc, "TOPLEFT", 4, yOff - 3)
        local iconPath = GetSpellTexture and GetSpellTexture(spellID)
        if iconPath then
            tex:SetTexture(iconPath)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        -- Spell name — narrower when a note is present to prevent overlap
        local nameStr = MakeFont(sc, 11, "LEFT")
        nameStr:SetPoint("TOPLEFT", sc, "TOPLEFT", 30, yOff - 4)
        nameStr:SetWidth(note and (COL_W - 155) or (COL_W - 34))
        nameStr:SetText(label or "Unknown")

        -- Usage note — fixed 115px right column, size 9 to fit longer notes
        if note then
            local noteStr = MakeFont(sc, 9, "RIGHT")
            noteStr:SetPoint("TOPRIGHT", sc, "TOPRIGHT", -4, yOff - 5)
            noteStr:SetWidth(115)
            noteStr:SetText("|cff888888" .. note .. "|r")
        end

        yOff = yOff - ROW_H
    end

    -- Determine which spells are active and not suppressed.
    -- talentGated: uses strict C_Traits check — no IsPlayerSpell fallback
    --   (cross-spec grayed spells return true from IsPlayerSpell even when not taken).
    -- suppressIfTalent: hide this entry when the replacing talent is active.
    -- combatGated: always show (combat-granted, no spellbook entry).
    local function isActive(entry)
        if entry.suppressIfTalent then
            if (IsPlayerSpell and IsPlayerSpell(entry.suppressIfTalent))
            or UiTalentCheck(entry.suppressIfTalent) then
                return false
            end
        end
        if entry.talentGated then
            return UiTalentCheck(entry.id) and (IsPlayerSpell and IsPlayerSpell(entry.id) or false)
        end
        if entry.combatGated then
            return true
        end
        return true  -- baseline spells are always active
    end

    local rowIdx = 0

    -- COOLDOWN SPELLS
    if spec.majorCooldowns and #spec.majorCooldowns > 0 then
        local hasCDs = false
        for _, cd in ipairs(spec.majorCooldowns) do
            if not cd.isInterrupt and not cd.isUtility and isActive(cd) then hasCDs = true; break end
        end
        if hasCDs then
            SectionHeader("Cooldown Spells")
            for _, cd in ipairs(spec.majorCooldowns) do
                if not cd.isInterrupt and not cd.isUtility and isActive(cd) then
                    rowIdx = rowIdx + 1
                    SpellRow(cd.id, cd.label, cd.expectedUses or "", rowIdx)
                end
            end
        end
    end

    -- INTERRUPT / UTILITY (isInterrupt and isUtility entries)
    local hasInterrupts = false
    if spec.majorCooldowns then
        for _, cd in ipairs(spec.majorCooldowns) do
            if (cd.isInterrupt or cd.isUtility) and isActive(cd) then hasInterrupts = true; break end
        end
    end
    if hasInterrupts then
        SectionHeader("Interrupt & Utility")
        for _, cd in ipairs(spec.majorCooldowns) do
            if (cd.isInterrupt or cd.isUtility) and isActive(cd) then
                rowIdx = rowIdx + 1
                SpellRow(cd.id, cd.label, "situational", rowIdx)
            end
        end
    end

    -- ROTATIONAL SPELLS
    if spec.rotationalSpells and #spec.rotationalSpells > 0 then
        local hasRS = false
        for _, rs in ipairs(spec.rotationalSpells) do
            if isActive(rs) then hasRS = true; break end
        end
        if hasRS then
            SectionHeader("Rotational Spells")
            for _, rs in ipairs(spec.rotationalSpells) do
                if isActive(rs) then
                    rowIdx = rowIdx + 1
                    SpellRow(rs.id, rs.label, rs.combatGated and "Requires Metamorphosis" or nil, rowIdx)
                end
            end
        end
    end

    -- UPTIME BUFFS
    if spec.uptimeBuffs and #spec.uptimeBuffs > 0 then
        SectionHeader("Uptime Buffs")
        for _, ub in ipairs(spec.uptimeBuffs) do
            rowIdx = rowIdx + 1
            SpellRow(ub.id, ub.label, "target " .. (ub.targetUptime or "?") .. "% uptime", rowIdx)
        end
    end

    -- PROC BUFFS
    if spec.procBuffs and #spec.procBuffs > 0 then
        SectionHeader("Proc Buffs")
        for _, pb in ipairs(spec.procBuffs) do
            rowIdx = rowIdx + 1
            SpellRow(pb.id, pb.label, "spend quickly", rowIdx)
        end
    end

    yOff = yOff - 6
    sc:SetHeight(math.abs(yOff) + 10)
end

--------------------------------------------------------------------------------
local debugFrame = nil

function UI.ShowDebugWindow()
    if debugFrame then
        debugFrame:SetShown(not debugFrame:IsShown())
        return
    end

    local f = CreateFrame("Frame", "MidnightSenseiDebug", UIParent, "BackdropTemplate")
    f:SetSize(460, 580)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    ApplyBackdrop(f, {0.04,0.04,0.07,0.97}, C.BORDER_GOLD)
    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) f:StopMovingOrSizing() end)
    debugFrame = f

    -- Title
    local title = MakeFont(f, 13, "CENTER")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -12)
    title:SetPoint("TOPRIGHT", f, "TOPRIGHT", -26, -12)
    title:SetTextColor(C.TITLE[1], C.TITLE[2], C.TITLE[3], 1)
    title:SetText("Midnight Sensei - Debug Tools")

    -- Close button — use plain "X", not Unicode (FRIZQT__.TTF has no Unicode coverage)
    local x = CreateFrame("Button", nil, f)
    x:SetSize(20, 20)
    x:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    local xfs = MakeFont(x, 13, "CENTER")
    xfs:SetPoint("CENTER")
    xfs:SetText("|cffFF4444X|r")
    x:SetScript("OnClick", function() f:Hide() end)

    -- Separator
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(0.3, 0.3, 0.4, 0.5)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
    sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -30)

    -- Helper to run a slash command via the Core dispatch
    local function RunCmd(cmd)
        if MS.Core and MS.Core.SlashHandler then
            MS.Core.SlashHandler(cmd)
        else
            local handler = SlashCmdList["MIDNIGHTSENSEI"] or SlashCmdList["MS"]
            if handler then handler(cmd) end
        end
    end

    -- Shared vertical cursor — both helpers close over this
    local btnY = -40

    -- Section label helper
    local function AddSectionLabel(text, color)
        local sep2 = f:CreateTexture(nil, "ARTWORK")
        sep2:SetColorTexture(color[1], color[2], color[3], 0.3)
        sep2:SetHeight(1)
        sep2:SetPoint("TOPLEFT",  f, "TOPLEFT",  10, btnY - 4)
        sep2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, btnY - 4)

        local lbl = MakeFont(f, 9, "CENTER")
        lbl:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, btnY - 6)
        lbl:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, btnY - 6)
        lbl:SetTextColor(color[1], color[2], color[3], 0.9)
        lbl:SetText("-- " .. text .. " --")
        btnY = btnY - 20
    end

    -- Button builder
    local function AddDebugBtn(label, desc, cmd)
        local row = CreateFrame("Frame", nil, f, "BackdropTemplate")
        row:SetSize(428, 42)
        row:SetPoint("TOPLEFT", f, "TOPLEFT", 16, btnY)
        ApplyBackdrop(row, {0.07,0.07,0.12,0.6}, C.BORDER)

        local lbl = MakeFont(row, 11, "LEFT")
        lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -5)
        lbl:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
        lbl:SetText(label)

        local dsc = MakeFont(row, 9, "LEFT")
        dsc:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 5)
        dsc:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
        dsc:SetText(desc)

        local btn = MakeButton(row, 70, 28, "Run")
        btn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        btn:SetScript("OnClick", function()
            f:Hide()
            C_Timer.After(0.1, function() RunCmd(cmd) end)
        end)

        btnY = btnY - 48
    end

    -- ── Verify Tools ─────────────────────────────────────────────────────────
    AddSectionLabel("Verify Tools", {0.00, 1.00, 0.60})

    -- Verify mode toggle row (dynamic label shows current state)
    local vRow = CreateFrame("Frame", nil, f, "BackdropTemplate")
    vRow:SetSize(428, 42)
    vRow:SetPoint("TOPLEFT", f, "TOPLEFT", 16, btnY)
    ApplyBackdrop(vRow, {0.07,0.07,0.12,0.6}, C.BORDER)

    local vLbl = MakeFont(vRow, 11, "LEFT")
    vLbl:SetPoint("TOPLEFT", vRow, "TOPLEFT", 8, -5)
    vLbl:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
    vLbl:SetText("Verify Mode")

    local vDesc = MakeFont(vRow, 9, "LEFT")
    vDesc:SetPoint("BOTTOMLEFT", vRow, "BOTTOMLEFT", 8, 5)
    vDesc:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
    vDesc:SetText("Toggle spell ID capture for /ms verify report")

    local vState = MakeFont(vRow, 10, "CENTER")
    vState:SetPoint("RIGHT", vRow, "RIGHT", -82, 0)
    vState:SetText(MS.Core.VerifyMode and "|cff00FF00ON|r" or "|cffFF4444OFF|r")

    local vBtn = MakeButton(vRow, 70, 28, "Toggle")
    vBtn:SetPoint("RIGHT", vRow, "RIGHT", -6, 0)
    vBtn:SetScript("OnClick", function()
        RunCmd("verify")
        vState:SetText(MS.Core.VerifyMode and "|cff00FF00ON|r" or "|cffFF4444OFF|r")
    end)
    btnY = btnY - 48

    AddDebugBtn("Verify Report", "Export spell ID verification report to copyable window", "verify report")

    -- Auto-enable on login toggle row
    local aRow = CreateFrame("Frame", nil, f, "BackdropTemplate")
    aRow:SetSize(428, 42)
    aRow:SetPoint("TOPLEFT", f, "TOPLEFT", 16, btnY)
    ApplyBackdrop(aRow, {0.07,0.07,0.12,0.6}, C.BORDER)

    local aLbl = MakeFont(aRow, 11, "LEFT")
    aLbl:SetPoint("TOPLEFT", aRow, "TOPLEFT", 8, -5)
    aLbl:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
    aLbl:SetText("Auto-enable Verify on Login")

    local aDesc = MakeFont(aRow, 9, "LEFT")
    aDesc:SetPoint("BOTTOMLEFT", aRow, "BOTTOMLEFT", 8, 5)
    aDesc:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
    aDesc:SetText("Verify mode turns on automatically after every reload or login")

    local aState = MakeFont(aRow, 10, "CENTER")
    aState:SetPoint("RIGHT", aRow, "RIGHT", -82, 0)
    local autoOn = MS.Core.GetSetting and MS.Core.GetSetting("verifyAutoEnable")
    aState:SetText(autoOn and "|cff00FF00ON|r" or "|cffFF4444OFF|r")

    local aBtn = MakeButton(aRow, 70, 28, "Toggle")
    aBtn:SetPoint("RIGHT", aRow, "RIGHT", -6, 0)
    aBtn:SetScript("OnClick", function()
        local cur = MS.Core.GetSetting and MS.Core.GetSetting("verifyAutoEnable")
        if MS.Core.SetSetting then MS.Core.SetSetting("verifyAutoEnable", not cur) end
        aState:SetText((not cur) and "|cff00FF00ON|r" or "|cffFF4444OFF|r")
    end)
    btnY = btnY - 48

    -- ── General debug ────────────────────────────────────────────────────────
    AddDebugBtn("Version",          "Show addon version from TOC and metadata APIs",        "debug version")
    AddDebugBtn("Rotation Tracker", "Open the Rotation Tracker window — cast counts, status, and flag explanations for each spell", "debug rotational")

    -- ── Class Debugging ──────────────────────────────────────────────────────
    AddSectionLabel("Class Debugging", {0.00, 0.82, 1.00})

    AddDebugBtn("Talent Export",        "Export active talent snapshot for spec DB cross-reference",  "debug talents")
    AddDebugBtn("Spells Export",        "Export full spellbook snapshot for spec DB cross-reference", "debug spells")

    -- ── Recovery Tools ───────────────────────────────────────────────────────
    AddSectionLabel("Recovery Tools", {1.0, 0.5, 0.0})

    AddDebugBtn("Boss Board Ingest",  "Seed Boss Board from encounter history",                      "debug bossboard ingest")
    AddDebugBtn("Backfill M+ Keys",   "Patch Mythic dungeon history with season best key levels",    "debug backfill keys")
    AddDebugBtn("Clean Payload",      "Re-broadcast all your best scores with correct format",        "clean payload")

    -- Clear History — buried here intentionally, requires confirmation
    local clearRow = CreateFrame("Frame", nil, f, "BackdropTemplate")
    clearRow:SetSize(428, 42)
    clearRow:SetPoint("TOPLEFT", f, "TOPLEFT", 16, btnY)
    ApplyBackdrop(clearRow, {0.12,0.04,0.04,0.7}, {0.6,0.1,0.1,0.6})

    local clearLbl = MakeFont(clearRow, 11, "LEFT")
    clearLbl:SetPoint("TOPLEFT", clearRow, "TOPLEFT", 8, -5)
    clearLbl:SetTextColor(1, 0.35, 0.35, 1)
    clearLbl:SetText("Clear Fight History")

    local clearDesc = MakeFont(clearRow, 9, "LEFT")
    clearDesc:SetPoint("BOTTOMLEFT", clearRow, "BOTTOMLEFT", 8, 5)
    clearDesc:SetTextColor(0.7, 0.4, 0.4, 1)
    clearDesc:SetText("Permanently deletes all recorded encounters — this cannot be undone")

    local clearBtn = CreateFrame("Button", nil, clearRow, "BackdropTemplate")
    clearBtn:SetSize(70, 28)
    clearBtn:SetPoint("RIGHT", clearRow, "RIGHT", -6, 0)
    ApplyBackdrop(clearBtn, {0.20,0.04,0.04,0.9}, {0.6,0.1,0.1,0.8})
    local clearFs = MakeFont(clearBtn, 10, "CENTER")
    clearFs:SetPoint("CENTER")
    clearFs:SetText("|cffFF4444Run|r")
    clearBtn:SetScript("OnClick", function()
        -- Confirmation dialog
        local dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        dialog:SetSize(340, 130)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:SetMovable(false)
        ApplyBackdrop(dialog, {0.08,0.04,0.04,0.98}, {0.8,0.1,0.1,0.9})

        local msg = MakeFont(dialog, 11, "CENTER")
        msg:SetPoint("TOPLEFT",  dialog, "TOPLEFT",  10, -18)
        msg:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -10, -18)
        msg:SetWordWrap(true)
        msg:SetText("|cffFF4444This will permanently delete all fight history.|r\nThis action cannot be undone.")

        local confirmBtn = MakeButton(dialog, 120, 26, "Yes, Delete All")
        confirmBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 16, 12)
        confirmBtn:SetScript("OnClick", function()
            if MidnightSenseiCharDB then
                MidnightSenseiCharDB.encounters = {}
                if MS.Analytics then MS.Analytics.LastResult = nil end
                print("|cffFF4444Midnight Sensei:|r Fight history cleared.")
            end
            dialog:Hide()
            f:Hide()
            if historyFrame and historyFrame:IsShown() then
                RefreshHistoryContent()
            end
        end)

        local cancelBtn = MakeButton(dialog, 100, 26, "Cancel")
        cancelBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -16, 12)
        cancelBtn:SetScript("OnClick", function() dialog:Hide() end)

        dialog:Show()
    end)

    btnY = btnY - 48

    -- Resize frame to fit content
    f:SetHeight(math.abs(btnY) + 16)
    f:Show()
end
local creditsFrame = nil

function UI.ShowCredits()
    if not creditsFrame then
        creditsFrame = CreateFrame("Frame", "MidnightSenseiCredits", UIParent, "BackdropTemplate")
        creditsFrame:SetSize(440, 420)
        creditsFrame:SetPoint("CENTER")
        creditsFrame:SetFrameStrata("HIGH")
        creditsFrame:SetMovable(true)
        creditsFrame:SetClampedToScreen(true)
        creditsFrame:EnableMouse(true)
        creditsFrame:RegisterForDrag("LeftButton")
        creditsFrame:SetScript("OnDragStart", function(f) f:StartMoving() end)
        creditsFrame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
        ApplyBackdrop(creditsFrame, C.BG, C.BORDER_GOLD)
        MakeTitleBar(creditsFrame, "Midnight Sensei - Credits & About")

        -- Tab buttons: About | Sources | Changelog
        local tabs = { "About", "Sources", "Changelog" }
        local tabBtns = {}
        local tabPanels = {}

        local function ShowPanel(idx)
            for i, p in ipairs(tabPanels) do p:SetShown(i == idx) end
            for i, b in ipairs(tabBtns) do
                ApplyBackdrop(b, i == idx and {0.12,0.12,0.20,0.95} or C.BG_LIGHT, C.BORDER)
                b.label:SetTextColor(
                    i == idx and C.ACCENT[1] or C.TEXT_DIM[1],
                    i == idx and C.ACCENT[2] or C.TEXT_DIM[2],
                    i == idx and C.ACCENT[3] or C.TEXT_DIM[3], 1)
            end
        end

        for i, name in ipairs(tabs) do
            local btn = MakeButton(creditsFrame, 100, 22, name)
            btn:SetPoint("TOPLEFT", creditsFrame, "TOPLEFT", 10 + (i-1)*106, -34)
            local capturedIdx = i
            btn:SetScript("OnClick", function() ShowPanel(capturedIdx) end)
            table.insert(tabBtns, btn)
        end

        -- ── About panel ──────────────────────────────────────────────────
        local aboutPanel = CreateFrame("Frame", nil, creditsFrame)
        aboutPanel:SetPoint("TOPLEFT",     creditsFrame, "TOPLEFT",  10, -64)
        aboutPanel:SetPoint("BOTTOMRIGHT", creditsFrame, "BOTTOMRIGHT", -10, 36)
        table.insert(tabPanels, aboutPanel)

        local aboutText = MakeFont(aboutPanel, 10, "LEFT")
        aboutText:SetPoint("TOPLEFT",  aboutPanel, "TOPLEFT",  4, -4)
        aboutText:SetPoint("TOPRIGHT", aboutPanel, "TOPRIGHT", -4, -4)
        aboutText:SetWordWrap(true)
        aboutText:SetSpacing(4)
        aboutText:SetText(table.concat({
            "|cff00D1FFMidnight Sensei|r  |cff888888v" .. Core.VERSION .. "|r",
            " ",
            "|cffFFD700Author:|r  Midnight - Thrall (US)",
            " ",
            "A combat performance coaching addon for World of Warcraft: Midnight.",
            "Grades your fights A+ through F across all 13 classes and 39 specs,",
            "with actionable feedback tailored to your role and spec.",
            " ",
            "|cffFFD700Features:|r",
            "  - Per-fight grading: cooldown usage, activity, resource management",
            "  - Talent-aware: only scores abilities you actually have equipped",
            "  - Boss detection: tracks ENCOUNTER_START/END for real boss fights",
            "  - Social leaderboard: guild, party, and BNet friends rankings",
            "  - Weekly reset: aligned to Blizzard's Tuesday 7am PDT reset",
            "  - Delve tracking: tier-based scoring for solo content",
            "  - Score sync: syncs across guild members to recover scores after reinstall",
            " ",
            "|cffFFD700Contact:|r  MidnightTim on GitHub (MidnightTim/MidnightSensei)",
            " ",
            "|cff666666Midnight Sensei is a community addon, not affiliated with Blizzard.|r",
        }, "\n"))

        -- ── Sources panel ─────────────────────────────────────────────────
        local sourcesPanel = CreateFrame("Frame", nil, creditsFrame)
        sourcesPanel:SetPoint("TOPLEFT",     creditsFrame, "TOPLEFT",  10, -64)
        sourcesPanel:SetPoint("BOTTOMRIGHT", creditsFrame, "BOTTOMRIGHT", -10, 36)
        table.insert(tabPanels, sourcesPanel)

        local sf2 = CreateFrame("ScrollFrame", nil, sourcesPanel, "UIPanelScrollFrameTemplate")
        sf2:SetPoint("TOPLEFT",     sourcesPanel, "TOPLEFT",   0,   0)
        sf2:SetPoint("BOTTOMRIGHT", sourcesPanel, "BOTTOMRIGHT", -16, 0)
        local sc2 = CreateFrame("Frame", nil, sf2)
        sc2:SetWidth(sf2:GetWidth())
        sc2:SetHeight(10)
        sf2:SetScrollChild(sc2)

        local srcLines = {
            "Rotational guidance is informed by the following community resources.",
            "We gratefully acknowledge their contributions.",
            " ",
        }
        if Core.CREDITS then
            for _, credit in ipairs(Core.CREDITS) do
                table.insert(srcLines, "|cff00D1FF" .. credit.source .. "|r")
                table.insert(srcLines, "|cff888888" .. credit.url .. "|r")
                table.insert(srcLines, credit.desc)
                table.insert(srcLines, " ")
            end
        end
        table.insert(srcLines, "|cff666666Midnight Sensei is not affiliated with these resources.|r")

        local srcContent = MakeFont(sc2, 10, "LEFT")
        srcContent:SetPoint("TOPLEFT",  sc2, "TOPLEFT",  4, -4)
        srcContent:SetPoint("TOPRIGHT", sc2, "TOPRIGHT", -4, -4)
        srcContent:SetWordWrap(true)
        srcContent:SetSpacing(3)
        srcContent:SetText(table.concat(srcLines, "\n"))
        sourcesPanel._sc = sc2
        sourcesPanel._content = srcContent

        -- ── Changelog panel ───────────────────────────────────────────────────
        local changelogPanel = CreateFrame("Frame", nil, creditsFrame)
        changelogPanel:SetPoint("TOPLEFT",     creditsFrame, "TOPLEFT",  10, -64)
        changelogPanel:SetPoint("BOTTOMRIGHT", creditsFrame, "BOTTOMRIGHT", -10, 36)
        table.insert(tabPanels, changelogPanel)

        local sf3 = CreateFrame("ScrollFrame", nil, changelogPanel, "UIPanelScrollFrameTemplate")
        sf3:SetPoint("TOPLEFT",     changelogPanel, "TOPLEFT",   0,  0)
        sf3:SetPoint("BOTTOMRIGHT", changelogPanel, "BOTTOMRIGHT", -16, 0)
        local sc3 = CreateFrame("Frame", nil, sf3)
        sc3:SetWidth(sf3:GetWidth()) ; sc3:SetHeight(10)
        sf3:SetScrollChild(sc3)

        local clLines = {}
        if Core.CHANGELOG then
            for _, entry in ipairs(Core.CHANGELOG) do
                table.insert(clLines, "|cffFFD700v" .. entry.version ..
                    "|r  |cff888888" .. (entry.date or "") ..
                    " - " .. (entry.tagline or "") .. "|r")
                for _, change in ipairs(entry.changes or {}) do
                    table.insert(clLines, "  - " .. change)
                end
                table.insert(clLines, " ")
            end
        else
            table.insert(clLines, "No changelog available.")
        end

        local clContent = MakeFont(sc3, 10, "LEFT")
        clContent:SetPoint("TOPLEFT",  sc3, "TOPLEFT",  4, -4)
        clContent:SetPoint("TOPRIGHT", sc3, "TOPRIGHT", -4, -4)
        clContent:SetWordWrap(true)
        clContent:SetSpacing(3)
        clContent:SetText(table.concat(clLines, "\n"))
        changelogPanel._sc      = sc3
        changelogPanel._content = clContent

        ShowPanel(1)

        local closeBtn = MakeButton(creditsFrame, 60, 22, "Close")
        closeBtn:SetPoint("BOTTOM", creditsFrame, "BOTTOM", 0, 8)
        closeBtn:SetScript("OnClick", function() creditsFrame:Hide() end)

        creditsFrame._tabPanels = tabPanels
        creditsFrame._tabBtns   = tabBtns
    end

    creditsFrame:Show()
    -- Resize scroll children for Sources and Changelog panels
    C_Timer.After(0.05, function()
        for idx = 2, 3 do
            if creditsFrame._tabPanels and creditsFrame._tabPanels[idx] then
                local p = creditsFrame._tabPanels[idx]
                if p._sc and p._content then
                    p._sc:SetHeight(p._content:GetStringHeight() + 20)
                end
            end
        end
    end)
end

-- Opens the Credits panel directly on the Changelog tab (tab 3)
function UI.ShowChangelog()
    UI.ShowCredits()
    C_Timer.After(0.05, function()
        if creditsFrame and creditsFrame._tabPanels then
            -- Simulate clicking the Changelog tab (index 3)
            for i, p in ipairs(creditsFrame._tabPanels) do p:SetShown(i == 3) end
            if creditsFrame._tabBtns then
                for i, b in ipairs(creditsFrame._tabBtns) do
                    ApplyBackdrop(b, i == 3 and {0.12,0.12,0.20,0.95} or C.BG_LIGHT, C.BORDER)
                    b.label:SetTextColor(
                        i == 3 and C.ACCENT[1] or C.TEXT_DIM[1],
                        i == 3 and C.ACCENT[2] or C.TEXT_DIM[2],
                        i == 3 and C.ACCENT[3] or C.TEXT_DIM[3], 1)
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- FAQ / Help panel
--------------------------------------------------------------------------------
local faqFrame = nil

function UI.ShowFAQ()
    local lines = {
        "|cff00D1FFMidnight Sensei - Help & FAQ|r",
        " ",
        "|cffFFD700GETTING STARTED|r",
        "Type |cffFFFFFF/ms show|r to open the HUD, |cffFFFFFF/ms hide|r to close it.",
        "The HUD shows your last grade, score, and spec. After a fight you",
        "will see a |cffFFFFFF>> Review Fight|r button. Right-click the HUD for quick",
        "access to all features.",
        " ",
        "|cffFFD700UNDERSTANDING YOUR GRADE|r",
        "Grades run from F through A+. Each spec has weighted categories:",
        "  - Cooldown Usage: did you press your major cooldowns on cooldown?",
        "  - Rotational Spells: did you use key rotation abilities each fight?",
        "  - Activity: were you casting consistently? (no long idle gaps)",
        "  - Resource Mgmt: did you overcap your resource (Rage/Energy/etc)?",
        "  - Buff Uptime: did you keep your self-buffs active? (specs vary)",
        "  - Proc Usage: did you consume procs quickly? (Frost DK, Fire Mage...)",
        "  - Healer Efficiency: how much of your healing was overheal?",
        " ",
        "A fight shorter than 15 seconds is not recorded.",
        " ",
        "|cffFFD700ROTATIONAL SPELL FEEDBACK|r",
        "In addition to cooldowns, Midnight Sensei tracks whether you used",
        "key rotational spells each fight (e.g. Implosion, Rake, Obliterate).",
        "If you never used one in a long enough fight, it will appear in your",
        "feedback. Talent-gated spells are skipped if you don't have the talent.",
        " ",
        "|cffFFD700VISIBILITY OPTIONS|r",
        "Open |cffFFFFFF/ms options|r (or right-click HUD -> Options) and set:",
        "  Always: HUD always visible",
        "  In Combat: HUD only shows while in combat",
        "  Hide: HUD hidden (accessible via /ms show)",
        " ",
        "|cffFFD700GRADE HISTORY|r",
        "Type |cffFFFFFF/ms history|r or right-click -> Grade History.",
        "  - Filter by This Character or All Characters",
        "  - Sparkline shows your last 20 fights at a glance",
        "  - Left-click any row to inspect full details and feedback",
        "  - Right-click any row to delete that entry",
        " ",
        "|cffFFD700LEADERBOARD|r",
        "Type |cffFFFFFF/ms lb|r to open the social leaderboard.",
        "After each boss fight your score broadcasts to guild, party, and",
        "BNet friends who also have Midnight Sensei installed.",
        "Tabs: Party (session only), Guild (persists across sessions), Friends.",
        "Guild scores persist between sessions and sync across guild members —",
        "even if a player is offline you can still see their last recorded score.",
        "Weekly average counts boss encounters only — trash pulls and target",
        "dummies are never included in rankings.",
        "Right-click any guild row to remove a player. They repopulate",
        "automatically when they next log in or you hit Refresh.",
        " ",
        "Each tab (Dungeons, Raids) shows location info from that content type",
        "only — an LFR run will never bleed into the Dungeons tab.",
        "Mythic+ key level is shown where available (e.g. M+15).",
        "After updating the addon, each player needs to complete one new",
        "dungeon or raid for their tab location to reflect the correct content.",
        "Your own entry updates immediately from local history — no new run needed.",
        " ",
        "|cffFFD700NOTE ON MIDNIGHT 12.0 RESTRICTIONS|r",
        "Blizzard restricted enemy unit aura reads in Midnight 12.0.",
        "Target debuffs (Rupture, Flame Shock, etc.) cannot be tracked directly.",
        "These show in your priorityNotes as guidance but are not scored.",
        "All player self-buffs, cooldowns, and rotational casts work normally.",
        " ",
        "|cffFFD700BOSS VS NORMAL COMBAT|r",
        "Midnight Sensei detects boss encounters via ENCOUNTER_START/END.",
        "Boss fights show a |cffFF6600[Boss]|r tag in history and encounter detail.",
        "Filter your history to |cffFFFFFF[Boss] Only|r to review raid/dungeon boss pulls.",
        " ",
        "|cffFFD700TALENT-AWARE COOLDOWNS|r",
        "Cooldown scoring only includes spells you have learned.",
        "If you don't have a talent, it won't be scored against you.",
        " ",
        "|cffFFD700ALL COMMANDS|r",
        "  /ms show         Show the HUD",
        "  /ms hide         Hide the HUD",
        "  /ms history      Grade history & trending",
        "  /ms lb           Social leaderboard",
        "  /ms lb remove    Remove a player from guild leaderboard",
        "  /ms options      Settings",
        "  /ms faq          This panel",
        "  /ms update       View changelog",
        "  /ms credits      Credits & about",
        "  /ms report       Report a bug on GitHub",
        "  /ms versions     Show addon versions seen this session",
        "  /ms friend <n>   Query a player's last score directly",
        "  /ms tracker      Open the Rotation Tracker (cast counts + spell explanations)",
    }

    if not faqFrame then
        faqFrame = CreateFrame("Frame", "MidnightSenseiFAQ", UIParent, "BackdropTemplate")
        faqFrame:SetSize(460, 460)
        faqFrame:SetPoint("CENTER")
        faqFrame:SetFrameStrata("HIGH")
        faqFrame:SetMovable(true)
        faqFrame:SetClampedToScreen(true)
        faqFrame:EnableMouse(true)
        faqFrame:RegisterForDrag("LeftButton")
        faqFrame:SetScript("OnDragStart", function(f) f:StartMoving() end)
        faqFrame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
        ApplyBackdrop(faqFrame, C.BG, C.BORDER_GOLD)
        MakeTitleBar(faqFrame, "Midnight Sensei - Help & FAQ")

        local sf = CreateFrame("ScrollFrame", "MidnightSenseiFAQScroll",
                               faqFrame, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     faqFrame, "TOPLEFT",  10, -34)
        sf:SetPoint("BOTTOMRIGHT", faqFrame, "BOTTOMRIGHT", -26, 36)
        local sc = CreateFrame("Frame", nil, sf)
        sc:SetWidth(sf:GetWidth()) ; sc:SetHeight(10)
        sf:SetScrollChild(sc)

        faqFrame.contentText = MakeFont(sc, 10, "LEFT")
        faqFrame.contentText:SetPoint("TOPLEFT",  sc, "TOPLEFT",  4, -4)
        faqFrame.contentText:SetPoint("TOPRIGHT", sc, "TOPRIGHT", -4, -4)
        faqFrame.contentText:SetWordWrap(true)
        faqFrame.contentText:SetSpacing(2)
        faqFrame._sc = sc

        local closeBtn = MakeButton(faqFrame, 60, 22, "Close")
        closeBtn:SetPoint("BOTTOM", faqFrame, "BOTTOM", 0, 8)
        closeBtn:SetScript("OnClick", function() faqFrame:Hide() end)
    end

    faqFrame.contentText:SetText(table.concat(lines, "\n"))
    faqFrame:Show()
    C_Timer.After(0.05, function()
        if faqFrame._sc and faqFrame.contentText then
            faqFrame._sc:SetHeight(faqFrame.contentText:GetStringHeight() + 20)
        end
    end)
end

--------------------------------------------------------------------------------
-- Rotation Tracker window
-- Opens via /ms tracker or from the Debug Tools panel.
-- Shows the live rotationalTracking table from the last fight with cast counts,
-- status badges, and a plain-English explanation for every flag on each spell.
--------------------------------------------------------------------------------
local rotTrackerFrame = nil

function UI.ShowRotationalTracker()
    if rotTrackerFrame then
        rotTrackerFrame:SetShown(not rotTrackerFrame:IsShown())
        if rotTrackerFrame:IsShown() then UI.RefreshRotationalTracker() end
        return
    end

    rotTrackerFrame = CreateFrame("Frame", "MidnightSenseiRotTracker", UIParent, "BackdropTemplate")
    rotTrackerFrame:SetSize(510, 460)
    rotTrackerFrame:SetPoint("CENTER")
    rotTrackerFrame:SetFrameStrata("DIALOG")
    rotTrackerFrame:SetMovable(true)
    rotTrackerFrame:SetClampedToScreen(true)
    rotTrackerFrame:EnableMouse(true)
    rotTrackerFrame:RegisterForDrag("LeftButton")
    rotTrackerFrame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    rotTrackerFrame:SetScript("OnDragStop",  function(f) f:StopMovingOrSizing() end)
    ApplyBackdrop(rotTrackerFrame, C.BG, C.BORDER_GOLD)
    MakeTitleBar(rotTrackerFrame, "Midnight Sensei - Rotation Tracker")

    -- Subtitle
    local sub = MakeFont(rotTrackerFrame, 10, "LEFT")
    sub:SetPoint("TOPLEFT",  rotTrackerFrame, "TOPLEFT",  10, -34)
    sub:SetPoint("TOPRIGHT", rotTrackerFrame, "TOPRIGHT", -10, -34)
    sub:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
    sub:SetText("Cast counts from your last fight. Each spell shows how many times it was used and why it is tracked.")

    -- Fight duration (top-right)
    local fightInfo = MakeFont(rotTrackerFrame, 10, "RIGHT")
    fightInfo:SetPoint("TOPRIGHT", rotTrackerFrame, "TOPRIGHT", -28, -50)
    fightInfo:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
    rotTrackerFrame.fightInfo = fightInfo

    -- Column headers bar
    local hdrBg = rotTrackerFrame:CreateTexture(nil, "BACKGROUND")
    hdrBg:SetPoint("TOPLEFT",  rotTrackerFrame, "TOPLEFT",  10, -62)
    hdrBg:SetPoint("TOPRIGHT", rotTrackerFrame, "TOPRIGHT", -26, -62)
    hdrBg:SetHeight(18)
    hdrBg:SetColorTexture(C.TITLE_BG[1], C.TITLE_BG[2], C.TITLE_BG[3], 0.9)

    local function ColHdr(label, xOff, w, align)
        local fs = MakeFont(rotTrackerFrame, 9, align or "LEFT")
        fs:SetPoint("TOPLEFT", rotTrackerFrame, "TOPLEFT", xOff, -64)
        fs:SetWidth(w)
        fs:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
        fs:SetText(label)
    end
    ColHdr("SPELL",   36,  220)
    ColHdr("CASTS",  318,   50, "CENTER")
    ColHdr("MIN FIGHT", 378, 60, "CENTER")
    ColHdr("STATUS", 444,   50, "CENTER")

    -- Scroll frame
    local sf = CreateFrame("ScrollFrame", nil, rotTrackerFrame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     rotTrackerFrame, "TOPLEFT",   10, -82)
    sf:SetPoint("BOTTOMRIGHT", rotTrackerFrame, "BOTTOMRIGHT", -26, 36)
    local sc = CreateFrame("Frame", nil, sf)
    sc:SetWidth(sf:GetWidth())
    sc:SetHeight(10)
    sf:SetScrollChild(sc)
    rotTrackerFrame._sc = sc

    local closeBtn = MakeButton(rotTrackerFrame, 60, 22, "Close")
    closeBtn:SetPoint("BOTTOM", rotTrackerFrame, "BOTTOM", 0, 8)
    closeBtn:SetScript("OnClick", function() rotTrackerFrame:Hide() end)

    UI.RefreshRotationalTracker()
end

function UI.RefreshRotationalTracker()
    if not rotTrackerFrame or not rotTrackerFrame:IsShown() then return end

    local sc = rotTrackerFrame._sc
    for _, child in ipairs({sc:GetChildren()}) do child:Hide(); child:SetParent(nil) end
    for _, child in ipairs({sc:GetRegions()}) do child:Hide() end

    local rt   = MS.Analytics and MS.Analytics.GetRotationalTracking and MS.Analytics.GetRotationalTracking()
    local last = MS.Analytics and MS.Analytics.GetLastEncounter    and MS.Analytics.GetLastEncounter()
    local dur  = last and last.duration or 0
    local spec = Core.ActiveSpec

    -- Update fight duration label
    if dur > 0 then
        rotTrackerFrame.fightInfo:SetText("Last fight: " .. FormatDuration(dur))
    else
        rotTrackerFrame.fightInfo:SetText("No fight recorded yet")
    end

    -- Build a lookup: spell ID → spec definition entry (for flags)
    local specDef = {}
    if spec and spec.rotationalSpells then
        for _, rs in ipairs(spec.rotationalSpells) do
            specDef[rs.id] = rs
        end
    end

    local W      = sc:GetWidth() or 458
    local ROW_H  = 44
    local ICON_SZ = 20
    local yOff   = -4
    local rowIdx = 0

    -- Empty state
    if not rt or not next(rt) then
        local lbl = MakeFont(sc, 11, "CENTER")
        lbl:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, -20)
        lbl:SetPoint("TOPRIGHT", sc, "TOPRIGHT", 0, -20)
        lbl:SetText("|cff888888No fight data yet — run a fight to see tracking results.|r")
        sc:SetHeight(60)
        return
    end

    -- Sort alphabetically by label for consistent order
    local sorted = {}
    for id, entry in pairs(rt) do
        table.insert(sorted, { id = id, entry = entry })
    end
    table.sort(sorted, function(a, b)
        return (a.entry.label or "") < (b.entry.label or "")
    end)

    for _, item in ipairs(sorted) do
        local id  = item.id
        local rs  = item.entry
        local def = specDef[id] or {}

        rowIdx = rowIdx + 1
        local rc = (rowIdx % 2 == 0) and C.ROW_EVEN or C.ROW_ODD

        -- Row background
        local bg = sc:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, yOff)
        bg:SetPoint("TOPRIGHT", sc, "TOPRIGHT", 0, yOff)
        bg:SetHeight(ROW_H)
        bg:SetColorTexture(rc[1], rc[2], rc[3], rc[4])

        -- Spell icon
        local tex = sc:CreateTexture(nil, "ARTWORK")
        tex:SetSize(ICON_SZ, ICON_SZ)
        tex:SetPoint("TOPLEFT", sc, "TOPLEFT", 4, yOff - 12)
        local iconPath = GetSpellTexture and GetSpellTexture(id)
        if iconPath then
            tex:SetTexture(iconPath)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        -- Spell name (line 1)
        local nameStr = MakeFont(sc, 11, "LEFT")
        nameStr:SetPoint("TOPLEFT", sc, "TOPLEFT", 30, yOff - 5)
        nameStr:SetWidth(W - 175)
        nameStr:SetText(rs.label or "Unknown")

        -- Description (line 2) — plain-English explanation of flags
        local parts = {}
        if def.combatGated and def.talentGated then
            table.insert(parts, "Requires talent; only castable during a transformation window")
        elseif def.combatGated then
            table.insert(parts, "Only castable during a transformation window (e.g. Void Metamorphosis)")
        elseif def.talentGated then
            table.insert(parts, "Only tracked when this talent is active in your build")
        else
            table.insert(parts, "Core rotational ability — expected every fight")
        end
        if rs.minFightSeconds and rs.minFightSeconds > 15 then
            table.insert(parts, "flagged missed only if fight > " .. rs.minFightSeconds .. "s")
        end

        local descStr = MakeFont(sc, 9, "LEFT")
        descStr:SetPoint("TOPLEFT", sc, "TOPLEFT", 30, yOff - 22)
        descStr:SetWidth(W - 175)
        descStr:SetText("|cff777777" .. table.concat(parts, " — ") .. "|r")

        -- Cast count column
        local castStr = MakeFont(sc, 11, "CENTER")
        castStr:SetPoint("TOPLEFT", sc, "TOPLEFT", W - 148, yOff - 5)
        castStr:SetWidth(50)
        if dur > 0 then
            castStr:SetText(rs.useCount > 0 and ("|cff22EE22" .. rs.useCount .. "|r") or "|cff888888 0|r")
        else
            castStr:SetText("|cff888888—|r")
        end

        -- Min fight column
        local minStr = MakeFont(sc, 10, "CENTER")
        minStr:SetPoint("TOPLEFT", sc, "TOPLEFT", W - 98, yOff - 5)
        minStr:SetWidth(50)
        local minSec = rs.minFightSeconds or 15
        minStr:SetText("|cff666666" .. minSec .. "s|r")

        -- Status badge column
        local statusStr = MakeFont(sc, 10, "CENTER")
        statusStr:SetPoint("TOPLEFT", sc, "TOPLEFT", W - 50, yOff - 5)
        statusStr:SetWidth(46)
        if dur == 0 then
            statusStr:SetText("|cff666666—|r")
        elseif rs.useCount > 0 then
            statusStr:SetText("|cff22EE22CAST|r")
        elseif dur >= minSec then
            statusStr:SetText("|cffFF4444MISSED|r")
        else
            statusStr:SetText("|cff888888SHORT|r")
        end

        yOff = yOff - ROW_H
    end

    -- Footer: count of spec spells excluded from this build
    if spec and spec.rotationalSpells then
        local excluded = {}
        for _, rs in ipairs(spec.rotationalSpells) do
            if not rt[rs.id] then table.insert(excluded, rs.label) end
        end
        if #excluded > 0 then
            yOff = yOff - 6
            local sepLine = sc:CreateTexture(nil, "ARTWORK")
            sepLine:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, yOff)
            sepLine:SetPoint("TOPRIGHT", sc, "TOPRIGHT", 0, yOff)
            sepLine:SetHeight(1)
            sepLine:SetColorTexture(C.SEP[1], C.SEP[2], C.SEP[3], C.SEP[4])
            yOff = yOff - 4

            local noteLbl = MakeFont(sc, 9, "LEFT")
            noteLbl:SetPoint("TOPLEFT", sc, "TOPLEFT", 6, yOff)
            noteLbl:SetWidth(W - 10)
            noteLbl:SetWordWrap(true)
            noteLbl:SetText("|cff666666Not tracked this build (talent not taken or replaced): " ..
                table.concat(excluded, ", ") .. "|r")
            yOff = yOff - 26
        end
    end

    -- Legend
    yOff = yOff - 6
    local legendSep = sc:CreateTexture(nil, "ARTWORK")
    legendSep:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, yOff)
    legendSep:SetPoint("TOPRIGHT", sc, "TOPRIGHT", 0, yOff)
    legendSep:SetHeight(1)
    legendSep:SetColorTexture(C.SEP[1], C.SEP[2], C.SEP[3], C.SEP[4])
    yOff = yOff - 4

    local legendStr = MakeFont(sc, 9, "LEFT")
    legendStr:SetPoint("TOPLEFT", sc, "TOPLEFT", 6, yOff)
    legendStr:SetWidth(W - 10)
    legendStr:SetText("|cff22EE22CAST|r  used at least once  " ..
        "|cffFF4444MISSED|r  fight was long enough but spell was not used  " ..
        "|cff888888SHORT|r  fight too short to evaluate")
    yOff = yOff - 18

    sc:SetHeight(math.abs(yOff) + 10)
end

--------------------------------------------------------------------------------
-- Update toast
--------------------------------------------------------------------------------
function UI.ShowUpdateToast(sender, version)
    local toast = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    toast:SetSize(300, 40)
    toast:SetPoint("TOP", UIParent, "TOP", 0, -120)
    toast:SetFrameStrata("HIGH")
    ApplyBackdrop(toast, C.TITLE_BG, C.BORDER_GOLD)
    local msg = MakeFont(toast, 10, "CENTER")
    msg:SetPoint("CENTER")
    msg:SetText("|cff00D1FFMidnight Sensei:|r " .. sender ..
                " has v" .. version .. " -> /ms update")
    C_Timer.After(8.0, function() toast:Hide() end)
end

--------------------------------------------------------------------------------
-- Public event hooks
--------------------------------------------------------------------------------
function UI.OnCombatStart()
    local f = CreateMainFrame()
    f.specText:SetText(Core.GetSpecInfoString())
    f.gradeText:SetText("...")
    f.gradeText:SetTextColor(0.55, 0.55, 0.55, 1)
    f.scoreText:SetText("")
    f.labelText:SetText("In combat...")
    f.labelText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
    f.reviewBtn:Hide()
    ApplyHudVisibility("combat_start")
end

function UI.OnCombatEnd(result)
    local f = CreateMainFrame()
    -- Populate before visibility check so text is always current
    if result then
        local gc = result.gradeColor
        -- gradeColor can be a table {r,g,b} or may have been lost on reload
        -- Fall back to grade-based colour if needed
        if type(gc) ~= "table" then
            gc = { Core.GetGrade(result.finalScore) }
            -- Core.GetGrade returns letter,color,label — we want color (index 2)
            local _, col = Core.GetGrade(result.finalScore)
            gc = col or {0.6, 0.6, 0.6}
        end
        f.gradeText:SetText(result.finalGrade or "?")
        f.gradeText:SetTextColor(gc[1] or 0.6, gc[2] or 0.6, gc[3] or 0.6, 1)
        f.scoreText:SetText(tostring(result.finalScore or 0))
        f.scoreText:SetTextColor(gc[1] or 0.6, gc[2] or 0.6, gc[3] or 0.6, 1)
        local bossTag = (result.isBoss and result.bossName)
            and ("|cffFF6600[Boss] " .. result.bossName .. "|r  ")
            or ""
        f.labelText:SetText(bossTag .. (result.gradeLabel or ""))
        f.labelText:SetTextColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
        f.specText:SetText(Core.GetSpecInfoString())
        f.reviewBtn:Show()
    else
        f.gradeText:SetText("")
        f.scoreText:SetText("")
        f.labelText:SetText("Fight too short to record")
        f.labelText:SetTextColor(C.TEXT_DIM[1], C.TEXT_DIM[2], C.TEXT_DIM[3], 1)
        f.reviewBtn:Hide()
    end
    ApplyHudVisibility("combat_end")
    UI.RefreshHistory()
end

function UI.UpdateVerifyBar()
    if not mainFrame then return end
    local on = MS.Core and MS.Core.VerifyMode or false
    if mainFrame.verifyBar then
        mainFrame.verifyBar:SetShown(on)
    end
end

function UI.ToggleMainFrame()
    local f = CreateMainFrame()
    if f:IsShown() then
        f:Hide()
    else
        local lastEnc = MS.Analytics and MS.Analytics.GetLastEncounter and MS.Analytics.GetLastEncounter()
        PopulateHudFromResult(lastEnc)
        f.specText:SetText(Core.GetSpecInfoString())
        ApplyHudVisibility("show")
        f:Show()
    end
end

function UI.ShowMainFrame()
    local f = CreateMainFrame()
    local lastEnc = MS.Analytics and MS.Analytics.GetLastEncounter and MS.Analytics.GetLastEncounter()
    PopulateHudFromResult(lastEnc)
    f.specText:SetText(Core.GetSpecInfoString())
    ApplyHudVisibility("show")
    f:Show()
end

function UI.HideMainFrame()
    local f = CreateMainFrame()
    f:Hide()
end

-- Spec change: update HUD spec text
MS.Core.On(MS.Core.EVENTS.SPEC_CHANGED, function(spec)
    if mainFrame and mainFrame.specText then
        mainFrame.specText:SetText(MS.Core.GetSpecInfoString())
    end
end)

-- On session ready: populate HUD from last saved encounter (current session or DB)
MS.Core.On(MS.Core.EVENTS.SESSION_READY, function()
    local f = CreateMainFrame()
    local lastEnc = nil
    if MS.Analytics and MS.Analytics.GetLastEncounter then
        lastEnc = MS.Analytics.GetLastEncounter()
    end
    PopulateHudFromResult(lastEnc)
    f.specText:SetText(Core.GetSpecInfoString())
    if HudVisibility() == "always" then f:Show() end

    -- Register with WoW's built-in Options / Settings panel.
    -- The Midnight 12.0 API is Settings.RegisterVerticalLayoutCategory.
    -- We wrap in pcall so that if the API changes or is unavailable, nothing breaks.
    C_Timer.After(0.5, function()
        local ok = pcall(function()
            if not (Settings and Settings.RegisterVerticalLayoutCategory) then return end

            local category = Settings.RegisterVerticalLayoutCategory("Midnight Sensei")
            if not category then return end

            -- Each "initializer" adds a row to the Settings panel for this addon
            local layout = category:GetLayout()
            if layout and layout.AddInitializer then
                layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(
                    "Midnight Sensei v" .. Core.VERSION ..
                    "  |cff888888Created by Midnight - Thrall (US)|r"))
                layout:AddInitializer(CreateSettingsButtonInitializer(
                    "Open Options", "Configure HUD, play style, and more",
                    function() UI.OpenOptions() end))
                layout:AddInitializer(CreateSettingsButtonInitializer(
                    "Grade History", "View fight history and trends",
                    function() UI.ShowHistory() end))
                layout:AddInitializer(CreateSettingsButtonInitializer(
                    "Leaderboard", "Guild / Party / Friends / Delve rankings",
                    function()
                        if MS.Leaderboard and MS.Leaderboard.Toggle then
                            MS.Leaderboard.Toggle()
                        end
                    end))
                layout:AddInitializer(CreateSettingsButtonInitializer(
                    "Help & FAQ", "How scoring and grading works",
                    function() UI.ShowFAQ() end))
                layout:AddInitializer(CreateSettingsButtonInitializer(
                    "Credits & About", "Author info and sources",
                    function() UI.ShowCredits() end))
            end

            Settings.RegisterAddOnCategory(category)
        end)

        -- Fallback: if the new Settings API isn't available (very old client),
        -- try the legacy InterfaceOptions approach
        if not ok then
            pcall(function()
                if InterfaceOptions_AddCategory then
                    local panel = CreateFrame("Frame")
                    panel.name = "Midnight Sensei"
                    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
                    title:SetText("Midnight Sensei v" .. Core.VERSION)
                    local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
                    sub:SetTextColor(0.7, 0.7, 0.7, 1)
                    sub:SetText("Created by Midnight - Thrall (US)  |  /ms for commands")
                    InterfaceOptions_AddCategory(panel)
                end
            end)
        end
    end)
end)

--------------------------------------------------------------------------------
-- Minimap Button (LibDBIcon)
-- Requires: LibStub, LibDataBroker-1.1, LibDBIcon-1.0 (bundled in libs\)
-- Collapses/hides correctly with Minimap Map Icons and all other LDB managers.
--------------------------------------------------------------------------------
local function CreateMinimapButton()
    local LibStub    = LibStub
    local LDB        = LibStub and LibStub("LibDataBroker-1.1", true)
    local LibDBIcon  = LibStub and LibStub("LibDBIcon-1.0",     true)

    if not LDB or not LibDBIcon then
        -- Libs not loaded yet — shouldn't happen given TOC order, but guard anyway
        if Core.GetSetting("debugMode") then
            print("|cff888888MS:|r LibDBIcon not available — minimap button skipped.")
        end
        return
    end

    -- Ensure minimap saved settings exist
    if MidnightSenseiDB then
        MidnightSenseiDB.minimapIcon = MidnightSenseiDB.minimapIcon or { hide = false }
    end

    -- DataBroker object — this is what LDB managers (ElvUI, TitanPanel, etc.) display
    local broker = LDB:NewDataObject("MidnightSensei", {
        type  = "launcher",
        label = "Midnight Sensei",
        icon  = "Interface\\AddOns\\MidnightSensei\\logo",
        OnClick = function(self, btn)
            if btn == "RightButton" and IsShiftKeyDown() then
                -- Shift+Right-click: open the HUD right-click context menu
                UI.ShowMainCtxMenu()
            elseif btn == "RightButton" and IsControlKeyDown() then
                -- Ctrl+Right-click: Boss Board
                if MS.BossBoard and MS.BossBoard.Toggle then
                    MS.BossBoard.Toggle()
                end
            elseif btn == "RightButton" then
                if MS.Leaderboard and MS.Leaderboard.Toggle then
                    MS.Leaderboard.Toggle()
                end
            else
                UI.ToggleMainFrame()
            end
        end,
        OnTooltipShow = function(tip)
            tip:SetText("Midnight Sensei", 1, 0.82, 0)
            tip:AddLine("Left-click: Toggle HUD", 0.8, 0.8, 0.8)
            tip:AddLine("Right-click: Leaderboard", 0.8, 0.8, 0.8)
            tip:AddLine("Ctrl+Right-click: Boss Board", 0.8, 0.8, 0.8)
            tip:AddLine("Shift+Right-click: Options", 0.8, 0.8, 0.8)
        end,
    })

    -- Register with LibDBIcon — this handles all positioning, dragging,
    -- and hide/show compatibility with minimap button manager addons
    LibDBIcon:Register("MidnightSensei", broker,
        MidnightSenseiDB and MidnightSenseiDB.minimapIcon)
end

-- Use PLAYER_ENTERING_WORLD — fires after SavedVariables are loaded and
-- all frames including Minimap are ready
local minimapEventFrame = CreateFrame("Frame")
minimapEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
minimapEventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        C_Timer.After(0.5, CreateMinimapButton)
    end
end)
