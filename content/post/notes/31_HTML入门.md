---
title: "HTML入门"
date: 2021-05-31
draft: false
toc: true
categories: ["学习笔记"]
tags: ["前端"]
---

## 简介
```
<!-- DOCTYPE: 告诉浏览器规范(可省略) -->
<!DOCTYPE html>
<html lang="en">

<!-- 头 -->
<head>
    <!-- 描述标签 -->
    <!-- 做SEO -->
    <meta charset="UTF-8">
    <meta name="keywords" content="First html">
    <meta name="description" charset="learning html">
    <!-- 标题 -->
    <title>Title</title>
</head>

<!-- 主体 -->
<body>
    Hello world!
</body>
</html>
```

## 基础标签
```
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/html" xmlns="http://www.w3.org/1999/html"
      xmlns="http://www.w3.org/1999/html">
<head>
    <meta charset="UTF-8">
    <title>Basic Tag</title>
</head>

<body>
<!-- 标题标签 -->
<h1>one</h1>
<h2>two</h2>
<h3>three</h3>
<h4>four</h4>
<h5>five</h5>
<h6>six</h6>

<!-- 段落标签 -->
<p>Twinkle, twinkle, little star</p>
<p>How I wonder what you are</p>
<p>Up above the world so high</p>

<!-- 水平线标签 -->
<hr/>

<!-- 换行标签 -->
Like a diamond in the sky</br>
Twinkle, twinkle little star</br>
How I wonder what you are</br>

<!-- 粗体, 斜体 -->
<h1>字体样式</h1>
<strong>Strong</strong>
<em>Em</em>
</br>

<!--特殊符号-->
空&nbsp;&nbsp;&nbsp;格

&gt;
&lt;
&copy;

</body>
</html>
```

## 图片/超链接标签
```
<img src="../resources/image/avator.jpeg" alt="name" title="悬停文字" width="100" height="100">
```

```
<a name="top">top</a>
<!--
herf: 必填, 跳转哪个页面
target: 窗口哪里打开
  _blank: 新网页打开
  _self: 自己网页打开
-->
<a href="1.firstwebpage.html" target="_blank">clinkme1</a></br>
<a href="https://www.google.com">clinkme2</a>

<a href="1.firstwebpage.html">
  <img src="../resources/image/avator.jpeg" alt="name" title="悬停文字" width="100" height="100">
</a>

<!--锚链接
1.标记
2.跳转标记
-->
<a href="2.basicTag.html#top">to top</a>

<!--邮件标签, 各种联系方式功能标签可以直接到对应厂的网站上下-->
<a href="mailto:huanruiz@foxmail.com">send mail</a>
```

- 块元素: p, h1-h6
- 行内元素: a, strong

## 列表/表格标签
```
<!--有序列表-->
  <ol>
    <li>Java</li>
    <li>Python</li>
    <li>JavaScript</li>
    <li>C</li>
  </ol>

<!--无序列表-->
<ul>
  <li>Java</li>
  <li>Python</li>
  <li>JavaScript</li>
  <li>C</li>
</ul>

<!--自定义列表
dl: 标签
dt: 标题
dd: 内容
-->
<dl>
  <dt>Static</dt>
  <dd>Java</dd>
  <dt>Dynamic</dt>
  <dd>Python</dd>
  <dd>JavaScript</dd>
</dl>
```

```
<!--Table
行: tr
列: td
-->
<table border="1px">
  <tr>
    <!--colspan 跨列-->
    <td colspan="3">1-1</td>
  </tr>
  <tr>
    <td>1-2</td>
    <td>1-3</td>
    <td>1-4</td>
  </tr>

  <tr>
    <!--rowspan 跨行-->
    <td rowspan="2">2-1</td>
    <td>2-2</td>
    <td>2-3</td>
  </tr>

  <tr>
    <td>3-1</td>
    <td>3-2</td>
  </tr>
</table>
```

## 媒体元素/页面结构/iframe
```
<!--
controls: 控制条
autoplay: 自动播放
-->
<video src="" controls autoplay></video>
<audio src="" controls autoplay></audio>
```

- header
- footer
- section
- article
- aside: 侧边栏
- nav

```
<!--b站-->
<iframe src="//player.bilibili.com/player.html?aid=55631961&bvid=BV1x4411V75C&cid=97257967&page=11" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"> </iframe>

<!--test, 发现google不能内嵌-->
<iframe src="https://www.baidu.com" frameborder="0" width="300px" height="300px"></iframe>

<!--通过href填内容-->
<iframe src="" name="hello">width="300px" height="300px"</iframe>
<a href="https://www.baidu.com" target="hello">点击跳转</a>
```

## 表单
```
<form action="1.firstwebpage.html" method="get">
  <p>name: <input type="text" name="username" value="init" maxlength="8" size="30"></p>
  <p>password: <input type="password" name="pwd"></p>
  <input type="submit">
  <input type="reset">
  <p>gender单选框: <!--name表示一个组-->
    <input type="radio" value="boy" name="gender">male
    <input type="radio" value="girl" name="gender">female
  </p>

  <p>多选框:
    <input type="checkbox" value="code" name="hobby" checked>code
    <input type="checkbox" value="eat" name="hobby">eat
    <input type="checkbox" value="sleep" name="hobby">sleep
  </p>

  <!--按钮-->
  <p>
    <input type="button" name="btn1" value="longer">
    <input type="image" name="btn2" src="../resources/image/avator.jpeg">
  </p>

  <!--下拉框-->
  <p>Country
    <select name="list name">
      <option value="value">China</option>
      <option value="value" selected>US</option>
      <option value="value">UK</option>
    </select>
  </p>

  <!--文本域-->
  <p>Feedback
    <textarea name="textarea" cols="50" rows="10">content</textarea>
  </p>

  <!--文件域-->
  <p>
    <input type="file" name="files">
    <input type="button" value="upload" name="upload">
  </p>

  <!--邮件验证(只检查@)-->
  <p>
    邮箱: <input type="email" name=""email>
    url: <input type="url" name=""url>
    number: <input type="number" name="num" max="100" min="0" step="10">
  </p>

  <!--滑块-->
  <p>
    <input type="range" name="voice" min="0" max="100" step="2">
  </p>

  <!--搜索框I(多个x)-->
  <p>Search
    <input type="search" name="search">
  </p>
</form>
```

一些标签:
- readonly: 只读
- disable: 禁用
- hiddle: 隐藏, 可以配合value使输入保持默认值
- placeholder="": 提示信息
- required: 必填
- pattern: 正则判断

## 参考
1. [HTML5完整教学通俗易懂-狂神说Java](https://www.bilibili.com/video/BV1x4411V75C)