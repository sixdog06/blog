---
title: "Java Concurrency in Practice Chapter5-Building Blocks"
date: 2022-02-05
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
---

上一章讲如何设计线程安全类, 这一章就介绍JDK中已有的线程安全类, 把线程安全性委托给这些类, 并让这些类区管理所有的状态, 从而使模块线程安全.

### Problems with synchronized collections
同之前提到过的一样, 同步容器类进行复合操作, 对调用方也可能是线程不安全的. 比如下面的代码. 解决方式是在调用端对复合操作加锁, 锁用`list`对象. 
```
public static Object getLast(Vector list) {
    int lastIndex = list.size() - 1;
    return list.get(lastIndex);
}   

public static void deleteLast(Vector list) {
    int lastIndex = list.size() - 1;
    list.remove(lastIndex);
}
```

即使是现在常用的并发容器类, 也会有复合操作带来的并发问题, 如下代码. 如果我们希望迭代期间加锁, 可以克隆这个容器, 去迭代副本, 因为副本封闭在单线程内, 保证线程安全. 还应注意如toString, hashCode, equals这些方法会隐式地进行迭代, 可能会带来线程安全问题. *e.g. HiddenIterator*.
```
public class HiddenIterator {

    private final Set<Integer> set = new HashSet<>();

    public synchronized void add(Integer i) {
        set.add(i);
    }

    public synchronized void remove(Integer i) {
        set.remove(i);
    }

    public void addTenThings() {
        Random r = new Random();
        // 这里的迭代加锁了, 线程安全
        for (int i = 0; i < 10; i++) {
            add(r.nextInt());
        }
        // 调用toString, 进行了间接的迭代操作, 线程不安全
        System.out.println("DEBUG: added ten elements to " + set);
    }
}
```
```
List<Widget> widgetList = Collections.synchronizedList(new ArrayList<>());
...
// May throw ConcurrentModificationException(一直持有锁消耗资源, 也有死锁的风险)
for (Widget w : widgetList) {
    doSomething(w);
}
```

### Concurrent collections
用并发容器替代同步容器, 可以极大提高伸缩性并降低风险. 比如使用`ConcurrentHashMap`, 它的原理是用了更细粒度的锁, 从而实现最大程度的共享. 但是对一些但是size/isEmpty的值不一定准确(这些方法在并发场景作用较小).

### Blocking queues and the producer-consumer pattern
阻塞队列可以用来实现生产者-消费者模式. *e.g. FileCrawler/Indexer*. 让对象安全地从生产者线程发布到消费者线程, 实现Serial thread confinement(串行的线程封闭). 对象虽然只属于单个线程, 但是可以通过安全地publish对象来转移所有权. 书里面还介绍了通过Deque实现work stealing, 也就是消费者访问自己的双端队列, 如果完成了工作, 就送其他消费者消费的双端队列末尾秘密地获取工作, 这就是工作密取. 
```
/**
 * 扫描本地文件并建立索引方便以后搜索, FileCrawler是生产者
 */
public class FileCrawler implements Runnable {

    private final BlockingQueue<File> fileQueue;

    private final FileFilter fileFilter;

    private final File root;

    public FileCrawler(BlockingQueue<File> fileQueue, FileFilter fileFilter, File root) {
        this.fileQueue = fileQueue;
        this.fileFilter = fileFilter;
        this.root = root;
    }

    @Override
    public void run() {
        try {
            crawl(root);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void crawl(File root) throws InterruptedException {
        File[] entries = root.listFiles(fileFilter);
        if (entries != null) {
            for (File entry : entries) {
                if (entry.isDirectory()) {
                    crawl(entry);
                } else if (!alreadyIndexed(entry)) {
                    fileQueue.put(entry);
                }
            }
        }
    }

    private boolean alreadyIndexed(File file) {
        return true;
    }
}

/**
 * Indexer是消费者, 拿消息队列的文件进行index
 */
public class Indexer {

    private final BlockingQueue<File> queue;

    public Indexer(BlockingQueue<File> queue) {
        this.queue = queue;
    }

    public void run() {
        try {
            while (true) {
                indexFile(queue.take());
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void indexFile(File file) {
        // do indexing
    }
}
```

