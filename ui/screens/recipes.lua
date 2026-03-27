local screen = {}

local function clip(line, maxW)
  if not maxW or #line <= maxW then
    return line
  end
  return string.sub(line, 1, math.max(3, maxW - 1)) .. "~"
end

function screen.render(termObj, state)
  local w = state.maxLineWidth
  termObj.write("Recipes\n")
  local recipes = state.recipes or {}
  local shown = 0
  local limit = state.pageSize or 12
  for _, recipe in ipairs(recipes) do
    shown = shown + 1
    termObj.write(clip(("- %s [%s]"):format(recipe.recipeId, recipe.machineType), w) .. "\n")
    if shown >= limit then
      termObj.write("...\n")
      break
    end
  end
  if shown == 0 then
    termObj.write("No recipes loaded.\n")
  end
  if not state.ultraCompact then
    termObj.write("\nCLI:\n")
    termObj.write("recipe_cli.lua add|del\n")
  end
end

return screen
