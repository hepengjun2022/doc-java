# 一、JVM概述

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JVM%E6%A6%82%E8%BF%B0.png?raw=true)

## Ⅰ .概述：

JVM（Java Virtual Machine）也就是我们所说的java虚拟机，它是一个虚构出来的计算机，是通过在实际的计算机上仿真模拟各种计算机功能来实现的。它的作用主要是把java类通过编译变成class的二进制文件，然后在jvm虚拟机里面去加载运行。

## Ⅱ.主要功能：

- 通过ClassLoader寻找和装载class文件。
- 解释字节码成为指令并执行，提供class文件的运行环境。
- 进行运行期间的内存分配和垃圾回收。
- 提供与硬件交互的平台。

----

# 二、JVM虚拟机组成

## Ⅰ.类加载子系统

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JVM%E7%B1%BB%E5%8A%A0%E8%BD%BD%E5%AD%90%E7%B3%BB%E7%BB%9F.png?raw=true)

### 1.作用

+ 类加载子系统负责从文件或者网络中加载Class文件（Class文件在开头有特定标识（cafe babe））。
+ 类加载器(Class Loader)只负责class文件的加载，至于是否可以运行，由执行引擎（Execution Engine）决定。
+ 加载类的信息存放于方法区的内存空间。除了类信息之外，方法区还会存放运行时常量池信息，可能还包括字符串字面量和数字常量（这部分常量信息是Class文件中常量池部分的内存映射）。

### 2.类加载器扮演的角色

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/JVM%E7%B1%BB%E5%8A%A0%E8%BD%BD%E5%99%A8%E6%89%AE%E6%BC%94%E7%9A%84%E8%A7%92%E8%89%B2.png?raw=true)



### 3.类加载原理：

**类被加载到方法区**后主要包含**运行常量池**、**类型信息**、**字段信息**、**方法信息**、**类加载器的引用**、**对应class实例的引用**等信息。

类加载器的引用：这个类到类加载器实例的引用。

对应class实例的引用：类加载器在加载类信息放在方法区后，会创建一个对象的class类型的对象实例放在堆（Heap）中，

这样，作为开发人员我们只需要访问方法区中类定义的入口和切入点即可。

### 4. 类加载过程：

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

#### Ⅰ .类加载器分类

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

## Ⅱ.字节码执行引擎

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

## Ⅲ.运行时数据区

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



----



# 三、对象内存回收：

堆中几乎放着所有的对象实例，对堆垃圾回收前的第一步就是要判断哪些对象已经死亡（即不能再被任何途径使用的对象）。

**判断对象是否死亡：**

## **Ⅰ .引用计数法：**

- 给对象添加一个引用计数器，有访问加1，引用失效减1

  - 优点：简单，效率高

  - 缺点：不能解决对象相互循环引用的问题，计数器都不为0，无法通知GC回收器进行回收。

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

## **Ⅱ.根搜索算法（可达性算法）**

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

# 四、对象创建流程：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AF%B9%E8%B1%A1%E5%88%9B%E5%BB%BA%E6%B5%81%E7%A8%8B%E5%9B%BE.png?raw=true)

## **1.类加载检查**

虚拟机遇到一条new指令时，首先将去检查这个指令的参数是否能在常量池中定位到一个类的符号引用，并且检查这个符号引用代表的类是否已被加载、验证、解析和初始化过。如果没有，那必须先执行相应的类加载过程。 new指令对应到语言层面上讲是，new关键词、对象克隆、对象序列化等。

## **2.分配内存**

在类加载检查通过后，虚拟机将为新生对象分配内存。对象所需内存的大小在类加载完成后便可完全确定，把一块确定大小的内存从Java堆中划分出来。 

**分配内存需要考虑两个问题**： 

1.如何划分内存。 

2.在并发情况下，可能出现正在给对象A分配内存，指针还没来得及修改，对象B又同时使用了原来的指针来分配内存的情况。

**划分内存的方法**： 

- **“指针碰撞”（Bump the Pointer）**(默认用指针碰撞) ：

如果Java堆中内存是绝对规整的，所有用过的内存都放在一边，空闲的内存放在另一边，中间放着一个指针作为分界点的指示器，那所分配内存就仅仅是把那个指针向空闲空间那边挪动一段与对象大小相等的距离，且在并发环境下会出现并发问题。

解决指针碰撞的方法：

1. CAS（compare and swap）：

   虚拟机采用CAS配上失败重试的方式保证更新操作的原子性来对分配内存空间的动作进行同步处理。 

2. 本地线程分配缓冲（Thread Local Allocation Buffer,TLAB）：

   把内存分配的动作按照线程划分在不同的空间之中进行，即每个线程在Java堆中预先分配一小块内存。通过­XX:+/­UseTLAB参数来设定虚拟机是否使用TLAB(JVM会默认开启­XX:+UseTLAB)，­XX:TLABSize 指定TLAB大小。

- **“空闲列表”（Free List）** 

