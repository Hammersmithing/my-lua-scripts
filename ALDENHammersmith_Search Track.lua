-- Live Track Search - Tracks (Auto-Resize, Hover Highlight, Scrollbar, Blinking Caret)
-- Option B (macOS-safe): resizes by re-creating the gfx window when needed.
-- Final tweaks:
--  - Removes the top header text entirely.
--  - Placeholder lives inside the input box only.
--  - Footer shows ONLY "Matches: X".
--  - Click a result: select + scroll into view, then close.
--  - Record-arm remains disabled.

-------------------------------------------------------
-- Config
-------------------------------------------------------

local TITLE = "Live Track Search (List)"

local font_name = "Arial"
local font_size = 15

local WIN_W         = 520
local MIN_WIN_H     = 170
local MAX_WIN_H     = 720
local MAX_ROWS_SHOW = 18

local LIST_PAD_PX   = 12

-- Scrollbar visuals
local SB_W          = 14
local SB_ARROW_H    = 16
local SB_MIN_THUMB  = 18

-- Caret blink
local CARET_PERIOD_SEC = 1.0
local CARET_ON_SEC      = 0.5
local CARET_W_PX        = 2

-- Track enable behavior on click (record-arm disabled per request)
local ENABLE_UNMUTE   = true
local ENABLE_SHOW_TCP = true
local ENABLE_SHOW_MCP = true
local ENABLE_REC_ARM  = false

-- Placeholder
local PLACEHOLDER_TEXT = "Type to search..."

-------------------------------------------------------
-- UI layout constants (pixels)
-------------------------------------------------------

local pad       = 12
local gap1      = 10
local input_h   = 24
local gap2      = 12
local footer_h  = 32  -- only "Matches"

-------------------------------------------------------
-- State
-------------------------------------------------------

local query            = ""
local last_query       = ""
local matches          = {}   -- { {idx0=int, name=string}, ... }
local match_count      = 0
local list_scroll      = 0    -- 0-based index into matches

local last_lmb         = false
local last_wheel       = 0

local current_h        = MIN_WIN_H
local pending_reinit_h = nil
local exit_now         = false

-- Scrollbar drag
local sb_dragging      = false
local sb_drag_offset_y = 0

-------------------------------------------------------
-- Helpers
-------------------------------------------------------

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function point_in_rect(px, py, x, y, w, h)
  return px >= x and px <= (x + w) and py >= y and py <= (y + h)
end

local function get_track_name(tr)
  local _, name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
  if not name or name == "" then name = "(unnamed)" end
  return name
end

local function enable_track(tr)
  if not tr then return end
  if ENABLE_UNMUTE   then reaper.SetMediaTrackInfo_Value(tr, "B_MUTE", 0) end
  if ENABLE_SHOW_TCP then reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", 1) end
  if ENABLE_SHOW_MCP then reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", 1) end
  if ENABLE_REC_ARM  then reaper.SetMediaTrackInfo_Value(tr, "I_RECARM", 1) end
end

