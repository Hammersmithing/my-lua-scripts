-- Select Next Track With MIDI
-- Jumps to the next track that contains at least one MIDI item (wrap-around).

local function track_has_midi(tr)
    local item_count = reaper.CountTrackMediaItems(tr)
    for i = 0, item_count - 1 do
        local item = reaper.GetTrackMediaItem(tr, i)
        if item then
            local take = reaper.GetMediaItemTake(item, 0)
            if take and reaper.TakeIsMIDI(take) then
                return true
            end
        end
    end
    return false
end

local function get_current_track_index()
    local num_tracks = reaper.CountTracks(0)
    for i = 0, num_tracks - 1 do
        local tr = reaper.GetTrack(0, i)
        if tr and reaper.IsTrackSelected(tr) then
            return i
        end
    end
    return -1
end

local num_tracks = reaper.CountTracks(0)
if num_tracks == 0 then return end

-- Build list of MIDI tracks
local midi_indices = {}
for i = 0, num_tracks - 1 do
    local tr = reaper.GetTrack(0, i)
    if tr and track_has_midi(tr) then
        midi_indices[#midi_indices+1] = i
    end
end

if #midi_indices == 0 then
    reaper.ShowMessageBox("No tracks with MIDI items found.", "Next MIDI Track", 0)
    return
end

local cur_index = get_current_track_index()

-- Find position in midi_indices
local pos = nil
for i, idx in ipairs(midi_indices) do
    if idx == cur_index then
        pos = i
        break
    end
end

-- Determine next position (wrap)
local next_pos
if not pos then
    next_pos = 1   -- if current track isn't a MIDI track, go to first MIDI track
else
    next_pos = pos + 1
    if next_pos > #midi_indices then next_pos = 1 end
end

local target_idx = midi_indices[next_pos]
local target_tr  = reaper.GetTrack(0, target_idx)
if not target_tr then return end

reaper.Undo_BeginBlock()
reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
reaper.SetTrackSelected(target_tr, true)
reaper.Main_OnCommand(40913, 0) -- Scroll selected into view
reaper.Undo_EndBlock("Select Next Track With MIDI", -1)

