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

playxlib = {}

--- Takes a width and height and returns a boolean to indicate whether the shape
-- is optimally a square. This is used by the engine code to determine
-- whether a square screen is better than a rectangular screen for a certain
-- set of screen dimensions.
-- @param Width
-- @param Height
-- @return Boolean
function playxlib.IsSquare(width, height)
    return math.abs(width / height - 1) < 0.2
end

--- Encodes a string to be placed into a JavaScript string.
-- @param str String to encode
-- @return Encoded
function playxlib.JSEscape(str)
    return str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\'", "\\'")
        :gsub("\r", "\\r"):gsub("\n", "\\n")
end

--- Percent encodes a value for URLs.
-- @param s String
-- @return Encoded
function playxlib.URLEscape(s)
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
function playxlib.URLEscapeTable(vars)
    local str = ""
    
    for k, v in pairs(vars) do
        str = str .. playxlib.URLEscape(k) .. "=" .. playxlib.URLEscape(v) .. "&"
    end
    
    return str:sub(1, -2)
end

--- HTML encodes a string.
-- @param str
-- @return Encoded string
function playxlib.HTMLEscape(str)
    return str:gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub("\"", "&quot;")
end

--- Unescape HTML. This function fudges the job, and it does not handle all of
-- HTML's named entities.
-- @param s The string
-- @return Unescaped string
function playxlib.HTMLUnescape(s)
    if not s then return nil end
    
    s = s:gsub("<br */?>", "\n")
    s = s:gsub("&#([0-9]+);", function(m) return string.char(tonumber(m)) end)
    s = s:gsub("&#x(%x+);", function(m) return string.char(tonumber(m, 16)) end)
    s = s:gsub("&lt;", "<")
    s = s:gsub("&gt;", ">")
    s = s:gsub("&quot;", "\"")
    s = s:gsub("&amp;", "&")
    s = s:gsub("<[^<]+>", "")
    
    return s
end

--- Attempts to match a list of patterns against a string, and returns
-- the first match, or nil if there were no matches.
-- @param str The string
-- @param patterns Table of patterns
-- @return Table of results, or bil
function playxlib.FindMatch(str, patterns)
    for _, pattern in pairs(patterns) do
        local m = {str:match(pattern)}
        if m[1] then return m end
    end
    
    return nil
end

--- Gets a timestamp in UTC.
-- @param t Time
-- @return Time
function playxlib.UTCTime(t)
	local tSecs = os.time(t)
	t = os.date("*t", tSecs)
	local tUTC = os.date("!*t", tSecs)
	tUTC.isdst = t.isdst
	local utcSecs = os.time(tUTC)
	return tSecs + os.difftime(tSecs, utcSecs)
end


--- Gets the tags out of a string.
-- @param s
-- @param delim Delimiter
-- @return Table
function playxlib.ParseTags(s, delim)
    if not s then return nil end
    
    local final = {}
    
    local tags = string.Explode(delim, s)
    for _, tag in pairs(tags) do
        tag = tag:Trim()
        if tag ~= "" and not table.HasValue(final, tag) then
            table.insert(final, tag)
        end
    end
    
    return final
end

--- Casts a console command arg to a string.
-- @param v
-- @param default
-- @return Boolean
function playxlib.CastToString(v, default)
    if v == nil then return default end
    return tostring(v)
end

--- Casts a console command arg to a number.
-- @param v
-- @param default
-- @return Boolean
function playxlib.CastToNumber(v, default)
    v = tonumber(v)
    if v == nil then return default end
    return v
end

--- Casts a console command arg to a bool.
-- @param v
-- @param default
-- @return Boolean
function playxlib.CastToBool(v, default)
    if v == nil then return default end
    if v == "false" then return false end
    v = tonumber(v)
    if v == nil then return true end
    return v ~= 0
end

--- Parses a human-readable time string. Returns the number in seconds, or
-- nil if it cannot detect a format. Blank strings will return 0.
-- @param str
-- @return Time
function playxlib.ParseTimeString(str)
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

--- Parses a string containing data formatted in CSV into a table.
-- Fields can be quoted with double quotations or be unquoted, and characters
-- can be escaped with a backslash. This CSV parser is very forgiving. The
-- return table has each line in a new entry, and each field is then a further
-- entry in a table. Not all the rows may have the same number of fields in
-- the returned table.
-- @param data CSV data
-- @return Table containg data
function playxlib.ParseCSV(data)
    local lines = string.Explode("\n", data:gsub("\r", ""))
    local result = {}
    
    for i, line in pairs(lines) do
        local line = line:Trim()
        
        if line ~= "" then
	        local buffer = ""
	        local escaped = false
	        local inQuote = false
	        local fields = {}
	        
	        for c = 1, #line do
	            local char = line:sub(c, c)
	            if escaped then
	                buffer = buffer .. char
	                escaped = false
	            else
	                if char == "\\" then
	                    escaped = true
	                elseif char == "\"" then
	                    inQuote = not inQuote
	                elseif char == "," then
	                    if inQuote then
	                        buffer = buffer .. char
	                    else
	                        table.insert(fields, buffer)
	                        buffer = ""
	                    end
	                else
	                    buffer = buffer .. char
	                end
	            end
	        end
	        
	        table.insert(fields, buffer)
	        table.insert(result, fields)
	   end
    end
    
    return result
end

--- Turns a table into CSV data.
-- @param data Table to convert
-- @return CSV data
function playxlib.WriteCSV(data)
    local output = ""
    
    for _, v in pairs(data) do
        local line = ""
        for _, p in pairs(v) do
            if type(p) == 'boolean' then
                line = line .. ",\"" .. (p and "true" or "false") .. "\""
            else
                line = line .. ",\"" .. tostring(p):gsub("[\"\\]", "\\%1") .. "\""
            end
        end
        
        output = output .. "\n" .. line:sub(2)
    end
    
    return output:sub(2)
end

--- Tries to interpret a string as a boolean. "true," "y," etc. are considered
-- to be true.
-- @param s String
-- @return Boolean
function playxlib.IsTrue(s)
    local s = s:lower():Trim()
    return s == "t" or s == "true" or s == "1" or s == "y" or s == "yes"
end