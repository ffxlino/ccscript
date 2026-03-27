local networkScreen = dofile("ui/screens/network.lua")
local resourcesScreen = dofile("ui/screens/resources.lua")
local recipesScreen = dofile("ui/screens/recipes.lua")
local calculatorScreen = dofile("ui/screens/calculator.lua")
local energyScreen = dofile("ui/screens/energy.lua")
local logsScreen = dofile("ui/screens/logs.lua")

local appUi = {}

local function chooseMonitorScale(monitor, minWidth, minHeight)
  local scales = { 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5 }
  local selected = 0.5
  for _, scale in ipairs(scales) do
    local okSet = pcall(monitor.setTextScale, scale)
    if okSet then
      local okSize, w, h = pcall(monitor.getSize)
      if okSize and w >= minWidth and h >= minHeight then
        selected = scale
      else
        break
      end
    end
  end
  pcall(monitor.setTextScale, selected)
  return selected
end

local function pickOutput(settings)
  local monitor = peripheral.find("monitor")
  if monitor then
    local minWidth = settings.uiMinWidth or 18
    local minHeight = settings.uiMinHeight or 6
    local scale = chooseMonitorScale(monitor, minWidth, minHeight)
    return monitor, true, scale
  end
  return term, false, 1
end

local function shortName(tabId)
  local map = {
    network = "NET",
    resources = "RES",
    recipes = "RCP",
    calculator = "CAL",
    energy = "PWR",
    logs = "LOG",
  }
  return map[tabId] or string.sub(string.upper(tabId), 1, 3)
end

