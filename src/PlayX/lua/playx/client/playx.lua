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
CreateConVar("playx_host_url", "http://localhost/playx/host.html", {FCVAR_REPLICATED, FCVAR_ARCHIVE})

PlayX = {}

include("playx/client/bookmarks.lua")
include("playx/client/providers.lua")
include("playx/client/panel.lua")

PlayX.Enabled = true
PlayX.Playing = false
PlayX.CurrentMedia = nil
PlayX.SeenNotice = false
PlayX.JWPlayerURL = ""
PlayX.HasChrome = chrome ~= nil and chrome.NewBrowser ~= nil
PlayX.SupportsChrome = chrome ~= nil and chrome.NewBrowser ~= nil

PlayX.ProcMat = nil
PlayX.ProcMatSq = nil

if PlayX.SupportsChrome then
    Msg("PlayX DEBUG: gm_chrome detected\n")
    
    local mat = Material("playx/screen")
    local matSq = Material("playx/screen_sq")

    if mat and matSq then
        PlayX.ProcMat = {
            Material = mat,
            Texture = mat:GetMaterialTexture("$basetexture"),
            TextureID = surface.GetTextureID("playx/screen"),
            Width = 1024,
            Height = 512,
        }
        PlayX.ProcMatSq = {
            Material = matSq,
            Texture = matSq:GetMaterialTexture("$basetexture"),
            TextureID = surface.GetTextureID("playx/screen_sq"),
            Width = 1024,
            Height = 1024,
        }
        
        Msg("PlayX DEBUG: playx/screen and playx/screen_sq materials detected\n")
    else
        PlayX.SupportsChrome = false
        
        Msg("PlayX DEBUG: playx/screen and playx/screen_sq materials not detected; gm_chrome is unavailable\n")
    end
end

--- Internal function to update the FPS of the current player instance.
local function DoFPSChange()
    if PlayX.PlayerExists() then
        PlayX.GetInstance():SetFPS(PlayX:GetPlayerFPS())
    end
end

--- Begins play of media on the instance.
local function BeginPlay()
    DoFPSChange()
    
    PlayX.GetInstance().LowFramerateMode = PlayX.CurrentMedia.LowFramerate
    PlayX.GetInstance():Play(PlayX.CurrentMedia.Handler, PlayX.CurrentMedia.URI,
                             CurTime() - PlayX.CurrentMedia.StartTime,
                             PlayX.GetPlayerVolume(), PlayX.CurrentMedia.HandlerArgs)
    
    if not PlayX.SeenNotice then
        PlayX.ShowHint("Want to stop what's playing? Go to the Q menu > Options > PlayX")
        PlayX.SeenNotice = true
    end
    
    PlayX.Playing = true
    
    PlayX.UpdatePanels()
end

--- Ends play on the instance.
local function EndPlay()
    PlayX.GetInstance():Stop()
    PlayX.Playing = false
    
    PlayX.UpdatePanels()
end

--- Enables the player.
local function DoEnable()
    if PlayX.Enabled then return end
    
    PlayX.Enabled = true
    
    if PlayX.PlayerExists() then
        if PlayX.CurrentMedia and PlayX.CurrentMedia.ResumeSupported then
            BeginPlay()
        end
    end
end

--- Disables the player.
local function DoDisable()
    if not PlayX.Enabled then return end
    
    PlayX.Enabled = false
    
    if PlayX.PlayerExists() then
        if PlayX.CurrentMedia and PlayX.Playing then
            EndPlay()
        end
    end
end

--- Checks whether the player is spawned.
-- @return
function PlayX.PlayerExists()
    return table.Count(ents.FindByClass("gmod_playx")) > 0
end

--- Gets the player instance entity
-- @return Entity or nil
function PlayX.GetInstance()
    local props = ents.FindByClass("gmod_playx")
    return props[1]
end

--- Used to get the HTML, namely for debugging purposes.
function PlayX.GetHTML()
    if PlayX.PlayerExists() then
        return PlayX.GetInstance().CurrentPage:GetHTML()
    end
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
-- @return
function PlayX.GetPlayerFPS()
    return math.Clamp(GetConVar("playx_fps"):GetInt(), 1, 30)
end

