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

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
resource.AddFile("materials/vgui/entities/gmod_playx.vmt")

include("shared.lua")

ENT.Subscribers = {}
ENT.Media = nil
ENT.LastOpenTime = 0
ENT.LastWireOpenTime = 0
ENT.InputProvider = ""
ENT.InputURI = ""
ENT.InputStartAt = 0
ENT.InputDisableJW = false
ENT.InputForceLowFramerate = false

--- Initialize the entity.
-- @hidden
function ENT:Initialize()
    if self.KVModel then
        self.Entity:SetModel(self.KVModel)
    end
    
    self.Entity:PhysicsInit(SOLID_VPHYSICS)
    self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
    self.Entity:SetSolid(SOLID_VPHYSICS)
    self.Entity:DrawShadow(false)
    
    if WireAddon then
        self.Inputs = Wire_CreateInputs(self.Entity, {
            "Provider [STRING]",
            "URI [STRING]",
            "StartAt",
            "DisableJW",
            "ForceLowFramerate",
            "Open",
            "Close",
        })
        
        self.Outputs = Wire_CreateOutputs(self.Entity, {
            "InputError [STRING]",
            "Provider [STRING]",
            "Handler [STRING]",
            "URI [STRING]",
            "Start",
            "ActualStartTime",
            "Length",
            "URL [STRING]",
            "Title [STRING]",
            "Description [STRING]",
            "Tags [ARRAY]",
            "DatePublished",
            "DateModified",
            "Submitter [STRING]",
            "SubmitterURL [STRING]",
            "SubmitterAvatar [STRING]",
            "Faved",
            "Views",
            "Comments",
            "NormalizedRating",
            "RatingCount",
            "Thumbnail [STRING]",
            "Width",
            "Height",
            "IsLive",
            "ViewerCount",
        })
        
        self:ClearWireOutputs()
    end
    
    -- Auto-subscribe
    for _, ply in pairs(player.GetHumans()) do
        if PlayX.ShouldAutoSubscribe(ply, self) then
            self:Subscribe(ply)
        end
    end
    
    self:SetUseType(SIMPLE_USE)
    self:UpdateScreenBounds()
end

--- Add a user to this player's subscription list. The user will start 
-- seeing the media if something is already playing. If the player is already
-- subscribed, nothing will happen.
-- @param ply
-- @return False if the player was already subscribed
function ENT:Subscribe(ply)
    if self.Subscribers[ply] then return false end
    
    if hook.Call("PlayXSubscribe", GAMEMODE, self, ply) == false then
        return
    end
    
    self.Subscribers[ply] = true
    
    -- Something is already playing -- send the user the information
    if self.Media and self.Media.ResumeSupported and
        (not self.Media.Length or self.Media.StartTime + self.Media.Length > RealTime()) then
        self:SendBeginMessage(ply)
        self:SendStdMetadataMessage(ply)
    end
    
    return true
end

--- Remove the user from this player's subscription list. The media will stop
-- for the player. If the player was not subscribed, then nothing will happen.
-- @param ply
-- @return False if the player was not subscribed to begin with
function ENT:Unsubscribe(ply)
    if not self.Subscribers[ply] then return false end
    
    if hook.Call("PlayXUnsubscribe", GAMEMODE, self, ply) == false then
        return
    end
    
    self.Subscribers[ply] = nil
    
    -- Something is playing -- tell the user to stop
    if self.Media then
        self:SendEndMessage(ply)
    end
    
    return true
end

--- Gets a list of Player objects.
-- @return Table of subscribers
function ENT:GetSubscribers()
    local subscribers = {}
    for ply, _ in pairs(self.Subscribers) do
        table.insert(subscribers, ply)
    end
    return subscribers
end

--- Returns true if the passed player has subscribed to this instance.
-- @return Boolean
function ENT:IsSubscribed(ply)
    return self.Subscribers[ply] and true or false
end

