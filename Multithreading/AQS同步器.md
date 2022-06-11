# 一、AQS

## 1.1、AQS介绍

java.util.concurrent包中的大多数同步器实现都是围绕着共同的基础行为，比如等待队列、条件队列、独占获取、共享获取等，而这些行为的抽象就是基于AbstractQueuedSynchronizer（简称AQS）实现的。

<font color='red'>AQS是一个抽象同步框架，可以用来实现一个依赖状态的同步器。</font>

JDK中提供的大多数的同步器如Lock, Latch, Barrier等，都是基于AQS框架来实现的：

- 一般是通过一个内部类Sync继承 AQS 。
- 将同步器所有调用都映射到Sync对应的方法 。

AQS的继承方法：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-%E5%90%8C%E6%AD%A5%E5%99%A8%E7%9A%84%E7%BB%A7%E6%89%BF%E6%96%B9%E6%B3%95.png?raw=true)

## 1.2、AQS具备的特征

+ 阻塞等待队列
+ 共享/独占
+ 公平/非公平
+ 可重入
+ 允许中断

AQS内部维护属性<font color='red'>volatile int state</font>（state标识资源的可用状态）

State三种访问方式：

+ getState()
+ setState()
+ compareAndSetState()

## 1.3、AQS资源共享方式

+ Exclusive-独占，只有一个线程能执行，如ReetrantLock
+ Share-共享，多个线程可以同时执行，如Semaphore/CountDownLatch

## 1.4、AQS两种队列

### 1.4.1、同步等待队列

#### ①、介绍

AQS当中的同步等待队列也称CLH队列，CLH队列是Craig、Landin、Hagersten三人发明的<font color='red'>一种基于双向链表数据结构的队列，是FIFO先进先出线程等待队列，Java中的CLH队列是原CLH队列的一个变种,线程由原自旋机制改为阻塞机制。</font>

#### ②、同步等待队列实现

**AQS依赖CLH同步队列来完成同步状态的管理：**

+ 当前线程如果获取同步状态失败，AQS会将当前线程构造成为一个节点（Node）并加入到CLH同步队列，同时阻塞当前线程。
+ 当同步状态释放时，会把首节点唤醒（公平锁方式），使其再次尝试获取同步状态。
+ 通过<font color='red'>signal或者signalAll将条件队列中的节点转移到同步队列中</font>。（由条件队列转化为同步队列） 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-CLH%E9%98%9F%E5%88%97.png?raw=true)

#### ③、同步等待队列作用

主要用于<font color='red'>维护获取锁失败时入队的线程。</font>

### 1.4.2、条件等待队列

AQS中条件队列是使用单向列表保存的，用nextWaiter来连接，<font color='red'>调用await()时会释放锁，然后线程会加入到条件队列，调用signal()唤醒的时候会把条件队列中的线程节点移动到同步队列中，等待再次获得锁。</font>

**进入条件队列的条件：**

- 调用await方法阻塞线程； 
- 当前线程存在于同步队列的头结点，调用await方法进行阻塞（从同步队列转化到条件队列） 

## 1.5、AQS队列中的节点状态

```java
static final class Node {
    /** Marker to indicate a node is waiting in shared mode */
    static final Node SHARED = new Node();
    /** Marker to indicate a node is waiting in exclusive mode */
    static final Node EXCLUSIVE = null;
    /** waitStatus value to indicate thread has cancelled */
    static final int CANCELLED =  1;
    /** waitStatus value to indicate successor's thread needs unparking */
    static final int SIGNAL    = -1;
    /** waitStatus value to indicate thread is waiting on condition */
    static final int CONDITION = -2;

    static final int PROPAGATE = -3;
    volatile int waitStatus;
}
```

- 值为0，初始化状态，表示当前节点在sync队列中，等待着获取锁。 
- CANCELLED，值为1，表示当前的线程被取消； 
- SIGNAL，值为-1，表示当前节点的后继节点包含的线程需要运行，也就是unpark； 
- CONDITION，值为-2，表示当前节点在等待condition，也就是在condition队列中；
- PROPAGATE，值为-3，表示当前场景下后续的acquireShared能够得以执行； 

## 1.6、实现自定义同步器

不同的自定义同步器竞争共享资源的方式也不同。自定义同步器在实现时只需要实现共享 资源state的获取与释放方式即可，至于具体线程等待队列的维护（如获取资源失败入队/唤醒出队等），AQS已经在顶层实现好了。

**自定义同步器实现时主要实现以下几种方法：** 

- isHeldExclusively()：该线程是否正在独占资源。只有用到condition才需要去实现它。
- tryAcquire(int)：独占方式。尝试获取资源，成功则返回true，失败则返回false。 
- tryRelease(int)：独占方式。尝试释放资源，成功则返回true，失败则返回false。 
- tryAcquireShared(int)：共享方式。尝试获取资源。负数表示失败；0表示成功，但没有剩余可用资源；正数表示成功，且有剩余资源。 
- tryReleaseShared(int)：共享方式。尝试释放资源，如果释放后允许唤醒后续等待结点返回true，否则返回false。 

# 二、Condition接口详解

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-Condition%E6%8E%A5%E5%8F%A3%E6%96%B9%E6%B3%95.png?raw=true)

+ await()：<font color='red'>释放当前持有的锁，然后阻塞当前线程，同时向Condition队列尾部添加一个节点，所以调用Condition#await方法的时候必须持有锁。 </font>

+ signal()：<font color='red'>将Condition队列的首节点移动到阻塞队列尾部，然后唤醒因调用Condition#await方法而阻塞的线程</font>(唤醒之后这个线程就可以去竞争锁了)，所以调用Condition#signal方法的时候必须持有锁，持有锁的线程唤醒被因调用Condition#await方法而阻塞的线程。

**等待唤醒机制之await/signal测试** 

```java
public static void main(String[] args) {
    Lock lock = new ReentrantLock();
    Condition condition = lock.newCondition();
    new Thread(() -> {
        lock.lock();
        try {
            log.debug(Thread.currentThread().getName() + " 开始处理任务");
            //会释放当前持有的锁，然后阻塞当前线程
            condition.await();
            log.debug(Thread.currentThread().getName() + " 结束处理任务");
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }).start();
    
    new Thread(() -> {
        lock.lock();
        try {
            log.debug(Thread.currentThread().getName() + " 开始处理任务");
            Thread.sleep(2000);
            //唤醒因调用Condition#await方法而阻塞的线程
            condition.signal();
            log.debug(Thread.currentThread().getName() + " 结束处理任务");
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }).start();
}
```

结果：

