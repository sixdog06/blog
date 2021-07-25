---
title: "CSS tutorial"
date: 2021-06-02
draft: false
toc: true
categories: ["学习笔记"]
tags: ["前端"]
---

## CSS Overview
CSS学习我打算纯靠看英文文档完成, 养成好习惯. CSS全称Cascading Style Sheets层叠级联样式表, 开始学习之前按照文档创建文件夹, 其中html文件用chrome打开, 编辑的时候用vscode, 用静态网站可以最快得测试效果.
![](/notes/notes32_1.png)

- Selector: HTML element name
- Declaration: specifies which of the element's properties you want to style
- Properties: ways in which you can style an HTML element

Different types of selectors, we can adjust the colour/font size... of contents in blocks:
![](/notes/notes32_2.png)

> Something else you might like to try is styling a paragraph when it comes directly after a heading at the same hierarchy level in the HTML. To do so place a +  (an adjacent sibling combinator) between the selectors.

CSS layout is mostly based on the box model:
![](/notes/notes32_3.png)

shorthand:
- width (of an element).
- background-color, the color behind an element's content and padding.
- color, the color of an element's content (usually text).
- text-shadow sets a drop shadow on the text inside an element.
- display sets the display mode of an element. (keep reading to learn more)

> [Color picker tool](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Colors/Color_picker_tool)

## CSS first steps
### What is CSS?
在`<head>`中加入`<link rel="stylesheet" type="text/css" href="style.css">`, 引入css文件, 除此之外也可以直接在block内嵌样式, 或者在`<head>`中加`<style>`.

除了上面的, 还有`@rules`这种用法. 比如`@import 'styles2.css';`, 表示import一个CSS. 还有
```
body {
  background-color: pink;
}

@media (min-width: 30em) {
  body {
    background-color: blue;
  }
}
```
指浏览器窗口比30em宽的时候, 把背景设置为蓝色(文档这样说, 但是我自己没测试出粉色的情况). 

### Getting started with CSS
hover: 鼠标悬停时改变效果
```
a:hover {
    color:red;
}
```

可以用`+`链接两个部分, `h1 + p`表示选择紧跟在h1之后的p.

### How CSS is structured
CSS可以通过`calc`做简单的计算, 通过`transform`做一些旋转等.
```
.box {
  padding: 10px;
  width: calc(90% - 30px);
  background-color: rebeccapurple;
  color: white;
  transform: rotate(0.8turn);
}
```

### How CSS works
1. The browser loads the HTML (e.g. receives it from the network).
2. It converts the HTML into a DOM (Document Object Model). The DOM represents the document in the computer's memory. The DOM is explained in a bit more detail in the next section.
3. The browser then fetches most of the resources that are linked to by the HTML document, such as embedded images and videos ... and linked CSS! JavaScript is handled a bit later on in the process, and we won't talk about it here to keep things simpler.
4. The browser parses the fetched CSS, and sorts the different rules by their selector types into different "buckets", e.g. element, class, ID, and so on. Based on the selectors it finds, it works out which rules should be applied to which nodes in the DOM, and attaches style to them as required (this intermediate step is called a render tree).
5. The render tree is laid out in the structure it should appear in after the rules have been applied to it.
6. The visual display of the page is shown on the screen (this stage is called painting).
The following diagram also offers a simple view of the process.

- [小练习](https://developer.mozilla.org/en-US/docs/Learn/CSS/First_steps/Using_your_new_knowledge)
```
body {
    font-family: Arial, Helvetica, sans-serif;
}

h1 {
    color: hotpink;
    font-size: 2em;
    font-family: Georgia, 'Times New Roman', Times, serif;
    border-bottom: 10px dotted purple;
}

h2 {
    font-size: 1.5em;
    font-style: italic;
}

.job-title {
    color: #999999;
    font-weight: bold;
}

a:hover {
    color:green;
}

ul {
    background-color: #eeeeee;
    border: solid purple 5px;
}
```

## CSS building blocks
### Cascade and inheritance(难)
**CSS order matters**, the last will be used. But if an element selector is **less specific**, it will get a lower score.

### The box model



## 参考
1. [CSS doc](https://developer.mozilla.org/en-US/docs/Web/CSS)