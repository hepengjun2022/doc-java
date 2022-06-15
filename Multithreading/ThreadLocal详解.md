# 一、ThreadLocal简介

ThreadLocal叫做**线程变量**，意思是ThreadLocal中填充的变量属于**当前线程**，该变量对其他线程而言是隔离的，也就是说该变量是当前线程独有的变量。ThreadLocal为变量在每个线程中都创建了一个副本，那么每个线程可以访问自己内部的副本变量。

ThreadLoal 变量，线程局部变量，同一个 ThreadLocal 所包含的对象，在不同的 Thread 中有不同的副本。这里有几点需要注意：

- 因为每个 Thread 内有自己的实例副本，*且该副本只能由当前 Thread 使用*。这是也是 ThreadLocal 命名的由来。
- 既然每个 Thread 有自己的实例副本，且其它 Thread 不可访问，那就*不存在多线程间共享的问题*。

ThreadLocal 提供了线程本地的实例。它与普通变量的区别在于，每个使用该变量的线程都会初始化一个完全独立的实例副本。ThreadLocal 变量通常被private static修饰。当一个线程结束时，它所使用的所有 ThreadLocal 相对的实例副本都可被回收。

总的来说，ThreadLocal 适用于每个线程需要自己独立的实例且该实例需要在多个方法中被使用，也即变量在线程间隔离而在方法或类间共享的场景

下图可以增强理解：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ThreadLocal-%E5%8E%9F%E7%90%86.png?raw=true)

# 二、ThreadLocal与Synchronized区别

ThreadLocal 其实是与线程绑定的一个变量。ThreadLocal和Synchonized都用于解决多线程并发访问。

但是ThreadLocal与synchronized有本质的区别：

+ Synchronized用于线程间的数据共享，而ThreadLocal则用于线程间的数据隔离。

+ Synchronized是利用锁的机制，使变量或代码块在某一时该只能被一个线程访问。而ThreadLocal为每一个线程都提供了变量的副本，使得每个线程在某一时间访问到的并不是同一个对象，这样就隔离了多个线程对数据的数据共享。而Synchronized却正好相反，它用于在多个线程间通信时能够获得数据共享。

  **一句话理解ThreadLocal:**

  threadlocl是作为当前线程中属性ThreadLocalMap集合中的某一个Map的key值Map（threadlocl,value），虽然不同的线程之间threadlocal这个key值是一样，但是不同的线程所拥有的ThreadLocalMap是独一无二的，也就是不同的线程间同一个ThreadLocal（key）对应存储的值(value)不一样，从而到达了线程间变量隔离的目的，但是同一个线程中这个变量value是一样的。

# 三、TreadLocal的简单使用

```java
public class ThreadLocaDemo {
 
    private static ThreadLocal<String> localVar = new ThreadLocal<String>();
 
    static void print(String str) {
        //打印当前线程中本地内存中本地变量的值
        System.out.println(str + " :" + localVar.get());
        //清除本地内存中的本地变量
        localVar.remove();
    }
    public static void main(String[] args) throws InterruptedException {
 
        new Thread(new Runnable() {
            public void run() {
                ThreadLocaDemo.localVar.set("local_A");
                print("A");
                //打印本地变量
                System.out.println("after remove : " + localVar.get());
               
            }
        },"A").start();
 
        Thread.sleep(1000);
 
        new Thread(new Runnable() {
            public void run() {
                ThreadLocaDemo.localVar.set("local_B");
                print("B");
                System.out.println("after remove : " + localVar.get());
              
            }
        },"B").start();
    }
}
```

结果：

```java
A :local_A
after remove : null
B :local_B
after remove : null
```

从这个示例中我们可以看到，两个线程分表获取了自己线程存放的变量，他们之间变量的获取并不会错乱。这个的理解也可以结合图1-1，相信会有一个更深刻的理解。

# 四、ThreadLocal的原理

## 4.1 ThreadLocal的set()方法：