```java
05:26:35.352 [Thread-0] DEBUG com.tuling.jucdemo.lock.ConditionTest - Thread-0 开始处理任务
05:26:35.354 [Thread-1] DEBUG com.tuling.jucdemo.lock.ConditionTest - Thread-1 开始处理任务
05:26:37.355 [Thread-1] DEBUG com.tuling.jucdemo.lock.ConditionTest - Thread-1 结束处理任务
05:26:37.355 [Thread-0] DEBUG com.tuling.jucdemo.lock.ConditionTest - Thread-0 结束处理任务
```

# 三、ReetrantLock

## 3.1、ReetrantLock介绍

<font color='red'>ReentrantLock是一种基于AQS框架的应用实现，是JDK中的一种线程并发访问的同步手段，它的功能类似于synchronized是一种互斥锁，可以保证线程安全。</font>

### 3.1.1、相对于synchronized， ReentrantLock具备如下特点：

- 可中断 
- 可以设置超时时间 
- 可以设置为公平锁 
- 支持多个条件变量 
- 与 synchronized 一样，都支持可重入。

### 3.1.2、synchronized和ReentrantLock的区别：

- synchronized是JVM层次的锁实现，ReentrantLock是JDK层次的锁实现； 
- synchronized的锁状态是无法在代码中直接判断的，但是ReentrantLock可以通过ReentrantLock#isLocked判断； 
- synchronized是非公平锁，ReentrantLock是可以是公平也可以是非公平的； 
- synchronized是不可以被中断的，而ReentrantLock#lockInterruptibly方法是可以被中断的； 
- 在发生异常时synchronized会自动释放锁，而ReentrantLock需要开发者在finally块中显示释放锁； 
- ReentrantLock获取锁的形式有多种：如立即返回是否成功的tryLock(),以及等待指定时长的获取，更加灵活； 
- synchronized在特定的情况下对于已经在等待的线程是后来的线程先获得锁（回顾一下sychronized的唤醒策略），而ReentrantLock对于已经在等待的线程是先来的线程先获得锁；

## 3.2、ReetrantLock使用

### 3.2.1、同步执行，类似于sychronized

```java
public class ReentrantLockDemo {
    private static  int sum = 0;
    private static Lock lock = new ReentrantLock();
    //private static TulingLock lock = new TulingLock();
    public static void main(String[] args) throws InterruptedException {
        for (int i = 0; i < 3; i++) {
            Thread thread = new Thread(()->{
                //加锁
                lock.lock();
                try {
                    // 临界区代码
                    // TODO 业务逻辑：读写操作不能保证线程安全
                    for (int j = 0; j < 10000; j++) {
                        sum++;
                    }
                } finally {
                    // 解锁
                    lock.unlock();
                }
            });
            thread.start();
        }
        Thread.sleep(2000);
        System.out.println(sum);
    }
}
结果：
30000
```

### 3.2.2、可重入

```java
public class ReentrantLockDemo2 {
    public static ReentrantLock lock = new ReentrantLock();
    public static void main(String[] args) {
        method1();
    }
    public static void method1() {
        lock.lock();
        try {
            log.debug("execute method1");
            method2();
        } finally {
            lock.unlock();
        }
    }
    public static void method2() {
        lock.lock();
        try {
            log.debug("execute method2");
            method3();
        } finally {
            lock.unlock();
        }
    }
    public static void method3() {
        lock.lock();
        try {
            log.debug("execute method3");
        } finally {
            lock.unlock();
        }
    }
}
结果：
05:43:35.347 [main] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo2 - execute method1
05:43:35.350 [main] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo2 - execute method2
05:43:35.350 [main] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo2 - execute method3
```

### 3.2.3、可中断

```java
public class ReentrantLockDemo3 {
    public static void main(String[] args) throws InterruptedException {
        ReentrantLock lock = new ReentrantLock();
        Thread t1 = new Thread(() -> {
            log.debug("t1启动...");
            try {
                lock.lockInterruptibly();
                try {
                    log.debug("t1获得了锁");
                } finally {
                    lock.unlock();
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
                log.debug("t1等锁的过程中被中断");
            }
        }, "t1");
        lock.lock();
        try {
            log.debug("main线程获得了锁");
            t1.start();
            //先让线程t1执行
            Thread.sleep(1000);
            t1.interrupt();
            log.debug("线程t1执行中断");
        } finally {
            lock.unlock();
        }
    }
}
结果：
05:45:59.311 [main] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo3 - main线程获得了锁
05:45:59.313 [t1] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo3 - t1启动...
05:46:00.313 [main] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo3 - 线程t1执行中断
java.lang.InterruptedException
	at java.util.concurrent.locks.AbstractQueuedSynchronizer.doAcquireInterruptibly(AbstractQueuedSynchronizer.java:898)
	at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireInterruptibly(AbstractQueuedSynchronizer.java:1222)
	at java.util.concurrent.locks.ReentrantLock.lockInterruptibly(ReentrantLock.java:335)
	at com.tuling.jucdemo.lock.ReentrantLockDemo3.lambda$main$0(ReentrantLockDemo3.java:19)
	at java.lang.Thread.run(Thread.java:745)
05:46:00.313 [t1] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo3 - t1等锁的过程中被中断
```

**lock 与 lockInterruptibly()的区别：**

- lock 优先考虑获取锁，待获取锁成功后，才响应中断。
- lockInterruptibly 优先考虑响应中断，而不是响应锁的普通获取或重入获取。

interrupt()：线程中断，并更改中断标记flag=false->true。

isInterrupted()：判断线程是否已被中断过，即判断中断标志flag。

interrupted()：清除中断标志，flag=true->false。

### 3.2.4、锁超时

```java
public class ReentrantLockDemo4 {
    public static void main(String[] args) throws InterruptedException {
        ReentrantLock lock = new ReentrantLock();
        Thread t1 = new Thread(() -> {
            log.debug("t1启动...");
            // 注意： 即使是设置的公平锁，此方法也会立即返回获取锁成功或失败，公平策略不生效
//            if (!lock.tryLock()) {
//                log.debug("t1获取锁失败，立即返回false");
//                return;
//            }
            //超时
            try {
                if (!lock.tryLock(1, TimeUnit.SECONDS)) {
                    log.debug("等待 1s 后获取锁失败，返回");
                    return;
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
                return;
            }
            try {
                log.debug("t1获得了锁");
            } finally {
                lock.unlock();
            }
        }, "t1");
        lock.lock();
        try {
            log.debug("main线程获得了锁");
            t1.start();
            //先让线程t1执行
            Thread.sleep(2000);
        } finally {
            lock.unlock();
        }
    }
}
结果：
05:51:01.194 [main] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo4 - main线程获得了锁
05:51:01.197 [t1] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo4 - t1启动...
05:51:02.197 [t1] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo4 - 等待 1s 后获取锁失败，返回
```

