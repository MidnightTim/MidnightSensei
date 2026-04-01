--------------------------------------------------------------------------------
-- MidnightSensei: Utils.lua
-- Shared helper functions
-- Framework: MidnightFlow v2.1.0 patterns
--------------------------------------------------------------------------------

MidnightSensei = MidnightSensei or {}
MidnightSensei.Core      = MidnightSensei.Core      or {}
MidnightSensei.Analytics = MidnightSensei.Analytics or {}
MidnightSensei.UI        = MidnightSensei.UI        or {}
MidnightSensei.Utils     = MidnightSensei.Utils     or {}

local MS    = MidnightSensei
local Utils = MS.Utils

--------------------------------------------------------------------------------
-- Rounding
--------------------------------------------------------------------------------
function Utils.Round(val, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(val * mult + 0.5) / mult
end

--------------------------------------------------------------------------------
-- Time Formatting
--------------------------------------------------------------------------------
function Utils.FormatDuration(seconds)
    seconds = seconds or 0
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    if mins > 0 then
        return string.format("%dm %02ds", mins, secs)
    else
        return string.format("%ds", secs)
    end
end

function Utils.FormatDurationShort(seconds)
    seconds = seconds or 0
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

function Utils.FormatTimestamp(timestamp)
    return date("%Y-%m-%d %H:%M", timestamp)
end

function Utils.FormatDate(timestamp)
    return date("%b %d", timestamp)
end

--------------------------------------------------------------------------------
-- Number Formatting
--------------------------------------------------------------------------------
function Utils.FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

function Utils.FormatPercent(value, decimals)
    decimals = decimals or 0
    return string.format("%." .. decimals .. "f%%", value)
end

--------------------------------------------------------------------------------
-- Color Helpers
--------------------------------------------------------------------------------
function Utils.ColorToHex(r, g, b)
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function Utils.WrapColor(text, r, g, b)
    local hex = Utils.ColorToHex(r, g, b)
    return "|cff" .. hex .. text .. "|r"
end

function Utils.WrapColorTable(text, colorTable)
    if not colorTable or #colorTable < 3 then return text end
    return Utils.WrapColor(text, colorTable[1], colorTable[2], colorTable[3])
end

--------------------------------------------------------------------------------
-- String Helpers
--------------------------------------------------------------------------------
function Utils.Trim(str)
    if not str then return "" end
    return str:match("^%s*(.-)%s*$") or ""
end

function Utils.Split(str, sep)
    local result = {}
    sep = sep or ","
    for part in str:gmatch("([^" .. sep .. "]+)") do
        table.insert(result, Utils.Trim(part))
    end
    return result
end

function Utils.Truncate(str, maxLen)
    if not str then return "" end
    maxLen = maxLen or 50
    if #str <= maxLen then return str end
    return str:sub(1, maxLen - 3) .. "..."
end

--------------------------------------------------------------------------------
-- Table Helpers
--------------------------------------------------------------------------------
function Utils.TableCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Utils.TableCopy(v)
    end
    return copy
end

function Utils.TableMerge(base, override)
    base = base or {}
    override = override or {}
    local result = Utils.TableCopy(base)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = Utils.TableMerge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

function Utils.TableCount(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

--------------------------------------------------------------------------------
-- Safe Value Access
--------------------------------------------------------------------------------
function Utils.SafeGet(t, ...)
    local current = t
    for _, key in ipairs({...}) do
        if type(current) ~= "table" then return nil end
        current = current[key]
        if current == nil then return nil end
    end
    return current
end

--------------------------------------------------------------------------------
-- Clamping
--------------------------------------------------------------------------------
function Utils.Clamp(value, minVal, maxVal)
    if value < minVal then return minVal end
    if value > maxVal then return maxVal end
    return value
end

function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

--------------------------------------------------------------------------------
-- Grade Color Interpolation
--------------------------------------------------------------------------------
function Utils.GetScoreColor(score)
    score = Utils.Clamp(score or 0, 0, 100)

    local r, g, b

    if score < 40 then
        local t = score / 40
        r = 1.0
        g = Utils.Lerp(0.2, 0.45, t)
        b = Utils.Lerp(0.2, 0.0, t)
    elseif score < 60 then
        local t = (score - 40) / 20
        r = 1.0
        g = Utils.Lerp(0.45, 0.85, t)
        b = 0.0
    elseif score < 85 then
        local t = (score - 60) / 25
        r = Utils.Lerp(1.0, 0.3, t)
        g = Utils.Lerp(0.85, 0.85, t)
        b = Utils.Lerp(0.0, 0.3, t)
    else
        local t = (score - 85) / 15
        r = Utils.Lerp(0.3, 0.2, t)
        g = Utils.Lerp(0.85, 0.9, t)
        b = Utils.Lerp(0.3, 0.2, t)
    end

    return r, g, b
end

--------------------------------------------------------------------------------
-- Spell Info Helpers
--------------------------------------------------------------------------------
function Utils.GetSpellName(spellID)
    if not spellID then return "Unknown" end
    local info = C_Spell.GetSpellInfo(spellID)
    if info and info.name then
        return info.name
    end
    return "Spell #" .. spellID
end

function Utils.GetSpellIcon(spellID)
    if not spellID then return nil end
    local info = C_Spell.GetSpellInfo(spellID)
    if info and info.iconID then
        return info.iconID
    end
    return nil
end

--------------------------------------------------------------------------------
-- Debug Print
--------------------------------------------------------------------------------
function Utils.Debug(...)
    if MidnightSenseiDB and MidnightSenseiDB.settings and MidnightSenseiDB.settings.debugMode then
        print("|cff888888[MS Debug]|r", ...)
    end
end
