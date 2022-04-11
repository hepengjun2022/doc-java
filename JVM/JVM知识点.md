# JVM

## 一、JVM概述

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JVM%E6%A6%82%E8%BF%B0.png?raw=true)

### Ⅰ .概述：

JVM（Java Virtual Machine）也就是我们所说的java虚拟机，它是一个虚构出来的计算机，是通过在实际的计算机上仿真模拟各种计算机功能来实现的。它的作用主要是把java类通过编译变成class的二进制文件，然后在jvm虚拟机里面去加载运行。

### Ⅱ.主要功能：

- 通过ClassLoader寻找和装载class文件。
- 解释字节码成为指令并执行，提供class文件的运行环境。
- 进行运行期间的内存分配和垃圾回收。
- 提供与硬件交互的平台。

----

## 二、JVM虚拟机组成

### Ⅰ.类加载子系统

### Ⅱ.字节码执行引擎

（JVM内存模型/结构）

### Ⅲ.运行时数据区

#### **1.Java堆**

（Heap）

线程共享，是java虚拟机管理内存最大的一块，此内存区域主要是存储一些对象引用实例。

- 新生代用来存放新分配的对象；新生代中经过垃圾回收，没有回收掉的对象，被复制到老年代
- 老年代存储对象比新生代存储对象的年龄大得多
- 老年代存储一些大对象
- 整个堆大小 = 新生代 + 老年龄
- 新生代 = Eden + 存活区
- 从前的持久代，用来存放Class、Method 等元信息的区域，从 JDK8 开始去掉了，取而代之的是元空间（MetaSpace），元空间并不在虚拟机里面，而是直接使用本地内存。

#### **2.方法区**

(Method Area)

- 线程共享
- 主要存储已经被虚拟机加载的类信息、常量、静态变量、以及编译器编译后的代码等数据。

**注意：**

+ Java7，将常量池是存放到了堆中。

+ Java8之后，取消了整个永久代区域，取而代之的是元空间。**运行时常量池和静态常量池存放在元空间中，而字符串常量池依然存放在堆中。**

#### **3.程序计数器**

(Program Counter Register)

- 线程私有
- 只占有一小块内存空间，它主要的作用是标记当前线程所执行的字节码文件的行号。

#### **4.线程栈**

（JVM Stacks）

​    ![0](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E7%BA%BF%E7%A8%8B%E6%A0%88%E7%BB%93%E6%9E%84.png?raw=true)

##### **①线程栈的作用：**

线程私有，其生命周期跟线程周期相同。

主要是虚拟机栈描述Java方法执行的内存模型，在方法被调用执行的时候，虚拟机栈会同时

给该方法创建一个栈帧（Stack Frame）用于存储局部变量表、操作数栈、动态链接、方法出

口等信息并且做入栈操作。

该方法被调用执行完毕，对应的栈帧在虚拟机栈里就会做出栈操作。

##### **②.栈帧构成：**

- 局部变量表：主要是记录该方法的局部变量
- 操作数栈：记录局部变量的值，然后进行压栈操作
- 动态链接：
  1.  每个栈帧都保存了一个可以指向该方法所在类的运行常量池的地址。
  2. 当前方法中如果需要调用其他方法的时候, 能够从运行时常量池中找到对应的符号引用。
  3. 然后将符号引用转换为直接引用,然后就能直接调用对应方法, 这就是动态链接。

- 方法出口：记录方法被调用的地方，并进行返回

#### **5.本地方法栈**

（Native Method Stacks）

线程私有，与虚拟机栈的功能类似，其作用主要是Java虚拟机为本地Native方法提供服务。

----

## 三、类加载过程

### 1.类加载原理：

**类被加载到方法区**后主要包含**运行常量池**、**类型信息**、**字段信息**、**方法信息**、**类加载器的引用**、**对应class实例的引用**等信息。

类加载器的引用：这个类到类加载器实例的引用。

对应class实例的引用：类加载器在加载类信息放在方法区后，会创建一个对象的class类型的对象实例放在堆（Heap）中，

这样，作为开发人员我们只需要访问方法区中类定义的入口和切入点即可。

### 2. 类加载过程：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E7%B1%BB%E5%8A%A0%E8%BD%BD%E8%BF%87%E7%A8%8B.png?raw=true)

​						**链接** 

**加载 >> （验证 >> 准备 >>  解析）>> 初始化 >> 使用 >> 卸载**

+ 加载：在硬盘上找到需要加载类的class文件，然后通过IO读入字节码文件并在堆内存生成java.lang.Class对象作为访问方法区数据结构的入口。
+ 验证：校验字节码文件。
  1. 文件格式：验证二进制文件是什么类型，是否符合当前JVM规范。（例如JVM字节码文件都以cafebabe开头）
  2. 元数据校验：
     + 检查类是否有父类、接口。验证其父类、接口的合法性。
     + 检查是否被final修饰
     + 检查是否为抽象类，是否实现了父类的抽象方法或者接口中的方法。
     + 验证方法重载等等。
  3. 字节码验证：主要验证程序的控制流程比如循环、分支等。
  4. 符号验证：主要验证符号引用转化为直接引用时的合法性。
+ 准备：对类的静态变量进行初始化和内存空间分配。

| 序号 | 数据类型       | 大小/位 | 封装类值  | 默认值         | 可表示数据范围                           |
| ---- | -------------- | ------- | --------- | -------------- | ---------------------------------------- |
| 1    | byte(位)       | 8       | Byte      | 0              | -128~127                                 |
| 2    | short(短整数)  | 16      | Short     | 0              | -32768~32767                             |
| 3    | int(整数)      | 32      | Integer   | 0              | -2147483648~2147483647                   |
| 4    | long(长整数)   | 64      | Long      | 0L             | -9223372036854775808~9223372036854775807 |
| 5    | float(单精度)  | 32      | Float     | 0.0f           | 1.4E-45~3.4028235E38                     |
| 6    | double(双精度) | 64      | Double    | 0.0            | 4.9E-324~1.7976931348623157E308          |
| 7    | char(字符)     | 16      | Character | '/uoooo'(null) | 0~65535                                  |
| 8    | boolean        | 8       | Boolean   | flase          | true或false                              |

+ 解析：将符号引用替换成直接引用，该阶段会把一些静态方法（符号引用，比如main()方法）替换成指向数据所在内存的指针或者是句柄等（直接引用），这也是所谓的静态链接过程（类加载期间完成，动态链接实在程序运行时完成）。
+ 初始化：对类的静态变量初始化为指定的值，并执行静态代码块。

