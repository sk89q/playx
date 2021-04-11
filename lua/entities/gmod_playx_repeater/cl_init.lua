-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2021 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$

include("shared.lua")

language.Add("gmod_playx_repeater", "PlayX Repeater")
language.Add("Undone_gmod_playx_repeater", "Undone PlayX Repeater")
language.Add("Undone_#gmod_playx_repeater", "Undone PlayX Repeater")
language.Add("Cleanup_gmod_playx_repeater", "PlayX Repeaters")
language.Add("Cleaned_gmod_playx_repeater", "Cleaned up PlayX Repeaters")

function ENT:Initialize()
    self.Entity:DrawShadow(false)
    
    self.DrawCenter = false
    self.NoScreen = false
    
    self:UpdateScreenBounds()
end

function ENT:DrawScreen(centerX, centerY)
    if IsValid(self.SourceInstance) then
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

function ENT:Think()  
    if not IsValid(self.SourceInstance) then
        self.SourceInstance = PlayX.GetInstance()
    end
    
    if IsValid(self.SourceInstance) then
        self.DrawCenter = self.SourceInstance.DrawCenter
    end
    self:NextThink(CurTime() + 0.1)  
end  

function ENT:OnRemove() 
end  