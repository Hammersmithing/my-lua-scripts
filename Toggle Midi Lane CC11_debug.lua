-- Toggle_CC11_DEBUG.lua
-- Debug version to find the issue

local targetCC = 11

-- Check SWS
if not reaper.SNM_CreateFastString then
  reaper.ShowMessageBox("SWS Extension is not installed!\nThis script requires SWS.", "Error", 0)
  return
end

-- Check selection
local sel_count = reaper.CountSelectedMediaItems(0)
reaper.ShowConsoleMsg("Selected items: " .. sel_count .. "\n")

if sel_count == 0 then
  reaper.ShowMessageBox("No items selected.\nSelect a MIDI item in the arrange view first.", "Error", 0)
  return
end

local function toggle_item(item)
  if not item then
    reaper.ShowConsoleMsg("Item is nil\n")
    return
  end

  local fast = reaper.SNM_CreateFastString("")
  local ok = reaper.SNM_GetSetObjectState(item, fast, false, false)
  if not ok then
    reaper.ShowConsoleMsg("Failed to get item state\n")
    reaper.SNM_DeleteFastString(fast)
    return
  end

  local chunk = reaper.SNM_GetFastString(fast)
  reaper.SNM_DeleteFastString(fast)

  if not chunk:find("<SOURCE MIDI") then
    reaper.ShowConsoleMsg("Item is not a MIDI item\n")
    return
  end

  reaper.ShowConsoleMsg("Processing MIDI item...\n")

  -- Gather current lanes
  local lanes = {}
  for lane, h1, h2 in chunk:gmatch("\nVELLANE%s+([%-%d]+)%s+([%-%d]+)%s+([%-%d]+)") do
    lanes[tonumber(lane)] = {tonumber(h1), tonumber(h2)}
    reaper.ShowConsoleMsg("  Found lane: " .. lane .. "\n")
  end

  if lanes[targetCC] then
    reaper.ShowConsoleMsg("CC11 is visible, removing...\n")
    chunk = chunk:gsub("\nVELLANE%s+"..targetCC.."%s+[^\n]+", "")
    if not chunk:find("\nVELLANE") then
      chunk = chunk .. "\nVELLANE -1 0 0"
    end
  else
    reaper.ShowConsoleMsg("CC11 not visible, adding...\n")
    local newLine = "\nVELLANE " .. targetCC .. " 50 50"
    local before = chunk
    chunk = chunk:gsub("(\nIGNTEMPO [01] [^\n]+)", "%1" .. newLine)
    if chunk == before then
      chunk = chunk .. newLine
    end
  end

  reaper.SetItemStateChunk(item, chunk, false)
  reaper.ShowConsoleMsg("Done!\n")
end

reaper.Undo_BeginBlock()
for i = 0, sel_count-1 do
  toggle_item(reaper.GetSelectedMediaItem(0, i))
end
reaper.Undo_EndBlock("Toggle CC11 lane", -1)
reaper.UpdateArrange()
