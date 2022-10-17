---
title: "Java Concurrency in Practice-I.Fundamentals"
date: 2022-01-29
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
---

基础知识覆盖了书中的第二章到第五章. 第一章为粗略的介绍, 简单过一下就好.

## Chapter2-Thread Safety
这一节主要介绍线程安全的一些基本概念, 解释一些基本名词. 写线程安全的并发代码, 关键就是在访问共享资源时做好管理.

### Atomicity
在不同的线程访问一个资源时, 这个资源的状态应该是一致的, 类的行为和应该有的规范完全一致. 我认为简单地说, 就是这个类的功能不管是单线程还是并发, 都是正常的. **所以无状态对象一定安全**, 因为它没有域, 也没有对其他类的域的引用, 计算过程只在栈上的, 没有共享资源, 那么一定安全了. 当这个而无状态类有字段时, 可以用原子变量类, 如`AtomicLong`来保证原子性(读取-修改-写入). 这里要注意, 原子性只针对原子变量本身, 多个原子变量因为不应时序的调用, 不能保证线程安全. *e.g. AtomicTest*.
```
public class AtomicTest {

    /**
     * 使用原子变量类, 保证原子性
     */
    private final AtomicLong count = new AtomicLong(0);

    public long getCount() {
        return count.getAndIncrement();
    }
}
```

### Locking
可以用`synchronized(lock) {}`标注同步代码块, 并且这些**内置锁**是可重入的, 重入是指在一个线程中可以多次获取同一把锁, 也就是说锁的粒度是线程, 线程可以获得自己持有的锁. *e.g. Widgit*这个例子的子类的同步方法中调用父类的同步方法, 两个方法的方法体不同, 但是`this`是相同的, 所以实际上是重入了同一把锁. 可以看出, 有些地方写`ReentrantLock`和`synchronized`的区别是`synchronized`不可重入, 这种说法是错的! 只不过用`ReentrantLock`, 我们可以多次手动获取锁, 并且手动解锁. 
```
public class Widget {

    public synchronized void doSomething() {
        System.out.println(this + ": calling method(super)");
    }

    public static void main(String[] args) {
        LoggingWidget loggingWidget = new LoggingWidget();
        loggingWidget.doSomething();
    }
}

class LoggingWidget extends Widget {

    @Override
    public synchronized void doSomething() {
        System.out.println(this + ": calling method");
        // 调用父类的同步方法, 虽然方法不同, 但是this是用一个, 那么锁就是同一个
        super.doSomething();
    }
}
```

### Guarding state with locks
多个线程共享的变量应该由一个锁来保护, 反之不是多个线程共享的变量无需保护. 锁需要保护invariants(不变性条件)中的所有涉及的变量, 只保护一个变量是不够的. 即使像Vector类的所有方法都是`synchronized`方法2, 也不能保证如
```
if (!vector.contains(element)) {
    vector.add(element)
}
```
的复合操作原子.

> 对invariants这个概念, 可以将其理解为状态的不变. 简单说, 比如我们要求`a == 2 * b`, 那个在并发场景下, 这个两个变量共同组成了这个2倍等式的不变性条件

### Liveness and performance
*e.g. SynchronizedFactorizer*中对整个方法进行加锁, 让Servlet无法多线程处理任务, 这种粗粒度地对整个方法加锁非常不好. 而*e.g. CachedFactorizer*中, 把读写的操作分别加锁, 会有更好的性能. 实际上只有读写的时候才会访问共享的变量, 而`doGet`代码块内的局部变量都没有被发布, 在自己的线程中是安全的.
```
/**
 * 粗粒度地对整个方法加锁(很不好)
 */
public class SynchronizedFactorizer extends HttpServlet {
    
    private BigInteger lastNumber;
    
    private BigInteger[] lastFactors;
    
    @Override
    protected synchronized void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        BigInteger i = (BigInteger)req.getAttribute("i");
        PrintWriter writer = resp.getWriter();
        if (i.equals(lastNumber)) {
            writer.print(Arrays.toString(lastFactors));
        } else {
            BigInteger[] factors = factor(i);
            lastNumber = i;
            lastFactors = factors;
            writer.print(Arrays.toString(factors));
        }
        super.doGet(req, resp);
    }
    
    /**
     * 因式分解, 还没实现
     */
    private BigInteger[] factor(BigInteger number) {
        return new BigInteger[]{};
    }
}
```

