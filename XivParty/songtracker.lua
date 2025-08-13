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

local socket = require('socket')
local classes = require('classes')
local utils = require('utils')
local res = require('resources')
local packets = require('packets')
local buffPacket = require('buffpacket')

local songTracker = classes.class()

-- Spell ID to tier mapping for songs with multiple levels
-- Colors based on actual buff icon analysis (darker base colors)
local SPELL_TIERS = {
    -- Paeon (378-385) - Blue icon
    [378] = { tier = 1, base_color = { r = 50, g = 90, b = 128 } }, -- Army's Paeon (Dark Blue)
    [379] = { tier = 2, base_color = { r = 50, g = 90, b = 128 } }, -- Army's Paeon II
    [380] = { tier = 3, base_color = { r = 50, g = 90, b = 128 } }, -- Army's Paeon III
    [381] = { tier = 4, base_color = { r = 50, g = 90, b = 128 } }, -- Army's Paeon IV
    [382] = { tier = 5, base_color = { r = 50, g = 90, b = 128 } }, -- Army's Paeon V
    [383] = { tier = 6, base_color = { r = 50, g = 90, b = 128 } }, -- Army's Paeon VI
    [384] = { tier = 7, base_color = { r = 50, g = 90, b = 128 } }, -- Army's Paeon VII
    [385] = { tier = 8, base_color = { r = 50, g = 90, b = 128 } }, -- Army's Paeon VIII
    
    -- Ballad (386-388) - Green icon
    [386] = { tier = 1, base_color = { r = 40, g = 100, b = 40 } }, -- Mage's Ballad (Dark Green)
    [387] = { tier = 2, base_color = { r = 40, g = 100, b = 40 } }, -- Mage's Ballad II
    [388] = { tier = 3, base_color = { r = 40, g = 100, b = 40 } }, -- Mage's Ballad III
    
    -- Minne (389-393) - Yellow icon
    [389] = { tier = 1, base_color = { r = 128, g = 128, b = 50 } }, -- Knight's Minne (Dark Yellow)
    [390] = { tier = 2, base_color = { r = 128, g = 128, b = 50 } }, -- Knight's Minne II
    [391] = { tier = 3, base_color = { r = 128, g = 128, b = 50 } }, -- Knight's Minne III
    [392] = { tier = 4, base_color = { r = 128, g = 128, b = 50 } }, -- Knight's Minne IV
    [393] = { tier = 5, base_color = { r = 128, g = 128, b = 50 } }, -- Knight's Minne V
    
    -- Minuet (394-398) - Red icon
    [394] = { tier = 1, base_color = { r = 128, g = 50, b = 50 } }, -- Valor Minuet (Dark Red)
    [395] = { tier = 2, base_color = { r = 128, g = 50, b = 50 } }, -- Valor Minuet II
    [396] = { tier = 3, base_color = { r = 128, g = 50, b = 50 } }, -- Valor Minuet III
    [397] = { tier = 4, base_color = { r = 128, g = 50, b = 50 } }, -- Valor Minuet IV
    [398] = { tier = 5, base_color = { r = 128, g = 50, b = 50 } }, -- Valor Minuet V
    
    -- Madrigal (399-400) - Purple icon
    [399] = { tier = 1, base_color = { r = 100, g = 50, b = 128 } }, -- Sword Madrigal (Dark Purple)
    [400] = { tier = 2, base_color = { r = 100, g = 50, b = 128 } }, -- Blade Madrigal
    
    -- Prelude (401-402) - Light Green icon
    [401] = { tier = 1, base_color = { r = 75, g = 128, b = 50 } }, -- Hunter's Prelude (Dark Light Green)
    [402] = { tier = 2, base_color = { r = 75, g = 128, b = 50 } }, -- Archer's Prelude
    
    -- Mambo (403-404) - Dark Green icon
    [403] = { tier = 1, base_color = { r = 50, g = 128, b = 75 } }, -- Sheepfoe Mambo (Dark Mint Green)
    [404] = { tier = 2, base_color = { r = 50, g = 128, b = 75 } }, -- Dragonfoe Mambo
    
    -- Single tier songs with darker colors from buff icons
    [405] = { tier = 1, base_color = { r = 100, g = 50, b = 128 } }, -- Fowl Aubade (Dark Purple)
    [406] = { tier = 1, base_color = { r = 100, g = 50, b = 128 } }, -- Herb Pastoral (Dark Purple)
    [408] = { tier = 1, base_color = { r = 100, g = 50, b = 128 } }, -- Shining Fantasia (Dark Purple)
    [409] = { tier = 1, base_color = { r = 100, g = 50, b = 128 } }, -- Scop's Operetta (Dark Purple)
    [410] = { tier = 2, base_color = { r = 100, g = 50, b = 128 } }, -- Puppet's Operetta (Dark Purple)
    [411] = { tier = 3, base_color = { r = 100, g = 50, b = 128 } }, -- Jester's Operetta (Dark Purple)
    [412] = { tier = 1, base_color = { r = 100, g = 50, b = 128 } }, -- Gold Capriccio (Dark Purple)
    [413] = { tier = 1, base_color = { r = 50, g = 50, b = 100 } }, -- Devotee Serenade (Dark Blue)
    [414] = { tier = 1, base_color = { r = 100, g = 50, b = 128 } }, -- Warding Round (Dark Purple)
    [415] = { tier = 1, base_color = { r = 100, g = 50, b = 128 } }, -- Goblin Gavotte (Dark Purple)
    [417] = { tier = 1, base_color = { r = 50, g = 90, b = 128 } }, -- Honor March (Dark Blue)
    [418] = { tier = 1, base_color = { r = 50, g = 50, b = 100 } }, -- Aria of Passion (Dark Blue)
    [419] = { tier = 2, base_color = { r = 50, g = 90, b = 128 } }, -- Advancing March (Dark Blue)
    [420] = { tier = 3, base_color = { r = 50, g = 90, b = 128 } }, -- Victory March (Dark Blue)
    
    -- Etudes (424-437) - Brown icon (darker)
    [424] = { tier = 1, base_color = { r = 110, g = 75, b = 50 } }, -- Sinewy Etude (Dark Brown/Orange)
    [425] = { tier = 2, base_color = { r = 110, g = 75, b = 50 } }, -- Dextrous Etude
    [426] = { tier = 3, base_color = { r = 110, g = 75, b = 50 } }, -- Vivacious Etude
    [427] = { tier = 4, base_color = { r = 110, g = 75, b = 50 } }, -- Quick Etude
    [428] = { tier = 5, base_color = { r = 110, g = 75, b = 50 } }, -- Learned Etude
    [429] = { tier = 6, base_color = { r = 110, g = 75, b = 50 } }, -- Spirited Etude
    [430] = { tier = 7, base_color = { r = 110, g = 75, b = 50 } }, -- Enchanting Etude
    [431] = { tier = 8, base_color = { r = 110, g = 75, b = 50 } }, -- Herculean Etude
    [432] = { tier = 9, base_color = { r = 110, g = 75, b = 50 } }, -- Uncanny Etude
    [433] = { tier = 10, base_color = { r = 110, g = 75, b = 50 } }, -- Vital Etude
    [434] = { tier = 11, base_color = { r = 110, g = 75, b = 50 } }, -- Swift Etude
    [435] = { tier = 12, base_color = { r = 110, g = 75, b = 50 } }, -- Sage Etude
    [436] = { tier = 13, base_color = { r = 110, g = 75, b = 50 } }, -- Logical Etude
    [437] = { tier = 14, base_color = { r = 110, g = 75, b = 50 } } -- Bewitching Etude
}