--- Sets the player FPS
-- @param fps
function PlayX.SetPlayerFPS(fps)
    RunConsoleCommand("playx_fps", fps)
end

--- Gets the player volume.
-- @return
function PlayX.GetPlayerVolume()
    return math.Clamp(GetConVar("playx_volume"):GetInt(), 0, 100)
end

--- Sets the player volume.
-- @return
function PlayX.SetPlayerVolume(vol)
    RunConsoleCommand("playx_volume", vol)
end

--- Checks to see if the user enabled gm_chrome. It does not check to see
-- whether it is supported, however. Use PlayX.SupportsChrome for that.
-- @return
function PlayX.ChromeEnabled()
    return GetConVar("playx_use_chrome"):GetBool()
end

--- Gets the host page URL.
-- @return
function PlayX.GetHostURL()
    return GetConVar("playx_host_url"):GetString()
end

--- Resume playing if it is not already playing. Error messages will 
-- be printed to console. 
function PlayX.ResumePlay()
    if not PlayX.PlayerExists() then
        Msg("There is no PlayX player spawned!\n")
    elseif not PlayX.CurrentMedia then
        Msg("No media is queued to play!\n")
    elseif not PlayX.CurrentMedia.ResumeSupported then
        Msg("The current media cannot be resumed.\n")
    elseif PlayX.Enabled then
        BeginPlay()
    end
end

--- Hides the player and stops it. Error messages will be printed to
-- console. 
function PlayX.HidePlayer()
    if not PlayX.PlayerExists() then
        Msg("There is no PlayX player spawned!\n")
    elseif not PlayX.CurrentMedia then
        Msg("No media is queued to play!\n")
    elseif PlayX.Enabled then
        EndPlay()
    end
end

--- Reset the render bounds of the project screen. Error messages will be
-- printed to console.
function PlayX.ResetRenderBounds()
    if not PlayX.PlayerExists() then
        Msg("There is no PlayX player spawned!\n")
    elseif not PlayX.GetInstance().IsProjector then
        Msg("The player is not a projector.\n")
    else
        PlayX.GetInstance():ResetRenderBounds()
    end
end

--- Puts in a request to open media. A request will be sent to the
-- server for processing.
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

--- Puts in a request to close media. A request will be sent to the server
-- for processing.
function PlayX.RequestCloseMedia()
    RunConsoleCommand("playx_close")
end

--- Opens the dialog for choosing a model to spawn the player with.
function PlayX.OpenSpawnDialog()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Select Model for PlayX Player")
    frame:SetSize(300, 200)
    frame:SetSizable(false)
    frame:Center()
    frame:MakePopup()
    
    local modelList = vgui.Create("DPanelList", frame)
    modelList:EnableHorizontal(true)
    modelList:SetPadding(5)
    modelList:SetPos(1, 25)
    modelList:SetSize(298, 174)
    
    for model, _ in pairs(PlayXScreens) do
        local spawnIcon = vgui.Create("SpawnIcon", modelList)
        
        spawnIcon:SetModel(model)
        spawnIcon.Model = model
        
        function spawnIcon.DoClick()
            surface.PlaySound("ui/buttonclickrelease.wav")
            RunConsoleCommand("playx_spawn", spawnIcon.Model)
            frame:Close()
        end
        
        modelList:AddItem(spawnIcon)
    end
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
    GAMEMODE:AddNotify("PlayX error: " .. tostring(err), NOTIFY_ERROR, 7);
    surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
end

--- Called on playx_enabled change.
local function EnabledCallback(cvar, old, new)
    if GetConVar("playx_enabled"):GetBool() then
        DoEnable()
    else
        DoDisable()
    end
    
    PlayX.UpdatePanels()
end

--- Called on playx_fps change.
local function FPSChangeCallback(cvar, old, new)
    DoFPSChange()
end

--- Called on playx_volume change.
local function VolumeChangeCallback(cvar, old, new)
    if PlayX.PlayerExists() and PlayX.CurrentMedia then
        PlayX.GetInstance():ChangeVolume(PlayX.GetPlayerVolume())
    end
end

cvars.AddChangeCallback("playx_enabled", EnabledCallback)
cvars.AddChangeCallback("playx_fps", FPSChangeCallback)
cvars.AddChangeCallback("playx_volume", VolumeChangeCallback)

