-- temp.lua

t = require("ds18b20")
local cc = coap.Client()
local io_pins = {5, 6, 7}
local i, p, j, a, k

for i, p in ipairs(io_pins) do
   t.setup(p)
   local addrs = t.addrs()
   if (addrs ~= nil) then
      print('d'..p..' sensors: '..table.getn(addrs))
      for j, a in ipairs(addrs) do
         local t_C = string.format('%.2f', t.read(a, t.C))
         if t_C == '85.00' then
            print('Invalid temp, wait for next round')
         else
            local t_data = string.format('%02X%02X%02X%02X%02X%02X%02X%02X %s',
                                         a:byte(1), a:byte(2), a:byte(3), a:byte(4),
                                         a:byte(5), a:byte(6), a:byte(7), a:byte(8),
                                         t_C)
            print(t_data)
            cc:post(coap.NON, 'coap://coap.i.siu.ro/store_temp', t_data)
         end
      end
   end
end
print()

t = nil
ds18b20 = nil
package.loaded["ds18b20"]=nil

-- EOF
