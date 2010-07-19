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

PlayX.SeenNotice = false

local spawnWindow = nil

--- Shows a hint. This only works on sandbox gamemodes and gamemodes that
-- implement GAMEMODE.AddNotify. If AddNotify is not available, the
-- message will not be shown anywhere.
-- @param msg
function PlayX.ShowHint(msg)
    if GAMEMODE and GAMEMODE.AddNotify then
	    GAMEMODE:AddNotify(msg, NOTIFY_GENERIC, 10);
	    surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
	end
end

--- Show the first play notice. This will only show anything if 
-- hints exist in the gameode.
function PlayX.ShowNotice()
    if PlayX.SeenNotice then return end
    
    PlayX.ShowHint("Want to stop what's playing? Go to the Q menu > Options > PlayX")
    PlayX.SeenNotice = true
end

--- Shows an error message. It will be shown in a popup if it is enabled
-- or if hints do not exist in this gamemode.
-- @param err
function PlayX.ShowError(err)
    local hasHint = GAMEMODE and GAMEMODE.AddNotify
    
    if GetConVar("playx_error_windows"):GetBool() or not hasHint then
        Derma_Message(err, "Error", "OK")
        gui.EnableScreenClicker(true)
        gui.EnableScreenClicker(false)
    else
	    GAMEMODE:AddNotify("PlayX error: " .. tostring(err), NOTIFY_ERROR, 7);
	    surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
	end
end

--- Opens the update window.
function PlayX.OpenUpdateWindow(ver)
    if ver == nil then
        RunConsoleCommand("playx_update_info")
        return
    end
    
    if PlayX._UpdateWindow and PlayX._UpdateWindow:IsValid() then
        return
    end
    
    local url = "http://playx.sk89q.com/update/?version=" .. playxlib.URLEscape(ver)
    
    local frame = vgui.Create("DFrame")
    PlayX._UpdateWindow = frame
    frame:SetTitle("PlayX Update News")
    frame:SetDeleteOnClose(true)
    frame:SetScreenLock(true)
    frame:SetSize(600, 400)
    frame:SetSizable(true)
    frame:Center()
    frame:MakePopup()
    
    local close = vgui.Create("DButton", frame)
    close:SetSize(90, 25)
    close:SetText("Close")
    close.DoClick = function(button)
        frame:Close()
    end
    
    local browser = vgui.Create("HTML", frame)
    browser:SetVerticalScrollbarEnabled(true)
	browser.OpeningURL = function(panel, url)
	    if not url:find("^http://[%.a-zA-Z0-9%-]*playx%.sk89q%.com") then
	       gui.OpenURL(url)
	       frame:Close()
	    end
	end
	browser.Paint = function(self)
	    local skin = derma.GetDefaultSkin()
        if not skin then return end
	    local c = skin.bg_color_dark
	    local fg = skin.text_normal
	    surface.SetDrawColor(c.r, c.g, c.b, 255)
	    surface.DrawRect(0, 0, self:GetWide() - 22, self:GetTall())
	    surface.SetFont(skin.fontFrame)
	    surface.SetTextColor(fg.r, fg.g, fg.b, 255)
	    surface.SetTextPos(10, 10) 
	    surface.DrawText("Loading" .. string.rep(".", (CurTime() * 2) % 3))
	end
    browser:OpenURL(url)

    -- Layout
    local oldPerform = frame.PerformLayout
    frame.PerformLayout = function()
        oldPerform(frame)
        browser:StretchToParent(10, 28, 10, 40)
        close:SetPos(frame:GetWide() - close:GetWide() - 8, frame:GetTall() - close:GetTall() - 8)
    end
    
    frame:InvalidateLayout(true, true)
end

--- Opens the dialog for choosing a model to spawn the player with.
-- @param forRepeater
function PlayX.OpenSpawnDialog(forRepeater)
    if spawnWindow and spawnWindow:IsValid() then
        return
    end
    
    local frame = vgui.Create("DFrame")
    frame:SetDeleteOnClose(true)
    frame:SetTitle("Select Model for PlayX " .. (forRepeater and "Repeater" or "Player"))
    frame:SetSize(275, 400)
    frame:SetSizable(true)
    frame:Center()
    frame:MakePopup()
    spawnWindow = frame
    
    local modelList = vgui.Create("DPanelList", frame)
    modelList:EnableHorizontal(true)
    modelList:SetPadding(5)
    
    for model, info in pairs(PlayXScreens) do
        if not forRepeater or not info.NoScreen then
	        local spawnIcon = vgui.Create("SpawnIcon", modelList)
	        
	        spawnIcon:SetModel(model)
	        spawnIcon.Model = model
	        spawnIcon.DoClick = function()
	            surface.PlaySound("ui/buttonclickrelease.wav")
	            RunConsoleCommand("playx_spawn" .. (forRepeater and "_repeater" or ""), spawnIcon.Model)
	            frame:Close()
	        end
	        
	        modelList:AddItem(spawnIcon)
        end
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
                    RunConsoleCommand("playx_spawn" .. (forRepeater and "_repeater" or ""), text)
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