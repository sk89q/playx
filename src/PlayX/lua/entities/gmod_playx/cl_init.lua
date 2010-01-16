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

require("chrome")
include("shared.lua")

language.Add("Undone_gmod_playx", "Undone PlayX Player")
language.Add("Cleanup_gmod_playx", "PlayX Player")
language.Add("Cleaned_gmod_playx", "Cleaned up the PlayX Player")

local usingChrome = chrome != nil and chrome.NewBrowser != nil

local browserMat = nil
local browserTexture = nil
local textureID = nil
local textureWidth = nil
local textureHeight = nil

if usingChrome then
    browserMat = Material("chrome/tele")

    if browserMat then
        browserTexture = browserMat:GetMaterialTexture("$basetexture")
        textureID = surface.GetTextureID("chrome/tele")
        textureWidth = browserTexture:GetActualWidth()
        textureHeight = browserTexture:GetActualHeight()
    else
        usingChrome = false
    end
end

local function JSEncodeString(str)
    return str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\'", "\\'")
        :gsub("\r", "\\r"):gsub("\n", "\\n")
end

function ENT:Initialize()
	self.Entity:DrawShadow(false)
	self:SetRenderBoundsWS(Vector(-50000, -50000, -50000), Vector(50000, 50000, 50000))

    local model = self.Entity:GetModel()
    local info = PlayXScreens[model]
    
    if info then
        if info.IsProjector then
            self:SetProjectorBounds(info.Forward, info.Right, info.Up)
        else
            self:SetScreenBounds(info.Offset, info.Width, info.Height, info.RotateAroundRight, info.RotateAroundUp)
        end
    else
        -- PHX plates are oriented flat
        if model:find("hunter/plates") or model:find("props_phx") or true then
            local mins = self.Entity:OBBMins()
            local maxs = self.Entity:OBBMaxs()
            
            self:SetScreenBounds(Vector(-mins.x, -mins.y, maxs.z + 0.2), 
                                 mins.y - maxs.y, mins.x - maxs.x, false, true)
        else
            local mins = self.Entity:OBBMins()
            local maxs = self.Entity:OBBMaxs()
            
            self:SetScreenBounds(Vector(-mins.x - 0.2, mins.y, -mins.z),
                                 math.abs(mins.y - maxs.y), math.abs(mins.z - maxs.z), true, true)
        end
    end
    
    self.UsingChrome = usingChrome
    self.CurrentPage = nil
    self.Playing = false
    self.FPS = 1
    self.LowFramerateMode = false
    self.DrawCenter = false
end

function ENT:SetScreenBounds(pos, width, height, rotateAroundRight, rotateAroundUp)
    self.IsProjector = false
    
    self.ScreenOffset = pos
    self.ScreenWidth = width
    self.ScreenHeight = height
    self.IsSquare = math.abs(width / height - 1) < 0.2 -- Uncalibrated number!
    
    if usingChrome then
        self.HTMLWidth = textureWidth
        self.HTMLHeight = textureHeight
        self.IsSquare = false
    else
        if self.IsSquare then
            self.HTMLWidth = 1024
            self.HTMLHeight = 1024
        else
            self.HTMLWidth = 1024
            self.HTMLHeight = 512
        end
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
end

function ENT:SetProjectorBounds(forward, right, up)
    self.IsProjector = true
    
    self.Forward = forward
    self.Right = right
    self.Up = up
    
    if usingChrome then
        self.HTMLWidth = textureWidth
        self.HTMLHeight = textureHeight
    else
        self.HTMLWidth = 1024
        self.HTMLHeight = 512
    end
    
    self.DrawScale = 1 -- Not used
end

function ENT:CreateBrowser(page)    
    if not self.DrawScale then
        Error("SetScreenBounds() not yet called")
    end
    
    self.CurrentPage = page
    
    if usingChrome then
        self.Browser = chrome.NewBrowser(textureWidth, textureHeight,
                                         browserTexture, self:GetTable())
        self.Browser:LoadURL("http://playx.googlecode.com/svn/host/host.html")
        -- TODO: Remove hard-coded URL
    else
        if PlayXBrowser and PlayXBrowser:IsValid() then
            Msg("Found existing PlayXBrowser; reusing\n")
            self.Browser = PlayXBrowser
        else
            self.Browser = vgui.Create("HTML")
        end
        
        self.Browser:SetSize(self.HTMLWidth, self.HTMLHeight)
        self.Browser:SetPaintedManually(true)
        self.Browser:SetVerticalScrollbarEnabled(false)
        self.Browser:SetHTML(page:GetHTML())
        
        if self.LowFramerateMode then
            self.Browser:StartAnimate(1000)
        else
            self.Browser:StartAnimate(1000 / self.FPS)
        end
        
        PlayXBrowser = self.Browser
    end
