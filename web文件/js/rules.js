getruleslist = function(){
	$("#content").empty();
	$.ajax({
		url:"/api/getrules",
		type:"get",
		success:function(res){
			if(res.success == "false")
			{
				$("#content").html("<h2>获取数据错误："+res.msg+"</h2>");
				return false;
			}
			else
			{
				position = "<select class='ruleposition'><option>uri</option><option>cookie</option><option>ua</option><option>post</option></select>";
				html = "<button id='saverulesbtn' style='margin-bottom:10px;'>保存修改</button>";
				html += "<table class=\"table\"><thead><tr><th>id</th><th>名称</th><th>通配</th><th>检测位置</th><th>模式</th><th>备注</th><th>操作</th></tr></thead><tbody>";
				
				//添加默认空的规则
				html += "<tr class='rulerow' id='' data-name=''><td>0</td><td><input type='text' value='' class='rulename'></td><td><input type='text' value='' class='rulecontent'></td><td>"+position+"</td><td>"+getmodel("0")+"</td><td><input type='text' class='ruleremark' value=''></td><td><span>编辑该条为添加。不添加则留空</span></td></tr>";
				$.each(res.data, function(k,v){
					model = getmodel(v.model);
					if(typeof(v.remark)=="undefined")
					{
						v.remark="";
					}
					position_tmp = position.replace("<option>"+v.position, "<option selected='selected'>"+v.position);
					html += "<tr class='rulerow' id='"+v.name+"' data-name='"+v.name+"'><td>"+(k+1)+"</td><td><input type='text' value='"+v.name+"' class='rulename'></td><td><input type='text' value='"+v.content+"' class='rulecontent'></td><td>"+position_tmp+"</td><td>"+model+"</td><td><input type='text' class='ruleremark' value='"+v.remark+"'></td><td><button class='delrulebtn'>删除</button></td></tr>";
				});
				html += "</tbody></table>";
				$("#content").append(html);
			}
		}
	});
}

getmodel = function(model){
	model_html = "";
	if(typeof(model)=="undefined" || model != "1")
	{
		model_html = "<button class='rulemodel' data-model='0' style='background-color:green;color:#fff'>检测模式,点击换为阻拦模式</button>";
	} 
	else
	{
		model_html = "<button class='rulemodel' data-model='1' style='background-color:red;color:#fff'>阻拦模式,点击换为学习模式</button>";
	}
	return model_html;
}

saverules = function(){
	rulesArr = new Array();
	trs = $(".rulerow");
	if(typeof(trs)=="undefined" || trs.length <1)
	{
		alert("没有数据");
		return false;
	}
	$.each(trs, function(){
		tmpObj = new Object();
		tmpObj.remark = $(this).find(".ruleremark").val();
		tmpObj.name = $(this).find(".rulename").val();
		tmpObj.content = $(this).find(".rulecontent").val();
		tmpObj.model = $(this).find(".rulemodel").attr("data-model");
		tmpObj.position = $(this).find(".ruleposition option:selected").text();
		if(tmpObj.name != "")
		{
			rulesArr.push(tmpObj);
		}
		
	});
	$.ajax({
			type:"POST",
			url:"/api/setrules",
			data:"rules="+$.base64.btoa(JSON.stringify(rulesArr)),
			success:function(res){
				if(res.success != "true")
				{
					alert("保存失败："+res.msg);
				}
				else
				{
					alert("保存成功");
					getruleslist();
				}
			}
		})
}

delrule = function(obj){
	$(obj).parent().parent().remove();
}

changerulemodel = function(target){
	if($(target).attr("data-model") != "1")
	{
		newEle = getmodel("1");
	}
	else
	{
		newEle = getmodel("0");
	}
	$(target).replaceWith(newEle);
}