```
/**
 * 带缓存且线程安全的因式分解Servlet, 对{@code SynchronizedFactorizer}进行优化
 * 既没有使用原子变量类, 也没有对整个方法加锁, 把栈上变量(每个线程独有的变量)排除在锁之外
 * 符合我们非共享不加锁的原则
 */
public class CachedFactorizer extends HttpServlet {

    private BigInteger lastNumber;

    private BigInteger[] lastFactors;
    
    /**
     * 命中的数量
     */
    private long hits;
    
    /**
     * 缓存命中的数量
     */
    private long cacheHits;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        BigInteger i = (BigInteger)req.getAttribute("i");
        // factor只在单线程的栈上使用, 不被发布, 无需加锁
        BigInteger[] factors = null;
        // 查询, 先检查后执行
        synchronized (this) {
            ++hits;
            if (i.equals(lastNumber)) {
                ++cacheHits;
                factors = lastFactors.clone();
            }
        }

        if (factors == null) {
            factors = factor(i);
            // 修改, 实时更新缓存
            synchronized (this) {
                lastNumber = i;
                lastFactors = factors.clone();
            }
        }
        PrintWriter writer = resp.getWriter();
        writer.print(Arrays.toString(factors));
        super.doGet(req, resp);
    }

    public synchronized long getHits() {
        return hits;
    }

    public synchronized double getCacheHitRatio() {
        return (double)cacheHits / (double)hits;
    }

    /**
     * 因式分解, 还没实现
     */
    private BigInteger[] factor(BigInteger number) {
        return new BigInteger[]{};
    }
}
```

## Chapter3-Sharing Objects
这一章主要讲如何安全地共享资源, 来保证线程安全性. 换个角度理解这句话, 如果资源不被共享, 那么也能保证线程安全.

### Visibility
没有同步机制, 两个线程的执行顺序是无法判断的(因为重排序), 这时候做内存操作很容易出错, 读的值可能是更新前的**失效数据**, 也可能是更新后的, 影响Visibility. *e.g. NoVisibility*. 在JavaBean中, 如果要对一个值的get和set进行同步, 那么`synchronized`需要同时加在在getter和setter方法上. **加锁不仅要保证互斥, 也要保证内存可见性.**
```
/**
 * 没有同步的情况下共享变量
 * ReaderThread读不到ready为true的值, 导致程序无法终止. 也有可能读到了ready但是读不到number的值
 */
public class NoVisibility {

    private static boolean ready;

    private static int number;

    private static class ReaderThread extends Thread {

        @Override
        public void run() {
            while (!ready) {
                // 让该线程回到ready状态, 实际生产中几乎不会用
                Thread.yield();
            }
            System.out.println(number);
        }
    }

    public static void main(String[] args) {
        new ReaderThread().run();
        number = 42;
        ready = true;
    }
}
```

> synchronized方法锁的的是`this`实例, 静态synchronized方法锁的是`ClassName.class`实例. 和对方法内部整个代码块加锁的写法是等价的.

失效数据过期了但是这个值也是有之前的某个线程设置的值, 这个是最低安全性的保证(out-of-thin-air-safety). 但是存在例外: 非volatile的64位数值变量(double/long), JVM允许读写操作分为2个高低32位的操作.

volatile提供轻量级的同步机制, 编译器和运行时不会对volatile变量重排序. **volatile值保证可见性, 不像锁一样还能保证原子性.** 只有如下场景用volatile变量:
- 对变量写入不依赖当前值, 且只会有单个线程更新变量的值
- 该变量不会和其他状态变量一起纳入不变性条件
- 访问变量时不需要加锁

### Publication and escape
publish指对象被作用域外的代码使用, 如果不应该被publish的对象被publish(对象还没构造好时), 就叫escape. 有一种不容易发现的情况就是构造器中new实例的时候, 这个实例被publish时, 构造器内的this也会被隐式地publish, 然而此时构造器可能并没有执行结束. 为了解决这个问题, 可以用工厂方法返回实例, 工厂方法中在对象构造完成后, 再把这个对象的实例传给其他类, 防止escape. *e.g. SafeListener ThisEscape*.
```
/**
 * this溢出
 */
public class ThisEscape {

    /**
     * 构造函数中, 包含对this的隐式引用, 所以当ThisEscape构造器发布EventListener时, this也会被发布.
     */
    public ThisEscape(EventSource source) {
        source.registerListener(
                new EventListener() {
                    @Override
                    public void onEvent(Event e) {
                        // 如果EventListener被发布, this溢出了, 但是ThisEscape并没有构造完成
                        System.out.println(this);
                    }
                }
        );
        System.out.println("do other thing");
    }

    public static void main(String[] args) {
        EventSource source = new EventSource();
        new ThisEscape(source);
        source.eventListener.onEvent(new Event());
    }
}
```

```
/**
 * 通过工厂方法, 防止this溢出
 */
public class SafeListener {

    /**
     * EventListener内部有onEvent方法等待override
     */
    private final EventListener listener;

    private SafeListener() {
        listener = new EventListener() {
            @Override
            public void onEvent(Event e) {
                // 不允许这个时候的状态被外部访问
            }
        };

        System.out.println("do other thing");
    }

    public static SafeListener newInstance(EventSource source) {
        // SafeListener构造完成后, 再用registerListener去注册
        SafeListener safe = new SafeListener();
        source.registerListener(safe.listener);
        return safe;
    }
}

public class EventSource {

    public EventListener eventListener;

    public void registerListener(EventListener eventListener) {
        this.eventListener = eventListener;
    }
}
```

