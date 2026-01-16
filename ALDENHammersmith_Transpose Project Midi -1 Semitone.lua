-- Transpose ALL MIDI in project DOWN 1 semitone (no editor needed, no dialog)

local proj = 0
local TRANSPOSE = -1 -- down 1 semitone

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local itemCount = reaper.CountMediaItems(proj)
local changed = 0

for i = 0, itemCount - 1 do
  local item = reaper.GetMediaItem(proj, i)
  local takeCount = reaper.CountTakes(item)

  for t = 0, takeCount - 1 do
    local take = reaper.GetTake(item, t)
    if take and reaper.TakeIsMIDI(take) then  -- :contentReference[oaicite:0]{index=0}
      reaper.MIDI_DisableSort(take)           -- :contentReference[oaicite:1]{index=1}

      local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)
      for n = 0, noteCount - 1 do
        local ok, sel, muted, startppq, endppq, chan, pitch, vel =
          reaper.MIDI_GetNote(take, n)        -- :contentReference[oaicite:2]{index=2}
        if ok then
          local newPitch = pitch + TRANSPOSE
          if newPitch < 0 then newPitch = 0 end
          if newPitch > 127 then newPitch = 127 end

          -- Set note (noSort=true while batch editing)
          reaper.MIDI_SetNote(take, n, sel, muted, startppq, endppq, chan, newPitch, vel, true) -- :contentReference[oaicite:3]{index=3}
          changed = changed + 1
        end
      end

      reaper.MIDI_Sort(take)                  -- :contentReference[oaicite:4]{index=4}
    end
  end
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Transpose ALL MIDI down 1 semitone (" .. tostring(changed) .. " notes)", -1)

