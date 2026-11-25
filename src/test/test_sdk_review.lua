-- Independent integration checks using the official SmartThings Edge SDK.
-- From src/: ST_LUA_LIBS=/path/to/lua_libs-api_v21 lua test/test_sdk_review.lua
-- This uses mocked SDK channels only. It never contacts a hub or account.
local sdk = os.getenv("ST_LUA_LIBS")
if sdk then package.path = sdk .. "/?.lua;" .. sdk .. "/?/init.lua;" .. package.path end

local test = require "integration_test"
local t_utils = require "integration_test.utils"
local zb_utils = require "integration_test.zigbee_test_utils"
local capabilities = require "st.capabilities"
local messages = require "st.zigbee.messages"
local zcl = require "st.zigbee.zcl"
local data_types = require "st.zigbee.data_types"
local generic_body = require "st.zigbee.generic_body"
local sdk_utils = require "st.utils"
local device

local function bytes(hex)
  return (hex:gsub("%x%x", function(pair) return string.char(tonumber(pair, 16)) end))
end

local function init_device(preferences, manufacturer)
  local profile = t_utils.get_profile_definition("zm16b-personal.yml")
  profile.id = "zm16b-test-profile-original"
  device = test.mock_device.build_test_zigbee_device({
    profile = profile,
    device_network_id = "1234",
    zigbee_endpoints = {
      [1] = {
        id = 1, profile_id = 0x0104,
        manufacturer = manufacturer or "_TZE284_3mzb0sdz", model = "TS0601",
        server_clusters = {0x0000, 0xEF00}, client_clusters = {0x000A, 0x0019},
      },
    },
  })
  rawget(device, "raw_st_data").preferences = preferences or {
    limitAction = "idle", motorDirectionAction = "keep",
  }
  test.mock_device.add_test_device(device)
end
test.set_test_init_function(function() init_device() end)

-- Independent golden wire bytes, deliberately not using protocol.encode.
local function expected_tx(command, hex)
  local header = zcl.ZclHeader({cmd = data_types.ZCLCommandId(command)})
  header.frame_ctrl:set_cluster_specific()
  header.frame_ctrl:set_disable_default_response()
  return messages.ZigbeeMessageTx({
    address_header = messages.AddressHeader(0, 1, 0x1234, 1, 0x0104, 0xEF00),
    body = zcl.ZclMessageBody({zcl_header = header, zcl_body = generic_body.GenericBody(bytes(hex))}),
  })
end

local function expect_write(hex)
  test.socket.zigbee:__expect_send({device.id, expected_tx(0, hex)})
end
local function expect_query()
  test.socket.zigbee:__expect_send({device.id, expected_tx(3, "")})
end
local function command(capability, name, args)
  -- The SDK socket receives positional args and converts them to named args.
  if args and args.shadeLevel ~= nil then args = {args.shadeLevel} end
  test.socket.capability:__queue_receive({device.id, {
    capability = capability, command = name, component = "main", args = args or {},
  }})
end
local function lifecycle(event)
  if event == "doConfigure" then
    device:expect_metadata_update({provisioning_state = "PROVISIONED"})
  end
  test.socket.device_lifecycle:__queue_receive({device.id, event})
end
local function preference(limit, direction)
  local event = device:generate_info_changed({preferences = {
    limitAction = limit, motorDirectionAction = direction or "keep",
  }})
  test.socket.device_lifecycle:__queue_receive(event)
  return event
end
local function report(hex)
  test.socket.zigbee:__queue_receive({device.id,
    zb_utils.build_custom_command_id(device, 0xEF00, 0x02, nil, bytes(hex))})
end
local function expect_level(value, state)
  test.socket.capability:__expect_send(device:generate_test_message("main",
    capabilities.windowShadeLevel.shadeLevel(value)))
  test.socket.capability:__expect_send(device:generate_test_message("main",
    capabilities.windowShade.windowShade(state)))
end

test.register_coroutine_test("SDK dispatch maps open/pause/close to DP1 enum 0/1/2", function()
  command("windowShade", "open"); expect_write("01000104000100")
  test.wait_for_events()
  command("windowShade", "pause"); expect_write("02000104000101")
  test.wait_for_events()
  command("windowShade", "close"); expect_write("03000104000102")
  test.wait_for_events()
end)

test.register_coroutine_test("DP9 percent target uses uint32 BE without inversion", function()
  for index, fixture in ipairs({{0,"00000000"},{37,"00000025"},{100,"00000064"}}) do
    command("windowShadeLevel", "setShadeLevel", {shadeLevel = fixture[1]})
    expect_write(string.format("%02X0009020004", index) .. fixture[2])
    test.wait_for_events()
  end
  -- Invalid arguments are rejected by the official SDK before dispatch;
  -- protocol/model tests separately cover the driver's own numeric guards.
end)