-- Beneficial song buff ID mappings with unique colors and spell IDs for duration lookup
-- Only includes songs that bards would cast on party members (195-215)
local SONG_BUFFS = {
    [195] = { name = "Paeon", type = "regen", color = { r = 100, g = 180, b = 255, a = 255 }, spellId = 378 }, -- Army's Paeon (Blue)
    [196] = { name = "Ballad", type = "regen", color = { r = 0, g = 0, b = 255, a = 255 }, spellId = 386 }, -- Mage's Ballad (Pure Blue)
    [197] = { name = "Minne", type = "defense", color = { r = 255, g = 165, b = 0, a = 255 }, spellId = 389 }, -- Knight's Minne (Orange)
    [198] = { name = "Minuet", type = "attack", color = { r = 255, g = 0, b = 0, a = 255 }, spellId = 394 }, -- Valor Minuet (Red)
    [199] = { name = "Madrigal", type = "accuracy", color = { r = 255, g = 20, b = 147, a = 255 }, spellId = 399 }, -- Sword/Blade Madrigal (Deep Pink)
    [200] = { name = "Prelude", type = "ranged", color = { r = 255, g = 255, b = 0, a = 255 }, spellId = 401 }, -- Hunter's/Archer's Prelude (Yellow)
    [201] = { name = "Mambo", type = "evasion", color = { r = 50, g = 205, b = 50, a = 255 }, spellId = 403 }, -- Sheepfoe/Dragonfoe Mambo (Lime Green)
    [202] = { name = "Aubade", type = "charm", color = { r = 255, g = 69, b = 0, a = 255 }, spellId = 405 }, -- Fowl Aubade (Orange Red)
    [203] = { name = "Pastoral", type = "slow", color = { r = 210, g = 180, b = 140, a = 255 }, spellId = 406 }, -- Herb Pastoral (Tan)
    [204] = { name = "Fantasia", type = "magic", color = { r = 138, g = 43, b = 226, a = 255 }, spellId = 408 }, -- Shining Fantasia (Blue Violet)
    [205] = { name = "Operetta", type = "charm", color = { r = 255, g = 192, b = 203, a = 255 }, spellId = 409 }, -- Scop's/Puppet's/Jester's Operetta (Pink)
    [206] = { name = "Capriccio", type = "stats", color = { r = 255, g = 215, b = 0, a = 255 }, spellId = 412 }, -- Gold Capriccio (Gold)
    [207] = { name = "Serenade", type = "silence", color = { r = 72, g = 209, b = 204, a = 255 }, spellId = 413 }, -- Devotee Serenade (Medium Turquoise)
    [208] = { name = "Round", type = "mp", color = { r = 123, g = 104, b = 238, a = 255 }, spellId = 414 }, -- Warding Round (Medium Slate Blue)
    [209] = { name = "Gavotte", type = "chr", color = { r = 219, g = 112, b = 147, a = 255 }, spellId = 415 }, -- Goblin Gavotte (Pale Violet Red)
    [210] = { name = "Dirge", type = "special", color = { r = 105, g = 105, b = 105, a = 255 }, spellId = 378 }, -- Dirge (Dim Gray) - rare buff
    [211] = { name = "Scherzo", type = "magic_eva", color = { r = 186, g = 85, b = 211, a = 255 }, spellId = 378 }, -- Scherzo (Medium Orchid) - rare buff
    [212] = { name = "Nocturne", type = "special", color = { r = 25, g = 25, b = 112, a = 255 }, spellId = 378 }, -- Nocturne (Midnight Blue) - rare buff
    [213] = { name = "Aria", type = "elemental", color = { r = 255, g = 140, b = 0, a = 255 }, spellId = 418 }, -- Aria of Passion (Dark Orange)
    [214] = { name = "March", type = "haste", color = { r = 154, g = 205, b = 50, a = 255 }, spellId = 417 }, -- Honor/Advancing/Victory March (Yellow Green)
    [215] = { name = "Etude", type = "stats", color = { r = 64, g = 224, b = 208, a = 255 }, spellId = 424 } -- Etudes (Turquoise)
}


