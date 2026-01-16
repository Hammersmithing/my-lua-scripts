-- Transpose selected MIDI notes up one octave (+12 semitones)
-- For use in REAPER MIDI Editor

local function main()
  local hwnd = reaper.MIDIEditor_GetActive()
  if not hwnd then
    reaper.ShowMessageBox("Please open a MIDI editor first.", "Error", 0)
    return
  end

  local take = reaper.MIDIEditor_GetTake(hwnd)
  if not take then
    reaper.ShowMessageBox("No active MIDI take.", "Error", 0)
    return
  end

  reaper.Undo_BeginBlock()

  local note_idx = 0
  local notes_transposed = 0

  while true do
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)
    if not retval then break end

    if selected then
      local new_pitch = pitch + 12
      if new_pitch <= 127 then
        reaper.MIDI_SetNote(take, note_idx, nil, nil, nil, nil, nil, new_pitch, nil, true)
        notes_transposed = notes_transposed + 1
      end
    end

    note_idx = note_idx + 1
  end

  reaper.MIDI_Sort(take)

  local item = reaper.GetMediaItemTake_Item(take)
  if item then
    reaper.UpdateItemInProject(item)
  end

  reaper.Undo_EndBlock("Transpose octave up", -1)
  reaper.UpdateArrange()
end

main()