### 3.2.5、公平锁

```java
public class ReentrantLockDemo5 {
    public static void main(String[] args) throws InterruptedException {
        //ReentrantLock lock = new ReentrantLock(true); //公平锁
        ReentrantLock lock = new ReentrantLock(); //非公平锁
        for (int i = 0; i < 500; i++) {
            new Thread(() -> {
                lock.lock();
                try {
                    try {
                        Thread.sleep(10);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    log.debug(Thread.currentThread().getName() + " running...");
                } finally {
                    lock.unlock();
                }
            }, "t" + i).start();
        }
        // 1s 之后去争抢锁
        Thread.sleep(1000);
        for (int i = 0; i < 500; i++) {
            new Thread(() -> {
                lock.lock();
                try {
                    log.debug(Thread.currentThread().getName() + " running...");
                } finally {
                    lock.unlock();
                }
            }, "强行插入" + i).start();
        }
    }
}
```

结果：

```java
非公平锁：
05:53:20.192 [t0] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - t0 running...
05:53:20.208 [t1] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - t1 running...
......
05:53:20.220 [t492] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - t492 running...
05:53:20.231 [t2] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - t2 running...
05:53:20.242 [t3] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - t3 running...
.......
公平锁：
05:55:09.995 [t453] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - t01 running...
.......
05:55:09.995 [t453] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - t453 running...
05:55:10.006 [t435] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - t435 running...
05:55:10.016 [t457] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - t457 running...
05:55:10.016 [强行插入0] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - 强行插入0 running...
05:55:10.016 [强行插入4] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - 强行插入4 running...
.....
05:55:10.034 [强行插入498] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - 强行插入498 running...
05:55:10.034 [强行插入497] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo5 - 强行插入497 running...
```

### 3.2.6、条件变量

java.util.concurrent类库中提供Condition类来实现线程之间的协调。调用 Condition.await() 方法使线程等待，其他线程调用Condition.signal() 或Condition.signalAll() 方法唤醒等待的线程。 

注意：调用Condition的await()和signal()方法，都必须在lock保护之内。

```java
public class ReentrantLockDemo6 {
    private static ReentrantLock lock = new ReentrantLock();
    private static Condition cigCon = lock.newCondition();
    private static Condition takeCon = lock.newCondition();
    private static boolean hashcig = false;
    private static boolean hastakeout = false;
    //送烟
    public void cigratee(){
        lock.lock();
        try {
            while(!hashcig){
                try {
                    log.debug("没有烟，歇一会");
                    cigCon.await();
                }catch (Exception e){
                    e.printStackTrace();
                }
            }
            log.debug("有烟了，干活");
        }finally {
            lock.unlock();
        }
    }
    //送外卖
    public void takeout(){
        lock.lock();
        try {
            while(!hastakeout){
                try {
                    log.debug("没有饭，歇一会");
                    takeCon.await();
                }catch (Exception e){
                    e.printStackTrace();
                }
            }
            log.debug("有饭了，干活");
        }finally {
            lock.unlock();
        }
    }
    public static void main(String[] args) {
        ReentrantLockDemo6 test = new ReentrantLockDemo6();
        new Thread(() ->{
            test.cigratee();
        }).start();
        new Thread(() -> {
            test.takeout();
        }).start();
        new Thread(() ->{
            lock.lock();
            try {
                hashcig = true;
                log.debug("唤醒送烟的等待线程");
                cigCon.signal();
            }finally {
                lock.unlock();
            }
        },"t1").start();
        new Thread(() ->{
            lock.lock();
            try {
                hastakeout = true;
                log.debug("唤醒送饭的等待线程");
                takeCon.signal();
            }finally {
                lock.unlock();
            }
        },"t2").start();
    }
}
结果：
06:00:48.305 [Thread-0] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo6 - 没有烟，歇一会
06:00:48.307 [Thread-1] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo6 - 没有饭，歇一会
06:00:48.308 [t1] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo6 - 唤醒送烟的等待线程
06:00:48.308 [t2] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo6 - 唤醒送饭的等待线程
06:00:48.308 [Thread-0] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo6 - 有烟了，干活
06:00:48.308 [Thread-1] DEBUG com.tuling.jucdemo.lock.ReentrantLockDemo6 - 有饭了，干活
```

# 四、ReetrantReadWriteLock

## 4.1、**读写锁介绍** 

现实中有这样一种场景：对共享资源有读和写的操作，且写操作没有读操作那么频繁（读多写少）。在没有写操作的时候，多个线程同时读一个资源没有任何问题，所以应该允许多个线程同时读取共享资源（读读可以并发）；但是如果一个线程想去写这些共享资源，就不应该允许其他线程对该资源进行读和写操作了（读写，写读，写写互斥）。

<font color='red'>在读多于写的情况下，读写锁能够提供比排它锁更好的并发性和吞吐量</font>。 针对这种场景，JAVA的并发包提供了读写锁ReentrantReadWriteLock，其内部维护了一对相关的锁，一个用于只读操作，称为读锁；一个用于写入操作，称为写锁。 

**线程进入读锁的前提条件：** 

- 没有其他线程的写锁 
- 没有写请求或者有写请求，但调用线程和持有锁的线程是同一个。 
- 线程进入写锁的前提条件
- 没有其他线程的读锁 
- 没有其他线程的写锁 

**而读写锁有以下三个重要的特性：** 

- 公平选择性：<font color='red'>支持非公平（默认）和公平的锁获取方式，吞吐量还是非公平优于公平。</font>
- 可重入：<font color='red'>读锁和写锁都支持线程重入</font>。以读写线程为例：<font color='red'>读线程获取读锁后，能够再次获取读锁。</font><font color='red'>写线程在获取写锁之后能够再次获取写锁，同时也可以获取读锁。 </font>
- 锁降级：遵循获取写锁、再获取读锁最后释放写锁的次序，写锁能够降级成为读锁。

## 4.2、使用

### 4.2.1、读写锁接口ReadWriteLock 

一对方法，分别获得读锁和写锁 Lock 对象。 

```java
public interface ReadWriteLock {
    /**
     * Returns the lock used for reading.
     *
     * @return the lock used for reading
     */
    Lock readLock();

    /**
     * Returns the lock used for writing.
     *
     * @return the lock used for writing
     */
    Lock writeLock();
}
```

### 4.2.2、ReetrantReadWriteLock类结构

