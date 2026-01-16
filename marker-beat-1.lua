-- Create marker named "beat 1" at playhead position

local function main()
  local playhead_pos = reaper.GetCursorPosition()
  reaper.AddProjectMarker(0, false, playhead_pos, 0, "beat 1", -1)
end

main()
