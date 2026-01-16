-- Tempo Map from Markers
-- Place markers at your downbeats (beat 1 of each bar), then run this script
-- It will create tempo changes so the grid aligns with your markers

local function main()
  -- Get number of markers
  local num_markers, num_regions = reaper.CountProjectMarkers(0)

  if num_markers < 2 then
    reaper.ShowMessageBox("Need at least 2 markers to create tempo map.\n\nPlace markers at your downbeats (beat 1 of each bar), then run this script.", "Tempo Map", 0)
    return
  end

  -- Collect marker positions
  local markers = {}
  local marker_count = 0

  for i = 0, num_markers + num_regions - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
    if retval > 0 and not isrgn then
      marker_count = marker_count + 1
      markers[marker_count] = pos
    end
  end

  if marker_count < 2 then
    reaper.ShowMessageBox("Need at least 2 markers (not regions) to create tempo map.", "Tempo Map", 0)
    return
  end

  -- Sort markers by position
  table.sort(markers)

  -- Get time signature (assume it stays constant)
  local bpm, bpi = reaper.GetProjectTimeSignature2(0)
  local beats_per_bar = bpi  -- beats per bar from project settings

  reaper.Undo_BeginBlock()

  -- Delete existing tempo markers first? Ask user
  local response = reaper.ShowMessageBox(
    "Found " .. marker_count .. " markers.\n\n" ..
    "This will create tempo changes at each marker position.\n" ..
    "Assumes each marker is beat 1 of a bar (" .. beats_per_bar .. " beats per bar).\n\n" ..
    "Continue?",
    "Tempo Map from Markers", 4)

  if response ~= 6 then return end  -- 6 = Yes

  -- Create tempo markers
  local tempos_created = 0

  for i = 1, marker_count - 1 do
    local pos1 = markers[i]
    local pos2 = markers[i + 1]
    local time_diff = pos2 - pos1

    -- Calculate BPM: beats_per_bar beats in time_diff seconds
    -- BPM = (beats_per_bar / time_diff) * 60
    local new_bpm = (beats_per_bar / time_diff) * 60

    -- Clamp to reasonable range
    if new_bpm < 20 then new_bpm = 20 end
    if new_bpm > 300 then new_bpm = 300 end

    -- Create tempo marker at pos1
    -- SetTempoTimeSigMarker(proj, ptidx, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo)
    -- ptidx = -1 to create new marker
    reaper.SetTempoTimeSigMarker(0, -1, pos1, -1, -1, new_bpm, 0, 0, true)
    tempos_created = tempos_created + 1
  end

  -- Update timeline
  reaper.UpdateTimeline()

  reaper.Undo_EndBlock("Tempo map from markers", -1)

  reaper.ShowMessageBox("Created " .. tempos_created .. " tempo changes.\n\nYour grid should now align with your markers!", "Tempo Map Complete", 0)
end

main()
