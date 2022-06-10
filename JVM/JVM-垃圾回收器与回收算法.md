# 一、JVM垃圾回收算法

## Ⅰ .分代收集理论

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%9E%83%E5%9C%BE%E5%9B%9E%E6%94%B6%E7%AE%97%E6%B3%95%E6%A6%82%E8%BF%B0.png?raw=true)

+ 根据对象存活周期的不同将内存分为几个模块。
+ 将java堆分为新生代和老年代，这样可以根据各个年代的特点选择各自适合的垃圾收集算法。

## Ⅱ.标记-复制算法

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E6%A0%87%E8%AE%B0-%E5%A4%8D%E5%88%B6%E7%AE%97%E6%B3%95.png?raw=true)

### 1.原理：

主要是**将内存分为大小相同的两块**，每次使用其中一块进行存放，当这一块内存使用完后，就将存活的对象复制到另一块，

这样每次内存回收只需要对内存区间的一半进行回收。

### 2.优点：

内存整理方便，将存活的对象直接移到领一块内存区域，情况正在使用的内存区域，不会产生内存碎片。

适用于新生代，将内存区分为两部分，回收效率高。

### 3.缺点：

将内存空间一分为二，对内存消耗大，不适用老年带。

## Ⅲ.标记-清除算法

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E6%A0%87%E8%AE%B0-%E6%B8%85%E9%99%A4%E7%AE%97%E6%B3%95.png?raw=true)

### 1.原理：

该算法分为两个阶段：

+ 标记阶段：标记出需要回收的对象

+ 清除阶段：清除被标记的对象

### 2.产生的问题：

+ 效率问题：如果堆内存的空间过大，对象过多，则回收效率不高。

+ 空间问题：标记清除后，内存区域会产生大量不连续的空间碎片。

  

## Ⅳ.标记-整理算法

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E6%A0%87%E8%AE%B0-%E6%95%B4%E7%90%86%E7%AE%97%E6%B3%95.png?raw=true)

该算法是根据老年代特点设计出的一种标记算法，标记过程仍与**标记-清除**算法一样，只是多了一步整理操作。

步骤：

1. 标记垃圾对象。
2. 让所有存活的对象向向内存的一端移动。
3. 清理掉边界意外的内存。

---

# 二、JVM垃圾收集器

## Ⅰ.Serial收集器

(-XX:+UseSerialGC（新生代） -XX:+UseSerialOldGC（老年代）)

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/serial%E6%94%B6%E9%9B%86%E5%99%A8.png?raw=true)

### 1.介绍：

Serial收集器，也叫单线程收集器，工作时使用一条垃圾收集线程去完成垃圾收集工作，更重要的是它在进行垃圾收集工作的时候必须暂停其他所有的工作线程（ "Stop The World" ），直到它收集结束。

新生代采用复制算法，老年代采用标记-整理算法。

### 2.优缺点：

优点：简单且高效，没有线程交互的开销，自然可以获得很高的单线程收集效率。

缺点：收集垃圾时，会STW，对用户体验不是很好。

### 3.用途：

Serial Old收集器是Serial收集器的老年代版本，它同样是一个单线程收集器。它主要有两大用途：

+ 在JDK1.5以及以前的版本与Parallel Scavenge收集器搭配使用

+ 作为CMS收集器的后备方案。

----

## Ⅱ.Parallel Scavenge收集器 

(-XX:+UseParallelGC(年轻代),-XX:+UseParallelOldGC(老年代))

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/parallel%E6%94%B6%E9%9B%86%E5%99%A8.png?raw=true)



### 1.介绍

Parallel收集器其实就是**Serial收集器的多线程版本**，除了使用多线程进行垃圾收集外，其余行为（控制参数、收集算法、回收策略等等）和Serial收集器类似。默认的收集线程数跟cpu核数相同，当然也可以用参数(-XX:ParallelGCThreads)指定收集线程数，但是一般不推荐修改。

Parallel Scavenge收集器关注点是吞吐量（高效率的利用CPU）。CMS等垃圾收集器的关注点更多的是用户线程的停顿时间（提高用户体验）。

**新生代**采用复制算法，**老年代**采用标记-整理算法。

### 2.注意：

Parallel Old收集器是Parallel Scavenge收集器的老年代版本。使用多线程和“标记-整理”算法。在注重吞吐量以及CPU资源的场合，都可以优先考虑 Parallel Scavenge收集器和Parallel Old收集器(JDK8默认的新生代和老年代收集器)。

----

## Ⅲ.ParNew收集器

(-XX:+UseParNewGC)

![img](https://raw.githubusercontent.com/hepengjun2022/doc-java/master/pic/parnew%E6%94%B6%E9%9B%86%E5%99%A8.png)

ParNew收集器其实跟Parallel收集器很类似，区别主要在于它可以和CMS收集器配合使用。

它是许多运行在Server模式下的虚拟机的首要选择，除了Serial收集器外，只有它能与CMS收集器（真正意义上的并发收集器）配合工作。

----

## Ⅳ.CMS收集器

(-XX:+UseConcMarkSweepGC(old))

### 1.介绍：

+ CMS（Concurrent Mark Sweep）收集器是一种以获取最短回收停顿时间为目标的收集器。

+ 它非常符合在注重用户体验的应用上使用，它是HotSpot虚拟机第一款真正意义上的并发收集器，它第一次实现了让垃圾收集线程与用户线程（基本上）同时工作。

+ CMS收集器是一种 “标记-清除”算法实现的，它的运作过程相比于前面几种垃圾收集器来说更加复杂一些。

### 2.垃圾收集过程

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/cms%E5%9E%83%E5%9C%BE%E6%94%B6%E9%9B%86%E5%99%A8.png?raw=true)

