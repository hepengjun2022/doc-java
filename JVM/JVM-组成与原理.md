# 一、JVM概述

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JVM%E6%A6%82%E8%BF%B0.png?raw=true)

## 1.1、概述：

JVM（Java Virtual Machine）也就是我们所说的java虚拟机，它是一个虚构出来的计算机，是通过在实际的计算机上仿真模拟各种计算机功能来实现的。它的作用主要是把java类通过编译变成class的二进制文件，然后在jvm虚拟机里面去加载运行。

## 1.2、主要功能：

- 通过ClassLoader寻找和装载class文件。
- 解释字节码成为指令并执行，提供class文件的运行环境。
- 进行运行期间的内存分配和垃圾回收。
- 提供与硬件交互的平台。

----

# 二、JVM虚拟机组成

## 2.1、类加载子系统

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JVM%E7%B1%BB%E5%8A%A0%E8%BD%BD%E5%AD%90%E7%B3%BB%E7%BB%9F.png?raw=true)

### 1.作用

+ 类加载子系统负责从文件或者网络中加载Class文件（Class文件在开头有特定标识（cafe babe））。
+ 类加载器(Class Loader)只负责class文件的加载，至于是否可以运行，由执行引擎（Execution Engine）决定。
+ 加载类的信息存放于方法区的内存空间。除了类信息之外，方法区还会存放运行时常量池信息，可能还包括字符串字面量和数字常量（这部分常量信息是Class文件中常量池部分的内存映射）。

### 2.类加载器扮演的角色

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JVM%E7%B1%BB%E5%8A%A0%E8%BD%BD%E5%99%A8%E6%89%AE%E6%BC%94%E7%9A%84%E8%A7%92%E8%89%B2.png?raw=true)



### 3.类加载原理

**类被加载到方法区**后主要包含**运行常量池**、**类型信息**、**字段信息**、**方法信息**、**类加载器的引用**、**对应class实例的引用**等信息。

类加载器的引用：这个类到类加载器实例的引用。

对应class实例的引用：类加载器在加载类信息放在方法区后，会创建一个对象的class类型的对象实例放在堆（Heap）中，

这样，作为开发人员我们只需要访问方法区中类定义的入口和切入点即可。

### 4.类加载过程

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

### 5.JVM中类加载全过程

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JVM%E4%B8%AD%E7%B1%BB%E5%8A%A0%E8%BD%BD%E5%85%A8%E8%BF%87%E7%A8%8B.png?raw=true)

### 6.类加载器

#### Ⅰ.类加载器分类

##### 1.引导类加载器

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

##### 2.扩展类加载器

负责加载支撑JVM运行的位于JRE的lib目录下的ext扩展目录中的JAR类包。

```
C:\Program Files\Java\jdk1.8.0_91\jre\lib\ext;
C:\Windows\Sun\Java\lib\ext
```

##### 3.应用程序类加载器

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

##### 4.自定义类加载

负责加载用户自定义路径下的类包。

#### Ⅱ.类加载机制

##### 1.双亲委派机制



![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%8F%8C%E4%BA%B2%E5%A7%94%E6%B4%BE%E6%9C%BA%E5%88%B6.png?raw=true)

###### ①.加载步骤：

1. 应用程序类加载器首先去加载，检查目标类是否已经被加载过，如果没找到就委托给父加载器，有就返回。

2. 扩展类加载器去加载，检查是否已经被类加载器加载过，没有则会委托给顶层加载器，有就返回。

3. 顶层加载器检查是否已经被类加载器加载过：
   + 有，直接返回。
   + 没有，再去自己的类加载路径去寻找：
     + 有，加载。
     + 没有，委派给下层加载器。

4. 扩展类加载再去自己的类加载路径去找，如果没找到增委派给下层加载器。

5. 应用类加载器再去自己的类加载路径去找，就抛出异常。

###### ②.类加载源码解析

**类加载器初始：**

getSystemClassLoader()方法获取类加载器：

```java
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

```java
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

###### ③.双亲委派机制好处

为什么设计双亲委派机制？

