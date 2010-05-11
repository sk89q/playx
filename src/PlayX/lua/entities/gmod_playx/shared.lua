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

--- Updates the screen bounds, based on either the screen list or using
-- an algorithm at detecting the screen.
-- @hidden
function ENT:CalculateScreenBounds()
    local model = self.Entity:GetModel()
    local info = PlayXScreens[model:lower()]
    
    -- Is this a pre-defined screen?
    if info then
        if info.IsProjector then
            self:SetScreenBounds(nil, 1024, 512,
                                 info.Right, info.Up, info.Forward)
        else
            local right = info.RotateAroundRight
            local up = info.RotateAroundUp
            local forward = info.RotateAroundForward
            
            -- For backwards compatibility, adapt to the new rotation system
            if type(right) == 'boolean' then
                right = right and -90 or 0
            end
            if type(up) == 'boolean' then
                up = up and 90 or 0
            end
            if type(forward) == 'boolean' then
                forward = forward and 90 or 0
            end
            
            self:SetScreenBounds(info.Offset, info.Width, info.Height,
                                 right, up, forward)
        end
    -- Or let's do our best attempt at fitting a screen automatically.
    else
        local center = self.Entity:OBBCenter()
        local mins = self.Entity:OBBMins()
        local maxs = self.Entity:OBBMaxs()
        local rightArea = (maxs.z * mins.z) * (maxs.y * mins.y)
        local forwardArea = (maxs.z * mins.z) * (maxs.x * mins.x)
        local topArea = (maxs.y * mins.y) * (maxs.x * mins.x)
        local maxArea = math.max(rightArea, forwardArea, topArea)
        
        if maxArea == rightArea then
            local width = maxs.y - mins.y
            local height = maxs.z - mins.z
            local pos = Vector(center.x + (maxs.x - mins.x) / 2 + 0.5,
                               center.y - width / 2,
                               center.z + height / 2)
            self:SetScreenBounds(pos, width, height, -90, 90, 0)
        elseif maxArea == forwardArea then
            local width = maxs.x - mins.x
            local height = maxs.z - mins.z
            local pos = Vector(center.x + width / 2,
                               center.y + (maxs.y - mins.y) / 2 + 0.5,
                               center.z + height / 2)
            self:SetScreenBounds(pos, width, height, 180, 0, -90)
        else
            local width = maxs.y - mins.y
            local height = maxs.x - mins.x
            local pos = Vector(center.x + height / 2,
                               center.y + width / 2,
                               center.z + (maxs.z - mins.z) / 2 + 0.5)
            self:SetScreenBounds(pos, width, height, 0, -90, 0)
        end
    end
end

--- Returns the center position of the player, not necessarily where the
-- screen is, in the case of non-projectors.
-- @return Position
-- @return Normal
function ENT:GetSourcePos()
    return self.Entity:GetPos() + self.Entity:OBBCenter()
end

--- Gets the projector's screen position, or if it's not a projector, a psuedo
-- projection line endpoint.
-- If the entity is not a projector then nil will be returned. 
-- @return Position
-- @return Normal
-- @return Boolean indicating whether a screen is showing
function ENT:GetProjectionPos()
    if self.IsProjector then
        local excludeEntities = player.GetAll()
        table.insert(excludeEntities, self.Entity)
        
        local dir = self.Entity:GetForward() * self.Forward * 4000 +
                    self.Entity:GetRight() * self.Right * 4000 +
                    self.Entity:GetUp() * self.Up * 4000
        local tr = util.QuickTrace(self.Entity:LocalToWorld(self.Entity:OBBCenter()),
                                   dir, excludeEntities)
        
        if tr.Hit then
            return tr.HitPos, tr.HitNormal, true
        else
            return tr.HitPos, tr.HitNormal, false
        end
    else
        local ang = self.Entity:GetAngles()
        
        ang:RotateAroundAxis(ang:Right(), self.Right)
        ang:RotateAroundAxis(ang:Up(), self.Up)
        ang:RotateAroundAxis(ang:Forward(), self.Forward)
        
        return self:GetSourcePos() + ang:Up() *
            (10 * (self.ScreenWidth * self.ScreenHeight) ^ 0.3)
    end
end

-- Model names MUST be lowercase
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