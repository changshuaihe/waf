local waf_monitor = ngx.shared.waf_monitor

--record nginx start timestamp for monitor
is_exist_starttime,err = waf_monitor:get("monitor.starttime")
if not is_exist_starttime then 
	waf_monitor:set("monitor.starttime", tostring(ngx.time()), 0)
end

--[[
is_exist_allcount, err = waf_conf:get("monitor.allcount")
if not is_exist_allcount then
	waf_conf:set("monitor.allcount", 0, 0)
end
--]]