- 沙箱安全机制：防止核心API库被随意篡改。（比如自己写的java.lang.String.class类不会被加载）
- 避免重复被加载：当父加载器已经加载过该类时，子加载器就没必要加载了，保证加载类的唯一性。

###### ④.补充

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

##### 2.全盘委托机制

“全盘负责”是指当一个ClassLoder装载一个类时，除非显示的使用另外一个ClassLoder，该类所依赖及引用的类也由这个ClassLoder载入。

##### 3.总结

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E7%B1%BB%E5%8A%A0%E8%BD%BD%E6%9C%BA%E5%88%B6%E6%80%BB%E7%BB%93.png?raw=true)

## 2.2、字节码执行引擎

### 1.概述

主要是通过编译器将源代码转成字节码，通过JIT执行字节码指令。

### 2.字节码执行引擎组成

+ 解释执行器

+ JIT即时编译器

  + C1编译器：

    + C1 编译器是一个简单快速的编译器，主要的关注点在于局部性的优化，适用于执行时间较短或对启动性能有要求的程序，例如，GUI 应用对界面启动速度就有一定要求，C1也被称为 Client Compiler。 

    + C1编译器几乎不会对代码进行优化。

  + C2编译器：

    + C2 编译器是为长期运行的服务器端应用程序做性能调优的编译器，适用于执行时间较长或对峰值性能有要求的程序。
    + 根据各自的适配性，这种即时编译也被称为Server Compiler。 但是C2代码已超级复杂，无人能维护！所以才会开发Java编写的Graal编译器取代C2(JDK10开始) 

  

### 3.字节码执行的方式

+ 解释执行（解释器）：Java程序运行期间，执行字节码指令，一般这些指令会按照顺序解释执行，这种 

  就是解释执行。

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E8%A7%A3%E9%87%8A%E5%99%A8%E7%BC%96%E8%AF%91.png?raw=true)

  （强制使用该模式：-Xint）

+ 编译执行（JIT编译器）：将字节码编译为机器码并执行，这个编译过程发生在运行期，称为JIT编译。下面则是两种编译模式：

  + client（即C1）：只做少量性能开销比高的优化，占用内存少，适用于桌面程序。
  + server（即C2）：进行了大量优化，占用内存多，适用于服务端程序。会收集大量的运行时信息。

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E8%A7%A3%E9%87%8A%E5%99%A8%E7%BC%96%E8%AF%91.png?raw=true)

  （强制使用该模式：-Xcomp）

  + 分层编译：

    + 在 Java7之前，需要根据程序的特性来选择对应的 JIT，虚拟机默认采用解释器和其中一个编译器配合工作。 

    + Java7及以后引入了分层编译，这种方式综合了 C1 的启动性能优势和 C2 的峰值性能优势，当然我们也可以通过参数强制指定虚拟机的即时编译模式。 

    + 在 Java8 中，默认开启分层编译。 

      ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E5%88%86%E5%B1%82%E7%BC%96%E8%AF%91.png?raw=true)

    + 分层编译原理：

      + 第 0 层：程序解释执行，默认开启性能监控功能（Profiling），如果不开启，可触发第二层编译。
      + 第 1 层：可称为 C1 编译，将字节码编译为本地代码，进行简单、可靠的优化，不开启Profiling。
      + 第 2 层：也称为 C1 编译，开启Profiling，仅执行带方法调用次数和循环回边执行次数profiling 的 C1 编译。 
      + 第 3 层：也称为 C1 编译，执行所有带 Profiling 的 C1 编译。 
      + 第 4 层：可称为 C2 编译，也是将字节码编译为本地代码，但是会启用一些编译耗时较长的优化，甚至会根据性能监控信息进行一些不可靠的激进优化。 

注意：

- 32为机器默认选择C1，可在启动时添加-client或-server来指定，64位机器若CPU>2且物理内存>2G则默认为C2，否则为C1
- Hotspot JVM执行代码的机制：对在执行过程中执行频率高的代码进行编译，对执行频率不高的代码继续解释执行。

### 4.热点代码

