---
title: "Java Concurrency in Practice-II.Structuring Concurrency Applications"
date: 2022-03-07
draft: false
author: "小拳头"
categories: ["Java"]
---
项目链接[JavaLab](https://github.com/huanruiz/JavaLab), 有示例的代码以*类名*的形式标注在小结中.

## Chapter6-Task Execution
### 6.1-Executing tasks in threads
如果串行执行任务, 性能很差, 不适合web服务器. 但是因为安全性和简单性, 被GUI框架广泛使用. *e.g. SingleThreadWebServer*. 如果并行执行, 但是无限制地创建线程, 依然会有缺陷, 因为线程的生命周期开销高(创建和销毁), 活跃的线程会消耗资源, 并且线程的数量上限是有限制的, 超出范围会产生OOM. *e.g. ThreadPerTaskWebServer*.

### 6.2 The Executor framework
通过`Executor`接口作为基础, 实现了很多异步任务执行的框架. *e.g. TaskExecutionWebServer*. Executors下也实现了创建线程池的方法(**实际上还是推荐手动设置参数**). Executor的主要目的还是解耦任务的提交和执行. 如果想有一些灵活的执行策略, `new Thread(runnable).start()`这种提交立即执行的代码就可以考虑用`Executor`来替代, 并在实现的时候插入一些执行策略. 
```
public interface Executor {
    void execute(Runnable command);
}
```

线程池todo. 

## 参考
1. Java并发编程实战
2. [廖雪峰Java教程-多线程](https://www.liaoxuefeng.com/wiki/1252599548343744/1255943750561472)
