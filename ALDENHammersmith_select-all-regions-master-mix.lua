-- Select All Regions Master Mix in Region Render Matrix
-- Adds all regions to the Master mix row in the Region Render Matrix

local function main()
  local proj = 0 -- current project

  -- Get master track for "Master mix" row in Region Render Matrix
  local master_track = reaper.GetMasterTrack(proj)

  -- Get all regions
  local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)

  if num_regions == 0 then
    reaper.ShowMessageBox("No regions found in project.", "Select All Regions Master Mix", 0)
    return
  end

  local regions_added = 0

  -- Iterate through all markers/regions
  local idx = 0
  while idx < num_markers + num_regions do
    local _, isrgn, _, _, _, markrgnindexnumber = reaper.EnumProjectMarkers(idx)

    if isrgn then
      -- Add this region to Master mix
      -- SetRegionRenderMatrix(proj, region_index, track, addorremove)
      -- track = master_track for Master mix row
      reaper.SetRegionRenderMatrix(proj, markrgnindexnumber, master_track, 1)
      regions_added = regions_added + 1
    end

    idx = idx + 1
  end

  reaper.ShowConsoleMsg("Added " .. regions_added .. " regions to Master mix render matrix.\n")
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Select All Regions Master Mix", -1)
