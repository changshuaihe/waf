local alias = require("alias_config")
local _M = {}
local remote_addr = ngx.var.remote_addr
local waf_conf = ngx.shared.waf_conf
local waf_monitor = ngx.shared.waf_monitor
local log = ngx.log
local ERR = ngx.ERR
local eof = ngx.eof

_M.deny = function (reason, data, model)
    if not data then
        data = ""
    end
    if not reason then
        reason = ""
    end

    if not model then
        model = "1"
    end

    local deny_model, err = waf_conf:get("deny_model")
    if not deny_model then
        deny_model = "0"
        log(ERR, err)
    end
    
    log(ERR, "rule_model:"..model.." deny_model:"..deny_model.." forrben_ip:"..remote_addr.." reason:"..reason.." data:"..data)
    if deny_model == "1" then  --规则和全局模式都是1才阻拦
        if model == "1" then
        	ngx.say(alias.go_back)
		eof()
   	end
    end


--先返回，然后统计数量
    --所有拦截数量
    local time_now = ngx.time()
    local time_key = time_now - time_now%600
    local expire_time = 60*60*48	--统计时间
    local all_count_key = "monitor.count.allcount.".."."..tostring(time_key)

    local res, err =  waf_monitor:incr(all_count_key, 1)
    if not res and err == "not found" then
        waf_monitor:set(all_count_key, 1, expire_time)
    end
    --按规则统计数量
    local rule_count_key = "monitor.count."..reason.."."..tostring(time_key)

    local res, err =  waf_monitor:incr(rule_count_key, 1)
    if not res and err == "not found" then
        waf_monitor:set(rule_count_key, 1, expire_time)
    end
    if deny_model == "1" and model == "1" then
        ngx.exit('200') 
    end
end

return _M
