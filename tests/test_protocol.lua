local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. package.path
local protocol = require "protocol"
local model = require "model"
local checks = 0
local function equal(actual, expected, label)
  assert(actual == expected, (label or "value") .. ": expected "
    .. tostring(expected) .. ", got " .. tostring(actual))
  checks = checks + 1
end
local function hex(bytes)
  return (bytes:gsub(".", function(c) return string.format("%02X", c:byte()) end))
end

equal(hex(protocol.encode(0x1234, 16, protocol.ENUM, 0)), "34121004000100", "upper-limit frame")
equal(hex(protocol.encode(1, 16, protocol.ENUM, 4)), "01001004000104", "delete-both frame")
equal(hex(protocol.encode(2, 9, protocol.VALUE, 100)), "02000902000400000064", "target 100 frame")
equal(hex(protocol.encode(3, 1, protocol.ENUM, 1)), "03000104000101", "pause frame")
for name, value in pairs(model.limit_actions) do
  if value ~= false then
    equal(model.changed_action(model.limit_actions, name, "idle", "idle"), value, name)
  end
end
equal(model.changed_action(model.limit_actions, "set_up", "set_up", "set_up"), nil, "unchanged")
equal(model.changed_action(model.limit_actions, "set_up", nil, "idle"), nil, "missing old pref")
equal(model.changed_action(model.limit_actions, "set_up", "idle", "set_up"), nil, "stale after restart")
equal(model.changed_action(model.limit_actions, "idle", "set_up", "set_up"), nil, "idle is inert")
equal(model.changed_action(model.limit_actions, "bad", "idle", "idle"), nil, "invalid action")
equal(model.changed_action(model.limit_actions, "set_down", "set_up", "set_up"), 1, "changed action")
equal(model.changed_action(model.direction_actions, "normal", "keep", "keep"), 0, "direction enum zero")
equal(model.supported("_TZE284_3mzb0sdz", "TS0601"), true, "fingerprint 1")
equal(model.supported("_TZE2841000000_3mzb0sdz", "TS0601"), true, "fingerprint 2")
equal(model.supported("_TZE200_other", "TS0601"), false, "wrong TS0601")
equal(model.shade_state(100), "open", "100 is open")
equal(model.shade_state(0), "closed", "0 is closed")
equal(model.shade_state(40), "partially open", "middle position")
equal(model.percent(-1), false)
equal(model.percent(101), false)
equal(model.percent(12.5), false)
equal(model.percent(100), true)

local first = protocol.encode(0x1234, 8, protocol.VALUE, 75)
local second = protocol.encode(0, 13, protocol.VALUE, 83):sub(3)
local decoded = assert(protocol.decode(first .. second))
equal(decoded.sequence, 0x1234, "sequence LE")
equal(#decoded.items, 2, "multi-DP")
equal(decoded.items[1].dp, 8)
equal(decoded.items[1].value, 75)
equal(decoded.items[2].dp, 13)
equal(decoded.items[2].value, 83)
equal(protocol.decode(first .. second:sub(1, -2)), nil, "truncated final DP rejects entire packet")
equal(protocol.decode("\0"), nil, "short sequence")
equal(protocol.decode(first .. "\16"), nil, "truncated header")
equal(protocol.decode("\0\0\16\4\0\0"), nil, "zero-length enum")
equal(protocol.decode("\0\0\8\2\0\1\50"), nil, "short uint32")
local raw = assert(protocol.decode("\0\0\99\3\0\3abc"))
equal(raw.items[1].raw, "abc", "unknown/string DP preserved")
equal(raw.items[1].value, nil, "unknown type not coerced")
local ok = pcall(protocol.encode, 1, 16, protocol.ENUM, -1)
equal(ok, false, "invalid enum rejected")
print("PASS: " .. checks .. " protocol/model assertions")
