# 一、Synchronized基础

## 1.1、Java共享内存模型带来的线程安全的问题

首先来看一个现象

```java
public class SyncDemo {
    private static  volatile int counter = 0;
    public static void increment() {
        counter++;
    }
    public static void decrement() {
        counter--;
    }
    public static void main(String[] args) throws InterruptedException {
        Object object=new Object();
        Thread t1 = new Thread(() -> {
//            synchronized (object){
                for (int i = 0; i < 50000; i++) {
                    increment();
                }
//            }
        }, "t1");
        Thread t2 = new Thread(() -> {
//            synchronized (object){
                for (int i = 0; i < 50000; i++) {
                    decrement();
                }
//            }
        }, "t2");
        t1.start();
        t2.start();
        t1.join();
        t2.join();
        log.info("counter={}", counter);
    }
}
```

结果：

```java
19:18:18.437 [main] INFO com.tuling.jucdemo.sync.SyncDemo - counter=-3441
19:21:04.464 [main] INFO com.tuling.jucdemo.sync.SyncDemo - counter=21170
```

分析：

以上程序得出的结果可能是正数，也有可能是负数。说明Java中对静态变量的自增或者自减操作并不是原子操作。

我们可以看JVM下的i++和i--的字节码指令可以看出自增或者自减不具有原子性：

```java
i++的JVM 字节码指令：

getstatic i // 获取静态变量i的值 
iconst_1 // 将int常量1压入操作数栈
iadd // 自增
putstatic i // 将修改后的值存入静态变量i

i--的JVM 字节码指令 
getstatic i // 获取静态变量i的值 
iconst_1 // 将int常量1压入操作数栈 
isub // 自减 
putstatic i // 将修改后的值存入静态变量i 
```

## 1.2、临界区（ Critical Section） 

既然要了解上述现象，就得知道临界区是什么？

如果一段代码块内存在<font color='red'>多个线程对共享资源进行读写操作</font>，则称这段代码块为<font color='red'>临界区，其共享资源为临界资源。</font>

```java
//临界资源
private static  volatile int counter = 0;
public static void increment() {//临界区
    counter++;
}
public static void decrement() {//临界区
    counter--;
}
```

结论：因为在多个线程对共享资源读写操作时发生指令交错，就会出现上述现象。

## 1.3、竞态条件（ Race Condition ）

<font color='red'>多个线程</font>在<font color='red'>临界区内执行</font>时，由于<font color='red'>代码的执行顺序不同</font>而导致的<font color='red'>结果无法预测</font>，称为发生了<font color='red'>竞态条件</font>。

### Ⅰ .避免临界区的竞态条件发生的手段：

- 阻塞方式：synchronized，Lock
- 非阻塞方式：原子变量，如用CAS,Atomic类（原子变量保证了该变量的所有操作都是原子的，不会因为多线程的同时访问而导致脏数据的读取问题。）

### Ⅱ.java中采用synchronized关键字完成互斥和同步的区别：

- 互斥：保证临界区的静态条件发生，即同一时间只能有一个线程执行临界区的代码。
- 同步：由于线程的执行先后顺序不同，需要一个线程等待其他线程运行到某个点。

## 1.4、Synchronized的使用

### Ⅰ.概念：

synchronized同步块是Java提供的<font color='red'>一种原子性内置锁</font>，Java中的<font color='red'>每一个对象都可以当作一个同步锁</font>来使用，<font color='red'>这些Java内置的且看不到的锁，也被叫做监视器锁（Monitor）。</font>

### Ⅱ.加锁方式：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Sychronized-%E5%8A%A0%E9%94%81%E6%96%B9%E5%BC%8F.png?raw=true)

```java
Object obj=new Object();
//加锁方式一
public static void increment() {
    synchronized(obj){
           counter++; 
    }
}
public static void decrement() {
    synchronized(obj){
           counter--; 
    }
}
//加锁方式二：
public static synchronized void increment() {
           counter++; 
}
public static synchronized void decrement() {
           counter--; 
}
```

结论：<font color='red'>synchronized使用对象锁保证了临界区代码的原子性。</font>

# 二、Synchronized高级

## 2.1、Synchronized底层原理：

### Ⅰ . Synchronized介绍：

- Synchronized是JVM内置锁，基于Monitor来实现的，依赖底层操作系统的互斥原语Mutex（互斥量）。
- jdk1.5之前是一个重量级锁，jdk1.5后进行了版本优化，如锁粗化化（Lock Coarsening）、锁消除（Lock Elimination）、轻量级锁（Lightweight Locking）、偏向锁锁（Biased Locking）、自适应自旋（Adaptive Spinning）等技术来减少锁的开销。
- 内置锁的并发性能已经与Lock持平。

### Ⅱ.Java虚拟机内部如何实现synchronized同步原理

通过一个同步结构支持方法和方法中的指令序列的同步：moniter。

- 同步方法：通过方法中的access_flags中设置ACC_SYNCHRONIZED标志来实现的；

  ```java
  public static synchronized void increment() {
      counter++;
  }
  public static synchronized void decrement() {
      counter--;
  }
  ```

  **查看synchronized的字节码指令序列：**

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E6%9F%A5%E7%9C%8B%E5%AD%97%E8%8A%82%E7%A0%81%E6%8C%87%E4%BB%A4%E5%BA%8F%E5%88%97.png?raw=true)

  ```java
  public static void increment() {
      synchronized (lock){
              counter++;
      }
  }
  public static void decrement() {
      synchronized (lock) {
          counter--;
      }
  }
  ```

  **查看synchronized的字节码指令序列：**

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E6%9F%A5%E7%9C%8B%E5%AD%97%E8%8A%82%E7%A0%81%E6%8C%87%E4%BB%A4%E5%BA%8F%E5%88%9702.png?raw=true)

  注意：两个指令的执行是<font color='red'>JVM通过调用操作系统的互斥原语mutex来实现的，被阻塞的线程会被挂起或者等待重新调度，这会导致“用户态和内核态”两个状态之间来回切换，对性能影响较大。</font>

