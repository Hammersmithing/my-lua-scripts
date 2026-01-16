-- Monophonic Legato for Selected Notes
-- Extends each selected note so that its end reaches
-- the start of the next selected note.
-- Assumes monophonic input: no two selected notes share a start time.

local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

local take = reaper.MIDIEditor_GetTake(editor)
if not take then return end

reaper.Undo_BeginBlock()
reaper.MIDI_DisableSort(take)

local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)
local notes = {}

-- Collect selected notes only
for i = 0, noteCount - 1 do
    local ok, sel, mute, startppq, endppq, chan, pitch, vel =
        reaper.MIDI_GetNote(take, i)

    if ok and sel then
        notes[#notes+1] = {
            idx      = i,
            sel      = sel,
            mute     = mute,
            startppq = startppq,
            endppq   = endppq,
            chan     = chan,
            pitch    = pitch,
            vel      = vel
        }
    end
end

-- If nothing selected, do nothing
if #notes == 0 then
    reaper.MIDI_Sort(take)
    reaper.Undo_EndBlock("Monophonic legato", -1)
    return
end

-- Sort selected notes by start time (monophonic = one at each time)
table.sort(notes, function(a, b)
    return a.startppq < b.startppq
end)

-- Extend each note to the next start
for i = 1, #notes - 1 do
    local curr = notes[i]
    local next_note = notes[i+1]

    reaper.MIDI_SetNote(
        take,
        curr.idx,
        curr.sel,
        curr.mute,
        curr.startppq,
        next_note.startppq,  -- new end = next start
        curr.chan,
        curr.pitch,
        curr.vel,
        true
    )
end

-- Last note remains unchanged

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Monophonic legato", -1)

