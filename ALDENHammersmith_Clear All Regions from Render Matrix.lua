-- Clear All Regions from Render Matrix_v005
-- This script removes all region render matrix assignments using only built-in REAPER API functions (no SWS required).
-- Works for standard Region Render Matrix mode (not MIDI Note Map).
-- Written for REAPER ReaScript (Lua)

-- Ensure compatibility with unpack across Lua versions
table.unpack = table.unpack or unpack

-- Get all regions
local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
if num_regions == 0 then
  reaper.MB("No regions found in the project.", "Error", 0)
  return
end

-- Clear render matrix by setting the RENDER_REGION_MATRIX string to empty
local function clear_render_region_matrix()
  local success = reaper.GetSetProjectInfo_String(0, "RENDER_REGION_MATRIX", "", true)
  if not success then
    reaper.MB("Failed to clear render matrix.", "Error", 0)
    return false
  end
  return true
end

reaper.Undo_BeginBlock()
local ok = clear_render_region_matrix()
reaper.Undo_EndBlock("Clear render matrix (standard mode only)", -1)

if ok then
  reaper.UpdateArrange()
  reaper.MB("Standard Region Render Matrix cleared.", "Done", 0)
end

