DEBUG = false

-- MQTT --
MQTT_RETAIN = 1
MQTT_NO_RETAIN = 0
MQTT_QOS_AT_LEAST_ONCE = 1
MQTT_QOS_EXACLY_ONCE = 2

__mqtt_base_topic = ""
__mqtt_on_connected = nil
__mqtt_on_message = nil

function _mqtt_connected(client)
    m:on("offline", function(client)
        prnt("offline")
        dofile("init.lua")
    end)

    m:on("message", function(client, topic, data)
        local data_json
        prnt("mqtt topic RX: "..topic)

        if (topic == __mqtt_base_topic.."/param_set") then
            prnt("PARAM SET "..data)
            data_json = sjson.decode(data)
            for k,v in pairs(data_json) do
                param_set(k, v)
            end
        elseif (topic == __mqtt_base_topic.."/reboot") then
            prnt("/reboot recieved. Restarting")
            node.restart()
        else
            __mqtt_on_message(client, topic, data)
        end
    end)

    m:subscribe(__mqtt_base_topic.."/param_set", MQTT_QOS_EXACLY_ONCE)
    m:subscribe(__mqtt_base_topic.."/reboot", MQTT_QOS_EXACLY_ONCE)

    __mqtt_on_connected(client)
end

function mqtt_connect(client_name, on_connected_callback, on_message_callback, base_topic)
    local mqtt_ip = param_get("mqtt_ip")

    __mqtt_on_connected = on_connected_callback
    __mqtt_on_message = on_message_callback
    __mqtt_base_topic = base_topic

    if (mqtt_ip == nil) then
        print("MQTT ip is missing... aborting")
        do return end
    end

    m = mqtt.Client(client_name, 120)
    m:connect(mqtt_ip, 1883, 0, _mqtt_connected,
    function(client, reason)
        prnt("MQTT connection failed, reason: " .. reason)
        dofile("init.lua")
    end)

    return m
end

-- CONSISTENT PARAMETERS --
PARAM_FILENAME_PREFIX = ".data_"

function param_set(name, value)
    if value == nil or file == nil then do return end end

    if file.open(PARAM_FILENAME_PREFIX..name, "w") then
        file.writeline(tostring(value))
        --file.close() # Seems like causing crash for some reason
    else
        prnt("Error opening "..PARAM_FILENAME_PREFIX..name)
    end
end

function param_get(name)
    local res

    if file.open(PARAM_FILENAME_PREFIX..name, "r") then
        res = file.readline()
        file.close()
    else
        prnt("Error opening "..PARAM_FILENAME_PREFIX..name)
    end

    return res
end

-- LOGGING --
function prnt(text)
    print(text)
end

function prntd(text)
    if (DEBUG == true) then
        prnt(text)
    end
end

-- GPIOs --
_gpios_cb = {}
_gpios_timer = {}
_gpios_data = {}
_gpios_pending_data = {}
function gpio_register(name, on_value_change)
    if _gpios_cb[name] ~= nil then
        return nil
    end

    _gpios_cb[name] = on_value_change
    _gpios_timer[name] = tmr.create()
    return true
end

function gpio_update(name, value)
    if _gpios_cb[name] == nil then
        return nil
    end

    _gpios_data[name] = value
    _gpios_cb[name](value)
end

function gpio_get(name)
    return  _gpios_data[name]
end

--Updates value only if stayed unchanged at least delay_time(ms)
function gpio_delayUpdate(name, value, delay_time)
    if _gpios_cb[name] == nil or _gpios_pending_data[name] == value then
        return nil
    end

    _gpios_pending_data[name] = value

    if gpio_get(name) == value then
        tmr.stop(_gpios_timer[name])
        return nil
    end

    tmr.alarm(_gpios_timer[name], delay_time, tmr.ALARM_SINGLE, function()
        gpio_update(name, value)
    end)
end