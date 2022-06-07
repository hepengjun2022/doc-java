# 一、并发与并行

并发与并行的目标都是最大化CPU的使用率。

**并行（parallel）：**指在同一时刻，有多条指令在多个处理器上同时执行。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E5%B9%B6%E8%A1%8C%E5%9B%BE.png?raw=true)

**并发（concurrency）：**指在同一时刻只能有一条命令执行，但是是多个进行指令被快速轮换执行，达到了多个进程同时执行的效果，但在微观上并不是同时执行的，只是为每个进行分配时间片，使得多个进程快速交替执行。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E5%B9%B6%E5%8F%91%E5%9B%BE.png?raw=true)

+ 并行在多处理器系统中存在，而并发可以在单处理器和多处理器系统同时存在。

+ 并发能够在单处理器系统中存在是因为并发的假象。
+ 并行要求程序能够同时执行多个操作，而并发只是要求程序假装同时执行多个操作（操作系统给每个操作分配时间片，让多个操作快速切换执行）。

---



# 二、并发三大特性

并发编程bug的源头：可见性、原子性和有序性问题。

## 1、可见性

当一个线程修改了共享变量的值，其他线程能够看到修改的值。

Java内存模型是通过在变量修改后将新值同步回主内存，在变量读取前从主内存刷新变量值，这种依赖**内存作为传递媒介**的方法来实现可见性。

保证可见性：

+ 通过volatile关键字保证可见性。
+ 通过内存屏障保证可见性。
+ 通过synchronized关键字保证可见性。
+ 通过Lock保证可见性。
+ 通过final关键字保证可见性。

## 2、有序性

即程序执行的顺序按照代码的先后顺序执行。但是JVM存在指令重排，所以存在有序性的问题。

保证有序性：

+ 通过synchronized关键字保证有序性。
+ 通过Lock保证有序性。

## 3、原子性

一个或多个操作，要么全部执行企切在执行过程中不被任何因素打断，要么全部不执行。在Java种，对基本数据类型的变量读取和赋值操作是原子性操作（64位处理器）。

不采取任何的原子性保障措施的自增操作并不是原子性的。

保证原子性：

+ 通过synchronized关键字保证原子性。
+ 通过Lock保证原子性。
+ 通过CAS保证原子性。



---

# 三、可见性问题深入分析

我们通过下面的Java小程序来分析Java的多线程可见性的问题

```java
public  class VisibilityTest {
    //  storeLoad  JVM内存屏障  ---->  (汇编层面指令)  lock; addl $0,0(%%rsp)
    // lock前缀指令不是内存屏障的指令，但是有内存屏障的效果   缓存失效
    private volatile boolean flag = true;
    private int count = 0;

    public void refresh() {
        // threadB对flag的写操作会 happens-before threadA对flag的读操作
        flag = false;
        System.out.println(Thread.currentThread().getName() + "修改flag:"+flag);
    }

    public void load() {
        System.out.println(Thread.currentThread().getName() + "开始执行.....");
        while (flag) {
            //TODO  业务逻辑
            count++;
            //JMM模型    内存模型： 线程间通信有关   共享内存模型
            //没有跳出循环   可见性的问题
            //能够跳出循环   内存屏障
            //UnsafeFactory.getUnsafe().storeFence();
            //能够跳出循环    ?   释放时间片，上下文切换   加载上下文：flag=true
            //Thread.yield();
            //能够跳出循环    内存屏障
            //System.out.println(count);
            //LockSupport.unpark(Thread.currentThread());
            //shortWait(1000000); //1ms
            //shortWait(1000);
//            long start = System.nanoTime();
//            long end = 0;
//            // do while   while?
//            while (start + 1000000 >= end) {
//                end = System.nanoTime();
//            }
//            try {
//                Thread.sleep(1);   //内存屏障
//            } catch (InterruptedException e) {
//                e.printStackTrace();
//            }
            //总结：  Java中可见性如何保证？ 方式归类有两种：
            //1. jvm层面 storeLoad内存屏障    ===>  x86   lock替代了mfence
            //2. 上下文切换   Thread.yield();

            // java
            // volatile  锁机制
            //当前线程对共享变量的操作会存在读不到，或者不能立即读到另一个线程对此变量的写操作

            // lock 硬件层面扩展      JMM为什么选择共享内存模型
        }
        System.out.println(Thread.currentThread().getName() + "跳出循环: count=" + count);
    }
    public static void main(String[] args) throws InterruptedException {
        VisibilityTest test = new VisibilityTest();
        // 线程threadA模拟数据加载场景
        Thread threadA = new Thread(() -> test.load(), "threadA");
        threadA.start();
        // 让threadA执行一会儿
        Thread.sleep(1000);
        // 线程threadB通过flag控制threadA的执行时间
        Thread threadB = new Thread(() -> test.refresh(), "threadB");
        threadB.start();

    }
    public static void shortWait(long interval) {
        long start = System.nanoTime();
        long end;
        do {
            end = System.nanoTime();
        } while (start + interval >= end);
    }
}
```



# 四、Java内存模型（JMM）

JAVA多线程通信模型——共享内存模型

## 1、JMM定义

java虚拟机规范中定义了java内存模型（Java Memory Model，JVM），用于屏蔽掉各种硬件和操作系统的内存访问差异，以实现让Java程序在各个平台下都能达到一致的并发效果。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E5%86%85%E5%AD%98%E6%A8%A1%E5%9E%8B.png?raw=true)

JMM规范了Java虚拟机与计算机内存是如何协同工作的：

+ 规定了一个线程何时可以看到由其他线程修改后的共享变量的值，以及在必要时如何同步的访问共享变量。

+ JMM描述的是一种抽象的概念，一组规则，通过这组规则控制程序中的各个变量在共享数据区域和私有数据区域的访问方式。
+ JMM是围绕原子性、有序性、可见性展开的。

