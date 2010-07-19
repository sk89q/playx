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

function HUDPaint()
    local instance = PlayX.GetInstance()
    local ply = LocalPlayer()
    
    if not instance then
        draw.SimpleText("Where's PlayX?", "TabLarge", 100, 100, Color(255, 255, 255, 255))
        return
    end
    
    local lines = {}
    
    local selfPos = ply:GetPos()
    local line1 = instance:GetSourcePos()
    local line2 = instance:GetProjectionPos()
    
    if line1 ~= nil and line2 ~= nil then        
        local distance = playxlib.PointLineSegmentDistance(line1, line2, selfPos)
        local projection = playxlib.PointLineSegmentProjection(line1, line2, selfPos)
        
        table.insert(lines, "Distance: " .. distance)
        
        local line1Screen = line1:ToScreen()
        local line2Screen = line2:ToScreen()
        local projectionScreen = projection:ToScreen()
        local pScreen = selfPos:ToScreen()
        
        if line1Screen.visible and line2Screen.visible then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawLine(line1Screen.x, line1Screen.y, line2Screen.x, line2Screen.y)
        end
        surface.SetDrawColor(0, 255, 0, 255)
        surface.DrawLine(projectionScreen.x - 5, projectionScreen.y - 5,
                         projectionScreen.x + 5, projectionScreen.y + 5)
        surface.DrawLine(projectionScreen.x - 5, projectionScreen.y + 5,
                         projectionScreen.x + 5, projectionScreen.y - 5)
    else
        table.insert(lines, "Projector screen not available")
    end
    
    table.insert(lines, "Sound: " .. instance:GetLocalVolume() .. "x")
    
    surface.SetDrawColor(0, 0, 255, 255)
    surface.DrawRect(16, 200 + 14, 200 * instance:GetLocalVolume() / 100, 14)
    surface.DrawOutlinedRect(16, 200 + 14, 200, 14)
    
    for k, line in pairs(lines) do
        draw.SimpleText(line, "TabLarge", 16, 200 + (k - 1) * 14, Color(255, 255, 255, 255))
    end
end

hook.Add("HUDPaint", "PlayXDebugHUD", HUDPaint)