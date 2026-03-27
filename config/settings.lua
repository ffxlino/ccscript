local settings = {
  scanIntervalSec = 2.0,
  uiRefreshSec = 0.25,
  snapshotIntervalSec = 5.0,
  transferOpsPerTick = 8,
  transferModes = {
    burst = { opsPerTick = 24 },
    balanced = { opsPerTick = 8 },
    safe = { opsPerTick = 2 },
  },
  defaultTransferMode = "balanced",
  recipesPath = "data/recipes.db.lua",
  networkSnapshotPath = "data/network_state.json",
  eventsLogPath = "logs/events.log",
  monitorPreferredScale = 0.5,
  -- Меньше значения — крупнее текст на маленьком мониторе (например 4×3 блока).
  uiMinWidth = 18,
  uiMinHeight = 6,
  -- Если высота/ширина в символах меньше порога — 2 строки хрома (micro).
  uiUltraIfHeightLTE = 18,
  uiUltraIfWidthLTE = 24,
  -- Физический монитор 4×3 часто даёт ОГРОМНУЮ сетку символов — пороги выше не срабатывают.
  -- Включите true для раскладки: строка 1 = «123456», строка 2 = «< P1 NET >».
  uiForceMicroLayout = true,
}

return settings