## 2、JMM与硬件内存架构的关系

Java内存模型与硬件内存架构之间存在差异，由于硬件的内存架构中没有区分线程栈和堆，所以对于硬件，所有线程栈和堆都分布在主内存中。部分线程栈和堆可能也会出现在CPU缓存和CPU寄存器中。

如下图所示，Java内存模型和计算机硬件内存架构是一个交叉关系：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E5%86%85%E5%AD%98%E6%A8%A1%E5%9E%8B%E4%B8%8E%E7%A1%AC%E4%BB%B6%E6%9E%B6%E6%9E%84%E5%85%B3%E7%B3%BB.png?raw=true)

**内存交互操作：**

主内存与工作内存之间的具体交互协议，即一个变量是如何从主内存拷贝到工作内存、从工作内存同步到主内存之间的实现细节。

Java内存模型定义了以下八种操作来完成：

从主内存 —> 执行引擎

+ lock(锁定)：作用于主内存的变量，把一个变量标识为一条线程独占状态。
+ read(读取)：作用于主内存变量，把一个变量值从主内存传输到线程的工作内存中。
+ load(载入)：作用于工作内存的变量，把read操作获得的变量值放入到变量副本中。
+ use(使用)：作用于工作内存的变量，把工作内存中一个变量值传递给执行引擎，每当虚拟机遇到一个需要使用变量的值的字节码指令时将会执行这个操作。

从执行引擎  ---> 主内存

+ assign(赋值)：作用于工作内存的变量，把一个从执行引擎收到的值赋值给工作内存的变量，每当虚拟机遇到一个给变量赋值的字节码指令时执行这个操作。
+ store(存储)：作用于工作内存的变量，把工作内存中的一个变量值传递到主内存，以便后续的write操作。
+ write(写入)：作用于主内存的变量，把store操作传递过来的值存入主内存的变量中。
+ unlock(解锁)：作用于主内存，把一个处于锁定状态的变量释放，释放后才能被其他线程锁定。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E5%86%85%E5%AD%98%E4%BA%A4%E4%BA%92%E6%93%8D%E4%BD%9C.png?raw=true)

**Java内存模型还规定了在执行上述八种基本操作时，必须满足如下规则：**

- 如果要把一个变量从主内存中复制到工作内存，就需要按顺寻地执行read和load操作， 如果把变量从工作内存中同步回主内存中，就要按顺序地执行store和write操作。但**Java内存模型只要求上述操作必须按顺序执行，而没有保证必须是连续执行。**
- 不允许read和load、store和write操作之一单独出现。
- 不允许一个线程丢弃它的最近assign的操作，即变量在工作内存中改变了之后必须同步到主内存中。
- 不允许一个线程无原因地（没有发生过任何assign操作）把数据从工作内存同步回主内存中。
- 一个新的变量只能在主内存中诞生，不允许在工作内存中直接使用一个未被初始化（load或assign）的变量。即就是对一个变量实施use和store操作之前，必须先执行过了assign和load操作。
- 一个变量在同一时刻只允许一条线程对其进行lock操作，但lock操作可以被同一条线程重复执行多次，多次执行lock后，只有执行相同次数的unlock操作，变量才会被解锁。lock和unlock必须成对出现
- 如果对一个变量执行lock操作，将会清空工作内存中此变量的值，在执行引擎使用这个变量前需要重新执行load或assign操作初始化变量的值。
- 如果一个变量事先没有被lock操作锁定，则不允许对它执行unlock操作；也不允许去unlock一个被其他线程锁定的变量。
- 对一个变量执行unlock操作之前，必须先把此变量同步到主内存中（执行store和write操作）。

## 3、JMM内存可见性保证

**按程序类型，Java程序的内存可见性保证分为三类：**

+ 单线程程序：单线程程序不会出现内存可见性问题，编译器、runtime和处理器会共同确保单线程程序的执行结果与该程序在顺序一致性模型中的执行结果相同。
+ 正确同步的多线程程序：正确同步的多线程程序的执行将具有顺序一致性（程序的执行结果与该程序在顺序一致性内存模型中的执行结果相同）。这是JMM关注的重点，**JMM通过限制编译器和处理器的重排序来为程序员提供内存可见性保证。**
+ 未同步/未正确同步的多线程程序：JMM为它们提供了最小安全性保障：线程执行时读取到的值，要么是之前某个线程写入的值，要么是默认值。未同步程序在JMM中执行时，整体上是无序的，其执行结果无法预知。 **JMM不保证未同步程序的执行结果与该程序在顺序一致性模型中的执行结果一致。**

未同步程序在JMM中执行时，整体上是无序的，其执行结果无法预知，在顺序一致性模型与JMM模型中执行特性有如下差异：

1. 顺序一致性模型保证**单线程**内的操作会按程序的顺序执行，而JMM不保证单线程内的操作会按程序的顺序执行，比如正确同步的多线程程序在临界区内的重排序。
2. 顺序一致性模型保证**所有线程**只能看到一致的操作执行顺序，而JMM不保证所有线程能看到一致的操作执行顺序。
3. 顺序一致性模型保证对所有的内存读/写操作都具有原子性，而JMM不保证对64位的long型和double型变量的写操作具有原子性（32位处理器）。

注：JVM在32位处理器上运行时，可能会把一个64位long/double型变量的写操作拆分为两个32位的写操作来执行。这两个32位的写操作可能会被分配到不同的总线事务中执行，此时对这个64位变量的写操作将不具有原子性。从JSR-133内存模型开始（即从JDK5开始），仅仅只允许把一个64位long/double型变量的写操作拆分为两个32位的写操作来执行，任意的读操作在JSR-133中都必须具有原子性。