--- Plays something as if you had typed it in the tool panel. It will attempt
-- to guess the handler frrom the provided provider and URI. If you've already
-- got a handler to play, look into BeginMedia(). You can manually detect
-- providers using the PlayX.ResolveProvider() API function.
-- @param provider Name of provider, leave blank to auto-detect
-- @param uri URI to play
-- @param start Time to start the video at, in seconds
-- @param forceLowFramerate Force the client side players to play at 1 FPS
-- @param useJW True to allow the use of the JW player, false for otherwise, nil to default true
-- @param ignoreLength True to not check the length of the video (for auto-close)
-- @return The result generated by a provider or nil
-- @return Error message if error
function ENT:OpenMedia(provider, uri, start, forceLowFramerate, useJW, ignoreLength)
    local start = start or 0
    local useJW = (useJW or true) and PlayX.IsUsingJW()
    
    -- Validate input
    if uri == "" then return false, "No URI provided" end
    
    -- Resolve the provider
    local provider, result = PlayX.ResolveProvider(provider, uri, useJW)
    if provider == nil then
        return false, result    
    end
    
    local r, err = hook.Call("PlayXMediaOpen", GAMEMODE, self, 
        provider, uri, start, forceLowFramerate, useJW, ignoreLength, provider, result)
    if r == false then
        return false, err
    elseif r ~= nil and r ~= true then
        result = r
    end
    
    -- Override low framerate mode
    local useLowFramerate = result.LowFramerate
    if forceLowFramerate then
        useLowFramerate = true
    end
    
    self:BeginMedia(result.Handler, result.URI, start, result.ResumeSupported,
                    useLowFramerate, result.HandlerArgs)
    self:UpdateMetadata({ Provider = provider })
    
    -- Fetch metadata information
    if result.QueryMetadata then
        result.QueryMetadata(function(data)
            if ValidEntity(self) then self:UpdateMetadata(data) end
        end,
        function(err)
            if ValidEntity(self) then self.OnMetadataError(err) end
        end)
    end
    
    return result
end

--- This directly processes media given as a handler. Use OpenMedia() if
-- you want provider detection. Use PlayX.ResolveProvider() if you want to do
-- provider detection manually. Remember that if you want metadata later on,
-- you will have to manually supply this entity with it, as BeginMedia() does
-- not do that (OpenMedia() does, but because it polls the provider framework).
-- @param handler
-- @param uri
-- @param start
-- @param resumeSupported
-- @param lowFramerate
-- @param length Length of the media in seconds, can be nil
-- @param handlerArgs Arguments for the handler, can be nil
function ENT:BeginMedia(handler, uri, start, resumeSupported, lowFramerate, handlerArgs)
    local start = start or 0
    local resumeSupported = resumeSupported or false
    local lowFramerate = lowFramerate or false
    local handlerArgs = handlerArgs or {}
    
    local res = hook.Call("PlayXMediaBegin", GAMEMODE, self, handler, uri, start,
                          resumeSupported, lowFramerate, handlerArgs)
    
    -- Let the hook deny play for whatever reason
    if res == false then
        return false
    end
    
    self.LastOpenTime = RealTime()
    
    self.Media = {
        Handler = handler,
        URI = uri,
        StartAt = start,
        StartTime = RealTime() - start,
        ResumeSupported = resumeSupported,
        LowFramerate = lowFramerate,
        HandlerArgs = handlerArgs,
        
        -- Filled by metadata functions
        Provider = nil,
        
        -- Filled by metadata functions from provider
        URL = nil,
        Title = nil,
        Description = nil,
        Length = nil,
        Tags = nil,
        DatePublished = nil,
        DateModified = nil,
        Submitter = nil,
        SubmitterURL = nil,
        SubmitterAvatar = nil,
        NumFaves = nil,
        NumViews = nil,
        NumComments = nil,
        RatingNorm = nil,
        NumRatings = nil,
        Thumbnail = nil,
        Width = nil,
        Height = nil,
        IsLive = nil,
        ViewerCount = nil,
    }
    
    hook.Call("PlayXMediaBegan", GAMEMODE, self, handler, uri, start,
        resumeSupported, lowFramerate, handlerArgs)
    
    -- Tell all subscribers of the media
    self:SendBeginMessage()
    
    return true
end