test.register_coroutine_test("configure, switch, refresh and restart never write DPs", function()
  lifecycle("doConfigure"); expect_query(); test.wait_for_events()
  lifecycle("driverSwitched"); expect_query(); test.wait_for_events()
  command("refresh", "refresh"); expect_query(); test.wait_for_events()
  lifecycle("init"); test.wait_for_events()
end)

test.register_coroutine_test("saved destructive preference is inert at startup and unrelated changes", function()
  test.wait_for_events()
  lifecycle("doConfigure"); expect_query(); test.wait_for_events()
  lifecycle("driverSwitched"); expect_query(); test.wait_for_events()
  test.socket.device_lifecycle:__queue_receive(device:generate_info_changed({label = "Renamed blind"}))
  test.wait_for_events()
  lifecycle("init"); test.wait_for_events()
end, {test_init = function()
  init_device({limitAction = "delete_both", motorDirectionAction = "reversed"})
end})

test.register_coroutine_test("only explicit changed preference sends one DP16; duplicates stay inert", function()
  local event = preference("set_up"); expect_write("01001004000100")
  test.wait_for_events()
  test.socket.device_lifecycle:__queue_receive(event)
  test.wait_for_events()
  preference("idle"); test.wait_for_events()
  preference("set_down"); expect_write("02001004000101")
  test.wait_for_events()
  preference("idle"); test.wait_for_events()
  preference("delete_up"); expect_write("03001004000102")
  test.wait_for_events()
  preference("delete_down"); expect_write("04001004000103")
  test.wait_for_events()
  preference("delete_both"); expect_write("05001004000104")
  test.wait_for_events()
end)

test.register_coroutine_test("missing old preference cannot execute action after profile setup", function()
  preference("set_up"); test.wait_for_events()
  preference("idle"); test.wait_for_events()
  preference("set_up"); expect_write("01001004000100")
  test.wait_for_events()
end, {test_init = function() init_device({}) end})

test.register_coroutine_test("motor direction writes DP11 and does not invert DP9", function()
  preference("idle", "reversed"); expect_write("01000B04000101")
  test.wait_for_events()
  command("windowShadeLevel", "setShadeLevel", {shadeLevel = 37})
  expect_write("02000902000400000025"); test.wait_for_events()
  preference("idle", "normal"); expect_write("03000B04000100")
  test.wait_for_events()
end)

test.register_coroutine_test("profile migration with a saved action cannot write DP16", function()
  local changed_profile = sdk_utils.deep_copy(rawget(device, "raw_st_data").profile)
  changed_profile.id = "zm16b-test-profile-migrated"
  test.socket.device_lifecycle:__queue_receive(device:generate_info_changed({
    profile = changed_profile,
    preferences = {limitAction = "set_up", motorDirectionAction = "keep"},
  }))
  test.wait_for_events()
  preference("idle"); test.wait_for_events()
  preference("set_up"); expect_write("01001004000100")
  test.wait_for_events()
end)

test.register_coroutine_test("multi-DP report emits actual position and battery only", function()
  report("341208020004000000250D0200040000006309040001011004000100")
  expect_level(37, "partially open")
  test.socket.capability:__expect_send(device:generate_test_message("main", capabilities.battery.battery(99)))
  test.wait_for_events()
  report("01000802000400000000"); expect_level(0, "closed"); test.wait_for_events()
  report("02000802000400000064"); expect_level(100, "open"); test.wait_for_events()
end)

test.register_coroutine_test("malformed or out-of-range reports cannot change actual position", function()
  for _, malformed in ipairs({
    "00", "000008", "000008020004000000",
    "0000080200040000002510", "000008020004000000250D02FFFF00",
    "00000802000125", "000008040000", "00000802000400000065",
    "000008040001250D020004000000FF", "0000010400010009020004000000641004000100",
  }) do
    report(malformed); test.wait_for_events()
  end
end)

test.register_coroutine_test("both exact ZM16B fingerprints support real SDK writes", function()
  command("windowShade", "open"); expect_write("01000104000100")
  test.wait_for_events()
end, {test_init = function() init_device(nil, "_TZE2841000000_3mzb0sdz") end})

test.register_coroutine_test("unsupported TS0601 fingerprint sends no command", function()
  command("windowShade", "open"); test.wait_for_events()
  command("refresh", "refresh"); test.wait_for_events()
  preference("delete_both"); test.wait_for_events()
end, {test_init = function() init_device(nil, "_TZE200_unrelated") end})

local result = test.run_registered_tests()
assert(result.failed == 0, string.format("%d SDK integration tests failed", result.failed))