## 4、volatile关键字

### 1. volatile特性

+ 可见性：对一个volatile变量的读，总是能看到（任意线程）对这个volatile变量最后的写入。

+ 原子性：对任意单个volatile变量的读/写具有原子性，但类似于volatile++这种复合操作不具有原子性（基于这点，我们通过会认为volatile不具备原子性）。<font color='red'>volatile仅仅保证对单个volatile变量的读/写具有原子性，而锁的互斥执行的特性可以确保对整个临界区代码的执行具有原子性</font>。

  注意：64位的long型和double型变量，只要它是volatile变量，对该变量的读/写就具有原子性。

+ 有序性：<font color='red'> 对volatile修饰的变量的读写操作前后加上各种特定的内存屏障来禁止指令重排序来保障有序性。 </font>

  **注意：**在JSR-133之前的旧Java内存模型中，虽然不允许volatile变量之间重排序，但旧的Java内存模型允许volatile变量与普通变量重排序。为了提供一种比锁更轻量级的线程之间通信的机制，<font color='red'>JSR-133专家组决定增强volatile的内存语义：严格限制编译器和处理器对volatile变量与普通变量的重排序，确保volatile的写-读和锁的释放-获取具有相同的内存语义</font>。

### 2. volatile写-读的内存语义

- 当写一个volatile变量时，JMM会把该线程对应的本地内存中的共享变量值刷新到主内存。

- 当读一个volatile变量时，JMM会把该线程对应的本地内存置为无效，线程接下来将从主内存中读取共享变量。

### 3. volatile可见性实现原理

+ **JMM内存交互层面实现：**

  volatile修饰的变量的read、load、use操作和assign、store、write必须是连续的，即修改后必须立即同步回主内存，使用时必须从主内存刷新，由此保证volatile变量操作对多线程的可见性。

+ **硬件层面实现：**

  通过lock前缀指令，会锁定变量缓存行区域并写回主内存，这个操作称为“缓存锁定”，缓存一致性机制会阻止同时修改被两个以上处理器缓存的内存区域数据。<font color='red'>一个处理器的缓存回写到内存会导致其他处理器的缓存无效。</font>

### 4. volatile在Hotspot的实现

+ **字节码解释器实现：**       

  JVM中的字节码解释器(bytecodeInterpreter)，用C++实现了JVM指令，其优点是实现相对简单且容易理解，缺点是执行慢。

  bytecodeInterpreter.cpp

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E5%9C%A8hotspot%E7%9A%84%E5%AE%9E%E7%8E%B0.png?raw=true)

+ **JIT模板解释器实现：**

  模板解释器(templateInterpreter)，其对每个指令都写了一段对应的汇编代码，启动时将每个指令与对应汇编代码入口绑定，可以说是效率做到了极致。 

  templateTable_x86_64.cpp

```c++
void TemplateTable::volatile_barrier(Assembler::Membar_mask_bits
                                     order_constraint) {
  // Helper function to insert a is-volatile test and memory barrier
  if (os::is_MP()) { // Not needed on single CPU
    __ membar(order_constraint);
  }
}

// 负责执行putfield或putstatic指令
void TemplateTable::putfield_or_static(int byte_no, bool is_static, RewriteControl rc) {
	// ...
	 // Check for volatile store
    __ testl(rdx, rdx);
    __ jcc(Assembler::zero, notVolatile);

    putfield_or_static_helper(byte_no, is_static, rc, obj, off, flags);
    volatile_barrier(Assembler::Membar_mask_bits(Assembler::StoreLoad |
                                                 Assembler::StoreStore));
    __ jmp(Done);
    __ bind(notVolatile);

    putfield_or_static_helper(byte_no, is_static, rc, obj, off, flags);

    __ bind(Done);
}
```

assembler_x86.hpp

```c++
// Serializes memory and blows flags
  void membar(Membar_mask_bits order_constraint) {
    // We only have to handle StoreLoad
    // x86平台只需要处理StoreLoad
    if (order_constraint & StoreLoad) {

      int offset = -VM_Version::L1_line_size();
      if (offset < -128) {
        offset = -128;
      }
      // 下面这两句插入了一条lock前缀指令: lock addl $0, $0(%rsp) 
      lock(); // lock前缀指令
      addl(Address(rsp, offset), 0); // addl $0, $0(%rsp) 
    }
  }
```

+ **linux系统x86中的实现：**

orderAccess_linux_x86.inline.hpp

```c++
inline void OrderAccess::storeload()  { fence(); }
inline void OrderAccess::fence() {
if (os::is_MP()) {
    // always use locked addl since mfence is sometimes expensive
#ifdef AMD64
    __asm__ volatile ("lock; addl $0,0(%%rsp)" : : : "cc", "memory");
#else
    __asm__ volatile ("lock; addl $0,0(%%esp)" : : : "cc", "memory");
#endif
  }
}
```

x86处理器中利用lock实现类似内存屏障的效果。

### 5. lock前缀指令的作用

1. 确保后续指令执行的原子性。在Pentium及之前的处理器中，带有lock前缀的指令在执行期间会锁住总线，使得其它处理器暂时无法通过总线访问内存，很显然，这个开销很大。在新的处理器中，Intel使用缓存锁定来保证指令执行的原子性，缓存锁定将大大降低lock前缀指令的执行开销。
2. LOCK前缀指令具有类似于内存屏障的功能，禁止该指令与前面和后面的读写指令重排序。
3. LOCK前缀指令会<font color='red'>等待它之前所有的指令完成、并且所有缓冲的写操作写回内存</font>(也就是将store buffer中的内容写入内存)之后才开始执行，并且根据缓存一致性协议，刷新store buffer的操作会导致其他cache中的副本失效。

