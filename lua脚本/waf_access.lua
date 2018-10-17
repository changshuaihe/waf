local global_config = require("init_config")
local alias	    = require("alias_config")
local actions	    = require("actions")
local cjson	    = require("cjson")

local log = ngx.log
local ERR = ngx.ERR
local ngx_ctx = ngx.ctx
local ip_deny_list = ngx.shared.ip_deny_list
local ip_white_list = ngx.shared.ip_white_list
local remote_addr = ngx.var.remote_addr
local ngx_var = ngx.var
local ngx_ctx = ngx.ctx
local ngx_unescape_uri = ngx.unescape_uri
local waf_conf = ngx.shared.waf_conf


-- 规则
--[[
local sql_rules = {"when+.end+.","and+.sleep+","dbms_pipe","waitfor.+delay+","select.+(from|limit|sleep|end|concat)", "(?:(union(.*?)select))"}
local script_rules = {"eval(|file_get_contents|include|require|require_once|shell_exec|phpinfo|system|passthru|preg_\\w+|execute|echo|print|print_r|var_dump|(fp)open|(script+.*(alert|cookie)+)|showmodaldialog"}
local file_scan_rules = {"\\.(php|asp|aspx|pl)","\\.\\.+.etc+"}
local useragent_rules = {"libwww-perl|pythoni|httrack|harvest|audit|dirbuster|pangolin|nmap|sqln|-scan|hydra|Parser|libwww|BBBike|sqlmap|w3af|owasp|Nikto|fimap|havij|PycURL|zmeu|BabyKrokodil|netsparker|httperf|bench"}
--]]
--获取参数
local host = ngx_unescape_uri(ngx_var.http_host)
local ip = remoteIp
local method = ngx_var.request_method
local request_uri = ngx_unescape_uri(ngx_var.request_uri)
local uri = ngx_unescape_uri(ngx_var.uri)
local useragent = ngx_unescape_uri(ngx_var.http_user_agent)
-- local referer = ngx_unescape_uri(ngx_var.http_referer)
local cookie = ngx_unescape_uri(ngx_var.http_cookie)
-- local query_string = ngx_unescape_uri(ngx_var.query_string)
-- local headers = ngx.req.get_headers()
-- local headers_data = ngx_unescape_uri(ngx.req.raw_header(false))
-- local http_content_type = ngx_unescape_uri(ngx_var.http_content_type)

ngx.req.read_body()
local post = ngx.req.get_post_args()
local args = ngx.req.get_uri_args()

-- 黑白名单
is_pass = ip_white_list:get(remote_addr)
ngx_ctx.ip_type = ""
if is_pass ~= nil then
    ngx_ctx.ip_type = "white"
    return
end
is_deny = ip_deny_list:get(remote_addr)
if is_deny ~= nil then
    ngx_ctx.ip_type = "deny"
    actions.deny("deny_list", remote_addr)
end

--正则过滤器
local match = function(str, rule, rule_name, data, model)
    str = string.lower(str)		--一定要转小写，防止大小写绕过
    is_deny = ngx.re.match(str, rule, "jo")
    if is_deny then
    	actions.deny(rule_name, data, model)
    end
end

-- else, check all parm for sqlInject,script,file scan... and so on
--
-- GET 参数
local uri_match = function(rule_name, rule)
	if args then
		for k, v in pairs(args) do
			if type(v) == "table" then
				for kt, vt in pairs(v) do
					match(vt, rule.content, rule_name, vt, rule.model)
				end
			else
				match(v, rule.content, rule_name, v, rule.model)
			end
		end
	end
end

-- POST content
local post_match = function(rule_name, rule)
	if method == "POST" then
		if post then
		    for k, v in pairs(post) do
		        if type(v) == "table" then
		            for kt, vt in pairs(v) do
		                match(vt, rule.content, rule_name, kt..":"..vt, rule.model)
		            end
		        else
		            match(v, rule.content, rule_name, k..":"..v, rule.model)
		        end
		    end
	    end
	end
end

-- COOKIE
local cookie_match = function(rule_name, rule)
	if cookie and cookie ~= "" then
	    match(cookie, rule.content, rule_name, cookie, rule.model)
	end
end

--USER_AGENT
local ua_match = function(rule_name, rule)
	if useragent and useragent ~= "" then
	    match(useragent, rule.content, rule_name, useragent, rule.model)
	end
end

-- get all rules
local all_rules_str,err = waf_conf:get("rules")

if not all_rules_str then
	log(ERR, err)
end

if all_rules_str == "" then
	log(ERR, "get rules faild,nil get")
end

--begin match rules
local all_rules = cjson.decode(all_rules_str)
for k, v in pairs(all_rules) do
	if not v.model or (v.model ~= "0" and v.model ~= "1") then
		v.model = "0"	
	end
	if v.position == "uri" then
		uri_match(v.name, v)
	end
	if v.position == "ua" then
		ua_match(v.name, v)
	end
	if v.position == "post" then
		post_match(v.name, v)
	end
	if v.position == "cookie" then
		cookie_match(v.name, v)
	end
end


-- METHOD
if not method then
    actions.deny("null_method", "nil")
end
if string.lower(method) ~= "get" and string.lower(method) ~= "post" and string.lower(method) ~= "head" then
   actions.deny("error_method_head", method)
end

return
