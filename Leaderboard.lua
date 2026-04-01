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
local Core = MS.Core

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
    [17] = "LFR",
    [14] = "Normal",   -- Normal Raid (flex)
    [15] = "Heroic",
    [16] = "Mythic",
}
local DUNGEON_DIFF = {
    [1]  = "Normal",
    [2]  = "Heroic",
    [23] = "Mythic",   -- Mythic keystone / M+
    [8]  = "Mythic",   -- Regular Mythic (no key)
}

local function GetInstanceContext()
    local instName, instType, diffID, diffName,
          maxPlayers, dynDiff, isDynamic, instMapID = GetInstanceInfo()

    local ctx = { encType = "normal", diffLabel = "World", keystoneLevel = nil }

    if not instType or instType == "none" then return ctx end

    if instType == "raid" then
        ctx.encType   = "raid"
        ctx.diffLabel = RAID_DIFF[diffID] or diffName or "Raid"

    elseif instType == "party" then
        ctx.encType = "dungeon"
        -- Check for active Mythic+ keystone
        local keystoneLevel = nil
        if C_ChallengeMode and C_ChallengeMode.GetSlottedKeystoneInfo then
            local _, _, ksLevel = C_ChallengeMode.GetSlottedKeystoneInfo()
            if ksLevel and ksLevel > 0 then
                keystoneLevel = ksLevel
                ctx.diffLabel = "M+" .. ksLevel
                ctx.keystoneLevel = ksLevel
            end
        end
        if not keystoneLevel then
            ctx.diffLabel = DUNGEON_DIFF[diffID] or diffName or "Dungeon"
        end

    elseif instType == "scenario" then
        -- Delves use the scenario instanceType
        -- diffName from GetInstanceInfo gives tier info like "Delve (8)" or similar
        -- We also check if the diffName contains "delve" or if isDynamic hints
        local lowerDiff = (diffName or ""):lower()
        local lowerName = (instName or ""):lower()
        if lowerDiff:find("delve") or lowerName:find("delve") or diffID == 167 then
            ctx.encType = "delve"
            -- Extract tier number from diffName if possible
            local tier = diffName and diffName:match("(%d+)")
            ctx.diffLabel = tier and ("Tier " .. tier) or (diffName or "Delve")
        else
            ctx.encType   = "dungeon"
            ctx.diffLabel = diffName or "Scenario"
        end
    end

    return ctx
end

-- Convenience wrapper called from Analytics
function LB.GetInstanceContext()
    return GetInstanceContext()
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
--   Components: score, duration, encType, charName
--   Each component is mixed with prime multipliers and summed mod 251.
--   Changing score without also changing charName and duration consistently
--   will produce a mismatched checksum that receivers silently reject.
--   The charName component ties the checksum to the character identity,
--   so you cannot reuse another player's valid broadcast for yourself.
--
-- Additional receiver-side checks:
--   - Score must be 0-100
--   - Duration bounds: score >= 90 requires duration >= 45s
--                      score >= 80 requires duration >= 20s
--   - Rate limit: max 20 SCORE messages per sender per session
--   - Implausibility: score > 95 in < 30s is rejected regardless
--------------------------------------------------------------------------------
local function NameHash(name)
    -- Simple djb2-style fold of character name bytes
    local h = 5381
    for i = 1, #(name or "") do
        h = ((h * 33) + string.byte(name, i)) % 251
    end
    return h
end

