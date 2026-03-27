local screen = {}

local function clip(line, maxW)
  if not maxW or #line <= maxW then
    return line
  end
  return string.sub(line, 1, math.max(3, maxW - 1)) .. "~"
end

function screen.render(termObj, state)
  local w = state.maxLineWidth
  local totals = state.energyTotals or {}
  termObj.write(clip(("Tot %d/%d"):format(totals.stored or 0, totals.capacity or 0), w) .. "\n")
  local shown = 0
  local limit = state.pageSize or 12
  for id, row in pairs(state.machineEnergy or {}) do
    shown = shown + 1
    local eta = row.etaSec and tostring(row.etaSec) .. "s" or "n/a"
    local line = state.ultraCompact
      and ("%s %d/%d u%s"):format(id, row.stored, row.capacity, eta)
      or ("- %s %d/%d usage:%d ETA:%s"):format(id, row.stored, row.capacity, row.usagePerSec or 0, eta)
    termObj.write(clip(line, w) .. "\n")
    if shown >= limit then
      termObj.write("...\n")
      break
    end
  end
  if shown == 0 then
    termObj.write("No energy devices.\n")
  end
end

return screen