#### **①.初始标记：**

暂停所有的其他线程(STW)，并记录下gc roots直接能引用的对象，该阶段速度很快。

#### **②.并发标记：**

并发标记阶段就是**从GC Roots的直接关联对象开始遍历整个对象图的过程**， 这个过程耗时较长但是不需要停顿用户线程， **可以与垃圾收集线程一起并发运行**。因为用户程序继续运行，可能会有导致已经标记过的对象状态发生改变。

#### **③.重新标记：**

重新标记阶段就是为了修正并发标记期间因为用户程序继续运行导致标记产生变动的那一部分对象的标记记录，这个阶段的停顿时间一般会比初始标记阶段的时间稍长，远远比并发标记阶段时间短。**主要用到三色标记里的增量更新算法做重新标记。**

#### **④.并发清理：**

开启用户线程，同时GC线程开始对未标记的区域做清扫。这个阶段如果有新增对象会被标记为黑色不做任何处理。

#### **⑤.并发重置：**

重置本次GC过程中的标记数据。

### 3.优缺点

##### 优点：

并发收集、低停顿。

##### 缺点：

+ <font color='red'>对CPU资源敏感（会和服务抢资源）。</font>

+ <font color='red'>无法处理浮动垃圾(在并发标记和并发清理阶段又产生垃圾</font>，这种浮动垃圾只能等到下一次gc再清理了)。

+ 它使用的<font color='red'>回收算法-“标记-清除”算法会导致收集结束时会有大量空间碎片产生</font>，通过参数XX:+UseCMSCompactAtFullCollection可以让jvm在执行完标记清除后再进行空间整理。

+ <font color='red'>执行过程中的不确定性</font>，会存在上一次垃圾回收还没执行完，然后垃圾回收又被触发的情况，特别是在并发标记和并发清理阶段会出现，一边回收，系统一边运行，也许没回收完就再次触发full gc，也就是"concurrentmode failure"，此时会进入stop the world，用serial old垃圾收集器来回收。

### 4.CMS底层收集算法（三色标记）

在并发标记的过程中，因为标记期间应用线程还在继续跑，对象间的引用可能发生变化，多标和漏标的情况就有可能发生。这里我们引入“三色标记”来给大家解释下，把Gcroots可达性分析遍历对象过程中遇到的对象， 按照“是否访问过”这个条件标记成以下三种颜色：

![img](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220411064729451.png)

+ **黑色**：表示对象已经被垃圾收集器访问过，且这个对象的所有引用都已扫描过。黑色的对象代表已扫描过，确认是安全存活的，但如果有其他对象引用指向了黑色对象，无须重新扫描一遍。黑色对象不可能直接（不经过灰色对象） 指向某个白色象。

+ **灰色**：表示对象已经被垃圾收集器访问过，但这个对象上至少存在一个引用还没有被扫描过。 

+ **白色**：表示对象尚未被垃圾收集器访问过。显然在可达性分析刚刚开始的阶段，所有的对象都是白色的，若在分析结束的阶段，仍然是白色的对象，即代表不可达。

```
public class ThreeColorRemark {

    public static void main(String[] args) {
        A a = new A();
        //开始做并发标记
        D d = a.b.d; // 1.读
        a.b.d = null; // 2.写
        a.d = d; // 3.写
    }
}
class A {
    B b = new B();
    D d = null;
}
class B {
    C c = new C();
    D d = new D();
}
class C {
}
class D {
}
```

### 5.收集中产生的问题

#### ①.多标-浮动垃圾：

+ 在并发标记过程中，如果由于方法运行结束导致部分局部变量(gcroot)被销毁，这个GCRoot引用的对象之前又被扫描过(被标记为非垃圾对象)，那么本轮GC不会回收这部分内存，这部分本应该回收却没有回收的对象，被称之为“浮动垃圾”。
+ 浮动垃圾并不会影响垃圾回收的正确性，只是需要等到下一轮垃圾回收中才被清除。
+ 另外，<font color='red'>针对并发标记(还有并发清理)开始后产生的新对象，通常的做法是直接全部当成黑色，本轮不会进行清除，这部分对象期间可能也会变为垃圾，这也算是浮动垃圾的一部分。</font>

#### ②.漏标-读写屏障：

漏标会导致被引用的对象被当成垃圾误删除，这是严重bug，必须解决。

**解决方案：**

##### **a.增量更新：**

**（incremental Update）**

+ 当黑色对象插入新的指向白色对象的引用关系时， 就将这个新插入的引用记录下来， 等并发标记结束之后， 再将这些记录过的引用关系中的黑色对象为根， 重新扫描一次。 

+ 这可以简化理解为， 黑色对象一旦新插入了指向白色对象的引用之后， 它就变回灰色对象了。