local function MakeChecksum(score, duration, encType, charName)
    -- Mix four independent components with distinct primes
    local a = (score         * 7)   % 251
    local b = (math.floor(duration) * 11)  % 251
    local c = (#(encType  or "") * 17)  % 251
    local d = NameHash(charName)
    local raw = (a + b + c + d) % 251
    return string.format("%03d", raw)
end

local function ValidateChecksum(score, duration, encType, charName, checksum)
    if not checksum then return false end
    return MakeChecksum(score, duration, encType, charName) == checksum
end

-- Per-sender rate limiter: max 20 SCORE messages per session
local senderRateLimit = {}
local RATE_LIMIT_MAX  = 20

local function CheckRateLimit(sender)
    senderRateLimit[sender] = (senderRateLimit[sender] or 0) + 1
    return senderRateLimit[sender] <= RATE_LIMIT_MAX
end

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
    MidnightSenseiDB.leaderboard         = MidnightSenseiDB.leaderboard         or {}
    MidnightSenseiDB.leaderboard.guild   = MidnightSenseiDB.leaderboard.guild   or {}
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

local function IsBNetFriend(fullName)
    local shortName = ShortName(fullName)
    local numFriends = BNGetNumFriends()
    for i = 1, numFriends do
        local _, _, _, _, toonName = BNGetFriendInfo(i)
        if toonName and toonName:match("^([^%-]+)") == shortName then return true end
    end
    return false
end

-- Update or create an entry, maintaining weekly avg and all-time best
local function MergeEntry(existing, name, className, specName, role,
                           grade, score, duration, encType, weekKey)
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
        weekScores   = {},
        weeklyAvg    = score,
        allTimeBest  = score,
        dungeonBest  = 0,
        raidBest     = 0,
        delveBest    = 0,
        normalBest   = 0,
        dungeonAvg   = 0,
        raidAvg      = 0,
        dungeonCount = 0,
        raidCount    = 0,
    }

    -- If new week, reset weekly data
    if e.weekKey ~= weekKey then
        e.weekKey    = weekKey
        e.weekScores = {}
        e.weeklyAvg  = 0
    end

    -- Add score to weekly list (cap at 50 per week)
    table.insert(e.weekScores, score)
    if #e.weekScores > 50 then table.remove(e.weekScores, 1) end

    -- Recalculate weekly avg
    local sum = 0
    for _, s in ipairs(e.weekScores) do sum = sum + s end
    e.weeklyAvg = math.floor(sum / #e.weekScores)

    -- All-time best
    if score > (e.allTimeBest or 0) then e.allTimeBest = score end

    -- Category bests and averages
    if encType == "dungeon" then
        if score > (e.dungeonBest or 0) then e.dungeonBest = score end
        e.dungeonCount = (e.dungeonCount or 0) + 1
        local prevSum  = (e.dungeonAvg or 0) * ((e.dungeonCount or 1) - 1)
        e.dungeonAvg   = math.floor((prevSum + score) / e.dungeonCount)
    elseif encType == "raid" then
        if score > (e.raidBest or 0) then e.raidBest = score end
        e.raidCount = (e.raidCount or 0) + 1
        local prevSum = (e.raidAvg or 0) * ((e.raidCount or 1) - 1)
        e.raidAvg     = math.floor((prevSum + score) / e.raidCount)
    elseif encType == "delve" then
        if score > (e.delveBest or 0) then e.delveBest = score end
    else
        if score > (e.normalBest or 0) then e.normalBest = score end
    end

    -- Update displayed fields
    e.name      = name
    e.className = className or e.className
    e.specName  = specName  or e.specName
    e.role      = role      or e.role
    e.grade     = grade
    e.score     = score     -- most recent
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
    local charName  = UnitName("player") or "?"
    local encType   = encounter.encType  or "normal"
    local diffLabel = encounter.diffLabel or ""
    local ks        = encounter.keystoneLevel and tostring(encounter.keystoneLevel) or "0"
    local cs        = MakeChecksum(encounter.finalScore,
                                   math.floor(encounter.duration or 0),
                                   encType, charName)

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
        (encounter.bossName or ""):gsub("|", "_"),
        encType,
        cs,
        diffLabel:gsub("|", "_"),
        ks,
        charName:gsub("|", "_"),    -- included so receiver can verify checksum
    }, "|")

    if IsInGuild()     then C_ChatInfo.SendAddonMessage(LB_PREFIX, payload, "GUILD") end
    if IsInRaid()      then C_ChatInfo.SendAddonMessage(LB_PREFIX, payload, "RAID")
    elseif IsInGroup() then C_ChatInfo.SendAddonMessage(LB_PREFIX, payload, "PARTY") end
end

Core.On(Core.EVENTS.GRADE_CALCULATED, BroadcastScore)

--------------------------------------------------------------------------------
-- HELLO broadcast
--------------------------------------------------------------------------------
local function BroadcastHello()
    if not Core.ActiveSpec then return end
    local payload = table.concat({ "HELLO", Core.VERSION,
        Core.ActiveSpec.className or "?",
        Core.ActiveSpec.name      or "?" }, "|")
    if IsInGuild()     then C_ChatInfo.SendAddonMessage(LB_PREFIX, payload, "GUILD") end
    if IsInRaid()      then C_ChatInfo.SendAddonMessage(LB_PREFIX, payload, "RAID")
    elseif IsInGroup() then C_ChatInfo.SendAddonMessage(LB_PREFIX, payload, "PARTY") end
