---
title: "Java Concurrency in Practice Chapter7-Cancellation and Shutdown"
date: 2022-11-05
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
---

### 7.1 Task cancellation
*e.g. PrimeGenerator*是一个质数生成器, 通过调用`aSecondOfPrimes`方法, 实现在1秒延迟后取消质数生成. 看起来没有什么问题, 但实际如果这个方法的任务调用了阻塞方法, 并且生产速度大于消费速度, 那么在阻塞队列满了之后, put时就会被阻塞. 即使消费者执行了cancel的操作, 生产者依然处在put的过程中, 读不到cancel的值, 使程序无法退出.
```
/**
 * 质数生成器
 */
public class PrimeGenerator implements Runnable {
    
    private final List<BigInteger> primes = new ArrayList<>();
    
    private volatile boolean cancelled;
    
    @Override
    public void run() {
        BigInteger p = BigInteger.ONE;
        while (!cancelled) {
            p = p.nextProbablePrime();
            synchronized (this) {
                primes.add(p);
            }
        }
    }
    
    public void cancel() {
        cancelled = true;
    }
    
    public synchronized List<BigInteger> get() {
        return new ArrayList<>(primes);
    }
    
    /**
     * 1秒钟的时候调用cancel
     */
    List<BigInteger> aSecondOfPrimes() throws InterruptedException {
        PrimeGenerator generator = new PrimeGenerator();
        new Thread(generator).start();
        try {
            SECONDS.sleep(1);
        } finally {
            generator.cancel();
        }
        return generator.get();
    }
}
```

而取消任务最好的方式就是用Thread的`interrupt()`方法, 注意Thread有一个静态的`interrupted()`方法, 作用是返回当前的中断状态, 但是它的底层是`currentThread().isInterrupted(true);`会清除中断标志, 如果返回为`true`, 表示这个线程正在中断中, 要记住去处理它. 上述代码的`!cancelled`就可以替换为`!Thread.currentThread().isInterrupted()`. **Java中取消一个任务最好的方式就是中断**. **Java的中断是非抢占式的, 执行任务或取消操作的代码都不应该对线程的中断策略有任何假设**. 调用阻塞队列的质数生成器: *PrimeProducer*.
```
/**
 * PrimeGenerator的阻塞队列版, 这时候需要用interrupt来实现cancel, 防止阻塞队列阻塞后线程读不到cancel信号量, 导致任务无法停止
 */
public class PrimeProducer extends Thread {

    private final BlockingQueue<BigInteger> queue;

    PrimeProducer(BlockingQueue<BigInteger> queue) {
        this.queue = queue;
    }

    @Override
    public void run() {
        try {
            BigInteger p = BigInteger.ONE;
            while (!Thread.currentThread().isInterrupted()) {
                queue.put(p = p.nextProbablePrime());
            }
        } catch (InterruptedException consumed) {
            // Allow thread to exit
        }
    }

    public void cancel() {
        interrupt();
    }
}
```

知道了怎么通过中断取消一个任务, 那么对于中断应该如何响应呢. 有两种办法:
- `throw InterruptedException` 抛出中断给父线程
- `catch (InterruptedException e)`中设置`interrupted = true;`并在finally中判断这个标志位, 若为`true`则重试中断. 

接下来运用上面的知识来实现一个实现一个计时运行的任务. 在这之前先分析两种不好的实现方法. 第一种的代码如下, 在外部线程中去实现中断, 而我们不应该对线程的中断策略有任何假设, `timedRun`可以被任意线程调用, 不能被随意中断. `timedRun`很有可能已经完成任务, 或者没完成任务也不响应中断. 这种实现是绝对不能出现的.
```
public class TimedRun {
    
    /**
     * timedRun是static的, 可以被任何线程调用, 调用线程的中断策略是未知的, 如果该线程任务已经执行完成,
     * {@code cancelExec.schedule}的延时才结束, 那么{@code taskThread.interrupt()}会造成无法推测的后果
     */
    private static final ScheduledExecutorService cancelExec = new                       ScheduledThreadPoolExecutor(1);
    
    public static void timedRun(Runnable r, long timeout, TimeUnit unit) {
        final Thread taskThread = Thread.currentThread();
        // 在一段延时后调用
        cancelExec.schedule(new Runnable() {
            @Override
            public void run() {
                taskThread.interrupt();
            }
        }, timeout, unit);
        r.run();
    }
    
    /**
     * 修复了timedRun的问题, 但是因为用了join. 无法知道线程是正常退出(因为taskThread.interrupt()退出)还是因为join超时而返回
     */
    public static void timedRun2(final Runnable r, long timeout, TimeUnit unit) throws InterruptedException {
        class RethrowableTask implements Runnable {
            /**
             * 在两个线程之间共享
             */
            private volatile Throwable t;
            
            @Override
            public void run() {
                try { 
                    r.run();
                } catch (Throwable t) {
                    this.t = t;
                }
            }
            
            void rethrow() {
                if (t != null) {
                    throw launderThrowable(t);
                }
            }
        }
        
        RethrowableTask task = new RethrowableTask();
        final Thread taskThread = new Thread(task);
        // 任务线程开始执行
        taskThread.start();
        // 用专门的中断线程中断任务
        cancelExec.schedule(new Runnable() {
                @Override
                public void run() {
                    taskThread.interrupt();
                }
            }, timeout, unit);
        taskThread.join(unit.toMillis(timeout));
        task.rethrow();
    }
    
    /**
     * 通过Future的取消功能来实现. 这样可以知道是因为超时退出(TimeoutException), 还是任务执行完成后或没执行完成因为中断而退出
     */
    private static final ExecutorService taskExec = Executors.newFixedThreadPool(1);
    
    public static void timedRun3(Runnable r, long timeout, TimeUnit unit) throws InterruptedException {
        Future<?> task = taskExec.submit(r);
    
        try {
            task.get(timeout, unit);
        } catch (TimeoutException e) {
            // 超时, 可以取消任务
        } catch (ExecutionException e) {
            // exception thrown in task; rethrow
            throw launderThrowable(e.getCause());
        } finally {
            // 任务没有执行了, 这行代码没有影响. 若还在执行, 则中断任务
            task.cancel(true);
        }
    }
}
```

第二种实现方法实际上是可用的, 通过join来让定时任务执行, 而执行任务的线程`RethrowableTask`也有自己的中断策略, 其中的抛错也被`volatile`, 保证可见性, 可以安全地被发布到`timedRun`的线程. 这种实现方式的问题是依赖了`join`, 因为Java Thread api本身的缺陷, 无论join成功或超时, 总会有结果(因为可见性), 而join本身又不返回成功与否的标志, 程序就无法知道线程是正常对出还是因为join超时而返回. 
```
public static void timedRun(final Runnable r, long timeout, TimeUnit unit) throws InterruptedException {
    class RethrowableTask implements Runnable {
        private volatile Throwable t; 
        public void run() {
            try {
                r.run();
            } catch (Throwable t) {
                this.t = t;
            } 
            void rethrow() {
                if (t != null) {
                    throw launderThrowable(t);
                }
            }
        }
    }

    RethrowableTask task = new RethrowableTask();
    final Thread taskThread = new Thread(task);
    taskThread.start();
    cancelExec.schedule(new Runnable() {
        public void run() {
            taskThread.interrupt();
        }
    }, timeout, unit);
    taskThread.join(unit.toMillis(timeout));
    task.rethrow();
}
```

