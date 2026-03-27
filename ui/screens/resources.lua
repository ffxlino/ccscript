local screen = {}

local function clip(line, maxW)
  if not maxW or #line <= maxW then
    return line
  end
  return string.sub(line, 1, math.max(3, maxW - 1)) .. "~"
end

local function renderItems(termObj, items, page, pageSize, maxW)
  local sorted = {}
  for _, v in pairs(items or {}) do
    sorted[#sorted + 1] = v
  end
  table.sort(sorted, function(a, b) return (a.count or 0) > (b.count or 0) end)
  local startAt = (page - 1) * pageSize + 1
  local finishAt = math.min(#sorted, startAt + pageSize - 1)
  for i = startAt, finishAt do
    local it = sorted[i]
    termObj.write(clip(("- %s x%d"):format(it.name, it.count), maxW) .. "\n")
  end
  if #sorted == 0 then
    termObj.write("No item data.\n")
  end
end

local function renderFluids(termObj, fluids, page, pageSize, maxW)
  local sorted = {}
  for _, v in pairs(fluids or {}) do
    sorted[#sorted + 1] = v
  end
  table.sort(sorted, function(a, b) return (a.amount or 0) > (b.amount or 0) end)
  local startAt = (page - 1) * pageSize + 1
  local finishAt = math.min(#sorted, startAt + pageSize - 1)
  for i = startAt, finishAt do
    local it = sorted[i]
    termObj.write(clip(("- %s %du"):format(it.name, it.amount), maxW) .. "\n")
  end
  if #sorted == 0 then
    termObj.write("No fluid data.\n")
  end
end

function screen.render(termObj, state)
  local w = state.maxLineWidth
  local ultra = state.ultraCompact
  local itemPg = state.page or 1
  local fluidPg = state.page or 1
  if ultra then
    termObj.write(clip("I:items", w) .. "\n")
    renderItems(termObj, state.items, itemPg, state.pageSize or 4, w)
    termObj.write(clip("F:fluids", w) .. "\n")
    renderFluids(termObj, state.fluids, fluidPg, math.max(2, (state.pageSize or 4) - 2), w)
    return
  end
  termObj.write("Resources (items)\n")
  renderItems(termObj, state.items, itemPg, state.pageSize or 10, w)
  termObj.write("\nFluids\n")
  renderFluids(termObj, state.fluids, fluidPg, state.pageSize or 10, w)
end

return screen
