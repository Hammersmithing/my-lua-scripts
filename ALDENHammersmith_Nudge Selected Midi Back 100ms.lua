-- Nudge Selected MIDI Backward 100ms
-- Moves selected notes AND selected CC events 100ms earlier.
-- Prevents negative time positions.

local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

local take = reaper.MIDIEditor_GetTake(editor)
if not take then return end

reaper.Undo_BeginBlock()
reaper.MIDI_DisableSort(take)

local shift_sec = 0.100 -- 100 ms backwards

local _, noteCount, ccCount, _ = reaper.MIDI_CountEvts(take)

------------------------------------------------------------
-- Process NOTES
------------------------------------------------------------
for i = 0, noteCount - 1 do
    local ok, sel, mute, startppq, endppq, chan, pitch, vel =
        reaper.MIDI_GetNote(take, i)

    if ok and sel then
        -- Convert PPQ to time
        local start_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
        local end_time   = reaper.MIDI_GetProjTimeFromPPQPos(take, endppq)

        -- Shift backward
        start_time = start_time - shift_sec
        end_time   = end_time - shift_sec

        -- Prevent negative times
        if start_time < 0 then
            local diff = -start_time
            start_time = 0
            end_time   = end_time + diff  -- preserve note length
        end

        -- Convert back to PPQ
        local new_start_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, start_time)
        local new_end_ppq   = reaper.MIDI_GetPPQPosFromProjTime(take, end_time)

        reaper.MIDI_SetNote(
            take, i,
            sel, mute,
            new_start_ppq, new_end_ppq,
            chan, pitch, vel,
            true -- noSort
        )
    end
end

------------------------------------------------------------
-- Process CC EVENTS (pitch, modwheel, sustain, etc.)
------------------------------------------------------------
for i = 0, ccCount - 1 do
    local ok, sel, mute, ppqpos, chanmsg, chan, msg2, msg3 =
        reaper.MIDI_GetCC(take, i)

    if ok and sel then
        local time = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)

        -- Shift backward
        time = time - shift_sec

        -- Prevent negative
        if time < 0 then time = 0 end

        local new_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, time)

        reaper.MIDI_SetCC(
            take, i,
            sel, mute,
            new_ppq,
            chanmsg, chan,
            msg2, msg3,
            true
        )
    end
end

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Nudge selected MIDI -100ms", -1)
