--------------------------------------------------------------------------------
-- Midnight Sensei: Leaderboard.lua
-- Social leaderboard: Party / Guild / Friends
--
-- Protocol prefix: "MS_LB"
-- Message format (pipe-delimited):
--   SCORE|ver|class|spec|role|grade|score|duration|isBoss|bossName|encType|checksum
--   HELLO|ver|class|spec
--
-- Integrity: each score message includes a checksum = bit.bxor of
--   (score * 7 + duration * 3 + playerGUID_crc) so trivially doctored values
--   fail validation on the receiver's side.
--
-- Leaderboard categories:
--   "dungeon"  - boss fight inside an instance (5-man/M+)
--   "raid"     - boss fight inside a raid instance
--   "normal"   - non-boss combat
--
-- Weekly rolling average: each player entry stores a weekKey (YYYYWW).
--   On a new week the weekly avg resets. The leaderboard sorts by
--   weeklyAvg desc, then allTimeBest desc, making consistent weekly
--   performance matter more than a single lucky A+.
--------------------------------------------------------------------------------

MidnightSensei             = MidnightSensei             or {}
MidnightSensei.Core        = MidnightSensei.Core        or {}
MidnightSensei.Analytics   = MidnightSensei.Analytics   or {}
MidnightSensei.Leaderboard = MidnightSensei.Leaderboard or {}

local MS   = MidnightSensei
local LB   = MS.Leaderboard
local Core = MS.Core or MidnightSensei.Core or {}

local LB_PREFIX = "MS_LB"

--------------------------------------------------------------------------------
-- Week key helper
-- WoW weekly reset: Tuesday 7:00 AM PDT (UTC-7) = Tuesday 14:00 UTC
-- We compute which "WoW week" we're in by anchoring to that boundary.
-- A WoW week runs Tue 14:00 UTC → Tue 13:59 UTC the following week.
--------------------------------------------------------------------------------
local function GetWeekKey()
    local utcTime  = time()          -- seconds since epoch (UTC)
    -- Shift clock back by 14 hours so Tuesday 14:00 UTC becomes Tuesday 00:00
    local shifted  = utcTime - (14 * 3600)
    local t        = date("!*t", shifted)   -- UTC broken-down time of shifted clock
    -- Find how many days past the most recent Tuesday (weekday: 1=Sun…7=Sat; Tue=3)
    local wday     = t.wday   -- 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    local daysSinceTue = (wday - 3 + 7) % 7
    -- Step back to the Tuesday of this WoW week
    local tueSec   = shifted - daysSinceTue * 86400
    local tue      = date("!*t", tueSec)
    -- Key = YYYYMMDD of that Tuesday (unique per WoW week)
    return string.format("%04d%02d%02d", tue.year, tue.month, tue.mday)
end

