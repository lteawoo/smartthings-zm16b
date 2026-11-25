local capabilities = require "st.capabilities"
local messages = require "st.zigbee.messages"
local zcl = require "st.zigbee.zcl"
local constants = require "st.zigbee.constants"
local data_types = require "st.zigbee.data_types"
local generic_body = require "st.zigbee.generic_body"
local log = require "log"
local protocol = require "protocol"
local model = require "model"

local M = {}
local BASELINE = "zm16b.preference_baseline"
local SEQUENCE = "zm16b.sequence"

local function supported(device)
  if model.supported(device:get_manufacturer(), device:get_model()) then return true end
  log.warn("ZM16B: unsupported fingerprint; no command sent")
  return false
end

local function snapshot(device)
  local preferences = device.preferences or {}
  device:set_field(BASELINE, {
    limitAction = preferences.limitAction,
    motorDirectionAction = preferences.motorDirectionAction,
  })
end

local function send_raw(device, command, payload)
  if not supported(device) then return false end
  local endpoint = device:get_endpoint(protocol.CLUSTER)
  if type(endpoint) ~= "number" or endpoint < 1 or endpoint > 240 then
    log.warn("ZM16B: no valid Zigbee endpoint; no command sent")
    return false
  end
  local header = zcl.ZclHeader({cmd = data_types.ZCLCommandId(command)})
  header.frame_ctrl:set_cluster_specific()
  header.frame_ctrl:set_disable_default_response()
  local address = messages.AddressHeader(
    constants.HUB.ADDR, constants.HUB.ENDPOINT,
    device:get_short_address(), endpoint,
    constants.HA_PROFILE_ID, protocol.CLUSTER
  )
  device:send(messages.ZigbeeMessageTx({
    address_header = address,
    body = zcl.ZclMessageBody({
      zcl_header = header,
      zcl_body = generic_body.GenericBody(payload),
    }),
  }))
  return true
end

local function write_dp(device, dp, datatype, value)
  local sequence = ((device:get_field(SEQUENCE) or 0) + 1) % 0x10000
  device:set_field(SEQUENCE, sequence)
  return send_raw(device, protocol.WRITE_COMMAND, protocol.encode(sequence, dp, datatype, value))
end

function M.refresh(_, device)
  -- Read-only Tuya dataQuery, also used by Z2M for this model's battery query.
  send_raw(device, protocol.QUERY_COMMAND, "")
end

function M.init(_, device)
  -- Never execute saved preferences at boot, driver update, or device re-init.
  snapshot(device)
end

function M.configure(driver, device)
  M.refresh(driver, device)
end

function M.driver_switched(driver, device)
  snapshot(device)
  M.refresh(driver, device)
end

function M.info_changed(_, device, _, args)
  -- Old preferences are mandatory. infoChanged also occurs for names/profile edits.
  local old_store = args and args.old_st_store
  local old = old_store and old_store.preferences
  local baseline = device:get_field(BASELINE)
  local current = device.preferences or {}
  if type(old) ~= "table" or type(baseline) ~= "table" then
    snapshot(device)
    return
  end
  -- A profile migration is not a user request to execute a saved action.
  local previous_profile = old_store.profile
  if previous_profile and device.profile
      and previous_profile.id and device.profile.id
      and previous_profile.id ~= device.profile.id then
    snapshot(device)
    return
  end
  local limit = model.changed_action(model.limit_actions,
    current.limitAction, old.limitAction, baseline.limitAction)
  local direction = model.changed_action(model.direction_actions,
    current.motorDirectionAction, old.motorDirectionAction, baseline.motorDirectionAction)
  -- Adopt changes before sending, so a duplicated infoChanged cannot resend them.
  snapshot(device)
  if limit ~= nil then
    if write_dp(device, 16, protocol.ENUM, limit) then
      log.info("ZM16B: limit command SENT (" .. current.limitAction
        .. "). Motor confirmation is not available; verify physically.")
    end
  end
  if direction ~= nil then
    if write_dp(device, 11, protocol.ENUM, direction) then
      log.info("ZM16B: direction command SENT (" .. current.motorDirectionAction .. ")")
    end
  end
end

function M.open(_, device)
  write_dp(device, 1, protocol.ENUM, model.motion.open)
end

function M.close(_, device)
  write_dp(device, 1, protocol.ENUM, model.motion.close)
end

function M.pause(_, device)
  write_dp(device, 1, protocol.ENUM, model.motion.pause)
end

function M.set_level(_, device, command)
  local value = command and command.args and command.args.shadeLevel
  if not model.percent(value) then
    log.warn("ZM16B: invalid shade level; expected integer 0..100")
    return
  end
  -- This model uses 100=open, 0=closed, matching SmartThings directly.
  -- DP9 is a target/write; actual position is reported on DP8.
  write_dp(device, 9, protocol.VALUE, value)
end

function M.report(_, device, message)
  if not model.supported(device:get_manufacturer(), device:get_model()) then return end
  local body = message and message.body and message.body.zcl_body
  local packet, err = protocol.decode(body and body.body_bytes)
  if not packet then
    log.warn("ZM16B: ignored malformed Tuya report: " .. err)
    return
  end
  for _, item in ipairs(packet.items) do
    if item.dp == 8 and item.datatype == protocol.VALUE and model.percent(item.value) then
      device:emit_event(capabilities.windowShadeLevel.shadeLevel(item.value))
      device:emit_event(capabilities.windowShade.windowShade(model.shade_state(item.value)))
    elseif item.dp == 13 and item.datatype == protocol.VALUE and model.percent(item.value) then
      device:emit_event(capabilities.battery.battery(item.value))
    end
    -- A DP1/DP9 echo is not arrival, and DP16 echo is not verified calibration.
    -- Remote changes are retained in the motor; preferences are never replayed.
  end
end

return M
