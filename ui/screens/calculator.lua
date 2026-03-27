local screen = {}

local function clip(line, maxW)
  if not maxW or #line <= maxW then
    return line
  end
  return string.sub(line, 1, math.max(3, maxW - 1)) .. "~"
end

function screen.render(termObj, state)
  termObj.write(state.ultraCompact and "Calc\n" or "Craft calculator\n")
  local deficits = state.plan and state.plan.deficits or {}
  local count = 0
  local w = state.maxLineWidth
  for itemId, row in pairs(deficits) do
    count = count + 1
    local line
    if state.ultraCompact then
      line = ("%s h%d n%d m%d"):format(itemId, row.have, row.required, row.missing)
    else
      line = ("- %s have:%d need:%d miss:%d"):format(itemId, row.have, row.required, row.missing)
    end
    termObj.write(clip(line, w) .. "\n")
    if state.ultraCompact and count >= (state.pageSize or 4) then
      termObj.write("...\n")
      break
    end
  end
  if count == 0 then
    termObj.write("No plan (add plannerTargets).\n")
  end
end

return screen