end

function ENT:Play(handler, uri, start, volume, handlerArgs)
    local page, center = PlayX.Handlers[handler](self.HTMLWidth, self.HTMLHeight,
                                                 start, volume, uri, handlerArgs)
    
    self.DrawCenter = center
    
    self.CurrentPage = page
    
    if not self.Browser then
        self:CreateBrowser(page)
    else
        if usingChrome then
            self.Browser:LoadURL("http://playx.googlecode.com/svn/host/host.html")
            -- TODO: Remove hard-coded URL
        else
            self.Browser:SetHTML(page:GetHTML())
        
            if self.LowFramerateMode then
                self.Browser:StartAnimate(1000)
            else
                self.Browser:StartAnimate(1000 / self.FPS)
            end
        end
    end
    
    self.Playing = true
end

function ENT:Stop()
    if self.Browser and (usingChrome or self.Browser:IsValid()) then
        if usingChrome then
            self.Browser:Free()
            self.Browser = nil
        else
            self.CurrentPage = nil
            self.Browser:SetHTML([[STOPPED]])
            self.Browser:SetPaintedManually(true)
            self.Browser:StopAnimate()
        end
    end
    
    self.Playing = false
end

function ENT:ResetRenderBounds()
    -- Not sure if this works
	self:SetRenderBoundsWS(Vector(-100, -100, -100), Vector(100, 100, 100))
	self:SetRenderBoundsWS(Vector(-50000, -50000, -50000), Vector(50000, 50000, 50000))
end

function ENT:SetFPS(fps)
    self.FPS = fps
    
    if not usingChrome and self.Browser and self.Browser:IsValid() and not self.LowFramerateMode then
        self.Browser:StartAnimate(1000 / self.FPS)
    end
end