热点代码，就是那些被频繁调用的代码，比如调用次数很高或者在 for 循环里的那些代码。这些再次编译后的机器码会被缓存起来，以备下次使用，但对于那些执行次数很少的代码来说，这种编译动作就纯属浪费。 

JVM提供了一个参数“-XX:ReservedCodeCacheSize”，用来限制 CodeCache 的大小。也就是说，JIT 编译后的代码都会放在 CodeCache 里。

如果这个空间不足，JIT 就无法继续编译，编译执行会变成解释执行，性能会降低一个数量级。同时，JIT 编译器会一直尝试去优化代码，从而造成了 CPU 占用上升。 

**通过 java -XX:+PrintFlagsFinal –version查询:** 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E7%83%AD%E7%82%B9%E4%BB%A3%E7%A0%81.png?raw=true)

### 5.热点探测

在 HotSpot 虚拟机中的热点探测是 JIT 优化的条件，热点探测是基于计数器的热点探测，采用这种方法的虚拟机会为每个方法建立计数器统计方法的执行次数，如果执行次数超过一定的阈值就认为它是“热点方法” 。

虚拟机为**每个方法**准备了**两类计数器**：方法调用计数器（Invocation Counter）和回边计数器 （Back Edge Counter）。在确定虚拟机运行参数的前提下，这两个计数器都有一个确定的阈值，当计数器超过阈值溢出了，就会触发 JIT 编译。 

1. **方法调用计数器**

   用于统计方法被调用的次数，方法调用计数器的默认阈值在客户端模式下是 1500 次，在服务端模式下是 10000 次(我们用的都是服务端，java –version查询)，可通过 -XX: CompileThreshold 来设定 ：

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E6%96%B9%E6%B3%95%E8%B0%83%E7%94%A8%E8%AE%A1%E6%95%B0%E5%99%A801.png?raw=true)

   **通过 java -XX:+PrintFlagsFinal –version查询：**

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E6%96%B9%E6%B3%95%E8%B0%83%E7%94%A8%E8%AE%A1%E6%95%B0%E5%99%A802.png?raw=true)

2. **回边计数器**

   用于统计一个方法中循环体代码执行的次数，在字节码中遇到控制流向后跳转的指令称为“回边”（Back Edge），该值用于计算是否触发 C1 编译的阈值，在不开启分层编译的情况下，在服务端模式下是**10700**。

   计算公式：回边计数器阈值 =方法调用计数器阈值（CompileThreshold）×（OSR比率 （OnStackReplacePercentage）-解释器监控比率（InterpreterProfilePercentage）/100 。

   **通过 java -XX:+PrintFlagsFinal –version查询先关参数：**

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E5%9B%9E%E7%BC%96%E8%AE%A1%E6%95%B0%E5%99%A801.png?raw=true)

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E5%9B%9E%E7%BC%96%E8%AE%A1%E6%95%B0%E5%99%A802.png?raw=true)

   其中OnStackReplacePercentage默认值为140，InterpreterProfilePercentage默认值为33，如果都取默认值，那Server模式虚拟机回边计数器的阈值为10700。回边计数器阈值 =10000×（140-33）=10700

### 6.JIT优化技术

#### 1.C1优化（主要）

##### ①.方法内联

方法内联的优化行为就是把目标方法的代码复制到发起调用的方法之中，避免发生真实的方法调用。

```
private int add1(int x1,int x2,int x3,int x4){
	return add2(x1,x2)+add2(x3,x4);
}
private int add2(int x1,int x2){
	return x1+x2;
}
```

方法内联之后，

```
private int add(int x1,int x2,int x3,int x4){
	return x1+x2+x3+x4;
}
```

JVM 会自动识别热点方法，并对它们使用方法内联进行优化。 

我们可以通过 -XX:CompileThreshold 来设置热点方法的阈值。 

但要强调一点，热点方法不一定会被 JVM 做内联优化，如果这个方法体太大了，JVM 将不执行内联操作。 

而方法体的大小阈值，我们也可以通过参数设置来优化： 

