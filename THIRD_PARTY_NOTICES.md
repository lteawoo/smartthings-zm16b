# Sources and licenses

This small independent driver implements the public ZM16B datapoint mapping
from `Koenkk/zigbee-herdsman-converters` (`src/devices/zemismart.ts` and
`src/lib/tuya.ts`) and the Tuya wire layout from `Koenkk/zigbee-herdsman`.
The repositories are MIT-licensed. Upstream license copies are included under
`licenses/`.

The SmartThings EF00 message construction pattern was cross-checked against
`wonjj6768/smartthings-zigbee-edge-drivers` at commit
`dce5cc37e5e71b9961fedcc241da533f844697ac`, particularly
`source/src/tuya_common/message_protocol.lua`. Its MIT notice is preserved
under `licenses/wonjj6768-MIT.txt`. This is a separate project; no copy of the
large upstream driver framework is included.

SmartThings Edge SDK API v21 is used for validation and is not redistributed
with this source. The SmartThings SDK is Apache-2.0-licensed. The driver uses
its public message, capability, lifecycle, and device APIs.
