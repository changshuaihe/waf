//导航菜单路由
$("#ipwhitelink").on("click", function(){
  ipwhite();
});
$("#ipdenylink").on("click", function(){
  ipdeny();
});
$("#editrules").on("click", function(){
  getruleslist();
});
$("#baseconfig").on("click", function(){
  baseconfig();
});
$("#monitor").on("click", function(){
  monitor();
})


//////////////////////////////ip管理页面
//从content列表删除ip
$("#content").on("click", ".delwhiteipbtn", function(){
  delipwhite($(this).attr('data-ip'));
});
$("#content").on("click", ".deldenyipbtn", function(){
  delipdeny($(this).attr('data-ip'));
});

//添加ip
$("#content").on("click", "#adddenyipbtn", function(){
  adddenyip($(this).attr('data-ip'));
})
$("#content").on("click", "#addwhiteipbtn", function(){
  addwhiteip($(this).attr('data-ip'));
});

//////////////////////////////规则页面
//保存规则
$("#content").on("click", "#saverulesbtn", function(){
  saverules();
});
//删除规则
$("#content").on("click", ".delrulebtn", function(){
  delrule(this);
});
//修改规则模式
$("#content").on("click", ".rulemodel", function(){
  changerulemodel(this);
});

/////////////////////////////基本配置页
$("#content").on("click", "#saverunmodelbtn", function(){
  saverunmodel();
});