ReentrantReadWriteLock是可重入的读写锁实现类。在它内部，维护了一对相关的锁，一个用于只读操作，另一个用于写入操作。只要没有 Writer 线程，读锁可以由多个 Reader 线程同时持有。<font color='red'>写锁是独占的，读锁是共享的。 </font>

```java
private final ReentrantReadWriteLock.ReadLock readerLock;
/** Inner class providing writelock */
private final ReentrantReadWriteLock.WriteLock writerLock;
/** Performs all synchronization mechanics */
final Sync sync;
public ReentrantReadWriteLock() {
    this(false);
}
public ReentrantReadWriteLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
    readerLock = new ReadLock(this);
    writerLock = new WriteLock(this);
}
public ReentrantReadWriteLock.WriteLock writeLock() { return writerLock; }
public ReentrantReadWriteLock.ReadLock  readLock()  { return readerLock; }
```

### 4.2.3、读写锁的使用

```java
private ReadWriteLock readWriteLock = new ReentrantReadWriteLock(); 
private Lock r = readWriteLock.readLock(); 
private Lock w = readWriteLock.writeLock(); 
// 读操作上读锁 
    public Data get(String key) { 
        r.lock(); 
        try { 
        // TODO 业务逻辑 
        }finally { 
        r.unlock(); 
        } 
    } 
    // 写操作上写锁 
    public Data put(String key, Data value) { 
        w.lock(); 
        try { 
        // TODO 业务逻辑 
        }finally { 
        w.unlock(); 
        } 
    } 
```

注意事项 ：

- **读锁不支持条件变量** 
- **重入时升级不支持**：<font color='red'>持有读锁的情况下去获取写锁，会导致获取永久等待 </font>
- **重入时支持降级**： <font color='red'>持有写锁的情况下可以去获取读锁应用场景</font>

示例

<font color='red'>ReentrantReadWriteLock适合读多写少的场景 </font>

```java
public class Cache { 
static Map<String, Object> map = new HashMap<String, Object>(); 
static ReentrantReadWriteLock rwl = new ReentrantReadWriteLock(); 
static Lock r = rwl.readLock(); 
static Lock w = rwl.writeLock(); 
    // 获取一个key对应的value 
    public static final Object get(String key) { 
        r.lock(); 
        try { 
            return map.get(key); 
        } finally { 
            r.unlock(); 
        } 
    } 
    // 设置key对应的value，并返回旧的value 
    public static final Object put(String key, Object value) { 
        w.lock(); 
        try { 
            return map.put(key, value); 
        } finally { 
            w.unlock(); 
        } 
    } 
    // 清空所有的内容 
    public static final void clear() { 
        w.lock(); 
        try { 
            map.clear(); 
        } finally { 
            w.unlock(); 
        } 
    } 
}
```

上述示例中，Cache组合一个非线程安全的HashMap作为缓存的实现，同时使用读写锁的读锁和写锁来保证Cache是线程安全的。在读操作get(String key)方法中，需要获取读锁，这使得并发访问该方法时不会被阻塞。

写操作put(String key,Object value)方法和clear()方法，在更新 HashMap时必须提前获取写锁，当获取写锁后，其他线程对于读锁和写锁的获取均被阻塞，而 只有写锁被释放之后，其他读写操作才能继续。

Cache使用读写锁提升读操作的并发性，也保证每次写操作对所有的读写操作的可见性，同时简化了编程方式。

### 4.2.4、锁降级

<font color='red'>锁降级指的是写锁降级成为读锁。</font>如果当前线程拥有写锁，然后将其释放，最后再获取读锁，这种分段完成的过程不能称之为锁降级。<font color='red'>锁降级是指把持住（当前拥有的）写锁，再获取到读锁，随后释放（先前拥有的）写锁的过程。</font>锁降级可以帮助我们拿到当前线程修改后的结果而不被其他线程所破坏，防止更新丢失。

**锁降级的使用示例** 

因为数据不常变化，所以多个线程可以并发地进行数据处理，当数据变更后，如果当前线程感知到数据变化，则进行数据的准备工作，同时其他处理线程被阻塞，直到当前线程完成数据的准备工作。 

```java
public class reentrantWriteReadLock {
    public static void main(String[] args) throws InterruptedException {
        Test t=new Test();
        t.processData();
    }
}
class Test{
    private final ReentrantReadWriteLock rwl = new ReentrantReadWriteLock();
    private final Lock readLock = rwl.readLock();
    private final Lock writeLock = rwl.writeLock();
    private volatile boolean update = false;
    public void processData() throws InterruptedException {
        System.out.println("开启读锁---");
        readLock.lock();
        if (!update) {
            // 必须先释放读锁
            System.out.println("有写操作");
            readLock.unlock();
            System.out.println("释放读锁---");
            // 降级从写锁获取到开始
            writeLock.lock();
            System.out.println("开启写锁+++++++");
            try {
                if (!update) {
                    // TODO 准备数据的流程（略）
                    System.out.println("准备数据中。。。。。");
                    Thread.sleep(2000);
                    System.out.println("准备阶段完成。。。。");
                    update = true;
                }
                readLock.lock();
                System.out.println("开启读锁///////");
            } finally {
                System.out.println("释放写锁+++++++++");
                writeLock.unlock();
            }
            // 锁降级完成，写锁降级为读锁
            Thread.sleep(2000);
            System.out.println("锁降级完成，写锁降级为读锁");
        }
        try {
            System.out.println("使用数据执行中");
            //TODO 使用数据的流程（略）
            Thread.sleep(2000);
            System.out.println("执行完成");
        } finally {
            readLock.unlock();
            System.out.println("释放读锁///////");
        }
    }
}
```

结果：

```
开启读锁---
有写操作
释放读锁---
开启写锁+++++++
准备数据中。。。。。
准备阶段完成。。。。
开启读锁///////
释放写锁+++++++++
锁降级完成，写锁降级为读锁
使用数据执行中
执行完成
释放读锁///////
```

**锁降级中读锁的获取是否必要呢？**

答案是必要的。主要是为了保证数据的可见性，如果当前线程不获取读锁而是直接释放写锁，假设此刻另一个线程（记作线程T）获取了写锁并修改了数据，那么当前线程无法感知线程T的数据更新。如果当前线程获取读锁，即遵循锁降级的步骤，则线程T将会被阻塞，直到当前线程使用数据并释放读锁之后，线程T才能获取写锁进行数据更新。

<font color='red'>RentrantReadWriteLock不支持锁升级（把持读锁、获取写锁，最后释放读锁的过程）。 目的也是保证数据可见性</font>，如果读锁已被多个线程获取，其中任意线程成功获取了写锁并更新了数据，则其更新对其他获取到读锁的线程是不可见的。 

