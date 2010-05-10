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

require("datastream")

CreateClientConVar("playx_enabled", 1, true, false)
CreateClientConVar("playx_fps", 14, true, false)
CreateClientConVar("playx_volume", 80, true, false)
CreateClientConVar("playx_provider", "", false, false)
CreateClientConVar("playx_uri", "", false, false)
CreateClientConVar("playx_start_time", "0:00", false, false)
CreateClientConVar("playx_force_low_framerate", 0, false, false)
CreateClientConVar("playx_use_jw", 1, false, false)
CreateClientConVar("playx_ignore_length", 0, false, false)
CreateClientConVar("playx_use_chrome", 1, true, false)
CreateClientConVar("playx_error_windows", 1, true, false)

PlayX = {}

include("playx/client/bookmarks.lua")
include("playx/client/handlers.lua")
include("playx/client/panel.lua")
include("playx/client/engines/html.lua")
include("playx/client/engines/gm_chrome.lua")

PlayX.Enabled = GetConVar("playx_enabled"):GetBool()
PlayX.JWPlayerURL = "http://playx.googlecode.com/svn/jwplayer/player.swf"
PlayX.HostURL = "http://sk89q.github.com/playx/host/host.html"
PlayX.Providers = {}

--- Checks if a player instance exists in the game.
-- @return Whether a player exists
function PlayX.PlayerExists()
    return table.Count(ents.FindByClass("gmod_playx")) > 0
end

--- Get all the PlayX entities.
-- @return List of entities
function PlayX.GetInstances()
    return ents.FindByClass("gmod_playx")
end

--- Returns true if any of the local instances have media.
-- @return Boolean
function PlayX.HasMedia()
    for _, v in pairs(PlayX.GetInstances()) do
        if v:HasMedia() then return true end
    end
    
    return false
end

--- Returns true if any of the instances are playing.
-- @return Boolean
function PlayX.HasPlaying()
    for _, v in pairs(PlayX.GetInstances()) do
        if v:IsPlaying() then return true end
    end
    
    return false
end

--- Gets the number of instances that are currently playing.
-- @return Number
function PlayX.GetPlayingCount()
    local count = 0
    
    for _, v in pairs(PlayX.GetInstances()) do
        if v:IsPlaying() then count = count + 1 end
    end
    
    return count
end

--- Checks whether any media being played can be resumed.
-- @return Boolean
function PlayX.HasResumable()
    for _, v in pairs(PlayX.GetInstances()) do
        if v:IsResumable() then return true end
    end
    
    return false
end

--- Gets the number of instances that can be resumed.
-- @return Number
function PlayX.GetResumableCount()
    local count = 0
    
    for _, v in pairs(PlayX.GetInstances()) do
        if v:IsResumable() then count = count + 1 end
    end
    
    return count
end

--- Gets the class for an engine by name. May return nil.
-- @param name Name of engine
-- @return Engine class
function PlayX.GetEngine(name)
    return list.Get("PlayXEngines")[name]
end

--- Converts handler and arguments into an appropriate engine.
-- @param handler
-- @param args
-- @param width
-- @param height
-- @param start
-- @param volume
function PlayX.ResolveHandler(handler, args, screenWidth, screenHeight,
                              start, volume)
    -- See if there is a hook for resolving handlers
    local result = hook.Call("PlayXResolveHandler", GAMEMODE, handler)
    
    if result then
        return result
    end
    
    local handlers = list.Get("PlayXHandlers")
    
    if handlers[handler] then
        return handlers[handler](args, screenWidth, screenHeight, start, volume)
    else
        Error("PlayX: Unknown handler: " .. tostring(handler))
    end
end

--- Resume playing of everything.
function PlayX.ResumePlay()
    if not PlayX.HasMedia() then
        PlayX.ShowError("Nothing is playing.")
    else
        local count = 0
        
        for _, v in pairs(PlayX.GetInstances()) do
            if v:IsResumable() then
                v:Start()
                count = count + 1
            end
        end
        
        if count == 0 then
            PlayX.ShowError("The media being played cannot be resumed.")
        end
    end
    
    PlayX.UpdatePanels()
end

--- Stops playing everything.
function PlayX.StopPlay()
    if not PlayX.HasMedia() then
        PlayX.ShowError("Nothing is playing.\n")
    else
        for _, v in pairs(PlayX.GetInstances()) do
            v:Stop()
        end
    end
    
    PlayX.UpdatePanels()
end
PlayX.HidePlayer = PlayX.StopPlay -- Legacy

--- Reset the render bounds of the projector screen.
function PlayX.ResetRenderBounds()
    if not PlayX.PlayerExists() then
        PlayX.ShowError("Nothing is playing.\n")
    elseif PlayX.Enabled then
        for _, v in pairs(PlayX.GetInstances()) do
            v:ResetRenderBounds()
        end
    end
end

