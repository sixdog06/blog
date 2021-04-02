---
title: "Java多线程-高级"
date: 2020-12-10
draft: false
toc: true
categories: ["学习笔记"]
tags: ["Java"]
---

## 继续卖票
高内聚低耦合, 线程操作资源类. 操作指线程对外暴露的调用方法(高内聚). 线程之间低耦合. 
```
public class SaleTicket {
    public static void main(String[] args) {
        Ticket ticket = new Ticket();
        new Thread(new Runnable() {
            @Override
            public void run() {
                for (int i = 1; i < 40; i++) {
                    ticket.saleTicket();
                }
            }
        }, "A").start();
        new Thread(new Runnable() {
            @Override
            public void run() {
                for (int i = 1; i < 40; i++) {
                    ticket.saleTicket();
                }
            }
        }, "B").start();
        new Thread(new Runnable() {
            @Override
            public void run() {
                for (int i = 1; i < 40; i++) {
                    ticket.saleTicket();
                }
            }
        }, "C").start();
    }
}

class Ticket { //资源类

    private int number = 30;
    public synchronized void saleTicket() {
        if (number > 0) {
            System.out.println(Thread.currentThread().getName() + " sale: no." + (number--) + ", remain: " + number);
        }
    }
}
```

用`lock`和lambda替换`synchronized`. 其中lambda可以快速实现`@functionalInterface`函数式接口, 也就是除了default方法/static方法之外只有一个**没有实现的方法**. 括号就对应函数参数, 中括号内就是函数体. 
```
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class SaleTicket {
    public static void main(String[] args) {
        Ticket ticket = new Ticket();
        new Thread(() -> {
            for (int i = 1; i < 40; i++) {
                ticket.saleTicket();
            }
        }, "A").start();
        new Thread(() -> {
            for (int i = 1; i < 40; i++) {
                ticket.saleTicket();
            }
        }, "B").start();
        new Thread(() -> {
            for (int i = 1; i < 40; i++) {
                ticket.saleTicket();
            }
        }, "C").start();
    }
}

class Ticket { //资源类

    private int number = 30;
    private Lock lock = new ReentrantLock();
    public void saleTicket() { //参照文档
        lock.lock();
        try {
            if (number > 0) {
                System.out.println(Thread.currentThread().getName() + " sale: no." + (number--) + ", remain: " + number);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }
}
```

观察Thread.State, 发现其对应6种状态: NEW/RUNNABLE/BLOCKED/WAITING/TIMED_WAITING/TERMINATED. 其中WAITING是一直等待, 而TIMED_WAITING是等待一段时间自唤醒.

## 线程间通信(生产者/消费者)
条件判断时, 必须在while中. 否则被唤醒时, if内的条件可能根本没有改变, 所以需要用while再次进行判断.
```
public class ThreadWaitNotify {
    public static void main(String[] args) {
        Airconditioner aircondition = new Airconditioner();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    Thread.sleep(300);
                    aircondition.increment();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"A").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    Thread.sleep(400);
                    aircondition.decrement();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"B").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    Thread.sleep(500);
                    aircondition.increment();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"C").start();

        new Thread(()->{
            for (int i = 1; i <= 10; i++) {
                try {
                    Thread.sleep(600);
                    aircondition.decrement();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        },"D").start();
    }
}

class Airconditioner {
    private int number = 0;

    public synchronized void increment() throws Exception{
        while (number != 0) this.wait(); //1.判断, 必须用while! 防止虚假唤醒
        number++; //2.加
        System.out.println(Thread.currentThread().getName()+"\t"+number);
        this.notifyAll(); //3.通知
    }
    public synchronized void decrement() throws Exception{

        while (number == 0) this.wait(); //1.判断
        number--; //2.减
        System.out.println(Thread.currentThread().getName()+"\t"+number);
        this.notifyAll(); //3.通知
    }
}
```

用lock(Condition)写, `class Airconditioner`改为如下形式. 从synchronized/wait/notify到lock/await/signal. 如果多个线程想精确的按`顺序执行, 将number按顺序设置即可. 
```
class Airconditioner{
    private int number = 0;
    private Lock lock = new ReentrantLock();
    private Condition condition = lock.newCondition(); //用condition替换

