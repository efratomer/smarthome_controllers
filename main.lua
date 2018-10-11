require "common"

mqttLog = 0
BUILTIN_LED = 4
LIGHT_THRESHOLD = 500
STATUS_CHANGE_DELAY = 500
STATUS_TOPIC = "/home/living_room/ac/console"
TARGET_HIT = 2

LightStatus = -1
gpio.mode(BUILTIN_LED, gpio.OUTPUT)
m = mqtt.Client("water_heater_control", 120)

function sendStatus(status)
    print(status)
    if mqttLog == 1 then
      m:publish(STATUS_TOPIC, status, MQTT_QOS_AT_LEAST_ONCE, MQTT_NO_RETAIN, function(client) end)
    end
end

function changeState(newState)
  if newState == 1 then
    m:publish("/home/living_room/ac", "ON", MQTT_QOS_AT_LEAST_ONCE, MQTT_RETAIN, function(client) print("sent on") end)
    param_set("status", "on")
    gpio.write(BUILTIN_LED, gpio.LOW)
  else
    m:publish("/home/living_room/ac", "OFF", MQTT_QOS_AT_LEAST_ONCE, MQTT_RETAIN, function(client) print("sent off") end)
    param_set("status", "off")
    gpio.write(BUILTIN_LED, gpio.HIGH)
  end
end

function sendData(hitCount)
  local ldr = adc.read(0) -- reads value from Analog Input (max 1V)
  sendStatus("ldr=" .. ldr .. ", hitCount=" .. hitCount)
  param_set("ldr", ldr)
  if ldr > LIGHT_THRESHOLD and LightStatus ~= 1 then  -- If sensor >500 detect status LED is on
        if hitCount < TARGET_HIT then
          tmr.delay(STATUS_CHANGE_DELAY)
          sendData(hitCount + 1)
          do return end
        end
        LightStatus = 1
        sendStatus("ldr=" .. ldr .. ", status=1")
        changeState(1)
  end
  if ldr < LIGHT_THRESHOLD and LightStatus ~= 0 then  -- If sensor >500 detect status LED changed from on to off
        if hitCount < TARGET_HIT then
          tmr.delay(STATUS_CHANGE_DELAY)
          sendData(hitCount + 1)
          do return end
        end
        LightStatus = 0
        sendStatus("ldr=" .. ldr .. ", status=0")
        changeState(0)
  end
end

function mqtt_on_message(client, topic, data)
    
end

function mqtt_on_connect(client)
    sendStatus("MQTT connected")
    m:subscribe("/home/living_room/ac/log", MQTT_QOS_AT_LEAST_ONCE)
    tmr.alarm(0, 1000, 1, function() sendData(0) end )
end

mqtt_connect(mqtt_on_connect, mqtt_on_message, "/home/living_room/ac")
