# SmartThings Edge WLED Device Driver
This is a SmartThings Edge device driver implementation for devices that run WLED. The goal of this project is to create the driver that will allow you to add WLED devices that on your network to your SmartThings hub. The WLED light strip can then be used in your smart home just like any color smart bulb.

## Installation
This is currently very early in development and very non-functional. Because of the current state of this project, I am not making it available for installation yet. Once this project nears feature completion and stability, I will update this will installation instructions on how to get this installed on your SmartThings hub.

## Development Roadmap
- [x] Device discovery and addition to a hub
- [x] Device state refresh
- [x] Control of entire light strip on/off state
- [x] Control of entire light strip light level (dimmer)
- [x] Control of entire light strip color by specific color
- [x] Control of entire light strip color by white light temperature
- [x] Healthcheck support*
- [ ] Device state updates from device

\* *Healthcheck works and updates the online status of the device but the custom HTTP request timeout doesn't seem to be working. This means it'll take the default 60s instead of the intended 5s after the refresh command before marking the device as offline.*

Additional features will be considered in the future once these are complete. At this time, these are considered the essential capabilities of this device driver.

### Features under consideration
- Rediscovery when device IP address changes
- Presets
- Multiple segment handling