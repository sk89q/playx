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
function PlayX.OpenUpdateWindow(ver)
    if ver == nil then
        RunConsoleCommand("playx_update_info")
        return
    end
    
    if updateWindow and updateWindow:IsValid() then
        return
    end
    
    local url = "http://playx.sk89q.com/update/?version=" .. PlayX.URLEncode(ver)
    
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
    if hook.Call("PlayXShowError", false, err) ~= nil then
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