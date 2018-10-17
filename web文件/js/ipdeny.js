ipdeny = function(){
	$("#content").empty();
	$.ajax({
		url:"/api/getipdenylist",
		type:"get",
		success:function(res){
			if(res.success == "true")
			{
				html = "<table class=\"table\"><thead><tr><th>id</th><th>IP</th><th>操作</th></tr></thead><tbody>";
				html += "<tr><td>0</td><td><input type='text' id='adddenyip'></td><td><button id='adddenyipbtn'>添加</button></td></tr>";
				$.each(res.data, function(k,v){
					html += "<tr class='iplist'><td>"+(k+1)+"</td><td>"+v+"</td><td><button  data-ip=\""+v+"\" class='deldenyipbtn' id=\"del_"+v+"\">删除</button></td></tr>";
				});
				
				html += "</tbody></table>";
				$("#content").append(html);
			}
			else
			{
				$("#content").html("<h2>获取数据错误："+res.msg+"</h2>");
			}

		}
	});
}

delipdeny = function(ip){
	istrue = confirm("确认要删除？");
	if(istrue)
	{
		$.ajax({
			url:"/api/deldenyip?ip="+ip,
			type:"get",
			success:function(res){
				if(res.success == "true")
				{
					alert("删除成功");
					ipdeny();
				}
				else
				{
					alert("删除失败"+res.msg);
				}
			}
		})
	}
	else
	{
		console.log('cancel')
	}
}

adddenyip = function(){
	ip = $("#adddenyip").val();
	if(ip == "")
	{
		alert("ip不能为空");
		return false;
	}
	$.ajax({
		url:"/api/adddenyip?ip="+ip,
		type:"get",
		success:function(res){
			if(res.success != "true")
			{
				alert(res.msg);
				return false;
			}
			else
			{
				alert('添加成功');
				ipdeny();
			}
		}
	});
}