+ 如果不进行处理，在并发清理阶段就会被清理掉，这是严重BUG，所以必须在清理前进行重新标记。

##### **b.原始快照：**

**（Snapshot At The Beginning，SATB） **

当灰色对象要删除指向白色对象的引用关系时， 将需要删除的引用通过写屏障方式记录下来， 在并发标记结束之后， 再将这些记录过的引用关系中的灰色对象为根， 重新扫描一次，这样就能扫描到白色的对象，将白色对象直接标记为黑色，让其成为浮动垃圾，下一轮GC进行回收。

**将白色对象直接标记为黑色的目的：**让这种对象在本轮gc清理中能存活下来，待下一轮gc的时候重新扫描，这个对象也有可能是浮动垃圾。（SATB这种不会深度扫描。只是找到白色对象，标记为黑色即可）

以上无论是对引用关系记录的插入还是删除， 虚拟机的记录操作都是通过写屏障实现的。

#### ③.读写屏障

对于读写屏障，以Java HotSpot VM为例，其并发标记时对漏标的处理方案如下： 

+ CMS：写屏障 + 增量更新

+ G1，Shenandoah：写屏障 + SATB 

+ ZGC：读屏障

##### **a.写屏障：**

其实就是指在赋值操作前后，加入一些处理（可以参考AOP的概念）

```
void oop_field_store(oop* field, oop new_value) {
    pre_write_barrier(field); // 写屏障‐写前操作
    *field = new_value;
    post_write_barrier(field, value); // 写屏障‐写后操作
}
```

**写屏障实现SATB：**

当对象B的成员变量的引用发生变化时，比如引用消失（a.b.d = null），我们可以利用写屏障，将B原来成员变量的引用对象D记录下来。

```
void oop_field_store(oop* field, oop new_value) {
    pre_write_barrier(field); // 写屏障‐写前操作
    *field = new_value;
}
void pre_write_barrier(oop* field) {
    oop old_value = *field; // 获取旧值
    remark_set.add(old_value); // 记录原来的引用对象
}
```

##### **b.读屏障：**

```
oop oop_field_load(oop* field) {
    pre_load_barrier(field); // 读屏障‐读取前操作
    return *field;
}
```

读屏障是直接针对第一步：D d = a.b.d，当读取成员变量时，一律记录下来：

```
void pre_load_barrier(oop* field) {
    oop old_value = *field;
    remark_set.add(old_value); // 记录读取到的对象
}
```

现代追踪式（可达性分析）的垃圾回收器几乎都借鉴了三色标记的算法思想，尽管实现的方式不尽相同：

比如白色/黑色集合一般都不会出现（但是有其他体现颜色的地方）、灰色集合可以通过栈/队列/缓存日志等方式进行实现、遍历方式可以是广度/深度遍历等等。

**为什么G1用SATB？CMS用增量更新？**

SATB相对增量更新效率会高(当然SATB可能造成更多的浮动垃圾)，因为不需要在重新标记阶段再次深度扫描被删除引用对象，而CMS对增量引用的根对象会做深度扫描，G1因为很多对象都位于不同的region，CMS就一块老年代区域，重新深度扫描对象的话G1的代价会比CMS高，所以G1选择SATB不深度扫描对象，只是简单标记，等到下一轮GC再深度扫描。

### **6.CMS的相关核心参数：**

**-XX:+UseConcMarkSweepGC**：启用cms。

**-XX:ConcGCThreads**：并发的GC线程数 

**-XX:+UseCMSCompactAtFullCollection**：FullGC之后做压缩整理（减少碎片）。 

**-XX:CMSFullGCsBeforeCompaction**：多少次FullGC之后压缩一次，默认是0，代表每次FullGC后都会压缩一 次 5。 

**-XX:CMSInitiatingOccupancyFraction**: 当老年代使用达到该比例时会触发FullGC（默认是92，这是百分比）。 

**-XX:+UseCMSInitiatingOccupancyOnly**：只使用设定的回收阈值(-XX:CMSInitiatingOccupancyFraction设 定的值)，如果不指定，JVM仅在第一次使用设定值，后续则会自动调整。 

**-XX:+CMSScavengeBeforeRemark**：在CMS GC前启动一次minor gc，目的在于减少老年代对年轻代的引 用，降低CMS GC的标记阶段时的开销，一般CMS的GC耗时 80%都在标记阶段 。

**-XX:+CMSParallellnitialMarkEnabled**：表示在初始标记的时候多线程执行，缩短STW 。

**-XX:+CMSParallelRemarkEnabled**：在重新标记的时候多线程执行，缩短STW。

----

## Ⅴ.G1收集器

**(-XX:+UseG1GC)**

### 1.介绍：

G1 (Garbage-First)是一款面向服务器的垃圾收集器,主要针对配备多颗处理器及大容量内存的机器. 以极高概率满足GC 停顿时间要求的同时,还具备高吞吐量性能特征。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/G1%E6%94%B6%E9%9B%86%E5%99%A8.png?raw=true)

- G1将Java堆划分为多个大小相等的独立区域（Region），JVM最多可以有2048个Region。 一般Region大小等于堆大小除以2048，比如堆大小为4096M，则Region大小为2M，当然也可以用参数"-XX:G1HeapRegionSize"手动指定Region大小，但是推荐默认的计算方式。