### 6. 汇编层面volatile实现

添加下面的jvm参数查看之前可见性Demo的汇编指令

```
-XX:+UnlockDiagnosticVMOptions -XX:+PrintAssembly -Xcomp
```

验证了可见性使用了**lock前缀指令**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E6%B1%87%E7%BC%96%E5%B1%82%E9%9D%A2volatile%E5%AE%9E%E7%8E%B0.png?raw=true)

### 7. 从硬件层面分析Lock前缀指令

32位的IA-32处理器支持对系统内存中的位置进行锁定的原子操作。这些操作通常用于管理共享的数据结构(如信号量、段描述符、系统段或页表)，在这些结构中，两个或多个处理器可能同时试图修改相同的字段或标志。处理器使用三种相互依赖的机制来执行锁定的原子操作:

- 有保证的原子操作。
- 总线锁定，使用LOCK#信号和LOCK指令前缀。
- 缓存一致性协议，确保原子操作可以在缓存的数据结构上执行(缓存锁);这种机制出现在Pentium 4、Intel Xeon和P6系列处理器中。

### 8. CPU高速缓存架构分析

#### Ⅰ. CPU高速缓存

CPU缓存即高速缓冲存储器，是位于CPU与主内存间的一种容量较小但速度很高的存储器。由于CPU的速度远高于主内存，CPU直接从内存中存取数据要等待一定时间周期，Cache中保存着CPU刚用过或循环使用的一部分数据，当CPU再次使用该部分数据时可从Cache中直接调用,减少CPU的等待时间，提高了系统的效率。 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E7%9A%84CPU%E7%BC%93%E5%AD%98%E6%80%A7%E8%83%BD%E5%AF%B9%E6%AF%94.png?raw=true)

##### ①. CPU局部性原理

<font color='red'>在CPU访问存储设备时，无论是存取数据抑或存取指令，都趋于聚集在一片连续的区域中，这就是局部性原理。</font>

**时间局部性（Temporal Locality）**：如果一个信息项正在被访问，那么在近期它很可能还会被再次访问。 比如循环、递归、方法的反复调用等。 

**空间局部性（Spatial Locality）**：如果一个存储器的位置被引用，那么将来他附近的位置也会被引用。 比如顺序执行的代码、连续创建的两个对象、数组等。 

##### ②. 多CPU多核缓存架构

+ **物理CPU：**物理CPU就是插在主机上的真实的CPU硬件，在Linux下可以数不同的physical id 来确认主机的物理CPU个数。 

+ **核心数**：我们常常会听说多核处理器，其中的核指的就是核心数。在Linux下可以通过cores来确认主机的物理CPU的核心数。 

+ **逻辑CPU**：逻辑CPU跟超线程技术有联系，假如物理CPU不支持超线程的，那么逻辑CPU的数量等于核 心数的数量；如果物理CPU支持超线程，那么逻辑CPU的数目是核心数数目的两倍。在Linux下可以通过 processors 的数目来确认逻辑CPU的数量。

现代CPU为了提升执行效率，减少CPU与内存的交互，一般在CPU上集成了多级缓存架构，常见的为三级缓存结构。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM-%E4%B8%89%E7%BA%A7%E7%BC%93%E5%AD%98%E7%BB%93%E6%9E%84.png?raw=true)

#### Ⅱ. 缓存一致性

Cache coherence

计算机体系结构中，缓存一致性是共享资源数据的一致性，这些数据最终存储在多个本地缓存中。当系统中的客户机维护公共内存资源的缓存时，可能会出现数据不一致的问题，这在多处理系统中的cpu中尤其如此。 

在共享内存多处理器系统中，每个处理器都有一个单独的缓存内存，共享数据可能有多个副本:一个副本在主内存中，一个副本在请求它的每个处理器的本地缓存中。当数据的一个副本发生更改时，其他副本必须反映该更改。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM-%E7%BC%93%E5%AD%98%E4%B8%80%E8%87%B4%E6%80%A7%E5%8D%8F%E8%AE%AE%E5%8E%9F%E7%90%86%E5%9B%BE.png?raw=true)

缓存一致性是确保共享操作数(数据)值的变化能够及时地在整个系统中传播的规程。 

##### ①. 写传播

（Write Propagation）

对任何缓存中的数据的更改都必须传播到对等缓存中的其他副本(该缓存行的副本)。 

##### ②. 事务串行化

（Transaction Serialization）

对单个内存位置的读/写必须被所有处理器以相同的顺序看到。理论上，一致性可以在加载/ 

存储粒度上执行。然而，在实践中，它通常在缓存块的粒度上执行。 

##### ③. 一致性机制

（Coherence mechanisms）

+ 确保一致性的两种最常见的机制是窥探机制（snooping ）和基于目录的机制（directory- based），这两种机制各有优缺点。

+ 如果有足够的带宽可用，基于协议的窥探往往会更快，因为所有事务都是所有处理器看到的请求/响应。其缺点是窥探是不可扩展的。

+ 每个请求都必须广播到系统中的所有节点，这意味着随着系统变大，(逻辑或物理)总线的大小及其提供的带宽也必须增加。

+ 另一方面，目录往往有更长的延迟(3跳 请求/转发/响应)，但使用更少的带宽，因为消息是点对点的，而不是广播的。由于这个原因，许多较大的系统(>64处理器)使用这种类型的缓存一致性。 

#### Ⅲ. 总线仲裁机制

在计算机中，数据通过总线在处理器和内存之间传递。每次处理器和内存之间的数据传递都是通过一系列步骤来完成的，这一系列步骤称之为总线事务（Bus Transaction）。

+ 总线事务包括读事务（Read Transaction）和写事务（WriteTransaction）。

