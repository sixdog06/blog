---
title: "Vue入门"
date: 2021-07-02
draft: false
toc: true
categories: ["学习笔记"]
tags: ["Vue"]
---

官方文档的中文介绍有简单入门的视频教程, 下载**HbuilderX**, 并导入官方的教程代码. 我学习的过程是先看完视频跑一边代码再根据文档梳理一次. 

## Hello World
把`app`这个vue对象的`data对象`绑定到`<div>`元素中. 要注意**只有当实例被创建时就已经存在于data中的property才是响应式的**, 所以如果后面要用一个property, 在`data`中需要预先声明一个空的property. 
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
![](/notes/notes34_1.png)

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

### 计算属性
`computed`中的内容就是计算属性, 基于响应式依赖进行缓存, **只在相关响应式依赖发生改变时它们才会重新求值**. 如果不要缓存, 使用方法也可以做到同样的效果. 除了计算属性之外还有侦听属性, 和前面的`vm.$watch`类似, 比如`<input v-model="question">`, 当用户在输入框打字时, 我们就可以用`watch`下的`question: function(newQuestion, oldQuestion) {}`侦听并执行代码块内的逻辑.
```
var vm = new Vue({
  el: '#demo',
  data: {
    firstName: 'Foo',
    lastName: 'Bar'
  },
  computed: {
    fullName: function () {
      return this.firstName + ' ' + this.lastName
      //可以加入setter, 否则只有getter
      //get: function() {}
      //set: function() {}
    }
  }
})
```