- G1保留了年轻代和老年代的概念，但不再是物理隔阂，它们都是（可以不连续）Region的集合。
- <font color='red'>默认年轻代对堆内存的占比是5%</font>，如果堆大小为4096M，那么年轻代占据200MB左右的内存，对应大概是100个 Region，可以通过“-XX:G1NewSizePercent”设置新生代初始占比。
- 在系统运行中，<font color='red'> JVM会不停的给年轻代增加更多的Region，但是最多新生代的占比不会超过60%</font>，可以通过“-XX:G1MaxNewSizePercent”调整。
- <font color='red'>年轻代中的Eden和 Survivor对应的region也跟之前一样，默认8:1:1</font>，假设年轻代现在有1000个region，eden区对应800个，s0对应100 个，s1对应100个。
- <font color='red'>一个Region可能之前是年轻代，如果Region进行了垃圾回收，之后可能又会变成老年代，也就是说Region的区域功能可能会动态变化。</font>
- G1垃圾收集器对于对象什么时候会转移到老年代跟以前一样的规则，<font color='red'>唯一不同的是对大对象的处理，G1有专门分配大对象的Region叫Humongous区，而不是让大对象直接进入老年代的Region中。</font>
- <font color='red'>在G1中，大对象的判定规则就是一个大对象超过了一个Region大小的50%</font>，比如按照上面算的，每个Region是2M，只要一个大对象超过了1M，就会被放入Humongous中，而且一个大对象如果太大，可能会横跨多个Region来存放。<font color='red'>Humongous区专门存放短期巨型对象，不用直接进老年代，可以节约老年代的空间</font>，避免因为老年代空间不够的GC开销。

### **2.垃圾收集步骤：**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/G1%E5%9E%83%E5%9C%BE%E6%94%B6%E9%9B%86%E5%99%A8%E6%AD%A5%E9%AA%A4.png?raw=true)

#### **1.初始标记：**

（initial mark，STW）

暂停所有的其他线程，并记录下gc roots直接能引用的对象，速度很快 。 

#### **2.并发标记：**

（Concurrent Marking）

开启用户线程，同时GC线程开始对未标记的区域做清扫。这个阶段如果有新增对象会被标记为黑色不做任何处理。

#### **3.最终标记：**

（Remark，STW）

重新标记阶段就是为了修正并发标记期间因为用户程序继续运行导致标记产生变动的那一部分对象的标记记录，这个阶段的停顿时间一般会比初始标记阶段的时间稍长，远远比并发标记阶段时间短。**主要用到三色标记里的增量更新算法做重新标记。**

#### **4.筛选回收：**

（Cleanup，STW）

+ <font color='red'>筛选回收阶段首先对各个Region的回收价值和成本进行排序，根据用户所期望的GC停顿时间来制定回收计划。</font>(可以用JVM参数 -XX:MaxGCPauseMillis指定停顿时间)
+ 比如说老年代此时有1000个 Region都满了，但是因为根据预期停顿时间，本次垃圾回收可能只能停顿200毫秒，那么通过之前回收成本计算得知，可能回收其中800个Region刚好需要200ms，那么就只会回收800个Region(Collection Set，要回收的集合)，尽量把GC导致的停顿时间控制在我们指定的范围内。这个阶段其实也可以做到与用户程序一起并发执行，但是因为只回收一部分Region，时间是用户可控制的，而且停顿用户线程将大幅提高收集效率。
+ <font color='red'>不管是年轻代或是老年代，回收算法主要用的是复制算法，将一个region中的存活对象复制到另一个region中，这种不会像CMS那样回收完因为有很多内存碎片还需要整理一次，G1采用复制算法回收几乎不会有太多内存碎片。</font>
+ <font color='red'>CMS回收阶段是跟用户线程一起并发执行的，G1因为内部实现太复杂暂时没实现并发回收</font>，不过到了Shenandoah就实现了并发收集，Shenandoah可以看成是G1的升级版本。

### 3.G1垃圾收集分类：

- **YoungGC：**YoungGC并不是说现有的Eden区放满了就会马上触发，G1会计算下现在Eden区回收大概要多久时间，如果回收时间远远小于参数 -XX:MaxGCPauseMills 设定的值，那么增加年轻代的region，继续给新对象存放，不会马上做YoungGC，直到下一次Eden区放满，G1计算回收时间接近参数 -XX:MaxGCPauseMills 设定的值，那么就会触发Young GC。
- **MixedGC：**老年代的堆占有率达到参数(-XX:InitiatingHeapOccupancyPercent)设定的值则触发，回收所有的Young和部分Old(根据期望的GC停顿时间确定old区垃圾收集的优先顺序)以及大对象区，<font color='red'>正常情况G1的垃圾收集是先做MixedGC，主要使用复制法，需要把各个region中存活的对象拷贝到别的region里去，拷贝过程中如果发现没有足够的空region能够承载拷贝对象就会触发一次Full GC。</font>
- **Full GC：**<font color='red'>停止系统程序，然后采用单线程进行标记、清理和压缩整理，好空闲出来一批Region来供下一次MixedGC使用，这个过程是非常耗时的。</font>(Shenandoah优化成多线程收集了)。

