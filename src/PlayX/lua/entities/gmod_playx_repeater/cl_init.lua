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

language.Add("gmod_playx_repeater", "PlayX Repeater")
language.Add("Undone_gmod_playx_repeater", "Undone PlayX Repeater")
language.Add("Undone_#gmod_playx_repeater", "Undone PlayX Repeater")
language.Add("Cleanup_gmod_playx_repeater", "PlayX Repeaters")
language.Add("Cleaned_gmod_playx_repeater", "Cleaned up PlayX Repeaters")

ENT.CLSource = nil
ENT.SourceInstance = nil

--- Initialize the entity.
-- @hidden
function ENT:Initialize()
    self.Entity:DrawShadow(false)
    
    self.DrawCenter = false
    self.NoScreen = false
    
    self:UpdateScreenBounds()
end

--- Set the PlayX entity to be the source. Pass nil or NULL to clear.
-- This will override the server set source.
-- @param src Source
function ENT:SetSource(src)
    self.CLSource = ValidEntity(src) and src or nil
end

--- Get the client set source entity. May return nil.
-- @return Source
function ENT:GetSource()
    return self.CLSource
end

--- Get the server set source entity. May return nil.
-- @return Source
function ENT:GetServerSource()
    return ValidEntity(self.dt.Source) and self.dt.Source or nil
end

--- Get the active source entity. May return nil.
-- @return Source
function ENT:GetActiveSource()
    return ValidEntity(self.SourceInstancee) and self.SourceInstance or nil
end

--- Used to draw the screen content. This function must be called once
-- a 3D2D context has been created.
-- @param centerX Center X
-- @param centerY Center Y
-- @hidden
function ENT:DrawScreen(centerX, centerY)
    if ValidEntity(self.SourceInstance) then
        if not self.SourceInstance.NoScreen then
            self.SourceInstance:DrawScreen(centerX, centerY)
        else
        draw.SimpleText("PlayX source has no screen",
                        "HUDNumber",
                        centerX, centerY, Color(255, 255, 255, 255),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    else
        draw.SimpleText("PlayX source is required for repeater",
                        "HUDNumber",
                        centerX, centerY, Color(255, 255, 255, 255),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

--- Think hook that gets the source instance.
-- @hidden
function ENT:Think()
    if ValidEntity(self.CLSource) then
        self.SourceInstance = self.CLSource
    elseif ValidEntity(self.dt.Source) then
        self.SourceInstance = self.dt.Source
    else
        self.SourceInstance = PlayX.GetInstance()
    end
    
    if ValidEntity(self.SourceInstance) then
        self.DrawCenter = self.SourceInstance.DrawCenter
    end
    
    self:NextThink(CurTime() + 0.1)  
end

--- Do nothing removal hook.
-- @hidden
function ENT:OnRemove() 
end  