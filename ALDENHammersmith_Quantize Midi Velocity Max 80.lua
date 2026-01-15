-- Quantize MIDI Velocity Max 80
-- Limits selected MIDI note velocities so any value above 80 becomes 80.

local ceiling = 80   -- <<< MAX VELOCITY

-- Get active MIDI editor
local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

-- Get MIDI take
local take = reaper.MIDIEditor_GetTake(editor)
if not take then return end

reaper.Undo_BeginBlock()
reaper.MIDI_DisableSort(take)

local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)

-- Process notes
for i = 0, noteCount - 1 do
    local ok, sel, mute, startppq, endppq, chan, pitch, vel =
        reaper.MIDI_GetNote(take, i)

    if ok and sel then
        if vel > ceiling then
            vel = ceiling
            reaper.MIDI_SetNote(
                take, i,
                sel, mute,
                startppq, endppq,
                chan, pitch, vel,
                true
            )
        end
    end
end

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Quantize MIDI Velocity Max 80", -1)