### Thread confinement
从代码实现上, 把变量限制在只能被一个线程用同步. 如Swing的dispatch线程. 如果仅从代码去实现这样的逻辑, 书中定义叫ad-hoc thread confinement, 这种程序会比较脆弱, 举个例子, volatile变量如果保证单线程写入, 因为可见性可以保证, 所以可以确保线程安全, 但是可以预见的是保证单线程写入本身就不是容易的事情. **stack confinement**也是一种特殊的Thread confinement, 让变量被限制在代码块内: *e.g. ThreadConfinementExample.loadTheArk*. 这个例子其实和前面的*CachedFactorizer*类似. 
```
public class ThreadConfinementExample {

    /**
     * animals作为局部变量, 被封闭在代码块内
     */
    public int loadTheArk(Collection<Animal> candidates) {
        SortedSet<Animal> animals;
        int numPairs = 0;
        Animal candidate = null;

        // animals对象只在
        animals = new TreeSet<>();
        animals.addAll(candidates);
        for (Animal a : animals) {
            if (candidate == null || !candidate.isPotentialMate(a)) {
                candidate = a;
            }
        }
        return numPairs;
    }
}
```

还有一种保证thread confinement使用**ThreadLocal**, 使用时可以把它想象成一个Map, 对不同的线程提供对应的值, 当线程不用这个值了, 这个值就会被GC. 每个set的值在使用的线程都有独立的副本, 在get时也总会返回当前线程设置的最新值.
```
private static ThreadLocal<Connection> connectionHolder = new ThreadLocal<Connection>() {

    @Override
    public Connection initialValue() {
        try {
            return DriverManager.getConnection(DB_URL);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
};

public static Connection getConnection() {
    return connectionHolder.get();
}
```

### Immutability
immutable的对象线程安全, 不可变对象需要满足如下几个条件. *e.g. ThreeStooges*.
- 对象创建后其状态不能修改(是集合类也可以, 但是不发布, 而是用已有元素做一些判断)
- 域都是final(String除外, ~严格来说不用满足这一点, 但是实现上需要对JMM有深入的理解, 所以自己写代码别这么做~). 将不可变的域声明为final是个好习惯. 
- 对象创建期间, this不溢出
```
public class ThreeStooges {

    /**
     * Set可变, 但是构造后无法修改
     */
    private final Set<String> stooges = new HashSet<>();

    public ThreeStooges() {
        stooges.add("Moe");
        stooges.add("Larry");
        stooges.add("Curly");
    }

    public boolean isStooge(String name) {
        return stooges.contains(name);
    }
}
```

当某个变量的读写有竞争条件时, 可以把他们放在一个不可变对象中, 来保证线程安全.
```
public class VolatileCachedFactorizer extends HttpServlet {

    /**
     * volatile保证visibility, 只要引用改变了, 其他线程就能看到
     */
    private volatile OneValueCache cache = new OneValueCache(null, null);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        BigInteger i = (BigInteger)req.getAttribute("i");
        BigInteger[] factors = cache.getFactors(i);
        if (factors == null) {
            factors = factor(i);
            cache = new OneValueCache(i, factors);
        }
        PrintWriter writer = resp.getWriter();
        writer.print(Arrays.toString(factors));
        super.doGet(req, resp);
    }

    /**
     * 因式分解, 还没实现
     */
    private BigInteger[] factor(BigInteger number) {
        return new BigInteger[]{};
    }
}

/**
 * 线程安全的因式分解, 因为lastNumber和lastFactors不可变
 */
public class OneValueCache {

    private final BigInteger lastNumber;

    private final BigInteger[] lastFactors;

    public OneValueCache(BigInteger i, BigInteger[] factors) {
        lastNumber = i;
        lastFactors = Arrays.copyOf(factors, factors.length);
    }

    public BigInteger[] getFactors(BigInteger i) {
        if (lastNumber == null || !lastNumber.equals(i)) {
            return null;
        } else {
            return Arrays.copyOf(lastFactors, lastFactors.length);
        }
    }
}
```

### Safe publication
**Effectively immutable objects**(技术上状态可变, 但是实际上不会对其进行改变)需要安全地publish, 让使用这个对象的线程看到已发布的状态. 书中总结了以下几种方式. 
- 静态初始化函数中初始化一个对象的引用. 因为静态初始化在JVM的初始化阶段进行, JVM保证内部的线程安全.
- 将对象引用保存到volatile或AtomicReference对象中
- 将对象引用保存到正确构造对象的final域中
- 将对象引用保存到一个由锁保护的域中

而Mutable objects不仅仅需要safe publication, 还需要线程安全或用锁保护. 而不可变对象因为本身保证了线程安全, 所以可用任何机制发布. 

## Chapter4-Composing Objects
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
确保一个对象只能有单个线程访问, 封装在对象内部的数据, 可以把数据的访问限制在对象的方法上. *e.g. PersonSet*. 进而想到Java的监视器模式, 用一把内部锁来封装内部的mutable state. *e.g. PrivateLock*.  *e.g. MonitorVehicleTracker*.
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
