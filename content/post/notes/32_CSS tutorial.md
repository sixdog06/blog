---
title: "CSS tutorial"
date: 2021-06-02
draft: false
toc: true
categories: ["学习笔记"]
tags: ["前端"]
---

## CSS basics
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


## 参考
1. [CSS doc](https://developer.mozilla.org/en-US/docs/Web/CSS)