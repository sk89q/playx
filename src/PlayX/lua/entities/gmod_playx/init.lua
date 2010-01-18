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

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_playx.vmt")

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:DrawShadow(false)
    
	if WireAddon then
		self.Outputs = Wire_CreateOutputs(self.Entity, {
            "Provider [STRING]",
            "Handler [STRING]",
            "URI [STRING]",
            "Playing",
            "Start",
            "ActualStartTime",
            "Length",
            "Identifier [STRING]",
            "Title [STRING]",
        })
	end
end

function ENT:SpawnFunction(ply, tr)
    PlayX.SendSpawnDialogUMsg(ply)
end

function ENT:OnRemove()
    PlayX.CloseMedia()
end

function ENT:ClearWireOutputs()
	if WireAddon then
        Wire_TriggerOutput(self.Entity, "Provider", "")
        Wire_TriggerOutput(self.Entity, "Handler", "")
        Wire_TriggerOutput(self.Entity, "URI", "")
        Wire_TriggerOutput(self.Entity, "Playing", 0)
        Wire_TriggerOutput(self.Entity, "Start", 0)
        Wire_TriggerOutput(self.Entity, "ActualStartTime", 0)
        Wire_TriggerOutput(self.Entity, "Length", 0)
        Wire_TriggerOutput(self.Entity, "Identifier", "")
        Wire_TriggerOutput(self.Entity, "Title", "")
    end
end

function ENT:UpdateWireOutputs(handler, uri, start, length, provider,
                               identifier, title)
	if WireAddon then
        Wire_TriggerOutput(self.Entity, "Provider", provider)
        Wire_TriggerOutput(self.Entity, "Handler", handler)
        Wire_TriggerOutput(self.Entity, "URI", uri)
        Wire_TriggerOutput(self.Entity, "Playing", 1)
        Wire_TriggerOutput(self.Entity, "Start", start)
        Wire_TriggerOutput(self.Entity, "ActualStartTime", CurTime())
        Wire_TriggerOutput(self.Entity, "Length", length)
        Wire_TriggerOutput(self.Entity, "Identifier", identifier)
        Wire_TriggerOutput(self.Entity, "Title", title)
    end
end

function ENT:UpdateWireLength(length)
	if WireAddon then
        Wire_TriggerOutput(self.Entity, "Length", length)
    end
end

function ENT:UpdateWireMetadata(length, provider, title)
	if WireAddon then
        Wire_TriggerOutput(self.Entity, "Length", length)
        Wire_TriggerOutput(self.Entity, "Title", title)
    end
end

local function PlayXEntityDuplicator(ply, model, pos, ang)
    if PlayX.PlayerExists() then
        return nil
    end
    
    if not PlayX.IsPermitted(ply) then
        return nil
    end
    
	local ent = ents.Create("gmod_playx")
    ent:SetModel(model)
	ent:SetPos(pos)
	ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    
    ply:AddCleanup("gmod_playx", ent)

    return ent
end

duplicator.RegisterEntityClass("gmod_playx", PlayXEntityDuplicator, "Model", "Pos", "Ang")