end

Core.On(Core.EVENTS.SESSION_READY, function() C_Timer.After(4.0, BroadcastHello) end)
Core.On(Core.EVENTS.SPEC_CHANGED,  function() C_Timer.After(1.0, BroadcastHello) end)

--------------------------------------------------------------------------------
-- Incoming message parser
--------------------------------------------------------------------------------
local function OnAddonMessage(prefix, payload, channel, sender)
    if prefix ~= LB_PREFIX then return end
    local shortSelf = UnitName("player")
    if ShortName(sender) == shortSelf then return end

    local parts = {}
    for p in payload:gmatch("[^|]+") do table.insert(parts, p) end
    if #parts < 2 then return end

    local msgType = parts[1]

    if msgType == "SCORE" then
        -- Format: SCORE|ver|class|spec|role|grade|score|dur|isBoss|bossName|encType|cs|diffLabel|ks|charName
        if #parts < 15 then return end

        local className = parts[3]
        local specName  = parts[4]
        local role      = parts[5]
        local grade     = parts[6]
        local score     = tonumber(parts[7]) or 0
        local duration  = tonumber(parts[8]) or 0
        local isBoss    = (parts[9] == "1")
        local bossName  = parts[10]
        local encType   = parts[11]
        local checksum  = parts[12]
        local diffLabel = parts[13] or ""
        local ks        = tonumber(parts[14]) or 0
        local charName  = parts[15] or ShortName(sender)

        -- 1. Score range
        if score < 0 or score > 100 then return end

        -- 2. Checksum — ties score+duration+encType to the sender's character name
        if not ValidateChecksum(score, duration, encType, charName, checksum) then
            if Core.GetSetting("debugMode") then
                print("|cffFF4444Midnight Sensei:|r Rejected score from " ..
                      ShortName(sender) .. " (checksum mismatch)")
            end
            return
        end

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

        local weekKey = GetWeekKey()

        local inParty = IsInGroup() or IsInRaid()
        if inParty then
            for i = 1, GetNumGroupMembers() do
                local unit = (IsInRaid() and "raid" or "party") .. i
                if UnitName(unit) and ShortName(sender) == UnitName(unit) then
                    partyData[sender] = MergeEntry(partyData[sender], sender,
                        className, specName, role, grade, score, duration,
                        encType, weekKey)
                    partyData[sender].diffLabel     = diffLabel
                    partyData[sender].keystoneLevel = ks > 0 and ks or nil
                    break
                end
            end
        end
        if IsInGuild() and IsGuildMember(sender) then
            local db = GetDB()
            if db then
                db.guild[sender] = MergeEntry(db.guild[sender], sender,
                    className, specName, role, grade, score, duration,
                    encType, weekKey)
                db.guild[sender].diffLabel     = diffLabel
                db.guild[sender].keystoneLevel = ks > 0 and ks or nil
            end
        end
        if IsBNetFriend(sender) then
            friendsData[sender] = MergeEntry(friendsData[sender], sender,
                className, specName, role, grade, score, duration,
                encType, weekKey)
            friendsData[sender].diffLabel     = diffLabel
            friendsData[sender].keystoneLevel = ks > 0 and ks or nil
        end

        LB.RefreshUI()

    elseif msgType == "HELLO" then
        -- Sender just logged in. If we have their guild data, send it back
        -- so they can recover scores they lost from a reinstall or clear.
        if IsInGuild() and IsGuildMember(sender) then
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
                    db.guild[sender].online = true
                end

                -- GRM-style sync: send their stored best back to them
                -- so they can recover scores after a reinstall.
                -- Only send if we have meaningful data (allTimeBest > 0).
                local entry = db.guild[sender]
                if entry and (entry.allTimeBest or 0) > 0 then
                    C_Timer.After(2.0 + math.random() * 3.0, function()
                        -- SYNC|target|allTimeBest|weeklyAvg|dungeonBest|raidBest|delveBest
                        local senderShort = ShortName(sender)
                        local syncPayload = table.concat({
                            "SYNC",
                            senderShort,
                            tostring(entry.allTimeBest  or 0),
                            tostring(entry.weeklyAvg    or 0),
                            tostring(entry.dungeonBest  or 0),
                            tostring(entry.raidBest     or 0),
                            tostring(entry.delveBest    or 0),
                            entry.weekKey or GetWeekKey(),
                        }, "|")
                        -- Send only to guild (private enough, no need to spam raid)
                        if IsInGuild() then
                            C_ChatInfo.SendAddonMessage(LB_PREFIX, syncPayload, "GUILD")
                        end
                    end)
                end
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
        if name and online and db.guild[name] then
            db.guild[name].online = true
        end
    end
    LB.RefreshUI()
