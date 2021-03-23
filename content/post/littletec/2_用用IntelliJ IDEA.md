---
title: "用用IntelliJ IDEA"
date: 2020-11-23
draft: false
toc: true
categories: ["技术小文"]
tags: ["IDEA"]
---

## 查看安装目录
对于macos, 在`Applications`文件夹找到`idea`, 右键出菜单, 点击`Show Package Contents`就可以看到目录了. 其中`bin`就可以找到配置文件.

## Module
IDEA下的module相当于Eclipse的project, 而project则相当于workspace. 不同的project需要通过不同的窗口打开. 一个Project下的不同module可以分布式得部署在不同的服务器上. 新建的module下也有src文件夹, 所以其实project下的src就可以不用了(可以删除).

## Project详细信息
`File->Project Structure`.

## 配置
macos中是`Preference`

## 调试
- step over: 进入下一步, 如果当前行断点是一个方法, 则不进入当前方法体内
- step into: 进入下一步, 如果当前行断点是一个方法, 则进入当前方法体内
- force step into 进入下一步, 如果当前行断点是一个方法, 则进入当前方法体内
- step out: 跳出
- resume program stop: 恢复程序运行, 但如果该断点下面代码还有断点则停在下一个断点上


## 参考
1. [尚硅谷IDEA教程(idea经典之作)](https://www.bilibili.com/video/BV1PW411X75p?p=5)