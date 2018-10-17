require("resty.core.shdict")
local cjson = require("cjson")
local redis = require("redis_iresty")
local red = redis:new()

local say = ngx.say
local ip_deny_list = ngx.shared.ip_deny_list
local ip_white_list = ngx.shared.ip_white_list
local waf_conf = ngx.shared.waf_conf
local waf_monitor = ngx.shared.waf_monitor -- 统计数量

--redis list name config
local redis_deny_model    = "waf.conf.deny_model"
local redis_ip_white_list = "waf.ip_white_list"
local redis_ip_deny_list  = "waf.ip_deny_list"
local redis_deny_model    = "waf.conf.deny_model"
local redis_rules         = "waf.rules_list"

local ngx_var = ngx.var
local ngx_unescape_uri = ngx.unescape_uri
local args = ngx.req.get_uri_args()
local post = ngx.req.get_post_args()
local uri = ngx_unescape_uri(ngx_var.uri)

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

local set_rules = function()
	local res = {}
	if not post then
		res.msg = "post content err"
		res.success = "false"
		return res
	end
	local flag = false
	for k, v in pairs(post) do
		if k == "rules" and type(v) == "string" then
			v = ngx.decode_base64(v)
			local all_rules, err = json_decode(v)
			if not all_rules then
				res.success = "false"
				res.msg = "error json format"
				return res
			end
			flag = true
			local ok, err = red:set(redis_rules, v)
			if not ok then
				res.success = "false"
				res.msg = err
				return res
			else
				res.success = "true"
				res.msg = "success"
				return res
			end
		end
	end
	if flag == false then
		res.success = "false"
		res.msg = "err post content"
	end
	return res	
end
local get_rules = function()
	local res = {}
	local ok, err = red:get(redis_rules)
	if not ok then
		res.msg = err
		res.data = ""
		res.sucess = "false"
	else
		res.msg = "success"
		res.success = "true"
		res.data = cjson.decode(ok)
	end
	return res
end

local get_deny_model = function()
        local res = {}
        local ok, err = red:get(redis_deny_model)
	if not ok then
		res.msg = err
		res.success = "false"
		res.data = ""
	else
		res.msg = "success"
		res.success = "true"
		res.data = ok
	end
	
        return res
end

local set_deny_model = function()
        local res = {}
        if args == nil then
                res.msg = "model is null"
                res.success = "false"
                return res
        end
        local flag = false
        for k, v in pairs(args) do
                if k == "model" then
                        if v ~= nil or v ~= "" then
				if v ~= "0" and v ~= "1" then
					res.success = "false"
					res.msg = "error value,must be 0 or 1"
					return res
				end
				flag = true
                                local ok, err = red:set(redis_deny_model, v)
                                if not ok then
                                        res.success = "false"
                                        res.msg = err
                                else
                                        res.success = "true"
                                        res.msg = "success"
                                end

                        end
                end
        end
        if flag == false then
                res.success = "false"
                res.msg = "nil args"
        end
        return res
end

local add_deny_ip = function()
        local res = {}
        if args == nil then
                res.msg = "ip is null"
                res.success = "false"
                return res
        end
        local flag = false
        for k, v in pairs(args) do
                if k == "ip" then
                        if v ~= nil or v ~= "" then
				flag = true
                                local ok, err = red:rpush(redis_ip_deny_list, v)
                                if not ok then
                                        res.success = "false"
                                        res.msg = err
                                else
                                        res.success = "true"
                                        res.msg = "success"
                                end

                        end
                end
        end
        if flag == false then
                res.success = "false"
                res.msg = "nil args"
        end
        return res
end

local add_white_ip = function()
	local res = {}
	if args == nil then
                res.msg = "ip is null"
                res.success = "false"
                return res
        end
        local flag = false
        for k, v in pairs(args) do
                if k == "ip" then
			if v ~= nil or v ~= "" then
				local ok, err = red:rpush(redis_ip_white_list, v)
				flag = true
				if not ok then
                	                res.success = "false"
        	                        res.msg = err
	                        else
                        	        res.success = "true"
                                	res.msg = "success"
                        	end

			end
		end
	end
        if flag == false then
                res.success = "false"
                res.msg = "nil args"
        end
        return res
end

local del_white_ip = function()
	local res = {}
	if args == nil then
		res.msg = "ip is null"
		res.success = "false"
		return res
	end
	local flag = false
	for k, v in pairs(args) do
        	if k == "ip" then
			flag = true
			local ok, err = red:lrem(redis_ip_white_list, 0, v)
			if not ok then
				res.success = "false"
				res.msg = err
			else
				res.success = "true"
				res.msg = "success"
			end
		end
	end
	if flag == false then
                res.success = "false"
                res.msg = "nil args"
        end
	return res
end

local del_deny_ip = function()
        local res = {}
	if args == nil then
        	res.msg = "ip is null"
        	res.success = "false"
                return res
        end
	local flag = false
        for k, v in pairs(args) do
                if k == "ip" then
			flag = true
                        local ok, err = red:lrem(redis_ip_deny_list, 0, v)
                        if not ok then
                                res.success = "false"
                                res.msg = err
                        else
                                res.success = "true"
                                res.msg = "success"
                        end
                end
        end
	if flag == false then
		res.success = "false"
		res.msg = "nil args"
	end
	return res
