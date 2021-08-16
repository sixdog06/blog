---
title: "CSS入门"
date: 2021-08-12
draft: false
toc: true
categories: ["学习笔记"]
tags: ["前端"]
---

Cascading Style Sheets(CSS) is a stylesheet language used to describe the presentation of a document written in HTML or XML(including XML dialects such as SVG, MathML or XHTML). CSS describes how elements should be rendered on screen, on paper, in speech, or on other media. CSS is among the core languages of the open web and is standardized across Web browsers according to W3C specifications. 

官方的tutorial读起来会感到都一点混乱, 东西全但抓不住重点, 所以我通过看视频+看重点部分的文档进行入门的学习. 

## 样式位置
常用的有三种, 遵循就近原则, 最近的样式优先级最高. 
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>

    <!--外部样式-->
    <link rel="stylesheet" href="css/style.css">
    <!--内部样式-->
    <style>
        h1{
            color: lightgreen;
        }
    </style>
</head>
<body>
    <!--行内样式-->
    <h1 style="color: blueviolet">hahahah</h1>
</body>
</html>
```

## 选择器
常见的的是下列三种, 更多的可以在[选择器列表](https://developer.mozilla.org/zh-CN/docs/Learn/CSS/Building_blocks/Selectors)找到. 优先级**id选择器>class选择器>标签选择器**. 
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>

    <style>
        #id{
            color: blue;
        }
        .class{
            color: red;
        }
        h1{
            color: lightgreen;
        }
    </style>
</head>
<body>
    <h1 id="id" class="class" style="color: blueviolet">hahahah</h1>
</body>
</html>
```

> 注意CSS的注释是`/* 这是一行单行注释 */`这种形式的, `<!-- -->`在部分浏览器的`<style>`标签生效, 但不推荐使用.

### 层次选择器
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>

    <style>
        /*后代选择器*/
        body p{
            background: red;
        }
        /*子选择器(只选择一代后代)*/
        body>p{
            background:orange;
        }
        /*相邻兄弟选择器(只向下选择一个兄弟)*/
        .active+p{
            background: blue;
        }
        /*通用兄弟选择器(向下选择所有兄弟)*/
        .active2~p{
            background:gray;
        }
    </style>
</head>
<body>
    <p>p0</p>
    <p class="active">p1</p>
    <p>p2</p>
    <p class="active">p3</p>
    <ul>
        <li>
            <p>p4</p>
        </li>
        <li>
            <p>p5</p>
        </li>
        <li>
            <p>p6</p>
        </li>
    </ul>
    <p>p8</p>
    <p class="active2">p7</p>
    <p>p9</p>
    <p>p10</p>
</body>
</html>
```

### 伪类选择器
```
<style>
    /*ul的第一个子元素*/
    ul li:first-child{
        background: red;
    }
    /*ul的最后一个子元素*/
    ul li:last-child{
        background: blue;
    }
    /*
        首先找到所有当前元素的兄弟元素, 然后按照位置先后顺序从1开始排序
        nth-child括号中表达式(an+b)匹配到的元素集合
    */
    p:nth-child(2n+1){
        background: orange;
    }
    /*针对具有一组兄弟节点的标签, 用n来筛选出在一组兄弟节点的位置*/
    p:nth-of-type(1){
        background: green;
    }
</style>
```

### 属性选择器
支持用正则筛选属性, `=`表示等于, `*=`表示包含, `^=`表示开头, `$=`表示以结尾.
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
  <style>
    .demo a{
      height: 50px;
      width: 50px;
      float:left;
      background: blue;
      text-align: center;
      color: beige;
      text-decoration: none;
      margin-right: 5px;
      font: bold 20px/50px Arial;
    }
    a[id]{
      background: red;
    }
    a[class*=first3]{
      background: aqua;
    }
    a[class="links item2 first2"]{
      background: orange;
    }
    a[class$=first4]{
      background: lightgreen;
    }
  </style>
</head>
<body>
  <p class="demo">
    <a href="https://www.baidu.com" class="first" id="first">1</a>
    <a href="a" class="links item2 first2" >2</a>
    <a href="ab" class="links item3 first3" >3</a>
    <a href="abc" class="links item4 first4" >4</a>
  </p>
</body>
</html>
```

## 样式
### 字体
常用方式是用`<span>`标签吧想处理的部分字体框起来再应用样式. 
- font-family: 字体, 可以用逗号隔开中英文样式, 分别应用
- font-size: 字体大小
- font-weight: 字体粗细

### 文本样式
- color: 颜色
- text-align: 文本对齐方式
- text-indent: 首行缩进, 比如`2em`表示首行缩进2个字
- line-height: 行高
- text-decoration: 装饰, 放下划线(underline)/中划线(line-through)等
- vetical-align: 用middle实现水平对齐
- text-shadow: 水平偏移 垂直偏移 模糊半径 颜色


### 超链接与阴影
超链接是有默认颜色和下划线的, 可以自己去掉.
```
/*去掉超链接默认的下划线*/
a{
    text-decoration:none;
}
/*鼠标悬浮的状态*/
a:hover{
    color:orange;
}
/*鼠标按住未释放的状态*/
a:active{
    color:green
}
/*点击之后的状态*/
a:visited{
    color:red
}
```

### 列表
控制列表前面的点或数字. 可以设置`list-style`如下:
- none: 去掉原点
- circle: 空心圆
- decimal: 数字
- square: 正方形

## 盒子模型
可以通过debug中的computed测试. 
- padding: 内边距
- border: 边框
- margin: 外边距

比如
```
/*分别表示上/右/下/左*/
margin: 0 0 0 0
/*auto表示左右自动*/
margin: 0 auto
/*表示上/右/下/左都为4px*/
margin: 4px
/*表示上为10px, 左右为20px, 下为30px*/
margin: 10px 20px 30px
```

最后整个元素的大小就等于`内容+padding+border+margin`.

## 浮动
块级元素比如`h1~h6/p/div`等的内部可以包含行内元素(也叫内联元素)如`span/a/img`等, 反之就不行. 块级元素会独占一行, 也就是说后面的元素会放在新的一行(准确的说应该是他们的默认类型是某种元素). 我们也可以通过在块级元素内部写`display: inline`将其转换为行内元素. 还有`display: inline-block`. 他们有什么特点呢, 这里直接用文档的解释:

Some HTML elements, such as `<h1>` and `<p>`, use block as their outer display type by default. If a box has an outer display type of block, it will behave in the following ways. 
- The box will break onto a new line.
- The box will extend in the inline direction to fill the space available in its container. In most cases this means that the box will become as wide as its container, filling up 100% of the space available.
- The width and height properties are respected.
- Padding, margin and border will cause other elements to be pushed away from the box

Some HTML elements, such as `<a>`, `<span>`, `<em>` and `<strong>` use inline as their outer display type by default. If a box has an outer display type of inline, then:
- The box will not break onto a new line.
- The width and height properties will not apply.
- Vertical padding, margins, and borders will apply but will not cause other inline boxes to move away from the box.
- Horizontal padding, margins, and borders will apply and will cause other inline boxes to move away from the box.


## 参考
1. [CSS doc](https://developer.mozilla.org/en-US/docs/Web/CSS)
2. [CSS3-狂神说Java](https://www.bilibili.com/video/BV1YJ411a7dy)