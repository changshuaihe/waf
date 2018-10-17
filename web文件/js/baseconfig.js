baseconfig = function(){
	$("#content").empty();
	$.ajax({
		url:"/api/getdenymodel",
		type:"get",
		success:function(res){
			if(res.success != "true")
			{
				$("#content").html("<h2>获取数据错误："+res.msg+"</h2>");
				return false;
			}
			else
			{
				runmodel = "";
				if(res.data == "1")
				{
					runmodel = "<select id='runmodel'><option value='0'>检测模式</option><option selected='selected' value='1'>阻拦模式</option></select>";
				}
				if(res.data == "0")
				{
					runmodel = "<select id='runmodel'><option selected='selected' value='0'>检测模式</option><option value='1'>阻拦模式</option></select>";
				}
				if(res.data != "0" && res.data != "1")
				{
					runmodel = "获取结果失败,请检查服务器";
				}
				html = "<table class=\"table\"><tbody>";
				html += "<tr><td>运行模式:</td><td>"+runmodel+"</td><td><button id='saverunmodelbtn' style='margin-bottom:10px;'>保存修改</button></td></tr>";
				html += "</tbody></table>";
				$("#content").append(html);
			}
		}
	})
}

saverunmodel = function(){
	model = $("#runmodel option:selected").val();
	if(model != "1" && model != "0")
	{
		alert("值错了，检查下");
		return false;
	}
	$.ajax({
		url:"/api/setdenymodel?model="+model,
		type:"get",
		success:function(res){
			if(res.success != "true")
			{
				alert("更新失败:"+res.msg);
				return false;
			}
			else
			{
				alert("更新成功");
				baseconfig();
				return false;
			}
		}
	});
}