--- Send a play begin message to clients. If no argument is provided, the
-- message will be sent to all players subscribed to this entity. This is
-- called by PlayX automatically on video start and when a player is 
-- subscribed, so there is no need to call this on your own.
-- @param ply
-- @hidden
function ENT:SendBeginMessage(ply)
    local filter = ply or self:GetSubscribers()
    
    -- See if we can fit it in a usermessage
    local strLength = string.len(self.Media.Handler) +
                      string.len(self.Media.URI)
    
    if next(self.Media.HandlerArgs) == nil and strLength <= 200 then
        umsg.Start("PlayXBegin", filter)
        umsg.Entity(self)
        umsg.String(self.Media.Handler)
        umsg.String(self.Media.URI)
        umsg.Long(RealTime() - self.Media.StartTime) -- To be safe
        umsg.Bool(self.Media.ResumeSupported)
        umsg.Bool(self.Media.LowFramerate)
        umsg.End()
    else
	    datastream.StreamToClients(filter, "PlayXBegin", {
            Entity = self,
	        Handler = self.Media.Handler,
	        URI = self.Media.URI,
	        PlayAge = RealTime() - self.Media.StartTime,
	        ResumeSupported = self.Media.ResumeSupported,
	        LowFramerate = self.Media.LowFramerate,
	        HandlerArgs = self.Media.HandlerArgs,
	    })
	end
end

--- Safe method of ending the media. This can be called even if nothing is
-- being played at the moment.
function ENT:CloseMedia()
    if self.Media then
        self:EndMedia()
    end
end

--- Ends the media. Only call if something is playing.
-- @hidden
function ENT:EndMedia()
    if hook.Call("PlayXMediaEnd", GAMEMODE, self) == false then
        return
    end
    
    self:ClearWireOutputs()
    
    self.Media = nil
    
    hook.Call("PlayXMediaEnded", GAMEMODE, self)
    
    self:SendEndMessage()
end

--- Tell subscribed clients that the media has ended, or choose to tell only
-- one client that. There should be no need to call this method. Unsubscribe
-- the user if you want the user to no longer view the media.
-- @param ply User to send the message to
-- @hidden
function ENT:SendEndMessage(ply)
    local filter = ply or self:GetSubscribers()
    
    umsg.Start("PlayXEnd", filter)
    umsg.Entity(self)
    umsg.End()
end

--- Tell standard metadata to clients. This is mostly used for the radio HUD
-- overlay and it cannot be extended.
-- @param ply User to send the message to
-- @hidden
function ENT:SendStdMetadataMessage(ply)
    local filter = ply or self:GetSubscribers()
    if not self.Media.Title then return end
    
    umsg.Start("PlayXMetadataStd", filter)
    umsg.Entity(self)
    umsg.String(self.Media.Title:gsub(1, 200))
    umsg.End()
end

--- Updates the current media metadata. Calling this while nothing is playing
-- has no effect. This can be called many times and multiple times.
-- @param data Metadata structure
function ENT:UpdateMetadata(data)
    if not self.Media then return end
    
    -- Allow a hook to override the data
    local res = hook.Call("PlayXMetadataReceive", GAMEMODE, self, self.Media, data)
    if res then data = res end
    
    table.Merge(self.Media, data)
    self:SetWireMetadata(self.Media)
    
    -- Send off data information for the HUD overlay
    if data.Title then
        self:SendStdMetadataMessage()
    end
end

--- Called on a metadata fetch error.
-- @param err Error message
-- @hidden
function ENT:OnMetadataError(err)
    MsgN("Metadata failed: " .. err)
end

--- Returns true if race protection is still wearing off.
-- return Boolean
function ENT:RaceProtectionTriggered()
    local raceProtectionTime = GetConVar("playx_race_protection"):GetFloat()
    
    return raceProtectionTime > 0 and
        RealTime() - self.LastOpenTime < raceProtectionTime
end

--- Determines whether players can see this entity.
-- @hidden
function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

--- Opens the spawn dialog.
-- @hidden
function ENT:SpawnFunction(ply, tr)
    if hook.Call("PlayXSpawnFunction", GAMEMODE, ply, tr) == false then return end
    
    PlayX.SendSpawnDialog(ply)