### **4.G1收集器参数设置：**

**-XX:+UseG1GC：**使用G1收集器。

**-XX:ParallelGCThreads：**指定GC工作的线程数量 。

**-XX:G1HeapRegionSize：**指定分区大小(1MB~32MB，且必须是2的N次幂)，默认将整堆划分为2048个分区 。

**-XX:MaxGCPauseMillis：**目标暂停时间(默认200ms) 。

**-XX:G1NewSizePercent：**新生代内存初始空间(默认整堆5%) 。

**-XX:G1MaxNewSizePercent：**新生代内存最大空间 。

**-XX:TargetSurvivorRatio：**Survivor区的填充容量(默认50%)，Survivor区域里的一批对象(年龄1+年龄2+年龄n的多个 年龄对象)总和超过了Survivor区域的50%，此时就会把年龄n(含)以上的对象都放入老年代 。

**-XX:MaxTenuringThreshold：**最大年龄阈值(默认15) 。

**-XX:InitiatingHeapOccupancyPercent：**老年代占用空间达到整堆内存阈值(默认45%)，则执行新生代和老年代的混合 收集(MixedGC)，比如我们之前说的堆默认有2048个region，如果有接近1000个region都是老年代的region，则可能 就要触发MixedGC了。

**-XX:G1MixedGCLiveThresholdPercent：**(默认85%) region中的存活对象低于这个值时才会回收该region，如果超过这 个值，存活对象过多，回收的的意义不大。 

**-XX:G1MixedGCCountTarget：**在一次回收过程中指定做几次筛选回收(默认8次)，在最后一个筛选回收阶段可以回收一 会，然后暂停回收，恢复系统运行，一会再开始回收，这样可以让系统不至于单次停顿时间过长。

 **-XX:G1HeapWastePercent(默认5%)：**gc过程中空出来的region是否充足阈值，在混合回收的时候，对Region回收都 是基于复制算法进行的，都是把要回收的Region里的存活对象放入其他Region，然后这个Region中的垃圾对象全部清 理掉，这样的话在回收过程就会不断空出来新的Region，一旦空闲出来的Region数量达到了堆内存的5%，此时就会立 即停止混合回收，意味着本次混合回收就结束了。

### **5.G1垃圾收集器适用场景：**

1. 50%以上的堆被存活对象占用 。
2. 对象分配和晋升的速度变化非常大 。
3. 垃圾回收时间特别长，超过1秒 。
4. 8GB以上的堆内存(建议值) 。
5. 停顿时间是500ms以内。

### 6.总结：

毫无疑问， 可以由用户指定期望的停顿时间是G1收集器很强大的一个功能， 设置不同的期望停顿时间， 可使得G1在不 同应用场景中取得关注吞吐量和关注延迟之间的最佳平衡。 不过， 这里设置的“期望值”必须是符合实际的， 不能异想天开， 毕竟G1是要冻结用户线程来复制对象的， 这个停顿时间再怎么低也得有个限度。 它默认的停顿目标为两百毫秒，一般来说， 回收阶段占到几十到一百甚至接近两百毫秒都很正常， 但如果我们把停顿时间调得非常低， 譬如设置为二十毫秒， 很可能出现的结果就是由于停顿目标时间太短， 导致每次选出来的回收集只占堆内存很小的一部分， 收集器收集的速度逐渐跟不上分配器分配的速度， 导致垃圾慢慢堆积。 很可能一开始收集器还能从空闲的堆内存中获得一些喘息的时间， 但应用运行时间一长就不行了， 最终占满堆引发Full GC反而降低性能， 所以通常把期望停顿时间设置为一两百毫秒或者两三百毫秒会是比较合理的。

----

## Ⅵ.ZGC收集器

### 1.ZGC出现的背景



![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC%E5%87%BA%E7%8E%B0%E8%83%8C%E6%99%AF.png?raw=true)

在Java项目中，如果JVM要进行垃圾回收，会暂停所有业务线程，这会导致业务系统暂停。而ZGC就是为了减少STW时间到极致而生的。

### 2.ZGC介绍和ZGC的目标

ZGC（the Z Garbage Collector）是JDK11中推出的一款追求极致低延迟的垃圾收集器。

ZGC的目标：

+ 停顿时间不超过10ms（JDK16已经达到不超过1ms）
+ 停顿时间不会随着堆大小或者活跃对象数量增加而增加。
+ 支持8MB-4TB级别的堆大小，JDK15以后已经支持16TB。

### 3.ZGC的内存布局

ZGC为了细粒度地控制内存的分配，将内存划分成小的分区，称之为页面（Page）。

ZGC中没有分代的概念（新生代、老年代）。

**ZGC支持三种页面：**

+ 小页面：2MB页面空间
+ 中页面：32MB的页面空间
+ 大页面：受操作系统控制

**对象根据大小不同在ZGC中分配内存：**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AF%B9%E8%B1%A1%E5%9C%A8ZGC%E7%9A%84%E5%86%85%E5%AD%98%E5%88%86%E9%85%8D.png?raw=true)

+ 当对象大小 <= 256KB时，对象分配在小页面。
+ 当 256KB <  对象大小 <=4MB时，对象分配在中页面。
+ 当 4MB < 对象大小，对象分配在大页面。  

