-- @description Quantize selected MIDI note ends (ALWAYS FORWARD to next gridline, timesig + swing aware)
-- @version 1.0
-- @author you
-- @provides [main=main,midi_editor] .

-- Quantizes note ends forward to the next MIDI editor grid position.
-- Uses QN math (works across tempo changes). Respects MIDI editor swing.

local function quantize_note_end_forward(take, note_idx, startppq, endppq, grid_qn, swing)
  -- convert current end to project QN
  local qn_end = reaper.MIDI_GetProjQNFromPPQPos(take, endppq)
  local eps = 1e-12
  local target_qn

  if swing and math.abs(swing) > eps then
    -- swing grid: pair = 2*grid, with swung midpoint at g + swing*(g/2)
    local pair = 2 * grid_qn
    local pos_in_pair = qn_end % pair
    local base = qn_end - pos_in_pair
    local swing_mid = base + grid_qn + swing * (grid_qn / 2)

    if qn_end < swing_mid - eps then
      target_qn = swing_mid
    else
      -- if exactly on swingpoint or after it, go to the end of the pair
      target_qn = base + pair
    end
  else
    -- straight grid: always go to next multiple of grid_qn
    local rem = qn_end % grid_qn
    local base = qn_end - rem
    if rem <= eps then
      target_qn = base + grid_qn  -- already on grid -> move to next
    else
      target_qn = base + grid_qn
    end
  end

  local out_ppq = reaper.MIDI_GetPPQPosFromProjQN(take, target_qn)
  if out_ppq <= startppq then
    out_ppq = startppq + 1 -- ensure positive length
  end

  -- read original values to keep chan/pitch/vel
  local ok, sel, muted, sppq, eppq, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)
  if ok and sel then
    reaper.MIDI_SetNote(take, note_idx, true, muted, startppq, out_ppq, chan, pitch, vel, true)
  end
end

local function process_take(take)
  if not take or not reaper.TakeIsMIDI(take) then return end
  local grid_qn, swing = reaper.MIDI_GetGrid(take) -- grid in QN, swing 0..1
  local _, note_count = reaper.MIDI_CountEvts(take)
  for i = 0, note_count-1 do
    local ok, sel, muted, startppq, endppq = reaper.MIDI_GetNote(take, i)
    if ok and sel then
      quantize_note_end_forward(take, i, startppq, endppq, grid_qn, swing or 0)
    end
  end
  reaper.MIDI_Sort(take)
end

reaper.Undo_BeginBlock()

local me = reaper.MIDIEditor_GetActive()
if me then
  -- process all editable takes in the active MIDI editor
  local idx = 0
  while true do
    local take = reaper.MIDIEditor_EnumTakes(me, idx, true)
    if not take then break end
    process_take(take)
    idx = idx + 1
  end
else
  -- process active takes of selected items
  local sel_cnt = reaper.CountSelectedMediaItems(0)
  for i = 0, sel_cnt-1 do
    local it = reaper.GetSelectedMediaItem(0, i)
    local take = it and reaper.GetActiveTake(it) or nil
    if take then process_take(take) end
  end
end

reaper.Undo_EndBlock("Quantize selected MIDI note ends (forward to next gridline)", -1)