## Class绑定Style
实际上还是绑定了`data`中的字段.
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
        <!-- v-bind:class="{ active: isActive, green: isGreen}" map形式也可以, 这里的green指样式 -->
        <div 
        class="test" 
        v-bind:class="[ isActive ? 'active' : '', isGreen ? 'green' : '']" 
        style="width:200px; height:200px; text-align:center; line-height:200px;">
            hi vue
        </div>
        <!--color(属性):color(变量)-->
        <div 
        :style="{color:color, fontSize:size, background: isRed ? '#FF0000' : ''}">
            hi vue
        </div>
    </div>
    <script type="text/javascript">
    var vm = new Vue({
        el : "#app",
        data : {
            isActive : true, //是否生效
            isGreen : true,
            color : "#FFFFFF",
            size : '50px',
            isRed : true
        }
    });
    </script>
    <style>
    .test{font-size:30px;}
    .green{color:#00FF00;}
    .active{background:#FF0000;}
    </style>
</body>
</html>
```

## 条件渲染
`if-else`中的模板可以复用元素, 可以用两个`<input>`做测试, 两个`<input>`通过一个按键互相切换, 输入框中的值不变. 如果想每次都重新渲染, 那么在`<input>`中加入`key`即可. 而`v-show`无论是否隐藏都会渲染, 只是用css进行隐藏. 
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
        <div v-if="type === 'A'"> <!--根据条件渲染div(惰性)-->
        A
        </div>
        <div v-else-if="type === 'B'">
        B
        </div>
        <div v-else-if="type === 'C'">
        C
        </div>
        <div v-else>
        Not A/B/C
        </div>
        <!--根据条件渲染, element本身存在, 只是css渲染不同-->
        <h1 v-show="ok">Hello!</h1>
    </div>
    <script type="text/javascript">
    var vm = new Vue({
        el : "#app",
        data : {
            type : "B",
            ok : true
        }
    });
    </script>
    <style type="text/css">
    </style>
</body>
</html>
```

## 列表渲染
`<li v-for="(item,index) in items" :key="index">`就是迭代的语法, `in`可以用`of`替换. `<li v-for="value, key in object">`可以用来迭代对象中的内容. 对象遍历的是`Object.keys()`的结果. `v-for`采用**就地更新策略**, 所以即使遍历对象顺序变了, Vue也不会移动Dom元素, 如果要更新这个元素, 就需要用`v-bind:key="index"`来制定一个唯一的key确定节点身份, 其中`v-bind`可以省略.

可以用计算属性的`list.filter`进行对迭代结果进行过滤, 如果计算属性不适用, 也可以用方法包裹一个过滤. 
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
        <ul>
            <!--列表渲染数组元素与索引-->
            <!--:key等同v-bind:key, 让vue根据index排序, 否则list顺序改变是不会渲染新顺序的-->
            <li v-for="(item,index) in items" :key="index">
            {{index}}{{ item.message }}
            </li>
        </ul>
        <ul>
            <li v-for="value, key in object">
                {{key}} : {{ value }}
            </li>
        </ul>
    </div>
    <script type="text/javascript">
    var vm = new Vue({
        el : "#app",
        data : {
            items : [
                { message: 'Foo' },
                { message: 'Bar' }
            ],
            object: {
                title: 'How to do lists in Vue',
                author: 'Jane Doe',
                publishedAt: '2016-04-10'
            }
        }
    });
    </script>
</body>
</html>
```

> 官方文档不推荐在一个element上同时用`v-for`和`v-if`, 因为`v-for`的优先级更高, 所以其实每一次的迭代都运行`v-if`, 所以直接把`v-if`放在外层元素(template)才能真的跳过循环的执行. 

## 事件处理
通过`v-on`绑定事件, 类似于中断器. 除了点击事件, 双击事件, 还可以处理**系统修饰键**, 比如`v-on:keyup.enter`拿到回车事件, `.left`鼠标左键事件等等.
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
        <div id="example-1">
            <button v-on:click="counter += 1"> 数值 :  {{ counter }} </button><br /> <!--直接绑定js指令-->
            <button v-on:dblclick="greet('abc', $event)">Greet</button> <!--绑定greet函数,dblclick为双击-->
        </div>
    </div>
    <script type="text/javascript">
    var vm = new Vue({
        el : "#app",
        data : {
            counter: 0,
            name : "vue"
        },
        methods:{
            greet : function (str, e) {
                alert(str);
                console.log(e);
            }
        }
    });
    </script>
    <style type="text/css">
    </style>
</body>
</html>
```

## 输入绑定
可以对输入内容进行双向绑定. 要注意`v-model`不会在输入法组合文字过程中得到更新, 输入法输入需要用input事件处理.
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
        <div id="example-1">
            <input v-model="message" placeholder="edit me"> <!--双向绑定message单行文本-->
            <p>Message is: {{ message }}</p>
            <textarea v-model="message2" placeholder="add multiple lines"></textarea> <!--双向绑定message多行文本-->
            <p style="white-space: pre-line;">{{ message2 }}</p>
            <br />
            
            <!--复选框绑定到list-->
            <div style="margin-top:20px;">
                <input type="checkbox" id="jack" value="Jack" v-model="checkedNames">
                <label for="jack">Jack</label>
                <input type="checkbox" id="john" value="John" v-model="checkedNames">
                <label for="john">John</label>
                <input type="checkbox" id="mike" value="Mike" v-model="checkedNames">
                <label for="mike">Mike</label>
                <br>
                <span>Checked names: {{ checkedNames }}</span>
            </div>
            
            <!--单选按钮-->
            <div style="margin-top:20px;">
                <input type="radio" id="one" value="One" v-model="picked">
                <label for="one">One</label>
                <br>
                <input type="radio" id="two" value="Two" v-model="picked">
                <label for="two">Two</label>
                <br>
                <span>Picked: {{ picked }}</span>
            </div>
            <button type="button" @click="submit">提交</button>
        </div>
        
    </div>
    <script type="text/javascript">
    var vm = new Vue({
        el : "#app",
        data : {
            message : "test", //初始化
            message2 :"hi",
            checkedNames : ['Jack', 'John'],
            picked : "Two"
        },
        methods: {
            submit : function () {
                console.log(this.message);
                var postObj = { //通过变量收集所有data的值
                    msg1 : this.message1,
                    msg2 : this.message2,
                    checkval : this.checkedNames
                };
                console.log(postObj)
            }
        }
    });
    </script>
    <style type="text/css">
    </style>
</body>
</html>
```

`v-model`有一些修饰符, 比如:
- `v-model.lazy`: 输入框在change事件之后同步, 而不是input
- `v-model.number`: 自动将用户的输入值转为数值类型
- `v-model.trim`: 减掉输入的首尾空白字符

## 组件(Components)
注意这里的data是一个函数而不是一个字段, 保证每个实例可以维护一份被返回对象的独立的拷贝, 否则用到这个Component的地方都会使用同一个对象, 绑定的`template`中必须有**根节点**, 否则会报`every component must have a single root element`错误. 
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
        <!--数据封闭在组件内部, 互相没有影响-->
        <button-counter title="title1 : " @clicknow="clicknow">
            <h2>---------------</h2>
        </button-counter>
        <button-counter title="title2 : "></button-counter>
    </div>
    <script type="text/javascript">
    Vue.component('button-counter', { //创建一个组件
        props: ['title'], //props定义组件属性
        data: function () {
            return {
                count: 0
            }
        },
        //组件template必须有根节点, <slot></slot>是插槽, 可以放入任意html标签, 这里是<h2>---------------</h2>
        template: '<div><h1>hi...</h1><button v-on:click="clickfun">{{title}} You clicked me {{ count }} times.</button><slot></slot></div>',
        methods:{ //组件脚本
            clickfun : function () {
                this.count ++;
                this.$emit('clicknow', this.count); //触发事件(事件名称, 可携带的参数)
            }
        }
    })
    var vm = new Vue({
        el : "#app",
        data : {
            
        },
        methods:{
            clicknow : function (e) {
                console.log(e);
            }
        }
    });
    </script>
    <style type="text/css">
    </style>
</body>
</html>
```

可以局部绑定, 把`template`声明到Vue实例的`components`中. `props`中可以注册一些attributes, 这些中可以注册一些attributes就成为了组件的property. 
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
        <button-counter title="This is title"></button-counter>
        <test></test>
    </div>
    <script type="text/javascript">
    Vue.component('button-counter', {
        props: ['title'],
        data: function () {
            return {}
        },
        template: '<div><h1>hi...{{ title }}</h1></div>',
        methods:{
            
        }
    })
    var vm = new Vue({
        el : "#app",
        data : {
            
        },
        methods:{
            clicknow : function (e) {
                console.log(e);
            }
        },
        components:{
            test : {
                template:"<h2>h2...</h2>" //局部注册
            }
        }
    });
    </script>
    <style type="text/css">

    </style>
</body>
</html>
```

> 部分HTML元素对内部元素的类型有限制, 所以我们自定义的`component`如果放在里面, 可能会导致渲染错误.

## 单文件组件
简单来说, 就是一个`.vue`文件作为一个单文件组件, 在页面文件中通过`import 文件名 from '路径/文件名.vue'`, 再用
```
export default {
    name: 'app',
    components: {
        文件名
    }
}
```
注册这个组件, 在template中就可以使用这个组件了. 单文件组件包含`<template>/<script>/<style>`三种组件. 

## 参考
1. [Vue getting started](https://cn.vuejs.org/v2/guide/index.html)