+ 读事务从内存传送数据到处理器，写事务从处理器传送数据到内存，每个事务会读/写内存中一个或多个物理上连续的字。这里的关键是，<font color='red'>总线会同步试图并发使用总线的事务。在一个处理器执行总线事务期间，总线会禁止其他的处理器和I/O设备执行内存的读/写。 </font>

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM-%E6%80%BB%E7%BA%BF%E7%AA%A5%E6%8E%A2%E6%9C%BA%E5%88%B6.png?raw=true)

  假设处理器A，B和C同时向总线发起总线事务，这时总线仲裁（Bus Arbitration）会对竞争做出裁决，这里假设总线在仲裁后判定处理器A在竞争中获胜（总线仲裁会确保所有处理器都能公平的访问内存）。此时处理器A继续它的总线事务，而其他两个处理器则要等待处理器A的总线事务完成后才能再次执行内存访问。假设在处理器A执行总线事务期间（不管这个总线事务是读事务还是写事务），处理器D向总线发起了总线事务，此时处理器D的请求会被总线禁止。 

<font color='red'>总线的这种工作机制可以把所有处理器对内存的访问以串行化的方式来执行。在任意时间点，最多只能有一个处理器可以访问内存。这个特性确保了单个总线事务之中的内存读/写操作具有原子性。 </font>

原子操作是指不可被中断的一个或者一组操作。处理器会自动保证基本的内存操作的原子性，也就是一个处理器从内存中读取或者写入一个字节时，其他处理器是不能访问这个字节的内存地址。最新的处理器能自动保证单处理器对同一个缓存行里进行16/32/64位的操作是原子的，但是复杂的内存操作处理器是不能自动保证其原子性的，比如跨总线宽度、跨多个缓存行和跨页表的访问。处理器提供总线锁定和缓存锁定两个机制来保证复杂内存操作的原子性。 

##### ①. 总线锁定

总线锁定就是使用处理器提供的一个 LOCK＃信号，当其中一个处理器在总线上输出此信号时，其它处理器的请求将被阻塞住，那么该处理器可以独占共享内存。 

由于总线锁定阻止了被阻塞处理器和所有内存之间的通信，而输出LOCK#信号的CPU可能只需要锁住特定的一块内存区域，因此总线锁定开销较大。

##### ②. 缓存锁定

缓存锁定是指内存区域如果被缓存在处理器的缓存行中，并且在Lock操作期间被锁定，那 么当它执行锁操作回写到内存时，处理器不会在总线上声言LOCK＃信号（总线锁定信号），而是修改内部的内存地址，并允许它的缓存一致性机制来保证操作的原子性，因为**缓存一致性机制会阻止同时修改由两个以上处理器缓存的内存区域数据**，当其他处理器回写已被锁定的缓存行的数据时，会使缓存行无效。

**缓存锁定不能使用的特殊情况：** 

+ 当操作的数据不能被缓存在处理器内部，或操作的数据跨多个缓存行时，则处理器会调用总线锁定。 

+ 有些处理器不支持缓存锁定。

32位的IA-32处理器支持对系统内存中的位置进行锁定的原子操作。这些操作通常用于管理共享的数据结构(如信号量、段描述符、系统段或页表)，在这些结构中，两个或多个处理器可能同时试图修改相同的字段或标志。处理器使用三种相互依赖的机制来执行锁定的原子操作：

+ 有保证的原子操作。
+ 总线锁定，使用LOCK#信号和LOCK指令前缀。
+ 缓存一致性协议，确保原子操作可以在缓存的数据结构上执行(缓存锁);这种机制出现在Pentium 4、Intel Xeon和P6系列处理器中 。

#### Ⅳ. 总线窥探

（Bus Snooping）

总线窥探(Bus snooping)是缓存中的一致性控制器(snoopy cache)监视或窥探总线事务的一种方案，其目标是在分布式共享内存系统中维护缓存一致性。包含一致性控制器(snooper)的缓存称为snoopy缓存。该方案由Ravishankar和Goodman于1983年提出。 

##### ①. 工作原理

<font color='red'>当特定数据被多个缓存共享时，处理器修改了共享数据的值，更改必须传播到所有其他具有 该数据副本的缓存中。这种更改传播可以防止系统违反缓存一致性。</font>数据变更的通知可以通过总 线窥探来完成。所有的窥探者都在监视总线上的每一个事务。如果一个修改共享缓存块的事务出 现在总线上，所有的窥探者都会检查他们的缓存是否有共享块的相同副本。如果缓存中有共享块 的副本，则相应的窥探者执行一个动作以确保缓存一致性。<font color='red'>这个动作可以是刷新缓存块或使缓存 块失效。它还涉及到缓存块状态的改变，这取决于缓存一致性协议（cachecoherence protocol）。 </font>

##### ②. 窥探协议类型

根据管理写操作的本地副本的方式，有两种窥探协议: 

+ **Write-invalidate** 

当处理器写入一个共享缓存块时，其他缓存中的所有共享副本都会通过总线窥探失效。这种方法确保处理器只能读写一个数据的一个副本。其他缓存中的所有其他副本都无效。这是最常用的窥探协议。MSI、MESI、MOSI、MOESI和MESIF协议属于该类型。 

+ **Write-update** 

当处理器写入一个共享缓存块时，其他缓存的所有共享副本都会通过总线窥探更新。这个方法将写数据广播到总线上的所有缓存中。它比write-invalidate协议引起更大的总线流量。这就 是为什么这种方法不常见。Dragon和firefly协议属于此类别。 

#### Ⅴ. 一致性协议

（Coherence protocol）

一致性协议在多处理器系统中应用于高速缓存一致性。为了保持一致性，人们设计了各种模型和协议，如MSI、MESI(又名Illinois)、MOSI、MOESI、MERSI、MESIF、write-once、Synapse、Berkeley、Firefly和Dragon协议。 