```java
 public void set(T value) {
        //1.获取当前线程
        Thread t = Thread.currentThread();
        //2.尝试获取ThreadLocalMap，如果为空则进行创建初始化
        //  如果不为空则直接更新保存变量值
        ThreadLocalMap map = getMap(t);
        if (map != null)
            map.set(this, value);
        else
            //初始化threadMap并赋值
            createMap(t, value);
 }
```

 从上面的代码可以看出，ThreadLocal  set赋值的时候首先会获取当前线程thread,并获取thread线程中的ThreadLocalMap属性。如果map属性不为空，则直接更新value值，如果map为空，则实例化threadLocalMap,并将value值初始化。

```java
public class ThreadLocal<T> {
    ...
    static class ThreadLocalMap {

        static class Entry extends WeakReference<ThreadLocal<?>> {
            /** The value associated with this ThreadLocal. */
            Object value;

            Entry(ThreadLocal<?> k, Object v) {
                super(k);
                value = v;
            }
        }
    }
    ....
}
```

 可看出ThreadLocalMap是ThreadLocal的内部静态类，而它的构成主要是用Entry来保存数据 ，而且还是继承的弱引用。在Entry内部使用ThreadLocal作为key，使用我们设置的value作为value。详细内容要大家自己去跟。

```java
//threadLocal的内部方法
void createMap(Thread t, T firstValue) {
    t.inheritableThreadLocals = new ThreadLocalMap(this, firstValue);
}

```

```java
//threadPool的构造方法
ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
    table = new Entry[INITIAL_CAPACITY];
    int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
    table[i] = new Entry(firstKey, firstValue);
    size = 1;
    setThreshold(INITIAL_CAPACITY);
}
```

##  4.2 ThreadLocal的get方法

```java
public T get() {
    //1.获取当前线程
    Thread t = Thread.currentThread();
    //2.获取当前线程的ThreadLocalMap
    ThreadLocalMap map = getMap(t);
    //3.判断map是否为空
    if (map != null) {
        //3.1不为空则从threadLocalMap中取出值。
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    //3.2 为空，则进行初始化，初始化结果：key为threadlocal，值为null
    return setInitialValue();
}
```

## 4.3 ThreadLocal的remove方法

```java
public void remove() {
     //1.传入当前线程，获取当前线程的threadlocalMap
     ThreadLocalMap m = getMap(Thread.currentThread());
     if (m != null)
     m.remove(this);
}
```

<font color='red'>remove方法直接将ThrealLocal 对应的值从当前相差Thread中的ThreadLocalMap中删除。为什么要删除，这涉及到内存泄露的问题</font>

+ 实际上 ThreadLocalMap 中使用的 key 为 ThreadLocal 的弱引用，弱引用的特点是，如果这个对象只存在弱引用，那么在下一次垃圾回收的时候必然会被清理掉。

+ 所以如果 ThreadLocal 没有被外部强引用的情况下，在垃圾回收的时候会被清理掉的，这样一来 ThreadLocalMap中使用这个 ThreadLocal 的 key 也会被清理掉。但是，value 是强引用，不会被清理，这样一来就会出现 key 为 null 的 value。

+ ThreadLocal其实是与线程绑定的一个变量，如此就会出现一个问题：如果没有将ThreadLocal内的变量删除（remove）或替换，它的生命周期将会与线程共存。通常线程池中对线程管理都是采用线程复用的方法，在线程池中线程很难结束甚至于永远不会结束，这将意味着线程持续的时间将不可预测，甚至与JVM的生命周期一致。举个例字，如果ThreadLocal中直接或间接包装了集合类或复杂对象，每次在同一个ThreadLocal中取出对象后，再对内容做操作，那么内部的集合类和复杂对象所占用的空间可能会开始持续膨胀。

## 4.4、ThreadLocal与Thread，ThreadLocalMap之间的关系 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ThreadLocal-%E5%85%B3%E7%B3%BB01.png?raw=true)

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/ThreadLocal-%E5%85%B3%E7%B3%BB02.png?raw=true)

图4-1 Thread、THreadLocal、ThreadLocalMap之间啊的数据关系图

从这个图中我们可以非常直观的看出，ThreadLocalMap其实是Thread线程的一个属性值，而ThreadLocal是维护ThreadLocalMap

这个属性指的一个工具类。<font color='red'>Thread线程可以拥有多个ThreadLocal维护的自己线程独享的共享变量</font>（这个共享变量只是针对自己线程里面共享）

