---
title: "几行代码解释Java的虚拟线程并不是万能解药"
date: 2023-05-03
draft: false
author: "小拳头"
categories: ["TECH"]
---

在[JEP 444](https://openjdk.org/jeps/444)中, 对虚拟线程进行了第一次正式的介绍, 并且提供了[preview api](https://openjdk.org/jeps/12). 虚拟线程在JDK19中已经被发布, 并且预计在JDK21中发布最新版本.

其实从JEP 444的介绍可以看出, 虚拟线程只会对高并发(超过几千的并发量)并且不是CPU密集型应用的效果有显著的提升. 有了virtual thread这个概念, 非virtual的线程也就有了platform thread这个名字. virtual thread是一种轻量级的platform thread, 它具有platform thread的所有功能. 类似Go中的goroutines, virtual thread是JDK提供的用户级线程, 并不直接与OS绑定, 所以一个OS先线程下可以有很多个虚拟线程. Java平台线程的切换从抽象的角度看是时间片的轮状, 或是有优先级的调度, 但是当一个平台线程进行IO操作时, CPU资源其实并没有被有效使用, 而虚拟线程则可以在IO操作进行等待的时候, 执行其他的任务, 冲锋利用CPU.

下面的例程, 分别用`Thread.sleep(1000);`来模拟IO操作的等待时间, `Test.fibonacci(int n);`来模拟计算操作. 分别测试IO密集和CPU密集的运行效果. 每两个实验之间主线程会`Thread.sleep(5000);`, 让当前执行的任务全部完成, 再执行下一个.
```
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Test {

    public static void main(String[] args) throws InterruptedException {
        ExecutorService virtualService = Executors.newVirtualThreadPerTaskExecutor();
        ExecutorService nonVirtualService = Executors.newFixedThreadPool(1);
        
        // I/O密集测试
        System.out.println("start i/o bound test(virtualService), time:" + System.currentTimeMillis());
        for (int i = 0; i < 5; i++) {
            virtualService.execute(new IoBoundTask());
        }

        Thread.sleep(5000);
        System.out.println("start i/o bound test(nonVirtualService), time:" + System.currentTimeMillis());
        for (int i = 0; i < 5; i++) {
            nonVirtualService.execute(new IoBoundTask());
        }

        Thread.sleep(5000);
        // CPU密集测试
        System.out.println("start cpu bound test(virtualService), time:" + System.currentTimeMillis());
        for (int i = 0; i < 3; i++) {
            virtualService.execute(new CpuBoundTask());
        }

        Thread.sleep(5000);
        System.out.println("start cpu bound test(nonVirtualService), time:" + System.currentTimeMillis());
        for (int i = 0; i < 3; i++) {
            nonVirtualService.execute(new CpuBoundTask());
        }
        virtualService.shutdown();
        nonVirtualService.shutdown();
    }

    /**
     * 用斐波那契数列计算来消耗CPU资源
     */
    public static int fibonacci(int n) {
        if (n == 0) {
            return 0;
        } else if (n == 1) {
            return 1;
        } else {
            return fibonacci(n - 1) + fibonacci(n - 2);
        }
    }
}

class IoBoundTask implements Runnable {
    @Override
    public void run() {
        try {
            // I/O密集也就是线程会在某个I/O操作中等待, 用sleep可以模拟这种情况
            Thread.sleep(1000);
            System.out.println(Thread.currentThread());
            System.out.println(System.currentTimeMillis());
        } catch (InterruptedException e) {
        }
    }
}

class CpuBoundTask implements Runnable {
    @Override
    public void run() {
        // CPU密集也就是线程会持续消耗CPU资源进行计算
        Test.fibonacci(40);
        System.out.println(Thread.currentThread());
        System.out.println(System.currentTimeMillis());
    }
}
```

因为虚拟线程目前处于preview的状态, 直接用`javac`编译会报`error: newVirtualThreadPerTaskExecutor() is a preview API and is disabled by default.`, 加上开启preview api的参数即可.
```
Javac Test.java --enable-preview --source 19
```

运行Test.class文件时, 也需要开启preview api. 在代码中我限制了平台线程的线程池核心线程数和线程池的最大线程数都为1, 为保持实验的一致性, 通过JVM参数, 对虚拟线程也做同样限制.
```
Java --enable-preview -Djdk.virtualThreadScheduler.parallelism=1 -Djdk.virtualThreadScheduler.maxPoolSize=1 -Djdk.virtualThreadScheduler.minRunnable=1 Test
```

从运行结果可以看出, 执行IO密集型的任务时, 虚拟线程的5个任务几乎同时完成, 而平台线程执行时, 输出是一个一个蹦出来的, 事实上是串行执行. 而执行CPU密集型任务时, 虚拟线程和平台线程执行的效果都近似于串行, 虚拟线程并没有等待时间做任务的切换. 进而印证的JEP的介绍和我们的结论.

最后进行一个灵魂发问: JDK21发布后何时能上生产...

# 参考
1. https://jenkov.com/tutorials/java-concurrency/java-virtual-threads.html