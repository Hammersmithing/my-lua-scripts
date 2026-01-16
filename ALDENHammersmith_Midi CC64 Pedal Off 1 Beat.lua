-- MIDI CC64 Pedal Off for 1 Beat
-- Inserts CC64 = 0 (pedal up) at the edit cursor,
-- then CC64 = 127 (pedal down) one beat later (time-signature aware).

local proj = 0

-- Get active MIDI editor
local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

-- Get MIDI take
local take = reaper.MIDIEditor_GetTake(editor)
if not take then return end

-- Use edit cursor position
local cursor_time = reaper.GetCursorPosition()

-- Get current time signature at cursor (num/denom)
local _, num, denom, _ = reaper.TimeMap_GetTimeSigAtTime(proj, cursor_time)
if not denom or denom == 0 then denom = 4 end  -- safety

-- Compute 1 beat length in quarter notes:
-- measure length in QN = num * (4/denom), so 1 beat = (4/denom) QN
local beat_len_qn = 4 / denom

-- Convert cursor time to QN
local cur_qn = reaper.TimeMap2_timeToQN(proj, cursor_time)
local end_qn = cur_qn + beat_len_qn

-- Convert QN back to project time
local end_time = reaper.TimeMap2_QNToTime(proj, end_qn)

-- Convert to PPQ positions for this take
local start_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, cursor_time)
local end_ppq   = reaper.MIDI_GetPPQPosFromProjTime(take, end_time)

-- Settings
local chan      = 0    -- MIDI channel 1 (0-based)
local cc_num    = 64   -- sustain pedal
local val_off   = 0    -- pedal up
local val_on    = 127  -- pedal down

reaper.Undo_BeginBlock()
reaper.MIDI_DisableSort(take)

-- Insert CC64 = 0 at cursor (pedal off)
reaper.MIDI_InsertCC(
    take,
    false,          -- selected
    false,          -- muted
    start_ppq,      -- position
    0xB0,           -- chanmsg (CC)
    chan,
    cc_num,
    val_off
)

-- Insert CC64 = 127 one beat later (pedal back down)
reaper.MIDI_InsertCC(
    take,
    false,
    false,
    end_ppq,
    0xB0,
    chan,
    cc_num,
    val_on
)

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("MIDI CC64 Pedal Off for 1 Beat", -1)

