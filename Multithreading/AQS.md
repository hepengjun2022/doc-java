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



# 五、Semphore

# 六、CountDownLatch

