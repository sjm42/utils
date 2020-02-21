-- power.lua
-- This code is meant to be run in an esp8266/esp32 mcu
-- with NodeMCU firmware, and is controlling a power relay via CoAP.

pin_led = 4
pin_pwr = 1
gpio.mode(pin_led, gpio.OUTPUT)
gpio.mode(pin_pwr, gpio.OUTPUT)

cs = coap.Server()
cs:listen(5683)
pwr = false

function pwr_get(payload)
   if pwr then
      return "on"
   else
      return "off"
   end
end

function pwr_on(payload)
   print("power->on")
   pwr = true
   return "on"
end

function pwr_off(payload)
   print("power->off")
   pwr = false
   return "off"
end

function pwr_set(payload)
   -- remove all whitespace
   payload = string.gsub(payload , "%s", "")

   if payload == "on" then
      print("power->on")
      pwr = true
      return "on"
   elseif payload == "off" then
      print("power->off")
      pwr = false
      return "off"
   else
      print("error")
      return "error"
   end
end


cs:func("pwr_get")
cs:func("pwr_on")
cs:func("pwr_off")
cs:func("pwr_set")

tmr.alarm(5, 5000, tmr.ALARM_AUTO, function ()
    gpio.write(pin_led, pwr and gpio.HIGH or gpio.LOW)
    gpio.write(pin_pwr, pwr and gpio.HIGH or gpio.LOW)

    if pwr then
       print "pwr=on"
    else
       print "pwr=off"
    end

    -- for testing, blink
    -- pwr = not pwr
end)

-- EOF