PlayX.Enabled = GetConVar("playx_enabled"):GetBool()

--- Called on PlayXBegin user message.
local function DSBegin(_, id, encoded, decoded)
    Msg("PlayX DEBUG: Begin media message received\n")
    
    if not PlayX.PlayerExists() then -- This should not happen
        ErrorNoHalt("Undefined state DS_BEGIN_NO_PLAYER; please report error")
        return
    end
    
    local handler = decoded.Handler
    local uri = decoded.URI
    local playAge = decoded.PlayAge
    local resumeSupported = decoded.ResumeSupported
    local lowFramerate = decoded.LowFramerate
    local handlerArgs = decoded.HandlerArgs
    
    PlayX.Playing = true
    PlayX.CurrentMedia = nil
    
    if PlayX.Handlers[handler] then
        if uri:len() > 325 then
            print(string.format("PlayX: Playing %s using handler %s", uri, handler))
        else
            Msg(string.format("PlayX: Playing %s using handler %s\n", uri, handler))
        end
        
        PlayX.CurrentMedia = {
            ["Handler"] = handler,
            ["URI"] = uri,
            ["StartTime"] = CurTime() - playAge,
            ["ResumeSupported"] = resumeSupported,
            ["LowFramerate"] = lowFramerate,
            ["HandlerArgs"] = handlerArgs,
        }
        
        if PlayX.Enabled then
            BeginPlay()
        else
            PlayX.UpdatePanels() -- This matters for the admin, as the "End Media" button needs to be updated
            
            if resumeSupported then
                LocalPlayer():ChatPrint("PlayX: A video or something just started playing! Enable the player to see it.") 
            else
                LocalPlayer():ChatPrint("PlayX: A video or something just started playing! Enable the player to see the next thing that gets played.") 
            end
        end
    else
        Msg(string.format("PlayX: No such handler named %s, can't play %s\n", handler, uri))
    end
end

--- Called on PlayXEnd user message.
local function UMsgEnd(um)
    Msg("PlayX DEBUG: Eng umsg received\n")
    
    PlayX.CurrentMedia = nil
    
    if PlayX.PlayerExists() and PlayX.Playing and PlayX.Enabled then
        EndPlay()
    else
        PlayX.UpdatePanels() -- To make sure
    end
end

--- Called on PlayXSpawnDialog user message.
local function UMsgSpawnDialog(um)
    Msg("PlayX DEBUG: Spawn dialog request received\n")
    
    PlayX.OpenSpawnDialog()
end

--- Called on PlayXJWURL user message.
local function UMsgJWURL(um)
    Msg("PlayX DEBUG: JW URL set\n")
    
    PlayX.JWPlayerURL = um:ReadString()
    
    PlayX.UpdatePanels()
end

--- Called on PlayXError user message.
local function UMsgError(um)
    local err = um:ReadString()
    
    PlayX.ShowError(err)
end

datastream.Hook("PlayXBegin", DSBegin)
usermessage.Hook("PlayXEnd", UMsgEnd)
usermessage.Hook("PlayXSpawnDialog", UMsgSpawnDialog)
usermessage.Hook("PlayXJWURL", UMsgJWURL)
usermessage.Hook("PlayXError", UMsgError)

--- Called for concmd playx_resume.
local function ConCmdResume()
    PlayX.ResumePlay()
end

--- Called for concmd playx_hide.
local function ConCmdHide()
    PlayX.HidePlayer()
end

--- Called for concmd playx_reset_render_bounds.
local function ConCmdResetRenderBounds()
    PlayX.ResetRenderBounds()
end

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

--- Called for concmd playx_gui_close.
local function ConCmdGUIClose()
    PlayX.RequestCloseMedia()
end

--- Called for concmd playx_dump_html.
local function ConCmdDumpHTML()
    print(PlayX.GetHTML())
end

concommand.Add("playx_resume", ConCmdResume)
concommand.Add("playx_hide", ConCmdHide)
concommand.Add("playx_reset_render_bounds", ConCmdResetRenderBounds)
concommand.Add("playx_gui_open", ConCmdGUIOpen)
concommand.Add("playx_gui_close", ConCmdGUIClose)
concommand.Add("playx_dump_html", ConCmdDumpHTML) -- Debug function