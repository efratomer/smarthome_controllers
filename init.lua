require "common"

wifi.setmode(wifi.STATION)
print('MAC: ',wifi.sta.getmac())
print('chip: ',node.chipid())
print('heap: ',node.heap())

wifi_ssid = param_get("wifi_ssid")
wifi_pass = param_get("wifi_pass")

if (wifi_ssid == nil or wifi_pass == nil) then
    print("WiFi credentials are missing... aborting")
    do return end
end

station_cfg = {}
station_cfg.ssid = wifi_ssid
station_cfg.pwd = wifi_pass
station_cfg.save = false
wifi.sta.config(station_cfg)

wifi.sta.connect()
tmr.alarm(1, 1000, 1, function()
    if wifi.sta.getip() == nil then
        print("IP unavaiable, Waiting...")
    else
        tmr.stop(1)
        print("ESP8266 mode is: " .. wifi.getmode())
        print("The module MAC address is: " .. wifi.ap.getmac())
        print("Config done, IP is " .. wifi.sta.getip())
        
        dofile("main.lua")
    end
end)