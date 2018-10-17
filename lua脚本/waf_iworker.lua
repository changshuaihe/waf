local redis = require("redis_iresty")
local cjson = require("cjson.safe")

local red = redis:new()

local delay = 1  -- repet to get config in 10 seconds, dict will be expired in 10s
local new_timer = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR
local ip_deny_list = ngx.shared.ip_deny_list
local ip_white_list = ngx.shared.ip_white_list
local waf_conf = ngx.shared.waf_conf

--redis list name and conf key name config
local redis_ip_white_list = "waf.ip_white_list"
local redis_ip_deny_list  = "waf.ip_deny_list"
local redis_deny_model    = "waf.conf.deny_model" --"0" for study,"1" for deny
local redis_rules   = "waf.rules_list"

local update_ip_white_list = function()
	--get redis list length
	local list_len, err = red:llen(redis_ip_white_list)
	if not list_len then
		log(ERR, err)
		return
	end
	--get all keys in list
	for i=0, list_len-1 do
		local white_ip, err = red:lindex(redis_ip_white_list, i)
		if not white_ip then
			log(ERR, err)
			return
		end
		succ, err = ip_white_list:set(white_ip, "", delay*5)
		if not succ then
			log(ERR, err)
		end
	end
end

local update_ip_deny_list = function()
	--get redis list length
	local list_len, err = red:llen(redis_ip_deny_list)
	if not list_len then
		log(ERR, err)
		return
	end
	--get all keys in list
	for i=0, list_len-1 do
		local deny_ip, err = red:lindex(redis_ip_deny_list, i)
		if not deny_ip then
			log(ERR, err)
			return
		end
		succ, err = ip_deny_list:set(deny_ip, "", delay*5)
		if not succ then
			log(ERR, err)
		end
	end
end

local update_deny_model = function()
	local model, err = red:get(redis_deny_model)
	if not model or (model ~= "0" and model~= "1") then
		log(ERR, err)
		model = "0"
	end
	local succ, err = waf_conf:set("deny_model", model, 0)
	if not succ then
		log(ERR, err)
	end
end

-- for get all rules
local function _json_decode(str)
  return cjson.decode(str)
end

function json_decode( str )
    local ok, t = pcall(_json_decode, str)
    if not ok then
      return nil
    end

    return t
end

local update_rules = function()
	local rules_row_list = red:get(redis_rules)
	local all_rules, err = json_decode(rules_row_list)
	if not all_rules or type(all_rules) ~= "table" then
		log(ERR, "all_rules json string format error, use cmd: \"get 'waf.rules_list'\" in redis to get the string|system err is:".. tostring(err))
		return
	end
	ok, err = waf_conf:set("rules", rules_row_list)
	if not ok then
		log(ERR, err)
	end
end
--end for get all rules

local update_config -- don`t new it with the main function. logic err >.<

update_config = function(premature)
	update_ip_white_list()
        update_ip_deny_list()
        update_deny_model()
	update_rules()

	if not premature then
    		local ok, err = new_timer(delay, update_config)
        	if not ok then
                     log(ERR, "failed to create timer: ", err)
                    return
                end
	end
end

if 0 == ngx.worker.id() then
	new_timer(delay, update_config)
end