**ZGC对不同页面回收策略：**

简单来说，优先回收小页面。中页面、大页面尽量不回收。

**ZGC为什么要将内存进行分页这样的设计？**

标准大页（huge page）是Linux Kernel 2.6引入的，目的是通过使用大页内存来取代传统的4KB内存页面，以 

适应越来越大的系统内存，让操作系统可以支持现代硬件架构的大页面容量功能。

Huge pages两种格式大小：

+ 2MB：适用于GB级别内存。（默认）

+ 1GB：适用于TB级别的内存。

所以ZGC这么设置也是为了适应现代硬件架构的发展，提升性能。

### 4.ZGC支持NUMA

在过去，对于X86架构的计算机，内存控制器还没有整合进CPU，所有对内存的访问都需要通过北桥芯片来完成。X86系统中的所有内存都可以通过CPU进行同等访问。任何CPU访问任何内存的速度是一致的，不必考虑不同内存地址之间的差异，这称为“统一内存访问”（Uniform Memory Access，UMA）。

UMA系统的架构示意图：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC%E6%94%AF%E6%8C%81%E7%9A%84NUMA.png?raw=true)

在UMA中，各处理器与内存单元通过互联总线进行连接，各个CPU之间没有主从关系。之后的X86平台经历了 

一场从“拼频率”到“拼核心数”的转变，越来越多的核心被尽可能地塞进了同一块芯片上，各个核心对于内 

存带宽的争抢访问成为瓶颈，所以人们希望能够把CPU和内存集成在一个单元上（称Socket），这就是非统一 

内存访问（Non-Uniform Memory Access，NUMA）。很明显，在NUMA下，CPU访问本地存储器的速度比 

访问非本地存储器快一些。

NUMA处理器架构示意图：

![img](https://raw.githubusercontent.com/hepengjun2022/doc-java/master/pic/NUMA%E7%BB%93%E6%9E%84%E7%A4%BA%E6%84%8F%E5%9B%BE.png)

### 5.ZGC指针着色技术

颜色指针可以说是ZGC的核心概念。ZGC在指针中借了几个位出来做事情，所以它必须要求在64位的机器上才可以工作。并且因为要求64位的指针，也就不能支持压缩指针。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC%E6%8C%87%E9%92%88%E7%9D%80%E8%89%B2%E6%8A%80%E6%9C%AF.png?raw=true)

+ 低42位：记录对象在堆空间的地址。
+ 42-45位：记录GC相关的事情。（快速实现垃圾回收中的并发标记、转移和重定位等）
+ 46-63位：预留出来，方便ZGC以后扩展使用。（例如ZGC支持16TB，就成了44位，使用了预留空间的两位来扩容。）
+ M0（绿色）：标记存活对象，第1次垃圾回收，该次是M0，下次就是M1。
+ M1（红色）：标记存活对象，第2次垃圾回收，该次是M1，下次就是M0。
+ Remapped（蓝色）：创建出的并分配内存的新对象/完成重定位的那些对象。

### 6.ZGC垃圾回收流程

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC%E5%9E%83%E5%9C%BE%E5%9B%9E%E6%94%B6%E6%B5%81%E7%A8%8B.png?raw=true)

**GC回收可分为两个阶段：**

+ 标记阶段（**ZGC基于指针着色的并发标记算法** ）

  0. **初始阶段：**在ZGC初始化之后，此时地址视图为Remapped，程序正常运行，在内存中分配对象，满足一定条件后垃圾回收启动。

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC-%E5%87%86%E5%A4%87%E9%98%B6%E6%AE%B5.png?raw=true)

  1. **初始标记：**从根集合(GC Roots)出发，找出根集合直接引用的活跃对象，初始标记只需要扫描所有GC Roots，其处理时间和GC Roots的数量成正比，停顿时间不会随着堆的大小或者活跃对象的大小而增加。 

     ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC-%E5%88%9D%E5%A7%8B%E6%A0%87%E8%AE%B0%E9%98%B6%E6%AE%B5.png?raw=true)

  2. **并发标记：**根据初始标记找到的根对象，使用深度优先遍历对象的成员变量进行标记，这个阶段处理时间较长，所以需要与用户线程一起并发执行。（无STW，该阶段会产生漏标问题）

     ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC-%E5%B9%B6%E5%8F%91%E6%A0%87%E8%AE%B0%E9%98%B6%E6%AE%B5.png?raw=true)

  3. **再标记：**主要处理漏标对象，通过SATB算法解决（需要STW，G1中的解决漏标的方案）。

     ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC-%E5%86%8D%E6%A0%87%E8%AE%B0%E9%98%B6%E6%AE%B5.png?raw=true)

  

  该阶段使用**根可达性算法**进行标记：（**ZGC基于指针着色的并发标记算法** ）

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC%E6%A0%B9%E5%8F%AF%E8%BE%BE%E6%80%A7%E7%AE%97%E6%B3%95.png?raw=true)

  以”GC Roots“的对象作为起始点，从这些节点开始向下搜索，搜索所走过的路径成为**引用链**，当一个对象到GC Roots没有任何引用链相连接时，则证明此对象不是可用的。

  作为GC Roots的对象主要有下面4种：

  + 虚拟机栈（栈帧中的本地变量表）：各个线程调用方法堆栈中使用到的参数、局部变量、临时变量。
  + 方法区中类静态变量：java类的引用类型静态变量。
  + 方法区中常量：例如字符串常量池里的引用。
  + 本地方法栈中JNI指针：即一般说的Native方法。

