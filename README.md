# smarthome_controllers

## common.lua library
### Assumptions:
  * The following MQTT topics are reserved for internal use:
    * "<BASE_TOPIC>/param_set"
    * "<BASE_TOPIC>/reboot"
  * The following preserved data should exist before first use:
    * mqtt_ip - The MQTT broker IP
  
### Features:
  * Allow persistence mechanism to save parameters data.
  ```lua
  function param_get(name)
  function param_set(name, value)
  ```
  
  * Allow remotely changing persistence parameters data. Use an MQTT message with "<BASE_TOPIC>/param_set" as topic, data should be a JSON formatted data with parameters and their respective values. i.e: {"param1": "val1", "param2": "val2"}
  
  * Allow remotely rebooting device (for applying changes in persistence parameters data, for example).