--- Sends a request to the server to play something.
-- @param provider Name of provider, leave blank to auto-detect
-- @param uri URI to play
-- @param start Time to start the video at, in seconds
-- @param forceLowFramerate Force the client side players to play at 1 FPS
-- @param useJW True to allow the use of the JW player, false for otherwise, nil to default true
-- @param ignoreLength True to not check the length of the video (for auto-close)
-- @return The result generated by a provider, or nil and the error message
function PlayX.RequestOpenMedia(provider, uri, start, forceLowFramerate, useJW, ignoreLength)
    if useJW == nil then useJW = true end
    
    RunConsoleCommand("playx_open", uri, provider, start,
                      forceLowFramerate and 1 or 0, useJW and 1 or 0,
                      ignoreLength and 1 or 0)
end

--- Sends a request to the server to stop playing.
function PlayX.RequestCloseMedia()
    RunConsoleCommand("playx_close")
end

--- Enables the player.
function PlayX.Enable()
    RunConsoleCommand("playx_enabled", "1")
end

--- Disables the player.
function PlayX.Disable()
    RunConsoleCommand("playx_enabled", "0")
end

--- Gets the player FPS.
-- @return FPS
function PlayX.GetPlayerFPS()
    return math.Clamp(GetConVar("playx_fps"):GetInt(), 1, 30)
end

--- Sets the player FPS
-- @param fps Number between 1 and 30
function PlayX.SetPlayerFPS(fps)
    RunConsoleCommand("playx_fps", fps)
end

--- Gets the player volume.
-- @return Number between 0 and 100
function PlayX.GetPlayerVolume()
    return math.Clamp(GetConVar("playx_volume"):GetInt(), 0, 100)
end

--- Sets the player volume.
-- @param vol Number between 0 and 100
function PlayX.SetPlayerVolume(vol)
    RunConsoleCommand("playx_volume", vol)
end

--- Opens the dialog for choosing a model to spawn the player with.
function PlayX.OpenSpawnDialog()
    if spawnWindow and spawnWindow:IsValid() then
        return
    end
    
    local frame = vgui.Create("DFrame")
    frame:SetDeleteOnClose(true)
    frame:SetTitle("Select Model for PlayX Player")
    frame:SetSize(275, 400)
    frame:SetSizable(true)
    frame:Center()
    frame:MakePopup()
    spawnWindow = frame
    
    local modelList = vgui.Create("DPanelList", frame)
    modelList:EnableHorizontal(true)
    modelList:SetPadding(5)
    
    for model, _ in pairs(PlayXScreens) do
        local spawnIcon = vgui.Create("SpawnIcon", modelList)
        
        spawnIcon:SetModel(model)
        spawnIcon.Model = model
        spawnIcon.DoClick = function()
            surface.PlaySound("ui/buttonclickrelease.wav")
            RunConsoleCommand("playx_spawn", spawnIcon.Model)
            frame:Close()
        end
        
        modelList:AddItem(spawnIcon)
    end
    
    local cancelButton = vgui.Create("DButton", frame)
    cancelButton:SetText("Cancel")
    cancelButton:SetWide(80)
    cancelButton.DoClick = function()
        frame:Close()
    end
    
    local customModelButton = vgui.Create("DButton", frame)
    customModelButton:SetText("Custom...")
    customModelButton:SetWide(80)
    customModelButton:SetTooltip("Try PlayX's \"best attempt\" at using an arbitrary model")
    customModelButton.DoClick = function()
        Derma_StringRequest("Custom Model", "Enter a model path (i.e. models/props_lab/blastdoor001c.mdl)", "",
            function(text)
                local text = text:Trim()
                if text ~= "" then
                    RunConsoleCommand("playx_spawn", text)
                    frame:Close()
                else
                    Derma_Message("You didn't enter a model path.", "Error", "OK")
                end
            end)
    end
    
    local oldPerform = frame.PerformLayout
    frame.PerformLayout = function()
        oldPerform(frame)
        modelList:StretchToParent(5, 25, 5, 35)
        cancelButton:SetPos(frame:GetWide() - cancelButton:GetWide() - 5,
                            frame:GetTall() - cancelButton:GetTall() - 5)
        customModelButton:SetPos(frame:GetWide() - cancelButton:GetWide() - customModelButton:GetWide() - 8,
                            frame:GetTall() - customModelButton:GetTall() - 5)
    end
    
    frame:InvalidateLayout(true, true)
end

--- Opens the update window.
-- @param ver
function PlayX.OpenUpdateWindow(ver)
    if ver == nil then
        RunConsoleCommand("playx_update_info")
        return
    end
    
    if updateWindow and updateWindow:IsValid() then
        return
    end
    
    local url = "http://playx.sk89q.com/update/?version=" .. playxlib.URLEscape(ver)
    
    local frame = vgui.Create("DFrame")
    updateWindow = frame
    frame:SetTitle("PlayX Update News")
    frame:SetDeleteOnClose(true)
    frame:SetScreenLock(true)
    frame:SetSize(math.min(780, ScrW() - 0), ScrH() * 4/5)
    frame:SetSizable(true)
    frame:Center()
    frame:MakePopup()
    
    local browser = vgui.Create("HTML", frame)
    browser:SetVerticalScrollbarEnabled(false)
    browser:OpenURL(url)

    -- Layout
    local oldPerform = frame.PerformLayout
    frame.PerformLayout = function()
        oldPerform(frame)
        browser:StretchToParent(10, 28, 10, 10)
    end
    
    frame:InvalidateLayout(true, true)