### 4.2.5、ReentrantReadWriteLock源码分析 

思考： 

1. 读写锁是怎样实现分别记录读写状态的？ 

2. 写锁是怎样获取和释放的？ 

3. 读锁是怎样获取和释放的？ 

### 4.2.6、ReentrantReadWriteLock结构

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-ReentrantReadWriteLock%E7%BB%93%E6%9E%84.png?raw=true)

### 4.2.7、读写状态的设计 

#### ①.设计的精髓：（用一个变量如何维护多种状态）

在 ReentrantLock 中，使用 Sync ( 实际是 AQS )的 int 类型的 state 来表示同步状态，表示锁被一个线程重复获取的次数。但是，<font color='red'>读写锁 ReentrantReadWriteLock 内部维护着一对读写锁，如果要用一个变量维护多种状态，需要采用“按位切割使用”的方式来维护这个变量，将其切分为两部分：高16为表示读，低16为表示写。</font>

分割之后，读写锁是如何迅速确定读锁和写锁的状态呢？通过位运算。假如当前同步状态为S， 

那么： 

- 写状态，等于 S & 0x0000FFFF（将高 16 位全部抹去）。 当写状态加1，等于S+1。
- 读状态，等于 S >>> 16 (无符号补 0 右移 16 位)。当读状态加1，等于S+（1<<16）,也就是S+0x00010000 。

#### ②.根据状态的划分能得出一个推论：

S不等于0时，当写状态（S&0x0000FFFF）等于0时，则读状态（S>>>16）大于0，即读锁已被获取。 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-ReentrantReadWriteLock%E7%8A%B6%E6%80%81%E5%88%92%E5%88%86.png?raw=true)

代码实现：

java.util.concurrent.locks.ReentrantReadWriteLock.Sync

```java
static final int SHARED_SHIFT   = 16;
static final int SHARED_UNIT    = (1 << SHARED_SHIFT);
static final int MAX_COUNT      = (1 << SHARED_SHIFT) - 1;
static final int EXCLUSIVE_MASK = (1 << SHARED_SHIFT) - 1;

/** Returns the number of shared holds represented in count  */
static int sharedCount(int c)    { return c >>> SHARED_SHIFT; }
/** Returns the number of exclusive holds represented in count  */
static int exclusiveCount(int c) { return c & EXCLUSIVE_MASK; }
```

- exclusiveCount(int c) 静态方法，<font color='red'>获得持有写状态的锁的次数。</font> 
- sharedCount(int c) 静态方法，<font color='red'>获得持有读状态的锁的线程数量</font>。不同于写锁，读锁可以同时被多个线程持有。而每个线程持有的读锁支持重入的特性，所以需要对每个线程持有的读锁的数量单独计数，这就需要用到HoldCounter 计数器。

#### ③.HoldCounter 计数器 

<font color='red'>读锁的内在机制其实就是一个共享锁。</font>一次共享锁的操作就相当于对HoldCounter 计数器的操作。<font color='red'>获取共享锁，则该计数器 + 1，释放共享锁，该计数器 - 1。</font>只有当线程获取共享锁后才能对共享锁进行释放、重入操作。 

```java
static final class HoldCounter {
    int count = 0;
    // Use id, not reference, to avoid garbage retention
    final long tid = getThreadId(Thread.currentThread());
}

static final class ThreadLocalHoldCounter extends ThreadLocal<HoldCounter> {
    public HoldCounter initialValue() {
        return new HoldCounter();
    }
}
```

通过ThreadLocalHoldCounter 类，HoldCounter 与线程进行绑定。HoldCounter 是绑定线程的一个计数器，而 ThreadLocalHoldCounter 则是线程绑定的 ThreadLocal。 

- <font color='red'>HoldCounter是用来记录读锁重入数的对象 。</font>
- <font color='red'>ThreadLocalHoldCounter是ThreadLocal变量，用来存放不是第一个获取读锁的线程的其他线程的读锁重入数对象 。</font>

#### ④.写锁的获取

写锁是一个支持重进入的排它锁。如果当前线程已经获取了写锁，则增加写状态。如果当前线程在获取写锁时，读锁已经被获取（读状态不为0）或者该线程不是已经获取写锁的线程， 

则当前线程进入等待状态。 

写锁的获取是通过重写AQS中的tryAcquire方法实现的。

```java
protected final boolean tryAcquire(int acquires) {
    //当前线程
    Thread current = Thread.currentThread();
    //获取state状态 存在读锁或者写锁，状态就不为0
    int c = getState();
    //获取写锁的重入数
    int w = exclusiveCount(c);
    //当前同步状态state != 0，说明已经有其他线程获取了读锁或写锁
    if (c != 0) {
    // c!=0 && w==0 表示存在读锁
    // 当前存在读锁或者写锁已经被其他写线程获取，则写锁获取失败
        if (w == 0 || current != getExclusiveOwnerThread())
            return false;
    // 超出最大范围 65535
        if (w + exclusiveCount(acquires) > MAX_COUNT)
            throw new Error("Maximum lock count exceeded");
        //同步state状态
        setState(c + acquires);
        return true;
    }
    // writerShouldBlock有公平与非公平的实现, 非公平返回false，会尝试通过cas加锁
    //c==0 写锁未被任何线程获取，当前线程是否阻塞或者cas尝试获取锁
    if (writerShouldBlock() || !compareAndSetState(c, c + acquires))
        return false;
    //设置写锁为当前线程所有
    setExclusiveOwnerThread(current);
    return true;
}
```

通过源码我们可以知道： 

- 读写互斥 
- 写写互斥 
- 写锁支持同一个线程重入 
- writerShouldBlock写锁是否阻塞实现取决公平与非公平的策略（FairSync和NonfairSync）

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-ReentrantReadWriteLock%E5%85%AC%E5%B9%B3%E4%B8%8E%E9%9D%9E%E5%85%AC%E5%B9%B3.png?raw=true)

#### ⑤.写锁的释放 

写锁释放通过重写AQS的tryRelease方法实现 

