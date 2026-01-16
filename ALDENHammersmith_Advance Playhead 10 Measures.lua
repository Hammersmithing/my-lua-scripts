-- Move playhead forward 10 measures (works with tempo/time sig changes)

local cur_pos = reaper.GetCursorPosition()

-- Get current position in measures/beats
-- Returns: retval, measures, cml, fullbeats, cdenom
local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, cur_pos)

-- Calculate target measure (10 measures forward)
local target_measure = measures + 10

-- Convert target measure back to time position (start of that measure)
local new_pos = reaper.TimeMap2_beatsToTime(0, 0, target_measure)

reaper.SetEditCurPos(new_pos, true, false)

