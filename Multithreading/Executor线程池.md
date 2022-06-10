# 一、线程池基础

## 1.1、介绍

线程池”，顾名思义就是一个线程缓存，线程是稀缺资源，如果被无限制的创建，不仅会消耗系统资源，还会降低系统的稳定性，因此Java中提供线程池对线程进行统一分配、调优和监控。 

在web开发中，服务器需要接受并处理请求，所以会为一个请求来分配一个线程来进行处理。如果每次请求都新创建一个线程的话实现起来非常简便，但是存在一个问题：**如果并发的请求数量非常多，但每个线程执行的时间很短，这样就会频繁的创建和销毁线程，如此一来会大大降低系统的效率。可能出现服务器在为每个请求创建新线程和销毁线程上花费的时间和消耗的系统资源要比处理实际的用户请求的时间和资源更多。** 

**那么有没有一种办法使执行完一个任务，并不被销毁，而是可以继续执行其他的任务呢？**

这就是线程池的目的了。线程池为线程生命周期的开销和资源不足问题提供了解决方案。通过对多个任务重用线程，线程创建的开销被分摊到了多个任务上。

## 1.2、使用线程池的场景

- 单个任务处理时间较短
- 需要处理的任务数量很大

## 1.3、线程池的优势

- 复用存在的线程，减少线程创建和消亡的开销，提高性能。
- 提高响应速度。当任务到达时，任务可以不需要等待线程创建就能立即执行。
- 提高线程的可管理性。线程是稀缺资源，如果无限的去创建，不仅会消耗系统资源，还会降低系统的稳定性，使用线程池可以对线程进行统一的分配、调优和监控。

# 二、Executor框架

## 2.1、介绍

Executor接口是线程池框架中最基础的部分，定义了一个用于执行Runnable的execute方法。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Executor-%E6%A1%86%E6%9E%B6%E7%BB%93%E6%9E%84%E5%9B%BE.png?raw=true)

从图中可以看出Executor下有一个重要子接口ExecutorService，其中定义了线程池的具体行为：

- **execute**（Runnable command）：履行Ruannable类型的任务。
- **submit**（task）：可用来提交Callable或Runnable任务，并返回代表此任务的Future 对象。
- **shutdown**（）：在完成已提交的任务后封闭办事，不再接管新任务。
- **shutdownNow**（）：停止所有正在履行的任务并封闭办事。
- **isTerminated**（）：测试是否所有任务都履行完毕了。
- **isShutdown**（）：测试是否该ExecutorService已被关闭。

## 2.2、线程池重点属性

```java
private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
private static final int COUNT_BITS = Integer.SIZE-3; 
private static final int CAPACITY = (1 << COUNT_BITS)-1;
```

ctl 是对线程池的运行状态和线程池中有效线程的数量进行控制的一个字段， 它包含两部分的信息: 线程池的运行状态 (runState) 和线程池内有效线程的数量 (workerCount)。这里可以看到，使用了Integer类型来保存，高3位保存runState，低29位保存workerCount。COUNT_BITS 就是29，CAPACITY就是1左移29位减1（29个1），这个常量表示workerCount的上限值，大约是5亿。

**ctl相关方法**

```java
private static int runStateOf(int c)	{ return c & ~CAPACITY; }
private static int workerCountOf(int c)	{ return c & CAPACITY; } 
private static int ctlOf(int rs, int wc) { return rs | wc; }
```

- runStateOf：获取运行状态
- workerCountOf：获得活动线程数
- ctl：获取运行状态和活动线程数

## 2.3、线程池存在的5种状态

### ①.RUNNING

(1) 状态说明：线程池处在RUNNING状态时，能够接收新任务，以及对已添加的任务进行处理。

(02) 状态切换：线程池的初始化状态是RUNNING。换句话说，线程池被一旦被创建，就处于RUNNING状态，并且线程池中的任务数为0！

### ②.SHUTDOWN

(1) 状态说明：线程池处在SHUTDOWN状态时，不接收新任务，但能处理已添加的任务。

(2) 状态切换：调用线程池的shutdown()接口时，线程池由RUNNING -> SHUTDOWN。

### ③.STOP

(1) 状态说明：线程池处在STOP状态时，不接收新任务，不处理已添加的任务，并且会中断正在处理的任务。

(2) 状态切换：调用线程池的shutdownNow()接口时，线程池由(RUNNING or SHUTDOWN ) -> STOP。

### ④.TIDYING

(1) 状态说明：当所有的任务已终止，ctl记录的”任务数量”为0，线程池会变为TIDYING 状态。当线程池变为TIDYING状态时，会执行钩子函数terminated()。terminated()在ThreadPoolExecutor类中是空的，若用户想在线程池变为TIDYING时，进行相应的处理； 可以通过重载terminated()函数来实现。

(2) 状态切换：当线程池在SHUTDOWN状态下，阻塞队列为空并且线程池中执行的任务也为空时，就会由 SHUTDOWN -> TIDYING。 当线程池在STOP状态下，线程池中执行的任务为空时，就会由STOP -> TIDYING。

### **⑤.**TERMINATED

(1) 状态说明：线程池彻底终止，就变成TERMINATED状态。

(2) 状态切换：线程池处在TIDYING状态时，执行完terminated()之后，就会由 TIDYING -> TERMINATED。

**进入TERMINATED的条件如下：**

- 线程池不是RUNNING状态；
- 线程池状态不是TIDYING状态或TERMINATED状态；
- 如果线程池状态是SHUTDOWN并且workerQueue为空；
- workerCount为0；
- 设置TIDYING状态成功。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Executor-%E6%A1%86%E6%9E%B6%E7%BB%93%E6%9E%84%E5%9B%BE.png?raw=true)

**线程池的具体实现：**

