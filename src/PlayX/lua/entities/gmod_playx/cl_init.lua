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

language.Add("gmod_playx", "PlayX Player")
language.Add("Undone_gmod_playx", "Undone PlayX Player")
language.Add("Undone_#gmod_playx", "Undone PlayX Player")
language.Add("Cleanup_gmod_playx", "PlayX Player")
language.Add("Cleaned_gmod_playx", "Cleaned up the PlayX Player")

ENT.Media = nil
ENT.Result = nil
ENT.IsPlaying = false
ENT.LowFramerateMode = false
ENT.DrawCenter = false
ENT.PlayerData = {}
ENT.Volume = 100
ENT.WaitingInjection = false
ENT.LastFinalVolume = -1

--- Initializes the entity.
-- @hidden
function ENT:Initialize()
    if self.KVModel then
        self.Entity:SetModel(self.KVModel)
    end
    
    self.Entity:DrawShadow(false)
    self:UpdateScreenBounds()
    PlayX.RegisterSoundProcessor()
end

--- Prints a debugging message about this entity.
-- @param msg Message
-- @param ... Args for springf
-- @hidden
function ENT:Debug(msg, ...)
    local args = {...}
    PlayX.Debug(tostring(self) .. ": " .. msg, unpack(args))
end

--- Returns true if this instance has media.
-- @return Boolean
function ENT:HasMedia()
    return self.Media ~= nil
end

--- Returns true if this instance has resumable media.
-- @return Boolean
function ENT:IsResumable()
    return self.Media ~= nil and self.Media.ResumeSupported 
end

--- Begins media.
-- @param handler
-- @param uri
-- @param start
-- @param resumeSupported
-- @param lowFramerate
-- @param handlerArgs
function ENT:BeginMedia(handler, uri, start, resumeSupported, lowFramerate, handlerArgs)
    if not PlayX.GetHandler(handler) then
        Error(Format("PlayX: No such handler named %s, can't play %s\n", handler, uri:sub(1, 200)))
    end
    
    self.Media = {
        Handler = handler,
        URI = uri,
        StartTime = RealTime() - start,
        ResumeSupported = resumeSupported,
        LowFramerate = lowFramerate,
        HandlerArgs = handlerArgs,
    }
    
    self.LowFramerateMode = lowFramerate
    
    if PlayX.Enabled then
        if PlayX.DetectCrash() then return end
        self:Play()
    elseif self.IsPlaying then
        self:Stop()
    end
    
    if not PlayX.Enabled then
        if resumeSupported then
            LocalPlayer():ChatPrint(
                "PlayX: Something just started playing! Enable the player to see it."
            )
        else
            LocalPlayer():ChatPrint(
                "PlayX: Something just started playing! Enable the player to " .. 
                "see the next thing played."
            )
        end
    end
    
    self:MediaBegan(handler, uri, start, resumeSupported, lowFramerate, handlerArgs)
    
    PlayX.UpdatePanels()
end

--- Called when media has begun.
-- @param handler
-- @param uri
-- @param start
-- @param resumeSupported
-- @param lowFramerate
-- @param handlerArgs
function ENT:MediaBegan(handler, uri, start, resumeSupported, lowFramerate, handlerArgs)
    hook.Call("PlayXMediaBegan", GAMEMODE, self, handler, uri, start,
        resumeSupported, lowFramerate, handlerArgs)
end

--- Stop what's playing.
function ENT:EndMedia()
    self.Media = nil
    
    if self.IsPlaying then
        self:Stop()
    end
    
    self:MediaEnded()
    
    PlayX.UpdatePanels()
end

function ENT:MediaEnded()
    hook.Call("PlayXMediaEnded", GAMEMODE, self)
end

