-- init.lua

-- load credentials, 'SSID' and 'PASSWORD' declared and initialized in there
dofile("credentials.lua")

function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")

        -- the actual application
        dofile("power.lua")
    end
end

print("Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, PASSWORD)
-- wifi.sta.connect() not necessary because config() uses auto-connect=true by default

tmr.create():alarm(1000, tmr.ALARM_AUTO, function(cb_timer)
    if wifi.sta.getip() == nil then
        print("Waiting for IP address...")
    else
        cb_timer:unregister()
        print("WiFi connection established, IP address: " .. wifi.sta.getip())
        print("You have 5 seconds to abort")
        print("Waiting...")
        tmr.create():alarm(5000, tmr.ALARM_SINGLE, startup)
    end
end)

-- EOF