+ 经常执行的方法，默认情况下，方法体大小小于 325 字节的都会进行内联，我们可以通过 - XX:FreqInlineSize=N 来设置大小值。

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E6%96%B9%E6%B3%95%E5%86%85%E8%81%9401.png?raw=true)

+ 不是经常执行的方法，默认情况下，方法大小小于 35 字节才会进行内联，我们也可以通过 - XX:MaxInlineSize=N 来重置大小值。

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E6%96%B9%E6%B3%95%E5%86%85%E8%81%9402.png?raw=true)



**热点方法的优化可以有效提高系统性能，一般我们可以通过以下几种方式来提高方法内联：** 

+ 通过设置 JVM 参数来减小热点阈值或增加方法体阈值，以便更多的方法可以进行内联，但这种方法意味着需要占用更多地内存。 

+ 在编程中，避免在一个方法中写大量代码，习惯使用小方法体。

+ 尽量使用 final、private、static 关键字修饰方法，编码方法因为继承，会需要额外的类型检查。 

##### ②.冗余消除

将无用的代码进行消除。

```
//消除前
public void foo() {
        y = b.value;
        //do something
        y = y;
        sum = y + z;
}
//消除后
public void foo() {
        y = b.value;
        //do something
        sum = y + y;
}
```

##### ③复写传播.

```
 //复写前
 public void foo() {
        y = b.value;
        //do something
        z = y;
        sum = y + z;
    }
 //复写后
public void foo() {
        y = b.value;
        //do something
        z = b.value;
        sum = y + y;
    }
```

#### 2.C2优化

##### ①.锁消除

在非线程安全的情况下，尽量不要使用线程安全容器，比如 StringBuffer。由于 StringBuffer中的 append 方法被 Synchronized 关键字修饰，会使用到锁，从而导致性能下降。

```
@override
public synchronized StringBuffer append(String str){
	toStringCache = null;
	super.append(str);
	return this;
}
```

但实际上，在以下代码测试中，StringBuffer 和 StringBuilder 的性能基本没什么区别。这是因为在局部方法中创建的对象只能被当前线程访问，无法被其它线程访问，这个变量的读写肯定不会有竞争，这个时候 JIT 编译会对这个对象的方法锁进行锁消除。

下代码测试中，StringBuffer 和 StringBuilder 的性能基本没什么区别。这是因为在局部方法中 创建的对象只能被当前线程访问，无法被其它线程访问，这个变量的读写肯定不会有竞争，这个时候 JIT 编译会对这个对象的方法锁进行锁消除。 

```
public static String BufferString(String s1,String s2){
	StringBuffer sb=new StringBuffer();
	sb.append(s1);
	sb.append(s2);
	return sb.toString;
}
public static String BuilderString(String s1,String s2){
	StringBuilder sb=new StringBuilder();
	sb.append(s1);
	sb.append(s2);
	return sb.toString;
}
结果：
StringBuffer花费时间536
StringBuilder花费时间298
```

我们把锁消除关闭---测试发现性能差别有点大 

-XX:+EliminateLocks开启锁消除（jdk1.8默认开启，其它版本未测试） 

-XX:-EliminateLocks 关闭锁消除 

```
StringBuffer花费时间948
StringBuilder花费时间279
```

##### ②.标量替换

逃逸分析证明一个对象不会被外部访问，如果这个对象可以被拆分的话，当程序真正执行的时候可能不创建这个对象，而直接创建它的成员变量来代替。将对象拆分后，可以分配对象的成员变量在栈或寄存器上，原本的对象就无需分配内存空间了。这种编译优化就叫做标量替换。（前提是需要开启逃逸分析）

-XX:+DoEscapeAnalysis开启逃逸分析（jdk1.8默认开启） 

-XX:-DoEscapeAnalysis 关闭逃逸分析 

-XX:+EliminateAllocations开启标量替换（jdk1.8默认开启） 

-XX:-EliminateAllocations 关闭标量替换 

##### ③.逃逸分析技术

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AD%97%E8%8A%82%E7%A0%81%E6%89%A7%E8%A1%8C%E5%BC%95%E6%93%8E-%E9%80%83%E9%80%B8%E5%88%86%E6%9E%90%E5%8E%9F%E7%90%86.png?raw=true)

