monitor = function(){
	$("#content").empty();
	
	html = "<table style='text-align:left' class=\"table\"><tbody>";
	startTime = "";
	serverTime = "";
	$.ajax({
		url:"/api/monitor",
		type:"get",
		async:false,
		success:function(res){
			if(res.data.nowtime*1 < 1)
			{
				serverTime = "nil";
			}
			if(res.data.starttime*1 < 1)
			{
				startTime = "nil";
			}

			if(serverTime != "nil" && startTime != "nil")
			{
				showTime = getLocalTime(res.data.starttime);
				toNowSecond = res.data.nowtime*1 - res.data.starttime*1;
				runningTime = formatSeconds(toNowSecond);
				startTime = showTime;
			}
			html += "<tr><td>nginx启动时间:  "+startTime+"</td><td>nginx运行时长:  "+runningTime+"</td></tr>";
			html += "<tr><td>服务器时间:  "+ getLocalTime(res.data.nowtime) + "</td><td></td></tr>";
			//追加剩余内存空间的html
			html += "<tr><td>共享内存空间：</td><td></td></tr>"
			i = 0;
			$.each(res.data.free_space, function(k, v){
				free = v.split("|")[0];
				all = v.split("|")[1];
				if(i%2 == 0)
				{
					html += "<tr>";
				}
				
				html += "<td>";
				html += k.split("|") + ": " + ((free/1024)/1024).toFixed(2) + "Mb / " + all + "Mb     已用：" + (((free/1024)/1024).toFixed(2) / all).toFixed(2) + "%";
				html += "</td>";
				if(i%2 != 0 || i == res.data.free_space.length-1)
				{
					html += "</tr>";
				}
				i++;
			});

		}
	});
	html += "</tbody></table>";
	$("#content").append(html);
	$("#content").append("<div id=\"monitor\"><div id=\"rules_count\" class=\"col-md-12\" style=\"height:300px;\"></div></div>");
	$("#content").append("<div id=\"monitor\"><div id=\"rules_count_m\" class=\"col-md-12\" style=\"height:300px;\"></div></div>");
	paint_count();
	paint_count_8h();
}

var all_rules_name = new Array();	//所有规则列表 全局变量

get_rules_name = function(){
	keys = new Array();
	$.ajax({
		url: "/api/getrules",
		type:"get",
		async:false,
		success:function(res){
			if(res.success == "true")
			{
				$.each(res.data, function(k,v){
					keys.push(v.name);
				})
			}
			else
			{
				keys = "null";
			}
		}
	});
	return keys;
}
update_count = function(){
	count_keys_h = new Array();	//48小时的统计，每小时一个key
	time_now = getTime();
	time_base = time_now - time_now%600;	//分钟key的基准

	for(i=0;i<48;i++)
	{
		count_keys_h.unshift(time_base - 3600*i);
	}
	all_count = get_all_count_hour(count_keys_h);
	j = 0;
	tmp = new Array();
	$.each(all_rules_name, function(k,v){
		tmp[k] = new Object();
		tmp[k].name = v;
		tmp[k].type = "line";
		tmp[k].smooth = true;
		tmp[k].data = new Array();
	});
	for(i=0;i<48;i++)
	{
		v = all_count[count_keys_h[i]];
		$.each(tmp, function(tk,tv){
			if(isNaN(tmp[tk].data[i]))
			{
				tmp[tk].data[i] = 0;
			}
			if(typeof(v[tv.name]) != "undefined" && v[tv.name] >= 0)
			{
				tmp[tk].data[i] += v[tv.name];
			}
			else
			{
				tmp[tk].data[i] += 0;
			}
		})
		
	}
	return tmp;
}

update_count8h = function(){
	count_keys_h = new Array();	//48小时的统计，每小时一个key
	time_now = getTime();
	time_base = time_now - time_now%600;	//分钟key的基准

	for(i=0;i<6*8;i++)
	{
		count_keys_h.unshift(time_base - 600*i);
	}
	all_count = get_all_count(count_keys_h);
	j = 0;
	tmp = new Array();
	$.each(all_rules_name, function(k,v){
		tmp[k] = new Object();
		tmp[k].name = v;
		tmp[k].type = "line";
		tmp[k].smooth = true;
		tmp[k].data = new Array();
	});


	for(i=0;i<48;i++)
	{
		v = all_count[count_keys_h[i]];
		$.each(tmp, function(tk,tv){
			if(isNaN(tmp[tk].data[i]))
			{
				tmp[tk].data[i] = 0;
			}
			if(typeof(v[tv.name]) != "undefined" && v[tv.name] >= 0)
			{
				tmp[tk].data[i] += v[tv.name];
			}
			else
			{
				tmp[tk].data[i] += 0;
			}
		})
		
	}
	return tmp;
}