### Ⅲ.Monitor（管程/监视器）

- Monitor，直译为<font color='red'>监视器</font>，操作系统一般翻译为<font color='red'>管程</font>。管程是指<font color='red'>管理共享变量以及对共享变量操作的过程，让他们支持并发。</font>
- Java1.5之后提供的SDK并发包也是以管程为基础的。
- Java中实现管程技术，例如：synchronized关键字、wait()、notify()、notifyAll()。

### Ⅳ.MESA管程模型

在管程的发展史上，先后出现过三种不同的管程模型，分别是Hasen模型、Hoare模型和 MESA模型。现在正在广泛使用的是MESA模型。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-MESA%E6%A8%A1%E5%9E%8B.png?raw=true)

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E7%AE%A1%E7%A8%8B%E6%A8%A1%E5%9E%8B%E8%AF%AD%E4%B9%89%E5%8C%96.png?raw=true)

分析：管程引入了条件变量的概念，<font color='red'>每一个条件变量都有对应的一个等待队列</font>。条件变量和等待队列作用就是<font color='red'>解决线程之间的同步问题</font>。

**对于MESA管程来说，有一个编程范式：**

```java
while(条件不满足) { 
    wait();
}
```

- 线程被唤醒的时间和获得锁继续执行的时间是不一致的，被唤醒的线程再次执行时可能条件又不满足了，所以需要循环检查条件。
- MESA模型的wait()方法还有一个超时参数，为了避免线程进入等待队列永久阻塞。 

### Ⅴ.notify()和notifyAll()使用条件

满足三个条件可以使用notify()，其余情况尽量使用notifyAll()：

1. 所有等待线程拥有相同的等待条件；
2. 所有等待线程被唤醒后，执行相同的操作；
3. 只需要唤醒一个线程；

### Ⅵ.Java语言的内置管程sychronized

Java 参考了 MESA 模型，语言内置的管程（synchronized）对 MESA 模型进行了精简。MESA 模型中，条件变量可以有多个，<font color='red'>Java 语言内置的管程里只有一个条件变量。</font>模型如下图所示：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E5%86%85%E7%BD%AEMESA%E7%AE%A1%E7%A8%8B.png?raw=true)

### Ⅶ.Monitor机制在Java中的实现

java.lang.Object 类定义了<font color='red'> wait()，notify()，notifyAll() </font>方法，这些方法的具体实现，<font color='red'>依赖于ObjectMonitor实现，这是JVM内部基于C++实现的一套机制。 </font>

ObjectMonitor其主要数据结构如下（hotspot源码ObjectMonitor.hpp）：

```java
ObjectMonitor() {
  _header       = NULL; //markOop对象头
  _count        = 0; 
  _waiters      = 0, //等待线程数
  _recursions   = 0; //锁的重入次数
  _object       = NULL; //存储锁对象 
  _owner        = NULL;  //指向获得ObjectMonitor对象的线程（当前获取锁的线程）
  _WaitSet      = NULL; // 等待线程（调用wait）组成的双向循环链表，_WaitSet是第一个节点
  _WaitSetLock  = 0 ;
  _Responsible  = NULL ;
  _succ         = NULL ;
  _cxq          = NULL ; //多线程竞争锁会先存到这个单向链表中 （FILO栈结构） wait()
  FreeNext      = NULL ;
  _EntryList    = NULL ;//存放 在进入或重新进入时被阻塞(blocked)的线程 (也是存竞争锁失败的线程)notify() 
  _SpinFreq     = 0 ;
  _SpinClock    = 0 ;
  OwnerIsThread = 0 ;
  _previous_owner_tid = 0;//监视器前一个拥有者的线程id
}
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-Monitor%E6%9C%BA%E5%88%B6%E5%9C%A8Java%E4%B8%AD%E5%AE%9E%E7%8E%B0.png?raw=true)

- 获取锁时：将当前线程插入到cxq的头部。
- 释放锁时：默认策略（QMode=0）是：如果EntryList为空，则将 cxq中的元素按原有顺序插入到EntryList，并唤醒第一个线程，也就是当EntryList为空时，是后来的线程先获取锁。_EntryList不为空，直接从_EntryList中唤醒线程。

cxq是栈结构，EntryList是队列，假如有T1,T2，T3线程进入cxq，则会进行压占操作，如果EntryList为空，则将cxq线程按照先入后出的顺序放入EntryList(T3,T2,T1)，然后唤醒第一个线程T3去获取锁执行，由此可知，<font color='red'>synchronized为非公平锁。</font>

## 2.2、对象头的内存布局

### Ⅰ 、对象头详解

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E5%AF%B9%E8%B1%A1%E5%A4%B4%E7%BB%84%E6%88%90.png?raw=true)

Hotspot虚拟机的对象头包括：

- MarkWord

用于存储对象自身的运行时数据，如 <font color='red'>哈希码（HashCode）、GC分代年龄、锁状态标志、线程持有的锁、偏向线程ID、偏向时间戳</font>等，这部分数据的长度在32位和64位的虚拟机中分别为32bit和64bit，官方称它为“Mark Word”。

- Klass Pointer

对象头的另外一部分是klass类型指针，即对象指向它的类元数据的指针，虚拟机通过这个指针来确定这个对象是哪个类的实例。 32位4字节，64位开启指针压缩或最大堆内存<32g时4字节，否则8字节。

jdk1.8默认开启指针压缩后为4字节，当在JVM参数中关闭指针压缩（-XX:- UseCompressedOops）后，长度为8字节。

- 数组长度（只有数组对象才有）

如果对象是一个数组, 那在对象头中还必须有一块数据用于记录数组长度。 4字节。 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E5%AF%B9%E8%B1%A1%E5%A4%B4%E5%AD%98%E5%82%A8%E5%9B%BE.png?raw=true)

**使用JOL工具查看内存布局**

此工具可以查看new出来的一个java对象的内部布局,以及一个普通的java对象占用多少字节。

```java
<!‐‐ 查看Java 对象布局、大小工具 ‐‐> 
//引入依赖
<dependency> 
    <groupId>org.openjdk.jol</groupId> 
    <artifactId>jol‐core</artifactId> 
    <version>0.10</version> 