### 3.JVM中类加载全过程

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JVM%E4%B8%AD%E7%B1%BB%E5%8A%A0%E8%BD%BD%E5%85%A8%E8%BF%87%E7%A8%8B.png?raw=true)

----

## 四、类加载器

### Ⅰ .类加载器分类

#### 1.引导类加载器

负责加载支撑JVM运行位于JRE的lib目录下的核心类库。比如rt.jar、charsets.jar等。

```
bootstrapLoader加载以下文件：
file:/C:/Program%20Files/Java/jdk1.8.0_91/jre/lib/resources.jar
file:/C:/Program%20Files/Java/jdk1.8.0_91/jre/lib/rt.jar
file:/C:/Program%20Files/Java/jdk1.8.0_91/jre/lib/sunrsasign.jar
file:/C:/Program%20Files/Java/jdk1.8.0_91/jre/lib/jsse.jar
file:/C:/Program%20Files/Java/jdk1.8.0_91/jre/lib/jce.jar
file:/C:/Program%20Files/Java/jdk1.8.0_91/jre/lib/charsets.jar
file:/C:/Program%20Files/Java/jdk1.8.0_91/jre/lib/jfr.jar
```

#### 2.扩展类加载器

负责加载支撑JVM运行位于JRE的lib目录下的核心类库。

```
C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext;
C:\Windows\Sun\Java\lib\ext
```

#### 3.应用程序类加载器

负责加载ClassPath路径下的jar包，主要就是加载自己写的类。

```
C:\Program Files\Java\jdk1.8.0_91\jre\lib\charsets.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\deploy.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\access-bridge-64.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\cldrdata.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\dnsns.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\jaccess.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\jfxrt.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\localedata.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\nashorn.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\sunec.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\sunjce_provider.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\sunmscapi.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\sunpkcs11.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext\zipfs.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\javaws.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\jce.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\jfr.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\jfxswt.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\jsse.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\management-agent.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\plugin.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\resources.jar;C:\Program Files\Java\jdk1.8.0_91\jre\lib\rt.jar;
D:\ideaProject\jvmtest\target\classes;
D:\MavenRepository\org\springframework\boot\spring-boot-starter-web\2.1.4.RELEASE\spring-boot-starter-web-2.1.4.RELEASE.jar;
D:\MavenRepository\org\springframework\boot\spring-boot-starter\2.1.4.RELEASE\spring-boot-starter-2.1.4.RELEASE.jar;
D:\MavenRepository\org\springframework\boot\spring-boot\2.1.4.RELEASE\spring-boot-2.1.4.RELEASE.jar;
D:\MavenRepository\org\springframework\boot\spring-boot-autoconfigure\2.1.4.RELEASE\spring-boot-autoconfigure-2.1.4.RELEASE.jar;
D:\MavenRepository\org\springframework\boot\spring-boot-starter-logging\2.1.4.RELEASE\spring-boot-starter-logging-2.1.4.RELEASE.jar;D:\MavenRepository\ch\qos\logback\logback-classic\1.2.3\logback-classic-1.2.3.jar;
D:\MavenRepository\ch\qos\logback\logback-core\1.2.3\logback-core-1.2.3.jar;
D:\MavenRepository\org\slf4j\slf4j-api\1.7.26\slf4j-api-1.7.26.jar;
D:\MavenRepository\org\apache\logging\log4j\log4j-to-slf4j\2.11.2\log4j-to-slf4j-2.11.2.jar;
。。。。。
D:\MavenRepository\org\springframework\spring-context\5.1.6.RELEASE\spring-context-5.1.6.RELEASE.jar;
D:\MavenRepository\org\springframework\spring-expression\5.1.6.RELEASE\spring-expression-5.1.6.RELEASE.jar;
C:\Program Files\JetBrains\IntelliJ IDEA 2019.1.3\lib\idea_rt.jar
```

#### 4.自定义类加载

负责加载用户自定义路径下的类包。

### Ⅱ.类加载机制

#### 1.双亲委派机制



![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%8F%8C%E4%BA%B2%E5%A7%94%E6%B4%BE%E6%9C%BA%E5%88%B6.png?raw=true)

##### ①.加载步骤：

1. 应用程序类加载器首先去加载，检查目标类是否已经被加载过，如果没找到就委托给父加载器，有就返回。

2. 扩展类加载器去加载，检查是否已经被类加载器加载过，没有则会委托给顶层加载器，有就返回。

3. 顶层加载器检查是否已经被类加载器加载过：
   + 有，直接返回。
   + 没有，再去自己的类加载路径去寻找：
     + 有，加载。
     + 没有，委派给下层加载器。

4. 扩展类加载再去自己的类加载路径去找，如果没找到增委派给下层加载器。

5. 应用类加载器再去自己的类加载路径去找，就抛出异常。

##### ②.类加载源码解析

**类加载器初始：**

getSystemClassLoader()方法获取类加载器：

```
public static ClassLoader getSystemClassLoader() {
    //初始化类加载器方法：
    initSystemClassLoader();
    if (scl == null) {
        return null;
    }
    SecurityManager sm = System.getSecurityManager();
    if (sm != null) {
        checkClassLoaderPermission(scl, Reflection.getCallerClass());
    }
    return scl;
}
```

initSystemClassLoader()方法：

```
private static synchronized void initSystemClassLoader() {
    if (!sclSet) {
        if (scl != null)
            throw new IllegalStateException("recursive invocation");
        //在这里获取类加载器
        sun.misc.Launcher l = sun.misc.Launcher.getLauncher();
        if (l != null) {
            Throwable oops = null;
            scl = l.getClassLoader();
            try {
                scl = AccessController.doPrivileged(
                    new SystemClassLoaderAction(scl));
            } catch (PrivilegedActionException pae) {
                oops = pae.getCause();
                if (oops instanceof InvocationTargetException) {
                    oops = oops.getCause();
                }
            }
            if (oops != null) {
                if (oops instanceof Error) {
                    throw (Error) oops;
                } else {
                    // wrap the exception
                    throw new Error(oops);
                }
            }
        }
        sclSet = true;
    }
}
```

Launcher类：

