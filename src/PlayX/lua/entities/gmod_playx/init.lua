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
            "Start",
            "ActualStartTime",
            "Length",
            "URL [STRING]",
            "Title [STRING]",
            "Description [STRING]",
            "Tags [ARRAY]",
            "Faved",
            "Views",
            "NormalizedRating",
            "RatingCount",
            "Thumbnail [STRING]",
        })
        
        self:ClearWireOutputs()
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
        Wire_TriggerOutput(self.Entity, "Start", -1)
        Wire_TriggerOutput(self.Entity, "ActualStartTime", -1)
        Wire_TriggerOutput(self.Entity, "Length", -1)
        Wire_TriggerOutput(self.Entity, "URL", "")
        Wire_TriggerOutput(self.Entity, "Title", "")
        Wire_TriggerOutput(self.Entity, "Description", "")
        Wire_TriggerOutput(self.Entity, "Tags", "")
        Wire_TriggerOutput(self.Entity, "Faved", -1)
        Wire_TriggerOutput(self.Entity, "Views", -1)
        Wire_TriggerOutput(self.Entity, "NormalizedRating", -1)
        Wire_TriggerOutput(self.Entity, "RatingCount", -1)
        Wire_TriggerOutput(self.Entity, "Thumbnail", "")
    end
end

function ENT:SetWireMetadata(data)
    if WireAddon then
        Wire_TriggerOutput(self.Entity, "Provider", data.Provider and data.Provider or "")
        Wire_TriggerOutput(self.Entity, "Handler", data.Handler)
        Wire_TriggerOutput(self.Entity, "URI", data.URI)
        Wire_TriggerOutput(self.Entity, "Start", data.StartAt)
        Wire_TriggerOutput(self.Entity, "ActualStartTime", data.StartTime + data.StartAt)
        Wire_TriggerOutput(self.Entity, "Length", data.Length and data.Length or -1)
        Wire_TriggerOutput(self.Entity, "URL", data.URL and data.URL or "")
        Wire_TriggerOutput(self.Entity, "Title", data.Title and data.Title or "")
        Wire_TriggerOutput(self.Entity, "Description", data.Description and data.Description or "")
        Wire_TriggerOutput(self.Entity, "Tags", data.Tags and data.Tags or "")
        Wire_TriggerOutput(self.Entity, "Faved", data.NumFaves and data.NumFaves or -1)
        Wire_TriggerOutput(self.Entity, "Views", data.NumViews and data.NumViews or -1)
        Wire_TriggerOutput(self.Entity, "NormalizedRating", data.RatingNorm and data.RatingNorm or -1)
        Wire_TriggerOutput(self.Entity, "RatingCount", data.NumRatings and data.NumRatings or -1)
        Wire_TriggerOutput(self.Entity, "Thumbnail", data.Thumbnail and data.Thumbnail or "")
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