</dependency> 
//使用方法
System.out.println(ClassLayout.parseInstance(obj).toPrintable());
//测试
public static void main(String[] args) throws InterruptedException { 
    Object obj = new Object(); 
    //查看对象内部信息 
    System.out.println(ClassLayout.parseInstance(obj).toPrintable()); 
} 
```

结果：

```java
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)    markword               01 00 00 00 (00000001 00000000 00000000 00000000) (1)
      4     4        (object header)    markword               00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)   klass pointer           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)   padding（对齐填充位）
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total
```

- OFFSET：偏移地址，单位字节； 
- SIZE：占用的内存大小，单位为字节； 
- TYPE DESCRIPTION：类型描述，其中object header为对象头； 
- VALUE：对应内存中当前存储的值，二进制32位； 

### Ⅱ.MarkWord的结构

Hotspot通过markOop类型实现Mark Word，具体实现位于<font color='red'>markOop.hpp文件</font>中。

由于对 象需要存储的运行时数据很多，考虑到虚拟机的内存使用，markOop被设计成一个非固定的数据 结构，以便在极小的空间存储尽量多的数据，根据对象的状态复用自己的存储空间。 

简单点理解：MarkWord 结构搞得这么复杂，是因为需要<font color='red'>节省内存</font>，让同一个内存区域在不 同阶段有不同的用处。 

```java
//  32 bits:
//  --------
//             hash:25 ------------>| age:4    biased_lock:1 lock:2 (normal object)
//             JavaThread*:23 epoch:2 age:4    biased_lock:1 lock:2 (biased object)
//             size:32 ------------------------------------------>| (CMS free block)
//             PromotedObject*:29 ---------->| promo_bits:3 ----->| (CMS promoted object)
//
//  64 bits:
//  --------
//  unused:25 hash:31 -->| unused:1   age:4    biased_lock:1 lock:2 (normal object)
//  JavaThread*:54 epoch:2 unused:1   age:4    biased_lock:1 lock:2 (biased object)
//  PromotedObject*:61 --------------------->| promo_bits:3 ----->| (CMS promoted object)
//  size:64 ----------------------------------------------------->| (CMS free block)
//
//  unused:25 hash:31 -->| cms_free:1 age:4    biased_lock:1 lock:2 (COOPs && normal object)
//  JavaThread*:54 epoch:2 cms_free:1 age:4    biased_lock:1 lock:2 (COOPs && biased object)
//  narrowOop:32 unused:24 cms_free:1 unused:4 promo_bits:3 ----->| (COOPs && CMS promoted object)
//  unused:21 size:35 -->| cms_free:1 unused:7 ------------------>| (COOPs && CMS free block)
//
```

- hash：<font color='red'>保存对象的哈希码</font>。运行期间调用System.identityHashCode()来计算，延迟计算，并把结果赋值到这里。
- age：<font color='red'>保存对象的分代年龄</font>。表示对象被GC的次数，当该次数到达阈值的时候，对象就会转移到老年代。
- biased_lock：<font color='red'>偏向锁标识位</font>。由于无锁和偏向锁的锁标识都是 01，没办法区分，这里引入一位的偏向锁标识位。
- lock：<font color='red'>锁状态标识位。区分锁状态</font>，比如11时表示对象待GC回收状态, 只有最后2位锁标识(11)有效。 
- JavaThread*：<font color='red'>保存持有偏向锁的线程ID</font>。偏向模式的时候，当某个线程持有对象的时候，对象这里就会被置为该线程的ID。 在后面的操作中，就无需再进行尝试获取锁的动作。这个线程ID并不是JVM分配的线程ID号，和Java Thread中的ID是两个概念。
- epoch：<font color='red'>保存偏向时间戳</font>。偏向锁在CAS锁操作过程中，偏向性标识，表示对象更偏向哪个锁。 

**32位JVM下的对象结构描述**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-32VM%E5%AF%B9%E8%B1%A1%E7%BB%93%E6%9E%84.png?raw=true)

**64位JVM下的对象结构描述**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-64JVM%E5%AF%B9%E8%B1%A1%E7%BB%93%E6%9E%84.png?raw=true)

- **ptr_to_lock_record**：轻量级锁状态下，指向栈中锁记录的指针。当锁获取是无竞争时，JVM使用原子操作而不是OS互斥，这种技术称为轻量级锁定。在轻量级锁定的情况下，JVM通过CAS操作在对象的Mark Word中设置指向锁记录的指针。 

- **ptr_to_heavyweight_monitor**：重量级锁状态下，指向对象监视器Monitor的指针。如果两个不同的线程同时在同一个对象上竞争，则必须将轻量级锁定升级到Monitor以管理等待的线程。在重量级锁定的情况下，JVM在对象的ptr_to_heavyweight_monitor设置指向Monitor的指针。

**Mark Word中锁标记枚举 :**

```java
enum { 
    locked_value = 0, //00 轻量级锁 
    unlocked_value = 1, //001 无锁 
    monitor_value = 2, //10 监视器锁，也叫膨胀锁，也叫重量级锁 
    marked_value = 3, //11 GC标记 
    biased_lock_pattern = 5 //101 偏向锁 
}; 
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E9%94%81%E7%8A%B6%E6%80%81%E8%A1%A8.png?raw=true)