```
private static Launcher launcher = new Launcher();
private ClassLoader loader;
public static Launcher getLauncher() {
    return launcher;
}
//Launcher的构造方法（在这里指定了）
public Launcher() {
    Launcher.ExtClassLoader var1;
    try {
        //构造扩展类加载器，在构造的过程中将其父加载器设置为null
        var1 = Launcher.ExtClassLoader.getExtClassLoader();
    } catch (IOException var10) {
        throw new InternalError("Could not create extension class loader", var10);
    }

    try {
        //构造应用类加载器，在构造的过程中将其父加载器设置为ExtClassLoader，
        //Launcher的loader属性值是AppClassLoader，我们一般都是用这个类加载器来加载我们自己写的应用程序
        this.loader = Launcher.AppClassLoader.getAppClassLoader(var1);
        //getAppClassLoader(var1);主要是传入ExtClassLoader,将其绑定为AppClassLoader的父加载器
        //同时this.loader赋值，这样通过getClassLoader()方法获取到的就是AppClassLoader。
        //ClassLoader classLoader=ClassLoader.getSystemClassLoader();
    } catch (IOException var9) {
        throw new InternalError("Could not create application class loader", var9);
    }

    Thread.currentThread().setContextClassLoader(this.loader);
    String var2 = System.getProperty("java.security.manager");
     。。。 。。。 //省略一些不需关注代码
}
public ClassLoader getClassLoader() {
    return this.loader;
}
参见类运行加载全过程图可知其中会创建JVM启动器实例sun.misc.Launcher。
sun.misc.Launcher初始化使用了单例模式设计，保证一个JVM虚拟机内只有一个sun.misc.Launcher实例。
在Launcher构造方法内部，其创建了两个类加载器，分别是
sun.misc.Launcher.ExtClassLoader(扩展类加载器)和sun.misc.Launcher.AppClassLoader(应用类加载器)。
JVM默认使用Launcher的getClassLoader()方法返回的类加载器AppClassLoader的实例加载我们的应用程序。
```

**实现双亲委派核心方法loadClass()：**

```
protected Class<?> loadClass(String name, boolean resolve)
    throws ClassNotFoundException{
    synchronized (getClassLoadingLock(name)) {
        // First, check if the class has already been loaded
        //protected final Class<?> findLoadedClass(String name) {
        //  if (!checkName(name))
        //    return null;
        //  return findLoadedClass0(name);
        // }
        //private native final Class<?> findLoadedClass0(String name);底层C++
         //检查当前类加载器是否已经加载了该类
        Class<?> c = findLoadedClass(name);
        if (c == null) {
            long t0 = System.nanoTime();
            try {
                //如果当前加载器父加载器不为空则委托父加载器加载该类
                if (parent != null) {
                    c = parent.loadClass(name, false);
                } else {
                    //如果当前加载器父加载器为空则委托引导类加载器加载该类
                    c = findBootstrapClassOrNull(name);
                }
            } catch (ClassNotFoundException e) {
                // ClassNotFoundException thrown if class not found
                // from the non-null parent class loader
            }
            if (c == null) {
                // If still not found, then invoke findClass in order
                // to find the class.
                long t1 = System.nanoTime();
                //都会调用URLClassLoader的findClass方法在加载器的类路径里查找并加载该类
                c = findClass(name);//这里findClass会调用URLClassLoader的findClass()方法

                // this is the defining class loader; record the stats
                sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                sun.misc.PerfCounter.getFindClasses().increment();
            }
        }
        if (resolve) {
            resolveClass(c);
        }
        return c;
    }
}
```

**ClassLoader的findClass()方法：**

```
public abstract class ClassLoader {
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        throw new ClassNotFoundException(name);
    }
}
```

**URLClassLoader的findClass()方法：**

```
public class URLClassLoader extends SecureClassLoader implements Closeable {
    protected Class<?> findClass(final String name)throws ClassNotFoundException{
        final Class<?> result;
        try {
            result = AccessController.doPrivileged(
                new PrivilegedExceptionAction<Class<?>>() {
                    public Class<?> run() throws ClassNotFoundException {
                        //将传入的类名进行处理，获取类路径
                        String path = name.replace('.', '/').concat(".class");
                        //通过类路径获取到文件位置。
                        Resource res = ucp.getResource(path, false);
                        //文件不为空返回class文件
                        if (res != null) {
                            try {
                                return defineClass(name, res);
                            } catch (IOException e) {
                                throw new ClassNotFoundException(name, e);
                            }
                        } else {//为空返回null
                            return null;
                        }
                    }
                }, acc);
        } catch (java.security.PrivilegedActionException pae) {
            throw (ClassNotFoundException) pae.getException();
        }
        if (result == null) {
            throw new ClassNotFoundException(name);
        }
    	return result;
	}
}
```

##### ③.双亲委派机制好处

为什么设计双亲委派机制？

- 沙箱安全机制：防止核心API库被随意篡改。（比如自己写的java.lang.String.class类不会被加载）
- 避免重复被加载：当父加载器已经加载过该类时，子加载器就没必要加载了，保证加载类的唯一性。

##### ④.补充

主类在运行过程中如果使用到其它类，会逐步加载这些类。jar包或war包里的类不是一次性全部加载的，是使用到时才加载。

```
public class TestDynamicLoad {
    static {
        System.out.println("*************load TestDynamicLoad************");
    }
    public static void main(String[] args) {
        new A();
        System.out.println("*************load test************");
        B b = null; //B不会加载，除非这里执行B b=new B();
    }
}
class A {
    static {
        System.out.println("*************load A************");
}
    public A() {
        System.out.println("*************initial A************");
    }
}
class B {
    static {
        System.out.println("*************load B************");
    }
    public B() {
        System.out.println("*************initial B************");
    }
}
结果：
*************load TestDynamicLoad************
*************load A************
*************initial A************
*************load test************
```

----

#### 2.全盘委托机制

“全盘负责”是指当一个ClassLoder装载一个类时，除非显示的使用另外一个ClassLoder，该类 所依赖及引用的类也由这个ClassLoder载入。

#### 3.总结

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E7%B1%BB%E5%8A%A0%E8%BD%BD%E6%9C%BA%E5%88%B6%E6%80%BB%E7%BB%93.png?raw=true)

## 五、对象内存回收：

堆中几乎放着所有的对象实例，对堆垃圾回收前的第一步就是要判断哪些对象已经死亡（即不能再被任何途径使用的对象）。

**判断对象是否死亡：**

##### **Ⅰ .引用计数法：**

给对象添加一个引用计数器，有访问加1，引用失效减1

- 给对象添加一个引用计数器，有访问加1，引用失效减1

  - 优点：简单，效率高

  - 缺点：不能解决对象相互循环引用的问题，计数器都不为0，无法通知GC回收器 进行回收。

    ```
    public class ReferenceCountingGc { 
        Object instance = null;
        public static void main(String[] args) { 
            ReferenceCountingGc objA = new ReferenceCountingGc(); 
            ReferenceCountingGc objB = new ReferenceCountingGc(); 
            objA.instance = objB; 
            objB.instance = objA; 
            objA = null; 
            objB = null; 
        } 
    } 
    ```

