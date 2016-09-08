local ffi = require 'ffi'
local shdict = ngx.shared
local regx = ngx.re
local math = math
local _M = {
    _VERSION = '0.0.1'
}

local mt = {
    __index = _M
}

ffi.cdef[[
    struct in_addr {
        uint32_t s_addr;
    };

    int inet_aton(const char *cp, struct in_addr *inp);
    uint32_t ntohl(uint32_t netlong);

    char *inet_ntoa(struct in_addr in);
    uint32_t htonl(uint32_t hostlong);

    size_t strlen(const char *string);
    typedef struct iplocation {
        long start_ip;
        long end_ip;
        char country_code[7];
        char country_name[30];
        char province_code[2];
        char province_name[30];
        char city_name[30];
        char detail[100];
    } iplocation;
]]

local C = ffi.C

function ip2long(ip)
    local inp = ffi.new("struct in_addr[1]")
    if C.inet_aton(ip, inp) ~= 0 then
        return tonumber(C.ntohl(inp[0].s_addr))
    end
    return nil
end

function long2ip(long)
    if type(long) ~= "number" then
        return nil
    end
    local addr = ffi.new("struct in_addr")
    addr.s_addr = C.htonl(long)
    return ffi.string(C.inet_ntoa(addr))
end

local size = ffi.sizeof('iplocation')
local ptr_data = ffi.typeof('iplocation *')
local location_data = ffi.new('iplocation')

function _M.new(options)
    local options = options or {}
    options.path = options.path or 'lib/resty/location/ipdat.txt'
    options.dict = options.dict and shdict[options.dict] or shdict.ip_data
    return setmetatable(options, mt)
end

function _M.offset(self, start, last)
    local index = math.ceil(tonumber((start+last)/2))
    local data = self.dict:get('ip_data:'..index)
    if data then
        local location_data = ffi.cast(ptr_data, data)
        local ip_data = {}
        ip_data.start_ip = tonumber(location_data.start_ip)
        ip_data.end_ip = tonumber(location_data.end_ip)
        ip_data.country_code = tostring(ffi.string(location_data.country_code, tonumber(C.strlen(location_data.country_code))))
        ip_data.country_name = tostring(ffi.string(location_data.country_name, tonumber(C.strlen(location_data.country_name))))
        ip_data.province_code = tostring(ffi.string(location_data.province_code, ffi.sizeof('char[2]')))
        ip_data.province_name = tostring(ffi.string(location_data.province_name, tonumber(C.strlen(location_data.province_name))))
        ip_data.city_name = tostring(ffi.string(location_data.city_name, tonumber(C.strlen(location_data.city_name))))
        ip_data.detail = tostring(ffi.string(location_data.detail, tonumber(C.strlen(location_data.detail))))
        return ip_data,index
    end
end

function _M.search(self, ip)
    local start = 0
    local location_data
    local count = 0
    local last = self.dict:get('ip_data_last')
    if last == nil then
        self:reload()
        last = self.dict:get('ip_data_last')
    end
    last = last and tonumber(last) or 0
    if last < 1 then
        return nil, 'cannot find the last ip index data'
    end

    local data, index = self:offset(start, last)
    if data == nil then
        return nil, 'cannot query the data with the index '..index
    end
    while location_data == nil do
        location_data = data
        if ip >= data.start_ip and ip<= data.end_ip then
            break
        elseif ip < data.start_ip then
            last = index
        else
            start = index
        end
        data, index = self:offset(start, last)
        if data  == nil then
            break
        end
        count = count + 1
        location_data = nil
        if count > 200 then break end
    end
    if location_data then
        return location_data
    else
        return nil, 'can not find the data'
    end
end

function _M.loadfile(self)
    local path = self.path or 'lib/resty/location/ipdat.txt'
    local fd, err = io.open(path)
    if fd == nil then
        return nil, err
    end
    local data = {}
    local i = 0;
    for v in fd:lines() do
        local m, err = regx.match(v, '([0-9]+),([0-9]+),([A-Za-z]+),([^,]+),([^,]{0,2}),([^,]{0,30}),([^,]{0,30}),([^,]{0,100})')
        i = i+1
        if m then
            data[#data+1] = m
        end
    end
    fd:close()
    return data
end

function _M.reload(self)
    local data = self:loadfile()
    if #data == 0 then
        return nil, 'load file failed'
    end
    local res = false
    for i, v in pairs(data) do
        location_data.start_ip = tonumber(v[1])
        location_data.end_ip = tonumber(v[2])
        location_data.country_code = tostring(v[3])
        location_data.country_name = tostring(v[4])
        location_data.province_code = v[5] ~= nil and tostring(v[5]) or ''
        location_data.province_name = v[6] ~= nil and tostring(v[6]) or ''
        location_data.city_name = v[7] ~= nil and tostring(v[7]) or ''
        location_data.detail = v[8] ~= nil and tostring(v[8]) or ''
        local str = ffi.string(location_data, size)
        res = self.dict:set('ip_data:'..i, str)
    end
    self.dict:set('ip_data_last', #data)
    return res
end


function _M.location(self, ip)
    local ip = ip2long(ip)
    if ip == nil then
        return nil, 'Illegal ip address'
    end
    local tab = self:search(ip)
    if tab then
        return tab
    else
        return nil, 'cannot find the ip data'
    end
end

return _M