--- Starts playing. This will only work if the entity has media assigned
-- to it, possibly received from the server.
function ENT:Play()
    if not self.Media then return end
    
    PlayX.ShowNotice()
    PlayX.RegisterSoundProcessor()
    
    local handlerF = PlayX.GetHandler(self.Media.Handler)
    
    -- Get a handler result that contains information on how to play the media
    local result = handlerF(self.HTMLWidth, self.HTMLHeight,
                            RealTime() - self.Media.StartTime,
                            PlayX.GetVolume(), self:GetLocalVolume(),
                            self.Media.URI, self.Media.HandlerArgs)
    
    self.IsPlaying = true
    self.Result = result
    self.DrawCenter = result.Center
    self.PlayerData = {}
    PlayX.CrashDetectionOpen(self)
    
    if not self.Browser then
        self:CreateBrowser()
    end
    
    -- Used for JavaScript->Lua communication
    self.Browser.OpeningURL = function(_, url, target, postdata)
        if not ValidEntity(self) then return end
        
        local query = url:match("^http://playx.sktransport/%?(.*)$")
        if not query then return end
        
        if self.ProcessPlayerData then
            self:ProcessPlayerData(playxlib.ParseQuery(query))
        end
        
        return true -- Prevent navigation
    end
    
    -- Used to inject page
    self.Browser.FinishedURL = function()
        if not ValidEntity(self) then return end
        
        self:Debug("Injecting payload")
        self.WaitingInjection = false
        self:InjectPage()
    end
    
    self:Debug("Loading page...")
    
    -- We begin!
    if result.ForceURL then
        self.WaitingInjection = false
        self.Browser:OpenURL(result.ForceURL)
    else
        self.WaitingInjection = true
        self.Browser:OpenURL(PlayX.HostURL)
    end
    
    self:Played()
    
    PlayX.UpdatePanels()
end

--- Called when media has started playing.
function ENT:Played()
    hook.Call("PlayXPlayed", GAMEMODE, self)
end

--- Stop playing. The play can be resumed at any time (until EndMedia() is
-- called), but not all media can be resumed.
function ENT:Stop()
    if not self.IsPlaying then return end
    
    self.IsPlaying = false
    self.WaitingInjection = false
    self.Result = nil
    self.PlayerData = {}
    self:DestructBrowser()
    
    self:Stopped()
    
    PlayX.UpdatePanels()
end

--- Called on stop.
function ENT:Stopped()
    hook.Call("PlayXStopped", GAMEMODE, self)
end

--- Get the volume of this individual player. Volume is 0 to 100.
-- @return Volume
function ENT:GetVolume()
    return self.Volume
end

--- Changes the volume of this player. This does not affect the overall
-- PlayX volume, nor will it override it.
-- @param volume Volume (0-100) to change to
function ENT:SetVolume(volume)
    if not volume then
        volume = self.Volume
    else
        self.Volume = volume
    end
    
    local finalVolume = math.Clamp(PlayX.GetVolume() / 100 * volume / 100 * 100, 0, 100)
    
    if self.IsPlaying and self.LastFinalVolume ~= finalVolume then
        self.LastFinalVolume = finalVolume
        
        local js = self.Result.GetVolumeChangeJS(finalVolume)
        if js then
            self.Browser:Exec(js)
        end
    end
end

--- Get the local sound volume, which is the PlayX volume combined with this
-- player's individual volume. Value is 0 to 100.
-- @return Volume
function ENT:GetLocalVolume()
    return math.Clamp(PlayX.GetVolume() / 100 * self.Volume / 100 * 100, 0, 100)
end

--- Updates the current media metadata. Calling this while nothing is playing
-- has no effect. This can be called many times and multiple times.
-- @param data Metadata structure
function ENT:UpdateMetadata(data)
    if not self.Media then return end
    
    -- Allow a hook to override the data
    local res = self.MetadataReceive(self.Media, data)
    if res then data = res end
    
    table.Merge(self.Media, data)
end

--- Overridable function that works the same as the hook.
-- @param existingMedia Also accessible as self.Media
-- @param newData Incoming data
-- @return Nil or the new data
function ENT:MetadataReceive(existingMedia, newData)
    return hook.Call("PlayXMetadataReceive", GAMEMODE, self, existingMedia, newData)
end

--- Create the browser.
-- @hidden
function ENT:CreateBrowser()
    self.Browser = vgui.Create("HTML")
    self.Browser:SetMouseInputEnabled(false)        
    self.Browser:SetSize(self.HTMLWidth, self.HTMLHeight)
    self.Browser:SetPaintedManually(true)
    self.Browser:SetVerticalScrollbarEnabled(false)
end

--- Destruct the browser.
-- @hidden
function ENT:DestructBrowser()
    if self.HadStarted then
        self.HadStarted = false
        PlayX.CrashDetectionEnd()
    end
    
    if self.Browser and self.Browser:IsValid() then
        self.Browser:Remove()
    end
    
    self.Browser = nil
    
    PlayX.CrashDetectionClose(self)