##### **Ⅱ.根搜索算法（可达性算法）**

​    ![0](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%8F%AF%E8%BE%BE%E6%80%A7%E7%AE%97%E6%B3%95.png?raw=true)

从根节点向下遍历搜索引用的对象节点，搜索走过的路径称为引用链，如果一个对象到根没有连通的话，则会认为这个对象为不可达。                  

**常见的引用类型：(扩展)**

java的引用类型一般分为四种：强引用、弱引用、软引用、虚引用

- **强引用**：普通的变量引用

```
public static User user = new User(); 
```

- **软引用**：将对象用SoftReference软引用类型的对象包裹，正常情况不会被回收，只有当GC做完发现释放不出空间来存放新的对象的时候，则会把这些软引用的对象进行回收。**软引用可用来实现内存敏感的高速缓存。**

```
public static SoftReference<User> user = new SoftReference<User>(new User()); 
```

- **弱引用**：将对象用WeakReference弱引用类型的对象包裹，弱引用跟没引用差不多，GC会直接进行回收。

```
public static WeakReference<User> user = new WeakReference<User>(new User());
```

- **虚引用：**对象用ReferenceQueue弱引用类型的对象包裹，虚引用主要用来跟踪对象被垃圾回收器回收的活动。

```
public static ReferenceQueue<User> user = new ReferenceQueue<User>(new User());
```

软引用在实际中有重要的应用，例如浏览器的后退按钮。按后退时，这个后退时显示的网页内容是重新进行请求还是从缓存中取出呢？这就要看具体的实现策略了。 

（1）如果一个网页在浏览结束时就进行内容的回收，则按后退查看前面浏览过的页面时，需要重新构建 

（2）如果将浏览过的网页存储到内存中会造成内存的大量浪费，甚至会造成内存溢出 。

----

## 六、对象创建流程：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AF%B9%E8%B1%A1%E5%88%9B%E5%BB%BA%E6%B5%81%E7%A8%8B%E5%9B%BE.png?raw=true)

### **1.类加载检查**

虚拟机遇到一条new指令时，首先将去检查这个指令的参数是否能在常量池中定位到一个类的符号引用，并且检查这个符号引用代表的类是否已被加载、解析和初始化过。如果没有，那必须先执行相应的类加载过程。 new指令对应到语言层面上讲是，new关键词、对象克隆、对象序列化等。

### **2.分配内存**

在类加载检查通过后，接下来虚拟机将为新生对象分配内存。对象所需内存的大小在类加载完成后便可完全确定，为对象分配空间的任务等同于把一块确定大小的内存从Java堆中划分出来。 

**分配内存需要考虑两个问题**： 

1.如何划分内存。 

2.在并发情况下，可能出现正在给对象A分配内存，指针还没来得及修改，对象B又同时使用了原来的指针来分配内存的情况。

**划分内存的方法**： 

- **“指针碰撞”（Bump the Pointer）**(默认用指针碰撞) ：

如果Java堆中内存是绝对规整的，所有用过的内存都放在一边，空闲的内存放在另一边，中间放着一个指针作为分界点的指示器，那所分配内存就仅仅是把那个指针向空闲空间那边挪动一段与对象大小相等的距离，且在并发环境下会出现并发问题。 ·

- **“空闲列表”（Free List）** 

如果Java堆中的内存并不是规整的，已使用的内存和空闲的内存相互交错，那就没有办法简单地进行指针碰撞了，虚拟机就必须维护一个列表，记 录上哪些内存块是可用的，在分配的时候从列表中找到一块足够大的空间划分给对象实例，并更新列表上的记录 。

**解决并发问题的方法：（指针碰撞会出现并发问题，即多个线程抢夺空间）**

- **CAS（compare and swap）** 

虚拟机采用CAS配上失败重试的方式保证更新操作的原子性来对分配内存空间的动作进行同步处理。 

- **本地线程分配缓冲（Thread Local Allocation Buffer,TLAB）**

把内存分配的动作按照线程划分在不同的空间之中进行，即每个线程在Java堆中预先分配一小块内存。通过­XX:+/­UseTLAB参数来设定虚拟机是否使用TLAB(JVM会默认开启­XX:+UseTLAB)，­XX:TLABSize 指定TLAB大小。

### **3.初始化**

内存分配完成后，虚拟机需要将分配到的内存空间都初始化为零值（不包括对象头）， 如果使用TLAB，这一工作过程也可以提前至TLAB分配时进行。这一步操作保证了对象的实例字段在Java代码中可以不赋初始值就直接使用，程序能访问到这些字段的数据类型所对应的零值。

### **4.设置对象头** 

+ 初始化零值之后，虚拟机要对对象进行必要的设置，例如这个对象是哪个类的实例、如何才能找到类的元数据信息、对象的哈希码、对象的GC分代年龄等信息。这些信息存放在对象的对象头Object Header之中。 

+ 在HotSpot虚拟机中，对象在内存中存储的布局可以分为3块区域：对象头（Header）、 实例数据（Instance Data）和对齐填充（Padding）。 

+ HotSpot虚拟机的对象头包括两部分信息，第一部分用于存储对象自身的运行时数据， 如哈希码（HashCode）、GC分代年龄、锁状态标志、线程持有的锁、偏向线程ID、偏向时间戳等。
+ 对象头的另外一部分是类型指针，即对象指向它的类元数据的指针，虚拟机通过这个指针来确定这个对象是哪个类的实例。 

**对象头构成：**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AF%B9%E8%B1%A1%E5%A4%B4%E6%9E%84%E6%88%9001.png?raw=true)

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AF%B9%E8%B1%A1%E5%A4%B4%E6%9E%84%E6%88%9002.png?raw=true)

### **5.执行初始化方法** 

执行init方法，即对象按照程序员的意愿进行初始化。对应到语言层面上讲，就是为属性赋值（注意，这与上面的赋零值不同，这是由程序员赋的值），和执行构造方法。 

### **6.补充:**

**什么是java对象的指针压缩？** 

1. jdk1.6 update14开始，在64bit操作系统中，JVM支持指针压缩。

2. jvm配置参数:UseCompressedOops，compressed­­压缩、oop(ordinary object pointer)­­对象指针。 

3. 启用指针压缩:­XX:+UseCompressedOops(默认开启)，禁止指针压缩:­XX:­UseCompressedOops。 

**为什么要进行指针压缩？** 

1. 在64位平台的HotSpot中使用32位指针，内存使用会多出1.5倍左右，使用较大指针在主内存和缓存之间移动数据， 占用较大宽带，同时GC也会承受较大压力。

