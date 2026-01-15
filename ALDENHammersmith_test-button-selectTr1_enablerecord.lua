-- test-button-selectTr1_enablerecord.lua
-- GUI button that selects track 1 and record enables it

-- Initialize graphics window
gfx.init("Select & Arm Track 1", 200, 60)

-- Button dimensions
local btn_x, btn_y = 20, 15
local btn_w, btn_h = 160, 30

-- Track mouse state for debouncing
local mouse_was_down = false

-- Function to select and arm track 1
local function selectAndArmTrack1()
  local track = reaper.GetTrack(0, 0)
  if track then
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    reaper.SetTrackSelected(track, true)
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
  else
    reaper.ShowConsoleMsg("Error: No track 1 found in project\n")
  end
end

-- Check if mouse is over button
local function isMouseOverButton()
  return gfx.mouse_x >= btn_x and gfx.mouse_x <= btn_x + btn_w
     and gfx.mouse_y >= btn_y and gfx.mouse_y <= btn_y + btn_h
end

-- Main loop
local function main()
  -- Clear background
  gfx.set(0.2, 0.2, 0.2)
  gfx.rect(0, 0, gfx.w, gfx.h, 1)

  -- Draw button
  local hover = isMouseOverButton()
  local mouse_down = (gfx.mouse_cap & 1) == 1

  -- Button color (lighter when hovering)
  if hover then
    gfx.set(0.4, 0.6, 0.8) -- Light blue on hover
  else
    gfx.set(0.3, 0.5, 0.7) -- Normal blue
  end

  gfx.rect(btn_x, btn_y, btn_w, btn_h, 1) -- Filled rectangle

  -- Button border
  gfx.set(0.2, 0.3, 0.5)
  gfx.rect(btn_x, btn_y, btn_w, btn_h, 0) -- Border only

  -- Button text
  gfx.set(1, 1, 1) -- White text
  gfx.x = btn_x + 15
  gfx.y = btn_y + 8
  gfx.drawstr("Arm Track 1")

  -- Handle click (trigger on mouse down, only once)
  if mouse_down and hover and not mouse_was_down then
    selectAndArmTrack1()
  end

  -- Update mouse state for next frame
  mouse_was_down = mouse_down

  gfx.update()

  -- Keep window open
  local char = gfx.getchar()
  if char >= 0 and char ~= 27 then -- 27 = ESC to close
    reaper.defer(main)
  else
    gfx.quit()
  end
end

main()
