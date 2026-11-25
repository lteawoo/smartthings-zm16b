local ZigbeeDriver = require "st.zigbee"
local capabilities = require "st.capabilities"
local handlers = require "handlers"
local protocol = require "protocol"

local driver = ZigbeeDriver("zm16b-personal", {
  supported_capabilities = {
    capabilities.windowShade,
    capabilities.windowShadeLevel,
    capabilities.battery,
    capabilities.refresh,
  },
  capability_handlers = {
    [capabilities.windowShade.ID] = {
      [capabilities.windowShade.commands.open.NAME] = handlers.open,
      [capabilities.windowShade.commands.close.NAME] = handlers.close,
      [capabilities.windowShade.commands.pause.NAME] = handlers.pause,
    },
    [capabilities.windowShadeLevel.ID] = {
      [capabilities.windowShadeLevel.commands.setShadeLevel.NAME] = handlers.set_level,
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = handlers.refresh,
    },
  },
  lifecycle_handlers = {
    init = handlers.init,
    doConfigure = handlers.configure,
    driverSwitched = handlers.driver_switched,
    infoChanged = handlers.info_changed,
  },
  zigbee_handlers = {
    cluster = {
      [protocol.CLUSTER] = {
        [0x01] = handlers.report,
        [0x02] = handlers.report,
        [0x05] = handlers.report,
        [0x06] = handlers.report,
      },
    },
    zdo = {
      [0x0013] = handlers.refresh, -- Device_annce: query after the motor rejoins.
    },
  },
  health_check = false,
})

driver:run()