end

local get_ip_white_list = function()
	local res = {}

	local list_len, err = red:llen(redis_ip_white_list)
	if not list_len then
		res.data = ""
		res.msg = err
		res.success = "false"
		return res
	end
	--get all keys in list
	res.data = {}
	for i=0, list_len-1 do
		local white_ip, err = red:lindex(redis_ip_white_list, i)
		if not white_ip then
			res.data = ""
			res.msg = err
			res.success = "false"
			return res
		end
		table.insert(res.data, white_ip)
	end
	res.success = "true"
	res.msg = "success"
	return res
end

local get_ip_deny_list = function()
	local res = {}

	local list_len, err = red:llen(redis_ip_deny_list)
	if not list_len then
		res.data = ""
		res.msg = err
		res.success = "false"
		return res
	end
	--get all keys in list
	res.data = {}
	for i=0, list_len-1 do
		local deny_ip, err = red:lindex(redis_ip_deny_list, i)
		if not deny_ip then
			res.data = ""
			res.msg = err
			res.success = "false"
			return res
		end
		table.insert(res.data, deny_ip)
	end
	res.success = "true"
	res.msg = "success"
	return res
end

local get_free_space = function()
	local res = {}
	res.ip_deny_list = ip_deny_list:free_space() .. "|" .. "50"
	res.ip_white_list = ip_white_list:free_space() .. "|" .. "50"
	res.waf_conf = waf_conf:free_space() .. "|" .. "50"
	res.waf_monitor = waf_monitor:free_space() .. "|" .. "50"
	return res
end

local get_monitor = function()
	local res = {}
	res.data = {}
	local start_time, err = waf_monitor:get("monitor.starttime")
	if not start_time then
		res.data.starttime = "0"
	else
		res.data.starttime = start_time
	end
	res.data.free_space = get_free_space()
	res.data.nowtime = tostring(ngx.time())
	res.success = "true"
	res.msg = "success"
	return res
end

local get_hour_count = function()
  	local res = {}
	res.data = {}
        if args == nil then
                res.msg = "args is null"
                res.success = "false"
                return res
        end
        local flag = false
        for k, v in pairs(args) do
            if k == "time" then
				timestamp = tonumber(v)
				if not timestamp then
					res.success = "false"
					res.msg = "error timestamp format"
					return res
				end
				--获取所有规则
				local get_rules = get_rules()
				if get_rules.success == "false" then
					return get_rules
				end
				--遍历一小时六次的规则名称，依次拼接key
				for i=0,5,1 do
					for rules_k, rules_v in pairs(get_rules.data) do
						rule_name = rules_v.name
						local rule_count_key = "monitor.count."..rule_name.."."..(v-i*600)
						local count = waf_monitor:get(rule_count_key)
						if count then
							if not res.data[rule_name] then
								res.data[rule_name] = 0
							end
							res.data[rule_name] = res.data[rule_name] + count
						end
					end
				end
				flag = true
            end
        end
	if flag == true then
		res.success = "true"
		res.msg = "success"
	else
		res.success = "false"
		res.msg = "false"
	end
	return res	
end

local get_count = function()
  	local res = {}
	res.data = {}
        if args == nil then
                res.msg = "args is null"
                res.success = "false"
                return res
        end
        local flag = false
        for k, v in pairs(args) do
                if k == "time" then
			timestamp = tonumber(v)
			if not timestamp then
				res.success = "false"
				res.msg = "error timestamp format"
				return res
			end
			--获取所有规则
			local get_rules = get_rules()
			if get_rules.success == "false" then
				return get_rules
			end
			--遍历规则名称，依次拼接key
			for rules_k, rules_v in pairs(get_rules.data) do
				rule_name = rules_v.name
				local rule_count_key = "monitor.count."..rule_name.."."..v
				local count = waf_monitor:get(rule_count_key)
				if count then
					res.data[rule_name] = count
				end
			end
			flag = true
                end
        end
	if flag == true then
		res.success = "true"
		res.msg = "success"
	else
		res.success = "false"
		res.msg = "false"
	end
	return res	
end

--router
--
local res

if uri == "/api/getipwhitelist" then
    res = get_ip_white_list()
end

if uri == "/api/getipdenylist" then
    res = get_ip_deny_list()
end

if uri == "/api/delwhiteip" then
    res = del_white_ip()
end

if uri == "/api/deldenyip" then
    res = del_deny_ip()
end

if uri == "/api/addwhiteip" then
    res = add_white_ip()
end

if uri == "/api/adddenyip" then
    res = add_deny_ip()
end

if uri == "/api/getdenymodel" then
    res = get_deny_model()
end

if uri == "/api/setdenymodel" then
    res = set_deny_model()
end

if uri == "/api/getrules" then
    res = get_rules()
end

if uri == "/api/setrules" then
    res = set_rules()
end

if uri == "/api/monitor" then
    res = get_monitor()
end

if uri == "/api/getcount" then
    res = get_count()
end

if uri == "/api/gethourcount" then
	res = get_hour_count()
end

ngx.say(cjson.encode(res))
