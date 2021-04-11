-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2021 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

--resource.AddFile("materials/vgui/entities/gmod_playx_repeater.vmt")

function ENT:Initialize()
    self.Entity:PhysicsInit(SOLID_VPHYSICS)
    self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
    self.Entity:SetSolid(SOLID_VPHYSICS)
    self.Entity:DrawShadow(false)
end

function ENT:UpdateTransmitState()
end

function ENT:SpawnFunction(ply, tr)
    PlayX.SendSpawnDialogUMsg(ply, true)
end

function ENT:OnRemove()
end

local function PlayXRepeaterEntityDuplicator(ply, model, pos, ang)
    if not PlayX.IsPermitted(ply) then
        return nil
    end
    
    local ent = ents.Create("gmod_playx_repeater")
    ent:SetModel(model)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    
    if ply.AddCleanup then
        ply:AddCleanup("gmod_playx_repeater", ent)
    end
    
    return ent
end

duplicator.RegisterEntityClass("gmod_playx_repeater", PlayXRepeaterEntityDuplicator, "Model", "Pos", "Ang")