---
title: "Java Concurrency in Practice Chapter4-Composing Objects"
date: 2022-02-01
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
---

这一章介绍一些组合模式, 让我们把一个类设计成线程安全的类, 避免在每一次访问内存时都要去分析线程安全性, 平切在维护这些类时不会破坏线程安全性.

### Designing a thread-safe class
设计线程安全的类, 需要考虑3个基本要素. *e.g. Counter*.
- 构成对象状态的**所有变量**
- 约束状态变量的**不变性条件**
- 建立对象状态的并发访问管理策略
```
/**
 * 监视器模式的线程安全计数器
 * synchronization policy defines how an object coordinates access to its state without
 * violating its invariants or postconditions. It specifies the combination of immutability,
 * thread confinement, and locking.
 */
public final class Counter {

    /**
     * long是primitive type, 所以value是构成这个对象的所有状态
     */
    private long value = 0;

    public synchronized long getValue() {
        return value;
    }

    public synchronized long increment() {
        if (value == Long.MAX_VALUE) {
            throw new IllegalStateException("counter overflow");
        }
        return ++value;
    }
}
```

### Instance confinement
确保一个对象只能有单个线程访问. 封装在对象内部的数据, 可以把数据的访问限制在对象的方法上. *e.g. PersonSet*. 
```
public class PersonSet {

    /**
     * HashSet不是线程安全, 但是访问的方法线程安全, 保证了mySet线程安全
     * 注意这里的Person的线程安全性没有做假设
     */
    private final Set<Person> mySet = new HashSet<>();

    public synchronized void addPerson(Person p) {
        mySet.add(p);
    }

    public synchronized boolean containsPerson(Person p) {
        return mySet.contains(p);
    }
}
```

Java的监视器模式, 用一把内部锁来封装内部的mutable state. *e.g. PrivateLock*.  *e.g. MonitorVehicleTracker*.
```
/**
 * Guarding state with a private lock
 */
public class PrivateLock {

    private final Object myLock = new Object();

    Widget widget;

    void someMethod() {
        synchronized (myLock) {
            // Access or modify the state of widget...
        }
    }
}
```
```
/**
 * 车辆追踪器, 监视器模式, 保证在修改MutablePoint时线程安全
 */
public class MonitorVehicleTracker {

    /**
     * 坐标, 这个locations和MutablePoint都不会publish
     */
    private final Map<String, MutablePoint> locations;

    public MonitorVehicleTracker(Map<String, MutablePoint> locations) {
        this.locations = deepCopy(locations);
    }
    
    /**
     * 传的是new出来的locations, 而不是这个类的域
     */
    public synchronized Map<String, MutablePoint> getLocations() {
        return deepCopy(locations);
    }
    
    /**
     * 每次都传出新的对象, 保证内部的MutablePoint不被发布
     */
    public synchronized MutablePoint getLocation(String id) {
        MutablePoint loc = locations.get(id);
        return loc == null ? null : new MutablePoint(loc);
    }

    public synchronized void setLocation(String id, int x, int y) {
        MutablePoint loc = locations.get(id);
        if (loc == null) {
            throw new IllegalArgumentException("No such ID: " + id);
        }
        loc.x = x;
        loc.y = y;
    }

    private static Map<String, MutablePoint> deepCopy(Map<String, MutablePoint> m) {
        Map<String, MutablePoint> result = new HashMap<>(5);
        for (String id : m.keySet()) {
            result.put(id, new MutablePoint(m.get(id)));
        }
        return Collections.unmodifiableMap(result);
    }
}

/**
 * 这个类不是线程安全的, 但是追踪器类安全
 */
public class MutablePoint {

    public int x, y;

    public MutablePoint() {
        x = 0;
        y = 0;
    }

    public MutablePoint(MutablePoint p) {
        this.x = p.x;
        this.y = p.y;
    }
}
```

