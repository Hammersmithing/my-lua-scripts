-- MIDI - Shorten Selected Notes by 25ms
-- For all selected notes in the active MIDI editor,
-- move the note end 25 ms earlier to create a small gap.
-- Notes shorter than 25 ms are clamped to a 1 ms minimum length.

local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

local take = reaper.MIDIEditor_GetTake(editor)
if not take then return end

reaper.Undo_BeginBlock()
reaper.MIDI_DisableSort(take)

local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)

local shorten_sec = 0.025  -- 25 ms
local min_len_sec = 0.001  -- 1 ms minimum note length

for i = 0, noteCount - 1 do
    local ok, sel, mute, startppq, endppq, chan, pitch, vel =
        reaper.MIDI_GetNote(take, i)

    if ok and sel then
        -- Convert PPQ to project time
        local start_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
        local end_time   = reaper.MIDI_GetProjTimeFromPPQPos(take, endppq)

        -- New end time: 25 ms earlier, but at least 1 ms after start
        local new_end_time = end_time - shorten_sec
        local min_end_time = start_time + min_len_sec
        if new_end_time < min_end_time then
            new_end_time = min_end_time
        end

        -- Convert back to PPQ
        local new_end_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, new_end_time)

        reaper.MIDI_SetNote(
            take,
            i,
            sel,
            mute,
            startppq,
            new_end_ppq,
            chan,
            pitch,
            vel,
            true -- noSort
        )
    end
end

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Shorten selected notes by 25ms", -1)