```java
protected final boolean tryRelease(int releases) {
    //若锁的持有者不是当前线程，抛出异常 
    if (!isHeldExclusively())
        throw new IllegalMonitorStateException();
    int nextc = getState() ‐releases;
    //当前写状态是否为0，为0则释放写锁 
    boolean free = exclusiveCount(nextc) == 0;
    if (free)
        setExclusiveOwnerThread(null);
    setState(nextc);
    return free;
}
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-ReentrantReadWriteLock%E5%86%99%E9%94%81%E9%87%8A%E6%94%BE.png?raw=true)

#### ⑥.读锁的获取

实现共享式同步组件的同步语义需要通过重写AQS的tryAcquireShared方法和tryReleaseShared方法。读锁的获取实现方法为： 

```java
protected final int tryAcquireShared(int unused) {
    Thread current = Thread.currentThread();
    int c = getState();
    // 如果写锁已经被获取并且获取写锁的线程不是当前线程，当前线程获取读锁失败返回‐1 判断锁降级
    if (exclusiveCount(c) != 0 && getExclusiveOwnerThread() != current)
        return ‐1;
    //计算出读锁的数量
    int r = sharedCount(c);
    /**
     * 读锁是否阻塞 readerShouldBlock()公平与非公平的实现
     * r < MAX_COUNT： 持有读锁的线程小于最大数（65535）
     * compareAndSetState(c, c + SHARED_UNIT) cas设置获取读锁线程的数量
     */
    if (!readerShouldBlock() &&
            r < MAX_COUNT &&
            compareAndSetState(c, c + SHARED_UNIT)) { //当前线程获取读锁
        if (r == 0) { //设置第一个获取读锁的线程
            firstReader = current;
            firstReaderHoldCount = 1; //设置第一个获取读锁线程的重入数
        } else if (firstReader == current) { // 表示第一个获取读锁的线程重入
            firstReaderHoldCount++;
        } else { // 非第一个获取读锁的线程
            HoldCounter rh = cachedHoldCounter;
            if (rh == null || rh.tid != getThreadId(current))
                cachedHoldCounter = rh = readHolds.get();
            else if (rh.count == 0)
                readHolds.set(rh);
            rh.count++; //记录其他获取读锁的线程的重入次数
        }
        return 1;
    }
    // 尝试通过自旋的方式获取读锁,实现了重入逻辑
    return fullTryAcquireShared(current);
}
```

- 读锁共享，读读不互斥 
- 读锁可重入，每个获取读锁的线程都会记录对应的重入数 
- 读写互斥，锁降级场景除外 
- 支持锁降级，持有写锁的线程，可以获取读锁，但是后续要记得把读锁和写锁读释放 
- readerShouldBlock读锁是否阻塞实现取决公平与非公平的策略（FairSync和NonfairSync） 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-ReentrantReadWriteLock%E8%AF%BB%E9%94%81%E8%8E%B7%E5%8F%96.png?raw=true)

#### ⑦.读锁的释放 

获取到读锁，执行完临界区后，要记得释放读锁（如果重入多次要释放对应的次数），不然会阻塞其他线程的写操作。

读锁释放的实现主要通过方法tryReleaseShared：

```
protected final boolean tryReleaseShared(int unused) {
    Thread current = Thread.currentThread();
    //如果当前线程是第一个获取读锁的线程 
    if (firstReader == current) {
        // assert 
        firstReaderHoldCount > 0;
        if (firstReaderHoldCount == 1)
            firstReader = null;
        else
            firstReaderHoldCount--;
        //重入次数减1 
    } else {
        //不是第一个获取读锁的线程 
        HoldCounter rh = cachedHoldCounter;
        if (rh == null || rh.tid != getThreadId(current))
            rh = readHolds.get();
        int count = rh.count;
        if (count <= 1) {
            readHolds.remove();
            if (count <= 0)
                throw unmatchedUnlockException();
        }
        --rh.count;//重入次数减1 
    }
    for (; ; ) {
        //cas更新同步状态 
        int c = getState();
        int nextc = c - SHARED_UNIT;
        if (compareAndSetState(c, nextc))
            // Releasing the read lock has no effect on readers,  
            // but it may allow waiting writers to proceed if  
            // both read and write locks are now free. 
            return nextc == 0;
    }
}
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-ReentrantReadWriteLock%E7%9A%84CAS%E6%97%A0%E9%94%81.png?raw=true)

# 五、Semphore

## 5.1、Semphore介绍

<font color='red'>Semaphore，俗称信号量，它是操作系统中PV操作的原语在java的实现，它也是基于AbstractQueuedSynchronizer实现的。</font>

Semaphore的功能非常强大，大小为1的信号量就类似于互斥锁，通过同时只能有一个线程获取信号量实现。大小为n（n>0）的信号量可以实现限流的功能，它可以实现只能有n个线程同时获取信号量。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-Semaphore%E4%BF%A1%E5%8F%B7%E9%87%8F.png?raw=true)

<font color='red'>PV操作是操作系统一种实现进程互斥与同步的有效方法。</font>PV操作与信号量（S）的处理相关，P表示通 过的意思，V表示释放的意思。

用PV操作来管理共享资源时，首先要确保PV操作自身执行的正确性。 

- P操作的主要动作是： 

1. S减1； 
2. 若S减1后仍大于或等于0，则进程继续执行； 
3. 若S减1后小于0，则该进程被阻塞后放入等待该信号量的等待队列中，然后转进程调度。 

- V操作的主要动作是： 

1. ①S加1； 
2. ②若相加后结果大于0，则进程继续执行； 
3. ③若相加后结果小于或等于0，则从该信号的等待队列中释放一个等待进程，然后再返回原进程继续执行或转进程调度。

## 5.2、Semphore方法

### 5.2.1、构造方法

```java
pulibc Semaphore(int permits){
    sync = new NonfairSync(permits);
}
pulibc Semaphore(int permits,boolean fair){
    sync = fair ? new NonfairSync(permits):new NonfairSync(permits);
}
```

- permits 表示许可证的数量（资源数） 
- fair 表示公平性，如果这个设为 true 的话，下次执行的线程会是等待最久的线程 

### 5.2.2、常用方法

```java
public void acquire() throws InterruptedException 
public boolean tryAcquire() 
public void release() 
public int availablePermits() 
public final int getQueueLength() 
public final boolean hasQueuedThreads() 
protected void reducePermits(int reduction) 
protected Collection<Thread> getQueuedThreads() 
```

- <font color='red'>acquire() ：表示阻塞并获取许可 </font>
- <font color='red'>tryAcquire()： 方法在没有许可的情况下会立即返回 false，要获取许可的线程不会阻塞 </font>
- <font color='red'>release()：表示释放许可 </font>
- int availablePermits()：返回此信号量中当前可用的许可证数。 
- int getQueueLength()：返回正在等待获取许可证的线程数。 
- boolean hasQueuedThreads()：是否有线程正在等待获取许可证。 
- void reducePermit（int reduction）：减少 reduction 个许可证 
- Collection getQueuedThreads()：返回所有等待获取许可证的线程集合 

