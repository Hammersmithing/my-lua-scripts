-- Quantize selected MIDI note lengths to 1/8 note grid
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
  local notes_quantized = 0

  while true do
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)
    if not retval then break end

    if selected then
      -- Convert PPQ positions to quarter notes
      local start_qn = reaper.MIDI_GetProjQNFromPPQPos(take, startppqpos)
      local end_qn = reaper.MIDI_GetProjQNFromPPQPos(take, endppqpos)
      local note_length_qn = end_qn - start_qn

      -- Quantize length to nearest 1/8 note (minimum 1/8 note)
      local quantized_length_qn = math.floor(note_length_qn / eighth_note_qn + 0.5) * eighth_note_qn
      if quantized_length_qn < eighth_note_qn then
        quantized_length_qn = eighth_note_qn
      end

      -- Calculate new end position
      local new_end_qn = start_qn + quantized_length_qn
      local new_endppq = reaper.MIDI_GetPPQPosFromProjQN(take, new_end_qn)

      -- Set the new note length (keep start position unchanged)
      reaper.MIDI_SetNote(take, note_idx, selected, muted, startppqpos, math.floor(new_endppq), chan, pitch, vel, false)
      notes_quantized = notes_quantized + 1
    end

    note_idx = note_idx + 1
  end

  reaper.MIDI_Sort(take)
  reaper.Undo_EndBlock("Quantize note lengths to 1/8 grid", -1)

  if notes_quantized == 0 then
    reaper.ShowMessageBox("No notes selected. Please select notes to quantize.", "Info", 0)
  end
end

main()
