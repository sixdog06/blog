---
title: "Vue入门"
date: 2021-07-01
draft: false
toc: true
categories: ["学习笔记"]
tags: ["Vue"]
---

官方的中文介绍有简单入门的视频教程, 下载**HbuilderX**, 并导入官方的教程代码. 看完视频跑一边代码再根据文档复习一次. 

## Hello World
把`app`这个vue对象的`data对象`绑定到`<div>`元素中. 要注意**只有当实例被创建时就已经存在于data中的property才是响应式的**, 所以如果后面要用一个property, 再`data`中需要预先声明一个空的property. 
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
	var app = new Vue( //创建一个vue对象
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

如果`data:obj`进行了映射, 但是同时`Object.freeze(obj)`, 那么obj中的property无法被修改. Vue有一些实例property和方法, 都带有前缀`$`. 比如用`$watch`可以观察变量前后的变化, 回调函数`function`会在`vm.a`改变后调用.
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

	//观察变量前后的变化
	vm.$watch('a', function(newVal, oldVal){
		console.log(newVal, oldVal);
	})
	//修改变量a
	vm.$data.a = "test"
	</script>
</body>
</html>
```

## 实例生命周期钩子
可以在生命周期不同的阶段注入逻辑, **不能在property或回调上使用箭头函数, 因为建通函数没有this, 可能导致错误(向上级查找)**, 可能导致`Uncaught TypeError: Cannot read property of undefined`或`Uncaught TypeError: this.myMethod is not a function`.
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
	{{msg}}
</div>
<script type="text/javascript">
var vm = new Vue({
	el : "#app",
	data : {
		msg : "hi vue",
	},
	//在实例初始化之后，数据观测(data observer)和event/watcher事件配置之前被调用
	beforeCreate:function(){
		console.log('beforeCreate');
	},
	/* 在实例创建完成后被立即调用。
	在这一步, 实例已完成以下的配置：数据观测(data observer), 属性和方法的运算, watch/event事件回调
	然而, 挂载阶段还没开始, $el属性目前不可见。 */
	created	:function(){
		console.log('created');
	},
	//在挂载开始之前被调用: 相关的渲染函数首次被调用
	beforeMount : function(){
		console.log('beforeMount');

	},
	//el被新创建的vm.$el替换, 节点被vue节点替换
	mounted : function(){
		console.log('mounted');
	
	},
	//数据更新时调用
	beforeUpdate : function(){
		console.log('beforeUpdate');
			
	},
	//组件DOM已经更新, 组件更新完毕 
	updated : function(){
		console.log('updated');
			
	}
});
setTimeout(function(){
	vm.msg = "change ......";
}, 3000);
</script>
</body>
</html>
```

实例生命周期:
![](/notes/notes36_1.png)

## 模板语法
### 插值(Mustache{{}})
注意差值中支持的是表达式, 不是语句或者流控制等, 所以`if (ok) { return message}`这种写法不会生效.
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
		{{msg}}
		<p>Using mustaches: {{ rawHtml }}</p>
		<p v-html="rawHtml"></p> <!--通过v-html指令把变量转换为html元素-->
		<div v-bind:class="color">test...</div> <!--通过v-bind动态绑定颜色-->
		<p>{{ number + 1 }}</p> <!--js运算-->
		<p>{{ 1 == 1 ? 'YES' : 'NO' }}</p> <!--js三元运算-->
		<p>{{ message.split('').reverse().join('') }}</p> <!--string的函数运算-->
	</div>
	<script type="text/javascript">
	var vm = new Vue({
		el : "#app",
		data : {
			msg : "hi vue",
			rawHtml : '<span style="color:red">this is should be red</span>',
			color:'blue',
			number : 10,
			ok : 1,
			message : "vue"
		}
	});
	vm.msg = "hi....";
	</script>
	<style type="text/css">
	.red{color:red;}
	.blue{color:blue; font-size:100px;}
	</style>
</body>
</html>
```

### 指令(Directives)
带有`v-`前缀的特殊attribute. 
- `<p v-if="seen">现在你看到我了</p>`: 通过表达式seen的真假选择是否插入/移除`<p>`元素
- `<a v-bind:href="url">...</a>`: href attribute与**表达式**url的值绑定
- `<a v-on:click="doSomething">...</a>`: 用`v-on`可以监听DOM事件

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
		<p v-if="seen">现在你看到我了</p>
		<a v-bind:href="url">...</a> <!--绑定属性-->
		<div @click="click1"> , <!--绑定点击事件-->
			<div @click.stop="click2"> <!--.stop:当前点击事件执行后就停止-->
				click me
			</div>
		</div>
	</div>
	<script type="text/javascript">
	var vm = new Vue({
		el : "#app",
		data : {
			seen : false, //是否渲染
			url : "https://cn.vuejs.org/v2/guide/syntax.html#%E6%8C%87%E4%BB%A4"
		},
		methods:{
			click1 : function () {
				console.log('click1......');
			},
			click2 : function () {
				console.log('click2......');
			}
		}
	});
	</script>
	<style type="text/css">
	</style>
</body>
</html>
```

### 缩写
直接copy文档:
```
<!-- 完整语法 -->
<a v-bind:href="url">...</a>

<!-- 缩写 -->
<a :href="url">...</a>

<!-- 动态参数的缩写 (2.6.0+) -->
<a :[key]="url"> ... </a>
```

```
<!-- 完整语法 -->
<a v-on:click="doSomething">...</a>

<!-- 缩写 -->
<a @click="doSomething">...</a>

<!-- 动态参数的缩写 (2.6.0+) -->
<a @[event]="doSomething"> ... </a>
```




1. [Vue getting started](https://cn.vuejs.org/v2/guide/index.html)