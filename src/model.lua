-- Device-specific mappings from the upstream Zigbee2MQTT ZM16B definition.
local M = {}

M.manufacturers = {
  ["_TZE284_3mzb0sdz"] = true,
  ["_TZE2841000000_3mzb0sdz"] = true,
}
M.motion = {open = 0, pause = 1, close = 2}
M.limit_actions = {
  idle = false,
  set_up = 0,
  set_down = 1,
  delete_up = 2,
  delete_down = 3,
  delete_both = 4,
}
M.direction_actions = {keep = false, normal = 0, reversed = 1}

function M.supported(manufacturer, model)
  return model == "TS0601" and M.manufacturers[manufacturer] == true
end

function M.percent(value)
  return type(value) == "number" and value % 1 == 0 and value >= 0 and value <= 100
end

function M.shade_state(percent)
  if percent == 0 then return "closed" end
  if percent == 100 then return "open" end
  return "partially open"
end

-- A preference action is allowed only for an observed old -> new change.
-- The in-memory baseline makes stale/replayed events harmless after init.
-- Missing old preferences (including a new profile's empty table) are never actions.
function M.changed_action(allowed, current, old, baseline)
  if current == nil or old == nil or baseline == nil then return nil end
  if allowed[current] == nil or allowed[old] == nil then return nil end
  if current == old or baseline ~= old then return nil end
  local value = allowed[current]
  if value == false then return nil end
  return value
end

return M
