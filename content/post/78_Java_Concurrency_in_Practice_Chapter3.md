---
title: "Java Concurrency in Practice Chapter3-Sharing Objects"
date: 2022-01-30
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
---

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

使用**ThreadLocal**也能实现thread confinement, 使用时可以把它想象成一个Map, 对不同的线程提供对应的值, 当线程不用这个值了, 这个值就会被GC. 每个set的值在使用的线程都有独立的副本, 在get时也总会返回当前线程设置的最新值.
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
- 域都是final
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
