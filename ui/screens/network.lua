local screen = {}

local function clip(line, maxW)
  if not maxW or #line <= maxW then
    return line
  end
  return string.sub(line, 1, math.max(3, maxW - 1)) .. "~"
end

function screen.render(termObj, state)
  local net = state.networkSummary or {}
  local w = state.maxLineWidth
  termObj.write(clip(("Net C:%d T:%d M:%d Md:%d/%d"):format(
    net.computers or 0, net.turtles or 0, net.monitors or 0, net.wiredModems or 0, net.wirelessModems or 0
  ), w) .. "\n")
  if not state.ultraCompact then
    termObj.write("Connected devices:\n")
  end
  local count = 0
  local limit = state.pageSize or 12
  for id, dev in pairs(state.devices or {}) do
    count = count + 1
    if count > limit then
      termObj.write("...\n")
      break
    end
    local caps = dev.capabilities or {}
    local flags = {}
    if caps.inventory then flags[#flags + 1] = "INV" end
    if caps.fluids then flags[#flags + 1] = "FLD" end
    if caps.energy then flags[#flags + 1] = "ENG" end
    if caps.modem then flags[#flags + 1] = "NET" end
    if caps.monitor then flags[#flags + 1] = "MON" end
    local class = dev.class and ("{" .. dev.class .. "}") or ""
    termObj.write(clip(("- %s [%s]%s %s"):format(id, dev.type, class, table.concat(flags, ",")), w) .. "\n")
  end
  if count == 0 then
    termObj.write("No peripherals found.\n")
  end
end

return screen
