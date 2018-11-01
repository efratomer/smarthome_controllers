require "common"

BUILTIN_LED = 4
LIGHT_THRESHOLD = 500
MQTT_BASE_TOPIC = "/home/living_room/ac"
STATUS_TOPIC = MQTT_BASE_TOPIC.."/console"
update_delay = 0

gpio.mode(BUILTIN_LED, gpio.OUTPUT)

function sendData()
  local ldr = adc.read(0) -- reads value from Analog Input (max 1V)

  print("ldr="..ldr)
  if ldr > LIGHT_THRESHOLD then  -- If sensor >500 detect status LED is on
    gpio_delayUpdate("ldr_value", "on", update_delay)
  end
  if ldr < LIGHT_THRESHOLD then  -- If sensor >500 detect status LED changed from on to off
    gpio_delayUpdate("ldr_value", "off", update_delay)
  end
end

function mqtt_on_message(client, topic, data)
  -- No messages to handle for now
end

function on_state_change(new_state)
  print("state changed: "..new_state)

  if newState == "on" then
    m:publish(MQTT_BASE_TOPIC, "ON", MQTT_QOS_AT_LEAST_ONCE, MQTT_RETAIN, function(client) print("sent on") end)
    gpio.write(BUILTIN_LED, gpio.LOW)
  else
    m:publish(MQTT_BASE_TOPIC, "OFF", MQTT_QOS_AT_LEAST_ONCE, MQTT_RETAIN, function(client) print("sent off") end)
    gpio.write(BUILTIN_LED, gpio.HIGH)
  end
end

function mqtt_on_connect(client)
  print("MQTT connected")
  tmr.alarm(0, 1000, 1, function() sendData() end )
  gpio_register("ldr_value", on_state_change)
  update_delay = param_get("update_delay")
end

m = mqtt_connect("livingroom_ac_control", mqtt_on_connect, mqtt_on_message, MQTT_BASE_TOPIC)
