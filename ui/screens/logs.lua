local screen = {}

local function clip(line, maxW)
  if not maxW or #line <= maxW then
    return line
  end
  return string.sub(line, 1, math.max(3, maxW - 1)) .. "~"
end

function screen.render(termObj, state)
  termObj.write("Log\n")
  local messages = state.messages or {}
  local keep = state.ultraCompact and math.min(state.pageSize or 4, 6) or (state.pageSize or 15)
  local from = math.max(1, #messages - keep)
  local w = state.maxLineWidth
  for i = from, #messages do
    termObj.write(clip(("* %s"):format(messages[i]), w) .. "\n")
  end
  if #messages == 0 then
    termObj.write("No events.\n")
  end
end

return screen
