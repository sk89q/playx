-- PlayX
-- Copyright (c) 2009 sk89q <http://www.sk89q.com>
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

ENT.Type = "anim"
ENT.Base = "base_anim"
 
ENT.PrintName = "PlayX Player"
ENT.Author = "sk89q"
ENT.Contact = "http://www.sk89q.com"
ENT.Purpose = "Internet media player"
ENT.Instructions = "Spawn one, and then use the spawn menu."

ENT.WireDebugName = "PlayX Player"

ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

PlayXScreens = {
    ["models/props/cs_assault/billboard.mdl"] = {
        ["Offset"] = Vector(1, -110.5, 57.5),
        ["Width"] = 221,
        ["Height"] = 115,
        ["RotateAroundRight"] = true,
        ["RotateAroundUp"] = true,
    },
    ["models/props/cs_office/tv_plasma.mdl"] = {
        ["Offset"] = Vector(6.2, -28, 36),
        ["Width"] = 56,
        ["Height"] = 33.5,    
        ["RotateAroundRight"] = true,
        ["RotateAroundUp"] = true,
    },
    ["models/props/cs_office/projector.mdl"] = {
        ["IsProjector"] = true,
        ["Forward"] = 0,
        ["Right"] = 1,    
        ["Up"] = 0,
    },
    ["models/dav0r/camera.mdl"] = {
        ["IsProjector"] = true,
        ["Forward"] = 1,
        ["Right"] = 0,    
        ["Up"] = 0,
    },
}

cleanup.Register("gmod_playx")