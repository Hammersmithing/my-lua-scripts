-- Move edit cursor backward by 1 measure (time-sig aware)
local proj = 0
local cur  = reaper.GetCursorPosition()
local qn   = reaper.TimeMap2_timeToQN(proj, cur)

-- get current time signature at 'cur'
local num, den = 4, 4
local cnt = reaper.CountTempoTimeSigMarkers(proj)
for i = 0, cnt-1 do
  local _, pos, _, _, _, ts_num, ts_den = reaper.GetTempoTimeSigMarker(proj, i)
  if pos and pos <= cur then
    if ts_num and ts_den then num, den = ts_num, ts_den end
  else
    break
  end
end

local qn_per_measure = num * (4/den)
local new_time = reaper.TimeMap2_QNToTime(proj, qn - qn_per_measure)
if new_time < 0 then new_time = 0 end

-- move view + seek playback
reaper.SetEditCurPos(new_time, true, true)