### Blocking and interruptible methods
线程可能会因为等待i/o操作结束/等待获得一个锁等等而暂停执行, 如果方法被阻塞并抛出`InterruptedException`, 说明该方法是一个阻塞方法. 当阻塞方法被调用时, 最好的办法是传递`InterruptedException`给调用者(不捕获异常, 或捕获异常后再次抛出). 如果需要恢复中断(不能抛错的情况), 可以捕获Exception并尝试恢复中断*e.g. TaskRunnable*.
```
/**
 * 恢复中断
 */
public class TaskRunnable implements Runnable {

    BlockingQueue<String> queue;

    @Override
    public void run() {
        try {
            processTask(queue.take());
        } catch (InterruptedException e) {
            // restore interrupted status
            Thread.currentThread().interrupt();
        }
    }

    private void processTask(String take) {
        // do something
    }
}
```

### Synchronizers
这一小节介绍了一些基本的同步工具类. 第一种是`Latches`, 它是一种**闭锁(这种锁在到达结束状态之前不会允许线程通过, 结束状态之后允许所有线程通过并且不再关闭)**. *e.g. TestHarness*. `FutureTask`也可以用作闭锁, 调用get时, 若任务已完成, 则立刻返回结果. 若任务还未完成, 就会阻塞, 直到任务完成后返回结果或者抛出异常. *e.g. Preloader*.
```
/**
 * 闭锁
 */
public class TestHarness {

    public long timeTasks(int nThreads, final Runnable task) throws InterruptedException {
        // 初始值为1
        final CountDownLatch startGate = new CountDownLatch(1);
        // 初始值为线程数
        final CountDownLatch endGate = new CountDownLatch(nThreads);
        for (int i = 0; i < nThreads; i++) {
            Thread t = new Thread() {

                @Override
                public void run() {
                    try {
                        // 在启动门上等待
                        startGate.await();
                        try {
                            task.run();
                        } finally {
                            // 结束门在每个线程结束后减1
                            endGate.countDown();
                        }
                    } catch (InterruptedException ignored) {
                    }
                }
            };
            t.start();
        }
        long start = System.nanoTime();
        // 启动门减1, 其他线程开始运行
        startGate.countDown();
        // 主线程等待, 其他线程全部运行结束后才会运行
        endGate.await();
        long end = System.nanoTime();
        return end - start;
    }
}
```

```
/**
 * 闭锁, 通过FutureTask
 */
public class Preloader {

    private final Thread thread = new Thread();

    private final FutureTask<ProductInfo> future = new FutureTask<>(new Callable<ProductInfo>() {

        @Override
        public ProductInfo call() {
            return loadProductInfo();
        }
    });

    public void start() {
        thread.start();
    }

    public ProductInfo get() throws InterruptedException, DataLoadException {
        try {
            // 在完成计算后返回结果(异步)
            return future.get();
        } catch (ExecutionException e) {
            Throwable cause = e.getCause();
            if (cause instanceof DataLoadException) {
                // 数据加载出错导致的exception(已知异常)
                throw (DataLoadException)cause;
            } else {
                throw launderThrowable(cause);
            }
        }
    }

    /**
     * 加载商品信息(一些运算逻辑)
     */
    private ProductInfo loadProductInfo() {
        return new ProductInfo();
    }

    /**
     * 一些异常处理
     */
    public static RuntimeException launderThrowable(Throwable t) {
        if (t instanceof RuntimeException) {
            return (RuntimeException) t;
        } else if (t instanceof Error) {
            throw (Error) t;
        } else {
            throw new IllegalStateException("Not unchecked", t);
        }
    }
}
```

`Semaphore`可以通过`permit`来实现资源池/对容器加边界. 通过构造函数传一个初值, 每次尝试调用`acquire`就会获取一个许可, 当调用结束后再次调用`release`释放许可. *e.g. BoundedHashSet*.
```
public class BoundedHashSet<T> {

    private final Set<T> set;

    private final Semaphore sem;

    /**
     * @param bound 信号量的限制值
     */
    public BoundedHashSet(int bound) {
        this.set = Collections.synchronizedSet(new HashSet<T>());
        sem = new Semaphore(bound);
    }

    public boolean add(T o) throws InterruptedException {
        sem.acquire();
        boolean wasAdded = false;
        try {
            wasAdded = set.add(o);
            return wasAdded;
        }
        finally {
            if (!wasAdded) {
                sem.release();
            }
        }
    }

    public boolean remove(Object o) {
        boolean wasRemoved = set.remove(o);
        if (wasRemoved) {
            sem.release();
        }
        return wasRemoved;
    }
}
```

