-- Get the current playhead position
local cur_pos = reaper.GetCursorPosition()

-- Get tempo (BPM) at the current position
local bpm = reaper.TimeMap_GetDividedBpmAtTime(cur_pos)

-- Default to 4 beats per measure (assuming 4/4 time)
local beats_per_measure = 4

-- Get time signature markers and determine the current time signature
-- API: retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo
local num_markers = reaper.CountTempoTimeSigMarkers(0)

for i = 0, num_markers - 1 do
    local retval, timepos, measurepos, beatpos, marker_bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(0, i)
    if retval and timepos <= cur_pos and timesig_num > 0 then
        beats_per_measure = timesig_num
    elseif timepos > cur_pos then
        break
    end
end

-- Calculate the length of 10 measures in seconds
local sec_per_beat = 60 / bpm
local sec_per_measure = sec_per_beat * beats_per_measure
local time_to_move = sec_per_measure * 10

-- Move the playhead BACKWARD
local new_pos = cur_pos - time_to_move
if new_pos < 0 then new_pos = 0 end -- Prevent negative position

reaper.SetEditCurPos(new_pos, true, false)

