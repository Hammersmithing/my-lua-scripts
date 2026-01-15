-- test-button-selectTr1_enablerecord.lua
-- Selects track 1 and record enables it

-- Get track 1 (index 0)
local track = reaper.GetTrack(0, 0)

if track then
  -- Unselect all tracks first
  reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks

  -- Select track 1
  reaper.SetTrackSelected(track, true)

  -- Record enable track 1
  reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
else
  reaper.ShowConsoleMsg("Error: No track 1 found in project\n")
end
