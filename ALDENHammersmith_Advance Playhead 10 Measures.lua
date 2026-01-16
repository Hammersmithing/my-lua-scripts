-- Get the current playhead position
local cur_pos = reaper.GetCursorPosition()

-- Get tempo (BPM) at the current position
local bpm = reaper.TimeMap_GetDividedBpmAtTime(cur_pos)

-- Default to 4 beats per measure (assuming 4/4 time)
local beats_per_measure = 4

-- Get time signature markers and determine the current time signature
local num_markers = reaper.CountTempoTimeSigMarkers(0)
for i = 0, num_markers - 1 do
    local retval, pos, _, num, den, _ = reaper.GetTempoTimeSigMarker(0, i)
    if retval and pos <= cur_pos then
        beats_per_measure = num -- Use the latest valid beats per measure
    else
        break
    end
end

-- Calculate the length of 10 measures in seconds
local sec_per_beat = 60 / bpm
local sec_per_measure = sec_per_beat * beats_per_measure
local time_to_move = sec_per_measure * 10

-- Move the playhead forward
reaper.SetEditCurPos(cur_pos + time_to_move, true, false)