2. 为了减少64位平台下内存的消耗，启用指针压缩功能。 

3. 在jvm中，32位地址最大支持4G内存(2的32次方)，可以通过对对象指针的压缩编码、解码方式进行优化，使得jvm 只用32位地址就可以支持更大的内存配置(小于等于32G)。 

4. 堆内存小于4G时，不需要启用指针压缩，jvm会直接去除高32位地址，即使用低虚拟地址空间。 

5. 堆内存大于32G时，压缩指针会失效，会强制使用64位(即8字节)来对java对象寻址，这就会出现1的问题，所以堆内 存不要大于32G为好。

**finalize()方法最终判定对象是否存活：** 

即使在可达性分析算法中不可达的对象，也并非是“非死不可”的，这时候它们暂时处于“缓刑”阶段，要真正宣告一 个对象死亡，至少要经历再次标记过程。 标记的前提是对象在进行可达性分析后发现没有与GC Roots相连接的引用链。 

1. 第一次标记并进行一次筛选。 筛选的条件是此对象是否有必要执行finalize()方法。 当对象没有覆盖finalize方法，对象将直接被回收。 

2. 第二次标记 如果这个对象覆盖了finalize方法，finalize方法是对象脱逃死亡命运的最后一次机会，如果对象要在finalize()中成功拯救 自己，只要重新与引用链上的任何的一个对象建立关联即可，譬如把自己赋值给某个类变量或对象的成员变量，那在第 二次标记时它将移除出“即将回收”的集合。如果对象这时候还没逃脱，那基本上它就真的被回收了。 

   注意：一个对象的finalize()方法只会被执行一次，也就是说通过调用finalize方法自我救命的机会就一次.

**如何判断一个类是无用的类:**

类需要同时满足下面3个条件才能算是 “无用的类” ： 

1. 该类所有的实例都已经被回收，也就是 Java 堆中不存在该类的任何实例。 
2. 加载该类的 ClassLoader 已经被回收。 
3. 该类对应的 java.lang.Class 对象没有在任何地方被引用，无法在任何地方通过反射访问该类的方法。

----

## 七、对象内存分配：

### **Ⅰ.对象栈上分配**

我们通过JVM内存分配可以知道JAVA中的对象都是在堆上进行分配，当对象没有被引用的时候，需要依靠GC进行回收内 存，如果对象数量较多的时候，会给GC带来较大压力，也间接影响了应用的性能。为了减少临时对象在堆内分配的数 量，JVM通过逃逸分析确定该对象不会被外部访问。如果不会逃逸可以将该对象在栈上分配内存，这样该对象所占用的 内存空间就可以随栈帧出栈而销毁，就减轻了垃圾回收的压力。 

对象逃逸分析：就是分析对象动态作用域，当一个对象在方法中被定义后，它可能被外部方法所引用，例如作为调用参数传递到其他地方中。

JVM对于这种情况可以通过开启逃逸分析参数(-XX:+DoEscapeAnalysis)来优化对象内存分配位置，使其通过标量替换优先分配在栈上(栈上分配)。JDK7之后默认开启逃逸分析，如果要关闭使用参数(-XX:-DoEscapeAnalysis) 标量替换：

通过逃逸分析确定该对象不会被外部访问，并且对象可以被进一步分解时，JVM不会创建该对象，而是将该对象成员变量分解若干个被这个方法使用的成员变量所代替，这些代替的成员变量在栈帧或寄存器上分配空间，这样就 不会因为没有一大块连续空间导致对象内存不够分配。

开启标量替换参数(-XX:+EliminateAllocations)，JDK7之后默认开启。 

**标量与聚合量：**

+ 标量即不可被进一步分解的量，而JAVA的基本数据类型就是标量（如：int，long等基本数据类型以及 reference类型等）。

+ 标量的对立就是可以被进一步分解的量，而这种量称之为聚合量，而在JAVA中对象就是可以被进一 步分解的聚合量。

### **Ⅱ.对象在Eden区分配**

大多数情况下，对象在新生代中 Eden 区分配。

当 Eden 区没有足够空间进行分配时，虚拟机将发起一次Minor GC。

Minor GC和Full GC 有什么不同呢？ 

+ Minor GC/Young GC：指发生新生代的的垃圾收集动作，Minor GC非常频繁，回收速度一般也比较快。

+ Major GC/Full GC：一般会回收老年代 ，年轻代，方法区的垃圾，Major GC的速度一般会比Minor GC的慢 10倍以上。 

Eden与Survivor区默认8:1:1 大量的对象被分配在eden区，eden区满了后会触发minor gc，可能会有99%以上的对象成为垃圾被回收掉，剩余存活的对象会被挪到为空的那块survivor区，下一次eden区满了后又会触发minor gc，把eden区和survivor区垃圾对象回收，把剩余存活的对象一次性挪动到另外一块为空的survivor区，因为新生代的对象都是朝生夕死的，存活时间很短，所 以JVM默认的8:1:1的比例是很合适的，让eden区尽量的大，survivor区够用即可。

 JVM默认有这个参数-XX:+UseAdaptiveSizePolicy(默认开启)，会导致这个8:1:1比例自动变化，如果不想这个比例有变 化可以设置参数-XX:-UseAdaptiveSizePolicy

### **Ⅲ.大对象直接进入老年代**

大对象就是需要大量连续内存空间的对象（比如：字符串、数组）。

JVM参数 -XX:PretenureSizeThreshold 可以设置大对象的大小，如果对象超过设置大小会直接进入老年代，不会进入年轻代，这个参数只在 Serial 和ParNew两个收集器下有效。 

设置JVM参数：-XX:PretenureSizeThreshold=1000000 (单位是字节) -XX:+UseSerialGC ，再执行程序会发现大对象直接进了老年代，为什么要这样呢？

+ 为了避免为大对象分配内存时的复制操作而降低效率。

### **Ⅳ.长期存活的对象将进入老年代**

+ 虚拟机采用了分代收集的思想来管理内存，那么内存回收时就必须能识别哪些对象应放在新生代，哪些对象应放在老年代中。

+ 为了做到这一点，虚拟机给每个对象一个对象年龄（Age）计数器。 如果对象在 Eden 出生并经过第一次 Minor GC 后仍然能够存活，并且能被 Survivor 容纳的话，将被移动到 Survivor 空间中，并将对象年龄设为1。

