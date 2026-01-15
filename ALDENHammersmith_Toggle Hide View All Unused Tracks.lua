-- Toggle Hide Unused Tracks - Used Folders Small
-- First run ("hide mode"):
--   * Determine which tracks are "used":
--       - track has media items, OR
--       - track is a folder parent whose descendants have items
--   * Save per-track:
--       - B_SHOWINTCP, B_SHOWINMIXER, I_FOLDERCOMPACT
--   * Hide all unused tracks (TCP + Mixer)
--   * For used folder parents, set I_FOLDERCOMPACT = 1 (small view)
--
-- Second run ("restore mode"):
--   * Restore visibility + folder compact state for all tracks.

local proj        = 0
local SECTION     = "ToggleHideUnusedTracks_UsedFoldersSmall"
local KEY_ACTIVE  = "active"
local KEY_STATE   = "track_state"

-------------------------------------------------------
-- Check current toggle state
-------------------------------------------------------
local _, active_val = reaper.GetProjExtState(proj, SECTION, KEY_ACTIVE)
local is_active = (_ == 1 and active_val == "1")

-------------------------------------------------------
-- Save current state (vis + folder compact)
-------------------------------------------------------
local function save_state()
    local track_count = reaper.CountTracks(proj)
    local lines = {}

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(proj, i)
        if tr then
            local _, guid = reaper.GetSetMediaTrackInfo_String(tr, "GUID", "", false)
            local show_tcp   = reaper.GetMediaTrackInfo_Value(tr, "B_SHOWINTCP")
            local show_mixer = reaper.GetMediaTrackInfo_Value(tr, "B_SHOWINMIXER")
            local foldercmp  = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERCOMPACT")

            local line = string.format("%s|%d|%d|%d",
                guid or "",
                show_tcp or 0,
                show_mixer or 0,
                foldercmp or 0
            )
            lines[#lines+1] = line
        end
    end

    local state_str = table.concat(lines, "\n")
    reaper.SetProjExtState(proj, SECTION, KEY_STATE, state_str)
    reaper.SetProjExtState(proj, SECTION, KEY_ACTIVE, "1")
end

-------------------------------------------------------
-- Restore saved state
-------------------------------------------------------
local function restore_state()
    local ret, state_str = reaper.GetProjExtState(proj, SECTION, KEY_STATE)
    if ret ~= 1 or not state_str or state_str == "" then
        -- nothing saved; just clear flag
        reaper.SetProjExtState(proj, SECTION, KEY_ACTIVE, "0")
        return
    end

    local saved = {}
    for line in state_str:gmatch("[^\n]+") do
        local guid, stcp, smix, fcmp =
            line:match("^(.-)|(%-?%d+)|(%-?%d+)|(%-?%d+)$")
        if guid then
            saved[guid] = {
                show_tcp   = tonumber(stcp) or 0,
                show_mixer = tonumber(smix) or 0,
                foldercmp  = tonumber(fcmp) or 0
            }
        end
    end

    local track_count = reaper.CountTracks(proj)
    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(proj, i)
        if tr then
            local _, guid = reaper.GetSetMediaTrackInfo_String(tr, "GUID", "", false)
            local s = saved[guid]
            if s then
                reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP",   s.show_tcp)
                reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", s.show_mixer)
                reaper.SetMediaTrackInfo_Value(tr, "I_FOLDERCOMPACT", s.foldercmp)
            end
        end
    end

    reaper.SetProjExtState(proj, SECTION, KEY_ACTIVE, "0")
end

-------------------------------------------------------
-- Compute "used" tracks (self or children have items)
-------------------------------------------------------
local function compute_used_flags()
    local track_count = reaper.CountTracks(proj)
    local used = {}
    for i = 0, track_count - 1 do used[i] = false end

    -- We'll keep track of folder parents by depth
    local depth = 0
    local parent_at_depth = {}

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(proj, i)
        local td = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH") or 0

        -- If this track starts a folder, remember it at current depth
        if td > 0 then
            parent_at_depth[depth] = i
        end

        -- "Self used" if this track has any items
        local item_count = reaper.CountTrackMediaItems(tr)
        local self_used = (item_count > 0)

        if self_used then
            used[i] = true
            -- Mark all current parents as used-by-children
            for d = 0, depth - 1 do
                local p = parent_at_depth[d]
                if p ~= nil then
                    used[p] = true
                end
            end
        end

        depth = depth + td  -- td can be positive, zero, or negative
        if depth < 0 then depth = 0 end
    end

    return used
end

-------------------------------------------------------
-- Hide unused + set used folders small
-------------------------------------------------------
local function hide_unused_and_set_folders_small()
    local track_count = reaper.CountTracks(proj)
    if track_count == 0 then return end

    local used = compute_used_flags()

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(proj, i)
        local is_used = used[i]

        if not is_used then
            -- Unused: hide completely
            reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", 0)
            reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", 0)
        else
            -- Used: ensure visible
            reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", 1)
            reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", 1)

            -- If this is a folder parent, set small collapsed view
            local folder_depth = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH") or 0
            if folder_depth > 0 then
                reaper.SetMediaTrackInfo_Value(tr, "I_FOLDERCOMPACT", 1)  -- small
            end
        end
    end
end

-------------------------------------------------------
-- Main toggle
-------------------------------------------------------
reaper.Undo_BeginBlock()

if is_active then
    -- Restore full template
    restore_state()
else
    -- Save baseline and apply hide logic
    save_state()
    hide_unused_and_set_folders_small()
end

reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Toggle hide unused tracks (used folders small)", -1)