## 2.3、Synchronized锁状态

### Ⅰ 、锁状态介绍

#### 1.偏向锁

（Java 6之后加入的新锁）

##### ①. 为什么会有偏向锁？

在大多数情况下，锁不仅不存在多线程竞争，而且<font color='red'>总是由同一线程多次获得，因此为了减少同一线程获取锁(会涉及到一些CAS操作,耗时)的代价而引入偏向锁。</font>

##### ②.偏向锁的核心思想？

如果一个线程获得了锁，那么锁就进入偏向模式，此时Mark Word 的结构也变为偏向锁结构，当同一个线程再次请求锁时，无需再做任何同步操作，即获取锁的过程，这样就省去了大量有关锁申请的操作，从而也就提供程序的性能。所以，<font color='red'>对于没有锁竞争的场合，偏向锁有很好的优化效果</font>，毕竟极有可能连续多次是同一个线程申请相同的锁。

##### ③.什么场合适合偏向锁？

- 对于总是由同一线程多次获得锁的场景，偏向锁很合适。
- 对于锁竞争比较激烈的场合，每次申请锁的线程都不相同，偏向锁就会失效

需要注意的是，<font color='red'>偏向锁失败后，并不会立即膨胀为重量级锁，而是先升级为轻量级锁。 </font>

当JVM启用了偏向锁模式（jdk6默认开启），新创建对象的Mark Word中的Thread Id为0， 说明此时处于可偏向但未偏向任何线程，也叫做<font color='red'>匿名偏向状态(anonymously biased)。</font>

默认开启偏向锁 ：

开启偏向锁：-XX:+UseBiasedLocking -XX:BiasedLockingStartupDelay=0 

关闭偏向锁：-XX:-UseBiasedLocking 

##### ③.偏向锁延迟偏向

偏向锁模式存在偏向锁延迟机制：

HotSpot 虚拟机在启动后有个 4s 的延迟才会对每个新建的对象开启偏向锁模式。JVM启动时会进行一系列的复杂活动，比如装载配置，系统类初始化等等。在这个过程中会使用大量synchronized关键字对对象加锁，且这些锁大多数都不是偏向锁。为了减少初始化时间，JVM默认延时加载偏向锁。 

验证：

```java
@Slf4j  
public class LockEscalationDemo{ 
    public static void main(String[] args) throws InterruptedException { 
        log.debug(ClassLayout.parseInstance(new Object()).toPrintable());  
        Thread.sleep(4000);  
        log.debug(ClassLayout.parseInstance(new Object()).toPrintable());  
    }  
} 
结果：
 OFFSET  SIZE   TYPE DESCRIPTION               VALUE
      0     4        (object header)           01 00 00 00 (00000001 00000000 00000000 00000000) (1)
      4     4        (object header)           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

01:07:43.412 [main] DEBUG com.tuling.jucdemo.sync.MyTestLockEscalation - java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION               VALUE        从001变为101（无锁变为偏向锁）
      0     4        (object header)           05 00 00 00 (00000101 00000000 00000000 00000000) (5)
      4     4        (object header)           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total
```

##### ④.偏向锁撤销之调用对象HashCode

调用锁对象的obj.hashCode()或System.identityHashCode(obj)方法会导致该对象的偏向锁被撤销。因为对于一个对象，其HashCode只会生成一次并保存，偏向锁是没有地方保存hashcode的。

- 轻量级锁会在锁记录中记录 hashCode ，锁记录在线程栈的栈空间创建的。
- 重量级锁会在 Monitor 中记录 hashCode

当对象处于可偏向状态（线程ID为0）和已偏向的状态下，调用HashCode计算将会使对象再也无法偏向：

- 当对象可偏向时（处于匿名偏向状态），MarkWord将变成未锁定状态，调用HashCode()只能升级成轻量锁； 

- 当对象正处于偏向状态时，调用HashCode()将使偏向锁强制升级成重量锁。 

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E5%81%8F%E5%90%91%E9%94%81%E6%92%A4%E9%94%80.png?raw=true)

##### ⑤.偏向锁撤销之调用wait/notify

- 偏向锁状态调用obj.notify() 会升级为轻量级锁
- 偏向锁状态调用obj.wait(timeout) 会升级为重量级锁 

