---
title: "Java Concurrency in Practice Chapter2-Thread Safety"
date: 2022-01-29
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
---

这一节主要介绍线程安全的一些基本概念, 解释一些基本名词. 写线程安全的并发代码, 关键就是在访问共享资源时做好管理.

### Atomicity
在不同的线程访问一个资源时, 这个资源的状态应该是一致的, 类的行为和应该有的规范完全一致. **所以无状态对象一定安全**, 因为它没有域, 也没有对其他类的域的引用, 计算过程只在栈上的, 没有共享资源, 那么一定安全了. 当这个而无状态类有字段时, 可以用原子变量类, 如`AtomicLong`来保证原子性(读取-修改-写入). 这里要注意, 原子性只针对原子变量本身, 多个原子变量因为不同时序的调用, 不能保证线程安全. *e.g. AtomicTest*.
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
可以用`synchronized(lock) {}`标注同步代码块, 并且这些**内置锁**是可重入的, 重入是指在一个线程中可以多次获取同一把锁, 也就是说锁的粒度是线程, 线程可以获得自己持有的锁. *Widgit*这个例子的子类的同步方法中调用父类的同步方法, 两个方法的方法体不同, 但是`this`是相同的, 所以实际上是重入了同一把锁. 可以看出, 有些地方写`ReentrantLock`和`synchronized`的区别是`synchronized`不可重入, 这种说法是错的! 只不过用`ReentrantLock`, 我们可以多次手动获取锁, 并且手动解锁. 
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
多个线程共享的变量应该由一个锁来保护, 反之不是多个线程共享的变量无需保护. 锁需要保护invariants(不变性条件)中的所有涉及的变量, 只保护一个变量是不够的. `Vector`的所有方法都是`synchronized`方法, 也无法使复合操作原子.
```
if (!vector.contains(element)) {
    vector.add(element)
}
```


> 对invariants这个概念, 可以将其理解为状态的不变. 简单说, 比如我们要求`a == 2 * b`, 那个在并发场景下, 这个两个变量共同组成了这个2倍等式的不变性条件

### Liveness and performance
*SynchronizedFactorizer*中对整个方法进行加锁, 让Servlet无法多线程处理任务, 这种粗粒度地对整个方法加锁非常不好. 而*CachedFactorizer*中, 把读写的操作分别加锁, 会有更好的性能. 只有读写的时候才会问共享的变量, `doGet`代码块内的局部变量也都没有被发布, 在自己的线程中是安全的.
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
     * 因式分解, 未实现
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