end

--- Shows a hint.
-- @param msg
function PlayX.ShowHint(msg)
    GAMEMODE:AddNotify(msg, NOTIFY_GENERIC, 10);
    surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
end

--- Shows an error message.
-- @param err
function PlayX.ShowError(err)
    -- See if there is a hook for showing errors
    if hook.Call("PlayXShowError", GAMEMODE, err) ~= nil then
        return
    end

    if GetConVar("playx_error_windows"):GetBool() then
        Derma_Message(err, "Error", "OK")
        gui.EnableScreenClicker(true)
        gui.EnableScreenClicker(false)
    else
        GAMEMODE:AddNotify("PlayX error: " .. tostring(err), NOTIFY_ERROR, 7)
        surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
    end
end

--- Called on PlayXBegin user message.
-- Sent when the server tell the client to play media. This may happen if the
-- user gets subscribed from a player.
local function HandleBeginMessage(_, id, encoded, decoded)
    local ent = decoded.Entity
    local handler = decoded.Handler
    local arguments = decoded.Arguments
    local playAge = decoded.PlayAge
    local resumable = decoded.Resumable
    local lowFramerate = decoded.LowFramerate
    local startTime = CurTime() - playAge
    
    MsgN("PlayX: Received PlayXBegin with handler " .. handler)
    
    if ValidEntity(ent) then
        ent:Begin(handler, arguments, resumable, lowFramerate, startTime)
        
        if PlayX.Enabled then
            ent:Start()
        end
    else
        Error("PlayXBegin message referred to non-existent entity")
    end
    
    PlayX.UpdatePanels()
end

--- Handle the providers list.
local function HandleProvidersList(_, id, encoded, decoded)
    PlayX.Providers = decoded.List
end

--- Called on PlayXEnd user message.
-- Sent when the server tell the client to stop playing. This may happen if
-- the user gets unsubscribed from a player.
local function HandleEndMessage(um)
    local ent = um:ReadEntity()
    
    if ValidEntity(ent) then
        ent:End()
    else
        Error("PlayXEnd message referred to non-existent entity")
    end
    
    PlayX.UpdatePanels()
end

--- Called on PlayXError user message.
-- Sent when an error needs to be displayed.
local function HandleError(um)
    local err = um:ReadString()
    
    PlayX.ShowError(err)
end

datastream.Hook("PlayXBegin", HandleBeginMessage)
datastream.Hook("PlayXProvidersList", HandleProvidersList)
usermessage.Hook("PlayXEnd", HandleEndMessage)
usermessage.Hook("PlayXSpawnDialog", function() PlayX.OpenSpawnDialog() end)
usermessage.Hook("PlayXError", HandleError)

--- Called on playx_enabled change.
local function EnabledCallback(cvar, old, new)
    for _, instance in pairs(PlayX.GetInstances()) do
        if PlayX.Enabled then
            instance:Stop()
        else
            instance:Start()
        end
    end
    
    PlayX.UpdatePanels()
end

--- Called on playx_fps change.
local function FPSChangeCallback(cvar, old, new)
    for _, instance in pairs(PlayX.GetInstances()) do
        instance:UpdateFPS()
    end
end

--- Called on playx_volume change.
local function VolumeChangeCallback(cvar, old, new)
    hook.Call("PlayXVolumeChanged", GAMEMODE, PlayX.GetPlayerVolume())
    
    for _, instance in pairs(PlayX.GetInstances()) do
        instance:UpdateVolume()
    end
end

cvars.AddChangeCallback("playx_enabled", EnabledCallback)
cvars.AddChangeCallback("playx_fps", FPSChangeCallback)
cvars.AddChangeCallback("playx_volume", VolumeChangeCallback)

--- Called for concmd playx_gui_open.
local function ConCmdGUIOpen()
    -- Let's handle bookmark keywords
    if GetConVar("playx_provider"):GetString() == "" then
        local bookmark = PlayX.GetBookmarkByKeyword(GetConVar("playx_uri"):GetString())
        if bookmark then
            bookmark:Play()
            return
        end
    end
    
    PlayX.RequestOpenMedia(GetConVar("playx_provider"):GetString(),
                           GetConVar("playx_uri"):GetString(),
                           GetConVar("playx_start_time"):GetString(),
                           GetConVar("playx_force_low_framerate"):GetBool(),
                           GetConVar("playx_use_jw"):GetBool(),
                           GetConVar("playx_ignore_length"):GetBool())
end

concommand.Add("playx_resume", function() PlayX.ResumePlay() end)
concommand.Add("playx_hide", function() PlayX.HidePlayer() end)
concommand.Add("playx_reset_render_bounds", function() PlayX.ResetRenderBounds() end)
concommand.Add("playx_gui_open", ConCmdGUIOpen)
concommand.Add("playx_gui_close", function() PlayX.RequestCloseMedia() end)
concommand.Add("playx_dump_html", function() PlayX.GetHTML() end)
concommand.Add("playx_update_window", function() PlayX.OpenUpdateWindow() end)