- MSI protocol, the basic protocol from which the MESI protocol is derived. 
- Write-once (cache coherency), an early form of the MESI protocol. 
- MESI protocol 
- MOSI protocolMOESI protocol 
- MESIF protocol 
- MERSI protocol 
- Dragon protocol 
- Firefly protocol 

##### ①. MESI协议

**MESI协议**<font color='red'>是一个基于写失效的缓存一致性协议，是支持回写（write-back）缓存的最常用协议。</font>也称作**伊利诺伊协议** (Illinois protocol，因为是在伊利诺伊大学厄巴纳-香槟分校被发明 的)。与写通过（write through）缓存相比，回写缓冲能节约大量带宽。总是有“脏”（dirty）状态表示缓存中的数据与主存中不同。MESI协议要求在缓存不命中（miss）且数据块在另一个缓存时，允许缓存到缓存的数据复制。与MSI协议相比，MESI协议减少了主存的事务数量。这极大改善了性能。 

缓存行有4种不同的状态: 

+ **已修改Modified (M)** ：缓存行是脏的（dirty），与主存的值不同。如果别的CPU内核要读主存这块数据，该缓存行必须回写到主存，状态变为共享(S)。
+ **独占Exclusive (E)** ：缓存行只在当前缓存中，但是干净的--缓存数据同于主存数据。当别的缓存读取它时，状态变为共享；当前写数据时，变为已修改状态。 
+ **共享Shared (S)**：缓存行也存在于其它缓存中且是未修改的。缓存行可以在任意时刻抛弃。 
+ **无效Invalid (I)** ：缓存行是无效的。

任意一对缓存，对应缓存行的相容关系：

 ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E7%9A%84MESI%E5%AF%B9%E5%BA%94%E7%BC%93%E5%AD%98%E8%A1%8C%E5%85%B3%E7%B3%BB.png?raw=true)

当块标记为 M (已修改), 在其他缓存中的数据副本被标记为I(无效)。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E7%9A%84MESI%E7%8A%B6%E6%80%81%E5%8F%98%E5%8C%96%E5%9B%BE.png?raw=true)

#### Ⅵ. 伪共享问题

如果多个核的线程在操作同一个缓存行中的不同变量数据，那么就会出现频繁的缓存失效，即使在代码层面看这两个线程操作的数据之间完全没有关系。这种不合理的资源竞争情况就是伪共享（False Sharing）。 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E7%9A%84%E4%BC%AA%E5%85%B1%E4%BA%AB%E9%97%AE%E9%A2%98.png?raw=true)

##### ①. linux下查看Cache Line大小

Cache Line大小是64Byte 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM-linux%E6%9F%A5%E7%9C%8BCacheLine01.png?raw=true)

或者执行 cat /proc/cpuinfo 命令 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM-linux%E6%9F%A5%E7%9C%8BCacheLine02.png?raw=true)

##### ②. 避免伪共享方案

1. 缓存行填充

   ```java
   class Pointer {
        volatile long x;
       //避免伪共享： 缓存行填充
        long p1, p2, p3, p4, p5, p6, p7;
        volatile long y;
   }
   ```

2. 使用@sun.misc.Contended 注解（java8）

   注意需要配置jvm参数：-XX:-RestrictContended 

   ```java
   public class FalseSharingTest {
       public static void main(String[] args) throws InterruptedException {
           testPointer(new Pointer());
       }
   
       private static void testPointer(Pointer pointer) throws InterruptedException {
           long start = System.currentTimeMillis();
           Thread t1 = new Thread(() -> {
               for (int i = 0; i < 100000000; i++) {
                   pointer.x++;
               }
           });
           Thread t2 = new Thread(() -> {
               for (int i = 0; i < 100000000; i++) {
                   pointer.y++;
               }
           });
           t1.start();
           t2.start();
           t1.join();
           t2.join();
           // 思考：x,y是线程安全的吗？
           System.out.println(pointer.x+","+pointer.y);
           System.out.println(System.currentTimeMillis() - start);
       }
   }
   class Pointer {
       // 避免伪共享： @Contended +  jvm参数：-XX:-RestrictContended  jdk8支持
       @Contended
       volatile long x;
       volatile long y;
   }
   ```

   

## 5、有序性问题深入研究

```java
public class ReOrderTest {
    private static  int x = 0, y = 0;
    private volatile static  int a = 0, b = 0;
    public static void main(String[] args) throws InterruptedException {
        int i=0;
        while (true) {
            i++;
            x = 0;
            y = 0;
            a = 0;
            b = 0;
            /**
             *  x,y:   00, 10, 01, 11
             */
            Thread thread1 = new Thread(() -> {
                shortWait(20000);
                a = 1; // volatile写
                // StoreLoad
                // UnsafeFactory.getUnsafe().storeFence();
                x = b; // volatile读
            });
            Thread thread2 = new Thread(() -> {
                b = 1;
                // UnsafeFactory.getUnsafe().storeFence();
                y = a;
            });
            thread1.start();
            thread2.start();
            thread1.join();
            thread2.join();
            System.out.println("第" + i + "次（" + x + "," + y + ")");
            if (x==0&&y==0){
                break;
            }
        }
    }
    public static void shortWait(long interval){
        long start = System.nanoTime();
        long end;
        do{
            end = System.nanoTime();
        }while(start + interval >= end);
    }

}
```

### 1. 指令重排序

Java语言规范规定JVM线程内部维持顺序化语义。即只要程序的最终结果与它顺序化情况的结果相等，那么指令的执行顺序可以与代码顺序不一致，此过程叫指令的重排序。

指令重排序的意义：<font color='red'>JVM能根据处理器特性（CPU多级缓存系统、多核处理器等）适当的对机器指令进行重排序，使机器指令能更符合CPU的执行特性，最大限度的发挥机器性能。</font>

