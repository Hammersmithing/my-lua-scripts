-- Auto Record GUI
-- Select tracks from the first 16, then arm and record with one click

local track_selected = {}
local track_names = {}
local num_tracks = 0
local scroll_offset = 0
local btn_hover = false

-- Initialize track data
local function init_tracks()
  num_tracks = math.min(reaper.CountTracks(0), 16)
  for i = 1, 16 do
    track_selected[i] = false
    if i <= num_tracks then
      local track = reaper.GetTrack(0, i - 1)
      local _, name = reaper.GetTrackName(track)
      track_names[i] = string.format("%d: %s", i, name)
    else
      track_names[i] = string.format("%d: (no track)", i)
    end
  end
end

-- Unarm all tracks, arm selected, and record
local function do_auto_record()
  local total_tracks = reaper.CountTracks(0)

  -- Unarm all tracks
  for i = 0, total_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
  end

  -- Arm selected tracks
  for i = 1, math.min(num_tracks, 16) do
    if track_selected[i] then
      local track = reaper.GetTrack(0, i - 1)
      reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
    end
  end

  -- Start recording
  reaper.Main_OnCommand(1013, 0) -- Transport: Record
end

-- Draw checkbox
local function draw_checkbox(x, y, checked, label, index)
  local box_size = 16
  local mouse_x, mouse_y = gfx.mouse_x, gfx.mouse_y
  local is_hover = mouse_x >= x and mouse_x <= x + box_size and
                   mouse_y >= y and mouse_y <= y + box_size

  -- Checkbox background
  if checked then
    gfx.set(0.3, 0.6, 0.9, 1) -- Blue when checked
  else
    gfx.set(0.3, 0.3, 0.3, 1) -- Dark gray when unchecked
  end
  gfx.rect(x, y, box_size, box_size, 1)

  -- Checkbox border
  gfx.set(0.6, 0.6, 0.6, 1)
  gfx.rect(x, y, box_size, box_size, 0)

  -- Checkmark
  if checked then
    gfx.set(1, 1, 1, 1)
    gfx.line(x + 3, y + 8, x + 6, y + 12)
    gfx.line(x + 6, y + 12, x + 13, y + 4)
  end

  -- Label
  if index <= num_tracks then
    gfx.set(0.9, 0.9, 0.9, 1)
  else
    gfx.set(0.5, 0.5, 0.5, 1) -- Dimmed for non-existent tracks
  end
  gfx.x = x + box_size + 8
  gfx.y = y + 1
  gfx.drawstr(label)

  return is_hover
end

-- Draw button
local function draw_button(x, y, w, h, label)
  local mouse_x, mouse_y = gfx.mouse_x, gfx.mouse_y
  local is_hover = mouse_x >= x and mouse_x <= x + w and
                   mouse_y >= y and mouse_y <= y + h

  -- Button background
  if is_hover then
    gfx.set(0.8, 0.2, 0.2, 1) -- Red on hover
  else
    gfx.set(0.6, 0.15, 0.15, 1) -- Dark red
  end
  gfx.rect(x, y, w, h, 1)

  -- Button border
  gfx.set(0.9, 0.3, 0.3, 1)
  gfx.rect(x, y, w, h, 0)

  -- Button text
  gfx.set(1, 1, 1, 1)
  local str_w, str_h = gfx.measurestr(label)
  gfx.x = x + (w - str_w) / 2
  gfx.y = y + (h - str_h) / 2
  gfx.drawstr(label)

  return is_hover
end

-- Main draw function
local function draw()
  -- Background
  gfx.set(0.18, 0.18, 0.2, 1)
  gfx.rect(0, 0, gfx.w, gfx.h, 1)

  -- Title
  gfx.set(1, 1, 1, 1)
  gfx.setfont(1, "Arial", 18)
  gfx.x = 15
  gfx.y = 10
  gfx.drawstr("Auto Record - Select Tracks")

  -- Track list
  gfx.setfont(1, "Arial", 14)
  local start_y = 45
  local row_height = 24
  local checkbox_hovers = {}

  for i = 1, 16 do
    local y = start_y + (i - 1) * row_height
    local hover = draw_checkbox(15, y, track_selected[i], track_names[i], i)
    checkbox_hovers[i] = hover
  end

  -- Auto Record button
  local btn_y = start_y + 16 * row_height + 15
  btn_hover = draw_button(15, btn_y, gfx.w - 30, 40, "AUTO RECORD")

  -- Handle mouse clicks
  if gfx.mouse_cap & 1 == 1 then
    if not mouse_down then
      mouse_down = true

      -- Check checkbox clicks
      for i = 1, 16 do
        if checkbox_hovers[i] and i <= num_tracks then
          track_selected[i] = not track_selected[i]
        end
      end

      -- Check button click
      if btn_hover then
        -- Check if any tracks are selected
        local any_selected = false
        for i = 1, num_tracks do
          if track_selected[i] then
            any_selected = true
            break
          end
        end

        if any_selected then
          do_auto_record()
        else
          reaper.ShowMessageBox("Please select at least one track to arm.", "Auto Record", 0)
        end
      end
    end
  else
    mouse_down = false
  end
end

-- Main loop
local function main()
  draw()

  local char = gfx.getchar()
  if char >= 0 and char ~= 27 then -- 27 = ESC
    reaper.defer(main)
  else
    gfx.quit()
  end
end

-- Initialize
init_tracks()

-- Open window
gfx.init("Auto Record", 280, 480)
gfx.setfont(1, "Arial", 14)

main()