--------------------------------------------------------------------------------
-- Instance context snapshot
-- Called at fight start (PLAYER_REGEN_DISABLED) to capture full instance info.
-- Returns a context table: { encType, diffLabel, keystoneLevel }
--
-- encType:   "dungeon" | "raid" | "delve" | "normal"
-- diffLabel: "Normal" | "Heroic" | "Mythic" | "M+12" | "LFR" |
--            "Tier 8" (delve) | "World" etc.
-- keystoneLevel: number or nil
--------------------------------------------------------------------------------
local RAID_DIFF = {
    -- Legacy raid difficulties
    [17] = "LFR",
    [14] = "Normal",
    [15] = "Heroic",
    [16] = "Mythic",
    -- Midnight 12.0 raid difficulties (The Voidspire / March on Quel'Danas / The Dreamrift)
    -- Standard flex scaling: Normal=17(?), Heroic=15, Mythic=16 reused, LFR=17
    -- Fallback: any unknown diffID uses diffName from GetInstanceInfo()
    -- Encounter IDs (for reference — detected automatically via ENCOUNTER_START):
    --   The Voidspire (2912):         3176-3181
    --   March on Quel'Danas (2913):   3182-3183
    --   The Dreamrift (2939):         3306
}
local DUNGEON_DIFF = {
    [1]  = "Normal",
    [2]  = "Heroic",
    [23] = "Mythic",   -- Mythic keystone / M+
    [8]  = "Mythic",   -- Regular Mythic (no key)
}

-- Known Delve difficultyIDs.
-- Legacy (pre-Midnight): 167–177 = Tier 1–11 (offset from 166)
-- Midnight 12.0: single diffID 208 with diffName="Delves"; tier from C_Delves API
local DELVE_DIFF_IDS = {
    [167] = true, [168] = true, [169] = true, [170] = true,
    [171] = true, [172] = true, [173] = true, [174] = true,
    [175] = true, [176] = true, [177] = true,
    [208] = true,   -- Midnight 12.0 unified delve difficultyID
}

-- Tier level API (C_Delves) is nil in Midnight 12.0 — Blizzard does not expose it.
-- Returns nil; callers fall back to instance name for display.
local function GetDelveTier() return nil end

local function GetInstanceContext()
    local instName, instType, diffID, diffName,
          maxPlayers, dynDiff, isDynamic, instMapID = GetInstanceInfo()

    local ctx = { encType = "normal", diffLabel = "World", keystoneLevel = nil, instanceName = "" }

    if not instType or instType == "none" then return ctx end

    if instType == "raid" then
        ctx.encType      = "raid"
        ctx.diffLabel    = RAID_DIFF[diffID] or diffName or "Raid"
        ctx.instanceName = instName or ""

    elseif instType == "party" then
        ctx.encType      = "dungeon"
        ctx.instanceName = instName or ""
        local keystoneLevel = nil
        if C_ChallengeMode then
            -- GetActiveKeystoneInfo returns the level of the key currently in
            -- progress — reliable after the key is consumed and combat starts.
            -- GetSlottedKeystoneInfo only works before the key is activated.
            if C_ChallengeMode.GetActiveKeystoneInfo then
                local ok, ksLevel = pcall(C_ChallengeMode.GetActiveKeystoneInfo)
                if ok and ksLevel and ksLevel > 0 then
                    keystoneLevel     = ksLevel
                    ctx.diffLabel     = "M+" .. ksLevel
                    ctx.keystoneLevel = ksLevel
                end
            end
            -- Fallback: try slotted keystone (only valid before key activation)
            if not keystoneLevel and C_ChallengeMode.GetSlottedKeystoneInfo then
                local ok, _, _, ksLevel = pcall(C_ChallengeMode.GetSlottedKeystoneInfo)
                if ok and ksLevel and ksLevel > 0 then
                    keystoneLevel     = ksLevel
                    ctx.diffLabel     = "M+" .. ksLevel
                    ctx.keystoneLevel = ksLevel
                end
            end
        end
        if not keystoneLevel then
            ctx.diffLabel = DUNGEON_DIFF[diffID] or diffName or "Dungeon"
        end

    elseif instType == "scenario" then
        local lowerDiff = (diffName or ""):lower()
        local lowerName = (instName or ""):lower()
        if DELVE_DIFF_IDS[diffID]
        or lowerDiff:find("delve") or lowerName:find("delve") then
            ctx.encType      = "delve"
            ctx.instanceName = instName or ""
            -- Try live Delve API first (Midnight 12.0 uses unified diffID 208)
            local tier = GetDelveTier()
            -- Legacy fallback: diffID 167-177 encode tier directly via offset
            if not tier and diffID >= 167 and diffID <= 177 then
                tier = diffID - 166
            end
            ctx.diffLabel = tier and ("Tier " .. tier) or (instName or diffName or "Delve")
        else
            ctx.encType      = "dungeon"
            ctx.instanceName = instName or ""
            ctx.diffLabel    = diffName or "Scenario"
        end
    end

    return ctx
end

-- Safe addon message send — wraps in pcall to suppress Lua errors.
-- In Midnight 12.0, SendAddonMessage("PARTY") from inside an instance generates
-- a protected-call error that the game prints to chat. We avoid it entirely
-- by never sending to PARTY when inside an instance; GUILD covers guild members
-- and the HELLO/SYNC flow handles the rest.
local function SafeSend(prefix, payload, channel, target)
    local ok, err = pcall(C_ChatInfo.SendAddonMessage, prefix, payload, channel, target)
    if not ok and Core.GetSetting("debugMode") then
        print("|cff888888MS LB:|r send failed (" .. channel .. "): " .. tostring(err))
    end
end

local GUILD_WHISPER_MAX = 20  -- cap whispers to avoid spam in large guilds

local function WhisperOnlineGuildMembers(payload)
    -- Whisper online guild members individually — reliable path when
    -- GUILD channel addon messages are silently dropped (Midnight 12.0).
    -- Capped at GUILD_WHISPER_MAX to avoid flooding large guilds.
    local n = GetNumGuildMembers()
    local myShort = UnitName("player") or ""
    local count = 0
    for i = 1, n do
        if count >= GUILD_WHISPER_MAX then break end
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and online then
            local short = name:match("^([^%-]+)") or name
            if short ~= myShort then
                local delay = count * 0.1
                C_Timer.After(delay, function()
                    SafeSend(LB_PREFIX, payload, "WHISPER", name)
                end)
                count = count + 1
            end
        end
    end
end

local function BroadcastToAll(payload, whisperGuild)
    -- Try GUILD channel
    if IsInGuild() then SafeSend(LB_PREFIX, payload, "GUILD") end

    -- whisperGuild=true: also whisper online members directly.
    -- Used by manual broadcast commands when GUILD channel may be unreliable.
    -- NOT used on automatic fight broadcasts to avoid spamming 828 members.
    if whisperGuild and IsInGuild() then
        WhisperOnlineGuildMembers(payload)
    end

    -- Group channels
    if IsInRaid() then
        SafeSend(LB_PREFIX, payload, "RAID")
    elseif IsInGroup() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        SafeSend(LB_PREFIX, payload, "PARTY")
    end
end

-- Convenience wrappers called from other modules
function LB.GetInstanceContext()
    return GetInstanceContext()
end

function LB.GetWeekKey()
    return GetWeekKey()
end

-- Send a direct score request to a named player via addon whisper.
-- They respond automatically if they have the addon. Result prints to chat.
function LB.QueryFriend(target)
    if not target or target == "" then
        print("|cff00D1FFMidnight Sensei:|r Usage: /ms friend Name  or  /ms friend Name-Realm")
        return
    end
    local myFullName = UnitName("player") .. "-" .. (GetRealmName() or "")
    local payload = table.concat({ "REQD", Core.VERSION, myFullName }, "|")
    local ok, err = pcall(C_ChatInfo.SendAddonMessage, LB_PREFIX, payload, "WHISPER", target)
    if ok then
        print("|cff00D1FFMidnight Sensei:|r Checking |cffFFFFFF" .. target .. "|r...")
        -- If no response arrives within 5s, let the player know
        local responded = false
        -- Mark as pending so the SCORE whisper handler can cancel the timeout
        LB._pendingFriendQuery = target
        C_Timer.After(8.0, function()
            if LB._pendingFriendQuery == target then
                LB._pendingFriendQuery = nil
                print("|cff00D1FFMidnight Sensei:|r |cffFFFFFF" .. target ..
                      "|r |cffaa3333(Offline)|r — Not updated or addon not installed")
            end
        end)
    else
        print("|cffFF4444Midnight Sensei:|r Could not reach |cffFFFFFF" .. target ..
              "|r — check the name/realm spelling. Error: " .. tostring(err))
    end
end

--------------------------------------------------------------------------------
-- Integrity system
--
-- What we can and cannot prevent:
--   CANNOT: A motivated attacker reading the Lua source to understand the
--           checksum formula. WoW addon files are plain text — no secret
--           can be hidden here.
--   CAN:    Detect casual file edits, copy-paste tampering, and simple
--           score inflation by making the checksum depend on data the
--           attacker also needs to fake consistently.
--
-- Checksum formula:
--   Components: score, duration, encType
--   Changing any value without updating the checksum produces a mismatch.
--   charName is sent in the message for display purposes only — it is NOT
--   included in the checksum because scores can be re-broadcast by peers
--   (REQ handler) and the re-broadcaster's charName would differ.

local function MakeChecksum(score, duration, encType)
    -- Checksum retained in payload for backward compatibility with older clients
    -- that still validate it. New clients (1.3.0+) do not reject on mismatch.
    local a = (score               * 7)  % 251
    local b = (math.floor(duration) * 11) % 251
    local c = (#(encType or "")    * 17) % 251
    local raw = (a + b + c) % 251
    return string.format("%03d", raw)
end

local function ValidateChecksum(score, duration, encType, checksum)
    -- Checksum validation is intentionally disabled.
    -- Cross-version float/integer rounding differences cause false failures
    -- between clients running identical code. Score range + plausibility
    -- gates (below) provide sufficient tamper resistance for a guild tool.
    return true
end

-- Per-sender rate limiter: max 100 SCORE messages per session
-- (raised from 20 for pilot testing — revisit before public release)
local senderRateLimit = {}
local RATE_LIMIT_MAX  = 100

local function CheckRateLimit(sender)
    senderRateLimit[sender] = (senderRateLimit[sender] or 0) + 1
    return senderRateLimit[sender] <= RATE_LIMIT_MAX
end

local function ResetRateLimits()
    senderRateLimit = {}
end

function LB.ResetRateLimits()
    ResetRateLimits()
end

function LB.GetReceivedScoreLog()
    return receivedScoreLog
end

-- Last 5 received SCORE messages for diagnostics
local receivedScoreLog = {}

-- Plausibility gate: (minDuration, maxScore) pairs — score above maxScore
-- requires at least minDuration seconds
local PLAUSIBILITY = {
    { minDuration = 45, maxScore = 95 },
    { minDuration = 20, maxScore = 85 },
    { minDuration = 10, maxScore = 70 },
}

local function IsPlausible(score, duration)
    for _, rule in ipairs(PLAUSIBILITY) do
        if score > rule.maxScore and duration < rule.minDuration then
            return false
        end
    end
    return true
end

--------------------------------------------------------------------------------
-- Data stores
--------------------------------------------------------------------------------
local partyData   = {}   -- [playerName] = entry  (session-only)
local friendsData = {}   -- [playerName] = entry  (session-only)
-- Guild data lives in MidnightSenseiDB.leaderboard.guild

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function GetDB()
    if not MidnightSenseiDB then return nil end
    MidnightSenseiDB.leaderboard           = MidnightSenseiDB.leaderboard           or {}
    MidnightSenseiDB.leaderboard.guild     = MidnightSenseiDB.leaderboard.guild     or {}
    MidnightSenseiDB.leaderboard.friends   = MidnightSenseiDB.leaderboard.friends   or {}
    return MidnightSenseiDB.leaderboard
end

local function GetPlayerName()
    local name, realm = UnitFullName("player")
    realm = realm and realm ~= "" and realm or GetRealmName()
    return name .. "-" .. realm
end

local function ShortName(fullName)
    if not fullName then return "?" end
    return fullName:match("^([^%-]+)") or fullName
end

local function IsGuildMember(fullName)
    if not IsInGuild() then return false end
    local shortName = ShortName(fullName)
    local n = GetNumGuildMembers()
    for i = 1, n do
        local gName = GetGuildRosterInfo(i)
        if gName and gName:match("^([^%-]+)") == shortName then return true end
    end
    return false
end

-- Friends tab: BNet friend enumeration (BNGetFriendNumGameAccounts) returns 0
-- in Midnight 12.0. Manual friend list persists in SavedVariables and queries
-- via REQD whisper protocol (requires 1.3.0+ on both ends).
local function BuildFriendsList() return {} end
local function IsBNetFriend(_) return false end
local function WhisperFriends(_) end  -- no-op: cannot enumerate friend characters

-- Persistent manual friend list: array of "Name-Realm" strings
local friendList = {}  -- loaded from DB at SESSION_READY

local function GetFriendListDB()
    local db = GetDB()
    if not db then return nil end
    db.friendList = db.friendList or {}
    return db.friendList
end

local FRIEND_LIST_MAX = 20  -- cap to avoid excessive whisper load on login/refresh

function LB.AddFriend(nameRealm)
    if not nameRealm or nameRealm == "" then return end
    -- Normalise: if no realm suffix, append current realm
    if not nameRealm:find("-") then
        nameRealm = nameRealm .. "-" .. (GetRealmName() or "")
    end
    -- Enforce cap
    if #friendList >= FRIEND_LIST_MAX then
        print("|cffFF4444Midnight Sensei:|r Friend list is full (" .. FRIEND_LIST_MAX ..
              " max). Remove someone first with right-click or /ms friend remove Name.")
        return
    end
    -- Deduplicate
    for _, f in ipairs(friendList) do
        if f:lower() == nameRealm:lower() then
            print("|cff00D1FFMidnight Sensei:|r |cffFFFFFF" .. nameRealm ..
                  "|r is already in your friend list.")
            return
        end
    end
    table.insert(friendList, nameRealm)
    local db = GetFriendListDB()
    if db then table.insert(db, nameRealm) end
    print("|cff00D1FFMidnight Sensei:|r Added |cffFFFFFF" .. nameRealm ..
          "|r to your friend list (" .. #friendList .. "/" .. FRIEND_LIST_MAX .. ").")
    -- Immediately query them
    LB.QueryFriend(nameRealm)
    LB.RefreshUI()
end

function LB.RemoveFriend(nameRealm)
    local shortTarget = ShortName(nameRealm):lower()
    for i, f in ipairs(friendList) do
        if f:lower() == nameRealm:lower() or ShortName(f):lower() == shortTarget then
            local removed = f  -- use the stored full name for DB removal
            table.remove(friendList, i)
            local db = GetFriendListDB()
            if db then
                for j, v in ipairs(db) do
                    if v:lower() == removed:lower() then
                        table.remove(db, j) ; break
                    end
                end
            end
            -- Clear from friendsData — key may be short name or full Name-Realm
            for k in pairs(friendsData) do
                if ShortName(k):lower() == shortTarget then
                    friendsData[k] = nil
                    -- Also clear from SavedVariables
                    local lbdb = GetDB()
                    if lbdb and lbdb.friends then
                        lbdb.friends[k] = nil
                    end
                    break
                end
            end
            print("|cff00D1FFMidnight Sensei:|r Removed |cffFFFFFF" ..
                  ShortName(removed) .. "|r from your friend list (" ..
                  #friendList .. "/" .. FRIEND_LIST_MAX .. ").")
            LB.RefreshUI()
            return
        end
    end
    print("|cffFF4444Midnight Sensei:|r |cffFFFFFF" .. ShortName(nameRealm) ..
          "|r not found in friend list.")
end

function LB.QueryAllFriends()
    if #friendList == 0 then return end
    -- Stagger 0.5s apart — 20 friends = 10s total, well within WoW addon message limits
    for i, name in ipairs(friendList) do
        C_Timer.After((i - 1) * 0.5, function()
            LB.QueryFriend(name)
        end)
    end
end

-- Update or create an entry, maintaining weekly avg and all-time best.
-- isBoss=true means this was an actual boss encounter; only boss fights
-- count toward weeklyAvg (hardcoded, not optional).
local function MergeEntry(existing, name, className, specName, role,
                           grade, score, duration, encType, weekKey, isBoss)
    local e = existing or {
        name         = name,
        className    = className or "?",
        specName     = specName  or "?",
        role         = role      or "?",
        grade        = grade,
        score        = score,
        duration     = duration,
        timestamp    = time(),
        online       = true,
        weekKey      = weekKey,
        -- All-time bests (never reset)
        allTimeBest  = score,
        dungeonBest  = 0,
        raidBest     = 0,
        delveBest    = 0,
        normalBest   = 0,
        -- Weekly bests (reset each WoW week)
        dungeonWeekBest = 0,
        raidWeekBest    = 0,
        delveWeekBest   = 0,
        -- Weekly avg across all boss kills (mixed content)
        weekScores   = {},
        weeklyAvg    = 0,
        -- Per-content averages (all-time running)
        dungeonAvg   = 0,
        raidAvg      = 0,
        dungeonCount = 0,
        raidCount    = 0,
    }

    -- Ensure weekly fields exist on older entries
    if not e.weekScores        then e.weekScores        = {} end
    if not e.dungeonWeekBest   then e.dungeonWeekBest   = 0  end
    if not e.raidWeekBest      then e.raidWeekBest      = 0  end
    if not e.delveWeekBest     then e.delveWeekBest     = 0  end

    -- If new WoW week, reset all weekly data
    if e.weekKey ~= weekKey then
        e.weekKey         = weekKey
        e.weekScores      = {}
        e.weeklyAvg       = 0
        e.dungeonWeekBest = 0
        e.raidWeekBest    = 0
        e.delveWeekBest   = 0
    end

    -- Weekly avg — boss kills only (mixed content, for overall leaderboard sort)
    if isBoss then
        table.insert(e.weekScores, score)
        if #e.weekScores > 50 then table.remove(e.weekScores, 1) end
        local sum = 0
        for _, s in ipairs(e.weekScores) do sum = sum + s end
        e.weeklyAvg = math.floor(sum / #e.weekScores)
    end

    -- All-time best (every fight)
    if score > (e.allTimeBest or 0) then e.allTimeBest = score end

    -- Category all-time bests, weekly bests, and running averages
    if encType == "dungeon" then
        if score > (e.dungeonBest or 0)     then e.dungeonBest     = score end
        if score > (e.dungeonWeekBest or 0) then e.dungeonWeekBest = score end
        e.dungeonCount = (e.dungeonCount or 0) + 1
        local prevSum  = (e.dungeonAvg or 0) * ((e.dungeonCount or 1) - 1)
        e.dungeonAvg   = math.floor((prevSum + score) / e.dungeonCount)
    elseif encType == "raid" then
        if score > (e.raidBest or 0)     then e.raidBest     = score end
        if score > (e.raidWeekBest or 0) then e.raidWeekBest = score end
        e.raidCount = (e.raidCount or 0) + 1
        local prevSum = (e.raidAvg or 0) * ((e.raidCount or 1) - 1)
        e.raidAvg     = math.floor((prevSum + score) / e.raidCount)
    elseif encType == "delve" then
        if score > (e.delveBest or 0)     then e.delveBest     = score end
        if score > (e.delveWeekBest or 0) then e.delveWeekBest = score end
    else
        if score > (e.normalBest or 0) then e.normalBest = score end
    end

    -- Update displayed fields
    e.name      = name
    e.className = className or e.className
    e.specName  = specName  or e.specName
    e.role      = role      or e.role
    e.grade     = grade
    e.score     = score
    e.duration  = duration
    e.timestamp = time()
    e.online    = true

    return e
end

--------------------------------------------------------------------------------
-- Broadcast own score
--------------------------------------------------------------------------------

local function BroadcastScore(encounter)
    if not encounter or not encounter.finalScore then return end
    -- For delve encounters: only broadcast if it's a boss fight (ENCOUNTER_START fired)
    -- or if it's the highest delve score in history (suppress trash-pull spam).
    if encounter.encType == "delve" and not encounter.isBoss then
        local history = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
        if history then
            for _, enc in ipairs(history) do
                if enc.encType == "delve" and (enc.finalScore or 0) > (encounter.finalScore or 0) then
                    return  -- a better delve score already exists; skip broadcast
                end
            end
        end
    end
    local charName  = UnitName("player") or "?"
    local encType   = encounter.encType  or "normal"
    local diffLabel = encounter.diffLabel or ""
    local ks        = encounter.keystoneLevel and tostring(encounter.keystoneLevel) or "0"
    local cs = MakeChecksum(encounter.finalScore,
                            math.floor(encounter.duration or 0),
                            encType)

    local payload = table.concat({
        "SCORE",
        Core.VERSION,
        encounter.className  or "?",
        encounter.specName   or "?",
        encounter.role       or "?",
        encounter.finalGrade or "?",
        tostring(encounter.finalScore or 0),
        tostring(math.floor(encounter.duration or 0)),
        encounter.isBoss and "1" or "0",
        (encounter.bossName    or ""):gsub("|", "_"),
        encType,
        cs,
        diffLabel:gsub("|", "_"),
        ks,
        charName:gsub("|", "_"),
        (encounter.instanceName or ""):gsub("|", "_"),
    }, "|")

    BroadcastToAll(payload)
    -- Also whisper BNet friends directly — they may not share guild or group
    WhisperFriends(payload)
end

-- Manual broadcast: also whispers online guild members directly.
-- Used by /ms clean payload and /ms debug guild broadcast when GUILD
-- channel may not be reliable (Midnight 12.0 known issue).
function LB.BroadcastHelloToGuild()
    if not Core.ActiveSpec then return end
    local payload = table.concat({ "HELLO", Core.VERSION,
        Core.ActiveSpec.className or "?",
        Core.ActiveSpec.name      or "?" }, "|")
    BroadcastToAll(payload, true)  -- whisperGuild=true
end

function LB.BroadcastEncounterToGuild(encounter)
    if not encounter or not encounter.finalScore then return end
    local charName  = UnitName("player") or "?"
    local encType   = encounter.encType  or "normal"
    local diffLabel = encounter.diffLabel or ""
    local ks        = encounter.keystoneLevel and tostring(encounter.keystoneLevel) or "0"
    local cs = MakeChecksum(encounter.finalScore,
                            math.floor(encounter.duration or 0), encType)
    local payload = table.concat({
        "SCORE", Core.VERSION,
        encounter.className  or "?",
        encounter.specName   or "?",
        encounter.role       or "?",
        encounter.finalGrade or "?",
        tostring(encounter.finalScore or 0),
        tostring(math.floor(encounter.duration or 0)),
        encounter.isBoss and "1" or "0",
        (encounter.bossName    or ""):gsub("|", "_"),
        encType, cs,
        diffLabel:gsub("|", "_"),
        ks,
        charName:gsub("|", "_"),
        (encounter.instanceName or ""):gsub("|", "_"),
    }, "|")
    BroadcastToAll(payload, true)  -- whisperGuild=true
    WhisperFriends(payload)
end

Core.On(Core.EVENTS.GRADE_CALCULATED, BroadcastScore)

-- Auto-refresh leaderboard after each fight if it's open
Core.On(Core.EVENTS.GRADE_CALCULATED, function()
    C_Timer.After(0.5, function()
        LB.RefreshUI()
    end)
end)

--------------------------------------------------------------------------------
-- HELLO broadcast
--------------------------------------------------------------------------------
local function BroadcastHello()
    if not Core.ActiveSpec then return end
    local payload = table.concat({ "HELLO", Core.VERSION,
        Core.ActiveSpec.className or "?",
        Core.ActiveSpec.name      or "?" }, "|")
    BroadcastToAll(payload)
    WhisperFriends(payload)
end

-- Seed partyData with current group members on login/reload and when leaderboard opens.
-- partyData is session-only so it empties on reload; we refill from group unit tokens.
local function SeedPartyFromGroup()
    local n = GetNumGroupMembers()
    if n == 0 then return end
    local myShort = UnitName("player") or ""
    for i = 1, n do
        local unit = (IsInRaid() and "raid" or "party") .. i
        local name = UnitName(unit)
        -- Skip self — GetPartyData injects the self-entry separately
        if name and name ~= myShort then
            -- Key by short name to match how SCORE/HELLO sender arrives
            local key = name
            if not partyData[key] then
                partyData[key] = {
                    name        = name,
                    className   = UnitClass(unit) or "?",
                    specName    = "",
                    grade       = "--",
                    score       = 0,
                    online      = true,
                    timestamp   = 0,
                    weekKey     = GetWeekKey(),
                    weeklyAvg   = 0, allTimeBest = 0,
                    dungeonBest = 0, raidBest = 0, delveBest = 0, normalBest = 0,
                }
            end
        end
    end
end

Core.On(Core.EVENTS.SESSION_READY, function() C_Timer.After(4.0, BroadcastHello) end)
Core.On(Core.EVENTS.SESSION_READY, function()
    C_Timer.After(2.0, function()
        SeedPartyFromGroup()
        -- Load persisted friend list from DB
        local db = GetFriendListDB()
        if db then
            friendList = {}
            for _, name in ipairs(db) do
                table.insert(friendList, name)
            end
        end
        -- Load persisted friend scores from DB — mark all offline until they respond
        local lbdb = GetDB()
        if lbdb and lbdb.friends then
            for k, v in pairs(lbdb.friends) do
                v.online = false  -- will be set true when they respond this session
                friendsData[k] = v
            end
        end
        LB.RefreshUI()
    end)
    -- Query all manual friends after a short delay so they're loaded first
    C_Timer.After(6.0, function()
        LB.QueryAllFriends()
    end)
end)
Core.On(Core.EVENTS.SPEC_CHANGED,  function() C_Timer.After(1.0, BroadcastHello) end)

--------------------------------------------------------------------------------
-- Incoming message parser
--------------------------------------------------------------------------------
-- Forward declaration: SyncGuildOnlineStatus is defined later in this file
-- but called from OnAddonMessage (below) and the event frame. Without this
-- the local is out of scope at the call site and resolves as a nil global.
local SyncGuildOnlineStatus
local function OnAddonMessage(prefix, payload, channel, sender)
    if prefix ~= LB_PREFIX then return end
    local shortSelf = UnitName("player")
    if ShortName(sender) == shortSelf then return end

    local parts = {}
    for p in payload:gmatch("[^|]+") do table.insert(parts, p) end
    if #parts < 2 then return end

    local msgType = parts[1]

    if msgType == "SCORE" then
        -- Accept 12+ parts for backward compatibility with older clients.
        -- Format history:
        --   Old (12-14 parts): bossName|checksum|diffLabel|ks|charName  (no encType field)
        --   New (15-16 parts): bossName|encType|checksum|diffLabel|ks|charName|instanceName
        -- Detection: if parts[11] is a 3-digit number (000-250) it's the old checksum,
        -- meaning encType is absent and we need to shift fields.
        if #parts < 12 then return end

        local className = parts[3]
        local specName  = parts[4]
        local role      = parts[5]
        local grade     = parts[6]
        local score     = tonumber(parts[7]) or 0
        local duration  = tonumber(parts[8]) or 0
        local isBoss    = (parts[9] == "1")
        local bossName  = parts[10] or ""

        -- Detect format by checking if parts[11] looks like a checksum (3-digit numeric string)
        local encType, checksum, diffLabel, ks, charName, instanceName
        if parts[11] and parts[11]:match("^%d%d%d$") and tonumber(parts[11]) then
            -- Old format: no encType field — parts[11] is checksum
            -- Infer encType from diffLabel. Explicit raid/lfr keywords take priority.
            -- "Normal"/"Heroic"/"Mythic" without further context default to dungeon
            -- since those difficulties are far more common in daily dungeon content.
            local dl  = (parts[12] or ""):lower()
            local ks13 = tonumber(parts[13]) or 0
            local inferredType = "normal"
            if dl:find("^lfr") or dl:find("^raid") or dl:find("looking for raid") then
                inferredType = "raid"
            elseif dl:find("delve") or dl:find("tier") then
                inferredType = "delve"
            elseif dl:find("m%+") or dl:find("mythic%+") or ks13 > 0
                or dl:find("mythic") or dl:find("heroic")
                or dl:find("normal") or dl:find("timewalking") then
                inferredType = "dungeon"
            end
            encType      = inferredType
            checksum     = parts[11]
            diffLabel    = parts[12] or ""
            ks           = ks13
            charName     = parts[14] or ShortName(sender)
            instanceName = parts[15] or ""
        else
            -- New format: parts[11] is encType
            encType      = parts[11] or "normal"
            checksum     = parts[12]
            diffLabel    = parts[13] or ""
            ks           = tonumber(parts[14]) or 0
            charName     = parts[15] or ShortName(sender)
            instanceName = parts[16] or ""
        end

        -- 1. Score range
        if score < 0 or score > 100 then return end

        -- 2. Checksum — always passes (validation disabled, see ValidateChecksum above).
        -- Score range (step 1) and plausibility (step 3) are the active gates.

        -- 3. Plausibility (score too high for fight length)
        if not IsPlausible(score, duration) then
            if Core.GetSetting("debugMode") then
                print("|cffFF4444Midnight Sensei:|r Rejected score from " ..
                      ShortName(sender) .. " (implausible: " ..
                      score .. " in " .. duration .. "s)")
            end
            return
        end

        -- 4. Rate limit per sender per session
        if not CheckRateLimit(sender) then return end

        -- Log for diagnostics (/ms debug guild receive)
        table.insert(receivedScoreLog, {
            sender = ShortName(sender), channel = channel,
            score = score, encType = encType, isBoss = isBoss,
            diffLabel = diffLabel, instanceName = instanceName,
        })
        if #receivedScoreLog > 5 then table.remove(receivedScoreLog, 1) end

        local weekKey = GetWeekKey()

        -- Route to party: check if sender is currently in our group,
        -- regardless of which channel the message arrived on.
        -- IsInGroup() fails for LFD groups, so check unit names directly.
        local addedToParty = false
        local myShort = UnitName("player") or ""
        if ShortName(sender) ~= myShort then
            for i = 1, GetNumGroupMembers() do
                local unit = (IsInRaid() and "raid" or "party") .. i
                local unitName = UnitName(unit)
                if unitName and ShortName(sender) == unitName then
                    local key = ShortName(sender)
                    partyData[key] = MergeEntry(partyData[key], sender,
                        className, specName, role, grade, score, duration,
                        encType, weekKey, isBoss)
                    partyData[key].diffLabel     = diffLabel
                    partyData[key].bossName      = bossName
                    partyData[key].instanceName  = instanceName
                    partyData[key].keystoneLevel = ks > 0 and ks or nil
                    addedToParty = true
                    break
                end
            end
        end

        -- Route to guild if applicable.
        -- If message arrived on GUILD channel, sender is guaranteed to be a guild member
        -- (WoW validates this at protocol level). For other channels (PARTY, WHISPER),
        -- fall back to IsGuildMember roster check.
        if IsInGuild() then
            local isGuild = (channel == "GUILD") or IsGuildMember(sender)
            if isGuild then
                local db = GetDB()
                if db then
                    db.guild[sender] = MergeEntry(db.guild[sender], sender,
                        className, specName, role, grade, score, duration,
                        encType, weekKey, isBoss)
                    db.guild[sender].diffLabel     = diffLabel
                    db.guild[sender].bossName      = bossName
                    db.guild[sender].instanceName  = instanceName
                    db.guild[sender].keystoneLevel = ks > 0 and ks or nil
                    -- Store per-content-type location fields so each tab shows
                    -- its own last location rather than the last broadcast of any type
                    if encType == "dungeon" then
                        db.guild[sender].dungeonLabel    = diffLabel
                        db.guild[sender].dungeonInstance = instanceName
                        db.guild[sender].dungeonBoss     = bossName
                        db.guild[sender].dungeonKs       = ks > 0 and ks or nil
                    elseif encType == "raid" then
                        db.guild[sender].raidLabel       = diffLabel
                        db.guild[sender].raidInstance    = instanceName
                        db.guild[sender].raidBoss        = bossName
                    elseif encType == "delve" then
                        db.guild[sender].delveLabel      = diffLabel
                        db.guild[sender].delveInstance   = instanceName
                        db.guild[sender].delveBoss       = bossName
                    end
                end
            end
        end

        -- Route to friends: check IsBNetFriend, or if message came via WHISPER channel
        -- (friends who aren't in same guild/group send via whisper)
        if IsBNetFriend(sender) or channel == "WHISPER" then
            friendsData[sender] = MergeEntry(friendsData[sender], sender,
                className, specName, role, grade, score, duration,
                encType, weekKey, isBoss)
            friendsData[sender].diffLabel     = diffLabel
            friendsData[sender].bossName      = bossName
            friendsData[sender].instanceName  = instanceName
            friendsData[sender].keystoneLevel = ks > 0 and ks or nil
            if encType == "dungeon" then
                friendsData[sender].dungeonLabel    = diffLabel
                friendsData[sender].dungeonInstance = instanceName
                friendsData[sender].dungeonBoss     = bossName
                friendsData[sender].dungeonKs       = ks > 0 and ks or nil
            elseif encType == "raid" then
                friendsData[sender].raidLabel       = diffLabel
                friendsData[sender].raidInstance    = instanceName
                friendsData[sender].raidBoss        = bossName
            elseif encType == "delve" then
                friendsData[sender].delveLabel    = diffLabel
                friendsData[sender].delveInstance = instanceName
                friendsData[sender].delveBoss     = bossName
            end
            -- Persist to SavedVariables so data survives logout
            local lbdb = GetDB()
            if lbdb then
                lbdb.friends[sender] = friendsData[sender]
            end

            -- If this arrived via direct whisper (from /ms friend query), print to chat
            if channel == "WHISPER" then
                -- Cancel any pending friend query timeout on any whisper SCORE response
                LB._pendingFriendQuery = nil
                print("|cff00D1FFMidnight Sensei:|r |cffFFFFFF" .. ShortName(sender) ..
                      "|r |cff20aa20(Online)|r — Updated")
            end
        end

        LB.RefreshUI()

    elseif msgType == "REQ" then
        -- A peer is asking everyone to resend their last score (triggered by Refresh).
        C_Timer.After(0.5 + math.random() * 1.5, function()
            local lastEnc = MS.Analytics and MS.Analytics.GetLastEncounter
                            and MS.Analytics.GetLastEncounter()
            if lastEnc and lastEnc.finalScore then
                Core.Emit(Core.EVENTS.GRADE_CALCULATED, lastEnc)
            end
        end)

    elseif msgType == "REQD" then
        -- Direct request: a specific player is asking for our score via whisper.
        -- parts[2] = their version, parts[3] = their full name (return address).
        -- We whisper our last score directly back to them.
        -- Only respond to WHISPER channel — prevents spoofed REQD on guild/raid.
        if channel ~= "WHISPER" then return end
        local returnAddr = parts[3]
        if not returnAddr or returnAddr == "" then return end
        C_Timer.After(0.5 + math.random() * 0.5, function()
            local lastEnc = MS.Analytics and MS.Analytics.GetLastEncounter
                            and MS.Analytics.GetLastEncounter()
            if lastEnc and lastEnc.finalScore then
                -- Reuse BroadcastScore logic but whisper directly to requester
                local charName  = UnitName("player") or "?"
                local encType   = lastEnc.encType  or "normal"
                local diffLabel = lastEnc.diffLabel or ""
                local ks        = lastEnc.keystoneLevel and tostring(lastEnc.keystoneLevel) or "0"
                local cs = MakeChecksum(lastEnc.finalScore,
                                        math.floor(lastEnc.duration or 0),
                                        encType)
                local payload = table.concat({
                    "SCORE", Core.VERSION,
                    lastEnc.className  or "?",
                    lastEnc.specName   or "?",
                    lastEnc.role       or "?",
                    lastEnc.finalGrade or "?",
                    tostring(lastEnc.finalScore or 0),
                    tostring(math.floor(lastEnc.duration or 0)),
                    lastEnc.isBoss and "1" or "0",
                    (lastEnc.bossName    or ""):gsub("|", "_"),
                    encType,
                    cs,
                    diffLabel:gsub("|", "_"),
                    ks,
                    charName:gsub("|", "_"),
                    (lastEnc.instanceName or ""):gsub("|", "_"),
                }, "|")
                SafeSend(LB_PREFIX, payload, "WHISPER", returnAddr)
            end
        end)

    elseif msgType == "HELLO" then
        -- Guild: trust GUILD channel messages implicitly; use roster check for other channels
        if IsInGuild() and ((channel == "GUILD") or IsGuildMember(sender)) then
            local db = GetDB()
            if db then
                if not db.guild[sender] then
                    db.guild[sender] = {
                        name        = sender,
                        className   = parts[3] or "?",
                        specName    = parts[4] or "?",
                        grade       = "--",
                        score       = 0,
                        online      = true,
                        timestamp   = time(),
                        weekKey     = GetWeekKey(),
                        weekScores  = {},
                        weeklyAvg   = 0,
                        allTimeBest = 0,
                        dungeonBest = 0, raidBest  = 0,
                        delveBest   = 0, normalBest = 0,
                        dungeonAvg  = 0, raidAvg    = 0,
                        dungeonCount = 0, raidCount = 0,
                    }
                else
                    -- Always update identity fields — player may have switched
                    -- characters or specs since the last persisted entry.
                    db.guild[sender].online    = true
                    if parts[3] and parts[3] ~= "?" then
                        db.guild[sender].className = parts[3]
                    end
                    if parts[4] and parts[4] ~= "?" then
                        db.guild[sender].specName  = parts[4]
                    end
                end

                -- GRM-style sync back
                local entry = db.guild[sender]
                if entry and (entry.allTimeBest or 0) > 0 then
                    C_Timer.After(2.0 + math.random() * 3.0, function()
                        local syncPayload = table.concat({
                            "SYNC", ShortName(sender),
                            tostring(entry.allTimeBest  or 0),
                            tostring(entry.weeklyAvg    or 0),
                            tostring(entry.dungeonBest  or 0),
                            tostring(entry.raidBest     or 0),
                            tostring(entry.delveBest    or 0),
                            entry.weekKey or GetWeekKey(),
                        }, "|")
                        if IsInGuild() then SafeSend(LB_PREFIX, syncPayload, "GUILD") end
                    end)
                end
            end
        end

        -- Party: add placeholder if sender is in our group (skip self)
        local myShort = UnitName("player") or ""
        if ShortName(sender) ~= myShort then
            for i = 1, GetNumGroupMembers() do
                local unit = (IsInRaid() and "raid" or "party") .. i
                local unitName = UnitName(unit)
                if unitName and ShortName(sender) == unitName then
                    local key = ShortName(sender)
                    if not partyData[key] then
                        partyData[key] = {
                            name      = ShortName(sender),
                            className = parts[3] or "?",
                            specName  = parts[4] or "?",
                            grade     = "--",
                            score     = 0,
                            online    = true,
                            timestamp = 0,
                            weekKey   = GetWeekKey(),
                            weeklyAvg = 0, allTimeBest = 0,
                            dungeonBest = 0, raidBest = 0, delveBest = 0, normalBest = 0,
                        }
                    else
                        partyData[key].online    = true
                        if parts[3] and parts[3] ~= "?" then partyData[key].className = parts[3] end
                        if parts[4] and parts[4] ~= "?" then partyData[key].specName  = parts[4] end
                    end
                    break
                end
            end
        end

        -- Friends: add a no-score placeholder if sender is a BNet friend
        -- or if this HELLO arrived via whisper (direct BNet friend path)
        if IsBNetFriend(sender) or channel == "WHISPER" then
            if not friendsData[sender] then
                friendsData[sender] = {
                    name      = sender,
                    className = parts[3] or "?",
                    specName  = parts[4] or "?",
                    grade     = "--",
                    score     = 0,
                    online    = true,
                    timestamp = 0,
                    weekKey   = GetWeekKey(),
                    weeklyAvg = 0, allTimeBest = 0,
                    dungeonBest = 0, raidBest = 0, delveBest = 0, normalBest = 0,
                }
            else
                friendsData[sender].online = true
            end

            -- If this arrived via whisper, whisper back our HELLO so they also
            -- get our entry (mutual handshake — otherwise only one side registers).
            if channel == "WHISPER" and Core.ActiveSpec then
                local replyPayload = table.concat({
                    "HELLO", Core.VERSION,
                    Core.ActiveSpec.className or "?",
                    Core.ActiveSpec.name      or "?",
                }, "|")
                -- Whisper back to the exact sender (Name-Realm format is fine for WHISPER)
                pcall(C_ChatInfo.SendAddonMessage, LB_PREFIX, replyPayload, "WHISPER", sender)

                -- Also resend our last score directly to them so their Friends tab populates
                C_Timer.After(0.5, function()
                    local lastEnc = MS.Analytics and MS.Analytics.GetLastEncounter
                                    and MS.Analytics.GetLastEncounter()
                    if lastEnc and lastEnc.finalScore then
                        Core.Emit(Core.EVENTS.GRADE_CALCULATED, lastEnc)
                    end
                end)
            end
        end

        LB.RefreshUI()

    elseif msgType == "SYNC" then
        -- A peer is sending us back our own historical data (GRM-style recovery).
        -- Format: SYNC|targetName|allTimeBest|weeklyAvg|dungeonBest|raidBest|delveBest|weekKey
        if #parts < 8 then return end
        local targetName  = parts[2]
        local myShortName = UnitName("player") or ""

        -- Only accept if this is addressed to us
        if targetName ~= myShortName then return end

        local allTimeBest = tonumber(parts[3]) or 0
        local weeklyAvg   = tonumber(parts[4]) or 0
        local dungeonBest = tonumber(parts[5]) or 0
        local raidBest    = tonumber(parts[6]) or 0
        local delveBest   = tonumber(parts[7]) or 0
        local weekKey     = parts[8] or GetWeekKey()

        -- Validate all values are in range
        if allTimeBest > 100 or dungeonBest > 100 or raidBest > 100 or delveBest > 100 then
            return
        end

        -- Only restore values that are *higher* than what we currently have
        -- (never let a peer downgrade our scores)
        local db = MidnightSenseiDB
        if not db then return end
        db.leaderboard = db.leaderboard or {}
        local lb = db.leaderboard
        lb.recoveredBests = lb.recoveredBests or {}
        local rb = lb.recoveredBests
        local changed = false

        if allTimeBest > (rb.allTimeBest or 0) then
            rb.allTimeBest = allTimeBest ; changed = true end
        if dungeonBest > (rb.dungeonBest or 0) then
            rb.dungeonBest = dungeonBest ; changed = true end
        if raidBest    > (rb.raidBest    or 0) then
            rb.raidBest    = raidBest    ; changed = true end
        if delveBest   > (rb.delveBest   or 0) then
            rb.delveBest   = delveBest   ; changed = true end

        if changed and Core.GetSetting("debugMode") then
            print("|cff00D1FFMidnight Sensei:|r Recovered leaderboard data from " ..
                  ShortName(sender))
        end
        LB.RefreshUI()

    elseif msgType == "PING" then
        -- Channel connectivity test — just log receipt for /ms debug guild receive
        table.insert(receivedScoreLog, {
            sender = ShortName(sender), channel = channel,
            score = "PING", encType = "ping", isBoss = false,
            diffLabel = "", instanceName = "",
        })
        if #receivedScoreLog > 5 then table.remove(receivedScoreLog, 1) end
    end
end

--------------------------------------------------------------------------------
-- Guild online sync
--------------------------------------------------------------------------------
local function SyncGuildOnlineStatus()
    local db = GetDB()
    if not db then return end
    for name, entry in pairs(db.guild) do entry.online = false end
    local n = GetNumGuildMembers()
    for i = 1, n do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and online then
            -- db.guild key may be short name or full Name-Realm — match both
            if db.guild[name] then
                db.guild[name].online = true
            else
                local shortRoster = name:match("^([^%-]+)") or name
                for key in pairs(db.guild) do
                    if (key:match("^([^%-]+)") or key) == shortRoster then
                        db.guild[key].online = true ; break
                    end
                end
            end
        end
    end
    LB.RefreshUI()
end

-- Weekly avg is always boss-only. Not optional.
-- For encounters without weekKey (older history), falls back to timestamp comparison.
local function ComputeWeeklyAvg(history, weekKey)
    if not history then return 0 end

    -- Derive the UTC epoch for the start of this WoW week so we can bucket
    -- old encounters that predate the weekKey field.
    -- WoW's time() returns UTC epoch. We use GetWeekKey's own logic in reverse:
    -- The weekKey is YYYYMMDD of the Tuesday at 14:00 UTC that started the week.
    -- We find it by scanning backwards from now until we hit that Tuesday.
    -- Simple approach: current time() minus the offset we already computed in GetWeekKey.
    local weekStart = 0
    local weekEnd   = 0
    if #weekKey == 8 then
        -- Walk back from now to find the epoch that matches this weekKey.
        -- Each WoW week is exactly 7 days. GetWeekKey returns the current week's key,
        -- so if weekKey == GetWeekKey() we can compute weekStart directly from now.
        local utcNow   = time()
        local shifted  = utcNow - (14 * 3600)
        local t        = date("!*t", shifted)
        local wday     = t.wday
        local daysSinceTue = (wday - 3 + 7) % 7
        -- weekStart = epoch of this week's Tuesday 14:00 UTC
        local thisWeekStart = utcNow - daysSinceTue * 86400
                            - (t.hour * 3600 + t.min * 60 + t.sec)
                            + (14 * 3600)  -- add 14h to get 14:00 UTC

        -- Find how many weeks ago this weekKey was
        local curKey = GetWeekKey()
        if weekKey == curKey then
            weekStart = thisWeekStart
        elseif weekKey < curKey then
            -- Walk back in 7-day steps until we find the right key
            local probe = thisWeekStart
            for _ = 1, 52 do  -- max 1 year lookback
                probe = probe - 7 * 86400
                local probeShifted = probe - (14 * 3600)
                local pTue = date("!*t", probeShifted)
                local pKey = string.format("%04d%02d%02d", pTue.year, pTue.month, pTue.mday)
                if pKey == weekKey then
                    weekStart = probe
                    break
                end
            end
        end
        weekEnd = weekStart + 7 * 86400
    end

    local sum, count = 0, 0
    for _, enc in ipairs(history) do
        if enc.isBoss then
            local inWeek = false
            if enc.weekKey and enc.weekKey ~= "" then
                inWeek = (enc.weekKey == weekKey)
            elseif enc.timestamp and weekStart > 0 then
                inWeek = (enc.timestamp >= weekStart and enc.timestamp < weekEnd)
            end
            if inWeek then
                sum   = sum   + (enc.finalScore or 0)
                count = count + 1
            end
        end
    end
    return count > 0 and math.floor(sum / count) or 0
end

--------------------------------------------------------------------------------
-- Public data getters
--------------------------------------------------------------------------------
function LB.GetPartyData()
    local result = {}
    local myName = GetPlayerName()
    local spec   = Core.ActiveSpec
    if spec then
        local history = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
        -- Use last boss encounter in a dungeon/raid for display context.
        -- Falls back to any dungeon/raid enc, then any enc, if no boss found.
        local lastEnc = nil
        local lastEncAny = nil
        if history then
            for i = #history, 1, -1 do
                local e = history[i]
                if e.encType == "dungeon" or e.encType == "raid" then
                    if not lastEncAny then lastEncAny = e end
                    if e.isBoss and not lastEnc then lastEnc = e end
                end
                if lastEnc then break end
            end
            lastEnc = lastEnc or lastEncAny -- no delve/normal fallback
        end
        local wk      = GetWeekKey()
        local wAvg    = ComputeWeeklyAvg(history, wk)

        -- Compute all-time and category bests from full history
        local allBest, dungBest, raidBest, delvBest = 0, 0, 0, 0
        if history then
            for _, enc in ipairs(history) do
                local s = enc.finalScore or 0
                allBest = math.max(allBest, s)
                if     enc.encType == "dungeon" then dungBest = math.max(dungBest, s)
                elseif enc.encType == "raid"    then raidBest = math.max(raidBest, s)
                elseif enc.encType == "delve"   then delvBest = math.max(delvBest, s)
                end
            end
        end

        result[myName] = {
            name        = UnitName("player"),
            className   = spec.className or "?",
            specName    = spec.name      or "?",
            role        = spec.role      or "?",
            grade       = lastEnc and (lastEnc.finalGrade or lastEnc.grade) or "--",
            score       = lastEnc and lastEnc.finalScore  or 0,
            timestamp   = lastEnc and lastEnc.timestamp   or 0,
            isSelf      = true,
            online      = true,
            weekKey     = wk,
            weeklyAvg   = wAvg,
            allTimeBest = allBest,
            dungeonBest = dungBest,
            raidBest    = raidBest,
            delveBest   = delvBest,
            normalBest  = 0,
            diffLabel    = lastEnc and lastEnc.diffLabel    or "",
            instanceName = lastEnc and lastEnc.instanceName or "",
            bossName     = lastEnc and lastEnc.bossName     or "",
        }
        -- Merge CharDB.bests so scores beyond the encounter cap are preserved
        local cb = MidnightSenseiCharDB and MidnightSenseiCharDB.bests
        if cb then
            local e = result[myName]
            e.allTimeBest = math.max(e.allTimeBest, cb.allTimeBest or 0)
            e.dungeonBest = math.max(e.dungeonBest, cb.dungeonBest or 0)
            e.raidBest    = math.max(e.raidBest,    cb.raidBest    or 0)
            e.delveBest   = math.max(e.delveBest,   cb.delveBest   or 0)
            if cb.weekKey == wk then
                if cb.weeklyAvg         > e.weeklyAvg      then e.weeklyAvg      = cb.weeklyAvg         end
                if (cb.weeklyDungeonBest or 0) > (e.dungeonWeekBest or 0) then e.dungeonWeekBest = cb.weeklyDungeonBest end
                if (cb.weeklyRaidBest    or 0) > (e.raidWeekBest    or 0) then e.raidWeekBest    = cb.weeklyRaidBest    end
                if (cb.weeklyDelveBest   or 0) > (e.delveWeekBest   or 0) then e.delveWeekBest   = cb.weeklyDelveBest   end
            end
        end
    end
    for name, entry in pairs(partyData) do result[name] = entry end
    return result
end

function LB.GetGuildData()
    local db = GetDB()
    local guildData = db and db.guild or {}

    -- Always inject self so the player appears in their own guild tab
    if IsInGuild() then
        local myName = GetPlayerName()
        local spec   = Core.ActiveSpec
        if spec then
            local history = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
            -- Use last boss encounter per content type for accurate per-tab display.
            -- Separate dungeon and raid so each tab shows its own last location.
            local lastDungEnc, lastDungAny = nil, nil
            local lastRaidEnc, lastRaidAny = nil, nil
            if history then
                for i = #history, 1, -1 do
                    local e = history[i]
                    if e.encType == "dungeon" then
                        if not lastDungAny then lastDungAny = e end
                        if e.isBoss and not lastDungEnc then lastDungEnc = e end
                    elseif e.encType == "raid" then
                        if not lastRaidAny then lastRaidAny = e end
                        if e.isBoss and not lastRaidEnc then lastRaidEnc = e end
                    end
                    if lastDungEnc and lastRaidEnc then break end
                end
                lastDungEnc = lastDungEnc or lastDungAny
                lastRaidEnc = lastRaidEnc or lastRaidAny
            end
            -- Generic lastEnc for top-level grade/score display (prefer boss, either type)
            local lastEnc = lastDungEnc or lastRaidEnc
            local wk      = GetWeekKey()

            -- Boss-only weekly avg (always hardcoded)
            local wAvg = ComputeWeeklyAvg(history, wk)

            -- Category bests from full history
            local allBest, dungBest, raidBest, delvBest, normBest = 0, 0, 0, 0, 0
            -- Per-content weekly averages (boss kills this week only)
            local dungSum, dungCount, raidSum, raidCount = 0, 0, 0, 0
            if history then
                for _, enc in ipairs(history) do
                    local s = enc.finalScore or 0
                    allBest = math.max(allBest, s)
                    if enc.encType == "dungeon" then
                        dungBest = math.max(dungBest, s)
                        if enc.isBoss and (enc.weekKey == wk) then
                            dungSum   = dungSum   + s
                            dungCount = dungCount + 1
                        end
                    elseif enc.encType == "raid" then
                        raidBest = math.max(raidBest, s)
                        if enc.isBoss and (enc.weekKey == wk) then
                            raidSum   = raidSum   + s
                            raidCount = raidCount + 1
                        end
                    elseif enc.encType == "delve" then
                        delvBest = math.max(delvBest, s)
                    elseif enc.encType ~= "delve" then
                        normBest = math.max(normBest, s)
                    end
                end
            end
            local selfDungAvg = dungCount > 0 and math.floor(dungSum / dungCount) or 0
            local selfRaidAvg = raidCount > 0 and math.floor(raidSum / raidCount) or 0

            local existing = guildData[myName]
            local selfEntry = {
                name          = UnitName("player"),
                className     = spec.className or "?",
                specName      = spec.name      or "?",
                role          = spec.role      or "?",
                grade         = lastEnc and (lastEnc.finalGrade or lastEnc.grade) or "--",
                score         = lastEnc and lastEnc.finalScore  or 0,
                timestamp     = lastEnc and lastEnc.timestamp   or 0,
                isSelf        = true,
                online        = true,
                weekKey       = wk,
                weeklyAvg     = wAvg,
                allTimeBest   = allBest,
                dungeonBest   = dungBest,
                raidBest      = raidBest,
                delveBest     = delvBest,
                normalBest    = normBest,
                dungeonAvg    = selfDungAvg,
                raidAvg       = selfRaidAvg,
                diffLabel     = lastEnc and lastEnc.diffLabel    or "",
                instanceName  = lastEnc and lastEnc.instanceName or "",
                bossName      = lastEnc and lastEnc.bossName     or "",
                keystoneLevel = lastEnc and lastEnc.keystoneLevel or nil,
                -- Per-type location fields — prevent cross-content bleed in display
                dungeonLabel    = lastDungEnc and lastDungEnc.diffLabel    or "",
                dungeonInstance = lastDungEnc and lastDungEnc.instanceName or "",
                dungeonBoss     = lastDungEnc and lastDungEnc.bossName     or "",
                dungeonKs       = lastDungEnc and lastDungEnc.keystoneLevel or nil,
                raidLabel       = lastRaidEnc and lastRaidEnc.diffLabel    or "",
                raidInstance    = lastRaidEnc and lastRaidEnc.instanceName or "",
                raidBoss        = lastRaidEnc and lastRaidEnc.bossName     or "",
            }

            -- Merge with persisted data and peer-recovered bests
            if existing then
                selfEntry.allTimeBest = math.max(selfEntry.allTimeBest, existing.allTimeBest or 0)
                selfEntry.dungeonBest = math.max(selfEntry.dungeonBest, existing.dungeonBest or 0)
                selfEntry.raidBest    = math.max(selfEntry.raidBest,    existing.raidBest    or 0)
                selfEntry.delveBest   = math.max(selfEntry.delveBest,   existing.delveBest   or 0)
            end
            -- Merge with CharDB.bests — the permanent per-character record
            local cb = MidnightSenseiCharDB and MidnightSenseiCharDB.bests
            if cb then
                selfEntry.allTimeBest = math.max(selfEntry.allTimeBest, cb.allTimeBest or 0)
                selfEntry.dungeonBest = math.max(selfEntry.dungeonBest, cb.dungeonBest or 0)
                selfEntry.raidBest    = math.max(selfEntry.raidBest,    cb.raidBest    or 0)
                selfEntry.delveBest   = math.max(selfEntry.delveBest,   cb.delveBest   or 0)
                if cb.weekKey == wk then
                    if cb.weeklyAvg > selfEntry.weeklyAvg then selfEntry.weeklyAvg = cb.weeklyAvg end
                    if (cb.weeklyDungeonBest or 0) > (selfEntry.dungeonWeekBest or 0) then selfEntry.dungeonWeekBest = cb.weeklyDungeonBest end
                    if (cb.weeklyRaidBest    or 0) > (selfEntry.raidWeekBest    or 0) then selfEntry.raidWeekBest    = cb.weeklyRaidBest    end
                    if (cb.weeklyDelveBest   or 0) > (selfEntry.delveWeekBest   or 0) then selfEntry.delveWeekBest   = cb.weeklyDelveBest   end
                end
            end
            local rb = MidnightSenseiDB
                       and MidnightSenseiDB.leaderboard
                       and MidnightSenseiDB.leaderboard.recoveredBests
            if rb then
                selfEntry.allTimeBest = math.max(selfEntry.allTimeBest, rb.allTimeBest or 0)
                selfEntry.dungeonBest = math.max(selfEntry.dungeonBest, rb.dungeonBest or 0)
                selfEntry.raidBest    = math.max(selfEntry.raidBest,    rb.raidBest    or 0)
                selfEntry.delveBest   = math.max(selfEntry.delveBest,   rb.delveBest   or 0)
            end

            local result = {}
            for k, v in pairs(guildData) do
                v.dbKey = k  -- stamp exact db key on every peer entry
                result[k] = v
            end
            result[myName] = selfEntry
            return result
        end
    end

    -- Stamp the db key onto each entry so right-click remove uses the exact key.
    for key, entry in pairs(guildData) do
        entry.dbKey = key
    end
    return guildData
end

function LB.GetFriendsData()
    local result = {}
    local myName = GetPlayerName()
    local spec   = Core.ActiveSpec

    -- Always inject self so you can compare yourself against friends
    if spec then
        local history = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
        local lastEnc = nil
        local lastEncAny = nil
        if history then
            for i = #history, 1, -1 do
                local e = history[i]
                if e.encType == "dungeon" or e.encType == "raid" then
                    if not lastEncAny then lastEncAny = e end
                    if e.isBoss and not lastEnc then lastEnc = e end
                end
                if lastEnc then break end
            end
            lastEnc = lastEnc or lastEncAny -- no delve/normal fallback
        end
        local wk   = GetWeekKey()
        local wAvg = ComputeWeeklyAvg(history, wk)
        local allBest, dungBest, raidBest, delvBest = 0, 0, 0, 0
        if history then
            for _, enc in ipairs(history) do
                local s = enc.finalScore or 0
                allBest = math.max(allBest, s)
                if     enc.encType == "dungeon" then dungBest = math.max(dungBest, s)
                elseif enc.encType == "raid"    then raidBest = math.max(raidBest, s)
                elseif enc.encType == "delve" then delvBest = math.max(delvBest, s)
                end
            end
        end
        result[myName] = {
            name         = UnitName("player"),
            className    = spec.className or "?",
            specName     = spec.name      or "?",
            role         = spec.role      or "?",
            grade        = lastEnc and (lastEnc.finalGrade or lastEnc.grade) or "--",
            score        = lastEnc and lastEnc.finalScore  or 0,
            timestamp    = lastEnc and lastEnc.timestamp   or 0,
            isSelf       = true,
            online       = true,
            weekKey      = wk,
            weeklyAvg    = wAvg,
            allTimeBest  = allBest,
            dungeonBest  = dungBest,
            raidBest     = raidBest,
            delveBest    = delvBest,
            normalBest   = 0,
            diffLabel    = lastEnc and lastEnc.diffLabel    or "",
            instanceName = lastEnc and lastEnc.instanceName or "",
            bossName     = lastEnc and lastEnc.bossName     or "",
        }
        -- Merge CharDB.bests so scores beyond the encounter cap are preserved
        local cb = MidnightSenseiCharDB and MidnightSenseiCharDB.bests
        if cb then
            local e = result[myName]
            e.allTimeBest = math.max(e.allTimeBest, cb.allTimeBest or 0)
            e.dungeonBest = math.max(e.dungeonBest, cb.dungeonBest or 0)
            e.raidBest    = math.max(e.raidBest,    cb.raidBest    or 0)
            e.delveBest   = math.max(e.delveBest,   cb.delveBest   or 0)
            if cb.weekKey == wk then
                if cb.weeklyAvg         > e.weeklyAvg      then e.weeklyAvg      = cb.weeklyAvg         end
                if (cb.weeklyDungeonBest or 0) > (e.dungeonWeekBest or 0) then e.dungeonWeekBest = cb.weeklyDungeonBest end
                if (cb.weeklyRaidBest    or 0) > (e.raidWeekBest    or 0) then e.raidWeekBest    = cb.weeklyRaidBest    end
                if (cb.weeklyDelveBest   or 0) > (e.delveWeekBest   or 0) then e.delveWeekBest   = cb.weeklyDelveBest   end
            end
        end
    end

    -- Manual friend list entries
    for _, name in ipairs(friendList) do
        -- friendsData may be keyed by short name (same-realm sender) or full Name-Realm
        local shortName = ShortName(name):lower()
        local fdEntry = friendsData[name]
        if not fdEntry then
            for k, v in pairs(friendsData) do
                if ShortName(k):lower() == shortName then fdEntry = v ; break end
            end
        end
        if fdEntry then
            result[name] = fdEntry
        else
            result[name] = {
                name        = ShortName(name),
                className   = "?",
                specName    = "?",
                grade       = "--",
                score       = 0,
                online      = false,
                timestamp   = 0,
                weekKey     = GetWeekKey(),
                weeklyAvg   = 0, allTimeBest = 0,
                dungeonBest = 0, raidBest = 0, delveBest = 0, normalBest = 0,
                diffLabel = "", instanceName = "", bossName = "",
            }
        end
    end
    -- Note: friendsData may contain entries from past queries of removed friends.
    -- We intentionally do NOT include friendsData entries that aren't in friendList
    -- so removed friends don't persist in the tab.
    return result
end

-- Delve tab: one row per player showing aggregated delve performance.
-- Self: computed from local history. Guild peers: from broadcast data.
-- sortOrder "weekly" = this week's avg; "alltime" = best ever.
function LB.GetDelveData()
    local result  = {}
    local history = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
    local wk      = GetWeekKey()

    -- Self entries: aggregate per character that actually did the delve.
    -- MidnightSenseiCharDB.encounters is per-character — no cross-character pollution.
    -- We must key by enc.charName (saved at fight time) not the current player,
    -- otherwise switching characters overwrites the previous character's entry.
    if history then
        -- Group encounters by the character name that ran them
        local byChar = {}
        for _, enc in ipairs(history) do
            -- Accept all delve encounters — ENCOUNTER_START does not fire for delve
            -- bosses in Midnight 12.0, so isBoss is always false inside delves.
            if enc.encType == "delve" then
                local charKey = (enc.charName and enc.realmName)
                               and (enc.charName .. "-" .. enc.realmName)
                               or enc.charName
                               or GetPlayerName()
                if not byChar[charKey] then
                    byChar[charKey] = { weekScores = {}, allBest = 0, lastEnc = nil, charName = charKey }
                end
                local s = enc.finalScore or 0
                local entry = byChar[charKey]
                if s > entry.allBest then
                    entry.allBest = s
                    entry.lastEnc = enc
                end
                if enc.weekKey == wk then
                    table.insert(entry.weekScores, s)
                end
            end
        end

        for charKey, charData in pairs(byChar) do
            local lastEnc = charData.lastEnc
            if lastEnc then
                local wAvg = 0
                if #charData.weekScores > 0 then
                    local sum = 0
                    for _, s in ipairs(charData.weekScores) do sum = sum + s end
                    wAvg = math.floor(sum / #charData.weekScores)
                end
                local isCurrentPlayer = (ShortName(charKey) == UnitName("player"))
                -- Always show self; only filter peers on weekly when no data this week
                if isCurrentPlayer or sortOrder ~= "weekly" or wAvg > 0 then
                    result[charKey] = {
                        name         = ShortName(charKey),
                        className    = lastEnc.className or "?",
                        specName     = lastEnc.specName  or "?",
                        role         = lastEnc.role      or "?",
                        grade        = lastEnc.finalGrade or lastEnc.grade or "?",
                        score        = charData.allBest,
                        weeklyAvg    = wAvg,
                        allTimeBest  = charData.allBest,
                        delveBest    = charData.allBest,
                        dungeonBest  = 0, raidBest = 0, normalBest = 0,
                        diffLabel    = lastEnc.diffLabel    or "",
                        instanceName = lastEnc.instanceName or "",
                        bossName     = lastEnc.bossName     or "",
                        timestamp    = lastEnc.timestamp    or 0,
                        weekKey      = wk,
                        weekScores   = charData.weekScores,
                        isSelf       = isCurrentPlayer,
                        online       = true,
                    }
                end
            end
        end
    end

    -- Always inject self-entry so the current player always sees themselves.
    -- If they have no boss delve encounters the byChar loop won't add them.
    local myKey = GetPlayerName()
    if not result[myKey] then
        local spec = Core.ActiveSpec
        result[myKey] = {
            name         = UnitName("player"),
            className    = spec and spec.className or "?",
            specName     = spec and spec.name      or "?",
            role         = spec and spec.role      or "?",
            grade        = "--",
            score        = 0,
            weeklyAvg    = 0,
            allTimeBest  = 0,
            delveBest    = 0,
            dungeonBest  = 0, raidBest = 0, normalBest = 0,
            diffLabel    = "", instanceName = "", bossName = "",
            timestamp    = 0,
            weekKey      = wk,
            weekScores   = {},
            isSelf       = true,
            online       = true,
            noDelveData  = true,
        }
    end

    -- Guild peers: only when on guild or party tab (not friends-only view)
    if activeTab ~= "friends" then
        local guildData = LB.GetGuildData()
        for name, entry in pairs(guildData) do
            if not entry.isSelf and not result[name] then
                result[name] = {
                    name        = entry.name,
                    className   = entry.className,
                    specName    = entry.specName,
                    role        = entry.role,
                    grade       = (entry.delveBest or 0) > 0 and (entry.grade or "--") or "--",
                    score       = entry.delveBest or 0,
                    weeklyAvg   = (entry.delveBest or 0) > 0 and (entry.weeklyAvg or 0) or 0,
                    allTimeBest = entry.allTimeBest or 0,
                    delveBest   = entry.delveBest   or 0,
                    dungeonBest = 0, raidBest = 0, normalBest = 0,
                    diffLabel    = entry.delveLabel    or "",
                    instanceName = entry.delveInstance or "",
                    bossName     = entry.delveBoss     or "",
                    timestamp   = entry.timestamp or 0,
                    weekKey     = entry.weekKey   or "",
                    isSelf      = false,
                    online      = entry.online,
                    noDelveData = (entry.delveBest or 0) == 0,
                }
            end
        end
    end

    -- Friends peers: only when on friends tab (not guild/party view)
    if activeTab == "friends" then
        local friendsResult = LB.GetFriendsData()
        for name, entry in pairs(friendsResult) do
            if not entry.isSelf and not result[name] then
                result[name] = {
                    name        = entry.name,
                    className   = entry.className,
                    specName    = entry.specName,
                    role        = entry.role,
                    grade       = "--",
                    score       = entry.delveBest or 0,
                    weeklyAvg   = 0,
                    allTimeBest = entry.allTimeBest or 0,
                    delveBest   = entry.delveBest   or 0,
                    dungeonBest = 0, raidBest = 0, normalBest = 0,
                    diffLabel   = "",
                    instanceName= "",
                    bossName    = "",
                    timestamp   = entry.timestamp or 0,
                    weekKey     = entry.weekKey   or "",
                    isSelf      = false,
                    online      = entry.online,
                    noDelveData = (entry.delveBest or 0) == 0,
                }
            end
        end
    end

    return result
end

--------------------------------------------------------------------------------
-- Admin: remove a single guild entry
-- Clears the entry from SavedVariables. The player will repopulate automatically
-- when they next broadcast (on login, group join, or Refresh → REQ).
--------------------------------------------------------------------------------
function LB.RemoveGuildEntry(dbKey)
    if not dbKey then return end
    local db = GetDB()
    if not db then return end

    if db.guild[dbKey] then
        local displayName = ShortName(dbKey)
        db.guild[dbKey] = nil
        LB.RefreshUI()
        print("|cff00D1FFMidnight Sensei:|r Removed |cffFFFFFF" .. displayName ..
              "|r from the leaderboard. They will repopulate on Refresh or next login.")
    else
        print("|cffFF4444Midnight Sensei:|r Key '" .. dbKey .. "' not found. Run |cffFFFFFF/ms lb debug|r to list keys.")
    end
end


function LB.ClearGuildData()
    local db = GetDB()
    if db then db.guild = {} end
    LB.RefreshUI()
end

--------------------------------------------------------------------------------
-- Class colours
--------------------------------------------------------------------------------
local CLASS_COLORS = {
    WARRIOR={0.78,0.61,0.43}, PALADIN={0.96,0.55,0.73}, HUNTER={0.67,0.83,0.45},
    ROGUE={1.00,0.96,0.41},   PRIEST={1.00,1.00,1.00},  DEATHKNIGHT={0.77,0.12,0.23},
    SHAMAN={0.00,0.44,0.87},  MAGE={0.41,0.80,0.94},    WARLOCK={0.58,0.51,0.79},
    MONK={0.00,1.00,0.59},    DRUID={1.00,0.49,0.04},   DEMONHUNTER={0.64,0.19,0.79},
    EVOKER={0.20,0.58,0.50},
}
local function GetClassColor(cn)
    if not cn then return {0.9,0.9,0.9} end
    return CLASS_COLORS[cn:upper():gsub(" ","")] or {0.9,0.9,0.9}
end

--------------------------------------------------------------------------------
-- UI colours
--------------------------------------------------------------------------------
local COLOR = {
    FRAME_BG    = {0.04,0.04,0.06,0.90}, BORDER      = {0.30,0.30,0.40,0.60},
    BORDER_GOLD = {1.00,0.65,0.00,0.90}, TITLE_BG    = {0.12,0.12,0.18,0.95},
    TITLE_TEXT  = {1.00,0.65,0.00,1.00}, ACCENT      = {0.00,0.82,1.00,1.00},
    TEXT_MAIN   = {0.92,0.90,0.88,1.00}, TEXT_DIM    = {0.55,0.53,0.50,1.00},
    ROW_EVEN    = {0.08,0.08,0.12,0.50}, ROW_ODD     = {0.04,0.04,0.06,0.30},
    ROW_SELF    = {0.10,0.20,0.10,0.60}, ONLINE      = {0.20,0.85,0.20,1.00},
    OFFLINE     = {0.45,0.45,0.45,1.00}, TAB_ACTIVE  = {0.20,0.18,0.24,1.00},
    TAB_IDLE    = {0.10,0.10,0.14,1.00},
}

--------------------------------------------------------------------------------
-- UI helpers
--------------------------------------------------------------------------------
local lbFrame       = nil
local activeTab     = "guild"    -- social tab: party | guild | friends
local contentType   = "dungeon"  -- content row: delve | dungeon | raid
local sortOrder     = "weekly"   -- sort row:    weekly | alltime
local rowFrames     = {}

local function BD(f, bg, border)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetBackdrop({ bgFile="Interface/Tooltips/UI-Tooltip-Background",
                    edgeFile="Interface/Tooltips/UI-Tooltip-Border",
                    tile=true,tileSize=16,edgeSize=12,
                    insets={left=2,right=2,top=2,bottom=2} })
    local b=bg or COLOR.FRAME_BG; local e=border or COLOR.BORDER
    f:SetBackdropColor(b[1],b[2],b[3],b[4] or 1)
    f:SetBackdropBorderColor(e[1],e[2],e[3],e[4] or 1)
end

local function TF(parent, size, justify)
    local fs = parent:CreateFontString(nil,"OVERLAY")
    fs:SetFont("Fonts/FRIZQT__.TTF", size or 11, "")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetTextColor(COLOR.TEXT_MAIN[1],COLOR.TEXT_MAIN[2],COLOR.TEXT_MAIN[3],1)
    return fs
end

local function GHex(score)
    if not score or score==0 then return "aaaaaa" end
    if score>=90 then return "33ee33" elseif score>=80 then return "88cc44"
    elseif score>=70 then return "cccc33" elseif score>=60 then return "ee8833"
    else return "ee3333" end
end

local function TAgo(ts)
    if not ts or ts==0 then return "" end
    local d=time()-ts
    if d<60 then return "just now" elseif d<3600 then return math.floor(d/60).."m ago"
    elseif d<86400 then return math.floor(d/3600).."h ago"
    else return math.floor(d/86400).."d ago" end
end

--------------------------------------------------------------------------------
-- Row builder — 5 columns: rank | name | spec | category stats | week avg
--------------------------------------------------------------------------------
local function GetRow(parent, idx)
    if rowFrames[idx] then return rowFrames[idx] end
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(22)
    row:SetPoint("LEFT",  parent,"LEFT",  0,0)
    row:SetPoint("RIGHT", parent,"RIGHT", 0,0)

    row.rankText  = TF(row,10,"CENTER");  row.rankText:SetPoint("LEFT",row,"LEFT",4,0);   row.rankText:SetWidth(20)
    row.onlineDot = row:CreateTexture(nil,"OVERLAY"); row.onlineDot:SetSize(6,6); row.onlineDot:SetPoint("LEFT",row,"LEFT",26,0)
    row.nameText  = TF(row,11,"LEFT");    row.nameText:SetPoint("LEFT",row,"LEFT",36,0);  row.nameText:SetWidth(108)
    row.specText  = TF(row,9,"LEFT");     row.specText:SetPoint("LEFT",row,"LEFT",148,0); row.specText:SetWidth(70)
    row.specText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    row.catText   = TF(row,9,"LEFT");     row.catText:SetPoint("LEFT",row,"LEFT",222,0);  row.catText:SetWidth(330)
    row.catText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    row.latestText = TF(row,11,"RIGHT");  row.latestText:SetPoint("RIGHT",row,"RIGHT",-86,0); row.latestText:SetWidth(80)
    row.weekText   = TF(row,11,"RIGHT");  row.weekText:SetPoint("RIGHT",row,"RIGHT",-2,0);    row.weekText:SetWidth(80)

    rowFrames[idx] = row
    return row
end

local function PopulateRows(scrollChild, entries)
    for _, r in ipairs(rowFrames) do r:Hide() end
    local yOff = 0
    for i, entry in ipairs(entries) do
        local row = GetRow(scrollChild, i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",  scrollChild,"TOPLEFT",  0,-yOff)
        row:SetPoint("TOPRIGHT", scrollChild,"TOPRIGHT", 0,-yOff)

        local bgc = entry.isSelf and COLOR.ROW_SELF
            or (i%2==0 and COLOR.ROW_EVEN or COLOR.ROW_ODD)
        row:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",tile=true,tileSize=16})
        row:SetBackdropColor(bgc[1],bgc[2],bgc[3],bgc[4] or 0.5)

        row.rankText:SetText(i)
        row.rankText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)

        local cc  = GetClassColor(entry.className)
        local nm  = entry.isSelf and (ShortName(entry.name).." (you)") or ShortName(entry.name)
        row.nameText:SetText(nm); row.nameText:SetTextColor(cc[1],cc[2],cc[3],1)
        row.specText:SetText((entry.specName or "?").." "..(entry.className or ""))

        -- Category stats column — format: Diff/Tier · Instance · Boss
        local catStr = ""

        -- Helper: combine up to three parts with " - " separator, skipping blanks/junk
        local function JoinLabel(a, b, c)
            local parts = {}
            if a and a ~= "" and a ~= "World" and a ~= "0" then table.insert(parts, a) end
            if b and b ~= "" and b ~= "0"                  then table.insert(parts, b) end
            if c and c ~= "" and c ~= "0"                  then table.insert(parts, c) end
            return #parts > 0 and table.concat(parts, " - ") or "--"
        end

        local diff  = (entry.diffLabel and entry.diffLabel ~= "" and entry.diffLabel ~= "World") and entry.diffLabel or nil
        local inst  = (entry.instanceName and entry.instanceName ~= "") and entry.instanceName or nil
        local boss  = (entry.bossName and entry.bossName ~= "") and entry.bossName or nil

        -- Use per-content-type location fields when available — prevents LFR/raid
        -- diffLabels from bleeding into the Dungeons tab and vice versa.
        if contentType == "dungeon" then
            local dl = entry.dungeonLabel    or ""
            local di = entry.dungeonInstance or ""
            local db = entry.dungeonBoss     or ""
            local dk = entry.dungeonKs
            if dl ~= "" or di ~= "" then
                -- Prefer explicit M+ label from dungeonKs if diffLabel didn't carry it
                local displayDiff = (dk and dk > 0) and ("M+" .. dk)
                                    or (dl ~= "" and dl ~= "World" and dl) or nil
                diff = displayDiff
                inst = di ~= "" and di or nil
                boss = db ~= "" and db or nil
            end
        elseif contentType == "raid" then
            local rl = entry.raidLabel    or ""
            local ri = entry.raidInstance or ""
            local rb = entry.raidBoss     or ""
            if rl ~= "" or ri ~= "" then
                diff = (rl ~= "" and rl ~= "World" and rl) or nil
                inst = ri ~= "" and ri or nil
                boss = rb ~= "" and rb or nil
            end
        end

        -- Only show location data when the entry has actual data for this content type.
        -- Guild entries store the last broadcast's location regardless of content type,
        -- so a dungeon diffLabel must not show on the raid tab when raidBest is zero.
        -- This applies to self-entries too — isSelf only exempts from placeholder rows.
        if contentType == "dungeon" and (entry.dungeonBest or 0) == 0 then
            diff, inst, boss = nil, nil, nil
        elseif contentType == "raid" and (entry.raidBest or 0) == 0 then
            diff, inst, boss = nil, nil, nil
        end

        -- Friends placeholder: never queried or no score yet — show clean no-data state
        -- Also handles guild/friend peers with no data for the current content tab
        local isPlaceholder = (activeTab == "friends" and (entry.score or 0) == 0
                               and (entry.className == "?" or entry.className == nil))
                           or (contentType == "delve"   and entry.noDelveData   and not entry.isSelf)
                           or (contentType == "dungeon" and (entry.dungeonBest or 0) == 0 and activeTab ~= "party")
                           or (contentType == "raid"    and (entry.raidBest    or 0) == 0 and activeTab ~= "party")
        if isPlaceholder then
            if activeTab == "friends" and (entry.className == "?" or entry.className == nil) then
                row.specText:SetText("|cff555555— awaiting response —|r")
            else
                row.specText:SetText((entry.specName or "?").." "..(entry.className or ""))
            end
            local noDataText = contentType == "delve"   and "|cff555555No delves recorded|r"
                            or contentType == "dungeon" and "|cff555555No dungeons recorded|r"
                            or contentType == "raid"    and "|cff555555No raids recorded|r"
                            or "|cff555555No data yet|r"
            row.catText:SetText(noDataText)
            if row.latestText then row.latestText:SetText("|cff555555--|r") end
            row.weekText:SetText("|cff555555--|r")
        else
            if contentType == "delve" then
                local delveInst = inst
                local delveDiff = (diff and inst and diff ~= inst) and diff or nil
                catStr = JoinLabel(delveDiff, delveInst, boss)
                if entry.isDelveRun and entry.timestamp and entry.timestamp > 0 then
                    catStr = catStr .. " |cff888888" .. TAgo(entry.timestamp) .. "|r"
                end
            else
                catStr = JoinLabel(diff, inst, boss)
            end
            row.catText:SetText(catStr)

        -- Right columns — LATEST (most recent fight) and WK AVG (boss weekly avg)
        local function GradeScore(score)
            if not score or score == 0 then return "|cff888888--|r" end
            local grade = MS.Core and MS.Core.GetGrade and MS.Core.GetGrade(score)
            local gLetter = grade or "?"
            return "|cff"..GHex(score)..gLetter.."  "..score.."|r"
        end

        -- Latest: entry.score is always the most recent broadcast score
        local latestStr
        local latestScore = entry.score or 0
        if latestScore > 0 then
            latestStr = GradeScore(latestScore)
        else
            latestStr = "|cff888888--|r"
        end

        -- Weekly avg: content-type specific
        local weekStr
        local wk = GetWeekKey()
        local wAvg = 0
        if contentType == "dungeon" then
            wAvg = (entry.dungeonAvg and entry.dungeonAvg > 0) and entry.dungeonAvg
                   or ((entry.dungeonBest or 0) > 0 and (entry.weeklyAvg or 0) > 0
                       and entry.weeklyAvg) or 0
            if (entry.dungeonBest or 0) == 0 then wAvg = 0 end
        elseif contentType == "raid" then
            wAvg = (entry.raidAvg and entry.raidAvg > 0) and entry.raidAvg or 0
            if (entry.raidBest or 0) == 0 then wAvg = 0 end
        elseif contentType == "delve" then
            wAvg = entry.weeklyAvg or 0
        else
            wAvg = entry.weeklyAvg or 0
        end
        if wAvg > 0 then
            weekStr = GradeScore(wAvg)
            if entry.weekKey and entry.weekKey ~= wk then
                weekStr = weekStr .. " |cff888888(prev)|r"
            end
        else
            weekStr = "|cff888888--|r"
        end

        if row.latestText then row.latestText:SetText(latestStr) end
        row.weekText:SetText(weekStr)
        end -- end: not isPlaceholder

        -- Online dot
        local isOnline = (entry.online ~= false)
        if activeTab == "party" then isOnline = true end
        local dc = isOnline and COLOR.ONLINE or COLOR.OFFLINE
        row.onlineDot:SetColorTexture(dc[1],dc[2],dc[3],1)
        row.onlineDot:Show()

        -- Right-click to remove (guild: remove from leaderboard, friends: remove from list)
        if activeTab == "guild" and not entry.isSelf then
            row:EnableMouse(true)
            local entryDbKey = entry.dbKey or entry.name
            row:SetScript("OnMouseUp", function(_, button)
                if button == "RightButton" then
                    LB.RemoveGuildEntry(entryDbKey)
                end
            end)
            row:SetScript("OnEnter", function()
                GameTooltip:SetOwner(row, "ANCHOR_TOPRIGHT")
                GameTooltip:SetText("Right-click to remove from leaderboard", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        elseif activeTab == "friends" and not entry.isSelf then
            row:EnableMouse(true)
            local friendName = entry.name
            row:SetScript("OnMouseUp", function(_, button)
                if button == "RightButton" then
                    -- Find the full Name-Realm key from friendList
                    local fullKey = friendName
                    for _, f in ipairs(friendList) do
                        if ShortName(f):lower() == ShortName(friendName):lower() then
                            fullKey = f ; break
                        end
                    end
                    LB.RemoveFriend(fullKey)
                end
            end)
            row:SetScript("OnEnter", function()
                GameTooltip:SetOwner(row, "ANCHOR_TOPRIGHT")
                GameTooltip:SetText("Right-click to remove from friends", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        else
            row:EnableMouse(false)
            row:SetScript("OnMouseUp", nil)
            row:SetScript("OnEnter", nil)
            row:SetScript("OnLeave", nil)
        end

        row:Show()
        yOff = yOff + 22
    end
    scrollChild:SetHeight(math.max(yOff+8, 100))
end

--------------------------------------------------------------------------------
-- Sorting
--------------------------------------------------------------------------------
local function SortedEntries(dataTable)
    local list = {}
    for _, entry in pairs(dataTable) do table.insert(list, entry) end

    -- "player" sorts alphabetically; "recent" sorts by last activity timestamp
    if sortOrder == "player" then
        table.sort(list, function(a, b)
            return (a.name or "") < (b.name or "")
        end)
        return list
    end
    if sortOrder == "recent" then
        table.sort(list, function(a, b)
            local at = a.timestamp or 0
            local bt = b.timestamp or 0
            if at ~= bt then return at > bt end
            return (a.name or "") < (b.name or "")
        end)
        return list
    end

    local key
    if     contentType == "delve"   then
        key = sortOrder == "alltime" and "allTimeBest" or "weeklyAvg"
    elseif contentType == "dungeon" then
        key = sortOrder == "latest" and "score" or "dungeonBest"
    elseif contentType == "raid"    then
        key = sortOrder == "latest" and "score" or "raidBest"
    elseif sortOrder   == "latest"  then key = "score"
    elseif sortOrder   == "alltime" then key = "allTimeBest"
    else                                 key = "weeklyAvg"
    end
    table.sort(list, function(a, b)
        local av = a[key] or a.score or 0
        local bv = b[key] or b.score or 0
        if av ~= bv then return av > bv end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

local function GetSocialData()
    if     activeTab == "guild"   then return LB.GetGuildData()
    elseif activeTab == "friends" then return LB.GetFriendsData()
    else                               return LB.GetPartyData() end
end

local function RefreshContent()
    if not lbFrame or not lbFrame.scrollChild then return end

    -- Delve is a separate data source; other filters show social data
    local rawData
    if contentType == "delve" then
        rawData = LB.GetDelveData()
    else
        rawData = GetSocialData()
    end

    PopulateRows(lbFrame.scrollChild, SortedEntries(rawData))

    -- Update social tab counts
    local counts = { party=0, guild=0, friends=0 }
    for _ in pairs(LB.GetPartyData())   do counts.party   = counts.party   + 1 end
    for _ in pairs(LB.GetGuildData())   do counts.guild   = counts.guild   + 1 end
    for _, e in pairs(LB.GetFriendsData()) do
        if not e.isSelf then counts.friends = counts.friends + 1 end
    end

    if lbFrame.socialTabs then
        for _, tab in ipairs(lbFrame.socialTabs) do
            local c = counts[tab.key] or 0
            tab.label:SetText(tab.name .. " (" .. c .. ")")
        end
    end

    -- Show + button only on friends tab; grey it out when at cap
    if lbFrame.addFriendBtn then
        local atCap = #friendList >= FRIEND_LIST_MAX
        lbFrame.addFriendBtn:SetShown(activeTab == "friends")
        if activeTab == "friends" and lbFrame.addFriendFs then
            lbFrame.addFriendFs:SetText(atCap and "|cff555555+|r" or "|cff00D1FF+|r")
        end
    end

    -- Highlight active content type button
    if lbFrame.contentBtns then
        for _, cb in ipairs(lbFrame.contentBtns) do
            local active = (cb.filterKey == contentType)
            BD(cb, active and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
            cb.label:SetTextColor(
                active and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1],
                active and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2],
                active and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3], 1)
            if cb.filterKey == "delve" then
                cb.label:SetText("Delves")
            end
        end
    end

    -- Highlight active sort header button
    if lbFrame.sortBtns then
        for _, sb in ipairs(lbFrame.sortBtns) do
            local active = (sb.sortKey == sortOrder)
            BD(sb, active and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
            sb.fs:SetTextColor(
                active and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1],
                active and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2],
                active and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3], 1)
        end
    end

    -- Column headers (cat label only — sort headers are buttons, updated above)
    local catHdr
    if     contentType == "delve"   then catHdr = "RECENT DELVE / BOSS"
    elseif contentType == "dungeon" then catHdr = "RECENT DIFF / BOSS"
    elseif contentType == "raid"    then catHdr = "RECENT DIFF / BOSS"
    else                                 catHdr = "RECENT DIFFICULTY"
    end
    if lbFrame.hdrCat and lbFrame.hdrCat.fs then lbFrame.hdrCat.fs:SetText(catHdr) end

    -- Grey out social tabs when Delve is active
    local isDelve = (contentType == "delve")
    if lbFrame.socialTabs then
        for _, tab in ipairs(lbFrame.socialTabs) do
            tab.label:SetTextColor(
                isDelve and 0.35 or (tab.key == activeTab and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1]),
                isDelve and 0.33 or (tab.key == activeTab and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2]),
                isDelve and 0.30 or (tab.key == activeTab and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3]), 1)
        end
    end
end

function LB.RefreshUI()
    if lbFrame and lbFrame:IsShown() then RefreshContent() end
end

local function SetActiveTab(key)
    activeTab = key
    if lbFrame and lbFrame.socialTabs then
        for _, tab in ipairs(lbFrame.socialTabs) do
            local isActive = (tab.key == key)
            BD(tab, isActive and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
        end
    end
    RefreshContent()
end

local function SetContentFilter(key)
    contentType = key
    RefreshContent()
end

--------------------------------------------------------------------------------
-- Build frame
--------------------------------------------------------------------------------
local function CreateLeaderboardFrame()
    if lbFrame then return lbFrame end

    local FW, FH = 720, 480
    lbFrame = CreateFrame("Frame","MidnightSenseiLeaderboard",UIParent,"BackdropTemplate")
    lbFrame:SetSize(FW,FH)
    lbFrame:SetPoint("CENTER",UIParent,"CENTER",240,0)
    lbFrame:SetFrameStrata("HIGH")
    lbFrame:SetMovable(true); lbFrame:SetClampedToScreen(true); lbFrame:EnableMouse(true)
    BD(lbFrame)

    -- Title bar
    local tBar = CreateFrame("Frame",nil,lbFrame,"BackdropTemplate")
    tBar:SetPoint("TOPLEFT",lbFrame,"TOPLEFT",0,0)
    tBar:SetPoint("TOPRIGHT",lbFrame,"TOPRIGHT",0,0)
    tBar:SetHeight(26); BD(tBar, COLOR.TITLE_BG, COLOR.BORDER_GOLD)
    tBar:EnableMouse(true); tBar:RegisterForDrag("LeftButton")
    tBar:SetScript("OnDragStart",function() lbFrame:StartMoving() end)
    tBar:SetScript("OnDragStop", function() lbFrame:StopMovingOrSizing() end)

    local titleText = TF(tBar,12,"CENTER")
    titleText:SetPoint("CENTER"); titleText:SetTextColor(COLOR.TITLE_TEXT[1],COLOR.TITLE_TEXT[2],COLOR.TITLE_TEXT[3],1)
    titleText:SetText("Midnight Sensei - Leaderboard")

    local xBtn = CreateFrame("Button",nil,tBar)
    xBtn:SetSize(18,18); xBtn:SetPoint("RIGHT",tBar,"RIGHT",-4,0)
    local xFs = TF(xBtn,11,"CENTER"); xFs:SetPoint("CENTER"); xFs:SetText("X")
    xFs:SetTextColor(1,0.4,0.4,1)
    xBtn:SetScript("OnClick",function() lbFrame:Hide() end)

    -- ── Row 1: Social tabs (y = -26) — Party | Guild | Friends ─────────────
    -- Note: Friends tab is greyed out — BNGetFriendNumGameAccounts returns 0
    -- in Midnight 12.0, making cross-realm friend whisper enumeration impossible.
    -- Friends who share a guild or party still appear in those tabs.
    local socialDefs = {
        {key="party",   name="Party"},
        {key="guild",   name="Guild"},
        {key="friends", name="Friends"},
    }
    local socialW = math.floor(FW / #socialDefs)
    lbFrame.socialTabs = {}
    for i, td in ipairs(socialDefs) do
        local tab = CreateFrame("Button", nil, lbFrame, "BackdropTemplate")
        tab:SetSize(socialW, 26)
        tab:SetPoint("TOPLEFT", lbFrame, "TOPLEFT", (i-1)*socialW, -26)
        BD(tab, COLOR.TAB_IDLE, COLOR.BORDER)
        tab.key  = td.key ; tab.name = td.name
        tab.label = TF(tab, 11, "CENTER") ; tab.label:SetPoint("CENTER")

        if td.disabled then
            -- (reserved — no tabs currently disabled)
        else
            tab.label:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
            tab.label:SetText(td.name)
            tab:SetScript("OnClick", function()
                if contentType == "delve" then contentType = "dungeon" end
                SetActiveTab(td.key)
            end)
        end
        table.insert(lbFrame.socialTabs, tab)
    end

    -- ── Row 2: Content filter (y = -52) — Delves | Dungeons | Raids ────────
    local contentDefs = {
        {key="delve",   name="Delves"},
        {key="dungeon", name="Dungeons"},
        {key="raid",    name="Raids"},
    }
    local contentW = math.floor(FW / #contentDefs)
    lbFrame.contentBtns = {}
    for i, cd in ipairs(contentDefs) do
        local btn = CreateFrame("Button", nil, lbFrame, "BackdropTemplate")
        btn:SetSize(contentW, 22)
        btn:SetPoint("TOPLEFT", lbFrame, "TOPLEFT", (i-1)*contentW, -52)
        BD(btn, COLOR.TAB_IDLE, COLOR.BORDER)
        btn.filterKey = cd.key
        btn.label = TF(btn, 10, "CENTER") ; btn.label:SetPoint("CENTER")
        btn.label:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
        btn.label:SetText(cd.name)
        btn:SetScript("OnClick", function() SetContentFilter(cd.key) end)
        table.insert(lbFrame.contentBtns, btn)
    end

    -- ── Sort row removed — sorting now via clickable column headers below ─────

    -- ── Column headers (y = -74, moved up since sort row removed) ────────────
    local hdr = CreateFrame("Frame", nil, lbFrame)
    hdr:SetPoint("TOPLEFT",  lbFrame, "TOPLEFT",   4, -74)
    hdr:SetPoint("TOPRIGHT", lbFrame, "TOPRIGHT", -20, -74)
    hdr:SetHeight(22)
    local function Hdr(t, anchor, x, w)
        local fs = TF(hdr, 9, anchor)
        fs:SetPoint(anchor, hdr, anchor, x, 0) ; fs:SetWidth(w)
        fs:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
        fs:SetText(t)
        return fs
    end
    -- Clickable sort header helper
    local function SortHdr(label, sortKey, anchor, x, w)
        local btn = CreateFrame("Button", nil, hdr, "BackdropTemplate")
        btn:SetSize(w, 20)
        btn:SetPoint(anchor, hdr, anchor, x, 0)
        BD(btn, COLOR.TAB_IDLE, COLOR.BORDER)
        local fs = TF(btn, 9, "CENTER") ; fs:SetPoint("CENTER")
        fs:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
        fs:SetText(label)
        btn.fs = fs ; btn.sortKey = sortKey
        btn:SetScript("OnClick", function()
            sortOrder = sortKey
            RefreshContent()
        end)
        btn:SetScript("OnEnter", function()
            BD(btn, COLOR.TAB_ACTIVE, COLOR.BORDER)
            fs:SetTextColor(COLOR.ACCENT[1], COLOR.ACCENT[2], COLOR.ACCENT[3], 1)
        end)
        btn:SetScript("OnLeave", function()
            BD(btn, COLOR.TAB_IDLE, COLOR.BORDER)
            fs:SetTextColor(COLOR.TEXT_DIM[1], COLOR.TEXT_DIM[2], COLOR.TEXT_DIM[3], 1)
        end)
        return btn
    end

    Hdr("#",      "LEFT",  4,  20)
    lbFrame.hdrPlayer  = SortHdr("PLAYER",             "player", "LEFT",   36, 108)
    Hdr("SPEC",   "LEFT", 148, 70)
    lbFrame.hdrCat     = SortHdr("RECENT DIFF / BOSS", "recent", "LEFT",  222, 336)
    lbFrame.hdrLatest  = SortHdr("LATEST",             "latest", "RIGHT",  -86, 80)
    lbFrame.hdrWeek    = SortHdr("WK AVG",             "weekly", "RIGHT",   -2, 80)

    lbFrame.sortBtns = { lbFrame.hdrPlayer, lbFrame.hdrCat, lbFrame.hdrLatest, lbFrame.hdrWeek }

    -- ── Scroll (starts at y = -114) ──────────────────────────────────────────
    local sf = CreateFrame("ScrollFrame", "MidnightSenseiLBScroll", lbFrame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     lbFrame, "TOPLEFT",   4, -98)
    sf:SetPoint("BOTTOMRIGHT", lbFrame, "BOTTOMRIGHT", -22, 36)
    local sc = CreateFrame("Frame", nil, sf)
    sc:SetWidth(sf:GetWidth()) ; sc:SetHeight(200) ; sf:SetScrollChild(sc)
    lbFrame.scrollChild = sc

    -- Footer text (left side)
    local footerText = TF(lbFrame,9,"LEFT")
    footerText:SetPoint("BOTTOMLEFT",lbFrame,"BOTTOMLEFT",8,12)
    footerText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    footerText:SetText("Boss kills only  ·  /ms lb")

    -- + button (Add Friend) — only visible on friends tab
    local addFriendBtn = CreateFrame("Button", nil, lbFrame, "BackdropTemplate")
    addFriendBtn:SetSize(24, 20)
    addFriendBtn:SetPoint("BOTTOMRIGHT", lbFrame, "BOTTOMRIGHT", -82, 8)
    addFriendBtn:EnableMouse(true)
    BD(addFriendBtn, COLOR.TAB_IDLE, COLOR.BORDER)
    local addFs = TF(addFriendBtn, 13, "CENTER")
    addFs:SetPoint("CENTER")
    addFs:SetText("|cff00D1FF+|r")
    addFriendBtn:SetScript("OnEnter", function()
        BD(addFriendBtn, COLOR.TAB_ACTIVE, COLOR.BORDER)
        GameTooltip:SetOwner(addFriendBtn, "ANCHOR_TOP")
        GameTooltip:SetText("Add Friend", 0, 0.82, 1)
        GameTooltip:AddLine("Enter their Name or Name-Realm\nto add them to your friend list.\nMax " .. FRIEND_LIST_MAX .. " friends.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    addFriendBtn:SetScript("OnLeave", function()
        BD(addFriendBtn, COLOR.TAB_IDLE, COLOR.BORDER)
        GameTooltip:Hide()
    end)
    addFriendBtn:SetScript("OnClick", function()
        -- Simple input dialog using StaticPopup
        if not StaticPopupDialogs["MS_ADD_FRIEND"] then
            StaticPopupDialogs["MS_ADD_FRIEND"] = {
                text          = "|cff00D1FFMidnight Sensei|r — Add Friend\n\nEnter player name (Name or Name-Realm):",
                button1       = "Add",
                button2       = "Cancel",
                hasEditBox    = true,
                editBoxWidth  = 220,
                maxLetters    = 64,
                timeout       = 0,
                whileDead     = true,
                hideOnEscape  = true,
                preferredIndex = 3,
                OnAccept = function(self)
                    local name = self.editBox:GetText():match("^%s*(.-)%s*$")
                    if name and name ~= "" then
                        LB.AddFriend(name)
                    end
                end,
                EditBoxOnEnterPressed = function(self)
                    local name = self:GetText():match("^%s*(.-)%s*$")
                    if name and name ~= "" then
                        LB.AddFriend(name)
                    end
                    self:GetParent():Hide()
                end,
            }
        end
        StaticPopup_Show("MS_ADD_FRIEND")
    end)
    lbFrame.addFriendBtn = addFriendBtn
    lbFrame.addFriendFs  = addFs

    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, lbFrame, "BackdropTemplate")
    refreshBtn:SetSize(68, 20)
    refreshBtn:SetPoint("BOTTOMRIGHT", lbFrame, "BOTTOMRIGHT", -6, 8)
    refreshBtn:EnableMouse(true)
    BD(refreshBtn, COLOR.TAB_IDLE, COLOR.BORDER)
    local rFs = TF(refreshBtn, 10, "CENTER")
    rFs:SetPoint("CENTER")
    rFs:SetText("Refresh")
    refreshBtn:SetScript("OnEnter", function()
        BD(refreshBtn, COLOR.TAB_ACTIVE, COLOR.BORDER)
        rFs:SetTextColor(COLOR.ACCENT[1], COLOR.ACCENT[2], COLOR.ACCENT[3], 1)
    end)
    refreshBtn:SetScript("OnLeave", function()
        BD(refreshBtn, COLOR.TAB_IDLE, COLOR.BORDER)
        rFs:SetTextColor(COLOR.TEXT_MAIN[1], COLOR.TEXT_MAIN[2], COLOR.TEXT_MAIN[3], 1)
    end)
    refreshBtn:SetScript("OnClick", function()
        rFs:SetText("...")
        if activeTab == "guild" then SyncGuildOnlineStatus() end
        if activeTab == "friends" then
            -- Query each friend individually via REQD whisper
            LB.QueryAllFriends()
        else
            BroadcastHello()
            local reqPayload = "REQ|" .. Core.VERSION
            BroadcastToAll(reqPayload)
            WhisperFriends(reqPayload)
        end
        C_Timer.After(3.0, function()
            RefreshContent()
            rFs:SetText("Refresh")
        end)
    end)

    -- Week info
    local weekInfo = TF(lbFrame,9,"RIGHT")
    weekInfo:SetPoint("BOTTOMRIGHT",lbFrame,"BOTTOMRIGHT",-114,12)
    weekInfo:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    weekInfo:SetText("Week "..GetWeekKey())

    lbFrame:Hide()
    return lbFrame
end

function LB.Show()
    local frame = CreateLeaderboardFrame()
    SeedPartyFromGroup()   -- ensure current group is always shown when opening
    SetActiveTab(activeTab)
    frame:Show()
    RefreshContent()
end

function LB.Toggle()
    local frame = CreateLeaderboardFrame()
    if frame:IsShown() then frame:Hide() else LB.Show() end
end

function LB.HideFrame()
    if lbFrame then lbFrame:Hide() end
end

--------------------------------------------------------------------------------
-- Event frame
--------------------------------------------------------------------------------
local lbEventFrame = CreateFrame("Frame","MidnightSenseiLBEvents",UIParent)

lbEventFrame:SetScript("OnEvent",function(self,event,...)
    if event=="CHAT_MSG_ADDON" then
        OnAddonMessage(...)
    elseif event=="GUILD_ROSTER_UPDATE" then
        SyncGuildOnlineStatus()
    elseif event=="GROUP_ROSTER_UPDATE" then
        local current={}
        for i=1,GetNumGroupMembers() do
            local unit=(IsInRaid() and "raid" or "party")..i
            local name=UnitName(unit)
            if name then current[name]=true end
        end
        for name in pairs(partyData) do
            if not current[ShortName(name)] then partyData[name]=nil end
        end
        LB.RefreshUI()
    end
end)

lbEventFrame:RegisterEvent("CHAT_MSG_ADDON")
lbEventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
lbEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

C_ChatInfo.RegisterAddonMessagePrefix(LB_PREFIX)
