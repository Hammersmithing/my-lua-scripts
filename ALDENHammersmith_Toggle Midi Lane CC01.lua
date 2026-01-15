-- Toggle_CC1.lua
-- Toggle CC1 (Mod Wheel MSB) lane ON/OFF while preserving other lanes
-- Requires SWS (SNM_* functions)

local targetCC = 1 -- CC1
local laneHeight = 150 -- default height when showing the lane (try 120/150/200) :contentReference[oaicite:1]{index=1}

local function toggle_item(item)
  if not item then return end
  local fast = reaper.SNM_CreateFastString("")
  local ok = reaper.SNM_GetSetObjectState(item, fast, false, false)
  if not ok then reaper.SNM_DeleteFastString(fast) return end

  local chunk = reaper.SNM_GetFastString(fast)
  reaper.SNM_DeleteFastString(fast)
  if not chunk:find("<SOURCE MIDI") then return end

  -- Gather current lanes
  local lanes = {}
  for lane, h1, h2 in chunk:gmatch("\nVELLANE%s+([%-%d]+)%s+([%-%d]+)%s+([%-%d]+)") do
    lanes[tonumber(lane)] = {tonumber(h1), tonumber(h2)}
  end

  if lanes[targetCC] then
    -- Already visible: remove just this CC lane (full line)
    chunk = chunk:gsub("\nVELLANE%s+"..targetCC.."%s+[^\n]+", "")
    -- If no CC lanes remain, add a dummy hidden lane
    if not chunk:find("\nVELLANE") then
      chunk = chunk .. "\nVELLANE -1 0 0"
    end
  else
    -- Not visible: add this CC lane (taller by default)
    local newLine = ("\nVELLANE %d %d %d"):format(targetCC, laneHeight, laneHeight)

    -- Insert after IGNTEMPO if possible, else append
    local before = chunk
    chunk = chunk:gsub("(\nIGNTEMPO [01] [^\n]+)", "%1" .. newLine)
    if chunk == before then
      chunk = chunk .. newLine
    end
  end

  reaper.SetItemStateChunk(item, chunk, false)
end

reaper.Undo_BeginBlock()
for i = 0, reaper.CountSelectedMediaItems(0)-1 do
  toggle_item(reaper.GetSelectedMediaItem(0, i))
end
reaper.Undo_EndBlock("Toggle CC1 lane", -1)
reaper.UpdateArrange()

