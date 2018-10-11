-- MQTT --
MQTT_RETAIN = 1
MQTT_NO_RETAIN = 0
MQTT_QOS_AT_LEAST_ONCE = 1
MQTT_QOS_EXACLY_ONCE = 2

__mqtt_base_topic = ""
__mqtt_on_connected = nil
__mqtt_on_message = nil

function mqtt_connected(client)
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
                print(k,v)
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

function mqtt_connect(on_connected_callback, on_message_callback, base_topic)
    __mqtt_on_connected = on_connected_callback
    __mqtt_on_message = on_message_callback
    __mqtt_base_topic = base_topic
    
    m:connect("10.0.0.20", 1883, 0, mqtt_connected,
    function(client, reason)
        prnt("MQTT connection failed, reason: " .. reason)
        dofile("init.lua")
    end)
end

-- CONSISTENT PARAMETERS --
PARAM_FILENAME_PREFIX = ".data_"

function param_set(name, value)
    if value == nil or file == nil then do return end end

    if file.open(PARAM_FILENAME_PREFIX..name, "w") then
        file.writeline(tostring(value))
        --file.close() # Seems like causing crash for some reason
    else
        prnt("Error opening data_"..name)
    end
end

function param_get(name)
    local res
    
    if file.open(PARAM_FILENAME_PREFIX..name, "r") then
        res = file.readline()
        file.close()
    else
        prnt("Error opening data/"..name)
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