function ENT:Draw()
	self.Entity:DrawModel()
	
	if self.DrawScale then
        if not usingChrome and self.Browser and self.Browser:IsValid() and self.Playing then
            self.Browser:SetPaintedManually(false)
        end
		render.SuppressEngineLighting(true)
        
        if self.IsProjector then
            local excludeEntities = player.GetAll()
            table.insert(excludeEntities, self.Entity)
            
            local dir = self.Entity:GetForward() * self.Forward * 4000 +
                        self.Entity:GetRight() * self.Right * 4000 +
                        self.Entity:GetUp() * self.Up * 4000
            local tr = util.QuickTrace(self.Entity:LocalToWorld(self.Entity:OBBCenter()),
                                       dir, excludeEntities)
            
            if tr.Hit then
                local ang = tr.HitNormal:Angle()
                ang:RotateAroundAxis(ang:Forward(), 90) 
                ang:RotateAroundAxis(ang:Right(), -90)
                
                local width = tr.HitPos:Distance(self.Entity:LocalToWorld(self.Entity:OBBCenter())) * 0.001
                local height = width / 2
                local pos = tr.HitPos - ang:Right() * height * self.HTMLHeight / 2
                            - ang:Forward() * width * self.HTMLWidth / 2
                            + ang:Up() * 2
                
                cam.Start3D2D(pos, ang, width)
                if self.Browser and (usingChrome or self.Browser:IsValid()) and self.Playing then
                    self:PaintBrowser()
                else
                    surface.SetDrawColor(0, 0, 0, 255)
                    surface.DrawRect(0, 0, 1024, 512)
                    
                    if not PlayX.Enabled then
                        draw.SimpleText("Re-enable the player in the tool menu -> Options",
                                        "HUDNumber",
                                        1024 / 2, 512 / 2, Color(255, 255, 255, 255),
                                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
                cam.End3D2D()
            end
        else
            local shiftMultiplier = 1
            if not self.DrawCenter then
                shiftMultiplier = 2
            end
            
            local pos = self.Entity:LocalToWorld(self.ScreenOffset - 
                Vector(0, self.DrawShiftX * self.DrawScale, self.DrawShiftY * shiftMultiplier * self.DrawScale))
            local ang = self.Entity:GetAngles()
            
            if self.RotateAroundRight then ang:RotateAroundAxis(ang:Right(), -90) end
            if self.RotateAroundUp then ang:RotateAroundAxis(ang:Up(), 90) end
            
            cam.Start3D2D(pos, ang, self.DrawScale)
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(-self.DrawShiftX, -self.DrawShiftY * shiftMultiplier, self.DrawWidth, self.DrawHeight)
            if self.Browser and (usingChrome or self.Browser:IsValid()) and self.Playing then
                self:PaintBrowser()
            else
                if not PlayX.Enabled then
                    draw.SimpleText("Re-enable the player in the tool menu -> Options",
                                    "HUDNumber",
                                    self.DrawWidth / 2 - self.DrawShiftX,
                                    self.DrawHeight / 2 - self.DrawShiftY * shiftMultiplier,
                                    Color(255, 255, 255, 255),
                                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            cam.End3D2D()
        end

		render.SuppressEngineLighting(false)
        if not usingChrome and self.Browser and self.Browser:IsValid() and self.Playing then
            self.Browser:SetPaintedManually(true)
        end
	end
end

function ENT:PaintBrowser()
    if usingChrome then
        self.Browser:Update()
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, textureWidth, textureHeight)
        surface.SetTexture(textureID)
        surface.DrawTexturedRect(0, 0, textureWidth, textureHeight)
    else
        self.Browser:PaintManual()
    end
end

function ENT:OnRemove()
    -- NOTE: Gmod will call this method when Gmod "freezes" (you hear the
    -- clicking and water sounds when you return to Gmod), even though
    -- the entity may have not been deleted. We have to work around this,
    -- so that the video continues playing. We also have to re-update the
    -- render bounds, as Gmod will reset those.
    
    Msg("PlayX DEBUG: ENT:OnRemove() called\n")
    
    local ent = this
    local browser = self.Browser
    
    if usingChrome then
        if self.Browser then
            self.Browser:Free()
            self.Browser = nil
        end
    else
        -- Give Gmod 200ms to really delete the entity
        timer.Simple(0.2, function()
            if not ValidEntity(ent) and 
                (not PlayX:PlayerExists() or PlayX.GetInstance() == ent) then -- Entity is really gone
                Msg("PlayX DEBUG: Entity was really removed\n")
                
                -- Creating a new HTML panel tends to crash clients occasionally, so
                -- we're going try to keep a copy around
                -- Don't know whether the crash is caused by the browser being created
                -- or by the page browsing
                if browser and browser:IsValid() then
                    --browser:Clear()
                    local html = [[Gmod called ENT:OnRemove() even though no entity was removed. You should not be seeing this message.]]
                    browser:SetHTML(html)
                    browser:SetPaintedManually(true)
                    browser:StopAnimate()
                end
            elseif ValidEntity(ent) then -- Gmod lied
                Msg("PlayX DEBUG: Entity was NOT really removed\n")
                
                ent:ResetRenderBounds()
            elseif PlayX:PlayerExists() and ValidEntity(PlayX.GetInstance()) and
                PlayX.GetInstance() ~= ent then
                Msg("PlayX DEBUG: New PlayX entity created to replace old one\n")
                
                PlayX.GetInstance():ResetRenderBounds()
            else
                Msg("PlayX DEBUG: Multiple entities detected?\n")
            end
        end)
    end
end

-- For gm_chrome
function ENT:onFinishLoading()
    if self.CurrentPage.JS then
        self.Browser:Exec(self.CurrentPage.JS)
    end
    
    if self.CurrentPage.JSInclude then
        self.Browser:Exec([[
var script = document.createElement('script');
script.type = 'text/javascript';
script.src = ']] .. JSEncodeString(self.CurrentPage.JSInclude) .. [[';
document.body.appendChild(script);
]])
    else
        self.Browser:Exec([[
document.body.innerHTML = ']] .. JSEncodeString(self.CurrentPage.Body) .. [[';
]])
    end

    self.Browser:Exec([[
var style = document.createElement('style');
style.type = 'text/css';
style.styleSheet.cssText = ']] .. JSEncodeString(self.CurrentPage.CSS) .. [[';
document.getElementsByTagName('head')[0].appendChild(style);
]])
end

-- For gm_chrome
function ENT:onBeginNavigation(url) end
function ENT:onBeginLoading(url, status) end
function ENT:onChangeFocus(focus) end