如果Java堆中的内存并不是规整的，已使用的内存和空闲的内存相互交错，那就没有办法简单地进行指针碰撞了，虚拟机就必须维护一个列表，记录上哪些内存块是可用的，在分配的时候从列表中找到一块足够大的空间划分给对象实例，并更新列表上的记录 。

**解决并发问题的方法：（指针碰撞会出现并发问题，即多个线程抢夺空间）**



## **3.初始化**

内存分配完成后，虚拟机需要将分配到的内存空间都初始化为零值（不包括对象头），如果使用TLAB，这一工作过程也可以提前至TLAB分配时进行。

这一步操作保证了对象的实例字段在Java代码中可以不赋初始值就直接使用，程序能访问到这些字段的数据类型所对应的零值。

## **4.设置对象头**

+ 初始化零值之后，虚拟机要对对象进行必要的设置，例如这个对象是哪个类的实例、如何才能找到类的元数据信息、对象的哈希码、对象的GC分代年龄等信息，这些信息存放在对象的对象头Object Header之中。 

+ 在HotSpot虚拟机中，对象在内存中存储的布局可以分为3块区域：对象头（Header）、 实例数据（Instance Data）和对齐填充（Padding）。 

+ HotSpot虚拟机的对象头包括两部分信息，第一部分用于存储对象自身的运行时数据， 如哈希码（HashCode）、GC分代年龄、锁状态标志、线程持有的锁、偏向线程ID、偏向时间戳等。
+ 对象头的另外一部分是类型指针，即对象指向它的类元数据的指针，虚拟机通过这个指针来确定这个对象是哪个类的实例。 

**对象头构成：**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AF%B9%E8%B1%A1%E5%A4%B4%E6%9E%84%E6%88%9001.png?raw=true)

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E5%AF%B9%E8%B1%A1%E5%A4%B4%E6%9E%84%E6%88%9002.png?raw=true)

## **5.执行初始化方法** 

执行init方法，即对象按照程序员的意愿进行初始化。对应到语言层面上讲，就是为属性赋值（注意，这与上面的赋零值不同，这是由程序员赋的值），和执行构造方法。 

## **6.补充:**

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

2. 第二次标记如果这个对象覆盖了finalize方法，finalize方法是对象脱逃死亡命运的最后一次机会，如果对象要在finalize()中成功拯救 自己，只要重新与引用链上的任何的一个对象建立关联即可，譬如把自己赋值给某个类变量或对象的成员变量，那在第 二次标记时它将移除出“即将回收”的集合。如果对象这时候还没逃脱，那基本上它就真的被回收了。 

   注意：一个对象的finalize()方法只会被执行一次，也就是说通过调用finalize方法自我救命的机会就一次.

**如何判断一个类是无用的类:**

类需要同时满足下面3个条件才能算是 “无用的类” ： 

1. 该类所有的实例都已经被回收，也就是 Java 堆中不存在该类的任何实例。 
2. 加载该类的 ClassLoader 已经被回收。 
3. 该类对应的 java.lang.Class 对象没有在任何地方被引用，无法在任何地方通过反射访问该类的方法。

----

# 五、对象内存分配：

## **Ⅰ.对象栈上分配**

我们通过JVM内存分配可以知道JAVA中的对象都是在堆上进行分配，当对象没有被引用的时候，需要依靠GC进行回收内存，如果对象数量较多的时候，会给GC带来较大压力，也间接影响了应用的性能。为了减少临时对象在堆内分配的数 量，JVM通过逃逸分析确定该对象会不会被外部访问。如果不会逃逸可以将该对象在栈上分配内存，这样该对象所占用的 内存空间就可以随栈帧出栈而销毁，就减轻了垃圾回收的压力。 

对象逃逸分析：就是分析对象动态作用域，当一个对象在方法中被定义后，它可能被外部方法所引用，例如作为调用参数传递到其他地方中。

JVM对于这种情况可以通过开启逃逸分析参数(-XX:+DoEscapeAnalysis)来优化对象内存分配位置，使其通过标量替换优先分配在栈上(栈上分配)。JDK7之后默认开启逃逸分析，如果要关闭使用参数(-XX:-DoEscapeAnalysis) 标量替换：

通过逃逸分析确定该对象不会被外部访问，并且对象可以被进一步分解时，JVM不会创建该对象，而是将该对象成员变量分解若干个被这个方法使用的成员变量所代替，这些代替的成员变量在栈帧或寄存器上分配空间，这样就 不会因为没有一大块连续空间导致对象内存不够分配。

开启标量替换参数(-XX:+EliminateAllocations)，JDK7之后默认开启。 

**标量与聚合量：**

+ 标量即不可被进一步分解的量，而JAVA的基本数据类型就是标量（如：int，long等基本数据类型以及 reference类型等）。

+ 标量的对立就是可以被进一步分解的量，而这种量称之为聚合量，而在JAVA中对象就是可以被进一 步分解的聚合量。

## **Ⅱ.对象在Eden区分配**

大多数情况下，对象在新生代中 Eden 区分配。