# 五、ThreadLocal 常见使用场景

如上文所述，ThreadLocal 适用于如下两种场景

+ <font color='red'>每个线程需要有自己单独的实例</font>
+ <font color='red'>实例需要在多个方法中共享，但不希望被多线程共享</font>

对于第一点，每个线程拥有自己实例，实现它的方式很多。例如可以在线程内部构建一个单独的实例。ThreadLoca 可以以非常方便的形式满足该需求。

对于第二点，可以在满足第一点（每个线程有自己的实例）的条件下，通过方法间引用传递的形式实现。ThreadLocal 使得代码耦合度更低，且实现更优雅。

**场景：**

场景一：存储用户Session

一个简单的用ThreadLocal来存储Session的例子：

```java
private static final ThreadLocal threadSession = new ThreadLocal();
 
    public static Session getSession() throws InfrastructureException {
        Session s = (Session) threadSession.get();
        try {
            if (s == null) {
                s = getSessionFactory().openSession();
                threadSession.set(s);
            }
        } catch (HibernateException ex) {
            throw new InfrastructureException(ex);
        }
        return s;
    }
}
```

场景二：数据库连接，处理数据库事务

场景三：数据跨层传递（controller,service, dao）

 每个线程内需要保存类似于全局变量的信息（例如在拦截器中获取的用户信息），可以让不同方法直接使用，避免参数传递的麻烦却不想被多线程共享（因为不同线程获取到的用户信息不一样）。

例如，用 ThreadLocal 保存一些业务内容（用户权限信息、从用户系统获取到的用户名、用户ID 等），这些信息在同一个线程内相同，但是不同的线程使用的业务内容是不相同的。

在线程生命周期内，都通过这个静态 ThreadLocal 实例的 get() 方法取得自己 set 过的那个对象，避免了将这个对象（如 user 对象）作为参数传递的麻烦。

比如说我们是一个用户系统，那么当一个请求进来的时候，一个线程会负责执行这个请求，然后这个请求就会依次调用service-1()、service-2()、service-3()、service-4()，这4个方法可能是分布在不同的类中的。

这个例子和存储session有些像。

```java
package com.kong.threadlocal;
 
public class ThreadLocalDemo05 {
    public static void main(String[] args) {
        User user = new User("jack");
        new Service1().service1(user);
    }
 
}
class Service1 {
    public void service1(User user){
        //给ThreadLocal赋值，后续的服务直接通过ThreadLocal获取就行了。
        UserContextHolder.holder.set(user);
        new Service2().service2();
    }
}
class Service2 {
    public void service2(){
        User user = UserContextHolder.holder.get();
        System.out.println("service2拿到的用户:"+user.name);
        new Service3().service3();
    }
}
class Service3 {
    public void service3(){
        User user = UserContextHolder.holder.get();
        System.out.println("service3拿到的用户:"+user.name);
        //在整个流程执行完毕后，一定要执行remove
        UserContextHolder.holder.remove();
    }
}
class UserContextHolder {
    //创建ThreadLocal保存User对象
    public static ThreadLocal<User> holder = new ThreadLocal<>();
}
class User {
    String name;
    public User(String name){
        this.name = name;
    }
}

执行的结果：
service2拿到的用户:jack
service3拿到的用户:jack
```

场景四：Spring使用ThreadLocal解决线程安全问题 

我们知道在一般情况下，只有无状态的Bean才可以在多线程环境下共享，在Spring中，绝大部分Bean都可以声明为singleton作用域。就是因为Spring对一些Bean（如RequestContextHolder、TransactionSynchronizationManager、LocaleContextHolder等）中非线程安全的“状态性对象”采用ThreadLocal进行封装，让它们也成为线程安全的“状态性对象”，因此有状态的Bean就能够以singleton的方式在多线程中正常工作了。 

一般的Web应用划分为展现层、服务层和持久层三个层次，在不同的层中编写对应的逻辑，下层通过接口向上层开放功能调用。在一般情况下，从接收请求到返回响应所经过的所有程序调用都同属于一个线程，如图9-2所示。 





原文链接：https://blog.csdn.net/u010445301/article/details/111322569