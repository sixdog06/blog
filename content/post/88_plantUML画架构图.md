---
title: "plantUML画架构图"
date: 2023-11-04
draft: false
author: "小拳头"
categories: ["TECH"]
---

写文档总是要画各种图, 不管是软件工程师需要的流程图/架构图, PM的甘特图等等. 市面上也有很多工具支持, 微软的Visio, 集成在confluence中的draw.io, 都是很强大的工具. 但是作为一个文本编辑的忠实拥趸, 依然不喜欢用这些软件. 像我的博客和笔记一样, 尝试了各种工具后, 最终也回归到了用文字本身. 文字的好处有很多: 配合git实现优秀的版本管理, 本身具有自解释性. 对于需要沉淀的内容, 文字能最大化地压缩内容, 并且易于分享. 在团队协作的时候, 文字也是最好改动的. 

所以, 当我画图的时候, 也更倾向于使用文字脚本生成. plantUML进入了我的视野. UML的含义是Unified Modeling Language, 也就是用一种统一的标准, 来对设计可视化. 使用方式也非常简单, 在vscode上下载一个plantUML的插件, 创建一个`.puml`为后缀的插件, 用[plantUML](https://plantuml.com/)的语法进行编辑, 就能实现图片的实时预览. 

刚开始使用plantUML时, 我的建议是直接使用样例, 并进行修改, 需要用到某个组件的时候, 再去看对应的语法, plantUML的写法本身自解释性就很强, 所以无需我们专门花时间去学习语法. 从官网可以发现, 虽然plantUML支持了大量的结构, 但是对系统架构图支持依然不完善. 而这种常见的场景当然已经有大佬发现并解决了: [C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML).

只要在文件开头引入
```
!include  https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml
```
就能使用了.

那么C4是什么呢? 它的全称其实是C4 model, 而C4代表了4个单词: Context/Container/Component/Code, 这四个单词的表示我们软件架构图的四个层次, 粒度依次变细.
- Context: 系统层. 展示系统间的交互, 系统与人的交互, 也就是整个系统的架构逻辑
- Container: 系统内部设计. 展示某个系统使用了哪些组件, 如: 使用了db存储数据, 使用了页面/app做交互, 使用了HTTP服务传输数据
- Component: 容器内部设计. 比如拆开页面看, 我们用了不同controller来把数据给页面和app
- Code: 组件的代码

实际画图时, 我们可以灵活操作. 对于文档来说, 粒度一般到Container就可以了. 我们可以结合context和container, 同时展示整个系统的整体架构和自己负责系统使用的容器细节, 并用虚线把自己系统的context圈起来, 这样整个结构图就清晰明了了. 这些绘画的方式, 都在C4-PlantUML这个repository中可以找到. 有的时候我们希望架构图上能用icon来表示各种组件, 如MYSQL/Redis/AWS等等, 这些icon可以参考这个仓库: [plantuml-icon-font-sprites
](https://github.com/tupadr3/plantuml-icon-font-sprites/blob/master/devicons/index.md). 并在文件开头
```
!define DEVICONS https://raw.githubusercontent.com/tupadr3/plantuml-icon-font-sprites/master/devicons
!include DEVICONS/msql_server.puml
```
就能使用对应的icon了.