```java
public class waitTest {

    public static void main(String[] args) {
        Object obj = new Object();
        log.debug(Thread.currentThread().getName() + "准备执行中。。。\n"
                + ClassLayout.parseInstance(obj).toPrintable());
        synchronized (obj) {
            obj.notify();
            log.debug(Thread.currentThread().getName() + "获取锁执行中。。。\n"
                    + ClassLayout.parseInstance(obj).toPrintable());
            try {
                obj.wait(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            log.debug(Thread.currentThread().getName() + "获取锁执行中。。。\n"
                    + ClassLayout.parseInstance(obj).toPrintable());
        }
    }
}
结果：
01:37:34.131 [main] DEBUG com.tuling.jucdemo.mytest.waitTest - main准备执行中。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                  VALUE        无锁
      0     4        (object header)              01 00 00 00 (00000001 00000000 00000000 00000000) (1)
      4     4        (object header)              00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)              e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

01:37:34.134 [main] DEBUG com.tuling.jucdemo.mytest.waitTest - main获取锁执行中。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                  VALUE       调用notify()从无锁升级成轻量级锁
      0     4        (object header)              e0 f7 33 03 (11100000 11110111 00110011 00000011) (53737440)
      4     4        (object header)              00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)              e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

01:37:34.235 [main] DEBUG com.tuling.jucdemo.mytest.waitTest - main获取锁执行中。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                  VALUE        调用wait()从轻量级锁直接升级成重量级锁
      0     4        (object header)              ea fd e1 1c (11101010 11111101 11100001 00011100) (484572650)
      4     4        (object header)              00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)              e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total
```

#### 2.轻量级锁

存在多个线程交替去争夺锁，并不是很激烈，这时候可能升级为轻量级锁。

注意：

倘若偏向锁失败，虚拟机并不会立即升级为重量级锁，它还会尝试使用一种称为轻量级锁的优化手段，此时Mark Word 的结构也变为轻量级锁的结构。

**轻量级锁所适应的场景？**

适合线程交替执行同步块的场景，但是如果存在同一时间多个线程访问同一把锁的场合，就会导致轻量级锁膨胀为重量级锁。 

#### 3.重量级锁

多线程竞争激烈的场景，膨胀期间会创建monitor对象，这时操作由用户态转化为内核态，操作比较消耗性能。

### Ⅱ、锁升级

模拟多个线程去争夺同一把锁的场景：

```java
public static void main(String[] args) throws InterruptedException {
        log.debug(ClassLayout.parseInstance(new Object()).toPrintable());
        //HotSpot 虚拟机在启动后有个 4s 的延迟才会对每个新建的对象开启偏向锁模式
        Thread.sleep(5000);
        Object obj = new Object();
        log.debug("5秒后升级为偏向锁......................");
        log.debug(ClassLayout.parseInstance(obj).toPrintable());
        new Thread(new Runnable() {
            @Override
            public void run() {
                log.debug(Thread.currentThread().getName() + "开始执行。。。\n" + ClassLayout.parseInstance(obj).toPrintable());
                synchronized (obj) {
                    log.debug(Thread.currentThread().getName() + "获取锁执行中。。。\n" + ClassLayout.parseInstance(obj).toPrintable());
                }
                log.debug(Thread.currentThread().getName() + "释放锁。。。\n" + ClassLayout.parseInstance(obj).toPrintable());
            }
        }, "thread1").start();
        //控制线程竞争时机
        Thread.sleep(3000);
        new Thread(new Runnable() {
            @Override
            public void run() {
                log.debug(Thread.currentThread().getName() + "开始执行10000次。。。。\n" );
                for (int i = 0; i < 10000; i++) {
                    try {
                        if(i<4)
                            Thread.sleep(200);
                        else
                            Thread.sleep(1);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    synchronized (obj) {
                        if (i == 0 || i == 5000 || i == 1)
                            log.debug(Thread.currentThread().getName() + "第" + (i + 1) + "次获取锁执行中。。。。\n"  + ClassLayout.parseInstance(obj).toPrintable());
                    }
                }
            }
        }, "thread2").start();
        new Thread(new Runnable() {
            @Override
            public void run() {
              log.debug(Thread.currentThread().getName() + "开始执行10000次。。。。。\n" );
                for (int i = 0; i < 10000; i++) {
                    try {
                        if(i<4)
                            Thread.sleep(100);
                        else
                        Thread.sleep(1);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    synchronized (obj) {
                        if (i == 0 || i == 5000 || i == 1)
                            log.debug(Thread.currentThread().getName() + "第" + (i + 1) + "次获取锁执行中。。。。。\n"  + ClassLayout.parseInstance(obj).toPrintable());
                    }
                }
                try {
                    Thread.sleep(2000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }, "thread3").start();
        Thread.sleep(10000);
        log.debug(" 全部执行完成后-----------------");
        log.debug(ClassLayout.parseInstance(obj).toPrintable());
    }
```

结果：