+ 对象在 Survivor 中每熬过一次 MinorGC，年龄就增加1岁，当它的年龄增加到一定程度 （默认为15岁，CMS收集器默认6岁，不同的垃圾收集器会略微有点不同），就会被晋升到老年代中。对象晋升到老年代的年龄阈值，可以通过参数 -XX:MaxTenuringThreshold 来设置。

### **Ⅴ.对象动态年龄判断**

当前放对象的Survivor区域里(其中一块区域，放对象的那块s区)，一批对象的总大小大于这块Survivor区域内存大小的 50%对象的年龄(-XX:TargetSurvivorRatio可以指定)，那么此时大于等于这批对象年龄最大值的对象，就可以直接进入老年代了。

例如Survivor区域里现在有一批对象，年龄1+年龄2+年龄n的多个年龄对象总和超过了Survivor区域的50%对象的年龄，此时就会把年龄n(含)以上的对象都放入老年代。这个规则其实是希望那些可能是长期存活的对象，尽早进入老年代。

对象动态年龄判断机制一般是在minor gc之后触发的。

### **Ⅵ.老年代空间分配担保机制**

年轻代每次minor gc之前JVM都会计算下老年代剩余可用空间。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E8%80%81%E5%B9%B4%E4%BB%A3%E7%A9%BA%E9%97%B4%E5%88%86%E9%85%8D%E6%8B%85%E4%BF%9D%E6%9C%BA%E5%88%B6%E6%B5%81%E7%A8%8B%E5%9B%BE.png?raw=true)

1. 如果这个可用空间小于年轻代里现有的所有对象大小之和(包括垃圾对象) 。

2. 再确认“-XX:-HandlePromotionFailure”(jdk1.8默认就设置了)的参数是否设置了，未配置就直接Full GC。 
3. 如果有这个参数，就会看看老年代的可用内存大小，是否大于之前每一次minor gc后进入老年代的对象的平均大小，小于那么就会触发一次Full gc，对老年代和年轻代一起回收一次垃圾。
4. 如果回收完还是没有足够空间存放新的对象就会发生"OOM"。当然，如果minor gc之后剩余存活的需要挪动到老年代的对象大小还是大于老年代可用空间，那么也会触发full gc，fullgc完之后如果还是没有空间放minor gc之后的存活对象，则也会发生“OOM”。

----

## 八、JVM垃圾回收算法

### Ⅰ .分代收集理论

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%9E%83%E5%9C%BE%E5%9B%9E%E6%94%B6%E7%AE%97%E6%B3%95%E6%A6%82%E8%BF%B0.png?raw=true)

+ 根据对象存活周期的不同将内存分为几个模块。
+ 将java堆分为新生代和老年代，这样可以根据各个年代的特点选择各自适合的垃圾收集算法。

### Ⅱ.标记-复制算法

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E6%A0%87%E8%AE%B0-%E5%A4%8D%E5%88%B6%E7%AE%97%E6%B3%95.png?raw=true)

#### 1.原理：

主要是**将内存分为大小相同的两块**，每次使用其中一块进行存放，当这一块内存使用完后，就将存活的对象复制到另一块，

这样每次内存回收只需要对内存区间的一半进行回收。

#### 2.优点：

内存整理方便，将存活的对象直接移到领一块内存区域，情况正在使用的内存区域，不会产生内存碎片。

适用于新生代，将内存区分为两部分，回收效率高。

#### 3.缺点：

将内存空间一分为二，对内存消耗大，不适用老年带。

### Ⅲ.标记-清除算法

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E6%A0%87%E8%AE%B0-%E6%B8%85%E9%99%A4%E7%AE%97%E6%B3%95.png?raw=true)

#### 1.原理：

该算法分为两个阶段：

+ 标记阶段：标记出需要回收的对象

+ 清除阶段：清除被标记的对象

#### 2.产生的问题：

+ 效率问题：如果堆内存的空间过大，对象过多，则回收效率不高。

+ 空间问题：标记清除后，内存区域会产生大量不连续的空间碎片。

  

### Ⅳ.标记-整理算法

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E6%A0%87%E8%AE%B0-%E6%95%B4%E7%90%86%E7%AE%97%E6%B3%95.png?raw=true)

该算法是根据老年代特点设计出的一种标记算法，标记过程仍与**标记-清除**算法一样，只是多了一步整理操作。

步骤：

1. 标记垃圾对象。
2. 让所有存活的对象向向内存的一端移动。
3. 清理掉边界意外的内存。

---

## 九、垃圾收集器

### Ⅰ.Serial收集器

(-XX:+UseSerialGC -XX:+UseSerialOldGC)

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/serial%E6%94%B6%E9%9B%86%E5%99%A8.png?raw=true)

#### 1.介绍：

Serial收集器，也叫单线程收集器，工作时使用一条垃圾收集线程去完成垃圾收集工作，更重要的是它在进行垃圾收集工作的时候必须暂停其他所有的工作线程（ "Stop The World" ），直到它收集结束。

新生代采用复制算法，老年代采用标记-整理算法。

#### 2.优缺点：

优点：简单且高效，没有线程交互的开销，自然可以获得很高的单线程收集效率。

缺点：收集垃圾时，会STW，对用户体验不是很好。

#### 3.用途：

Serial Old收集器是Serial收集器的老年代版本，它同样是一个单线程收集器。它主要有两大用途：

+ 在JDK1.5以及以前的版本与Parallel Scavenge收集器搭配使用

+ 作为CMS收集器的后备方案。

----

### Ⅱ.Parallel Scavenge收集器 

(-XX:+UseParallelGC(年轻代),-XX:+UseParallelOldGC(老年代))

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/parallel%E6%94%B6%E9%9B%86%E5%99%A8.png?raw=true)



#### 1.介绍

Parallel收集器其实就是**Serial收集器的多线程版本**，除了使用多线程进行垃圾收集外，其余行为（控制参数、收集算法、回收策略等等）和Serial收集器类似。默认的收集线程数跟cpu核数相同，当然也可以用参数(-XX:ParallelGCThreads)指定收集线程数，但是一般不推荐修改。

Parallel Scavenge收集器关注点是吞吐量（高效率的利用CPU）。CMS等垃圾收集器的关注点更多的是用户线程的停顿时间（提高用户体验）。

**新生代**采用复制算法，**老年代**采用标记-整理算法。

#### 2.注意：

Parallel Old收集器是Parallel Scavenge收集器的老年代版本。使用多线程和“标记-整理”算法。在注重吞吐量以及CPU资源的场合，都可以优先考虑 Parallel Scavenge收集器和Parallel Old收集器(JDK8默认的新生代和老年代收集器)。

----

### Ⅲ.ParNew收集器

(-XX:+UseParNewGC)

