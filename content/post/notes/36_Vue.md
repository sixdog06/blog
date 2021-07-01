---
title: "Vue入门"
date: 2021-07-01
draft: false
toc: true
categories: ["学习笔记"]
tags: ["Vue"]
---

官方的中文介绍有简单入门的视频教程, 下载**HbuilderX**, 并导入官方的教程代码.

## chapter01 Installation
```
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<title></title>
		<!--通过下载vue.js文件引用-->
		<script src="vue.js" type="text/javascript" charset="utf-8"></script>
	</head>
	<body>
		<<script type="text/javascript">
			Vue()
		</script>
	</body>
</html>
```

## chapter02 Creating a Vue Instance
```
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title></title>
<script src="vue.js" type="text/javascript" charset="utf-8"></script>
</head>
<body>
	<div id="app">
	  {{ message }} {{name}} <!--视图-->
	</div>
	
	<script type="text/javascript">
	var app = new Vue({
		el: '#app',
		data: {
			message: 'Hello Vue!',
			name : "Vue"
		}
	});
	</script>

</body>
</html>
```


```
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title></title>
<script src="vue.js" type="text/javascript" charset="utf-8"></script>
</head>
<body>
<div id="app">
	{{a}}
</div>

<script type="text/javascript">
var data = { a : 1 };
var vm = new Vue({
	el   : "#app",
	data : data
});

//观察变量啊前后的变化
vm.$watch('a', function(newVal, oldVal){
	console.log(newVal, oldVal);
})
//修改变量a
vm.$data.a = "test"

</script>

</body>
</html>
```

## 04
https://v3.vuejs.org/api/composition-api.html#lifecycle-hooks

## 插值/指令

1. [Vue getting started](https://cn.vuejs.org/v2/guide/index.html)