```java
02:46:43.784 [main] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                 VALUE    初始状态：无锁状态
      0     4        (object header)             01 00 00 00 (00000001 00000000 00000000 00000000) (1)
      4     4        (object header)             00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)             e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

02:46:48.786 [main] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - 5秒后升级为偏向锁......................
02:46:48.786 [main] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                 VALUE    5秒变为偏向锁（偏向锁延迟机制，默认4秒后）
      0     4        (object header)             05 00 00 00 (00000101 00000000 00000000 00000000) (5)
      4     4        (object header)             00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)             e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

02:46:48.788 [thread1] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - thread1开始执行。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                 VALUE
      0     4        (object header)             05 00 00 00 (00000101 00000000 00000000 00000000) (5)
      4     4        (object header)             00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)             e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

02:46:48.788 [thread1] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - thread1获取锁执行中。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                  VALUE
      0     4        (object header)              05 c8 85 1f (00000101 11001000 10000101 00011111) (528861189)
      4     4        (object header)              00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)              e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

02:46:48.789 [thread1] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - thread1释放锁。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                   VALUE    
      0     4        (object header)               05 c8 85 1f (00000101 11001000 10000101 00011111) (528861189)
      4     4        (object header)               00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)               e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

02:46:51.788 [thread2] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - thread2开始执行10000次。。。。

02:46:51.789 [thread3] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - thread3开始执行10000次。。。。。

02:46:51.890 [thread3] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - thread3第1次获取锁执行中。。。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                   VALUE    thread2与thread3竞争，变为轻量级锁
      0     4        (object header)               d0 ed 0c 20 (11010000 11101101 00001100 00100000) (537718224)
      4     4        (object header)               00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)               e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

02:46:51.990 [thread2] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - thread2第1次获取锁执行中。。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                   VALUE
      0     4        (object header)               20 f3 fc 1f (00100000 11110011 11111100 00011111) (536671008)
      4     4        (object header)               00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)               e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total



02:47:01.334 [thread3] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - thread3第5001次获取锁执行中。。。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                     VALUE
      0     4        (object header)                 d0 ed 0c 20 (11010010 11101101 00001100 00100000) (537718224)
      4     4        (object header)                 00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                 e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

02:47:01.722 [thread2] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - thread2第5001次获取锁执行中。。。。
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                     VALUE    竞争5000次，由于竞争激烈变为重量级锁
      0     4        (object header)                 9a 11 fc 1c (10011010 00010001 11111100 00011100) (486281626)
      4     4        (object header)                 00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                 e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

02:47:01.790 [main] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo -  全部执行完成后-----------------
02:47:01.790 [main] DEBUG com.tuling.jucdemo.sync.LockEscalationDemo - java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                    VALUE    全部执行完成后，释放锁，变为无锁状态
      0     4        (object header)                9a 11 fc 1c (10011001 00010001 11111100 00011100) (486281626)
      4     4        (object header)                00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

Process finished with exit code 0
```

### Ⅲ、锁对象转化

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E9%94%81%E5%AF%B9%E8%B1%A1%E7%8A%B6%E6%80%81%E8%BD%AC%E5%8C%96%E5%9B%BE.png?raw=true)

# 三、Synchronized进阶

（Synchronized锁优化）

## 3.1、偏向锁批量重偏向&批量撤销 

### Ⅰ.批量重偏向与批量撤销作用

从偏向锁的加锁解锁过程中可看出，当只有一个线程反复进入同步块时，偏向锁带来的性能开销基本可以忽略，但是当有其他线程尝试获得锁时，就需要等到safe point时，再将偏向锁撤销为无锁状态或升级为轻量级，会消耗一定的性能。

<font color='red'>所以在多线程竞争频繁的情况下，偏向锁不仅不能提高性能，还会导致性能下降。</font>于是就有了批量重偏向与批量撤销的机制。 

### Ⅱ .批量重偏向与批量撤销原理

**（epoch到达20触发批量重偏向，epoch达到40触发批量撤销）**

以class为单位，为每个class维护一个偏向锁撤销计数器，每一次该class的对象发生偏向撤销操作时，该计数器+1，当这个值达到重偏向阈值（默认20）时，JVM就认为该class的偏向锁有问题，因此会进行批量重偏向。

每个class对象会有一个对应的epoch字段，每个处于偏向锁状态对象的Mark Word中也有该字段，其初始值为创建该对象时class中的epoch的值。每次发生批量重偏向时，就将该值+1，同时遍历JVM中所有线程的栈，找到该class所有正处于加锁状态的偏向锁，将其epoch字段改为新值。下次获得锁时，发现当前对象的epoch值和class的epoch不相等，那就算当前已经偏向了其他线程，也不会执行撤销操作，而是直接通过CAS操作将其Mark Word的Thread Id 改成当前线程Id。

当达到重偏向阈值（默认20）后，假设该class计数器继续增长，当其达到批量撤销的阈值后（默认40），JVM就认为该class的使用场景存在多线程竞争，会标记该class为不可偏向，之后对于该class的锁，直接走轻量级锁的逻辑。

**测试：批量重偏向** 

```java
public class BiasedLockingTest {
    public static void main(String[] args) throws  InterruptedException {
        //延时产生可偏向对象
        Thread.sleep(5000);
        // 创建一个list，来存放锁对象
        List<Object> list = new ArrayList<>();
        // 线程1
        new Thread(() -> {
            for (int i = 0; i < 50; i++) {
                // 新建锁对象
                Object lock = new Object();
                synchronized (lock) {
                    list.add(lock);
                }
            }
            try {
                //为了防止JVM线程复用，在创建完对象后，保持线程thead1状态为存活
                Thread.sleep(100000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }, "thead1").start();
        //睡眠3s钟保证线程thead1创建对象完成
        Thread.sleep(3000);
        log.debug("打印thead1，list中第20个对象的对象头：");
        log.debug((ClassLayout.parseInstance(list.get(19)).toPrintable()));
        
        // 线程2
        new Thread(() -> {
            for (int i = 0; i < 40; i++) {
                Object obj = list.get(i);
                synchronized (obj) {
                    if(i>=15&&i<=21||i>=38){
                        log.debug("thread2-第" + (i + 1) + "次加锁执行中\t"+
                                ClassLayout.parseInstance(obj).toPrintable());
                    }
                }
                if(i==17||i==19){
                    log.debug("thread2-第" + (i + 1) + "次释放锁\t"+
                            ClassLayout.parseInstance(obj).toPrintable());
                }
            }
            try {
                Thread.sleep(100000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }, "thead2").start();
        Thread.sleep(3000);
        new Thread(() -> {
            for (int i = 0; i < 50; i++) {
                Object lock =list.get(i);
                if(i>=17&&i<=21||i>=35&&i<=41){
                    log.debug("thread3-第" + (i + 1) + "次准备加锁\t"+
                            ClassLayout.parseInstance(lock).toPrintable());
                }
                synchronized (lock){
                    if(i>=17&&i<=21||i>=35&&i<=41){
                        log.debug("thread3-第" + (i + 1) + "次加锁执行中\t"+
                                ClassLayout.parseInstance(lock).toPrintable());
                    }
                }
            }
        },"thread3").start();
        Thread.sleep(3000);
        log.debug("查看新创建的对象");
        log.debug((ClassLayout.parseInstance(new Object()).toPrintable()));
        LockSupport.park();
    }
}
```