## 5.3、应用场景

### 5.3.1、限流

可以用于做流量控制，特别是公用资源有限的应用场景。

```java
public class SemaphoneTest2 {
    /**
     * 实现一个同时只能处理5个请求的限流器
     */
    private static Semaphore semaphore = new Semaphore(4);
    /**
     * 定义一个线程池
     */
    private static ThreadPoolExecutor executor = new ThreadPoolExecutor
            (10, 50, 60,
                    TimeUnit.SECONDS, new LinkedBlockingDeque<>(200));
    /**
     * 模拟执行方法
     */
    public static void exec() {
        try {
            //占用1个资源
            semaphore.acquire(1);
            //TODO  模拟业务执行
            System.out.println("执行exec方法");
            Thread.sleep(2000);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            //释放一个资源
            semaphore.release(1);
        }
    }
    public static void main(String[] args) throws InterruptedException {
        {
            for (; ; ) {
                Thread.sleep(100);
                // 模拟请求以10个/s的速度
                executor.execute(() -> exec());
            }
        }
    }
}
```



# 六、CountDownLatch

## 6.1、介绍

- <font color='red'>CountDownLatch（闭锁）是一个同步协助类，允许一个或多个线程等待，直到其他线程完成操作集。</font>
- CountDownLatch使用给定的计数值（count）初始化。<font color='red'>await方法会阻塞直到当前的计数值 （count）由于countDown()方法的调用达到0，count为0之后所有等待的线程都会被释放，并且随后对await方法的调用都会立即返回。这是一个一次性现象 —— count不会被重置。</font>
- 如果你需要一个重置count的版本，那么请考虑使用CyclicBarrier。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/AQS-CountDownLatch%E7%BB%93%E6%9E%84.png?raw=true)

## 6.2、CountDownLatch使用

### 6.2.1、CountDownLatch构造器

```java
public CountDownLatch(int count) {
    if (count < 0) throw new IllegalArgumentException("count < 0");
    this.sync = new Sync(count);
}
```

### 6.2.2、CountDownLatch常用方法

```java
// 调用 await() 方法的线程会被挂起，它会等待直到 count 值为 0 才继续执行 
public void await() throws InterruptedException { }; 
// 和 await() 类似，若等待 timeout 时长后，count 值还是没有变为 0，不再等待，继续执行
public boolean await(long timeout, TimeUnit unit) throws InterruptedException { }; 
// 会将 count 减 1，直至为 0 
public void countDown() { }; 
```

## 6.3、CountDownLatch应用场景

<font color='red'>CountDownLatch一般用作多线程倒计时计数器，强制它们等待其他一组（CountDownLatch的初始化决定）任务执行完成。</font>

CountDownLatch的两种使用场景：

### 6.3.1、让多个线程等待

模拟并发，让并发线程一起执行

```java
/**
 * 让多个线程等待：模拟并发，让并发线程一起执行
 */
public class CountDownLatchTest {
    public static void main(String[] args) throws InterruptedException {
        CountDownLatch countDownLatch = new CountDownLatch(1);
        for (int i = 0; i < 5; i++) {
            Thread.sleep(500);
            int num = i;
            new Thread(() -> {
                try {
                    //准备完毕……运动员都阻塞在这，等待号令
                    System.out.println("运动员"+(num +1)+"--进入等待");
                    countDownLatch.await();
                    String parter = "【" + Thread.currentThread().getName() + "】"
                            +"运动员"+(num +1);
                    System.out.println(parter + "--冲刺！！");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }).start();
        }
        Thread.sleep(2000);
        System.out.println("裁判十秒后将发出指令-----");
        Thread.sleep(10000);// 裁判准备发令
        System.out.println("裁判发出指令---------");
        countDownLatch.countDown();// 发令枪：执行发令
    }
}
```

结果：

```java
运动员1--进入等待
运动员2--进入等待
运动员3--进入等待
运动员4--进入等待
运动员5--进入等待
裁判十秒后将发出指令-----
裁判发出指令---------
【Thread-0】运动员1--冲刺！！
【Thread-1】运动员2--冲刺！！
【Thread-2】运动员3--冲刺！！
【Thread-3】运动员4--冲刺！！
【Thread-4】运动员5--冲刺！！
```

### 6.3.2、让单个线程等待

让单个线程等待，多个线程(任务)完成后，进行汇总合并：

```java
/**
 * 让单个线程等待：多个线程(任务)完成后，进行汇总合并
 */
public class CountDownLatchTest2 {
    public static void main(String[] args) throws Exception {
        CountDownLatch countDownLatch = new CountDownLatch(5);
        for (int i = 0; i < 5; i++) {
            final int index = i;
            new Thread(() -> {
                try {
                    Thread.sleep(1000 +
                            ThreadLocalRandom.current().nextInt(1000));
                    System.out.println(Thread.currentThread().getName()
                            + " finish task" + index);
                    countDownLatch.countDown();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }).start();
        }
        // 主线程在阻塞，当计数器==0，就唤醒主线程往下执行。
//        countDownLatch.await(10, TimeUnit.SECONDS);
        countDownLatch.await();
        System.out.println("主线程:在所有任务运行完成后，进行结果汇总");
    }
}
```

结果：

```java
Thread-3 finish task3
Thread-2 finish task2
Thread-1 finish task1
Thread-4 finish task4
Thread-0 finish task0
```

如果改为CountDownLatch countDownLatch = new CountDownLatch(6)，启动5个线程，还差一个。

调用countDownLatch.await()，如果未设置超时时间则就会一直等下去。

## 6.4、CountDownLatch实现原理

- 底层基于 AbstractQueuedSynchronizer 实现，CountDownLatch 构造函数中指定的count直接赋给AQS的state。<font color='red'>每次countDown()则都是release(1)减1，最后减到0时unpark阻塞的线程，这一步是由最后一个执行countdown方法的线程执行的。 </font>
- 而调用await()方法时，当前线程就会判断state属性是否为0，如果为0，则继续往下执行，如果不为0，则使当前线程进入等待状态，直到某个线程将state属性置为0，其就会唤醒在 await()方法中等待的线程。 

## 6.5、CountDownLatch与Thread.join的区别

- CountDownLatch的作用就是<font color='red'>允许一个或多个线程等待其他线程完成操作</font>，看起来有点类似join() 方法，但其提供了比 join() 更加灵活的API。 
- CountDownLatch可以手动<font color='red'>控制在n个线程里调用n次countDown()方法使计数器进行减一操作，也可以在一个线程里调用n次执行减一操作。 </font>
- <font color='red'>join() 的实现原理是不停检查join线程是否存活，如果 join 线程存活则让当前线程永远等待。</font>所以两者之间相对来说还是CountDownLatch使用起来较为灵活。