    public void increment() throws Exception{
        lock.lock();
        try {
            while (number != 0) { //不是0才执行
                condition.await(); //this.wait();
            }
            number++; //2.加
            System.out.println(Thread.currentThread().getName() + "\t" + number);
            condition.signalAll(); //this.notifyAll(); //3.通知
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }
    public void decrement() throws Exception{
        lock.lock();
        try {
            while (number == 0) {
                condition.await(); //this.wait(); //1.判断
            }
            number--; //2.减
            System.out.println(Thread.currentThread().getName() + "\t" + number);
            condition.signalAll(); //this.notifyAll(); //3.通知
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }
}
```

> juc中有枚举类`public enum TimeUnit`, 比`Thread.sleep()`, 能够更精确地控制时间. 比如`TimeUnit.SECONDS.sleep(2);`

## 8锁例题
```
import java.util.concurrent.TimeUnit;

public class Lock8 {
    public static void main(String[] args) throws Exception{
        Phone phone = new Phone();
        Phone phone2 = new Phone();
        new Thread(()->{
            try {
                phone.sendEmail();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }, "A").start();

//        Thread.sleep(100);

        new Thread(()->{
            try {
                phone.sendMs(); //phone2.sendMs();
            } catch (Exception e) {
                e.printStackTrace();
            }
        },"B").start();

//        Thread.sleep(100);

        new Thread(()->{
            try {
                phone.sayHello();
            } catch (Exception e) {
                e.printStackTrace();
            }
        },"c").start();
    }
}

class Phone {
    public synchronized void sendEmail() throws InterruptedException {
        TimeUnit.SECONDS.sleep(4);
        System.out.println("Send EMail");
    }

    public synchronized void sendMs() throws InterruptedException {
        System.out.println("Send Message");
    }

    public void sayHello() throws InterruptedException {
        System.out.println("Say Hello");
    }
}
}
```
1. 标准访问(资源类无delay), 按顺序打印. 先打印`Send EMail`. 
2. 邮件设置暂停4秒方法`TimeUnit.SECONDS.sleep(4);`, 先打印`Send EMail`. 同上. 因为`synchronized`锁的是整个实例对象.
3. 2的基础上, 没有`synchronized`的`sayHello()`不会被影响, 会先打印.
4. 两个对象`phone`和`phone2`互相没有影响, 因为是两个实例对象.

因为在多个`synchronized`方法存在的情况下, 一个线程调用了其中一个资源类, 其他线程就被等待了, 因为`synchronized`锁的实际上是当前对象`this`, 那么其他`synchronized`方法都没法有其他线程进入. 非`synchronized`可以有线程进入.

5. 两个静态同步方法, 同一个手机, 先打印`Send EMail`, 因为锁的是同一个字节码对象(类本身).
6. 两个静态同步方法, 两个手机(`phone2.sendMs()`), 先打印`Send EMail`, 因为锁的是同一个字节码对象(类本身).

`synchronized`在1234例子中, 锁的是this, 对于同步代码块, 锁的是括号中的对象(一般是this或者自己建的obj), 但是对于静态同步方法, 锁的就是.class.

7. 一个静态同步方法, 一个普通同步方法, 同一个手机, 先打印`Send Message`
8. 一个静态同步方法, 一个普通同步方法, 二个手机, 先打印`Send Message`

this/.class是两个东西, 所以静态同步方法和普通同步方法互相没有影响. 并且即使静态同步方法对应的**实例化对象**不同, 锁`static`依然是对象相同的.class.

## 不安全的集合
### ArrayList
用ArrayList会出现`Exception in thread "7" java.util.ConcurrentModificationException`. 用`Vector`(add加了`synchronized`又会导致效率降低). 所以用juc的`CopyOnWriteArrayList`.
```
public class NotSafeDemo {
    public static void main(String[] args) {
        List<String> list = new CopyOnWriteArrayList<>();//Collections.synchronizedList(new ArrayList<>());//new Vector<>();//new ArrayList<>();
        for (int i = 1; i <= 10; i++) {
            new Thread(() -> {
                list.add(UUID.randomUUID().toString().substring(0, 3)); //生成随机数
                System.out.println(list);
            }, String.valueOf(i)).start();
        }
    }
}
```

其中的`CopyOnWriteArrayList`的`add`如下, 所以说这是一个写时复制的容器.
```
public boolean add(E e) {
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
        Object[] elements = getArray(); //得到当前的array
        int len = elements.length; //得到长度
        Object[] newElements = Arrays.copyOf(elements, len + 1); //复制到newElements并多padding一个null用来添加
        newElements[len] = e; //null改为add的元素
        setArray(newElements); //替换原array
        return true;
    } finally {
        lock.unlock();
    }
}
```

### HashMap
```
public class NotSafeDemo {
    public static void main(String[] args) {
        Map<String, String> map = new ConcurrentHashMap<>(); //new HashMap<>();
        for (int i = 1; i <= 10; i++) {
            new Thread(() -> {
                map.put(Thread.currentThread().getName(), UUID.randomUUID().toString().substring(0, 3)); //生成随机数
                System.out.println(map);
            }, String.valueOf(i)).start();
        }
    }
}
```

## Callable
比Runnable多了返回值(带泛型), 可以抛异常, 并且用`call`替代了`run`. `FutureTask`的构造器是`public FutureTask(Callable<V> callable)`, 并且实现了`RunnableFuture<V>`, 而`RunnableFuture<V>`继承了`Runnable`. 所以就可以通过`FutureTask`建立多线程.
```
public class CallableDemo {
    public static void main(String[] args) throws Exception{
        FutureTask futureTask = new FutureTask(new MyThread());
        new Thread(futureTask, "A").start();
        new Thread(futureTask, "B").start();
        System.out.println(futureTask.get());
    }
}

class MyThread implements Callable<Integer> {
    @Override
    public Integer call() throws Exception {
        System.out.println("in Callable");
        TimeUnit.SECONDS.sleep(3);
        return 233;
    }
}
```

注意这里的`in Callable`只会被打印一次(Java有缓存, ~~这里可以深究~~). get方法一般放在最后, 防止一直等待线程执行完成.

## juc的辅助类
### CountDownLatch
线程调用`countDownLatch.await()`时, 这些线程会阻塞. 其他线程调用countDown方法会将计数器减1, 当计数器的值变为0时, 前面的因为`await`阻塞的线程被唤醒. 下面的例子模拟了人必须在关门前离开屋子的例子, 可以看到main线程最后才结束. 如果不加则`door close`可能会出现在任何位置.
```
public class CountDownLatchDemo {
    public static void main(String[] args) throws InterruptedException {
        CountDownLatch countDownLatch = new CountDownLatch(6);
        for (int i = 1; i <= 6; i++) {
            new Thread(()->{
                System.out.println(Thread.currentThread().getName()+"\tleave");
                countDownLatch.countDown();
            },String.valueOf(i)).start();
        }
        countDownLatch.await();
        System.out.println(Thread.currentThread().getName()+"\tdoor close");
    }
}
```

### CyclicBarrier
执行完之后阻塞, 等待所有线程执行好了, 包括包括构造器中的Runnable下的run. 和`CyclicBarrier`对比, 一个await在里面, 一个await在外面.ß
```
public class CyclicBarrierDemo {
    public static void main(String[] args) {
        CyclicBarrier cyclicBarrier = new CyclicBarrier(9, ()->{System.out.println("gogogo");});
        for (int i = 9; i > 0; i--) {
            final int ii = i;
            new Thread(() -> {
                System.out.println(Thread.currentThread().getName()+ " " + ii);
                try {
                    cyclicBarrier.await();
                } catch (InterruptedException | BrokenBarrierException e) {
                    e.printStackTrace();
                }
            }, String.valueOf(i)).start();
        }
    }
}
```


### Semaphore
抢车位模拟, `acquire`使信号量减1, 信号量为0, 则等待释放; `release`使信号量加1. 回想linux0.11中进程的信号量, 主要是做互斥量使用, 而这里主要是为了**控制线程数量(并发控制)**. 如果等于`Semaphore(1);`, 就和`synchronized`上锁功能相同.
```
public class SemaphoreDemo {
    public static void main(String[] args) throws InterruptedException {
        Semaphore semaphore = new Semaphore(3); //3个空车位
        for (int i = 1; i < 10; i++) {
            new Thread(() -> {
                try {
                    semaphore.acquire();
                    System.out.println(Thread.currentThread().getName() + " get one place");
                    TimeUnit.SECONDS.sleep(3);
                    System.out.println(Thread.currentThread().getName() + " leaving");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    semaphore.release();
                }
            }, String.valueOf(i)).start();
        }
    }
}
```

## ReadWriteLock
读-读操作应该是可以共存的, 互相之间不用阻塞. 而读-写/写-写才应该阻塞. 这个情况下可以用`ReadWriteLock readWriteLock = new ReentrantReadWriteLock();`, 读写锁.
```
public class ReadWriteLockDemo {
    public static void main(String[] args) {
        MyCache myCache = new MyCache();
        for (int i = 1; i <= 5; i++) {
            final int tempInt = i;
            new Thread(()->{
                myCache.put(tempInt+"", tempInt+"");
            },String.valueOf(i)).start();
        }
        for (int i = 1; i <= 5; i++) {
            final int tempInt = i;
            new Thread(()->{
                myCache.get(tempInt + "");
            },String.valueOf(i)).start();
        }
    }
}

class MyCache {

