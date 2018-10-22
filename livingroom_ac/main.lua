require "common"

BUILTIN_LED = 4
LIGHT_THRESHOLD = 500
STATUS_CHANGE_DELAY = 500
TARGET_HIT = 2
MQTT_BASE_TOPIC = "/home/living_room/ac"
STATUS_TOPIC = MQTT_BASE_TOPIC.."/console"

LightStatus = -1
gpio.mode(BUILTIN_LED, gpio.OUTPUT)

function changeState(newState)
  if newState == 1 then
    m:publish(MQTT_BASE_TOPIC, "ON", MQTT_QOS_AT_LEAST_ONCE, MQTT_RETAIN, function(client) print("sent on") end)
    gpio.write(BUILTIN_LED, gpio.LOW)
  else
    m:publish(MQTT_BASE_TOPIC, "OFF", MQTT_QOS_AT_LEAST_ONCE, MQTT_RETAIN, function(client) print("sent off") end)
    gpio.write(BUILTIN_LED, gpio.HIGH)
  end
end

function sendData(hitCount)
  local ldr = adc.read(0) -- reads value from Analog Input (max 1V)

  param_set("ldr", ldr)
  if ldr > LIGHT_THRESHOLD and LightStatus ~= 1 then  -- If sensor >500 detect status LED is on
    if hitCount < TARGET_HIT then
      tmr.delay(STATUS_CHANGE_DELAY)
      sendData(hitCount + 1)
      do return end
    end
    LightStatus = 1
    changeState(1)
  end
  if ldr < LIGHT_THRESHOLD and LightStatus ~= 0 then  -- If sensor >500 detect status LED changed from on to off
    if hitCount < TARGET_HIT then
      tmr.delay(STATUS_CHANGE_DELAY)
      sendData(hitCount + 1)
      do return end
    end
    LightStatus = 0
    changeState(0)
  end
end

function mqtt_on_message(client, topic, data)
  -- No messages to handle for now
end

function mqtt_on_connect(client)
  print("MQTT connected")
  tmr.alarm(0, 1000, 1, function() sendData(0) end )
end

m = mqtt_connect("livingroom_ac_control", mqtt_on_connect, mqtt_on_message, MQTT_BASE_TOPIC)
