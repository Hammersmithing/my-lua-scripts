-- MIDI Velocity Compression 5%
-- Scales selected MIDI note velocities down by 5% (vel * 0.95).

local factor = 0.95  -- 5% reduction

-- Get active MIDI editor
local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

-- Get MIDI take
local take = reaper.MIDIEditor_GetTake(editor)
if not take then return end

reaper.Undo_BeginBlock()
reaper.MIDI_DisableSort(take)

local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)

for i = 0, noteCount - 1 do
    local ok, sel, mute, startppq, endppq, chan, pitch, vel =
        reaper.MIDI_GetNote(take, i)

    if ok and sel then
        local new_vel = math.floor(vel * factor + 0.5)

        -- Clamp to safe MIDI range (1–127)
        if new_vel < 1 then new_vel = 1 end
        if new_vel > 127 then new_vel = 127 end

        reaper.MIDI_SetNote(
            take, i,
            sel, mute,
            startppq, endppq,
            chan, pitch, new_vel,
            true -- noSort
        )
    end
end

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("MIDI Velocity Compression 5%", -1)

