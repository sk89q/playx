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

ENT.NoScreen = false
ENT.IsProjector = false
ENT.ScreenOffset = nil
ENT.ScreenWidth = nil
ENT.ScreenHeight = nil
ENT.IsSquare = false
ENT.HTMLWidth = nil
ENT.HTMLHeight = nil
ENT.DrawScale = nil
ENT.DrawWidth = nil
ENT.DrawHeight = nil
ENT.DrawShiftX = nil
ENT.DrawShiftY = nil
ENT.RotateAroundRight = nil
ENT.RotateAroundUp = nil
ENT.RotateAroundForward = nil

--- Detects the screen position.
-- @hidden
function ENT:UpdateScreenBounds()
    local model = self.Entity:GetModel()
    local info = PlayXScreens[model:lower()]
    
    if CLIENT then
        pcall(hook.Remove, "HUDPaint", "PlayXHUD" .. self:EntIndex())
    end
    
    if info then
        self.NoScreen = false
        
        if info.NoScreen then
            self.NoScreen = true
            self:SetProjectorBounds(0, 0, 0)
            
	        if CLIENT then
	            hook.Add("HUDPaint", "PlayXHUD" .. self:EntIndex(), function()
	                if ValidEntity(self) then
	                    self:HUDPaint()
	                end
	            end)
	        end
        elseif info.IsProjector then
            self:SetProjectorBounds(info.Forward, info.Right, info.Up)
        else
            local rotateAroundRight = info.RotateAroundRight
            local rotateAroundUp = info.RotateAroundUp
            local rotateAroundForward = info.RotateAroundForward
            
            -- For backwards compatibility, adapt to the new rotation system
            if type(rotateAroundRight) == 'boolean' then
                rotateAroundRight = rotateAroundRight and -90 or 0
            end
            if type(rotateAroundUp) == 'boolean' then
                rotateAroundUp = rotateAroundUp and 90 or 0
            end
            if type(rotateAroundForward) == 'boolean' then
                rotateAroundForward = rotateAroundForward and 90 or 0
            end
            
            self:SetScreenBounds(info.Offset, info.Width, info.Height,
                                 rotateAroundRight,
                                 rotateAroundUp,
                                 rotateAroundForward)
        end
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
    
    if CLIENT then
        self:ResetRenderBounds()
    end
end

--- Sets the screen position for a non-projector screen.
-- @hidden
function ENT:SetScreenBounds(pos, width, height, rotateAroundRight,
                             rotateAroundUp, rotateAroundForward)
    self.IsProjector = false
    
    self.ScreenOffset = pos
    self.ScreenWidth = width
    self.ScreenHeight = height
    self.IsSquare = playxlib.IsSquare(width, height) -- Uncalibrated number!
    
    if self.IsSquare then
        self.HTMLWidth = 1024
        self.HTMLHeight = 1024
    else
        self.HTMLWidth = 1024
        self.HTMLHeight = 512
    end
    
    if width / height < self.HTMLWidth / self.HTMLHeight then
        self.DrawScale = width / self.HTMLWidth
        self.DrawWidth = self.HTMLWidth
        self.DrawHeight = height / self.DrawScale
        self.DrawShiftX = 0
        self.DrawShiftY = (self.DrawHeight - self.HTMLHeight) / 2
    else
        self.DrawScale = height / self.HTMLHeight
        self.DrawWidth = width / self.DrawScale
        self.DrawHeight = self.HTMLHeight
        self.DrawShiftX = (self.DrawWidth - self.HTMLWidth) / 2
        self.DrawShiftY = 0
    end
    
    self.RotateAroundRight = rotateAroundRight
    self.RotateAroundUp = rotateAroundUp
    self.RotateAroundForward = rotateAroundForward
end

--- Sets the projector screen position.
-- @hidden
function ENT:SetProjectorBounds(forward, right, up)
    self.IsProjector = true
    
    self.Forward = forward
    self.Right = right
    self.Up = up
    
    self.HTMLWidth = 1024
    self.HTMLHeight = 512
    
    self.DrawScale = 1 -- Not used
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

--- Gets the closet distance between a point and this instance. This returns the
-- distance to the point projected onto the finite line segment between
-- self:GetSourcePos() and self:GetProjectionPos().
-- @param pos Position
-- @return Distance
function ENT:GetProjectedDistance(pos)
    return playxlib.PointLineSegmentDistance(self:GetSourcePos(), 
        self:GetProjectionPos(), pos)
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
    ["models/props/cs_office/computer_monitor.mdl"] = {
        ["Offset"] = Vector(3.3, -10.5, 24.55),
        ["Width"] = 21,
        ["Height"] = 15.65,    
        ["RotateAroundRight"] = true,
        ["RotateAroundUp"] = true,
    },
    ["models/props_wasteland/controlroom_monitor001b.mdl"] = {
        ["Offset"] = Vector(15, -10.5, 1.4),
        ["Width"] = 22,
        ["Height"] = 18,    
        ["RotateAroundRight"] = -103,
        ["RotateAroundUp"] = true,
    },
    ["models/props_lab/monitor02.mdl"] = {
        ["Offset"] = Vector(10.8, -9, 22.5),
        ["Width"] = 17.5,
        ["Height"] = 14,    
        ["RotateAroundRight"] = -83,
        ["RotateAroundUp"] = true,
    },
    ["models/props_c17/tv_monitor01.mdl"] = {
        ["Offset"] = Vector(6, -9, 6),
        ["Width"] = 14.5,
        ["Height"] = 10.5,    
        ["RotateAroundRight"] = -90,
        ["RotateAroundUp"] = true,
    },
    ["models/props_lab/monitor01a.mdl"] = {
        ["Offset"] = Vector(12.2, -9, 11.3),
        ["Width"] = 18,
        ["Height"] = 15,    
        ["RotateAroundRight"] = -85,
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
    ["models/props_lab/citizenradio.mdl"] = {
        ["NoScreen"] = true,
    },
    ["models/props/radio_reference.mdl"] = {
        ["NoScreen"] = true,
    },
    ["models/props_misc/german_radio.mdl"] = {
        ["NoScreen"] = true,
    },
    ["models/props/cs_office/radio.mdl"] = {
        ["NoScreen"] = true,
    },
}

cleanup.Register("gmod_playx")