local function update_matches()
  matches     = {}
  match_count = 0
  list_scroll = 0

  local num_tracks = reaper.CountTracks(0)
  if num_tracks == 0 then return end

  local q = query:lower()
  if q == "" then return end

  for i = 0, num_tracks - 1 do
    local tr = reaper.GetTrack(0, i)
    if tr then
      local display_name = get_track_name(tr)
      local name_l = (display_name or ""):lower()
      if name_l:find(q, 1, true) then
        matches[#matches+1] = { idx0 = i, name = display_name }
      end
    end
  end

  match_count = #matches
end

local function trunc_to_width(s, max_w)
  if not s then return "" end
  if gfx.measurestr(s) <= max_w then return s end

  local ell = "..."
  local ell_w = gfx.measurestr(ell)
  if ell_w >= max_w then return ell end

  local lo, hi = 1, #s
  local best = ell
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    local cand = s:sub(1, mid) .. ell
    if gfx.measurestr(cand) <= max_w then
      best = cand
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  return best
end

-- Show tail so caret stays visible when long
local function fit_query_tail_to_width(s, max_w)
  s = s or ""
  if gfx.measurestr(s) <= max_w then return s end
  if #s == 0 then return "" end

  local lo, hi = 1, #s
  local best = s:sub(#s, #s)
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    local cand = s:sub(#s - mid + 1, #s)
    if gfx.measurestr(cand) <= max_w then
      best = cand
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  return best
end

local function caret_visible()
  local t = reaper.time_precise()
  local phase = t % CARET_PERIOD_SEC
  return phase < CARET_ON_SEC
end

local function jump_to_match(match_index_1based)
  if match_index_1based < 1 or match_index_1based > match_count then return end
  local idx0 = matches[match_index_1based].idx0
  local tr = reaper.GetTrack(0, idx0)
  if not tr then return end

  reaper.Undo_BeginBlock()
  reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
  reaper.SetTrackSelected(tr, true)
  enable_track(tr)
  reaper.TrackList_AdjustWindows(false)
  reaper.Main_OnCommand(40913, 0) -- Scroll selected track into view
  reaper.Undo_EndBlock("Live track search: select + jump", -1)
end

-------------------------------------------------------
-- Auto-size (Option B: re-create window)
-------------------------------------------------------

local function rows_to_show()
  if query == "" or match_count == 0 then return 1 end
  return math.min(match_count, MAX_ROWS_SHOW)
end

local function compute_desired_h(row_h)
  local input_y = pad
  local list_y  = input_y + input_h + gap2

  local rows = rows_to_show()
  local list_h = rows * row_h + LIST_PAD_PX

  local h = list_y + list_h + footer_h + pad
  return clamp(h, MIN_WIN_H, MAX_WIN_H)
end

local function request_resize_if_needed()
  gfx.setfont(1, font_name, font_size)
  local row_h = font_size + 8
  local desired_h = compute_desired_h(row_h)
  if desired_h ~= current_h then
    pending_reinit_h = desired_h
  end
end

local function do_pending_reinit_if_any()
  if not pending_reinit_h then return end
  current_h = pending_reinit_h
  pending_reinit_h = nil

  gfx.quit()
  gfx.init(TITLE, WIN_W, current_h)
  gfx.setfont(1, font_name, font_size)
  last_wheel = gfx.mouse_wheel
end

-------------------------------------------------------
-- Scrollbar geometry + mapping
-------------------------------------------------------

local function get_scrollbar_geom(list_x, list_y, list_w, list_h)
  local sb_x = list_x + list_w - SB_W
  local sb_y = list_y
  local sb_w = SB_W
  local sb_h = list_h

  local up_x, up_y, up_w, up_h = sb_x, sb_y, sb_w, SB_ARROW_H
  local dn_x, dn_y, dn_w, dn_h = sb_x, sb_y + sb_h - SB_ARROW_H, sb_w, SB_ARROW_H

  local track_x = sb_x
  local track_y = sb_y + SB_ARROW_H
  local track_w = sb_w
  local track_h = sb_h - 2 * SB_ARROW_H
  if track_h < 1 then track_h = 1 end

  return {
    sb_x=sb_x, sb_y=sb_y, sb_w=sb_w, sb_h=sb_h,
    up_x=up_x, up_y=up_y, up_w=up_w, up_h=up_h,
    dn_x=dn_x, dn_y=dn_y, dn_w=dn_w, dn_h=dn_h,
    track_x=track_x, track_y=track_y, track_w=track_w, track_h=track_h
  }
end

local function compute_thumb(geom, visible_rows)
  local max_scroll = math.max(0, match_count - visible_rows)

  if match_count <= 0 or max_scroll == 0 then
    return {
      thumb_x = geom.track_x + 1,
      thumb_y = geom.track_y + 1,
      thumb_w = geom.track_w - 2,
      thumb_h = math.max(1, geom.track_h - 2),
      max_scroll = 0
    }
  end

  local ratio = visible_rows / match_count
  local thumb_h = math.floor(geom.track_h * ratio)
  if thumb_h < SB_MIN_THUMB then thumb_h = SB_MIN_THUMB end
  if thumb_h > geom.track_h then thumb_h = geom.track_h end

  local travel = geom.track_h - thumb_h
  local t = list_scroll / max_scroll
  t = clamp(t, 0, 1)

  local thumb_y = geom.track_y + math.floor(travel * t)

  return {
    thumb_x = geom.track_x + 1,
    thumb_y = thumb_y,
    thumb_w = geom.track_w - 2,
    thumb_h = thumb_h,
    max_scroll = max_scroll
  }
end

-------------------------------------------------------
-- Main loop
-------------------------------------------------------

local function main_loop()
  do_pending_reinit_if_any()
  if exit_now then return end

  local ch = gfx.getchar()
  if ch == 27 or ch < 0 then return end

  -- typing
  if ch ~= 0 then
    if ch == 8 then
      if #query > 0 then query = query:sub(1, #query - 1) end
    elseif ch ~= 13 and ch ~= 10 then
      if ch >= 32 and ch <= 126 then
        query = query .. string.char(ch)
      end
    end
  end

  -- update on query change
  if query ~= last_query then
    update_matches()
    request_resize_if_needed()
    last_query = query
  end

  -- layout
  gfx.setfont(1, font_name, font_size)
  local row_h = font_size + 8

  local input_y = pad
  local input_x = pad
  local input_w = gfx.w - 2*pad

  local list_y  = input_y + input_h + gap2
  local list_x  = pad
  local list_w  = gfx.w - 2*pad
  local list_h  = gfx.h - (list_y + footer_h + pad)
  if list_h < (row_h + LIST_PAD_PX) then list_h = row_h + LIST_PAD_PX end

  local visible_rows = math.max(1, math.floor((list_h - LIST_PAD_PX) / row_h))

  local geom = get_scrollbar_geom(list_x, list_y, list_w, list_h)
  local thumb = compute_thumb(geom, visible_rows)

  local content_w = list_w - SB_W
  if content_w < 1 then content_w = 1 end

  -- clamp scroll
  if thumb.max_scroll > 0 then
    list_scroll = clamp(list_scroll, 0, thumb.max_scroll)
  else
    list_scroll = 0
  end

  -- mouse
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local cap = gfx.mouse_cap
  local lmb = (cap & 1) == 1
  local lmb_pressed = lmb and not last_lmb
  local lmb_released = (not lmb) and last_lmb
  last_lmb = lmb

  if lmb_released then sb_dragging = false end

  -- hover index (content only)
  local hover_index = 0
  if match_count > 0 and point_in_rect(mx, my, list_x, list_y, content_w, list_h) then
    local row = math.floor((my - list_y) / row_h) + 1
    local idx = list_scroll + row
    if idx >= 1 and idx <= match_count then hover_index = idx end
  end

  -- wheel scroll
  local wheel = gfx.mouse_wheel
  local wheel_delta = wheel - last_wheel
  last_wheel = wheel

  if thumb.max_scroll > 0 and wheel_delta ~= 0 then
    local steps = math.floor(wheel_delta / 120)
    if steps == 0 then steps = (wheel_delta > 0) and 1 or -1 end
    list_scroll = clamp(list_scroll - steps, 0, thumb.max_scroll)
  end

  -- scrollbar interactions
  if thumb.max_scroll > 0 then
    local over_up    = point_in_rect(mx, my, geom.up_x, geom.up_y, geom.up_w, geom.up_h)
    local over_dn    = point_in_rect(mx, my, geom.dn_x, geom.dn_y, geom.dn_w, geom.dn_h)
    local over_thumb = point_in_rect(mx, my, thumb.thumb_x, thumb.thumb_y, thumb.thumb_w, thumb.thumb_h)
    local over_track = point_in_rect(mx, my, geom.track_x, geom.track_y, geom.track_w, geom.track_h)

    if lmb_pressed then
      if over_up then
        list_scroll = clamp(list_scroll - 1, 0, thumb.max_scroll)
      elseif over_dn then
        list_scroll = clamp(list_scroll + 1, 0, thumb.max_scroll)
      elseif over_thumb then
        sb_dragging = true
        sb_drag_offset_y = my - thumb.thumb_y
      elseif over_track then
        if my < thumb.thumb_y then
          list_scroll = clamp(list_scroll - visible_rows, 0, thumb.max_scroll)
        elseif my > (thumb.thumb_y + thumb.thumb_h) then
          list_scroll = clamp(list_scroll + visible_rows, 0, thumb.max_scroll)
        end
      end
    end

    if lmb and sb_dragging then
      local travel = geom.track_h - thumb.thumb_h
      if travel < 1 then travel = 1 end

      local new_thumb_y = my - sb_drag_offset_y
      new_thumb_y = clamp(new_thumb_y, geom.track_y, geom.track_y + geom.track_h - thumb.thumb_h)

      local t = (new_thumb_y - geom.track_y) / travel
      local new_scroll = math.floor(t * thumb.max_scroll + 0.5)
      list_scroll = clamp(new_scroll, 0, thumb.max_scroll)
    end
  end

  -- click row: jump + close
  if lmb_pressed and hover_index > 0 then
    jump_to_match(hover_index)
    gfx.quit()
    exit_now = true
    return
  end

  ---------------------------------------------------
  -- draw
  ---------------------------------------------------

  gfx.set(0.08, 0.08, 0.08, 1)
  gfx.rect(0, 0, gfx.w, gfx.h, true)

  -- input box (with placeholder)
  gfx.set(0.25, 0.25, 0.25, 1)
  gfx.rect(input_x, input_y, input_w, input_h, true)

  local text_left_pad = 6
  local text_top_pad  = 4
  local max_text_w = input_w - (text_left_pad * 2) - CARET_W_PX - 2
  if max_text_w < 10 then max_text_w = 10 end

  local is_placeholder = (query == "")
  local shown_query = ""

  if is_placeholder then
    gfx.set(0.75, 0.75, 0.75, 1)
    gfx.x, gfx.y = input_x + text_left_pad, input_y + text_top_pad
    gfx.printf(PLACEHOLDER_TEXT)
  else
    gfx.set(1, 1, 1, 1)
    shown_query = fit_query_tail_to_width(query, max_text_w)
    gfx.x, gfx.y = input_x + text_left_pad, input_y + text_top_pad
    gfx.printf(shown_query)
  end

  -- caret
  if caret_visible() then
    local q_w = gfx.measurestr(shown_query)
    local cx = input_x + text_left_pad + q_w
    local cy = input_y + 4
    local chh = input_h - 8
    gfx.set(1, 1, 1, 1)
    gfx.rect(cx, cy, CARET_W_PX, chh, true)
  end

  -- list bg
  gfx.set(0.18, 0.18, 0.18, 1)
  gfx.rect(list_x, list_y, list_w, list_h, true)
  gfx.set(0.35, 0.35, 0.35, 1)
  gfx.rect(list_x, list_y, list_w, list_h, false)

  -- list content
  if query ~= "" and match_count > 0 then
    local text_x = list_x + 10
    local text_w = (list_w - SB_W) - 20
    if text_w < 10 then text_w = 10 end

    local start_i = list_scroll + 1
    local end_i = math.min(match_count, list_scroll + visible_rows)

    for i = start_i, end_i do
      local y = list_y + (i - start_i) * row_h

      if i == hover_index then
        gfx.set(0.30, 0.30, 0.30, 1)
        gfx.rect(list_x + 2, y + 1, (list_w - SB_W) - 4, row_h - 2, true)
      end

      local tr_idx0 = matches[i].idx0
      local label = string.format("%d: %s", tr_idx0 + 1, matches[i].name or "(unnamed)")
      label = trunc_to_width(label, text_w)

      gfx.set(1, 1, 1, 1)
      gfx.x, gfx.y = text_x, y + 4
      gfx.printf(label)
    end
  end

  -- scrollbar draw
  if match_count > visible_rows then
    local geom2 = get_scrollbar_geom(list_x, list_y, list_w, list_h)
    local thumb2 = compute_thumb(geom2, visible_rows)

    gfx.set(0.14, 0.14, 0.14, 1)
    gfx.rect(geom2.sb_x, geom2.sb_y, geom2.sb_w, geom2.sb_h, true)
    gfx.set(0.30, 0.30, 0.30, 1)
    gfx.rect(geom2.sb_x, geom2.sb_y, geom2.sb_w, geom2.sb_h, false)

    gfx.set(0.20, 0.20, 0.20, 1)
    gfx.rect(geom2.up_x, geom2.up_y, geom2.up_w, geom2.up_h, true)
    gfx.rect(geom2.dn_x, geom2.dn_y, geom2.dn_w, geom2.dn_h, true)

    gfx.set(1, 1, 1, 1)
    gfx.triangle(
      geom2.up_x + geom2.up_w/2, geom2.up_y + 4,
      geom2.up_x + 4,            geom2.up_y + geom2.up_h - 4,
      geom2.up_x + geom2.up_w - 4, geom2.up_y + geom2.up_h - 4
    )
    gfx.triangle(
      geom2.dn_x + 4,               geom2.dn_y + 4,
      geom2.dn_x + geom2.dn_w - 4,  geom2.dn_y + 4,
      geom2.dn_x + geom2.dn_w/2,    geom2.dn_y + geom2.dn_h - 4
    )

    gfx.set(0.16, 0.16, 0.16, 1)
    gfx.rect(geom2.track_x, geom2.track_y, geom2.track_w, geom2.track_h, true)

    gfx.set(0.35, 0.35, 0.35, 1)
    gfx.rect(thumb2.thumb_x, thumb2.thumb_y, thumb2.thumb_w, thumb2.thumb_h, true)
    gfx.set(0.55, 0.55, 0.55, 1)
    gfx.rect(thumb2.thumb_x, thumb2.thumb_y, thumb2.thumb_w, thumb2.thumb_h, false)
  end

  -- footer (ONLY Matches)
  local footer_y = list_y + list_h + 10
  gfx.set(1, 1, 1, 1)
  gfx.x, gfx.y = pad, footer_y
  gfx.printf("Matches: %d", match_count)

  gfx.update()
  reaper.defer(main_loop)
end

-------------------------------------------------------
-- Init
-------------------------------------------------------

gfx.init(TITLE, WIN_W, MIN_WIN_H)
gfx.setfont(1, font_name, font_size)
last_wheel = gfx.mouse_wheel

update_matches()
request_resize_if_needed()
do_pending_reinit_if_any()

main_loop()