![img](https://raw.githubusercontent.com/hepengjun2022/doc-java/master/pic/parnew%E6%94%B6%E9%9B%86%E5%99%A8.png)

ParNew收集器其实跟Parallel收集器很类似，区别主要在于它可以和CMS收集器配合使用。

它是许多运行在Server模式下的虚拟机的首要选择，除了Serial收集器外，只有它能与CMS收集器（真正意义上的并发收集器）配合工作。

----

### Ⅳ.CMS收集器

(-XX:+UseConcMarkSweepGC(old))

#### 1.介绍：

+ CMS（Concurrent Mark Sweep）收集器是一种以获取最短回收停顿时间为目标的收集器。

+ 它非常符合在注重用户体验的应用上使用，它是HotSpot虚拟机第一款真正意义上的并发收集器，它第一次实现了让垃圾收集线程与用户线程（基本上）同时工作。

+ CMS收集器是一种 “标记-清除”算法实现的，它的运作过程相比于前面几种垃圾收集器来说更加复杂一些。

#### 2.垃圾收集过程

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/cms%E5%9E%83%E5%9C%BE%E6%94%B6%E9%9B%86%E5%99%A8.png?raw=true)

##### **①.初始标记：**

暂停所有的其他线程(STW)，并记录下gc roots直接能引用的对象，该阶段速度很快。

##### **②.并发标记：**

并发标记阶段就是**从GC Roots的直接关联对象开始遍历整个对象图的过程**， 这个过程耗时较长但是不需要停顿用户线程， **可以与垃圾收集线程一起并发运行**。因为用户程序继续运行，可能会有导致已经标记过的对象状态发生改变。

##### **③.重新标记：**

重新标记阶段就是为了修正并发标记期间因为用户程序继续运行导致标记产生变动的那一部分对象的标记记录，这个阶段的停顿时间一般会比初始标记阶段的时间稍长，远远比并发标记阶段时间短。**主要用到三色标记里的增量更新算法做重新标记。**

##### **④.并发清理：**

开启用户线程，同时GC线程开始对未标记的区域做清扫。这个阶段如果有新增对象会被标记为黑色不做任何处理。

##### **⑤.并发重置：**

重置本次GC过程中的标记数据。

#### 3.优缺点

##### 优点：

并发收集、低停顿。

##### 缺点：

+ 对CPU资源敏感（会和服务抢资源）。

+ 无法处理浮动垃圾(在并发标记和并发清理阶段又产生垃圾，这种浮动垃圾只能等到下一次gc再清理了)。

+ 它使用的回收算法-“标记-清除”算法会导致收集结束时会有大量空间碎片产生，通过参数XX:+UseCMSCompactAtFullCollection可以让jvm在执行完标记清除后再进行空间整理。

+ 执行过程中的不确定性，会存在上一次垃圾回收还没执行完，然后垃圾回收又被触发的情况，特别是在并发标记和并发清理阶段会出现，一边回收，系统一边运行，也许没回收完就再次触发full gc，也就是"concurrentmode failure"，此时会进入stop the world，用serial old垃圾收集器来回收。

#### 4.CMS底层收集算法（三色标记）

在并发标记的过程中，因为标记期间应用线程还在继续跑，对象间的引用可能发生变化，多标和漏标的情况就有可能发生。这里我们引入“三色标记”来给大家解释下，把Gcroots可达性分析遍历对象过程中遇到的对象， 按照“是否访问过”这个条件标记成以下三种颜色：

![img](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220411064729451.png)

+ **黑色**：表示对象已经被垃圾收集器访问过，且这个对象的所有引用都已扫描过。黑色的对象代表已扫描过，它是安全存活的， 如果有其他对象引用指向了黑色对象，无须重新扫描一遍。黑色对象不可能直接（不经过灰色对象） 指向某个白色象。

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

#### 5.收集中产生的问题

##### ①.多标-浮动垃圾：

+ 在并发标记过程中，如果由于方法运行结束导致部分局部变量(gcroot)被销毁，这个gcroot引用的对象之前又被扫描过(被标记为非垃圾对象)，那么本轮GC不会回收这部分内存。
+ 这部分本应该回收但是没有回收到的内存，被称之为“浮动垃圾”。
+ 浮动垃圾并不会影响垃圾回收的正确性，只是需要等到下一轮垃圾回收中才被清除。
+ 另外，针对并发标记(还有并发清理)开始后产生的新对象，通常的做法是直接全部当成黑色，本轮不会进行清除，这部分对象期间可能也会变为垃圾，这也算是浮动垃圾的一部分。

##### ②.漏标-读写屏障：

漏标会导致被引用的对象被当成垃圾误删除，这是严重bug，必须解决。

**解决方案：**

###### **a.增量更新：**

+ 当黑色对象插入新的指向白色对象的引用关系时， 就将这个新插入的引用记录下来， 等并发扫描结束之后， 再将这些记录过的引用关系中的黑色对象为根， 重新扫描一次。 

+ 这可以简化理解为， 黑色对象一旦新插入了指向白色对象的引用之后， 它就变回灰色对象了。

###### **b.原始快照：**

当灰色对象要删除指向白色对象的引用关系时， 就将这个要删除的引用记录下来， 在并发扫描结束之后， 再将这些记录过的引用关系中的灰色对象为根， 重新扫描一次，这样就能扫描到白色的对象，将白色对象直接标记为黑色。

**将白色对象直接标记为黑色的目的：**让这种对象在本轮gc清理中能存活下来，待下一轮gc的时候重新扫描，这个对象也有可能是浮动垃圾。

以上无论是对引用关系记录的插入还是删除， 虚拟机的记录操作都是通过写屏障实现的。

##### ③.读写屏障

对于读写屏障，以Java HotSpot VM为例，其并发标记时对漏标的处理方案如下： 

+ CMS：写屏障 + 增量更新

+ G1，Shenandoah：写屏障 + SATB 

+ ZGC：读屏障

###### **a.写屏障：**

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

###### **b.读屏障：**

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

#### **6.CMS的相关核心参数：**

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

### Ⅴ.G1收集器

**(-XX:+UseG1GC)**

#### 1.介绍：

G1 (Garbage-First)是一款面向服务器的垃圾收集器,主要针对配备多颗处理器及大容量内存的机器. 以极高概率满足GC 停顿时间要求的同时,还具备高吞吐量性能特征。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/G1%E6%94%B6%E9%9B%86%E5%99%A8.png?raw=true)

