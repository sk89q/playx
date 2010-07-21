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

include("shared.lua")

function ENT:DrawScreen(centerX, centerY, x, y, width, height)
    if not self:HasMedia() and self.dt.ServerHasMedia then
        draw.SimpleText("Press use on this screen to view",
                        "HUDNumber",
                        centerX, centerY, Color(255, 255, 255, 255),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        self.BaseClass.DrawScreen(self, centerX, centerY)
    end
    
    if ValidEntity(self.dt.owning_ent) then
        draw.WordBox(2, x, y, "Owned by " .. self.dt.owning_ent:GetName(),
            "HUDNumber5", Color(140, 0, 0, 100), Color(255, 255, 255, 255))
    else
        draw.WordBox(2, x, y, "No longer owned!",
            "HUDNumber5", Color(140, 0, 0, 100), Color(255, 255, 255, 255))
    end
end

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

hook.Add("PlayXGetSoundMultiplier", "PlayXTV", function(instance)
    if instance:GetClass() ~= "playx_tv" then return end

    local fullSoundRadius = math.max(instance.ScreenWidth, instance.ScreenHeight)
    local distance = instance:GetProjectedDistance(LocalPlayer():GetPos())
    
    local factor = 1
    if not CanSee(LocalPlayer(), instance) then
        factor = 0.3
    end
    
    if distance < fullSoundRadius + 400 then
        return 100 * factor
    else
        local diff = (distance - fullSoundRadius - 400)
        return math.min(1, 1 / math.exp((1 / 1000 / 0.3) * diff)) * 100 * factor
    end
end)