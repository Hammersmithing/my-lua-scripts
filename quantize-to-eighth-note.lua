-- Quantize selected MIDI notes to 1/8 note grid
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

  -- Get project grid settings for 1/8 note
  -- 1/8 note = 0.5 quarter notes = 0.5 QN
  local eighth_note_qn = 0.5

  reaper.Undo_BeginBlock()

  -- Get all selected notes and quantize them
  local note_idx = 0
  local notes_quantized = 0

  while true do
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)
    if not retval then break end

    if selected then
      -- Convert PPQ to quarter notes
      local start_qn = reaper.MIDI_GetProjQNFromPPQPos(take, startppqpos)
      local end_qn = reaper.MIDI_GetProjQNFromPPQPos(take, endppqpos)
      local note_length_qn = end_qn - start_qn

      -- Quantize start position to nearest 1/8 note
      local quantized_start_qn = math.floor(start_qn / eighth_note_qn + 0.5) * eighth_note_qn
      local quantized_end_qn = quantized_start_qn + note_length_qn

      -- Convert back to PPQ
      local new_startppq = reaper.MIDI_GetPPQPosFromProjQN(take, quantized_start_qn)
      local new_endppq = reaper.MIDI_GetPPQPosFromProjQN(take, quantized_end_qn)

      -- Set the new note position
      reaper.MIDI_SetNote(take, note_idx, selected, muted, math.floor(new_startppq), math.floor(new_endppq), chan, pitch, vel, false)
      notes_quantized = notes_quantized + 1
    end

    note_idx = note_idx + 1
  end

  reaper.MIDI_Sort(take)
  reaper.Undo_EndBlock("Quantize notes to 1/8 grid", -1)

  if notes_quantized == 0 then
    reaper.ShowMessageBox("No notes selected. Please select notes to quantize.", "Info", 0)
  end
end

main()
