-- Tuya EF00 wire helpers. No SmartThings dependencies; see THIRD_PARTY_NOTICES.md.
local M = {
  CLUSTER = 0xEF00,
  WRITE_COMMAND = 0x00,
  QUERY_COMMAND = 0x03,
  VALUE = 0x02,
  ENUM = 0x04,
}

local function integer(value, minimum, maximum)
  return type(value) == "number" and value % 1 == 0
    and value >= minimum and value <= maximum
end

function M.encode(sequence, dp, datatype, value)
  assert(integer(sequence, 0, 0xFFFF), "invalid Tuya sequence")
  assert(integer(dp, 0, 0xFF), "invalid datapoint id")
  local bytes
  if datatype == M.ENUM then
    assert(integer(value, 0, 0xFF), "enum must be one byte")
    bytes = string.char(value)
  elseif datatype == M.VALUE then
    assert(integer(value, 0, 0xFFFFFFFF), "value must be uint32")
    bytes = string.pack(">I4", value)
  else
    error("unsupported write datatype")
  end
  -- Zigbee-herdsman defines the sequence as ZCL UINT16 (little endian).
  -- The Tuya DP header length and numeric DP value use big endian.
  return string.pack("<I2", sequence) .. string.char(dp, datatype)
    .. string.pack(">I2", #bytes) .. bytes
end

function M.decode(payload)
  if type(payload) ~= "string" or #payload < 2 then
    return nil, "missing Tuya sequence"
  end
  local sequence = string.unpack("<I2", payload)
  local items, cursor = {}, 3
  while cursor <= #payload do
    if #payload - cursor + 1 < 4 then
      return nil, "truncated datapoint header"
    end
    local dp, datatype = payload:byte(cursor, cursor + 1)
    local length = string.unpack(">I2", payload, cursor + 2)
    local first, last = cursor + 4, cursor + 3 + length
    if last > #payload then
      return nil, "truncated datapoint value"
    end
    local raw = payload:sub(first, last)
    local value
    if datatype == M.ENUM then
      if length ~= 1 then return nil, "enum length must be one" end
      value = raw:byte(1)
    elseif datatype == M.VALUE then
      if length ~= 4 then return nil, "value length must be four" end
      value = string.unpack(">I4", raw)
    end
    items[#items + 1] = {dp = dp, datatype = datatype, value = value, raw = raw}
    cursor = last + 1
  end
  -- Parsing is atomic: a malformed final DP rejects the entire packet.
  return {sequence = sequence, items = items}
end

return M
