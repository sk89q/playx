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

-- We store a copy of the HTML VGUI object so that we don't re-create it
-- if we don't need to. Perhaps this will reduce crashes?
local browserCache = nil
local alreadyCreated = false

local HTMLEngine = PlayX.MakeClass()

--- Returns on the status of this engine's support.
-- @return Boolean indicating statues
function HTMLEngine.IsSupported()
    return true -- Always supported
end

function HTMLEngine:AllocateScreen(screenWidth, screenHeight)     
    if PlayX.IsSquare(screenWidth, screenHeight) then
        self.Width = 1024
        self.Height = 1024
    else
        self.Width = 1024
        self.Height = 512
    end
    
    -- Re-use the browser if necessary
    if browserCache then
        if alreadyCreated then
            Error("Only one HTMLEngine object can exist at this time.")
        end
        
        self.Browser = browserCache
    else
        self.Browser = vgui.Create("HTML")
        browserCache = self.Browser
    end
    
    alreadyCreated = true
    
    self.Browser:SetSize(self.Width, self.Height)
    self.Browser:SetPaintedManually(true)
    self.Browser:SetVerticalScrollbarEnabled(false)
    self.Browser:StartAnimate(1000)
    
    return self.Width, self.Height
end

--- Loads media.
function HTMLEngine:Load(resource)
    self.Resource = resource

    if resource:GetURL() then
        self.Browser:OpenURL(resource:GetURL())
    else
        self.Browser:SetHTML(resource:GetHTML())
    end
end

--- Changes the volume.
-- @param volume
function HTMLEngine:SetVolume(volume)
    local js = self.Resource:GetVolumeJS()
    if js then
        self.Browser:Exec(js)
    end
end

function HTMLEngine:PrePaint()
    self.Browser:SetPaintedManually(false)
end

--- Renders to a surface.
function HTMLEngine:Paint()
    self.Browser:PaintManual()
    self.Browser:SetPaintedManually(true)
end

function HTMLEngine:PostPaint()
    self.Browser:SetPaintedManually(true)
end

--- Changes the FPS.
-- @param fps
function HTMLEngine:SetFPS(fps)
    self.Browser:StartAnimate(1000 / fps)
end

--- Returns where the content should be centered.
-- @return
function HTMLEngine:IsCentered()
    return self.resource.Centered
end

--- Destroys the browser instance.
function HTMLEngine:Destroy()
    local html = [[HTMLEngine:Destroy() called.]]
    self.Browser:SetHTML(html)
    self.Browser:SetPaintedManually(true)
    self.Browser:StopAnimate()
    
    alreadyCreated = false
end

list.Set("PlayXEngines", "HTMLEngine", HTMLEngine)