### Delegating thread safety
基于委托的车辆追踪器, *DelegatingVehicleTracker*. locations委托给ConcurrentMap保证线程安全. 这个类中只有单个状态. 还有一种情况是一个类需要多个独立且线程安全的状态变量, 那么可以把主类的线程安全委托给这些变量. 但如果这些变量互相有依赖关系, 限制条件(比如一个必须大于另一个). 那么仍然需要加锁. 
```
public class DelegatingVehicleTracker {

    /**
     * Point is immutable, 线程安全
     */
    private final ConcurrentMap<String, Point> locations;

    /**
     * unmodifiableMap is immutable
     */
    private final Map<String, Point> unmodifiableMap;

    public DelegatingVehicleTracker(Map<String, Point> points) {
        locations = new ConcurrentHashMap<>(points);
        // unmodifiableMap是locations的view, 虽然可以实时更新, 但可能存在不一致的view, 因为view会跟着locations变.
        unmodifiableMap = Collections.unmodifiableMap(locations);
    }

    public Map<String, Point> getLocations() {
        return unmodifiableMap;
        // 返回浅拷贝, 因为value不可变, 所以只需要赋值结构即可. 这样保证复制过来的view不发生变化.
        // return Collections.unmodifiableMap(new HashMap<String, Point>(locations));
    }

    public Point getLocation(String id) {
        return locations.get(id);
    }

    public void setLocation(String id, int x, int y) {
        if (locations.replace(id, new Point(x, y)) == null) {
            throw new IllegalArgumentException("invalid vehicle name: " + id);
        }
    }
}

/**
 * immutable class
 */
public class Point {

    public final int x, y;

    public Point(int x, int y) {
        this.x = x;
        this.y = y;
    }
}
```

如果保证Point的线程安全, 也可以发布Point, *e.g. PublishingVehicleTracker*. 和DelegatingVehicleTracker的区别是这个`SafePoint`是可以改变的, 因为读写的方法都加了锁, 所以还是能保证线程安全. 
```
/**
 * SafePoint被发布的版本, SafePoint本身线程安全, 所以允许可变. 可以改变车辆的位置.
 */
public class PublishingVehicleTracker {

    private final Map<String, SafePoint> locations;

    private final Map<String, SafePoint> unmodifiableMap;

    public PublishingVehicleTracker(Map<String, SafePoint> locations) {
        this.locations = new ConcurrentHashMap<>(locations);
        this.unmodifiableMap = Collections.unmodifiableMap(this.locations);
    }

    public Map<String, SafePoint> getLocations() {
        return unmodifiableMap;
    }

    public SafePoint getLocation(String id) {
        return locations.get(id);
    }

    public void setLocation(String id, int x, int y) {
        if (!locations.containsKey(id)) {
            throw new IllegalArgumentException("invalid vehicle name: " + id);
        }
        locations.get(id).set(x, y);
    }
}

/**
 * 可变, 但依然线程安全
 */
public class SafePoint {

    private int x, y;

    private SafePoint(int[] a) {
        this(a[0], a[1]);
    }

    public SafePoint(SafePoint p) {
        this(p.get());
    }

    public SafePoint(int x, int y) {
        this.x = x;
        this.y = y;
    }

    public synchronized int[] get() {
        return new int[] {x, y};
    }

    public synchronized void set(int x, int y) {
        this.x = x;
        this.y = y;
    }
}
```

### Adding functionality to existing thread-safe classes
如何对已经有的线程安全类增加更多的功能, 比如给一个list增加`如果没有该元素则添加的功能`. 最简单的方法是用子类去扩展基类的方法, 并对子类的方法进行加锁, 这种方法的问题是如果基类的同步策略改变, 会破怪子类的线程安全性. 还第一种方式是在使用端进行加锁, 但是要注意这个锁需要锁实例, 否则这个锁是无效的. 如*e.g. ListHelper*, 这样使用的问题是破坏封装性, 耦合度更高了. 更好的方法是Composition. *e.g. ImprovedList*. 这个例子使用监视器模式封装了List.
```
public class ListHelper {

    public List<String> list = Collections.synchronizedList(new ArrayList<>());
    
    /**
     * synchronized如果加载方法上, 锁就是ListHelper的实例, 和list中其他方法的锁不一样了, 无法保证线程安全
     */
    public boolean putIfAbsent(String x) {
        synchronized (list) {
            boolean absent = !list.contains(x);
            if (absent) {
                // do something
                return true;
            }
            return false;
        }
    }
}
```

```
public class ImprovedList<T> { //implements List<T> {

    private final List<T> list;
    
    /**
     * 这个地方传入后, 客户端就应该停止使用list
     * @param list
     */
    public ImprovedList(List<T> list) {
        this.list = list;
    }

    public synchronized boolean putIfAbsent(T x) {
        boolean contains = list.contains(x);
        if (contains) {
            list.add(x);
        }
        return !contains;
    }

    public synchronized void clear() {
        list.clear();
    }

    // ... similarly delegate other List methods
}
```

### Documenting synchronization policies
对类的线程安全性应该写文档, 同步策略是什么, 锁保护了哪些变量, 都应该注明. 如果遇到了没有写线程安全的类, 就假设不是线程安全的.

## Chapter5-Building Blocks
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
