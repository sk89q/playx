-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2023 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$

ENT.Type = "anim"
ENT.Base = "gmod_playx"
 
ENT.PrintName = "PlayX Repeater"
ENT.Author = "sk89q"
ENT.Contact = "http://www.sk89q.com"
ENT.Purpose = "Repeater of a PlayX screen"
ENT.Instructions = "Spawn a regular PlayX screen first."
ENT.Category = "PlayX"
ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

cleanup.Register("gmod_playx_repeater")