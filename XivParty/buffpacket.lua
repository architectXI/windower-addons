--[[
    Copyright © 2024, Tylas
    All rights reserved.

    Packet-based buff timer reading for XivParty
    Copied from GearSwap packet parsing
]]

local classes = require('classes')
local res = require('resources')

local buffPacket = classes.class()

function buffPacket:init()
    self.buff_timers = {}
    self.buff_start_times = {}  -- Track when buffs started for real-time countdown
    self.vana_offset = 572662306+1009810800  -- Default, will be updated by packet 0x37
end

function buffPacket:handleBuffPacket(data)
    if data:byte(0x05) ~= 0x09 then
        return
    end
    
    local newbuffs = {}
    for i=1,32 do
        local buff_id = data:unpack('H',i*2+7)
        if buff_id ~= 255 and buff_id ~= 0 then
            local t = data:unpack('I',i*4+0x45)/60
            newbuffs[i] = {
                id = buff_id,
                time = t,
                duration = function() return t-os.time()+(self.vana_offset or 0) end
            }
        end
    end
    
    for i, buff in pairs(newbuffs) do
        local duration = buff.duration()
        if duration > 0 then
            local old_duration = self.buff_timers[buff.id] or 0
            
            -- If this is a new buff or duration increased significantly, record start time
            if not self.buff_start_times[buff.id] or duration > old_duration + 10 then
                self.buff_start_times[buff.id] = {
                    start_time = os.time(),
                    initial_duration = duration
                }
            end
            
            self.buff_timers[buff.id] = duration
            
        end
    end
end

function buffPacket:getBuffDuration(buff_id)
    local buff_data = self.buff_start_times[buff_id]
    if buff_data then
        local elapsed = os.time() - buff_data.start_time
        local remaining = buff_data.initial_duration - elapsed
        if remaining <= 0 then
            -- Clean up expired buff
            self.buff_start_times[buff_id] = nil
            self.buff_timers[buff_id] = nil
            return 0
        end
        return remaining
    end
    return 0
end

return buffPacket