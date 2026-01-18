-- Clear Region Selections from Render Region Matrix
-- Removes all regions from all tracks in the Region Render Matrix

local function main()
  local proj = 0 -- current project

  -- Get all regions
  local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)

  if num_regions == 0 then
    reaper.ShowMessageBox("No regions found in project.", "Clear Region Render Matrix", 0)
    return
  end

  local regions_cleared = 0

  -- Get track count (including master)
  local num_tracks = reaper.CountTracks(proj)

  -- Iterate through all markers/regions
  local idx = 0
  while idx < num_markers + num_regions do
    local _, isrgn, _, _, _, markrgnindexnumber = reaper.EnumProjectMarkers(idx)

    if isrgn then
      -- Clear from master track
      local master_track = reaper.GetMasterTrack(proj)
      reaper.SetRegionRenderMatrix(proj, markrgnindexnumber, master_track, -1)

      -- Clear from all tracks
      for t = 0, num_tracks - 1 do
        local track = reaper.GetTrack(proj, t)
        reaper.SetRegionRenderMatrix(proj, markrgnindexnumber, track, -1)
      end

      regions_cleared = regions_cleared + 1
    end

    idx = idx + 1
  end

  reaper.ShowConsoleMsg("Cleared " .. regions_cleared .. " regions from render matrix.\n")
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Clear Region Selections from Render Matrix", -1)