end

--- Get the trace used for the projector.
-- @return Trace result
function ENT:GetProjectorTrace()
    -- Potential GC bottleneck?
    local excludeEntities = player.GetAll()
    table.insert(excludeEntities, self.Entity)
    
    local dir = self.Entity:GetForward() * self.Forward * 4000 +
                self.Entity:GetRight() * self.Right * 4000 +
                self.Entity:GetUp() * self.Up * 4000
    local tr = util.QuickTrace(self.Entity:LocalToWorld(self.Entity:OBBCenter()),
                               dir, excludeEntities)
    
    return tr
end

--- Reset the render bounds for this player.
function ENT:ResetRenderBounds()
    local tr = self:GetProjectorTrace()
        
    if tr.Hit then
        -- This makes the screen show all the time
        self:SetRenderBoundsWS(Vector(-1100, -1100, -1100) + tr.HitPos,
                               Vector(1100, 1100, 1100) + tr.HitPos)
    else
       -- This makes the screen show all the time
        self:SetRenderBoundsWS(Vector(-1100, -1100, -1100) + self:GetPos(),
                               Vector(1100, 1100, 1100) + self:GetPos())
    end
end

--- Draw the screen.
-- @hidden
function ENT:Draw()
    self.Entity:DrawModel()
    
    if self.NoScreen then return end
    if not self.DrawScale then return end
    
    render.SuppressEngineLighting(true)
    
    if self.IsProjector then
        local tr = self:GetProjectorTrace()
        
        if tr.Hit then
            local ang = tr.HitNormal:Angle()
            ang:RotateAroundAxis(ang:Forward(), 90) 
            ang:RotateAroundAxis(ang:Right(), -90)
            
            local width = tr.HitPos:Distance(self.Entity:LocalToWorld(self.Entity:OBBCenter())) * 0.001
            local height = width / 2
            local pos = tr.HitPos - ang:Right() * height * self.HTMLHeight / 2
                        - ang:Forward() * width * self.HTMLWidth / 2
                        + ang:Up() * 2
            
            -- This makes the screen show all the time
            self:SetRenderBoundsWS(Vector(-1100, -1100, -1100) + tr.HitPos,
                                   Vector(1100, 1100, 1100) + tr.HitPos)
            
            cam.Start3D2D(pos, ang, width)
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(0, 0, 1024, 512)
            self:DrawScreen(1024 / 2, 512 / 2, 0, 0, 1024, 512)
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
        
        ang:RotateAroundAxis(ang:Right(), self.RotateAroundRight)
        ang:RotateAroundAxis(ang:Up(), self.RotateAroundUp)
        ang:RotateAroundAxis(ang:Forward(), self.RotateAroundForward)
        
        -- This makes the screen show all the time
        self:SetRenderBoundsWS(Vector(-1100, -1100, -1100) + self:GetPos(),
                               Vector(1100, 1100, 1100) + self:GetPos())
        
        cam.Start3D2D(pos, ang, self.DrawScale)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(-self.DrawShiftX, -self.DrawShiftY * shiftMultiplier, self.DrawWidth, self.DrawHeight)
        self:DrawScreen(self.DrawWidth / 2 - self.DrawShiftX,
                        self.DrawHeight / 2 - self.DrawShiftY * shiftMultiplier,
                        -self.DrawShiftX, -self.DrawShiftY * shiftMultiplier,
                        self.DrawWidth, self.DrawHeight)
        cam.End3D2D()
    end

    render.SuppressEngineLighting(false)
end

--- Get player state text has provided by the player in the HTML control. This
-- may return nil, and not all handlers will provide this information. This
-- is used by the radio HUD and radio display.
-- @return Text or nil
-- @hidden
function ENT:GetPlayerStateText()
    local text = self.WaitingInjection and "Initializing..." or nil
    
    if self.PlayerData.State then
        text = self.PlayerData.State
        
        if text == "BUFFERING" then
            text = "Buffering" .. string.rep(".", CurTime() % 3)
        elseif text == "PLAYING" then
            text = "Playing"
        elseif text == "ERROR" then
            text = "Error"
        elseif text == "COMPLETED" then
            text = "Ended"
        elseif text == "STOPPED" then
            text = "Stopped"
        elseif text == "PAUSED" then
            text = "Paused"
        elseif text == "Idle" then
            text = "Idle (Error?)"
        end
    end
    
    return text