### Building an efficient, scalable result cache
一步一步设计一个带缓存的计算系统.
```
/**
 * A为输入, V为输出
 */
public interface Computable<A, V> {

    /**
     * 计算逻辑
     */
    V compute(A arg) throws InterruptedException;
}

/**
 * 对整个compute进行加锁, 如果单个线程的操作时间很长, 导致阻塞其他线程, 反而可能比不缓存还慢. 不推荐这种写法
 */
public class Memoizer1<A, V> implements Computable<A, V> {

    private final Map<A, V> cache = new HashMap<A, V>();

    private final Computable<A, V> c;

    public Memoizer1(Computable<A, V> c) {
        this.c = c;
    }

    @Override
    public synchronized V compute(A arg) throws InterruptedException {
        V result = cache.get(arg);
        if (result == null) {
            result = c.compute(arg);
            cache.put(arg, result);
        }
        return result;
    }
}

/**
 * 相比Memoizer1, 虽然compute本身不会阻塞, 但是如果有某个消耗大量资源的运算在线程1,
 * 线程2不知道线程1正在计算, 会再次进行这个计算. 最好的方式是等待线程1计算结束后直接用
 * 缓存中线程1已计算好的结果
 */
public class Memoizer2<A, V> implements Computable<A, V> {

    private final Map<A, V> cache = new ConcurrentHashMap<A, V>();

    private final Computable<A, V> c;

    public Memoizer2(Computable<A, V> c) {
        this.c = c;
    }

    @Override
    public V compute(A arg) throws InterruptedException {
        V result = cache.get(arg);
        if (result == null) {
            result = c.compute(arg);
            cache.put(arg, result);
        }
        return result;
    }
}

public class Memoizer3<A, V> implements Computable<A, V> {

    private final Map<A, Future<V>> cache = new ConcurrentHashMap<>();

    private final Computable<A, V> c;

    public Memoizer3(Computable<A, V> c) {
        this.c = c;
    }

    @Override
    public V compute(final A arg) throws InterruptedException {
        Future<V> f = cache.get(arg);
        // 这里的if非原子, 所以两个线程可能依然会算相同的值(概率比Memoizer2小), 因为这个check-then-act复合操作不原子, 两
        // 个线程很有可能拿到相同的值, 重复计算
        if (f == null) {
            Callable<V> eval = new Callable<V>() {

                @Override
                public V call() throws InterruptedException {
                    return c.compute(arg);
                }
            };
            FutureTask<V> ft = new FutureTask<V>(eval);
            f = ft;
            cache.put(arg, ft);
            ft.run(); // call to c.compute happens here
        }
        try {
            // 计算结束了, 直接返回. 若未计算结束, 则等这个线程计算结果
            return f.get();
        } catch (ExecutionException e) {
            throw launderThrowable(e.getCause());
        }
    }
}

/**
 * 比Memoizer3更好的实现, 但是没有解决缓存缓存的问题. 可以通过Future的子类来设置过期时间从而实现过期
 */
public class Memoizer<A, V> implements Computable<A, V> {

    private final ConcurrentMap<A, Future<V>> cache = new ConcurrentHashMap<>();

    private final Computable<A, V> c;

    public Memoizer(Computable<A, V> c) {
        this.c = c;
    }

    @Override
    public V compute(final A arg) throws InterruptedException {
        while (true) {
            Future<V> f = cache.get(arg);
            if (f == null) {
                Callable<V> eval = new Callable<V>() {

                    @Override
                    public V call() throws InterruptedException {
                        return c.compute(arg);
                    }
                };
                FutureTask<V> ft = new FutureTask<V>(eval);
                // 避免重算
                f = cache.putIfAbsent(arg, ft);
                if (f == null) {
                    f = ft;
                    ft.run();
                }
            }
            try {
                return f.get();
            } catch (CancellationException e) {
                // 防止cache pollution, 因为异步计算可能会取消
                cache.remove(arg, f);
            } catch (ExecutionException e) {
                throw launderThrowable(e.getCause());
            }
        }
    }
}
```
