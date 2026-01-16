-- @description Apply sustain pedal (CC64) to note lengths (extend notes), optionally remove CC64
-- @version 1.0
-- @author
-- @about
--   Extends MIDI notes whose note-off occurs while sustain pedal (CC64) is down so they end at pedal-up.
--   Optionally deletes CC64 events afterwards to leave “clean” note data.

----------------------------------------------------------------
-- USER SETTINGS
----------------------------------------------------------------
local THRESHOLD = 64                 -- CC64 value >= THRESHOLD is considered pedal down
local DELETE_CC64 = true             -- delete CC64 events after applying them
local ONLY_SELECTED_NOTES = false    -- true = only process selected notes
local CAP_AT_NEXT_NOTE_ON = true     -- prevent extending beyond next note-on of same pitch+channel

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function logln(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
end

local function get_target_take()
  -- Prefer active MIDI editor take
  local editor = reaper.MIDIEditor_GetActive()
  if editor then
    local t = reaper.MIDIEditor_GetTake(editor)
    if t and reaper.TakeIsMIDI(t) then return t end
  end

  -- Fallback: first selected item's active take
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item then
    local t = reaper.GetActiveTake(item)
    if t and reaper.TakeIsMIDI(t) then return t end
  end

  return nil
end

local function build_pedal_intervals_per_channel(take, cc_cnt, item_end_ppq)
  -- Collect CC64 events per channel
  local pedalEvts = {} -- pedalEvts[chan] = { {ppq=..., val=...}, ... }
  local pedalEventCount = 0

  for i = 0, cc_cnt - 1 do
    local ok, _, _, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, i)
    if ok and chanmsg == 0xB0 and msg2 == 64 then
      pedalEvts[chan] = pedalEvts[chan] or {}
      table.insert(pedalEvts[chan], { ppq = ppqpos, val = msg3 })
      pedalEventCount = pedalEventCount + 1
    end
  end

  if pedalEventCount == 0 then
    return {}, 0
  end

  -- Build intervals per channel: { {down=..., up=...}, ... }
  local intervals = {} -- intervals[chan] = list of intervals

  for chan = 0, 15 do
    local evts = pedalEvts[chan]
    if evts and #evts > 0 then
      table.sort(evts, function(a, b) return a.ppq < b.ppq end)

      local stateDown = false
      local downPPQ = nil

      for _, e in ipairs(evts) do
        if e.val >= THRESHOLD then
          if not stateDown then
            stateDown = true
            downPPQ = e.ppq
          end
        else
          if stateDown then
            stateDown = false
            intervals[chan] = intervals[chan] or {}
            table.insert(intervals[chan], { down = downPPQ, up = e.ppq })
            downPPQ = nil
          end
        end
      end

      -- If pedal never released, end interval at item end
      if stateDown and downPPQ ~= nil then
        intervals[chan] = intervals[chan] or {}
        table.insert(intervals[chan], { down = downPPQ, up = item_end_ppq })
      end
    end
  end

  return intervals, pedalEventCount
end

local function find_pedal_up(interval_list, t)
  -- Return pedal-up PPQ if t is inside any interval (down <= t < up)
  if not interval_list then return nil end
  for _, iv in ipairs(interval_list) do
    if t >= iv.down and t < iv.up then
      return iv.up
    end
  end
  return nil
end

----------------------------------------------------------------
-- Main
----------------------------------------------------------------
local take = get_target_take()
if not take then
  reaper.ShowMessageBox(
    "No MIDI take found.\n\nOpen a MIDI editor, or select a MIDI item, then run the script.",
    "Apply Sustain Pedal to Notes",
    0
  )
  return
end

local item = reaper.GetMediaItemTake_Item(take)
local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
local item_end_time = item_pos + item_len
local item_end_ppq = math.ceil(reaper.MIDI_GetPPQPosFromProjTime(take, item_end_time))

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

reaper.MIDI_DisableSort(take)

local _, note_cnt, cc_cnt, _ = reaper.MIDI_CountEvts(take)

-- Build note list and group by chan/pitch to compute next note start (optional cap)
local notes = {}
local groups = {} -- groups[chan][pitch] = { noteRef, ... }

for i = 0, note_cnt - 1 do
  local ok, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
  if ok then
    local n = {
      idx = i,
      sel = sel,
      muted = muted,
      startppq = startppq,
      endppq = endppq,
      chan = chan,
      pitch = pitch,
      vel = vel,
      next_start = nil
    }
    notes[#notes + 1] = n

    groups[chan] = groups[chan] or {}
    groups[chan][pitch] = groups[chan][pitch] or {}
    table.insert(groups[chan][pitch], n)
  end
end

if CAP_AT_NEXT_NOTE_ON then
  for _, pitches in pairs(groups) do
    for _, list in pairs(pitches) do
      table.sort(list, function(a, b)
        if a.startppq == b.startppq then
          return a.endppq < b.endppq
        end
        return a.startppq < b.startppq
      end)
      for j = 1, #list - 1 do
        list[j].next_start = list[j + 1].startppq
      end
    end
  end
end

-- Build pedal intervals
local intervals, pedalEventCount = build_pedal_intervals_per_channel(take, cc_cnt, item_end_ppq)
if pedalEventCount == 0 then
  reaper.MIDI_Sort(take)
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("Apply sustain pedal to note lengths", -1)
  reaper.ShowMessageBox("No CC64 sustain pedal events found in this take.", "Apply Sustain Pedal to Notes", 0)
  return
end

-- Extend notes
local extended = 0

for _, n in ipairs(notes) do
  if (not ONLY_SELECTED_NOTES) or n.sel then
    local up = find_pedal_up(intervals[n.chan], n.endppq)
    if up and up > n.endppq then
      local new_end = up

      if CAP_AT_NEXT_NOTE_ON and n.next_start then
        -- Only cap if we're extending past original end, and next note begins after original end
        if n.next_start > n.endppq and n.next_start < new_end then
          new_end = n.next_start
        end
      end

      if new_end > n.startppq then
        reaper.MIDI_SetNote(
          take,
          n.idx,
          n.sel,
          n.muted,
          n.startppq,
          new_end,
          n.chan,
          n.pitch,
          n.vel,
          true -- noSort
        )
        extended = extended + 1
      end
    end
  end
end

-- Optionally delete CC64 events
local deleted = 0
if DELETE_CC64 then
  for i = cc_cnt - 1, 0, -1 do
    local ok, _, _, _, chanmsg, _, msg2, _ = reaper.MIDI_GetCC(take, i)
    if ok and chanmsg == 0xB0 and msg2 == 64 then
      reaper.MIDI_DeleteCC(take, i)
      deleted = deleted + 1
    end
  end
end

reaper.MIDI_Sort(take)

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

reaper.Undo_EndBlock("Apply sustain pedal to note lengths (CC64 -> note ends)", -1)

-- Summary in console
logln(("Apply Sustain Pedal to Notes: extended %d notes; %s %d CC64 events."):format(
  extended,
  DELETE_CC64 and "deleted" or "kept",
  deleted
))