function songTracker:init(model)
    self.model = model
    self.activeSongs = {} -- playerId -> { song1, song2 }
    self.lastUpdateTime = socket.gettime()
    self.spellTracking = {} -- playerId -> buffId -> spellId (tracks original spell that created buff)
    self.songMaxDurations = {} -- buffId -> maxDuration
    
    self.buffReader = buffPacket.new()
    utils:log('Song tracker initialized with packet-based duration reading', 2)
end

-- Check if a buff ID is a song
function songTracker:isSongBuff(buffId)
    return SONG_BUFFS[buffId] ~= nil
end

-- Get song information by buff ID
function songTracker:getSongInfo(buffId)
    return SONG_BUFFS[buffId]
end

-- Calculate tiered color based on spell tier (completely different color progressions per song type)
function songTracker:getTieredColor(spellId)
    local tierInfo = SPELL_TIERS[spellId]
    if not tierInfo then
        return { r = 150, g = 150, b = 150, a = 255 } -- Default gray
    end
    
    -- Define color progressions for each song type
    local colorProgressions = {
        -- Paeon (Blue progression: Very Dark -> Bright Blue)
        paeon = {
            [1] = { r = 10, g = 10, b = 40 },    -- Very Dark Navy
            [2] = { r = 15, g = 15, b = 60 },    -- Dark Navy
            [3] = { r = 25, g = 25, b = 90 },    -- Navy
            [4] = { r = 40, g = 40, b = 120 },   -- Dark Blue
            [5] = { r = 60, g = 100, b = 180 },  -- Medium Blue (target brightness)
            [6] = { r = 80, g = 140, b = 220 },  -- Light Blue
            [7] = { r = 120, g = 180, b = 255 }, -- Bright Blue
            [8] = { r = 180, g = 220, b = 255 }  -- Very Bright Blue
        },
        -- Ballad (Green progression: Very Dark -> Bright Green)
        ballad = {
            [1] = { r = 5, g = 20, b = 5 },      -- Very Dark Forest
            [2] = { r = 10, g = 40, b = 10 },    -- Dark Forest
            [3] = { r = 20, g = 60, b = 20 },    -- Forest Green
            [4] = { r = 40, g = 100, b = 40 },   -- Medium Green
            [5] = { r = 80, g = 160, b = 80 }    -- Bright Green (target brightness)
        },
        -- Minne (Yellow progression: Very Dark -> Bright Yellow)
        minne = {
            [1] = { r = 30, g = 30, b = 10 },    -- Very Dark Olive
            [2] = { r = 50, g = 50, b = 15 },    -- Dark Olive
            [3] = { r = 80, g = 80, b = 20 },    -- Olive
            [4] = { r = 120, g = 120, b = 30 },  -- Dark Yellow
            [5] = { r = 180, g = 180, b = 60 }   -- Bright Yellow (target brightness)
        },
        -- Minuet (Red progression: Very Dark -> Bright Red)
        minuet = {
            [1] = { r = 40, g = 10, b = 10 },    -- Very Dark Red
            [2] = { r = 60, g = 15, b = 15 },    -- Dark Red
            [3] = { r = 90, g = 20, b = 20 },    -- Medium Dark Red
            [4] = { r = 130, g = 30, b = 30 },   -- Red
            [5] = { r = 180, g = 60, b = 60 }    -- Bright Red (target brightness)
        },
        -- Madrigal (Purple progression: Very Dark -> Bright Purple)
        madrigal = {
            [1] = { r = 30, g = 10, b = 40 },    -- Very Dark Purple
            [2] = { r = 50, g = 20, b = 70 },    -- Dark Purple
            [3] = { r = 80, g = 40, b = 110 },   -- Medium Purple
            [4] = { r = 120, g = 60, b = 160 }   -- Bright Purple (target brightness)
        },
        -- Prelude (Light Green progression: Very Dark -> Bright Light Green)
        prelude = {
            [1] = { r = 15, g = 40, b = 20 },    -- Very Dark Sea Green
            [2] = { r = 25, g = 60, b = 35 },    -- Dark Sea Green
            [3] = { r = 40, g = 90, b = 50 },    -- Sea Green
            [4] = { r = 70, g = 140, b = 80 }    -- Bright Sea Green (target brightness)
        },
        -- Mambo (Mint progression: Very Dark -> Bright Mint)
        mambo = {
            [1] = { r = 10, g = 40, b = 40 },    -- Very Dark Teal
            [2] = { r = 20, g = 60, b = 60 },    -- Dark Teal
            [3] = { r = 35, g = 90, b = 90 },    -- Teal
            [4] = { r = 60, g = 140, b = 140 }   -- Bright Teal (target brightness)
        },
        -- Etudes (Brown progression: Very Dark -> Bright Orange)
        etude = {
            [1] = { r = 20, g = 15, b = 10 },    -- Very Dark Brown
            [2] = { r = 30, g = 20, b = 15 },    -- Dark Brown
            [3] = { r = 45, g = 30, b = 20 },    -- Brown
            [4] = { r = 60, g = 40, b = 25 },    -- Medium Brown
            [5] = { r = 80, g = 55, b = 35 },    -- Light Brown
            [6] = { r = 100, g = 70, b = 45 },   -- Tan
            [7] = { r = 120, g = 85, b = 55 },   -- Light Tan
            [8] = { r = 140, g = 100, b = 65 },  -- Beige
            [9] = { r = 160, g = 115, b = 75 },  -- Light Beige
            [10] = { r = 180, g = 130, b = 85 }, -- Orange Brown (target brightness)
            [11] = { r = 200, g = 145, b = 95 }, -- Light Orange Brown
            [12] = { r = 220, g = 160, b = 105 }, -- Orange
            [13] = { r = 240, g = 175, b = 115 }, -- Light Orange
            [14] = { r = 255, g = 190, b = 125 }  -- Bright Orange
        },
        -- Default purple progression for misc songs
        default = {
            [1] = { r = 25, g = 10, b = 35 },    -- Very Dark Purple
            [2] = { r = 40, g = 20, b = 60 },    -- Dark Purple
            [3] = { r = 70, g = 35, b = 100 },   -- Medium Purple
            [4] = { r = 110, g = 60, b = 150 }   -- Bright Purple (target brightness)
        }
    }
    
    -- Determine song type and get appropriate color progression
    local progression = colorProgressions.default
    
    -- Paeon spells (378-385)
    if spellId >= 378 and spellId <= 385 then
        progression = colorProgressions.paeon
    -- Ballad spells (386-388)
    elseif spellId >= 386 and spellId <= 388 then
        progression = colorProgressions.ballad
    -- Minne spells (389-393)
    elseif spellId >= 389 and spellId <= 393 then
        progression = colorProgressions.minne
    -- Minuet spells (394-398)
    elseif spellId >= 394 and spellId <= 398 then
        progression = colorProgressions.minuet
    -- Madrigal spells (399-400)
    elseif spellId >= 399 and spellId <= 400 then
        progression = colorProgressions.madrigal
    -- Prelude spells (401-402)
    elseif spellId >= 401 and spellId <= 402 then
        progression = colorProgressions.prelude
    -- Mambo spells (403-404)
    elseif spellId >= 403 and spellId <= 404 then
        progression = colorProgressions.mambo
    -- March spells (417, 419-420)
    elseif spellId == 417 or (spellId >= 419 and spellId <= 420) then
        progression = colorProgressions.paeon -- Use blue progression for marches
    -- Etude spells (424-437)
    elseif spellId >= 424 and spellId <= 437 then
        progression = colorProgressions.etude
    end
    
    -- Get the appropriate color for this tier
    local shade = progression[tierInfo.tier] or progression[1]
    
    local color = {
        r = shade.r,
        g = shade.g,
        b = shade.b,
        a = 255
    }
    
    return color