当 Eden 区没有足够空间进行分配时，虚拟机将发起一次Minor GC。

Minor GC和Full GC 有什么不同呢？ 

+ Minor GC/Young GC：指发生新生代的的垃圾收集动作，Minor GC非常频繁，回收速度一般也比较快。

+ Major GC/Full GC：一般会回收老年代 ，年轻代，方法区的垃圾，Major GC的速度一般会比Minor GC的慢 10倍以上。 

Eden与Survivor区默认8:1:1 大量的对象被分配在eden区，eden区满了后会触发minor gc，可能会有99%以上的对象成为垃圾被回收掉，剩余存活的对象会被挪到为空的那块survivor区，下一次eden区满了后又会触发minor gc，把eden区和survivor区垃圾对象回收，把剩余存活的对象一次性挪动到另外一块为空的survivor区，因为新生代的对象都是朝生夕死的，存活时间很短，所 以JVM默认的8:1:1的比例是很合适的，让eden区尽量的大，survivor区够用即可。

 JVM默认有这个参数-XX:+UseAdaptiveSizePolicy(默认开启)，会导致这个8:1:1比例自动变化，如果不想这个比例有变 化可以设置参数-XX:-UseAdaptiveSizePolicy

## **Ⅲ.大对象直接进入老年代**

大对象就是需要大量连续内存空间的对象（比如：字符串、数组）。

JVM参数 -XX:PretenureSizeThreshold 可以设置大对象的大小，如果对象超过设置大小会直接进入老年代，不会进入年轻代，这个参数只在 Serial 和ParNew两个收集器下有效。 

设置JVM参数：-XX:PretenureSizeThreshold=1000000 (单位是字节) -XX:+UseSerialGC ，再执行程序会发现大对象直接进了老年代，为什么要这样呢？

+ 为了避免为大对象分配内存时的复制操作而降低效率。

## **Ⅳ.长期存活的对象将进入老年代**

+ 虚拟机采用了分代收集的思想来管理内存，那么内存回收时就必须能识别哪些对象应放在新生代，哪些对象应放在老年代中。

+ 为了做到这一点，虚拟机给每个对象一个对象年龄（Age）计数器。 如果对象在 Eden 出生并经过第一次 Minor GC 后仍然能够存活，并且能被 Survivor 容纳的话，将被移动到 Survivor 空间中，并将对象年龄设为1。

+ 对象在 Survivor 中每熬过一次 MinorGC，年龄就增加1岁，当它的年龄增加到一定程度 （默认为15岁，CMS收集器默认6岁，不同的垃圾收集器会略微有点不同），就会被晋升到老年代中。对象晋升到老年代的年龄阈值，可以通过参数 -XX:MaxTenuringThreshold 来设置。

## **Ⅴ.对象动态年龄判断**

触发：minor gc之后触发的

当前放对象的Survivor区域里(其中一块区域，放对象的那块s区)，一批对象的分带年龄总大小大于这块Survivor区域内存大小的 50%对象的年龄(-XX:TargetSurvivorRatio可以指定)，那么此时大于等于这批对象年龄最大值的对象，就可以直接进入老年代了。

例如Survivor区域里现在有一批对象，年龄1+年龄2+年龄n的多个年龄对象总和超过了Survivor区域的50%对象的年龄，此时就会把年龄n(含)以上的对象都放入老年代。这个规则其实是希望那些可能是长期存活的对象，尽早进入老年代。

对象动态年龄判断机制一般是在minor gc之后触发的。

## **Ⅵ.老年代空间分配担保机制**

触发：年轻代每次minor gc之前JVM都会计算下老年代剩余可用空间。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/%E8%80%81%E5%B9%B4%E4%BB%A3%E7%A9%BA%E9%97%B4%E5%88%86%E9%85%8D%E6%8B%85%E4%BF%9D%E6%9C%BA%E5%88%B6%E6%B5%81%E7%A8%8B%E5%9B%BE.png?raw=true)

1. 如果这个可用空间小于年轻代里现有的所有对象大小之和(包括垃圾对象) 。
2. 再确认“-XX:-HandlePromotionFailure”(jdk1.8默认就设置了)的参数是否设置了，未配置就直接Full GC。 
3. 如果有这个参数，就会看看老年代的可用内存大小，是否大于之前每一次minor gc后进入老年代的对象的平均大小，小于那么就会触发一次Full gc，对老年代和年轻代一起回收一次垃圾。
4. 如果回收完还是没有足够空间存放新的对象就会发生"OOM"。当然，如果minor gc之后剩余存活的需要挪动到老年代的对象大小还是大于老年代可用空间，那么也会触发full gc，fullgc完之后如果还是没有空间放minor gc之后的存活对象，则也会发生“OOM”。

为什么会有老年代空间分配担保机制？（个人理解）

+ 首先确保老年代有足够的空间确保该次Minor gc后满足进入老年代的对象能否容纳下。

+ 其次，如果动不动就直接Full gc 会影响性能，Full gc 花费的时间会比Young gc多10倍。

----