当撤销偏向锁阈值超过 20 次后，jvm 会这样觉得，我是不是偏向错了，于是会在给这些对象 加锁时重新偏向至加锁线程，<font color='red'>重偏向会重置对象的 Thread ID 。</font>

测试结果：

thread1: 

创建50个偏向线程thread1的偏向锁 1-50 偏向锁

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchroinzed-%E6%89%B9%E9%87%8F%E5%86%B2%E5%81%8F%E5%90%9101.png?raw=true)

thread2： 

1-18 偏向锁撤销，升级为轻量级锁 （thread1释放锁之后为偏向锁状态） 

19-40 偏向锁撤销达到阈值（20），执行了批量重偏向 （测试结果在第19就开始批量重偏向了）

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchroinzed-%E6%89%B9%E9%87%8F%E5%86%B2%E5%81%8F%E5%90%9102.png?raw=true)

**测试：批量撤销**

当撤销偏向锁阈值超过 40 次后，jvm 会认为不该偏向，于是整个类的所有对象都会变为不可偏向的，新建的对象也是不可偏向的。 

注意：<font color='red'>时间-XX:BiasedLockingDecayTime=25000ms范围内没有达到40次，撤销次数清为0， 重新计时。</font>

测试结果：

thread3:

1-18 从无锁状态直接获取轻量级锁 （thread2释放锁之后变为无锁状态）

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchroinzed-%E6%89%B9%E9%87%8F%E6%92%A4%E9%94%8001.png?raw=true)

19-40 偏向锁撤销，升级为轻量级锁 （thread2释放锁之后为偏向锁状态）

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchroinzed-%E6%89%B9%E9%87%8F%E6%92%A4%E9%94%8002.png?raw=true)

41-50 达到偏向锁撤销的阈值40，批量撤销偏向锁，升级为轻量级锁 （thread1释放锁之后为偏向锁状态） 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchroinzed-%E6%89%B9%E9%87%8F%E6%92%A4%E9%94%8003.png?raw=true)

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchroinzed-%E6%89%B9%E9%87%8F%E6%92%A4%E9%94%8004.png?raw=true)

## 3.2、自旋优化

- <font color='red'>重量级锁竞争的时候，还可以使用自旋来进行优化</font>，如果当前线程自旋成功（即这时候持锁线程已经退出了同步块，释放了锁），这时当前线程就可以避免阻塞。自旋会占用 CPU 时间，单核 CPU 自旋就是浪费，多核 CPU 自旋才能发挥优势。

- 在 Java 6 之后自旋是自适应的，比如对象刚刚的一次自旋操作成功过，那么认为这次自旋成功的可能性会高，就多自旋几次；反之，就少自旋甚至不自旋，比较智能。 

- Java 7 之后不能控制是否开启自旋功能。

## 3.3、锁粗化

假设一系列的连续操作都会<font color='red'>对同一个对象反复加锁及解锁，甚至加锁操作是出现在循环体中</font>，即使没有出现线程竞争，频繁地进行互斥同步操作也会导致不必要的性能损耗。如果JVM检测到有一连串零碎的操作都是对同一对象的加锁，将会扩大加锁同步的范围（即锁粗化）到整个操作序列的外部。

```java
StringBuffer buffer = new StringBuffer(); 
/** 
* 锁粗化 
*/ 
public void append(){ 
    buffer.append("aaa").append(" bbb").append(" ccc"); 
} 
```

上述代码每次调用 buffer.append方法都需要加锁和解锁，如果JVM检测到有一连串的对同一个对象加锁和解锁的操作，就会将其合并成一次范围更大的加锁和解锁操作，即在<font color='red'>第一次append方法时进行加锁，最后一次append方法结束后进行解锁。 </font>

注意：<font color='red'>自旋的目的是为了减少线程挂起的次数，尽量避免直接挂起线程（挂起操作涉及系统调用，存在用户态和内核态切换，这才是重量级锁最大的开销） </font>

## 3.4、锁消除

消除锁是虚拟机另外一种锁的优化，这种优化更彻底，Java虚拟机在JIT编译时(可以简单理解为当某段代码即将第一次被执行时 进行编译，又称即时编译)，通过对运行上下文的扫描，去除不可能存在共享资源竞争的锁，通过这种方式消除没有必要的锁，可以 节省毫无意义的请求锁时间，如下StringBuffer的append是一个同步方法，但是在add方法中的StringBuffer属于一个局部变量，并且不会被其他线程所使用，<font color='red'>因此StringBuffer不可能存在共享资源竞争的情景，JVM会自动将其锁消除。锁消除的依据是逃逸分析的数据支持。 </font>

锁消除，前提是java必须运行在server模式（server模式会比client模式作更多的优化），同时必须开启逃逸分析：

:-XX:+DoEscapeAnalysis 开启逃逸分析 

-XX:+EliminateLocks 表示开启锁消除。 

