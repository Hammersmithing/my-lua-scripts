-- Move playhead backward 1 measure (works with tempo/time sig changes)

local cur_pos = reaper.GetCursorPosition()

-- Get current position in measures/beats
local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, cur_pos)

-- Calculate target measure (1 measure back)
local target_measure = measures - 1
if target_measure < 0 then target_measure = 0 end

-- Convert target measure back to time position (start of that measure)
local new_pos = reaper.TimeMap2_beatsToTime(0, 0, target_measure)

reaper.SetEditCurPos(new_pos, true, true)