在编译器与CPU处理器中都能执行指令重排优化操作：

源代码 -- > 1：编译器优化冲排序 -- > 2：指令级并行冲排序 -- > 3：内存系统冲排序 -- > 最终执行的指令序列

### 2. **volatile重排序规则**

| 是否能重排序 | 第二个操作 |            |            |
| ------------ | ---------- | ---------- | ---------- |
| 第一个操作   | 普通读/写  | volatile读 | volatile写 |
| 普通读/写    |            |            | NO         |
| volatile读   | NO         | NO         | NO         |
| volatile写   |            | NO         | NO         |

**volatile禁止重排序场景：**

1. 第二个操作是volatile写，不管第一个操作是什么都不会重排序

2. 第一个操作是volatile读，不管第二个操作是什么都不会重排序

3. 第一个操作是volatile写，第二个操作是volatile读，也不会发生重排序

**JMM内存屏障插入策略：**

1. 在每个volatile写操作的前面插入一个StoreStore屏障

2. 在每个volatile写操作的后面插入一个StoreLoad屏障

3. 在每个volatile读操作的后面插入一个LoadLoad屏障

4. 在每个volatile读操作的后面插入一个LoadStore屏障

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E5%86%85%E5%AD%98%E5%B1%8F%E9%9A%9C%E6%8F%92%E5%85%A5%E7%AD%96%E7%95%A5.png?raw=true)

如何充分压榨硬件性能，压榨CPU计算能力，减少CPU等待时间（机械同感）

### 3. JSR133规范

x86处理器不会对读-读、读-写和写-写操作做重排序, 会省略掉这3种操作类型对应的内存屏障。仅会对写-读操作做重排序，所以volatile写-读操作只需要在volatile写后插入StoreLoad屏障 。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM%E7%9A%84JSR133%E8%A7%84%E8%8C%83%E5%9B%BE.png?raw=true)

### 4. JVM层面的内存屏障

在JSR规范中定义了4种内存屏障：

**LoadLoad屏障**：（指令Load1; LoadLoad; Load2），在Load2及后续读取操作要读取的数据被访问前，保证Load1要读取的数据被读取完毕。

**LoadStore屏障**：（指令Load1; LoadStore; Store2），在Store2及后续写入操作被刷出前，保证Load1要读取的数据被读取完毕。

**StoreStore屏障**：（指令Store1; StoreStore; Store2），在Store2及后续写入操作执行前，保证Store1的写入操作对其它处理器可见。

**StoreLoad屏障**：（指令Store1; StoreLoad; Load2），在Load2及后续所有读取操作执行前，保证Store1的写入对所有处理器可见。它的开销是四种屏障中最大的。在大多数处理器的实现中，这个屏障是个万能屏障，兼具其它三种内存屏障的功能。

由于x86只有store load可能会重排序，所以只有JSR的StoreLoad屏障对应它的mfence或lock前缀指令，其他屏障对应空操作。

### 5. 硬件层内存屏障

硬件层提供了一系列的内存屏障 memory barrier / memory fence(Intel的提法)来提供一致性的能力。拿X86平台来说，有几种主要的内存屏障：

1. lfence，是一种Load Barrier 读屏障

2. sfence, 是一种Store Barrier 写屏障

3. mfence, 是一种全能型的屏障，具备lfence和sfence的能力

4. Lock前缀，Lock不是一种内存屏障，但是它能完成类似内存屏障的功能。Lock会对CPU总线和高速缓存加锁，可以理解为CPU指令级的一种锁。它后面可以跟ADD, ADC, AND, BTC, BTR, BTS, CMPXCHG, CMPXCH8B, DEC, INC, NEG, NOT, OR, SBB, SUB, XOR, XADD, and XCHG等指令。

**内存屏障有两个能力：**

1. 阻止屏障两边的指令重排序

2. 刷新处理器缓存/冲刷处理器缓存

对Load Barrier来说，在读指令前插入读屏障，可以让高速缓存中的数据失效，重新从主内存加载数据。

对Store Barrier来说，在写指令之后插入写屏障，能让写入缓存的最新数据写回到主内存。

Lock前缀实现了类似的能力，它先对总线和缓存加锁，然后执行后面的指令，最后释放锁后会把高速缓存中的数据刷新回主内存。在Lock锁住总线的时候，其他CPU的读写请求都会被阻塞，直到锁释放。

<font color='red'>不同硬件实现内存屏障的方式不同，Java内存模型屏蔽了这种底层硬件平台的差异，由JVM来为不同的平台生成相应的机器码。</font>

### 6.as-if-serial

as-if-serial语义的意思是：<font color='red'>**不管怎么重排序（编译器和处理器为了提高并行度），（单线程）程序的执行结果不能被改变。**</font>编译器、runtime和处理器都必须遵守as-if-serial语义。 

为了遵守as-if-serial语义，编译器和处理器不会对存在数据依赖关系的操作做重排序，因为这种重排序会改变执行结果。但是，如果操作之间不存在数据依赖关系，这些操作就可能被编译器和处理器重排序。

```java
double pi = 3.14; // A 
double r = 1.0; // B 
double area = pi * r * r; // C
```

A和C之间存在数据依赖关系，同时B和C之间也存在数据依赖关系。因此在最终执行的指令序列中，C不能被重排序到A和B的前面（C排到A和B的前面，程序的结果将会被改变）。但A和B之间没有数据依赖关系，编译器和处理器可以重排序A和B之间的执行顺序。

### 7.happens-before

从JDK 5 开始，JMM使用happens-before的概念来阐述多线程之间的内存可见性。在JMM中，如果一个操作执行的结果需要对另一个操作可见，那么这两个操作之间必须存在happens- before关系。 happens-before和JMM关系如下图：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JMM-happensbefore.png?raw=true)

