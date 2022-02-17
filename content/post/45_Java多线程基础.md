---
title: "Java多线程-基础"
date: 2020-11-30
draft: false
author: "小拳头"
categories: ["Java"]
---

## 创建
### 方式1
1. 创建继承Thread类的子类
2. 重写Thread类的run()
3. 创建Thread类的子类的对象
4. 通过此对象调用start()
```
public class ThreadBase {
    public static void main(String[] args) {
        MyThread t1 = new MyThread();
        //t1.start(); //启动线程, 并调用当前线程的run()
        new Thread() { //直接创建Thread的匿名子类也可以
            @Override
            public void run() {
                for (int i = 0; i < 100; i++) {
                    System.out.println("thread2" + "-" + i);
                }
            }
        }.start();
        for (int i = 0; i < 100; i++) {
            System.out.println("thread0" + "-" + i);
        }
    }
}

class MyThread extends Thread{
    @Override
    public void run() {
        for (int i = 0; i < 100; i++) {
            System.out.println("thread1" + "-" + i);
        }
    }
}
```

### 方式2
通过`Runnable`. `run()`中其实是`target.run()`(target不是null的前提下), 构造器`Thread(Runnable target)`, 所以`run()`执行的就是重写的那一个. 对于卖票问题, 多个线程就可以用同一个Thread类来实例化, 本来static的变量(剩余票数)就可以被共享, 改为非静态的属性.
```
public class ThreadBase {
    public static void main(String[] args) {
        MyThread MThread = new MyThread();
        Thread t1 = new Thread(MThread);
        t1.start();
        for (int i = 0; i < 100; i++) {
            System.out.println("thread0" + "-" + i);
        }
    }
}

class MyThread implements Runnable{
    @Override
    public void run() {
        for (int i = 0; i < 100; i++) {
            System.out.println("thread1" + "-" + i);
        }
    }
}
```

## 一些方法
- setName(): 设置当前线程名字
- getName(): 获取当前线程名字
- yield(): 释放CPU执行权
- join(): 在线程a中调用`b.join`, 则a阻塞, b执行完之后, a结束阻塞
- sleep(long millitime): 让当前线程睡眠一段时间
- Thread.currentThread().getName()
- stop(): 强制结束线程, **Deprecated**

## 调度
优先级最高是`MAX_PRIORITY: 10`, `MIN_PRIORITY: 1`, `NORM_PRIORITY: 5`(默认). 

可以用`getPriorty()`获取线程的优先级, `setPriority()`设置线程的优先级. 

## 线程的生命周期
新建 就绪 阻塞 运行 死亡

## 线程同步
卖票问题, 当一个线程操作票数`ticket`的时候 , 其他线程不能也进来, 否则就有概率错票或者重票. 所以要对下面不安全的程序进行修改.
```
public class ThreadBase {
    public static void main(String[] args) {
        MyThread MThread = new MyThread();
        Thread t1 = new Thread(MThread);
        Thread t2 = new Thread(MThread);
        t1.setName("1");
        t2.setName("2");
        t1.start();
        t2.start();
    }
}

class MyThread implements Runnable{
    private int ticket = 50;

    @Override
    public void run() {
        while (true) {
            if (ticket > 0) {
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                ticket--;
                System.out.println(Thread.currentThread().getName() + ": " + ticket);
            } else {
                break;
            }
        }
    }
}
```

可以用同步监视器`synchronized`来锁住**操作共享数据的代码块**, 任何一个类的对象都可以充当锁, 但是多个线程要共享同一把锁. 虽然保证了资源不会同时被多个线程操作, 但是在代码块内只有单个线程操作, 效率低.
```
class MyThread implements Runnable{
    private int ticket = 50;
    Object obj = new Object();

    @Override
    public void run() {
        while (true) {
            synchronized (obj) { //上锁, 因为用的Runnable实现, 所以直接写this也可以
                if (ticket > 0) {
                    try {
                        Thread.sleep(100);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    ticket--;
                    System.out.println(Thread.currentThread().getName() + ": " + ticket);
                } else {
                    break;
                }
            }
        }
    }
}
```

也可以锁某个方法.
```
class MyThread implements Runnable{
    private int ticket = 50;
    Object obj = new Object();

    @Override
    public void run() {
        while (true) {
            show();
        }
    }

    private synchronized void show() { //同步监视器是this(MThread), 继承Thread方式实现只能锁static方法, 保证锁是类本身
        if (ticket > 0) {
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            ticket--;
            System.out.println(Thread.currentThread().getName() + ": " + ticket);
        }
    }
}
```

