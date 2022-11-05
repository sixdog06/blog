---
title: "Java Concurrency in Practice Chapter6-Task Execution"
date: 2022-03-07
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
---

一个大型的应用通常是一个个的任务组成的, 这个Chapter就讲怎么设计一个线程安全的任务.

### 6.1-Executing tasks in threads
如果串行执行任务, 性能很差, 不适合web服务器. 但是因为安全性和简单性, 被GUI框架广泛使用. *e.g. SingleThreadWebServer*. 如果并行执行, 但是无限制地创建线程, 依然会有缺陷, 因为线程的生命周期开销高(创建和销毁), 活跃的线程会消耗资源, 并且线程的数量上限是有限制的, 超出范围会产生OOM. *e.g. ThreadPerTaskWebServer*.
```
/**
 * 串行渲染器
 */
public class SingleThreadRenderer {
    
    void renderPage(CharSequence source) {
        renderText(source);
        List<ImageData> imageDatas = new ArrayList<>();
        for (ImageInfo imageInfo: scanForImageInfo(source)) {
            imageDatas.add(imageInfo.downloadImage());
            for (ImageData data : imageDatas) {
                renderImage(data);
            }
        }
    }
}

/**
 * 为每个任务创建线程
 */
public class ThreadPerTaskWebServer {
    
    public static void main(String[] args) throws IOException {
        ServerSocket socket = new ServerSocket(80);
        while (true) {
            final Socket connection = socket.accept();
            Runnable task = new Runnable() {
                
                @Override
                public void run() {
                    handleRequest(connection);
                } };
            new Thread(task).start();
        }
    }
}
```

### 6.2-The Executor framework
通过`Executor`接口作为基础, 实现了很多异步任务执行的框架. *e.g. TaskExecutionWebServer*. Executors下也实现了创建线程池的方法(**实际上还是推荐手动设置参数**). Executor的主要目的还是解耦任务的提交和执行. 如果想有一些灵活的执行策略, `new Thread(runnable).start()`这种提交立即执行的代码就可以考虑用`Executor`来替代, 并在实现的时候插入一些执行策略. 
```
/**
 * 基于Executor的web服务器
 */
public class TaskExecutionWebServer {
    
    private static final int N_THREADS = 100;
    
    private static final Executor exec = Executors.newFixedThreadPool(N_THREADS);
    
    public static void main(String[] args) throws IOException {
        ServerSocket socket = new ServerSocket(80);
        while (true) {
            final Socket connection = socket.accept();
            Runnable task = new Runnable() {
               @Override
                public void run() {
                    handleRequest(connection);
                }
            };
            exec.execute(task);
        }
    }
}
```

`ExecutorService`接口定义了一些管理`Executor`生命周期的方法, `shutdown`: 不再接受新任务并等待当前任务执行完成后再关闭, `shutdownNow`: 强制关闭. 

### 6.3 Finding exploitable parallelism
这一节通过一个图像渲染器来解释并发的设计. 首先是*e.g. SingleThreadRenderer*这种没有并发的串行设计, 图像渲染和图像下载的i/o操作耦合在一起, 等待i/o操作的过程中, CPU几乎不工作, 让整个任务的总时长较长, 所以需要拆开任务并发执行. 如果用Future类实现异步的图像渲染器, 如*e.g. FutureRenderer*, 理论上可以解决这个问题, 但是通常图像渲染的时间远低于下载的时间, 所以最终的瓶颈仍然在下载时间, 对性能的提升有限. 
```
/**
 * 串行, 性能不好, 但是能提供简单性和安全性. GUI框架用的多, 但不适合web服务器
 */
public class SingleThreadWebServer {
    
    public static void main(String[] args) throws IOException {
        ServerSocket socket = new ServerSocket(80);
        while (true) {
            Socket connection = socket.accept();
            handleRequest(connection);
        }
    }
}

/**
 * Future实现的异步图像渲染
 */
public class FutureRenderer {
    
    private final ExecutorService executor = new ThreadPoolExecutor(
            5,
            10,
            100,
            TimeUnit.MILLISECONDS,
            new ArrayBlockingQueue<>(5));
    
    void renderPage(CharSequence source) {
        final List<ImageInfo> imageInfos = scanForImageInfo(source);
        Callable<List<ImageData>> task = new Callable<List<ImageData>>() {
            @Override
            public List<ImageData> call() {
                List<ImageData> result = new ArrayList<>();
                for (ImageInfo imageInfo : imageInfos) {
                    result.add(imageInfo.downloadImage());
                }
                return result;
            }
        };
    
        Future<List<ImageData>> future = executor.submit(task);
        renderText(source);
        try {
            List<ImageData> imageData = future.get();
            for (ImageData data : imageData) {
                renderImage(data);
            }
        } catch (InterruptedException e) {
            // Re-assert the thread’s interrupted status
            Thread.currentThread().interrupt();
            // We don’t need the result, so cancel the task too
            future.cancel(true);
        } catch (ExecutionException e) {
            throw launderThrowable(e.getCause());
        }
    }
}
```

而*e.g. Renderer*通过`ExecutorCompletionService`实现了并行的下载与及时渲染. 已经下载好的图片在`completionService.take()`后可以被及时消费掉.
```
public class Renderer {
    
    private final ExecutorService executor;
    
    Renderer(ExecutorService executor) {
        this.executor = executor;
    }
    
    void renderPage(CharSequence source) {
        List<ImageInfo> info = scanForImageInfo(source);
        CompletionService<ImageData> completionService = new ExecutorCompletionService<>(executor);
        
        for (final ImageInfo imageInfo : info) {
            // 下载任务拆线程做
            completionService.submit(new Callable<ImageData>() {
                @Override
                public ImageData call() {
                    return imageInfo.downloadImage();
                }
            });
        }
    
        renderText(source);
    
        try {
            for (int t = 0, n = info.size(); t < n; t++) {
                // 把已经下载成功的图片分别渲染, 消费阻塞队列
                Future<ImageData> f = completionService.take();
                ImageData imageData = f.get();
                renderImage(imageData);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (ExecutionException e) {
            throw launderThrowable(e.getCause());
        }
    }
}
```