- ThreadPoolExecutor 默认线程池
- ScheduledThreadPoolExecutor 定时线程池

## 2.4、ThreadPoolExcutor

### ①.线程池创建

```java
public ThreadPoolExecutor(int corePoolSize,
                        int maximumPoolSize,
                        long keepAliveTime,
                        TimeUnit unit,
                        BlockingQueue<Runnable> workQueue,
                        ThreadFactory threadFactory,
                        RejectedExecutionHandler handler)
```

### ②.参数解释

- **corePoolSize：**线程池中的核心线程数，当提交一个任务时，线程池创建一个新线程执行任务，直到当前线程数等于corePoolSize；如果当前线程数为corePoolSize，继续提交的任务被保存到 阻塞队列中，等待被执行；如果执行了线程池的prestartAllCoreThreads()方法，线程池会提前创建并启动所有核心线程。

- **maximumPoolSize：**线程池中允许的最大线程数。如果当前阻塞队列满了，且继续提交任务，则创建新的线程执行任务，前提是当前线程数小于maximumPoolSize；

- **keepAliveTime：**线程池维护线程所允许的空闲时间。当线程池中的线程数量大于corePoolSize的时候，如果这时没有新的任务提交，核心线程外的线程不会立即销毁，而是会等待，直到等待的时间超过了keepAliveTime；

- **unit：**keepAliveTime的单位，有七种

  ```java
  TimeUnit.DAYS;               //天
  TimeUnit.HOURS;             //小时
  TimeUnit.MINUTES;           //分钟
  TimeUnit.SECONDS;           //秒
  TimeUnit.MILLISECONDS;      //毫秒
  TimeUnit.MICROSECONDS;      //微妙
  TimeUnit.NANOSECONDS;       //纳秒
  ```

- **workQueue：**用来保存等待被执行的任务的阻塞队列，且任务必须实现Runable接口，在JDK中提供了如下阻塞队列：

- - ArrayBlockingQueue：基于数组结构的有界阻塞队列，按FIFO排序任务；
  - LinkedBlockingQuene：基于链表结构的阻塞队列，按FIFO排序任务，吞吐量通常要高于ArrayBlockingQuene；
  - SynchronousQuene：一个不存储元素的阻塞队列，每个插入操作必须等到另一个线程调用移除操作，否则插入操作一直处于阻塞状态，吞吐量通常要高于LinkedBlockingQuene；
  - priorityBlockingQuene：具有优先级的无界阻塞队列；

- **threadFactory：**它是ThreadFactory类型的变量，用来创建新线程。默认使用Executors.defaultThreadFactory() 来创建线程。使用默认的ThreadFactory来创建线程时，会使新创建的线程具有相同的NORM_PRIORITY优先级并且是非守护线程，同时也设置了线程的名称。

- **handler：**线程池的饱和策略，当阻塞队列满了，且没有空闲的工作线程，如果继续提交任务，必须采取一种策略处理该任务，线程池提供了4种策略：

- - AbortPolicy：直接抛出异常，默认策略；
  - CallerRunsPolicy：用调用者所在的线程来执行任务；
  - DiscardOldestPolicy：丢弃阻塞队列中靠最前的任务，并执行当前任务；
  - DiscardPolicy：直接丢弃任务；

- ```java
  ThreadPoolExecutor.AbortPolicy: 丢弃任务并抛出RejectedExecutionException异常。 
  ThreadPoolExecutor.DiscardPolicy：也是丢弃任务，但是不抛出异常。 
  ThreadPoolExecutor.DiscardOldestPolicy：丢弃队列最前面的任务，然后重新尝试执行任务（重复此过程）
  ThreadPoolExecutor.CallerRunsPolicy：由调用线程处理该任务
  ```

上面的4种策略都是ThreadPoolExecutor的内部类。

当然也可以根据应用场景实现RejectedExecutionHandler接口，自定义饱和策略，如记录日志或持久化存储不能处理的任务。

### ③.线程池监控

```java
public long getTaskCount() //线程池已执行与未执行的任务总数
public long getCompletedTaskCount() //已完成的任务数
public int getPoolSize() //线程池当前的线程数
public int getActiveCount() //线程池中正在执行任务的线程数量
```

### ④.线程池工作原理

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Executor-%E7%BA%BF%E7%A8%8B%E6%B1%A0%E6%89%A7%E8%A1%8C%E6%B5%81%E7%A8%8B.png?raw=true)

1. 判断当前的线程数是否小于corePoolSize。是，使用入参任务通过addWord() 方法创建一个新的线程加入核心线程并执行任务。不是，则进行下一步 。

2. 线程池判断阻塞队列是否已满。 如果阻塞队列没有满，则将新提交的任务存储在阻塞队列中。如果阻塞队列已满，则进入下个流程。

3. 判断线程池里的线程数量是否小于最大线程数量(看线程池是否满了)。 如果小于，则创建一个新的工作线程（非核心线程，并给它设置超时时间，当我们处理完这些任务，无需手动销毁这个非核心线程，超时自动销毁）来执行任务。如果已满，则交给拒绝策略来处理这个任务。

额外：

**新加入的任务和阻塞队列的任务抢占线程是公平的还是非公平的**？

+ 在核心线程还没满的时候，是非公平的。

+ 核心线程满了是公平的。

# 三、核心方法源码分析



# 四、如何合理配置线程池的大小

一般需要根据任务的类型来配置线程池大小：

+ 如果是CPU密集型任务，就需要尽量压榨CPU，参考值可以设为 NCPU+1
+ 如果是IO密集型任务，参考值可以设置为2*N CPU

当然，这只是一个参考值，具体的设置还需要根据实际情况进行调整，比如可以先将线程池大小设置为参考值，再观察任务运行情况和系统负载、资源利用率来进行适当调整。