end

--- When the entity is used.
-- @hidden
function ENT:OnUse(activator, caller)
    hook.Call("PlayXUse", GAMEMODE, self, activator, caller) 
end

--- Removes the entity.
-- @hidden
function ENT:OnRemove()
    hook.Call("PlayXRemove", GAMEMODE, self) 
    
    -- No need to close the media
end

--- Clears the wire metadata.
-- @hidden
function ENT:ClearWireOutputs()
    if not WireAddon then return end
    
    Wire_TriggerOutput(self.Entity, "Provider", "")
    Wire_TriggerOutput(self.Entity, "Handler", "")
    Wire_TriggerOutput(self.Entity, "URI", "")
    Wire_TriggerOutput(self.Entity, "Start", -1)
    Wire_TriggerOutput(self.Entity, "ActualStartTime", -1)
    Wire_TriggerOutput(self.Entity, "Length", -1)
    Wire_TriggerOutput(self.Entity, "URL", "")
    Wire_TriggerOutput(self.Entity, "Title", "")
    Wire_TriggerOutput(self.Entity, "Description", "")
    Wire_TriggerOutput(self.Entity, "Tags", {})
    Wire_TriggerOutput(self.Entity, "DatePublished", -1)
    Wire_TriggerOutput(self.Entity, "DateModified", -1)
    Wire_TriggerOutput(self.Entity, "Submitter", "")
    Wire_TriggerOutput(self.Entity, "SubmitterURL", "")
    Wire_TriggerOutput(self.Entity, "SubmitterAvatar", "")
    Wire_TriggerOutput(self.Entity, "Faved", -1)
    Wire_TriggerOutput(self.Entity, "Views", -1)
    Wire_TriggerOutput(self.Entity, "Comments", -1)
    Wire_TriggerOutput(self.Entity, "NormalizedRating", -1)
    Wire_TriggerOutput(self.Entity, "RatingCount", -1)
    Wire_TriggerOutput(self.Entity, "Thumbnail", "")
    Wire_TriggerOutput(self.Entity, "Width", -1)
    Wire_TriggerOutput(self.Entity, "Height", -1)
    Wire_TriggerOutput(self.Entity, "IsLive", -1)
    Wire_TriggerOutput(self.Entity, "ViewerCount", -1)
end

--- Sets the wire metadata.
-- @param data Metadata table
-- @hidden
function ENT:SetWireMetadata(data)
    if not WireAddon then return end
    
    Wire_TriggerOutput(self.Entity, "Provider", data.Provider and data.Provider or "")
    Wire_TriggerOutput(self.Entity, "Handler", data.Handler)
    Wire_TriggerOutput(self.Entity, "URI", data.URI)
    Wire_TriggerOutput(self.Entity, "Start", data.StartAt)
    Wire_TriggerOutput(self.Entity, "ActualStartTime", data.StartTime + data.StartAt)
    Wire_TriggerOutput(self.Entity, "Length", data.Length and data.Length or -1)
    Wire_TriggerOutput(self.Entity, "URL", data.URL and data.URL or "")
    Wire_TriggerOutput(self.Entity, "Title", data.Title and data.Title or "")
    Wire_TriggerOutput(self.Entity, "Description", data.Description and data.Description or "")
    Wire_TriggerOutput(self.Entity, "Tags", data.Tags and data.Tags or {})
    Wire_TriggerOutput(self.Entity, "DatePublished", data.DatePublished and data.DatePublished or -1)
    Wire_TriggerOutput(self.Entity, "DateModified", data.DateModified and data.DateModified or -1)
    Wire_TriggerOutput(self.Entity, "Submitter", data.Submitter and data.Submitter or "")
    Wire_TriggerOutput(self.Entity, "SubmitterURL", data.SubmitterURL and data.SubmitterURL or "")
    Wire_TriggerOutput(self.Entity, "SubmitterAvatar", data.SubmitterAvatar and data.SubmitterAvatar or "")
    Wire_TriggerOutput(self.Entity, "Faved", data.NumFaves and data.NumFaves or -1)
    Wire_TriggerOutput(self.Entity, "Views", data.NumViews and data.NumViews or -1)
    Wire_TriggerOutput(self.Entity, "Comments", data.NumComments and data.NumComments or -1)
    Wire_TriggerOutput(self.Entity, "NormalizedRating", data.RatingNorm and data.RatingNorm or -1)
    Wire_TriggerOutput(self.Entity, "RatingCount", data.NumRatings and data.NumRatings or -1)
    Wire_TriggerOutput(self.Entity, "Thumbnail", data.Thumbnail and data.Thumbnail or "")
    Wire_TriggerOutput(self.Entity, "Width", data.Width and data.Width or -1)
    Wire_TriggerOutput(self.Entity, "Height", data.Height and data.Height or -1)
    Wire_TriggerOutput(self.Entity, "IsLive", data.IsLive and data.IsLive or -1)
    Wire_TriggerOutput(self.Entity, "ViewerCount", data.ViewerCount and data.ViewerCount or -1)
