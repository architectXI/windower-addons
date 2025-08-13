--[[
    Copyright © 2024, Tylas
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of XivParty nor the
          names of its contributors may be used to endorse or promote products
          derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

-- imports
local classes = require('classes')
local uiContainer = require('uiContainer')
local uiImage = require('uiImage')
local utils = require('utils')

-- create the class, derive from uiContainer
local uiSongBar = classes.class(uiContainer)

-- Song type colors (fallback when song-specific colors aren't available)
local songColors = {
    default = { r = 150, g = 150, b = 150, a = 255 }, -- Default gray for unknown songs
    regen = { r = 100, g = 255, b = 100, a = 255 },   -- Green for HP/MP regen songs
    defense = { r = 255, g = 200, b = 100, a = 255 }, -- Orange for defensive songs
    attack = { r = 255, g = 100, b = 100, a = 255 },  -- Red for offensive songs
    accuracy = { r = 255, g = 150, b = 255, a = 255 }, -- Pink for accuracy songs
    ranged = { r = 255, g = 255, b = 100, a = 255 },  -- Yellow for ranged songs
    evasion = { r = 150, g = 255, b = 150, a = 255 }, -- Light green for evasion
    haste = { r = 255, g = 255, b = 100, a = 255 },   -- Bright yellow for haste
    debuff = { r = 200, g = 100, b = 100, a = 255 },  -- Dark red for debuff songs
    magic = { r = 150, g = 150, b = 255, a = 255 },   -- Light blue for magic songs
    stats = { r = 200, g = 255, b = 255, a = 255 }    -- Cyan for stat boost songs
}

function uiSongBar:init(layout, player)
    if not layout.enabled then return end
    
    if self.super:init(layout) then
        self.player = player
        
        -- Create two song bars (left and right halves)
        self.songBar1 = nil
        self.songBar2 = nil
        
        -- Store animation state
        self.song1Progress = 0
        self.song1MaxDuration = 0
        self.song1Type = 'default'
        
        self.song2Progress = 0
        self.song2MaxDuration = 0
        self.song2Type = 'default'
        
        -- Bar dimensions (will be set in createPrimitives)
        self.barWidth = 0
        self.barHeight = 20 -- Default height
    end
end

function uiSongBar:createPrimitives()
    if not self.isEnabled then return end
    
    self.super:createPrimitives()
    
    -- Create thin progress lines under HP and MP bars
    -- From layout: HP bar imgBar pos=13,0 size=102,64 within HP pos=19,-7
    -- From layout: MP bar imgBar pos=13,0 size=102,64 within MP pos=150,-7
    self.hpBarWidth = 102  -- HP bar actual bar width (not background)
    self.mpBarWidth = 102  -- MP bar actual bar width (not background)
    self.lineHeight = 3    -- Thin line height
    
    -- Song bar 1 - thin line under HP bar
    self.songBar1 = self:addChild(uiImage.create())
    self.songBar1:pos(32, 30)  -- Positioned under HP bar
    self.songBar1:size(0, self.lineHeight)  -- Initially no width
    self.songBar1:color(255, 255, 255, 255)  -- Will be set in update
    
    -- Song bar 2 - thin line under MP bar  
    self.songBar2 = self:addChild(uiImage.create())
    self.songBar2:pos(163, 30)  -- Positioned under MP bar
    self.songBar2:size(0, self.lineHeight)  -- Initially no width
    self.songBar2:color(255, 255, 255, 255)  -- Will be set in update
end


function uiSongBar:update()
    if not self.isEnabled then return end
    
    self.super:update()
    
    if self.player and self.player.songs then
        -- Update song 1 (under HP bar)
        if self.player.songs[1] and self.player.songs[1].duration > 0 then
            local song = self.player.songs[1]
            local currentDuration = song.getDuration and song.getDuration() or song.duration
            local progressRatio = currentDuration / song.maxDuration
            local currentWidth = self.hpBarWidth * progressRatio
            
            if self.songBar1 then
                self.songBar1:size(currentWidth, self.lineHeight)
                
                if song.color then
                    self.songBar1:color(song.color.r, song.color.g, song.color.b, song.color.a)
                else
                    local color = songColors[song.songType] or songColors.default
                    self.songBar1:color(color.r, color.g, color.b, color.a)
                end
            end
        elseif self.songBar1 then
            self.songBar1:size(0, self.lineHeight)
        end
        
        -- Update song 2 (under MP bar)
        if self.player.songs[2] and self.player.songs[2].duration > 0 then
            local song = self.player.songs[2]
            local currentDuration = song.getDuration and song.getDuration() or song.duration
            local progressRatio = currentDuration / song.maxDuration
            local currentWidth = self.mpBarWidth * progressRatio
            
            if self.songBar2 then
                self.songBar2:size(currentWidth, self.lineHeight)
                
                if song.color then
                    self.songBar2:color(song.color.r, song.color.g, song.color.b, song.color.a)
                else
                    local color = songColors[song.songType] or songColors.default
                    self.songBar2:color(color.r, color.g, color.b, color.a)
                end
            end
        elseif self.songBar2 then
            self.songBar2:size(0, self.lineHeight)
        end
    else
        if self.songBar1 then
            self.songBar1:size(0, self.lineHeight)
        end
        if self.songBar2 then
            self.songBar2:size(0, self.lineHeight)
        end
    end
end

return uiSongBar