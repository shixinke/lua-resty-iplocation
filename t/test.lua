
local iplocation = require 'resty.iplocation.iplocation'

local options = {
    path = '/data/program/orapp/iplocation/lib/resty/iplocation/ipdat.txt'
}
local loc, err = iplocation:new(options)

if loc == nil then
    ngx.say(err)
else
    local res = loc:location('202.108.22.5')
    if res and type(res) == 'table' then
        for k, v in pairs(res) do
            ngx.say(k)
            ngx.say('=>')
            ngx.say(v)
            ngx.say('<br>')
        end
    end
    -- [[
    --detail =>
    --country_code => CNEIC
    --country_name => 中国
    --province_code => BJ
    --city_name => 北京
    --start_ip => 3396075520
    --province_name => 北京
    --end_ip => 3396141055
    -- ]]
end
