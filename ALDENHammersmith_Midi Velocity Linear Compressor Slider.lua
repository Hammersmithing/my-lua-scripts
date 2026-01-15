-- MIDI Velocity Compression Toward Min (Live)
-- Interactive slider that compresses selected MIDI note velocities
-- toward the lowest selected velocity in real-time.
--
-- Lowest selected velocity stays unchanged.
-- Other notes move linearly toward it based on slider (0-100%).
--
-- Esc = cancel and restore original velocities.
-- Closing the window = keep last state.

local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

local take = reaper.MIDIEditor_GetTake(editor)
if not take then return end

reaper.Undo_BeginBlock()
reaper.MIDI_DisableSort(take)

local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)

-- Collect selected notes and their original data
local notes = {}
local minVel = nil

for i = 0, noteCount - 1 do
    local ok, sel, mute, startppq, endppq, chan, pitch, vel =
        reaper.MIDI_GetNote(take, i)

    if ok and sel then
        notes[#notes+1] = {
            idx      = i,
            sel      = sel,
            mute     = mute,
            startppq = startppq,
            endppq   = endppq,
            chan     = chan,
            pitch    = pitch,
            vel_orig = vel
        }

        if not minVel or vel < minVel then
            minVel = vel
        end
    end
end

-- If no selected notes, bail
if #notes == 0 or not minVel then
    reaper.MIDI_Sort(take)
    reaper.Undo_EndBlock("MIDI Velocity Compression Toward Min (no notes)", -1)
    return
end

-- Apply compression with given amount (0.0 = none, 1.0 = flatten to min)
local function applyCompression(amount)
    for _, n in ipairs(notes) do
        local vel = n.vel_orig
        local delta = vel - minVel
        local new_vel = vel - (delta * amount)

        new_vel = math.floor(new_vel + 0.5)

        -- Clamp to 1–127
        if new_vel < 1 then new_vel = 1 end
        if new_vel > 127 then new_vel = 127 end

        reaper.MIDI_SetNote(
            take, n.idx,
            n.sel, n.mute,
            n.startppq, n.endppq,
            n.chan, n.pitch, new_vel,
            true -- noSort
        )
    end
end

-- GFX UI: simple horizontal slider 0–100%
gfx.init("MIDI Velocity Compression Toward Min (Live)", 360, 80)

local slider = 0.0      -- 0.0 to 1.0
local last_slider = -1
local dragging = false

local slider_x = 40
local slider_y = 40
local slider_w = 280
local slider_h = 10

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function loop()
    -- Handle close / Esc
    local ch = gfx.getchar()
    if ch == 27 then
        -- Esc: restore original velocities
        applyCompression(0.0)
        reaper.MIDI_Sort(take)
        reaper.Undo_EndBlock("MIDI Velocity Compression Toward Min (cancel)", -1)
        return
    elseif ch < 0 then
        -- Window closed: keep last applied state
        reaper.MIDI_Sort(take)
        reaper.Undo_EndBlock("MIDI Velocity Compression Toward Min (Live)", -1)
        return
    end

    -- Clear background
    gfx.set(0.1, 0.1, 0.1, 1)
    gfx.rect(0, 0, gfx.w, gfx.h, true)

    -- Label
    gfx.set(1, 1, 1, 1)
    gfx.x = 10
    gfx.y = 10
    gfx.printf("Compress toward lowest velocity (%.0f%%)", slider * 100)

    -- Draw slider track
    gfx.set(0.3, 0.3, 0.3, 1)
    gfx.rect(slider_x, slider_y, slider_w, slider_h, true)

    -- Draw slider fill
    gfx.set(0.7, 0.7, 0.7, 1)
    gfx.rect(slider_x, slider_y, slider_w * slider, slider_h, true)

    -- Draw handle
    local handle_x = slider_x + slider_w * slider - 4
    gfx.set(1, 1, 1, 1)
    gfx.rect(handle_x, slider_y - 4, 8, slider_h + 8, true)

    -- Mouse handling
    local mx, my = gfx.mouse_x, gfx.mouse_y
    local cap = gfx.mouse_cap
    local lmb = (cap & 1) == 1

    if lmb and not dragging then
        -- Start drag if click inside slider area
        if mx >= slider_x and mx <= slider_x + slider_w
           and my >= slider_y - 6 and my <= slider_y + slider_h + 6 then
            dragging = true
        end
    elseif not lmb then
        dragging = false
    end

    if dragging then
        slider = clamp((mx - slider_x) / slider_w, 0.0, 1.0)
    end

    -- Apply compression only when value changes
    if slider ~= last_slider then
        applyCompression(slider)
        last_slider = slider
    end

    gfx.update()
    reaper.defer(loop)
end

-- Initial apply (no compression) just to ensure a known state
applyCompression(slider)
loop()