end

--- Trigger input for Wiremod.
-- @hidden
function ENT:TriggerInput(iname, value)
    if iname == "Close" and value > 0 then
        if not GetConVar("playx_wire_input"):GetBool() then
            Wire_TriggerOutput(self.Entity, "InputError", "Cvar playx_wire_input is not 1")
        else
            self:CloseMedia()
            Wire_TriggerOutput(self.Entity, "InputError", "")
        end
    elseif iname == "Open" and value > 0 then
        local wireInputDelay = GetconVar("playx_wire_input_delay"):GetFloat()
        
        if not GetConVar("playx_wire_input"):GetBool() then
            Wire_TriggerOutput(self.Entity, "InputError", "Cvar playx_wire_input is not 1")
        elseif self:RaceProtectionTriggered() then
            Wire_TriggerOutput(self.Entity, "InputError", "Race protection triggered")
        elseif wireInputDelay > 0 and RealTime() - self.LastWireOpenTime < wireInputDelay then
            Wire_TriggerOutput(self.Entity, "InputError", "Wire input race protection triggered")
        else
            local uri = self.InputURI:Trim()
            local provider = self.InputProvider:Trim()
            local start = self.InputStartAt
            local forceLowFramerate = self.InputForceLowFramerate
            local useJW = not self.InputDisableJW
            
            if uri == "" then
                Wire_TriggerOutput(self.Entity, "InputError", "Empty URI inputted")
            elseif start == nil then
                Wire_TriggerOutput(self.Entity, "InputError", "Time format inputted for StartAt unrecognized")
            elseif start < 0 then
                Wire_TriggerOutput(self.Entity, "InputError", "Non-negative start time is required")
            else
                MsgN(string.format("Video played via wire input: %s", uri))
                
                local result, err = self:OpenMedia(
                    provider, uri, start, forceLowFramerate, useJW, false
                )
                
                if not result then
                    Wire_TriggerOutput(self.Entity, "InputError", err)
                else
                    Wire_TriggerOutput(self.Entity, "InputError", "")
	                
	                self.LastWireOpenTime = RealTime()
                end
            end
        end
    elseif iname == "Provider" then
        self.InputProvider = tostring(value)
    elseif iname == "URI" then
        self.InputURI = tostring(value)
    elseif iname == "StartAt" then
        self.InputStartAt = playxlib.ParseTimeString(tostring(value))
    elseif iname == "DisableJW" then
        self.InputDisableJW = value > 0
    elseif iname == "ForceLowFramerate" then
        self.InputForceLowFramerate = value > 0
    end
end

--- Duplication function.
-- @hidden
local function PlayXEntityDuplicator(ply, model, pos, ang)
    if PlayX.PlayerExists() then return nil end
    if not PlayX.IsPermitted(ply) then return nil end
    
    local ent = ents.Create("gmod_playx")
    ent:SetModel(model)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    
    -- Sandbox only
    if ply.AddCleanup then
        ply:AddCleanup("gmod_playx", ent)
    end
    
    return ent
end

duplicator.RegisterEntityClass("gmod_playx", PlayXEntityDuplicator, "Model", "Pos", "Ang")