## 6.6、**CountDownLatch与**CyclicBarrier**的区别** 

**CountDownLatch和CyclicBarrier都能够实现线程之间的等待，只不过它们侧重点不同：** 

1. CountDownLatch的计数器只能使用一次，而CyclicBarrier的计数器可以reset()方法重置。所以CyclicBarrier能处理更为复杂的业务场景，
2. 比如如果计算发生错误，可 以重置计数器，并让线程们重新执行一次。
3. CyclicBarrier还提供getNumberWaiting(可以获得CyclicBarrier阻塞的线程数量)、isBroken(用来知道阻塞的线程是否被中断)等方法。 
4. <font color='red'>CountDownLatch会阻塞主线程，CyclicBarrier不会阻塞主线程，只会阻塞子线程。</font>
5. CountDownLatch和CyclicBarrier都能够实现线程之间的等待，只不过它们侧重点不同：
   + <font color='red'>CountDownLatch一般用于一个或多个线程，等待其他线程执行完任务后，再执行。</font>
   + <font color='red'>CyclicBarrier一般用于一组线程互相等待至某个状态，然后这一组线程再同时执行。</font>

6. CyclicBarrier 还可以提供一个 barrierAction，合并多线程计算结果。

7. <font color='red'>CyclicBarrier是通过ReentrantLock的"独占锁"和Conditon来实现一组线程的阻塞唤 醒的，而CountDownLatch则是通过AQS的“共享锁”实现 。</font>

# 七、CyclicBarrier

## 7.1、CyclicBarrier介绍

从字面上的意思可以知道，这个类的中文意思是“循环栅栏”。大概的意思就是一个可循环利用的屏障。

## 7.2、CyclicBarrier的使用

### 7.2.1、构造方法

```java
// parties表示屏障拦截的线程数量，每个线程调用 await 方法告诉 CyclicBarrier 我已经到达了屏障，然后当前线程被阻塞。 
public CyclicBarrier(int parties) 
// 用于在线程到达屏障时，优先执行 barrierAction，方便处理更复杂的业务场景(该线程的执行时机是在到达屏障之后再执行) 
public CyclicBarrier(int parties, Runnable barrierAction) 
```

### 7.2.2、重要方法

```java
//屏障 指定数量的线程全部调用await()方法时，这些线程不再阻塞 
// BrokenBarrierException 表示栅栏已经被破坏，破坏的原因可能是其中一个线程 await()时被中断或者超时 
public int await() throws InterruptedException, BrokenBarrierException 
public int await(long timeout, TimeUnit unit) throws InterruptedException, BrokenBarrierException, TimeoutException 
//循环 通过reset()方法可以进行重置 
public void reset() 
```

## 7.3、CyclicBarrier的应用场景

+ <font color='red'>CyclicBarrier 可以用于多线程计算数据，最后合并计算结果的场景。</font>

```java
**
 * 栅栏与闭锁的关键区别在于，所有的线程必须同时到达栅栏位置，才能继续执行。
 */
public class CyclicBarrierTest2 {
    //保存每个学生的平均成绩
    private ConcurrentHashMap<String, Integer> map=new ConcurrentHashMap<String,Integer>();
    private ExecutorService threadPool= Executors.newFixedThreadPool(3);
    private CyclicBarrier cb=new CyclicBarrier(3,()->{
        int result=0;
        Set<String> set = map.keySet();
        for(String s:set){
            result+=map.get(s);
        }
        System.out.println("三人平均成绩为:"+(result/3)+"分");
    });
    public void count(){
        for(int i=0;i<3;i++){
            threadPool.execute(new Runnable(){
                @Override
                public void run() {
                    //获取学生平均成绩
                    int score=(int)(Math.random()*40+60);
                    map.put(Thread.currentThread().getName(), score);
                    System.out.println(Thread.currentThread().getName()
                            +"同学的平均成绩为："+score);
                    try {
                        //执行完运行await(),等待所有学生平均成绩都计算完毕
                        cb.await();
                    } catch (InterruptedException | BrokenBarrierException e) {
                        e.printStackTrace();
                    }
                }
            });
        }
    }
    public static void main(String[] args) {
        CyclicBarrierTest2 cb=new CyclicBarrierTest2();
        cb.count();
    }
}
```

结果：

```java
pool-1-thread-3同学的平均成绩为：75
pool-1-thread-1同学的平均成绩为：98
pool-1-thread-2同学的平均成绩为：88
三人平均成绩为:87分
```

+ 利用CyclicBarrier的计数器能够重置，屏障可以重复使用的特性，可以支持类似“人满发车”的场景

  ```java
  public class CyclicBarrierTest3 {
      public static void main(String[] args) {
          AtomicInteger counter = new AtomicInteger();
          ThreadPoolExecutor threadPoolExecutor = new ThreadPoolExecutor(
                  5, 5, 1000, TimeUnit.SECONDS,
                  new ArrayBlockingQueue<>(100),
                  (r) -> new Thread(r, counter.addAndGet(1) + " 号 "),
                  new ThreadPoolExecutor.AbortPolicy());
          CyclicBarrier cyclicBarrier = new CyclicBarrier(5,
                  () -> System.out.println("裁判：比赛开始~~"));
          for (int i = 0; i < 5; i++) {
              threadPoolExecutor.submit(new Runner(cyclicBarrier));
          }
      }
      static class Runner extends Thread{
          private CyclicBarrier cyclicBarrier;
          public Runner (CyclicBarrier cyclicBarrier) {
              this.cyclicBarrier = cyclicBarrier;
          }
          @Override
          public void run() {
              try {
                  int sleepMills = ThreadLocalRandom.current().nextInt(1000);
                  Thread.sleep(sleepMills);
                  System.out.println(Thread.currentThread().getName() + " 选手已就位, 准备共用时： " + sleepMills + "ms" + cyclicBarrier.getNumberWaiting());
                  cyclicBarrier.await();
              } catch (InterruptedException e) {
                  e.printStackTrace();
              }catch(BrokenBarrierException e){
                  e.printStackTrace();
              }
          }
      }
  }
  ```

  结果：

  ```java
  1 号  选手已就位, 准备共用时： 141ms0
  4 号  选手已就位, 准备共用时： 311ms1
  5 号  选手已就位, 准备共用时： 357ms2
  3 号  选手已就位, 准备共用时： 465ms3
  2 号  选手已就位, 准备共用时： 913ms4
  裁判：比赛开始~~
  ```

  