    private volatile Map<String, Object> map = new HashMap<>();
    private ReadWriteLock readWriteLock = new ReentrantReadWriteLock();

    public void put(String key, Object value) {
        readWriteLock.writeLock().lock();
        try {
            System.out.println(Thread.currentThread().getName() + " start to write" + key);
            try {
                TimeUnit.MICROSECONDS.sleep(300);
            } catch (Exception e) {
                e.printStackTrace();
            }
            map.put(key, value);
            System.out.println(Thread.currentThread().getName() + " finish write");

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            readWriteLock.writeLock().unlock();
        }
    }

    public void get(String key) {
        readWriteLock.readLock().lock();
        try {
            System.out.println(Thread.currentThread().getName() + " read data");
            Object result = map.get(key);
            System.out.println(Thread.currentThread().getName() + " finish read" + result);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            readWriteLock.readLock().unlock();
        }
    }
}
```

## BlockingQueue
了解线程池之前要先搞懂阻塞队列. `BlockingQueue`是`Queue`的子接口. 可以控制阻塞队列的大小. 常用实现类有`ArrayBlockingQueue`(数组存储)和`LinkedBlockingDeque`(链表存储). `add(e)/remove()/element()`会报错, `offer(e)`会返回true or false, poll返回null. put(e)/take()会阻塞. `boolean offer(E e, long timeout, TimeUnit unit)/E poll(long timeout, TimeUnit unit)`可控制超时等待时间.

## 线程池
线程复用, 控制最大并发数, 管理线程. 下面的代码中, 即使循环到10, 但是始终只会有5个线程在跑.
```
public class ThreadPoolDemo {
    public static void main(String[] args) {
        ExecutorService threadPool = Executors.newFixedThreadPool(5); //1.多线程
        //ExecutorService threadPool = Executors.newSingleThreadExecutor(); //2.一个线程
        //ExecutorService threadPool = Executors.newCachedThreadPool(); //3.n线程, 可伸缩, 如果慢一点(加delay), 会发现线程数都减少了

        try {
            for (int i = 1; i <= 10 ; i++) {
                threadPool.execute(() -> {
                    System.out.println(Thread.currentThread().getName());
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            threadPool.shutdown();
        }
    }
}
```

而这三种方法底层都是调用了`ThreadPoolExecutor`, 看似是不同的构造器, 实际上最终都用了调用了`this(7个参数)`的按个构造器, 如下. (源码的@param解释得很清楚).
```
public ThreadPoolExecutor(int corePoolSize, //线程池中常驻核心线程数
                            int maximumPoolSize, //线程池能同时容纳的最大线程数, 大于1
                            long keepAliveTime, //多余空闲线程的存活时间, 如果线程数比核心线程大, 则超时的就要销毁, 直到达到corePoolSize
                            TimeUnit unit, //keepAliveTime单位
                            BlockingQueue<Runnable> workQueue, //被提交但是没有执行的任务
                            ThreadFactory threadFactory, //生成线程的工厂
                            RejectedExecutionHandler handler) { //the handler to use when execution is blocked, because the thread bounds and queue capacities are reached, 队列满了怎么拒绝新来的Runnable
    if (corePoolSize < 0 ||
        maximumPoolSize <= 0 ||
        maximumPoolSize < corePoolSize ||
        keepAliveTime < 0)
        throw new IllegalArgumentException();
    if (workQueue == null || threadFactory == null || handler == null)
        throw new NullPointerException();
    this.acc = System.getSecurityManager() == null ?
            null :
            AccessController.getContext();
    this.corePoolSize = corePoolSize;
    this.maximumPoolSize = maximumPoolSize;
    this.workQueue = workQueue;
    this.keepAliveTime = unit.toNanos(keepAliveTime);
    this.threadFactory = threadFactory;
    this.handler = handler;
}
```

1. 创建线程池后, 等待请求.
2. `execute(Runnable command)`创建请求. 运行线程数小于corePoolSize->创建线程执行任务; 运行线程数大于等于corePoolSize->任务放入阻塞队列; 队列已满并且运行的线程数量小于maximumPoolSize, 创建非核心线程执行任务; 队列已满并且运行的线程数量大于等于maximumPoolSize->线程池启动饱和和拒绝策略在执行.
3. 当一个线程完成任务, 它会从队列中取下一个任务来执行.
4. 一个线程空闲时间超过keepAliveTime, 判断: 当前线程数大于corePoolSize, 扩容的线程数被停掉. 所以线程池完成任务后, 总会回到corePoolSize大小.

而阿里开发手册要求只能用`ThreadPoolExecutor`自定义创建线程池. 因为`FixedThreadPool`和 `SingleThreadPool`允许的请求队列长度为`Integer.MAX_VALUE`, 可能会堆积大量的请求并导致OOM, CachedThreadPool允许的创建线程数量为Integer.MAX_VALUE, 可能会创建大量的线程并导致OOM.
```
public class ThreadPoolDemo {
    public static void main(String[] args) {
        ThreadPoolExecutor threadPool = new ThreadPoolExecutor(
                2,
                3,
                2L,
                TimeUnit.SECONDS,
                new LinkedBlockingDeque<>(3), //原Integer.MAX_VALUE
                Executors.defaultThreadFactory(),
                new ThreadPoolExecutor.AbortPolicy());
        try {
            for (int i = 1; i <= 10; i++) { //报错RejectedExecutionException
                threadPool.execute(() -> {
                    System.out.println(Thread.currentThread().getName());
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            threadPool.shutdown();
        }
    }
}
```

上面代码用的`AbortPolicy()`报错, 因为7>阻塞队列大小+maximumPoolSize. 有以下4种拒绝策略.
- `AbortPolicy()`: RejectedExecutionException阻止运行
- `CallerRunsPolicy()`: 将某任务回退给调用者, 也就说把任务回退给main, 让main去执行整个线程的任务
- `DiscardOldestPolicy()`: 抛弃等待最久的任务
- `DiscardPolicy`: 丢弃无法处理的任务, 不处理也不抛异常, 如果允许任务丢失吗, 这就是最好的策略

> `Runtime.getRuntime().availableProcessors()`可以看到核心数量. CPU密集型一般maximumPoolSize=核心数+1, i/o密集型: CPU核数除以阻塞系数

## 分支合并框架
`ForkJoinPool`继承了`AbstractExecutorService`, `AbstractExecutorService`实现了`ExecutorService`. 下面代码是计算等差数列, 前半部分用t1计算, 后半部分t2计算.
```
public class ForkJoinDemo {
    public static void main(String[] args) throws Exception {
        MyTask myTask = new MyTask(0, 100);
        ForkJoinPool threadPool = new ForkJoinPool();
        ForkJoinTask<Integer> forkJoinTask = threadPool.submit(myTask);
        System.out.println(forkJoinTask.get());
        threadPool.shutdown();
    }
}

class MyTask extends RecursiveTask<Integer> {

    private static final Integer ADJUST_VALUE = 10;
    private int begin, end, res;

    public MyTask(int begin, int end) {
        this.begin = begin;
        this.end = end;
    }

    @Override
    public Integer compute() {
        if ((end - begin) <= ADJUST_VALUE) {
            for (int i = begin; i <= end; i++) {
                res = res + i;
            }
        } else {
            int middle = (end + begin) / 2;
            MyTask t1 = new MyTask(begin, middle);
            MyTask t2 = new MyTask(middle + 1, end);
            t1.fork();
            t2.fork();
            res = t1.join() + t2.join();
        }
        return res;
    }
}
```

## 异步回调
```
public class CompletableFutureDemo {
    public static void main(String[] args) throws Exception{
        CompletableFuture<Void> completableFuture = CompletableFuture.runAsync(() -> {
            System.out.println(Thread.currentThread().getName() + " no return.");
        });
        completableFuture.get();
        CompletableFuture<Integer> completableFuture2 = CompletableFuture.supplyAsync(() -> { //异步调用
            System.out.println(Thread.currentThread().getName() + " has return");
            //int a = 10/0; //产生异常
            return 233; //正常返回
        });

        System.out.println(completableFuture2.whenComplete((t, u) -> {
           System.out.println("t: "+t); //正常打印
           System.out.println("u: "+u); //异常打印
        }).exceptionally(f -> { //异常
            System.out.println("exception: "+f.getMessage());
            return 2333; //异常返回
        }).get());
    }
}
```

## 参考
1. Java核心技术
2. [juc与并发编程](https://www.bilibili.com/video/BV1vE411D7KE?p=39)
3. Java并发编程实战