get_all_count = function(keys){
	all_count_arr = new Array();

	$.each(keys, function(k,v){
		$.ajax({
			url:"/api/getcount?time=" + v,
			type:"get",
			async:false,
			success:function(res){
				all_count_arr[v] = res.data;
			}
		})
	});
	return all_count_arr;
}

get_all_count_hour = function(keys){
	all_count_arr = new Array();

	$.each(keys, function(k,v){
		$.ajax({
			url:"/api/gethourcount?time=" + v,
			type:"get",
			async:false,
			success:function(res){
				all_count_arr[v] = res.data;
			}
		})
	});
	return all_count_arr;
}

paint_count = function(){
	var dom = document.getElementById("rules_count");
	var myChart	//图表全局变量

	var myChart = echarts.init(dom);
	var app = {};
	option = null;
	app.title = '规则命中统计48h';

	option = {
	    title: {
	        text: 'waf规则命中统计48h',
	        subtext: ''
	    },
	    tooltip: {
	        trigger: 'axis'
	    },
	    legend: {
	    },
	    toolbox: {
	        show: true,
	        feature: {
	            magicType: {show: true, type: ['stack', 'tiled']},
	            saveAsImage: {show: true}
	        }
	    },
	    xAxis: {
	        type: 'category',
	        boundaryGap: false,
	        data: ['1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22'
	        		,'23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40','41','42'
	        		,'43','44','45','46','47','48']
	    },
	    yAxis: {
	        type: 'value'
	    },
	    series: []
	};
	if (option && typeof option === "object") {
	    myChart.setOption(option, true);
	};
	
	//获取规则列表
	all_rules_name = get_rules_name();

	if(all_rules_name == "null")
	{
		dom.innerHTML = "获取规则列表失败";
		return false;
	}
	else
	{
		myChart.hideLoading();
		option.legend.data = all_rules_name;
		datas = update_count();
		option.series = datas;
		myChart.setOption(option, true);
	}
};


paint_count_8h = function(){
	var dom2 = document.getElementById("rules_count_m");

	var myChart2 = echarts.init(dom2);
	var app2 = {};
	option = null;
	app2.title = '规则命中统计8h';

	option = {
	    title: {
	        text: 'waf规则命中统计8h',
	        subtext: ''
	    },
	    tooltip: {
	        trigger: 'axis'
	    },
	    legend: {
	        // data:['意向','预购','成交']
	    },
	    toolbox: {
	        show: true,
	        feature: {
	            magicType: {show: true, type: ['stack', 'tiled']},
	            saveAsImage: {show: true}
	        }
	    },
	    xAxis: {
	        type: 'category',
	        boundaryGap: false,
	        data: ['1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22'
	        		,'23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40','41','42'
	        		,'43','44','45','46','47','48']
	    },
	    yAxis: {
	        type: 'value'
	    },
	    series: []
	};
	if (option && typeof option === "object") {
	    myChart2.setOption(option, true);
	};
	
	if(all_rules_name == "null")
	{
		dom.innerHTML = "获取规则列表失败";
		return false;
	}
	else
	{
		myChart2.hideLoading();
		option.legend.data = all_rules_name;
		datas = update_count8h();
		option.series = datas;
		myChart2.setOption(option, true);
	}
};

getLocalTime = function(nS) {
	return new Date(parseInt(nS) * 1000).toLocaleString().replace(/:\d{1,2}$/,' ');  
}

getTime = function(){
  var tmp = Date.parse(new Date()).toString();
  tmp = tmp.substr(0,10);
  return tmp;
}

formatSeconds = function(value) { 
	var theTime = parseInt(value);// 秒 
	var theTime1 = 0;// 分 
	var theTime2 = 0;// 小时 
	// alert(theTime); 
	if(theTime > 60) { 
		theTime1 = parseInt(theTime/60); 
		theTime = parseInt(theTime%60); 
		// alert(theTime1+"-"+theTime); 
		if(theTime1 > 60) { 
			theTime2 = parseInt(theTime1/60); 
			theTime1 = parseInt(theTime1%60); 
		} 
	} 
	var result = ""+parseInt(theTime)+"秒"; 
	if(theTime1 > 0) { 
		result = ""+parseInt(theTime1)+"分"+result; 
	} 
	if(theTime2 > 0) { 
		result = ""+parseInt(theTime2)+"小时"+result; 
	} 
	return result; 
} 