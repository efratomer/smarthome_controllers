# smarthome_controllers

## common.lua library
### Assumptions:
  * The following MQTT topics are reserved for internal use:
    * "<BASE_TOPIC>/param_set"
    * "<BASE_TOPIC>/reboot"
  * The following preserved data should exist before first use:
    * mqtt_ip - The MQTT broker IP
    * wifi_ssid - WiFi SSID to associate with
    * wifi_pass - WiFi Password

### Features:
  * Allow persistence mechanism to save parameters data.
  ```lua
  function param_get(name)
  function param_set(name, value)
  ```

  * Allow remotely changing persistence parameters data. Use an MQTT message with "<BASE_TOPIC>/param_set" as topic, data should be a JSON formatted data with parameters and their respective values. i.e: {"param1": "val1", "param2": "val2"}

  * Allow remotely rebooting device (for applying changes in persistence parameters data, for example).
  Use an MQTT message with "<BASE_TOPIC>/reboot" as topic, data is ignored.

### API:
  ```lua
  --- Get persistence parameter with name `name`
  function param_get(name)

  --- Set persistence parameter with name `name` to value `value`
  function param_set(name, value)

  -- Allows to register a new gpio by passing a unique `name`.
  -- `on_value_change` callback function will be called when
  -- the gpio value is altered.
  function gpio_register(name, on_value_change)

  -- Alters a registered gpio with the given `name` to the
  -- given `value`.
  function gpio_update(name, value)

  -- Returns value of a registered gpio with the given `name`.
  function gpio_get(name)

  -- Similar to gpio_update but only alters the value after
  -- `delay_time` of miliseconds have passed. Additional call to
  -- this API with the same name and before previous delay_time
  -- have passed will cancel the previous call.
  function gpio_delayUpdate(name, value, delay_time)
  ```