逃逸分析的原理：分析对象动态作用域，当一个对象在方法中定义后，它可能被外部方法所引 

用。

比如：调用参数传递到其他方法中，这种称之为方法逃逸。甚至还有可能被外部线程访问到， 例如赋值给其他线程中访问的变量，这个称之为线程逃逸。 

从不逃逸到方法逃逸到线程逃逸，称之为对象由低到高的不同逃逸程度。 

如果确定一个对象不会逃逸出线程之外，那么让对象在栈上分配内存可以提高JVM的效率。 

当然逃逸分析技术属于JIT的优化技术，所以必须要符合热点代码，JIT才会优化，另外对象如果要分配到栈上，需要将对象拆分，这种编译优化就叫做标量替换技术。

##### ④.栈上分配

根据逃逸分析来决定是否在栈上分配。

## 2.3、运行时数据区

（JVM内存模型/结构）

+ class存放于本地硬盘中，在运行的时候，JVM将class文件加载到JVM中，被称为DNA元数据模板
  存放在JVM的方法区中，之后根据元数据模板实例化出相应的对象。
+ 在 class -> JVM -> 元数据模板 -> 实例对象这个过程中，类加载器扮演者快递员的角色。

### **1.Java堆**

（Heap）

线程共享，是java虚拟机管理内存最大的一块，此内存区域主要是存储一些对象引用实例。

- 新生代用来存放新分配的对象；新生代中经过垃圾回收，没有回收掉的对象，被复制到老年代
- 老年代存储对象比新生代存储对象的年龄大得多
- 老年代存储一些大对象
- 整个堆大小 = 新生代 + 老年龄
- 新生代 = Eden + 存活区
- 从前的持久代，用来存放Class、Method 等元信息的区域，从 JDK8 开始去掉了，取而代之的是元空间（MetaSpace），元空间并不在虚拟机里面，而是直接使用本地内存。

### **2.方法区**

(Method Area)

- 线程共享
- 主要存储已经被虚拟机加载的类信息、常量、静态变量、以及编译器编译后的代码等数据。

**注意：**

+ Java7，将常量池是存放到了堆中。

+ Java8之后，取消了整个永久代区域，取而代之的是元空间。**运行时常量池和静态常量池存放在元空间中，而字符串常量池依然存放在堆中。**

### **3.程序计数器**

(Program Counter Register)

- 线程私有
- 只占有一小块内存空间，它主要的作用是标记当前线程所执行的字节码文件的行号。

### **4.线程栈**

（JVM Stacks）

​    ![0](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E7%BA%BF%E7%A8%8B%E6%A0%88%E7%BB%93%E6%9E%84.png?raw=true)

#### **①线程栈的作用：**

线程私有，其生命周期跟线程周期相同。

主要是虚拟机栈描述Java方法执行的内存模型，在方法被调用执行的时候，虚拟机栈会同时

给该方法创建一个栈帧（Stack Frame）用于存储局部变量表、操作数栈、动态链接、方法出

口等信息并且做入栈操作。

该方法被调用执行完毕，对应的栈帧在虚拟机栈里就会做出栈操作。

#### **②.栈帧构成：**

- 局部变量表：主要是记录该方法的局部变量

- 操作数栈：记录局部变量的值，然后进行压栈操作

- 动态链接：
  1.  每个栈帧都保存了一个可以指向该方法所在类的运行常量池的地址。
  2.  当前方法中如果需要调用其他方法的时候, 能够从运行时常量池中找到对应的符号引用。
  3.  然后将符号引用转换为直接引用,然后就能直接调用对应方法, 这就是动态链接。

  动态链接与静态链接的区别：
  
  + 动态链接是需要用到才加载。
  + 静态链接是初始化时就加载。
  
- 方法出口：记录方法被调用的地方，并进行返回

### **5.本地方法栈**

（Native Method Stacks）

线程私有，与虚拟机栈的功能类似，其作用主要是Java虚拟机为本地Native方法提供服务。



