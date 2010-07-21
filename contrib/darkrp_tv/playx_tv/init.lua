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

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props/cs_office/tv_plasma.mdl")
    self.BaseClass.Initialize(self)
    
    local physObj = self:GetPhysicsObject()
    if physObj:IsValid() then
        physObj:Wake()
    end
    
    if ValidEntity(self.dt.owning_ent)
        and self.dt.owning_ent:GetPos():Distance(self:GetPos()) <= 2000 then
        PlayX.SubscribeOnly(self.dt.owning_ent, self)
    end
end

function ENT:MediaBegan()
    self.dt.ServerHasMedia = true
end

function ENT:MediaEnded()
    self.dt.ServerHasMedia = false
end

function ENT:MediaExpire()
    self.dt.ServerHasMedia = false
end

function ENT:ShouldAutoSubscribe()
    return false
end

function ENT:MediaOpen(provider, uri, start, forceLowFramerate,
        useJW, ignoreLength, result)
    if provider ~= "YouTube" then
        return false, "Only YouTube is allowed"
    end
end

function ENT:Use(activator, caller)
    if activator:IsPlayer() then
        if self:IsSubscribed(activator) then
            self:Unsubscribe(activator)
        else
            PlayX.SubscribeOnly(activator, self)
        end
    end
end

function ENT:Think()
    for _, ply in pairs(self:GetSubscribers()) do
        if ply:GetPos():Distance(self:GetPos()) > 2000 then
            self:Unsubscribe(ply)
        end
    end
    
    self:NextThink(CurTime() + 1)
    return true
end

duplicator.RegisterEntityClass("playx_tv", function() return nil end, "Model", "Pos", "Ang")

local data = {}

local function CanSee(ply, instance)
    local factor = 1
    filter = player.GetAll()
    data.start = ply:GetShootPos()
    data.endpos = instance:LocalToWorld(instance:OBBCenter())
    data.filter = filter
    local tr = util.TraceLine(data)
    return tr.Entity == instance
end

hook.Add("PlayXSelectInstance", "PlayXTV", function(ply)
    if PlayX.IsPermitted(ply) then return end
    if not ply then return end
    
    local temp = PlayX.GetInstances()
    local instances = {}
    local couldNotSee = 0
    
    -- We only want playx_tv entities that the player can control
    for _, instance in pairs(temp) do
        if instance.dt.owning_ent == ply then
            if instance:GetClass() == "playx_tv" and CanSee(ply, instance) 
                and ply:GetPos():Distance(instance:GetPos()) < 1000 then
                table.insert(instances, instance)
            else
                couldNotSee = couldNotSee + 1
            end
        end
    end
    
    if #instances == 0 then
        return false, couldNotSee > 0 and "A TV of yours is not in view." or "You don't own a television! Buy one with F4."
    else
        return instances[1]
    end
    
    local plyPos = ply:GetPos()
    table.sort(instances, function(a, b)
        return a:GetPos():Distance(plyPos) < b:GetPos():Distance(plyPos)
    end)
    
    return instances[1]
end)

hook.Add("PlayXIsPermitted", "PlayXTV", function(ply, instance)
    if not instance then return end
    if instance:GetClass() ~= "playx_tv" then return end
    
    return instance.dt.owning_ent == ply
end)

hook.Add("PlayXConCmdOpened", "PlayXTV", function(instance, ply)
    if instance:GetClass() ~= "playx_tv" then return end
    
    local attachment = ply:GetAttachment(ply:LookupAttachment("anim_attachment_RH"))
    if not attachment then return end
    local data = EffectData()
    local pos = attachment.Pos
    data:SetStart(pos)
    data:SetOrigin(instance:LocalToWorld(Vector(8, 25, 2)))
    data:SetScale(1)
    util.Effect("ToolTracer", data)
end)