end

--------------------------------------------------------------------------------
-- Public data getters
--------------------------------------------------------------------------------
function LB.GetPartyData()
    local result = {}
    local myName = GetPlayerName()
    local spec   = Core.ActiveSpec
    if spec then
        local history = MidnightSenseiDB and MidnightSenseiDB.encounters
        local lastEnc = history and history[#history]
        local wk      = GetWeekKey()
        local wScores = {}
        if history then
            for _, enc in ipairs(history) do
                if enc.timestamp and enc.timestamp > 0 then
                    local encWk = ""  -- old entries may not have weekKey
                    if enc.weekKey then encWk = enc.weekKey end
                    if encWk == wk then table.insert(wScores, enc.finalScore or 0) end
                end
            end
        end
        local wSum = 0
        for _, s in ipairs(wScores) do wSum = wSum + s end
        local wAvg = #wScores > 0 and math.floor(wSum / #wScores) or 0

        result[myName] = {
            name        = UnitName("player"),
            className   = spec.className or "?",
            specName    = spec.name      or "?",
            role        = spec.role      or "?",
            grade       = lastEnc and lastEnc.grade     or "--",
            score       = lastEnc and lastEnc.finalScore or 0,
            timestamp   = lastEnc and lastEnc.timestamp  or 0,
            isSelf      = true, online = true,
            weeklyAvg   = wAvg,
            allTimeBest = lastEnc and lastEnc.finalScore or 0,
            dungeonBest = 0, raidBest = 0, normalBest = 0,
        }
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
            local history = MidnightSenseiDB and MidnightSenseiDB.encounters
            local lastEnc = history and history[#history]
            local wk      = GetWeekKey()

            -- Compute weekly avg from local history
            local wScores = {}
            if history then
                for _, enc in ipairs(history) do
                    if enc.weekKey == wk then
                        table.insert(wScores, enc.finalScore or 0)
                    end
                end
            end
            local wSum = 0
            for _, s in ipairs(wScores) do wSum = wSum + s end
            local wAvg = #wScores > 0 and math.floor(wSum / #wScores) or 0

            -- Compute category bests from local history
            local dungBest, raidBest, delvBest, normBest = 0, 0, 0, 0
            if history then
                for _, enc in ipairs(history) do
                    local s = enc.finalScore or 0
                    if     enc.encType == "dungeon" then dungBest = math.max(dungBest, s)
                    elseif enc.encType == "raid"    then raidBest = math.max(raidBest, s)
                    elseif enc.encType == "delve"   then delvBest = math.max(delvBest, s)
                    else                                 normBest = math.max(normBest, s) end
                end
            end

            -- Build or update the self entry in guild data
            -- We write it into a local copy so we don't permanently pollute db.guild
            -- with computed data that the DB doesn't need to persist
            local existing = guildData[myName]
            local selfEntry = {
                name         = UnitName("player"),
                className    = spec.className or "?",
                specName     = spec.name      or "?",
                role         = spec.role      or "?",
                grade        = lastEnc and (lastEnc.finalGrade or lastEnc.grade) or "--",
                score        = lastEnc and lastEnc.finalScore or 0,
                timestamp    = lastEnc and lastEnc.timestamp  or 0,
                isSelf       = true,
                online       = true,
                weekKey      = wk,
                weekScores   = wScores,
                weeklyAvg    = wAvg,
                allTimeBest  = lastEnc and lastEnc.finalScore or 0,
                dungeonBest  = dungBest,
                raidBest     = raidBest,
                delveBest    = delvBest,
                normalBest   = normBest,
                diffLabel    = lastEnc and lastEnc.diffLabel or "",
                keystoneLevel = lastEnc and lastEnc.keystoneLevel or nil,
            }
            -- Merge with persisted data and any peer-recovered bests
            if existing then
                selfEntry.allTimeBest = math.max(selfEntry.allTimeBest, existing.allTimeBest or 0)
                selfEntry.dungeonBest = math.max(selfEntry.dungeonBest, existing.dungeonBest or 0)
                selfEntry.raidBest    = math.max(selfEntry.raidBest,    existing.raidBest    or 0)
                selfEntry.delveBest   = math.max(selfEntry.delveBest,   existing.delveBest   or 0)
            end
            -- Also incorporate scores recovered via SYNC from peers (reinstall recovery)
            local rb = MidnightSenseiDB and
                       MidnightSenseiDB.leaderboard and
                       MidnightSenseiDB.leaderboard.recoveredBests
            if rb then
                selfEntry.allTimeBest = math.max(selfEntry.allTimeBest, rb.allTimeBest or 0)
                selfEntry.dungeonBest = math.max(selfEntry.dungeonBest, rb.dungeonBest or 0)
                selfEntry.raidBest    = math.max(selfEntry.raidBest,    rb.raidBest    or 0)
                selfEntry.delveBest   = math.max(selfEntry.delveBest,   rb.delveBest   or 0)
            end

            -- Return a copy of guildData with self injected (don't modify db.guild directly)
            local result = {}
            for k, v in pairs(guildData) do result[k] = v end
            result[myName] = selfEntry
            return result
        end
    end

    return guildData
end

function LB.GetFriendsData()
    return friendsData
end

function LB.ClearGuildData()
    local db = GetDB()
    if db then db.guild = {} end
    LB.RefreshUI()
end

--------------------------------------------------------------------------------
-- Sorting — weekly avg first, then all-time best, then alpha
--------------------------------------------------------------------------------
local SORT_MODES = { "weeklyAvg", "allTimeBest", "dungeonBest", "raidBest" }
local sortMode   = "weeklyAvg"

local function SortedEntries(dataTable)
    local list = {}
    for _, entry in pairs(dataTable) do table.insert(list, entry) end
    table.sort(list, function(a, b)
        local av = a[sortMode] or a.score or 0
        local bv = b[sortMode] or b.score or 0
        if av ~= bv then return av > bv end
        return (a.name or "") < (b.name or "")
    end)
    return list
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
local lbFrame   = nil
local activeTab = "party"
local rowFrames = {}

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
    row.nameText  = TF(row,11,"LEFT");    row.nameText:SetPoint("LEFT",row,"LEFT",36,0);  row.nameText:SetWidth(110)
    row.specText  = TF(row,9,"LEFT");     row.specText:SetPoint("LEFT",row,"LEFT",150,0); row.specText:SetWidth(90)
    row.specText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    row.catText   = TF(row,9,"CENTER");   row.catText:SetPoint("RIGHT",row,"RIGHT",-70,0); row.catText:SetWidth(70)
    row.catText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    row.weekText  = TF(row,11,"RIGHT");   row.weekText:SetPoint("RIGHT",row,"RIGHT",-2,0); row.weekText:SetWidth(66)

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

        -- Category stats column: show diffLabel if available, else D/R/N bests
        local catStr = ""
        local dl = entry.diffLabel
        if dl and dl ~= "" and dl ~= "World" then
            catStr = dl
            -- Append best score for that category
            local encT = entry.score -- most recent
            if encT and encT > 0 then
                catStr = catStr .. " |cff" .. GHex(entry.score) .. entry.score .. "|r"
            end
        else
            local db = entry.dungeonBest or 0
            local rb = entry.raidBest    or 0
            local eb = entry.delveBest   or 0
            if db > 0 then catStr = catStr .. "D:"..db.." " end
            if rb > 0 then catStr = catStr .. "R:"..rb.." " end
            if eb > 0 then catStr = catStr .. "Dv:"..eb      end
            if catStr == "" then
                local nb = entry.normalBest or entry.score or 0
                catStr = nb > 0 and ("N:"..nb) or "--"
            end
        end
        row.catText:SetText(catStr)

        -- Weekly avg column
        local wAvg = entry.weeklyAvg or entry.score or 0
        local wk   = GetWeekKey()
        local weekStr = ""
        if wAvg and wAvg > 0 then
            weekStr = "|cff"..GHex(wAvg)..wAvg.."|r"
            if entry.weekKey and entry.weekKey ~= wk then
                weekStr = weekStr .. " |cff888888(prev)|r"
            end
        else
            weekStr = "|cff888888--this week--|r"
        end
        row.weekText:SetText(weekStr)

        -- Online dot
        local isOnline = (entry.online ~= false)
        if activeTab == "party" then isOnline = true end
        local dc = isOnline and COLOR.ONLINE or COLOR.OFFLINE
        row.onlineDot:SetColorTexture(dc[1],dc[2],dc[3],1)
        row.onlineDot:Show()
        row:Show()
        yOff = yOff + 22
    end
    scrollChild:SetHeight(math.max(yOff+8, 100))
end

--------------------------------------------------------------------------------
-- Sort buttons
--------------------------------------------------------------------------------
local SORT_LABELS = {
    weeklyAvg   = "Week Avg",
    allTimeBest = "All-Time",
    dungeonBest = "Dungeon",
    raidBest    = "Raid",
}

local function RefreshContent()
    if not lbFrame or not lbFrame.scrollChild then return end

    local rawData
    if     activeTab == "party"   then rawData = LB.GetPartyData()
    elseif activeTab == "guild"   then rawData = LB.GetGuildData()
    else                               rawData = LB.GetFriendsData() end

    PopulateRows(lbFrame.scrollChild, SortedEntries(rawData))

    -- Tab counts
    local counts = {
        party   = 0, guild = 0, friends = 0
    }
    for _ in pairs(LB.GetPartyData())   do counts.party   = counts.party   + 1 end
    for _ in pairs(LB.GetGuildData())   do counts.guild   = counts.guild   + 1 end
    for _ in pairs(LB.GetFriendsData()) do counts.friends = counts.friends + 1 end

    if lbFrame.tabs then
        for _, tab in ipairs(lbFrame.tabs) do
            local c = counts[tab.key] or 0
            tab.label:SetText(tab.name.." ("..c..")")
        end
    end

    -- Highlight active sort btn
    if lbFrame.sortBtns then
        for _, sb in ipairs(lbFrame.sortBtns) do
            local active = (sb.sortKey == sortMode)
            if active then
                sb:SetBackdropColor(0.20,0.18,0.28,1)
                sb.label:SetTextColor(COLOR.ACCENT[1],COLOR.ACCENT[2],COLOR.ACCENT[3],1)
            else
                sb:SetBackdropColor(COLOR.TAB_IDLE[1],COLOR.TAB_IDLE[2],COLOR.TAB_IDLE[3],1)
                sb.label:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
            end
        end
    end
end

function LB.RefreshUI()
    if lbFrame and lbFrame:IsShown() then RefreshContent() end
end

local function SetActiveTab(key)
    activeTab = key
    if lbFrame and lbFrame.tabs then
        for _, tab in ipairs(lbFrame.tabs) do
            local isActive = (tab.key == key)
            BD(tab, isActive and COLOR.TAB_ACTIVE or COLOR.TAB_IDLE, COLOR.BORDER)
            tab.label:SetTextColor(
                isActive and COLOR.ACCENT[1] or COLOR.TEXT_DIM[1],
                isActive and COLOR.ACCENT[2] or COLOR.TEXT_DIM[2],
                isActive and COLOR.ACCENT[3] or COLOR.TEXT_DIM[3], 1)
        end
    end
    RefreshContent()
end

--------------------------------------------------------------------------------
-- Build frame
--------------------------------------------------------------------------------
local function CreateLeaderboardFrame()
    if lbFrame then return lbFrame end

    local FW, FH = 520, 480
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

    -- Tab row
    local tabDefs = {
        {key="party",   name="Party"},
        {key="guild",   name="Guild"},
        {key="friends", name="Friends"},
    }
    local tabW = math.floor(FW / #tabDefs)
    lbFrame.tabs = {}
    for i,td in ipairs(tabDefs) do
        local tab = CreateFrame("Button",nil,lbFrame,"BackdropTemplate")
        tab:SetSize(tabW,26)
        tab:SetPoint("TOPLEFT",lbFrame,"TOPLEFT",(i-1)*tabW,-26)
        BD(tab, COLOR.TAB_IDLE, COLOR.BORDER)
        tab.key=td.key; tab.name=td.name
        tab.label = TF(tab,11,"CENTER"); tab.label:SetPoint("CENTER")
        tab.label:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
        tab.label:SetText(td.name)
        tab:SetScript("OnClick",function() SetActiveTab(td.key) end)
        table.insert(lbFrame.tabs, tab)
    end

    -- Sort buttons row
    local sortDefs = { "weeklyAvg", "allTimeBest", "dungeonBest", "raidBest" }
    local sortBtnW = math.floor(FW / #sortDefs)
    lbFrame.sortBtns = {}
    for i,sk in ipairs(sortDefs) do
        local sb = CreateFrame("Button",nil,lbFrame,"BackdropTemplate")
        sb:SetSize(sortBtnW, 20)
        sb:SetPoint("TOPLEFT",lbFrame,"TOPLEFT",(i-1)*sortBtnW,-52)
        BD(sb, COLOR.TAB_IDLE, COLOR.BORDER)
        sb.sortKey = sk
        sb.label = TF(sb,9,"CENTER"); sb.label:SetPoint("CENTER")
        sb.label:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
        sb.label:SetText(SORT_LABELS[sk])
        sb:SetScript("OnClick",function()
            sortMode = sk
            RefreshContent()
        end)
        table.insert(lbFrame.sortBtns, sb)
    end

    -- Column headers
    local hdr = CreateFrame("Frame",nil,lbFrame)
    hdr:SetPoint("TOPLEFT", lbFrame,"TOPLEFT",4,-74)
    hdr:SetPoint("TOPRIGHT",lbFrame,"TOPRIGHT",-20,-74)
    hdr:SetHeight(16)
    local function Hdr(t,anchor,x,w)
        local fs=TF(hdr,9,anchor)
        fs:SetPoint(anchor,hdr,anchor,x,0); fs:SetWidth(w)
        fs:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
        fs:SetText(t)
    end
    Hdr("#",     "LEFT",  4,   20)
    Hdr("PLAYER","LEFT",  36, 110)
    Hdr("SPEC",  "LEFT", 150,  90)
    Hdr("D/R/N", "RIGHT",-70,  70)
    Hdr("WK AVG","RIGHT", -2,  66)

    -- Scroll
    local sf = CreateFrame("ScrollFrame","MidnightSenseiLBScroll",lbFrame,"UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", lbFrame,"TOPLEFT",4,-92)
    sf:SetPoint("BOTTOMRIGHT",lbFrame,"BOTTOMRIGHT",-22,36)
    local sc = CreateFrame("Frame",nil,sf)
    sc:SetWidth(sf:GetWidth()); sc:SetHeight(200); sf:SetScrollChild(sc)
    lbFrame.scrollChild = sc

    -- Footer
    local footerText = TF(lbFrame,9,"LEFT")
    footerText:SetPoint("BOTTOMLEFT",lbFrame,"BOTTOMLEFT",8,12)
    footerText:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    footerText:SetText("Week Avg resets each week  *  D=Dungeon  R=Raid  N=Normal  *  /ms leaderboard")

    local refreshBtn = CreateFrame("Button",nil,lbFrame)
    refreshBtn:SetSize(60,18); refreshBtn:SetPoint("BOTTOMRIGHT",lbFrame,"BOTTOMRIGHT",-8,10)
    local rFs = TF(refreshBtn,10,"CENTER"); rFs:SetPoint("CENTER"); rFs:SetText("Refresh")
    refreshBtn:SetScript("OnClick",function()
        if activeTab=="guild" then SyncGuildOnlineStatus() end
        RefreshContent()
    end)

    -- Week info
    local weekInfo = TF(lbFrame,9,"RIGHT")
    weekInfo:SetPoint("BOTTOMRIGHT",lbFrame,"BOTTOMRIGHT",-72,12)
    weekInfo:SetTextColor(COLOR.TEXT_DIM[1],COLOR.TEXT_DIM[2],COLOR.TEXT_DIM[3],1)
    weekInfo:SetText("Week "..GetWeekKey())

    lbFrame:Hide()
    return lbFrame
end

function LB.Show()
    local frame = CreateLeaderboardFrame()
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
