-- Open ALL project MIDI in one MIDI editor and select everything (no dialogs)
-- Runs from Arrange view.

local proj = 0

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local itemCount = reaper.CountMediaItems(proj)
if itemCount == 0 then
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("Open ALL project MIDI in editor (none found)", -1)
  reaper.ShowMessageBox("No media items in project.", "Error", 0)
  return
end

-- Select ONLY items whose active take is MIDI
local any = false
for i = 0, itemCount - 1 do
  local item = reaper.GetMediaItem(proj, i)
  local take = reaper.GetActiveTake(item)
  local isMidi = take and reaper.TakeIsMIDI(take)

  reaper.SetMediaItemSelected(item, isMidi and true or false)
  if isMidi then any = true end
end

if not any then
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("Open ALL project MIDI in editor (no MIDI items)", -1)
  reaper.ShowMessageBox("No MIDI items found (active takes).", "Error", 0)
  return
end

reaper.UpdateArrange()

-- Open in built-in MIDI editor (behavior depends on your Preferences)
-- Commonly used as: Item: Open in built-in MIDI editor (set default behavior in preferences) :contentReference[oaicite:6]{index=6}
reaper.Main_OnCommand(40153, 0)

-- Select all MIDI content (notes/CC/etc) in every MIDI take
for i = 0, itemCount - 1 do
  local item = reaper.GetMediaItem(proj, i)
  local take = reaper.GetActiveTake(item)
  if take and reaper.TakeIsMIDI(take) then
    reaper.MIDI_SelectAll(take, true) -- :contentReference[oaicite:7]{index=7}
  end
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Open ALL project MIDI in editor and select all", -1)