end

-- Handle action packets to track spell IDs for song casts
function songTracker:handleActionPacket(act)
    if act.category ~= 4 then return end -- Only spell completion
    
    local spellId = act.param
    local spellData = res.spells[spellId]
    
    if not spellData or not spellData.status then return end
    
    local buffId = spellData.status
    if not self:isSongBuff(buffId) then return end
    
    -- Track which spell created which buff for each target
    for _, target in pairs(act.targets) do
        local targetId = target.id
        if not self.spellTracking[targetId] then
            self.spellTracking[targetId] = {}
        end
        
        -- Store the spell ID that created this buff
        self.spellTracking[targetId][buffId] = spellId
    end
end

-- Update song tracking for a player based on their current buffs
function songTracker:updatePlayerSongs(player)
    if not player or not player.buffs then return end
    
    local playerId = player.id or 0
    local currentTime = socket.gettime()
    
    -- Find active songs in player's buff list
    local playerSongs = {}
    for i = 1, 32 do
        local buffId = player.buffs[i]
        if buffId and self:isSongBuff(buffId) then
            table.insert(playerSongs, buffId)
            utils:log('Found song buff ' .. buffId .. ' on player ' .. (player.name or 'Unknown'), 0)
        end
    end
    
    if #playerSongs > 0 then
        utils:log('Player ' .. (player.name or 'Unknown') .. ' has ' .. #playerSongs .. ' active songs', 0)
    end
    
    -- Initialize player song tracking if needed
    if not self.activeSongs[playerId] then
        self.activeSongs[playerId] = {
            song1 = nil,
            song2 = nil
        }
    end
    
    local playerSongData = self.activeSongs[playerId]
    
    -- Update song slots
    for i, songId in ipairs(playerSongs) do
        if i <= 2 then -- FFXI allows max 2 songs per player
            local songInfo = self:getSongInfo(songId)
            local slotKey = "song" .. i
            
            -- Check if this is a new song or existing song
            if not playerSongData[slotKey] or playerSongData[slotKey].buffId ~= songId then
                -- Look up the original spell ID for tiered color
                local spellId = songInfo.spellId -- Default fallback
                if self.spellTracking[playerId] and self.spellTracking[playerId][songId] then
                    spellId = self.spellTracking[playerId][songId]
                end
                
                -- Get tiered color based on actual spell cast
                local tieredColor = self:getTieredColor(spellId)
                
                -- New song detected - don't estimate duration, track actual buff presence
                playerSongData[slotKey] = {
                    buffId = songId,
                    spellId = spellId,
                    name = songInfo.name,
                    type = songInfo.type,
                    color = tieredColor,
                    startTime = currentTime,
                    lastSeenTime = currentTime,
                    isActive = true
                }
                
                local spellName = res.spells[spellId] and res.spells[spellId].name or songInfo.name
                utils:log('New song detected for player ' .. (player.name or 'Unknown') .. ': ' .. spellName .. ' (tier ' .. (SPELL_TIERS[spellId] and SPELL_TIERS[spellId].tier or 1) .. ')', 1)
            else
                -- Update last seen time for existing song
                playerSongData[slotKey].lastSeenTime = currentTime
            end
        end
    end
    
    -- Clear song slots that are no longer active (buff disappeared)
    for slot = 1, 2 do
        local slotKey = "song" .. slot
        if playerSongData[slotKey] then
            local songStillActive = false
            for _, activeSongId in ipairs(playerSongs) do
                if activeSongId == playerSongData[slotKey].buffId then
                    songStillActive = true
                    break
                end
            end
            
            if not songStillActive then
                utils:log('Song expired for player ' .. (player.name or 'Unknown') .. ': ' .. playerSongData[slotKey].name, 1)
                playerSongData[slotKey] = nil
            end
        end
    end
    
    -- Reorganize songs if slot 1 is empty but slot 2 has a song
    if not playerSongData.song1 and playerSongData.song2 then
        playerSongData.song1 = playerSongData.song2
        playerSongData.song2 = nil
        utils:log('Moved song from slot 2 to slot 1', 0)
    end
    
    player.songs = {}
    local songSlot = 1
    
    -- Go through detected songs and assign to slots based on actual buff presence
    for i = 1, 32 do
        local player_buffs = windower.ffxi.get_player().buffs
        if player_buffs[i] and self:isSongBuff(player_buffs[i]) then
            local duration = self:getSongDuration(nil, player_buffs[i])
            
            if duration > 0 and songSlot <= 2 then
                local songInfo = self:getSongInfo(player_buffs[i])
                if songInfo then
                    if not self.songMaxDurations[player_buffs[i]] then
                        self.songMaxDurations[player_buffs[i]] = duration
                    end
                    
                    local buffId = player_buffs[i]
                    player.songs[songSlot] = {
                        duration = duration,
                        maxDuration = self.songMaxDurations[buffId],
                        songType = songInfo.type,
                        name = songInfo.name,
                        color = songInfo.color,
                        buffId = buffId,
                        getDuration = function() return self:getSongDuration(nil, buffId) end
                    }
                    songSlot = songSlot + 1
                end
            end
        end
    end
    
    -- Fill remaining slots
    for slot = songSlot, 2 do
        player.songs[slot] = {
            duration = 0,
            maxDuration = 0,
            songType = 'default'
        }
    end
end

function songTracker:getSongDuration(spellId, buffId)
    local duration = self.buffReader:getBuffDuration(buffId)
    
    if duration and duration > 0 then
        return duration
    end
    
    return 0
end

-- Update all players in the model
function songTracker:updateAllPlayers()
    local currentTime = socket.gettime()
    
    -- Throttle updates to avoid excessive processing
    if currentTime - self.lastUpdateTime < 0.5 then return end
    self.lastUpdateTime = currentTime
    
    -- Update main party songs
    for i = 0, 5 do
        local player = self.model.parties[0][i]
        if player then
            self:updatePlayerSongs(player)
        end
    end
    
    -- Update alliance songs if available
    for partyIdx = 1, 2 do
        for i = 0, 5 do
            local player = self.model.parties[partyIdx][i]
            if player then
                self:updatePlayerSongs(player)
            end
        end
    end
end

-- Clean up expired song data
function songTracker:cleanup()
    local currentTime = socket.gettime()
    for playerId, songData in pairs(self.activeSongs) do
        for slot = 1, 2 do
            local slotKey = "song" .. slot
            if songData[slotKey] then
                -- Clean up songs that haven't been seen for a long time (5 minutes grace period)
                local timeSinceLastSeen = currentTime - songData[slotKey].lastSeenTime
                if timeSinceLastSeen > 300 then -- 5 minutes grace period
                    utils:log('Cleaning up old song data for ' .. songData[slotKey].name, 1)
                    songData[slotKey] = nil
                end
            end
        end
    end
    
    -- Clean up spell tracking for players no longer in model
    local activePlayerIds = {}
    for partyIdx = 0, 2 do
        for i = 0, 5 do
            local player = self.model.parties[partyIdx][i]
            if player and player.id then
                activePlayerIds[player.id] = true
            end
        end
    end
    
    for playerId in pairs(self.spellTracking) do
        if not activePlayerIds[playerId] then
            self.spellTracking[playerId] = nil
        end
    end
end

return songTracker