+ 转移阶段：（**ZGC基于指针着色的并发转移算法**）

  1. 并发转移准备：分析出最具有回收价值的GC分页。（无STW）

     ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC-%E8%BD%AC%E7%A7%BB%E5%87%86%E5%A4%87%E9%98%B6%E6%AE%B5.png?raw=true)

  2. 初始转移：转移初始标记的存活对象同时做对象重定位。（有STW）

     ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC-%E5%88%9D%E5%A7%8B%E8%BD%AC%E7%A7%BB%E9%98%B6%E6%AE%B5.png?raw=true)

  3. 并发转移：对转移并标记的存活对象做转移。（无STW）

     ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC-%E5%B9%B6%E5%8F%91%E8%BD%AC%E7%A7%BB%E9%98%B6%E6%AE%B51.png?raw=true)

  **ZGC如何做到并发转移？**

  + 转发表（类似于HashMap）

  + 对象转移和插转发表做原子操作。

  **使用到的算法：**

  + **标记 - 整理算法、标记 - 复制算法。**

  + 当内存中有可用的空间，则使用标记复制算法。
  + 当内存中无可用空间，则使用标记整理算法。

+ 重定向阶段：（**ZGC基于指针着色的重定位算法**）

  主要是对上一次非根节点的对象做重定位(在第二次垃圾回收并发标记阶段进行)

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC-%E9%87%8D%E5%AE%9A%E4%BD%8D%E9%98%B6%E6%AE%B5.png?raw=true)

  

### 7.ZGC底层读屏障

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC%E8%A7%A6%E5%8F%91%E8%AF%BB%E5%B1%8F%E9%9A%9C.png?raw=true)

1. 介绍：

+ 读屏障是JVM向应用代码插入一小段代码的技术。

+ 当应用线程从堆中读取对象引用时，就会执行读屏障的代码。

  注意：仅”从堆中读取的对象引用“才会触发读屏障，在栈上分配的对象则不会触发读屏障。

2. 涉及对象：并发转移但还没做重定向的对象（着色指针使用M0和M1可以区分）

3. 触发实际：在两次GC之间（上一次完成并发转移，并未完成重定向）

4. 触发操作：对象重定位+删除转发表记录（两个操作是原子操作）

### 8.ZGC中GC的触发机制（JDK16）

##### ①.预热规则

+ 服务刚启动时出现，一般不需要关注。日志中关键字是“Warmup”。 

+ JVM启动预热，如果从来没有发生过GC，则在堆内存使用超过10%、20%、30%时，分别触发一次GC，以收集GC数据。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC%E7%9A%84GC%E8%A7%A6%E5%8F%91%E6%9C%BA%E5%88%B6-%E5%9F%BA%E4%BA%8E%E5%88%86%E9%85%8D%E9%80%9F%E7%8E%87%E8%87%AA%E9%80%82%E5%BA%94.png?raw=true)

##### ②.基于分配速率的自适应算法

+ 最主要的GC触发方式（默认方式），其算法原理可简单描述为”ZGC根据近期的对象分配速率以及GC时间，计算出当内存占用达到什么阈值时触发下一次GC”。

+ 通过ZAllocationSpikeTolerance参数控制阈值大小，该参数默认2，数值越大，越早的触发GC。日志中关键字是“Allocation Rate”。 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ZGC%E7%9A%84GC%E8%A7%A6%E5%8F%91%E6%9C%BA%E5%88%B6-%E9%A2%84%E7%83%AD%E8%A7%84%E5%88%99.png?raw=true)

##### ③.基于固定时间间隔

通过ZCollectionInterval控制，适合应对突增流量场景。流量平稳变化时，自适应算法可能在堆使用率达到95%以上才触发GC。流量突增时，自适应算法触发的时机可能会过晚，导致部分线程阻塞。我们通过调整此参数解决流量突增场景的问题，比如定时活动、秒杀等场景。 

##### ④.主动触发规则

类似于固定间隔规则，但时间间隔不固定，是ZGC自行算出来的时机，我们的服务因为已经加了基于固定时间间隔的触发机制，所以通过-ZProactive参数将该功能关闭，以免GC频繁，影响服务可用性。

##### ⑤.阻塞内存分配请求触发

当垃圾来不及回收，垃圾将堆占满时，会导致部分线程阻塞。我们应当避免出现这种触发方式。日志中关键字是“Allocation Stall”。 

##### ⑥.外部触发

代码中显式调用System.gc()触发。 日志中关键字是“System.gc()”。

##### ⑦.元数据分配触发

元数据区不足时导致，一般不需要关注。 日志中关键字是“Metadata GC Threshold”。 

### 9.ZGC参数设置

ZGC 优势不仅在于其超低的 STW 停顿，也在于其参数的简单，绝大部分生产场景都可以自适应。当然在极端情况下，还是有可能需要对 ZGC 个别参数做个调整，大致可以分为三类： 