end

--- Used to draw the screen content. This function must be called once
-- a 3D2D context has been created.
-- @param centerX Center X
-- @param centerY Center Y
-- @param x Top left position
-- @param y Top left position
-- @param width Width of screen
-- @param height Height of screen
-- @hidden
function ENT:DrawScreen(centerX, centerY, x, y, width, height)
    if self.Browser and self.Browser:IsValid() and self.Media then
        if not self.LowFramerateMode then
            if not self.BrowserMat then return end
            
            render.SetMaterial(self.BrowserMat)
            -- GC issue here?
            render.DrawQuad(Vector(0, 0, 0), Vector(self.HTMLWidth, 0, 0),
                            Vector(self.HTMLWidth, self.HTMLHeight, 0),
                            Vector(0, self.HTMLHeight, 0)) 
        else
            local text = self:GetPlayerStateText() or 
                "Video started in low framerate mode."
            
            if self.Media.Title then
                draw.SimpleText(text,
                                "MenuLarge",
                                centerX, centerY + 20, Color(255, 255, 255, 255),
                                TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                
	            draw.SimpleText(self.Media.Title:sub(1, 50),
	                            "HUDNumber",
	                            centerX, centerY - 50, Color(255, 255, 255, 255),
	                            TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            else
	            draw.SimpleText(text,
	                            "HUDNumber",
	                            centerX, centerY, Color(255, 255, 255, 255),
	                            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            -- Progress bar (terrible looking, yes?)
            if self.PlayerData.Duration or self.PlayerData.Position then
                local pct = self.PlayerData.Duration and 
                    math.Clamp(self.PlayerData.Position / self.PlayerData.Duration, 0, 1) or 0
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawOutlinedRect(centerX - 200, centerY + 5, 400, 10)
                if self.PlayerData.Position and self.PlayerData.Duration then
	                surface.SetDrawColor(255, 0, 0, 255)
	                surface.DrawRect(centerX - 199, centerY + 6, 398 * pct, 8)
                end
                
                if self.PlayerData.Position then
	                draw.SimpleText(playxlib.ReadableTime(self.PlayerData.Position),
	                    "MenuLarge", centerX - 200, centerY + 20,
	                    Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
                
		        if self.PlayerData.Duration then
	                draw.SimpleText(playxlib.ReadableTime(self.PlayerData.Duration),
	                    "MenuLarge", centerX + 200, centerY + 20,
	                    Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	            end
            end
        end
    else
        if PlayX.CrashDetected then
            draw.SimpleText("Disabled due to detected crash (see tool menu -> Options)",
                            "HUDNumber",
                            centerX, centerY, Color(255, 255, 0, 255),
                            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif not PlayX.Enabled then
            draw.SimpleText("Re-enable the player in the tool menu -> Options",
                            "HUDNumber",
                            centerX, centerY, Color(255, 255, 255, 255),
                            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

--- Draw the HUD for the radio.
-- @hidden
function ENT:HUDPaint()
    if not self.DrawScale or not self.NoScreen then return end
    if not self.Media or not self.IsPlaying then return end
    if not PlayX.ShowRadioHUD then return end

    local text = self:GetPlayerStateText()
    
    local hasBottomBar = text or self.PlayerData.Duration or self.PlayerData.Position
    local bw = 320
    local bh = hasBottomBar and 65 or 34
    local bx = ScrW() / 2 - bw / 2
    local by = 15
    
    draw.RoundedBox(6, bx, by, bw, bh, Color(0, 0, 0, 150))
        
    local titleText = self.Media.Title and self.Media.Title:sub(1, 50) 
        or "Title Unavailable"
    draw.SimpleText(titleText,
                    "DefaultBold",
                    ScrW() / 2, 25, Color(255, 255, 255, 255),
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    
    if text then
        draw.SimpleText(text,
                        "Default",
                        ScrW() / 2, by + 40, Color(255, 255, 255, 255),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    -- Progress bar (terrible looking, yes?)
    if self.PlayerData.Duration or self.PlayerData.Position then
        local pct = self.PlayerData.Duration and 
            math.Clamp(self.PlayerData.Position / self.PlayerData.Duration, 0, 1) or 0
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawOutlinedRect(bx + 10, by + 30, bw - 20, 6)
        if self.PlayerData.Position and self.PlayerData.Duration then
	        surface.SetDrawColor(255, 0, 0, 255)
	        surface.DrawRect(bx + 11, by + 31, (bw - 22) * pct, 4)
        end
        
        if self.PlayerData.Position then
	        draw.SimpleText(playxlib.ReadableTime(self.PlayerData.Position),
	            "DefaultBold", bx + 10, by + 40,
	            Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        
        if self.PlayerData.Duration then
	        draw.SimpleText(playxlib.ReadableTime(self.PlayerData.Duration),
	            "DefaultBold`", bx + bw - 10, by + 40,
	            Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	    end
    end
end

--- Think hook to get the material.
-- @hidden
function ENT:Think()
    if self.LowFramerateMode or self.NoScreen then
        self.BrowserMat = nil
    end
    
    if not self.Browser then
        self.BrowserMat = nil
    else
        self.BrowserMat = self.Browser:GetHTMLMaterial()  
    end  
    
    self:NextThink(CurTime() + 0.1)  
end  

--- Called on entity removal. Note that Gmod calls this on a full update
-- even if the entity wasn't deleted. PlayX detect this.
-- @hidden
function ENT:OnRemove()
    PlayX.CrashDetectionClose(self)
    
    local ent = self
    local entIndex = self:EntIndex()
    local browser = self.Browser
    
    -- Give Gmod 200ms to really delete the entity
    timer.Simple(0.2, function()
        if not ValidEntity(ent) then -- Entity is really gone
            if browser and browser:IsValid() then browser:Remove() end
            pcall(hook.Remove, "HUDPaint", "PlayXInfo" .. entIndex)
            PlayX.UpdatePanels()
            PlayX.RegisterSoundProcessor()
        else
            self:Debug("Full update detected; not removing entity")
        end
    end)
end

--- Processes data from the embedded player inside the HTML control.
-- @hidden
function ENT:ProcessPlayerData(data)
    for k, v in pairs(data) do
        if k == "State" then
            self.PlayerData[k] = v
        elseif k == "Position" or k == "Duration" then
            self.PlayerData[k] = tonumber(v)
        end
    end
end

--- Injects the appropriate code into the page.
-- @hidden
function ENT:InjectPage()    
    if not self.Browser or not self.Browser:IsValid() or not self.Result then
        return
    end
    
    if self.Result.ForceURL then
        self.Browser:Exec([[
document.body.style.overflow = 'hidden';
]])
    end
    
    if self.Result.JS then
        self.Browser:Exec(self.Result.JS)
    end
    
    if self.Result.JSInclude then
        self.Browser:Exec([[
var script = document.createElement('script');
script.type = 'text/javascript';
script.src = ']] .. playxlib.JSEscape(self.Result.JSInclude) .. [[';
document.body.appendChild(script);
]])
    elseif self.Result.Body then
        self.Browser:Exec([[
document.body.innerHTML = ']] .. playxlib.JSEscape(self.Result.Body) .. [[';
]])
    end
    
    if not self.Result.ForceURL then
        self.Browser:Exec([[
document.body.style.margin = '0';
document.body.style.padding = '0';
document.body.style.border = '0';
document.body.style.background = '#000000';
document.body.style.overflow = 'hidden';
]])
    end

    if self.Result.CSS then
        self.Browser:Exec([[
var style = document.createElement('style');
style.type = 'text/css';
style.styleSheet.cssText = ']] .. playxlib.JSEscape(self.Result.CSS) .. [[';
document.getElementsByTagName('head')[0].appendChild(style);
]])
    end
    
    if not self.Result.ForceURL and (self.LowFramerateMode or self.NoScreen) then
        self.Browser:Exec([[
var elements = document.getElementsByTagName('*');
for (var i = 0; i < elements.length; i++) {
    elements[i].style.position = 'absolute';
    elements[i].style.top = '-5000px';
    elements[i].style.left = '-5000px';
    elements[i].style.width = '1px';
    elements[i].style.height = '1px';
}
var blocker = document.createElement("div")
with (blocker.style) {
    position = 'fixed';
    top = '0';
    left = '0';
    width = '5000px;'
    height = '5000px';
    zIndex = 9999;
    background = 'black';
}
document.body.appendChild(blocker); 
]])
    end
end