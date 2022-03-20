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

### 6.2-The Executor framework
通过`Executor`接口作为基础, 实现了很多异步任务执行的框架. *e.g. TaskExecutionWebServer*. Executors下也实现了创建线程池的方法(**实际上还是推荐手动设置参数**). Executor的主要目的还是解耦任务的提交和执行. 如果想有一些灵活的执行策略, `new Thread(runnable).start()`这种提交立即执行的代码就可以考虑用`Executor`来替代, 并在实现的时候插入一些执行策略. 
```
public interface Executor {
    void execute(Runnable command);
}
```

`ExecutorService`接口定义了一些管理`Executor`生命周期的方法, `shutdown`: 不再接受新任务并等待当前任务执行完成后再关闭, `shutdownNow`: 强制关闭. 

### 6.3 Finding exploitable parallelism
这一节通过一个图像渲染器来解释并发的设计. 首先是*e.g. SingleThreadRenderer*这种没有并发的串行设计, 图像渲染和图像下载的i/o操作耦合在一起, 等待i/o操作的过程中, CPU几乎不工作, 让整个任务的总时长较长, 所以需要拆开任务并发执行. 如果用Future类实现异步的图像渲染器, 如*e.g. FutureRenderer*, 理论上可以解决这个问题, 但是通常图像渲染的时间远低于下载的时间, 所以最终的瓶颈仍然在下载时间, 对性能的提升有限. 

而*e.g. Renderer*通过`ExecutorCompletionService`实现了并行的下载与及时渲染. 已经下载好的图片在`completionService.take()`后可以被及时消费掉.

## Chapter7-Cancellation and Shutdown


## 参考
1. Java并发编程实战
2. [廖雪峰Java教程-多线程](https://www.liaoxuefeng.com/wiki/1252599548343744/1255943750561472)