+ **堆大小：**Xmx。当分配速率过高，超过回收速率，造成堆内存不够时，会触发 Allocation Stall，这类 Stall 会减缓当前的用户线程。因此，当我们在 GC 日志中看到 Allocation Stall，通常可以认为堆空间偏小或者 concurrent gc threads 数偏小。 

+ **GC 触发时机：**ZAllocationSpikeTolerance, ZCollectionInterval。
  + ZAllocationSpikeTolerance：用来估算当前的堆内存分配速率，在当前剩余的堆内存下，ZAllocationSpikeTolerance 越大，估算的达到OOM 的时间越快，ZGC 就会更早地进行触发 GC。
  + ZCollectionInterval：用来指定 GC 发生的间隔，以秒为单位触发 GC。 

+ **GC 线程：**ParallelGCThreads， ConcGCThreads。
  + ParallelGCThreads：设置 STW 任务的 GC 线 程数目，默认为 CPU 个数的 60%；
  + ConcGCThreads：并发阶段 GC 线程的数目，默认为 CPU 个数的 12.5%。增加 GC 线程数目，可以加快 GC 完成任务，减少各个阶段的时间，但也会增加 CPU 的抢占开销，可根据生产情况调整。 

由上可以看出 ZGC 需要调整的参数十分简单，通常设置 Xmx 即可满足业务的需求，大大减轻 Java 开发者的负担。

### 10.**ZGC典型应用场景** 

对于性能来说，不同的配置对性能的影响是不同的，如充足的内存下即大堆场景，ZGC 在各类 Benchmark 中 能够超过 G1 大约 5% 到 20%，而在小堆情况下，则要低于 G1 大约 10%；不同的配置对于应用的影响不尽相同，开发者需要根据使用场景来合理判断。 

<font color='red'>当前 ZGC 不支持压缩指针和分代 GC</font>，其内存占用相对于 G1 来说要稍大，在小堆情况下较为明显，而在大堆情况下，这些多占用的内存则显得不那么突出。**因此，以下两类应用强烈建议使用 ZGC 来提升业务体验：** 

+ **超大堆应用**。超大堆（百 G 以上）下，CMS 或者 G1 如果发生 Full GC，停顿会在分钟级别，可能会造成业务的终端，强烈推荐使用 ZGC。 

+ **当业务应用需要提供高服务级别协议**（Service Level Agreement，SLA），例如 99.99% 的响应时间不能超过 100ms，此类应用无论堆大小，均推荐采用低停顿的 ZGC。 

### 11.**ZGC生产注意事项** 

+ **RSS 内存异常现象** 

由前面 ZGC 原理可知，ZGC 采用多映射 multi-mapping 的方法实现了三份虚拟内存指向同一份物理内存。而Linux 统计进程 RSS 内存占用的算法是比较脆弱的，这种多映射的方式并没有考虑完整，因此根据当前 Linux 采用大页和小页时，其统计的开启 ZGC 的 Java 进程的内存表现是不同的。

在内核使用小页的 Linux 版本上，这种三映射的同一块物理内存会被 linux 的 RSS 占用算法统计 3 次，因此通常可以看到使用 ZGC 的 Java 进程的 RSS 内存膨胀了三倍左右，但是实际占用只有统计数据的三分之一，会对运维或者其他业务造成一定的困扰。而在内核使用大页的 Linux 版本上，这部分三映射的物理内存则会统计到 hugetlbfs inode 上，而不是当前 Java 进程上。 

+ **共享内存调整** 

ZGC 需要在 share memory 中建立一个内存文件来作为实际物理内存占用，因此当要使用的 Java 的堆大小大于 /dev/shm 的大小时，需要对 /dev/shm 的大小进行调整。通常来说，命令如下（下面是将 /dev/shm 调整为 64G）： 

```
vi/etc/fstabtmpfs /dev/shm tmpfs defaults,size= 65536M00 
```

首先修改 fstab 中 shm 配置的大小，size 的值根据需求进行修改，然后再进行 shm 的 mount 和 umount。 

```
umount/dev/shmmount /dev/shm 
```

+ **mmap 节点上限调整**

ZGC 的堆申请和传统的 GC 有所不同，需要占用的 memory mapping 数目更多，即每个 ZPage 需要 mmap 映射三次，这样系统中仅 Java Heap 所占用的 mmap 个数为 (Xmx / zpage_size) * 3，默认情况下zpage_size 的大小为 2M。 

为了给 JNI 等 native 模块中的 mmap 映射数目留出空间，内存映射的数目应该调整为 (Xmx / zpage_size) 3*1.2。 

默认的系统 memory mapping 数目由文件 /proc/sys/vm/max_map_count 指定，通常数目为 65536，当给JVM 配置一个很大的堆时，需要调整该文件的配置，使得其大于 (Xmx / zpage_size) 3*1.2。 

+ **ZGC存在的问题及持续改进** 

目前ZGC历代版本中存在的一些问题（阿里、腾讯、美团、华为等大厂在支持业务切换 ZGC 的出现的），基本上都已经将遇到的相关问题和修复积极向社区报告和回馈，很多问题在JDK16和JDK17已经修复完善。另外的话，问题相对来说不是非常严重，如果遇到类似的问题可以查看下JVM团队的历代修复日志，尽量使用比较新的版本来上线，以免重复掉坑里面。