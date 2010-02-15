-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- $Id$

--- Percent encodes a value.
-- @param s String
-- @return Encoded
function PlayX.URLEncode(s)
    s = tostring(s)
    local new = ""
    
    for i = 1, #s do
        local c = s:sub(i, i)
        local b = c:byte()
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or
            (b >= 48 and b <= 57) or
            c == "_" or c == "." or c == "~" then
            new = new .. c
        else
            new = new .. string.format("%%%X", b)
        end
    end
    
    return new
end

--- Percent encodes a table for the query part of a URL.
-- @param vars Table of keys and values
-- @return Encoded string
function PlayX.URLEncodeTable(vars)
    local str = ""
    
    for k, v in pairs(vars) do
        str = str .. PlayX.URLEncode(k) .. "=" .. PlayX.URLEncode(v) .. "&"
    end
    
    return str:sub(1, -2)
end

--- Attempts to match a list of patterns against a string, and returns
-- the matches, or nil if there were no matches.
-- @param str The string
-- @param patterns Table of patterns
-- @return Table of results, or bil
function PlayX.FindMatch(str, patterns)
    for _, pattern in pairs(patterns) do
        local m = {str:match(pattern)}
        if m[1] then return m end
    end
    
    return nil
end

--- Casts a console command arg to a string.
-- @param v
-- @param default
function PlayX.ConCmdToString(v, default)
    if v == nil then return default end
    return tostring(v)
end

--- Casts a console command arg to a number.
-- @param v
-- @param default
function PlayX.ConCmdToNumber(v, default)
    v = tonumber(v)
    if v == nil then return default end
    return v
end

--- Casts a console command arg to a bool.
-- @param v
-- @param default
function PlayX.ConCmdToBool(v, default)
    if v == nil then return default end
    if v == "false" then return false end
    v = tonumber(v)
    if v == nil then return true end
    return v ~= 0
end

--- Parses a human-readable time string. Returns the number in seconds, or
-- nil if it cannot detect a format. Blank strings will return 0.
-- @Param str
function PlayX.ParseTimeString(str)
    if str == "" or str == nil then return 0 end
    
    str = str:Trim()
    
    if tonumber(str) then
        return tonumber(str)
    end
    
    str = str:gsub("t=", "")
    str = str:gsub("#", "")
    
    local m, s = str:match("^([0-9]+):([0-9]+)$")
    if m then
        return tonumber(m) * 60 + tonumber(s)
    end
    
    local m, s, ms = str:match("^([0-9]+):([0-9]+)(%.[0-9]+)$")
    if m then
        return tonumber(m) * 60 + tonumber(s) + tonumber(ms)
    end
    
    local h, m, s = str:match("^([0-9]+):([0-9]+):([0-9]+)$")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
    end
    
    local h, m, s, ms = str:match("^([0-9]+):([0-9]+):([0-9]+)(%.[0-9]+)$")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms)
    end
    
    local s = str:match("^([0-9]+)s$")
    if s then
        return tonumber(s)
    end
    
    local m, s = str:match("^([0-9]+)m *([0-9]+)s$")
    if m then
        return tonumber(m) * 60 + tonumber(s)
    end
    
    local m, s = str:match("^([0-9]+)m$")
    if m then
        return tonumber(m) * 60
    end
    
    local h, m, s = str:match("^([0-9]+)h *([0-9]+)m *([0-9]+)s$")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
    end
    
    local h, m = str:match("^([0-9]+)h *([0-9]+)m$")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60
    end
    
    return nil
end