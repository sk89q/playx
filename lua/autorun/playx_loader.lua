-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2023 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$
-- Version 2.9.1 by Dathus [BR] on 2023-06-10 3:30 PM (-03:00 GMT)

--Setup Loading Log Formatation
function loadingLog (text)
	--Set Max Size
	local size = 32
	--If Text Len < max size
	if(string.len(text) < size) then
		-- Format the text to be Text+Spaces*LeftSize
		text = text .. string.rep( " ", size-string.len(text) )
	else
		--If Text is too much big then cut and add ...
		text = string.Left( text, size-3 ) .. "..."
	end
	--Log Messsage
	Msg( "||  "..text.."||\n" )
end

function debugTable( var, name )
  if not name then name = "a" end
  if "table" ~= type( var ) then
    print( name .. " = " .. tostring( var ) )
  else
    -- for tables, recurse through children
    for k,v in pairs( var ) do
      local child
      if 1 == string.find( k, "%a[%w_]*" ) then
        -- key can be accessed using dot syntax
        child = name .. '.' .. k
      else
        -- key contains special characters
        child = name .. '["' .. k .. '"]'
      end
      debugTable( v, child )
    end
  end
end

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

Msg( "\n/====================================\\\n")
Msg( "||               PlayX              ||\n" )
Msg( "||----------------------------------||\n" )
loadingLog("Version 2.9.1")
loadingLog("Updated on 2023-06-10 3:30 PM")
Msg( "\\====================================/\n\n" )
