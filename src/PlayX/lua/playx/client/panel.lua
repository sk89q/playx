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

--- Draw the settings panel.
local function SettingsPanel(panel)
	panel:ClearControls()
	panel:AddHeader()

    panel:AddControl("CheckBox", {
        Label = "Enabled",
        Command = "playx_enabled",
    })
    
    if not PlayX.Enabled then
        return
    end

    local chromeCheck = panel:AddControl("CheckBox", {
        Label = "Use gm_chrome",
        Command = "playx_use_chrome",
    })
    
    if not PlayX.SupportsChrome then
        chromeCheck:SetDisabled(true)
	    
	    panel:AddControl("Label", {
	        Text = "Installing gm_chrome provides vast improvements in performance. " ..
            "Visit http://wiki.github.com/sk89q/playx/installation for more information."
	    })
    end

	panel:AddControl("Slider", {
		Label = "Frame rate:",
		Command = "playx_fps",
		Type = "Integer",
		Min = "1",
		Max = "30",
	})
            
    panel:AddControl("Label", {
        Text = "Decreasing the frame rate will cause your game to run better, at the cost of video choppiness."
    })

	panel:AddControl("Slider", {
		Label = "Volume:",
		Command = "playx_volume",
		Type = "Float",
		Min = "1",
		Max = "100",
	})
	
	panel:AddControl("Label", {
		Text = "Not all media have adjustable volumes, and the player must be re-initialized " ..
            "for a change in volume to take effect."
	})
    
    if PlayX.CurrentMedia then
        if PlayX.CurrentMedia.ResumeSupported then
            local button = panel:AddControl("Button", {
                Label = "Hide Player",
                Command = "playx_hide",
            })
            
            if not PlayX.Playing then
                button:SetDisabled(true)
            end
            
            if PlayX.Playing then
                panel:AddControl("Button", {
                    Label = "Re-initialize Player",
                    Command = "playx_resume",
                })
            else
                panel:AddControl("Button", {
                    Label = "Resume Play",
                    Command = "playx_resume",
                })
            end
            
            panel:AddControl("Label", {
                Text = "The current media supports resuming."
            })
        else
            if PlayX.Playing then
                panel:AddControl("Button", {
                    Label = "Stop Play",
                    Command = "playx_hide",
                })
            
                local button = panel:AddControl("Button", {
                    Label = "Re-initialize Player",
                    Command = "playx_resume",
                })
            
                button:SetDisabled(true)
            else
                local button = panel:AddControl("Button", {
                    Label = "Stop Play",
                    Command = "playx_hide",
                })
                
                if not PlayX.Playing then
                    button:SetDisabled(true)
                end
                
                local button = panel:AddControl("Button", {
                    Label = "Resume Play",
                    Command = "playx_resume",
                })
            
                button:SetDisabled(true)
            end
            
            panel:AddControl("Label", {
                Text = "The current media cannot be resumed once stopped."
            })
        end
    else
        panel:AddControl("Label", {
            Text = "No media is playing at the moment."
        })
    end
    
    if PlayX:GetInstance() and PlayX:GetInstance().IsProjector then
        panel:AddControl("Button", {
            Label = "Fix Screen Not Always Appearing",
            Command = "playx_reset_render_bounds",
        })
    end
end

--- Draw the control panel.
local function ControlPanel(panel)
	panel:ClearControls()
	panel:AddHeader()
    
    local options = {
        ["Auto-detect"] = {["playx_provider"] = ""}
    }
    
    for id, name in pairs(PlayX.Providers) do
        options[name] = {["playx_provider"] = id}
    end
    
    -- TODO: Put the following two controls on the same line
    
    local label = panel:AddControl("DLabel", {})
    label:SetText("Provider:")

	panel:AddControl("ListBox", {
		Label = "Provider:",
		Options = options,
	})

	panel:AddControl("TextBox", {
		Label = "URI:",
        Command = "playx_uri",
		WaitForEnter = false,
	})

	panel:AddControl("TextBox", {
		Label = "Start At:",
        Command = "playx_start_time",
		WaitForEnter = false,
	})

    if PlayX.JWPlayerURL then
        panel:AddControl("CheckBox", {
            Label = "Use JW player when applicable",
            Command = "playx_use_jw",
        })
    end

	panel:AddControl("CheckBox", {
		Label = "Force low frame rate",
        Command = "playx_force_low_framerate",
	})
    
    panel:AddControl("CheckBox", {
        Label = "Don't auto stop on finish when applicable",
        Command = "playx_ignore_length",
    })
	
	panel:AddControl("Label", {
		Text = "READ: Press ENTER in the textboxes above before clicking the buttons below."
	})
    
    panel:AddControl("Button", {
        Label = "Open Media",
        Command = "playx_gui_open",
    })
    
    local button = panel:AddControl("Button", {
        Label = "Close Media",
        Command = "playx_gui_close",
    })
    
    if not PlayX.CurrentMedia then
        button:SetDisabled(true)
    end
end

--- PopulateToolMenu hook.
local function PopulateToolMenu()
	spawnmenu.AddToolMenuOption("Options", "PlayX", "PlayXSettings", "Settings", "", "", SettingsPanel)
	spawnmenu.AddToolMenuOption("Options", "PlayX", "PlayXControl", "Administrate", "", "", ControlPanel)
end

hook.Add("PopulateToolMenu", "PlayXPopulateToolMenu", PopulateToolMenu)

--- Updates the tool panels.
function PlayX.UpdatePanels()
    SettingsPanel(GetControlPanel("PlayXSettings"))
    ControlPanel(GetControlPanel("PlayXControl"))
end