local function drawLine(out, width, line)
  if #line > width then
    out.write(string.sub(line, 1, math.max(1, width - 1)) .. "~")
    return
  end
  out.write(line .. string.rep(" ", width - #line))
end

local function addRegion(list, x1, y1, x2, y2, action, arg)
  list[#list + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2, action = action, arg = arg }
end

local function hitTest(regions, x, y)
  for i = #regions, 1, -1 do
    local r = regions[i]
    if y >= r.y1 and y <= r.y2 and x >= r.x1 and x <= r.x2 then
      return r
    end
  end
  return nil
end

--- Micro layout: 2 строки хрома (вкладки 1-6 + панель < Pg TAB >), остальное — тело.
local function drawMicroChrome(self, out, uiState, width, height, regions)
  regions = regions or {}
  local chromeRows = 2
  if height < 2 then
    chromeRows = 1
  end
  local y1, y2 = 1, math.min(2, height)
  local bodyTop = math.min(chromeRows + 1, math.max(1, height))
  local bodyLines = math.max(1, height - chromeRows)

  out.setCursorPos(1, y1)
  local row1 = "123456"
  local pad = math.max(0, math.floor((width - #row1) / 2))
  local startX = pad + 1
  out.write(string.rep(" ", pad))
  for i = 1, #row1 do
    local ch = string.sub(row1, i, i)
    local x = startX + i - 1
    out.write(ch)
    addRegion(regions, x, y1, x, y1, "tab", i)
  end
  if startX + #row1 - 1 < width then
    out.write(string.rep(" ", width - (startX + #row1 - 1)))
  end

  if chromeRows >= 2 then
    local tabName = shortName(uiState.tabs[uiState.selectedTab] or "")
    local bar = string.format("< P%d %s >", uiState.page or 1, tabName)
    if #bar > width then
      bar = string.format("<P%d>", uiState.page or 1)
    end
    out.setCursorPos(1, y2)
    drawLine(out, width, bar)
    if string.sub(bar, 1, 1) == "<" then
      addRegion(regions, 1, y2, 1, y2, "page_prev", nil)
    end
    local gtCol = #bar
    if gtCol >= 1 and string.sub(bar, gtCol, gtCol) == ">" then
      addRegion(regions, gtCol, y2, gtCol, y2, "page_next", nil)
    end
  end

  return bodyTop, bodyLines, regions
end

--- Обычные вкладки (одна строка, обрезка по ширине — иначе CC переносит и «съедает» экран)
local function drawNormalChrome(self, out, uiState, width, height, compact, regions)
  local x = 1
  local y = 1
  out.setCursorPos(1, y)
  local hitboxes = {}
  local rowText = {}
  local function appendText(text, tabIndex)
    rowText[#rowText + 1] = { text = text, tabIndex = tabIndex }
  end

  appendText(compact and "T:" or "Tabs:")
  for i, tab in ipairs(uiState.tabs) do
    local label = compact and shortName(tab) or tab
    if i == uiState.selectedTab then
      appendText("[" .. label .. "]", i)
    else
      appendText(" " .. label .. " ", i)
    end
  end
  local flat = {}
  for _, seg in ipairs(rowText) do
    flat[#flat + 1] = seg.text
  end
  local full = table.concat(flat)
  if #full > width then
    full = string.sub(full, 1, math.max(1, width - 1)) .. "~"
    hitboxes = {}
    x = 1
    for _, seg in ipairs(rowText) do
      local t = seg.text
      if x + #t - 1 > width then
        break
      end
      if seg.tabIndex then
        hitboxes[#hitboxes + 1] = { index = seg.tabIndex, x1 = x, x2 = x + #t - 1, y = y }
      end
      x = x + #t
    end
  else
    x = 1
    for _, seg in ipairs(rowText) do
      if seg.tabIndex then
        hitboxes[#hitboxes + 1] = {
          index = seg.tabIndex,
          x1 = x,
          x2 = x + #seg.text - 1,
          y = y,
        }
      end
      x = x + #seg.text
    end
  end
  drawLine(out, width, full)
  out.write("\n")

  local helpY = 2
  out.setCursorPos(1, helpY)
  if compact then
    local tabName = shortName(uiState.tabs[uiState.selectedTab] or "")
    local bar = string.format("< P%d %s >", uiState.page or 1, tabName)
    if #bar > width then
      bar = string.format("<P%d>", uiState.page or 1)
    end
    drawLine(out, width, bar)
    if string.sub(bar, 1, 1) == "<" then
      addRegion(regions, 1, helpY, 1, helpY, "page_prev", nil)
    end
    local gtCol = #bar
    if gtCol >= 1 and string.sub(bar, gtCol, gtCol) == ">" then
      addRegion(regions, gtCol, helpY, gtCol, helpY, "page_next", nil)
    end
  else
    drawLine(out, width, ("Page:%d Keys:1-6 n/p [, .] left/right q"):format(uiState.page or 1))
  end

  for _, box in ipairs(hitboxes) do
    addRegion(regions, box.x1, box.y, box.x2, box.y, "tab", box.index)
  end

  return 3, math.max(1, height - 2)
end

function appUi.new(settings)
  local output, isMonitor, scale = pickOutput(settings)
  return setmetatable({
    out = output,
    isMonitor = isMonitor,
    scale = scale,
    settings = settings,
    uiRegions = {},
  }, { __index = appUi })
end

function appUi.render(self, uiState, viewModel)
  local out = self.out
  local width, height = out.getSize()

  local maxH = self.settings.uiUltraIfHeightLTE or 18
  local maxW = self.settings.uiUltraIfWidthLTE or 24
  local tabEst = 6
  for _, t in ipairs(uiState.tabs) do
    tabEst = tabEst + #t + 4
  end
  local ultra = self.settings.uiForceMicroLayout
    or (height <= maxH)
    or (width <= maxW)
    or (height < 3)
    or (tabEst > width)
  local compact = ultra or width < 42 or height < 16

  local regions = {}
  local bodyTop, bodyLines

  out.clear()
  if ultra then
    bodyTop, bodyLines = drawMicroChrome(self, out, uiState, width, height, regions)
  else
    bodyTop, bodyLines = drawNormalChrome(self, out, uiState, width, height, compact, regions)
  end

  local tab = uiState:currentTabName()
  local state = {
    devices = viewModel.devices,
    items = viewModel.items,
    fluids = viewModel.fluids,
    recipes = viewModel.recipes,
    plan = viewModel.plan,
    energyTotals = viewModel.energyTotals,
    machineEnergy = viewModel.machineEnergy,
    messages = uiState.messages,
    page = uiState.page,
    networkSummary = viewModel.networkSummary,
    pageSize = math.max(1, bodyLines - 2),
    compact = compact,
    ultraCompact = ultra,
    viewportWidth = width,
    viewportHeight = height,
    bodyTop = bodyTop,
    bodyLines = bodyLines,
    maxLineWidth = width,
  }

  out.setCursorPos(1, bodyTop)
  if tab == "network" then
    networkScreen.render(out, state)
  elseif tab == "resources" then
    resourcesScreen.render(out, state)
  elseif tab == "recipes" then
    recipesScreen.render(out, state)
  elseif tab == "calculator" then
    calculatorScreen.render(out, state)
  elseif tab == "energy" then
    energyScreen.render(out, state)
  elseif tab == "logs" then
    logsScreen.render(out, state)
  end

  self.uiRegions = regions
end

function appUi.handleEvent(self, uiState, event)
  local name = event[1]

  local function tabPrev()
    uiState.selectedTab = uiState.selectedTab - 1
    if uiState.selectedTab < 1 then
      uiState.selectedTab = #uiState.tabs
    end
    return true, nil
  end

  local function tabNext()
    uiState.selectedTab = (uiState.selectedTab % #uiState.tabs) + 1
    return true, nil
  end

  local function applyChar(ch)
    if ch >= "1" and ch <= "6" then
      uiState.selectedTab = tonumber(ch)
      return true, nil
    end
    if ch == "n" then
      uiState.page = uiState.page + 1
      return true, nil
    end
    if ch == "p" then
      uiState.page = math.max(1, uiState.page - 1)
      return true, nil
    end
    if ch == "," or ch == "[" then
      uiState.page = math.max(1, uiState.page - 1)
      return true, nil
    end
    if ch == "." or ch == "]" then
      uiState.page = uiState.page + 1
      return true, nil
    end
    if ch == "q" then
      return true, "quit"
    end
    return false, nil
  end

  if name == "key" then
    local key = event[2]
    if key >= keys.one and key <= keys.six then
      uiState.selectedTab = (key - keys.one) + 1
      return true, nil
    end
    if key == keys.n then
      uiState.page = uiState.page + 1
      return true, nil
    end
    if key == keys.p then
      uiState.page = math.max(1, uiState.page - 1)
      return true, nil
    end
    if key == keys.q then
      return true, "quit"
    end
    if key == keys.left then
      return tabPrev()
    end
    if key == keys.right then
      return tabNext()
    end
    if key == keys.comma then
      uiState.page = math.max(1, uiState.page - 1)
      return true, nil
    end
    if key == keys.period then
      uiState.page = uiState.page + 1
      return true, nil
    end
  elseif name == "char" then
    return applyChar(event[2])
  elseif name == "mouse_scroll" then
    local dir = event[2]
    if dir == 1 then
      uiState.page = uiState.page + 1
    else
      uiState.page = math.max(1, uiState.page - 1)
    end
    return true, nil
  elseif name == "monitor_touch" or name == "mouse_click" then
    local x, y = event[3], event[4]
    local r = hitTest(self.uiRegions or {}, x, y)
    if not r then
      return false, nil
    end
    if r.action == "tab" then
      uiState.selectedTab = r.arg
      return true, nil
    end
    if r.action == "page_prev" then
      uiState.page = math.max(1, uiState.page - 1)
      return true, nil
    end
    if r.action == "page_next" then
      uiState.page = uiState.page + 1
      return true, nil
    end
  end
  return false, nil
end

return appUi
