-- Make selected MIDI note lengths exactly 1/8 note
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

  -- 1/8 note = 0.5 quarter notes
  local eighth_note_qn = 0.5

  reaper.Undo_BeginBlock()

  local note_idx = 0
  local notes_changed = 0

  while true do
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)
    if not retval then break end

    if selected then
      -- Get start position in quarter notes
      local start_qn = reaper.MIDI_GetProjQNFromPPQPos(take, startppqpos)

      -- Set end position to exactly 1/8 note after start
      local new_end_qn = start_qn + eighth_note_qn
      local new_endppq = reaper.MIDI_GetPPQPosFromProjQN(take, new_end_qn)

      -- Set the new note length
      reaper.MIDI_SetNote(take, note_idx, nil, nil, nil, math.floor(new_endppq), nil, nil, nil, true)
      notes_changed = notes_changed + 1
    end

    note_idx = note_idx + 1
  end

  reaper.MIDI_Sort(take)

  local item = reaper.GetMediaItemTake_Item(take)
  if item then
    reaper.UpdateItemInProject(item)
  end

  reaper.Undo_EndBlock("Make note lengths 1/8", -1)
  reaper.UpdateArrange()
end

main()
