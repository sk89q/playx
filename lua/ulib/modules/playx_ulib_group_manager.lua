-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2021 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$
-- Version 2.7.6 by Nexus [BR] on 07-03-2013 09:02 PM

if SERVER then
	if ULib ~= nil then
		ULib.ucl.registerAccess("PlayX Access", {"admin", "superadmin"}, "Give access to PlayX", "PlayX")
	end
end