## 死锁
两个线程都占用对方需要同步的资源, 导致两个线程同时阻塞, 互相等待. 所以我们希望能有手动的上锁和解锁, 如下. 通过`lock.unlock()`解锁. 一般先考虑lock再考虑同步代码块, 随后考虑锁方法. `ReentrantLock`是可重入锁, 包含一个有参构造器`public ReentrantLock(boolean fair)`, 默认`fair = false`. 如果设置为`true`, 则为公平锁, 也就是让等待时间最长的线程优先获取锁, 但是会一定程度上影响性能. 
```
import java.util.concurrent.locks.ReentrantLock;

public class DeadLock {
    public static void main(String[] args) {
        MyLock MThread = new MyLock();
        Thread t1 = new Thread(MThread);
        Thread t2 = new Thread(MThread);
        t1.setName("1");
        t2.setName("2");
        t1.start();
        t2.start();
    }
}

class MyLock implements Runnable{
    private int ticket = 50;
    private ReentrantLock lock = new ReentrantLock(true); //true使先进先出

    @Override
    public void run() {
        while (true) {
            try {
                lock.lock();
                if (ticket > 0) {
                    try {
                        Thread.sleep(100);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    ticket--;
                    System.out.println(Thread.currentThread().getName() + ": " + ticket);
                } else {
                    break;
                }
            } finally {
                lock.unlock();
            }
        }
    }
}
```

## 线程间通信
做前面的实验会发现有时候一个线程拿着锁一直不释放, 如果想他们交替执行, 除了lock使用公平锁之外, 也可以让线程之间通信. 这三个方法必须在同步代码块内或同步方法中, 并且**调用者必须是同步监视器本身**.
- wait(): 阻塞当前线程, 释放锁
- notify(): 唤醒被wait的一个线程, 如果有多个wait的线程, 就根据优先级唤醒
- notifyAll(): 唤醒所有wait的线程

```
public class ThreadCom {
    public static void main(String[] args) {
        MyThreadCom MThread = new MyThreadCom();
        Thread t1 = new Thread(MThread);
        Thread t2 = new Thread(MThread);
        t1.setName("1");
        t2.setName("2");
        t1.start();
        t2.start();
    }
}

class MyThreadCom implements Runnable{
    private int ticket = 50;
    Object obj = new Object();

    @Override
    public void run() {
        while (true) {
            synchronized (this) {
                notify();
                if (ticket > 0) {
                    try {
                        Thread.sleep(100);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    ticket--;
                    System.out.println(Thread.currentThread().getName() + ": " + ticket);
                    try {
                        wait();
                    }  catch (InterruptedException e) {
                        break;
                    }
                } else {
                    break;
                }
            }
        }
    }
}
```

## Callable创建线程
1. 创建Callable实现类, 并实现call方法
2. 创建Callable实现类的对象, 并将对象作为参数给FutureTask构造器中
1. 将FutureTask对象给Thread, 并start
2. Callable的call()方法返回值可以用get()获取

Callable比起Runnable增加了返回值, 可以抛异常, 并且支持泛型. 在juc包中.
```
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.FutureTask;

public class ThreadBase {
    public static void main(String[] args) {
        MyThread MThread = new MyThread();
        FutureTask futureTask = new FutureTask(MThread);
        new Thread(futureTask).start();
        try {
            Object sum = futureTask.get();
            System.out.println(sum);
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (ExecutionException e) {
            e.printStackTrace();
        }
    }
}

class MyThread implements Callable {
    @Override
    public Object call() throws Exception {
        int sum = 0;
        for (int i = 1; i <= 100; i++) {
            if (i % 2 == 0) {
                System.out.println(i);
                sum += i;
            }
        }
        return sum;
    }
}
```

## 线程池
提前创建多个线程, 放到线程池中, 使用时直接获取, 使用完放回池中. 避免重复的创建销毁. 
1. 创建线程池并指明线程数量
2. 实现Runnable或Callable接口实现类对象
3. 关闭连接池

```
import javax.xml.ws.Service;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ThreadPool {
    public static void main(String[] args) {
        ExecutorService service = Executors.newFixedThreadPool(10);
        service.execute(new NumberThread()); //Runnable
        //service.submit(); //Callable
        service.shutdown();
    }
}

class NumberThread implements Runnable {
    @Override
    public void run() {
        for(int i = 1; i <= 100; i++) {
            if (i % 2 == 0) {
                System.out.println(i);
            }
        }
    }
}
```

## 参考
1. [尚硅谷最新版宋红康JVM教程](https://www.bilibili.com/video/BV1Kb411W75N?p=406)
2. [The Java® Virtual Machine Specification](https://docs.oracle.com/javase/specs/jvms/se8/html/index.html)