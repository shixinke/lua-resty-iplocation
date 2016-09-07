#lua-resty-iplocation

根据IP地址定位所在区域的工具函数(只需要一次载入IP地址库文件，将IP地址库数据存入共享内存)

#Overview

    lua_package_path '/the/path/to/your/project/lib/?.lua';
	lua_shared_dict ip_data 100m;

	server {
		location =/iplocation {
			default_type text/html;
			content_by_lua_block {
				local iplocation = require 'resty.iplocation.iplocation';
				local loc = iplocation:new({path = "/the/path/to/your/project/lib/iplocation/iplocation/ipdat.txt"});
                local  data = loc:location('202.108.22.5');
				--[[
                  {
					country_code = "CN",
                    country_name = "中国", 
                    province_code = "BJ", 
					province_name = "北京", 
					city_name = "北京", 
					start_ip = 3396075520, 
					end_ip = 3396141055, 
					detail = nil
                  }
                --]]
			}
		}
	}


#Methods

##new

用法:ok = iplocation:new({path = 'the/path/to/the/data/file', dict = 'shared dict name'})

功能：初始化iplocation模块

参数：是一个table，里面有两个元素
     
   path：数据文件所在路径

   dict:共享字典的名称(默认为ip_data，注：字典的大小建议为100m，因为文件存到内存中所占内存大约为70多M)

##offset

用法:ip_data,index = iplocation:offset(start, last)

功能：通过一个范围查找它的中位数以及它对应的IP数据

参数：
     
   start:起始点(数字型)

   last:终点(数字型)

注：不建议直接使用(模块内部使用)

##search

用法:data,err = iplocation:search(ip)

功能：通过二分法查找IP对应的地区数据

参数：ip为要查找的IP

##loadfile

用法：data, err = iplocation:loadfile()

功能：加载数据文件并返回数据

##reload

用法：ok, err = iplocation:reload()

功能：重新从数据文件中把数据加载到内存中(主要用于数据文件有更新时，同时更新数据到共享字典中)

##location

用法：tab, err = iplocation:location(ip)

功能：根据IP查找对应的地区定位数据

参数：ip：要查找的IP地址

返回数据说明：

如果查询成功，则得到一个table数据，其结构如下：

    {
        country_code = "CN",
        country_name = "中国",
        province_code = "BJ",
        province_name = "北京",
    	city_name = "北京",
    	start_ip = 3396075520,
    	end_ip = 3396141055,
    	detail = nil
     }

字段说明：

country_code：国家或地区英文简称编码

country_name：为国家名称(都是中文)

province_coe:省级行政区简称(目前数据中只有中国的省份）

province_name：省级行政区名称(不带行政区行政单位名称)

city_name:城市名称

start_ip:被查询的IP所在范围起始值

end_ip：被查询的IP所在范围终结值

detail:详细地址(目前大部分为空)
#TODO

目前首次加载数据文件到内存比较慢

查找算法的优化

#contact

由于是首次写lua开源库，请各位大神指点，也请各位同学反馈bug

E-mail:ishixinke@qq.com

website:[www.shixinke.com](http://www.shixinke.com "诗心客的博客")