```java
public class LockEliminationTest {
    StringBuffer buffer = new StringBuffer();
    /**
     * 锁粗化
     */
    public void append(){
        buffer.append("aaa").append(" bbb").append(" ccc");
    }
    /**
     * 锁消除
     * -XX:+EliminateLocks 开启锁消除(jdk8默认开启）
     * -XX:-EliminateLocks 关闭锁消除
     * @param str1
     * @param str2
     */
    public void append(String str1, String str2) {
        StringBuffer stringBuffer = new StringBuffer();
        stringBuffer.append(str1).append(str2);
    }
    public static void main(String[] args) throws InterruptedException {
        LockEliminationTest demo = new LockEliminationTest();
        long start = System.currentTimeMillis();
        for (int i = 0; i < 100000000; i++) {
            demo.append("aaa", "bbb");
        }
        long end = System.currentTimeMillis();
        System.out.println("执行时间：" + (end - start) + " ms");
    }
}
测试结果： 关闭锁消除执行时间4688 ms 开启锁消除执行时间：2601 ms
```

分析：StringBuffer的append是个同步方法，但是append方法中的 StringBuffer 属于一个局部变量，不可能从该方法中逃逸出去，因此其实这过程是线程安全的，可以将锁消除。

## 3.5、逃逸分析

逃逸分析，是一种可以有效减少Java 程序中同步负载和内存堆分配压力的跨函数全局数据流分析算法。通过逃逸分析，Java Hotspot编译器能够分析出一个新的对象的引用的使用范围从而决定是否要将这个对象分配到堆上。逃逸分析的基本行为就是分析对象动态作用域。 

**方法逃逸(对象逃出当前方法)** 

当一个对象在方法中被定义后，它可能被外部方法所引用，例如作为调用参数传递到其他地方中。 

**线程逃逸((对象逃出当前线程)** 

这个对象甚至可能被其它线程访问到，例如赋值给类变量或可以在其它线程中访问的实例变量。

**使用逃逸分析，编译器可以对代码做如下优化：** 

1. 同步省略或锁消除(Synchronization Elimination)。如果一个对象被发现只能从一个线程被访问 到，那么对于这个对象的操作可以不考虑同步。 
2. 将堆分配转化为栈分配(Stack Allocation)。如果一个对象在子程序中被分配，要使指向该对象 的指针永远不会逃逸，对象可能是栈分配的候选，而不是堆分配。 
3. 分离对象或标量替换(Scalar Replacement)。有的对象可能不需要作为一个连续的内存结构存在也可以被访问到，那么对象的部分（或全部）可以不存储在内存，而是存储在CPU寄存器中。 

jdk6才开始引入该技术，jdk7开始默认开启逃逸分析。在Java代码运行时，可以通过JVM参数指定是否开启逃逸分析：

```java
‐XX:+DoEscapeAnalysis //表示开启逃逸分析 (jdk1.8默认开启） 
‐XX:‐DoEscapeAnalysis //表示关闭逃逸分析。 
‐XX:+EliminateAllocations //开启标量替换(默认打开) 
‐XX:+EliminateLocks //开启锁消除(jdk1.8默认开启）
```

测试：

```java
/**
 * 进行两种测试
 * 关闭逃逸分析，同时调大堆空间，避免堆内GC的发生，如果有GC信息将会被打印出来
 * VM运行参数：-Xmx4G -Xms4G -XX:-DoEscapeAnalysis -XX:+PrintGCDetails -XX:+HeapDumpOnOutOfMemoryError
 *
 * 开启逃逸分析  jdk8默认开启
 * VM运行参数：-Xmx4G -Xms4G -XX:+DoEscapeAnalysis -XX:+PrintGCDetails -XX:+HeapDumpOnOutOfMemoryError
 *
 * 执行main方法后
 * jps 查看进程
 * jmap -histo 进程ID
 */
@Slf4j
public class EscapeTest {
    public static void main(String[] args) {
        long start = System.currentTimeMillis();
        for (int i = 0; i < 500000; i++) {
            alloc();
        }
        long end = System.currentTimeMillis();
        log.info("执行时间：" + (end - start) + " ms");
        try {
            Thread.sleep(Integer.MAX_VALUE);
        } catch (InterruptedException e1) {
            e1.printStackTrace();
        }
    }
    /**
     * JIT编译时会对代码进行逃逸分析
     * 并不是所有对象存放在堆区，有的一部分存在线程栈空间
     * Ponit没有逃逸
     */
    private static String alloc() {
        Point point = new Point();
        return point.toString();
    }
    /**
     *同步省略（锁消除）  JIT编译阶段优化，JIT经过逃逸分析之后发现无线程安全问题，就会做锁消除
     */
    public void append(String str1, String str2) {
        StringBuffer stringBuffer = new StringBuffer();
        stringBuffer.append(str1).append(str2);
    }
    /**
     * 标量替换
     *
     */
    private static void test2() {
        Point point = new Point(1,2);
        System.out.println("point.x="+point.getX()+"; point.y="+point.getY());
//        int x=1;
//        int y=2;
//        System.out.println("point.x="+x+"; point.y="+y);
    }
}
@Data
@AllArgsConstructor
@NoArgsConstructor
class Point{
    private int x;
    private int y;
}
```

测试结果：

开启逃逸分析，部分对象会在栈上分配

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E9%80%83%E9%80%B8%E5%88%86%E6%9E%90%E6%B5%8B%E8%AF%95%E7%BB%93%E6%9E%9C%E5%BC%80%E5%90%AF.png?raw=true)

未开启：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Synchronized-%E9%80%83%E9%80%B8%E5%88%86%E6%9E%90%E6%B5%8B%E8%AF%95%E7%BB%93%E6%9E%9C%E6%9C%AA%E5%BC%80%E5%90%AF.png?raw=true)