happens-before原则非常重要，<font color='red'>它是判断数据是否存在竞争、线程是否安全的主要依据，</font>依靠这个原则，我们解决在并发环境下两操作之间是否可能存在冲突的所有问题。

下面我们就一个简单的例子稍微了解下happens-before ：

```java
i = 1; //线程A执行 
j = i ; //线程B执行
```

j 是否等于1呢？假定线程A的操作（i = 1）happens-before线程B的操作（j = i）,那么可以确定线程B执行后j = 1 一定成立，如果他们不存在happens-before原则，那么j = 1 不一定成立。这就是happens-before原则的威力。

#####  ①. happens-before规则的定义： 

1. 如果一个操作happens-before另一个操作，那么第一个操作的执行结果将对第二个操作 可见，而且第一个操作的执行顺序排在第二个操作之前。 

2. 两个操作之间存在happens-before关系，并不意味着一定要按照happens-before原则制定的顺序来执行。如果重排序之后的执行结果与按照happens-before关系来执行的结果一致，那么这种重排序并不非法。

   

##### ②. happens-before原则的规则：

1. 程序次序规则：一个线程内，按照代码顺序，书写在前面的操作先行发生于书写在后面的操作；
2. 锁定规则：一个unLock操作先行发生于后面对同一个锁的lock操作； 

3. volatile变量规则：对一个变量的写操作先行发生于后面对这个变量的读操作； 

4. 传递规则：如果操作A先行发生于操作B，而操作B又先行发生于操作C，则可以得出操作A 先行发生于操作C； 

5. 线程启动规则：Thread对象的start()方法先行发生于此线程的每个一个动作； 

6. 线程中断规则：对线程interrupt()方法的调用先行发生于被中断线程的代码检测到中断事件 的发生； 

7. 线程终结规则：线程中所有的操作都先行发生于线程的终止检测，我们可以通过Thread.join()方法结束、Thread.isAlive()的返回值手段检测到线程已经终止执行； 

8. 对象终结规则：一个对象的初始化完成先行发生于他的finalize()方法的开始；

我们来详细看看上面每条规则（摘自《深入理解Java虚拟机第12章》）： 

**程序次序规则**：一段代码在单线程中执行的结果是有序的。注意是执行结果，因为虚拟机、处理 器会对指令进行重排序。虽然重排序了，但是并不会影响程序的执行结果，所以程序最终执行的 结果与顺序执行的结果是一致的。故而这个规则只对单线程有效，在多线程环境下无法保证正确性。

**锁定规则**：这个规则比较好理解，无论是在单线程环境还是多线程环境，一个锁处于被锁定状态，那么必须先执行unlock操作后面才能进行lock操作。 

**volatile变量规则**：这是一条比较重要的规则，它标志着volatile保证了线程可见性。通俗点讲就 是如果一个线程先去写一个volatile变量，然后一个线程去读这个变量，那么这个写操作一定是 happens-before读操作的。**传递规则**：提现了happens-before原则具有传递性，即A happens-before B , B happens- before C，那么A happens-before C 。

**线程启动规则**：假定线程A在执行过程中，通过执行ThreadB.start()来启动线程B，那么线程A对共享变量的修改在接下来线程B开始执行后确保对线程B可见。 

**线程终结规则**：假定线程A在执行的过程中，通过制定ThreadB.join()等待线程B终止，那么线程B在终止之前对共享变量的修改在线程A等待返回后可见。

**上面八条是原生Java满足Happens-before关系的规则，但是我们可以对他们进行推导出其他满足happens-before的规则：**

1. 将一个元素放入一个线程安全的队列的操作Happens-Before从队列中取出这个元素的操作。

2. 将一个元素放入一个线程安全容器的操作Happens-Before从容器中取出这个元素的操作。

3. 在CountDownLatch上的倒数操作Happens-Before CountDownLatch#await()操作。

4. 释放Semaphore许可的操作Happens-Before获得许可操作。

5. Future表示的任务的所有操作Happens-Before Future#get()操作。

6. 向Executor提交一个Runnable或Callable的操作Happens-Before任务开始执行操作。

   

##### ③. happens-before的概念：

<font color='red'>**如果两个操作不存在上述（前面8条 + 后面6条）任一一个happens-before规则，那么这两个操作就没有顺序的保障，JVM可以对这两个操作进行重排序。如果操作A happens-before操作B，那么操作A在内存上所做的操作对操作B都是可见的。** </font>

下面就用一个简单的例子来描述下happens-before原则：

```java
private int i = 0; 
public void write(int j ){ 
    i = j; 
} 
public int read(){ 
    return i; 
}
```

我们约定线程A执行write()，线程B执行read()，且线程A优先于线程B执行，那么 线程B获得结果是什么？

我们就这段简单的代码一次分析happens­before的规则（规则5、6、7、8 + 推导的6条可以忽略，因为他们和这段代码毫无关系）： 

+ 由于两个方法是由不同的线程调用，所以肯定不满足程序次序规则； 

+ 两个方法都没有使用锁，所以不满足锁定规则； 
+ 变量i不是用volatile修饰的，所以volatile变量规则不满足； 
+ 传递规则肯定不满足；

所以我们无法通过happens­before原则推导出线程A happens­before线程B，虽然可以确认在时间上线程A优先于线程B指定，但是就是无法确认线程B获得的结果是什么，所以这段代码不是线程安全的。

那么怎么修复这段代码呢？

满足规则2、3任一即可。

**总结：**

<font color='red'>**happens-before原则是JMM中非常重要的原则，它是判断数据是否存在竞争、线程是否安全的主要依据，保证了多线程环境下的可见性。**</font>
