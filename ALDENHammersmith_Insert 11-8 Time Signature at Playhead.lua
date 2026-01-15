-- Set Meter 11/8 at Cursor
-- Inserts a 11/8 time signature marker at the current edit cursor position,
-- keeping the current tempo, and affecting the timeline from there
-- until the next time signature marker.

local proj = 0

-- Use edit cursor position
local pos = reaper.GetCursorPosition()
if not pos then return end

-- Get current tempo at that position
local bpm = reaper.TimeMap_GetDividedBpmAtTime(pos)
if not bpm or bpm <= 0 then bpm = 120 end -- safety fallback

local ts_num   = 11
local ts_denom = 8
local lineartempo = false  -- normal tempo behavior

reaper.Undo_BeginBlock()

reaper.AddTempoTimeSigMarker(
    proj,
    pos,
    bpm,
    ts_num,
    ts_denom,
    lineartempo
)

reaper.UpdateTimeline()
reaper.Undo_EndBlock("Set meter 11/8 at cursor", -1)