- G1将Java堆划分为多个大小相等的独立区域（Region），JVM最多可以有2048个Region。 一般Region大小等于堆大小除以2048，比如堆大小为4096M，则Region大小为2M，当然也可以用参数"-XX:G1HeapRegionSize"手动指定Region大小，但是推荐默认的计算方式。

- G1保留了年轻代和老年代的概念，但不再是物理隔阂，它们都是（可以不连续）Region的集合。 默认年轻代对堆内存的占比是5%，如果堆大小为4096M，那么年轻代占据200MB左右的内存，对应大概是100个 Region，可以通过“-XX:G1NewSizePercent”设置新生代初始占比，在系统运行中，JVM会不停的给年轻代增加更多 的Region，但是最多新生代的占比不会超过60%，可以通过“-XX:G1MaxNewSizePercent”调整。年轻代中的Eden和 Survivor对应的region也跟之前一样，默认8:1:1，假设年轻代现在有1000个region，eden区对应800个，s0对应100 个，s1对应100个。
- 一个Region可能之前是年轻代，如果Region进行了垃圾回收，之后可能又会变成老年代，也就是说Region的区域功能 可能会动态变化。
- G1垃圾收集器对于对象什么时候会转移到老年代跟以前一样的规则，唯一不同的是对大对象的处理，G1有专门分配 大对象的Region叫Humongous区，而不是让大对象直接进入老年代的Region中。在G1中，大对象的判定规则就是一个大对象超过了一个Region大小的50%，比如按照上面算的，每个Region是2M，只要一个大对象超过了1M，就会被放入Humongous中，而且一个大对象如果太大，可能会横跨多个Region来存放。Humongous区专门存放短期巨型对象，不用直接进老年代，可以节约老年代的空间，避免因为老年代空间不够的GC开销。

#### **2.垃圾收集步骤：**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/G1%E5%9E%83%E5%9C%BE%E6%94%B6%E9%9B%86%E5%99%A8%E6%AD%A5%E9%AA%A4.png?raw=true)

##### **1.初始标记：**

（initial mark，STW）

暂停所有的其他线程，并记录下gc roots直接能引用的对象，速度很快 。 

##### **2.并发标记：**

（Concurrent Marking）

开启用户线程，同时GC线程开始对未标记的区域做清扫。这个阶段如果有新增对象会被标记为黑色不做任何处理。

##### **3.最终标记：**

（Remark，STW）

重新标记阶段就是为了修正并发标记期间因为用户程序继续运行导致标记产生变动的那一部分对象的标记记录，这个阶段的停顿时间一般会比初始标记阶段的时间稍长，远远比并发标记阶段时间短。**主要用到三色标记里的增量更新算法做重新标记。**

##### **4.筛选回收：**

（Cleanup，STW）

+ 筛选回收阶段首先对各个Region的回收价值和成本进行排序，根据用户所期 望的GC停顿时间(可以用JVM参数 -XX:MaxGCPauseMillis指定)来制定回收计划。
+ 比如说老年代此时有1000个 Region都满了，但是因为根据预期停顿时间，本次垃圾回收可能只能停顿200毫秒，那么通过之前回收成本计算得知，可能回收其中800个Region刚好需要200ms，那么就只会回收800个Region(Collection Set，要回收的集合)，尽量把GC导致的停顿时间控制在我们指定的范围内。这个阶段其实也可以做到与用户程序一起并发执行，但是因为只回收一部分Region，时间是用户可控制的，而且停顿用户线程将大幅提高收集效率。
+ 不管是年轻代或是老年代，回收算法主要用的是复制算法，将一个region中的存活对象复制到另一个region中，这种不会像CMS那样 回收完因为有很多内存碎片还需要整理一次，G1采用复制算法回收几乎不会有太多内存碎片。
+ (注意：CMS回收阶段是跟用户线程一起并发执行的，G1因为内部实现太复杂暂时没实现并发回收，不过到了Shenandoah就实现了并发收集，Shenandoah可以看成是G1的升级版本)

#### 3.G1垃圾收集分类：

- **YoungGC：**YoungGC并不是说现有的Eden区放满了就会马上触发，G1会计算下现在Eden区回收大概要多久时间，如果回收时间远远小于参数 -XX:MaxGCPauseMills 设定的值，那么增加年轻代的region，继续给新对象存放，不会马上做YoungGC，直到下一次Eden区放满，G1计算回收时间接近参数 -XX:MaxGCPauseMills 设定的值，那么就会触发Young GC。
- **MixedGC：**老年代的堆占有率达到参数(-XX:InitiatingHeapOccupancyPercent)设定的值则触发，回收所有的Young和部分Old(根据期望的GC停顿时间确定old区垃圾收集的优先顺序)以及大对象区，正常情况G1的垃圾收集是先做MixedGC，主要使用复制法，需要把各个region中存活的对象拷贝到别的region里去，拷贝过程中如果发现没有足够的空region能够承载拷贝对象就会触发一次Full GC。
- **Full GC：**停止系统程序，然后采用单线程进行标记、清理和压缩整理，好空闲出来一批Region来供下一次MixedGC使用，这 个过程是非常耗时的。(Shenandoah优化成多线程收集了)。

#### **4.G1收集器参数设置：**

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

#### **5.G1垃圾收集器适用场景：**

1. 50%以上的堆被存活对象占用 。
2. 对象分配和晋升的速度变化非常大 。
3. 垃圾回收时间特别长，超过1秒 。
4. 8GB以上的堆内存(建议值) 。
5. 停顿时间是500ms以内。

#### 6.总结：

毫无疑问， 可以由用户指定期望的停顿时间是G1收集器很强大的一个功能， 设置不同的期望停顿时间， 可使得G1在不 同应用场景中取得关注吞吐量和关注延迟之间的最佳平衡。 不过， 这里设置的“期望值”必须是符合实际的， 不能异想 天开， 毕竟G1是要冻结用户线程来复制对象的， 这个停顿时间再怎么低也得有个限度。 它默认的停顿目标为两百毫秒，一般来说， 回收阶段占到几十到一百甚至接近两百毫秒都很正常， 但如果我们把停顿时间调得非常低， 譬如设置为二十毫秒， 很可能出现的结果就是由于停顿目标时间太短， 导致每次选出来的回收集只占堆内存很小的一部分， 收集器收集的速度逐渐跟不上分配器分配的速度， 导致垃圾慢慢堆积。 很可能一开始收集器还能从空闲的堆内存中获得一些喘息的时间， 但应用运行时间一长就不行了， 最终占满堆引发Full GC反而降低性能， 所以通常把期望停顿时间设置为一两百毫秒或者两三百毫秒会是比较合理的。

----

### Ⅵ.ZGC收集器

- - 
