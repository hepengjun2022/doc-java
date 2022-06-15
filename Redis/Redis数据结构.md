# 一、String字符串

## 1.1、常用命令

## 1.2、应用场景

## 1.3、底层原理

redis其实可以理解为 K-V数据库，因此对每个键值对都会有一个 dictEntry，里面存储了指向 Key 和 Value 的指针；next 指向下一个 dictEntry，与本 Key-Value 无关

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis%E5%BA%95%E5%B1%82K-V%E7%BB%93%E6%9E%84.png?raw=true)

注意：val存的是指向redisObject的指针，而redisObject对象中type属性可以指定类型。

key：

```c++
typedef struct dictEntry {
    void *key; //存储key
    union {
        void *val; //存储value
        uint64_t u64;
        int64_t s64;
        double d;
    } v;
    struct dictEntry *next;
} dictEntry;
```

Value：

<font color='red'>value既不是存的String，也不是存的SDS结构，而且用的RedisObject结构</font>。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis%E7%9A%84redisObject%E7%BB%93%E6%9E%84.png?raw=true)

```c++
// redisObject对象 :  string , list ,set ,hash ,zset ...
typedef struct redisObject {
    // 4bits  类型
    unsigned type:4;        //  4 bit, sting , hash
    // 4bits 存储格式
    unsigned encoding:4;    //  4 bit
    // 24bits 记录LRU信息
    unsigned lru:LRU_BITS; /* LRU time (relative to global lru_clock) or
                            * LFU data (least significant 8 bits frequency
                            * and most significant 16 bits access time). 
                            *    24 bit 
    //指向对象的值            * */
    int refcount;           // 4 byte  
    void *ptr;              // 8 byte  总空间:  4 bit + 4 bit + 24 bit + 4 byte + 8 byte = 16 byte  
} robj;
```

RedisObject：
实际上，不论 redis存储的值 是 5 种类型的哪一种，都是通过 RedisObject 来存的； 

1. RedisObject 中的 type 字段指明了要存的值的类型，即：String/List/Set/Zset/Hash中的一个；
2. RedisObject 中的encoding表示底层使用的编码格式，为了提供存储效率和执行效率，每种数据类型的底层结构不止一种。
3. RedisObject 中的ptr 字段则指向对象所在的地址。可以看出，字符串对象虽然经过了 RedisObject 的包装，但仍然需要通过 SDS储。

### 1.SDS结构与其他语言字符串结构比较

#### ①.获取字符串长度复杂度

由于SDS结构中含有len属性，所以获取字符串长度的复杂度为o(1);而对于其他语言来说，获取字符串的长度需要遍历字符串计数来实现，时间复杂度o(n);

#### ②.字符串的内存重分配次数

其他语言由于不记录字符串长度，所以要修改字符串必须重新分配内存。SDS实现了空间预分配和惰性释放两种策略：

+ 空间预分配：当SDS的API 对一个SDS进行修改，并且需要对SDS进行空间扩展的时候，不仅会为SDS分配修改所需的空间，还会为SDS额外分配空间，这样可以减少连续执行字符串增长操作所需内存分配次数。
+ 惰性释放：当 SDS 的 API 需要对 SDS 保存的字符串进行缩短时，程序并不立即使用内存重分配来回收缩短后多出来的字节，而是使用 free 属性将这些字节的数量记录起来，并等待将来使用。

#### ③.二进制安全

指能处理任意的二进制数据，包括非 ASCII 和 null 字节。C 字符串以空字符 '\0'，作为字符串结束的标识，而对于一些二进制文件（如图片等），内容可能包括空字符串'\0'，导致程序读入的空字符会被误认为是字符串的结尾，因此C字符串无法正确存取二进制数据；SDS 的 API 都是以处理二进制的方式来处理 buf 里面的元素，并且 SDS 不是以空字符串'\0'来判断是否结束，而是以 len 属性表示的长度来判断字符串是否结束，因此 Redis 不仅可以保存文本数据，还可以保存任意格式的二进制数据。

#### ④.C字符串函数兼容

SDS 的buf数组会以'\0'结尾，这样可以重用 C 语言库<string.h> 中的一部分函数，避免了不必要的代码重复。

#### ⑤.API安全性与缓冲区溢出

**缓冲区溢出（buffer overflow）**：会存在这样的一种异常，当程序将数据写入缓冲区时，会超过缓冲区的边界，并覆盖相邻的内存位置。在 C 语言中使用 strcat 函数来进行两个字符串的拼接，一旦没有分配足够长度的内存空间，就会造成缓冲区溢出：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-SDS%E5%AE%89%E5%85%A8api.png?raw=true)

由于 SDS 记录了自身长度，同时在修改时，API 会按照如下步骤进行：

（1）先检查SDS的空间是否满足修改所需的要求；

（2）如果不满足要求的话，API 会自动将 SDS 的空间扩展至执行修改所需的大小；

（3）然后才执行实际的修改操作；

所以SDS不会造成缓冲区溢出情况。

### 2.String的SDS结构

String类型底层数据结构非C语言char[]，而是redis作者自己创建的一种SDS结构（Simple-Dynamic-String），其结构如下：

```c++
//redis3.2版本以前
struct sdshdr {  
    int len;/*已使用长度*/
    int free;/*剩余空间长度*/
    char buf[];/*存储的数据*/
};
```

```c++
//redis3.2版本以后
typedef char *sds;  
struct__attribute__((__packed__))sdshdr5{  
    unsigned char flags;  
    char buf[];// buf[0]: z:  0101001
};  
struct__attribute__((__packed__))sdshdr8 {  
    uint8_t len; /* used */  
    uint8_t alloc; /* excluding the header and null terminator */  
    unsigned char flags; /* 3 lsb of type, 5 unused bits */  
    char buf[];  
};  
struct __attribute__ ((__packed__)) sdshdr16 {  
    uint16_t len; /* used */
    uint16_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};  
struct __attribute__ ((__packed__)) sdshdr32 {  
    uint32_t len; /* used */
    uint32_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};  
struct __attribute__ ((__packed__)) sdshdr64 {
    uint64_t len; /* used */
    uint64_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};  
```

为什么不使用C的char[]作为string结构？

c语言的char[]字符以'\0'结尾，如果socket传入的是文件、音频这样的流，可能会出现'\0'导致后面的字符读取不到。Redis采用SDS使用len和'\0'就会有效的读取到数据。不会存在数据中有'\0'导致后面数据读取不到的问题。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-SDS%E7%BB%93%E6%9E%8401.png?raw=true)

**字符串存储过程分为两步：**

1. 选择合适的SDS类型；
2. 选择合适的encoding编码格式;

#### ①.选择合适的SDS类型

<font color='red'>根据值value的长度选择对应的SDS类型</font>

结合源码分析：

```c++
static inline char sdsReqType(size_t string_size) {
    if (string_size < 1<<5)
        return SDS_TYPE_5;
    if (string_size < 1<<8)
        return SDS_TYPE_8;
    if (string_size < 1<<16)
        return SDS_TYPE_16;
#if (LONG_MAX == LLONG_MAX)
    if (string_size < 1ll<<32)
        return SDS_TYPE_32;
    return SDS_TYPE_64;
#else
    return SDS_TYPE_32;
#endif
}
```

根据位移计算可知 1<<8 = 2^8=256，单位是字节。也就是说，每种类型的SDS可存储的字节数如下：

SDS_TYPE_5　-- 32 Byte
SDS_TYPE_8　-- 256 Byte
SDS_TYPE_16 -- 64KＢ
SDS_TYPE_32 -- ...
SDS_TYPE_64 -- ...        

#### ②.选择合适的encoding编码格式

**Redis的全部底层数据结构有：**

<font color='red'>redis_encoding_int (long类型的整数)</font>

<font color='red'>redis_encoding_embstr  (embstr编码的简单动态字符串)</font>

<font color='red'>redis_encoding_raw (简单动态字符串)</font>

<font color='red'>redis_encoding_ht (字典）</font>

<font color='red'>redis_encoding_linkedlist （双端链表）</font>

<font color='red'>redis_encoding_ziplist（压缩列表）</font>

<font color='red'>redis_encoding_intset（整数集合）</font>

<font color='red'>redis_encoding_skiplist（跳跃表和字典）</font>

字符串的底层encoding编码结构：(三种之一)

+ int
+ raw 
+ embstr

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-%E5%AD%97%E7%AC%A6%E4%B8%B2%E7%9A%84%E5%BA%95%E5%B1%82encoding%E7%BC%96%E7%A0%81%E7%BB%93%E6%9E%84.png?raw=true)

#### ③.embstr 和 raw比较

**好处：**embstr 的使用只分配一次内存空间(因此 RedisObject 和 sds 是连续的)，而 raw 需要分配两次内存空间(分别为 RedisObject 和 sds 分配空间)。因此与 raw 相比，embstr 的好处在于创建时少分配一次空间，删除时少释放一次空间，以及对象的所有数据连在一起，寻找方便。

**坏处:** 而embstr 的坏处也很明显，如果字符串的长度增加需要重新分配内存时，整个 RedisObject 和 sds 都需要重新分配空间，因此 Redis 中的 embstr 实现为只读。

#### ④.底层数据编码格式转换

当 int 数据不再是整数，或大小超过了 long 的范围时，自动转化为 raw。
对于 embstr，由于其实现是只读的，因此在对 embstr 对象进行修改时，都会先转化为 raw 再进行修改。因此，只要是修改 embstr 对象，修改后的对象一定是 raw 的，无论是否达到了 44个字节。

#### ⑤.字符串追加空间扩展流程

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-SDS%E6%89%A9%E5%AE%B9%E8%BF%87%E7%A8%8B.png?raw=true)

+ 当字符串长度 < 1M，扩容是加倍现有空间

+ 当字符串长度 > 1M，扩容时一次只会多扩容1M空间。（字符串最大长度512M）

  ```c++
  static int checkStringLength(client *c, long long size) {
      if (size > 512*1024*1024) {
          addReplyError(c,"string exceeds maximum allowed size (512MB)");
          return C_ERR;
      }
      return C_OK;
  }
  ```

#### 六.总结

+ 如果一个字符串内容可转为 long，那么该字符串会被转化为 long 类型，对象 ptr 指向该 long，并且对象类型也用 int 类型表示。
+ 普通的字符串有两种 embstr 和 raw。

+ 如果字符串对象的长度小于 44字节，就用 embstr，否则用 raw。

  **为什么是44呢？**

  实际redis中存储数据的最小SDS结构是SDS_TYPE_8，结构：

  ```c++
  struc SDS{
      int8 capatcity;//1字节 
      int8 len;		//1字节 
      int8 flag;      //1字节
      byte[] content; //内容
  }
  ```

  可以看出，一个最小的SDS，至少占用３字节,再加上RedisObject的16个字节，也就是说一个最小的字符串是19个字节。

  再了解下redis的内存分配器：jemalloc、tcmalloc。

  这些内存分配器可以分配的大小2/4/8/16/32/64字节，可以看出最多分配64字节，即64K连续的内存。

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-SDS8%E7%BB%93%E6%9E%84.png?raw=true)

  64字节，减去RedisObject的16字节和SDS的3字节头信息，剩下45字节，再去除\0结尾，这样得出embstr可存储最大长度为64-16-3-1=44字节的字符串。 

  字符串最大长度是512M。

# 二、Hash

## 2.1、常用命令

## 2.2、应用场景

## 2.3、底层原理

### ①.介绍

在redis中,哈希对象的键是一个[字符串](https://so.csdn.net/so/search?q=字符串&spm=1001.2101.3001.7020)类型，值是一个键值对集合。这种类型的value为哈希类型即键值对类型，与Java中的HashMap相类似，可以理解为value又是一组键值对。这种类型特别适合用于存储对象。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-Hash%E5%BA%95%E5%B1%82.png?raw=true)

Hash 数据结构底层实现为一个字典( dict ),也是RedisBb用来存储K-V的数据结构,当数据量比较小，或者单个元素比较小时，底层用ziplist存储，数据大小和元素数量阈值可以通过如下参数设置。 

```java
hash-max-ziplist-entries  512    //  ziplist 元素个数超过 512 ，将改为hashtable编码 
hash-max-ziplist-value    64      //  单个元素大小超过 64 byte时，将改为hashtable编码
```

### ②.Hash类型的两种实现方式

+ ziplist 编码的[哈希](https://so.csdn.net/so/search?q=哈希&spm=1001.2101.3001.7020)对象使用压缩列表作为底层实现。
+ hashtable 编码的哈希对象使用字典作为底层实现。

### ③.ziplist 编码作为底层实现

ziplist 编码的哈希对象使用压缩列表作为底层实现， 每当有新的键值对要加入到哈希对象时，程序会先将保存了键的压缩列表节点推入到压缩列表表尾， 然后再将保存了值的压缩列表节点推入到压缩列表表尾。

因此保存了同一键值对的两个节点总是紧挨在一起， 保存键的节点在前， 保存值的节点在后；先添加到哈希对象中的键值对会被放在压缩列表的表头方向，而后来添加到哈希对象中的键值对会被放在压缩列表的表尾方向。

例如， 我们执行以下 HSET 命令，

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-Hash%E4%BD%BF%E7%94%A8set%E5%91%BD%E4%BB%A4.png?raw=true)

student 键的值对象使用的是 ziplist 编码

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-Hash%E5%BA%95%E5%B1%82%E7%BB%93%E6%9E%84.png?raw=true)

另一方面，hashtable编码的哈希对象使用字典作为底层实现，哈希对象中的每个键值对都使用一个字典键值对来保存:
字典的每个键都是一个字符串对象，对象中保存了键值对的键;
字典的每个值都是一个字符串对象，对象中保存了键值对的值。
举个例子，如果前面profile键创建的不是ziplist编码的哈希对象，而是hashtable编码的哈希对象，那么这个哈希对象应该会是下图的样子。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-Hash%E5%BA%95%E5%B1%8201.png?raw=true)

编码转换
当哈希对象可以同时满足以下两个条件时，哈希对象使用ziplist编码:
    哈希对象保存的所有键值对的键和值的字符串长度都小于64字节;
    哈希对象保存的键值对数量小于512个;
不能满足这两个条件的哈希对象需要使用hashtable编码。第一个条件可以通过配置文件中的 set-max-intset-entries 进行修改

# 三、List

## 3.1、介绍

List是一个有序(按加入的时序排序)的数据结构，Redis采用quicklist（双端链表） 和 ziplist 作为List的底层实现。

可以通过设置每个ziplist的最大容量，quicklist的数据压缩范围，提升数据存取效率

+ list-max-ziplist-size  -2        //  单个ziplist节点最大能存储  8kb  ,超过则进行分裂,将数据存储在新的ziplist节点中。

+ list-compress-depth  1        //  0 代表所有节点，都不进行压缩，1， 代表从头节点往后走一个，尾节点往前走一个不用压缩，其他的全部压缩，2，3，4 ... 以此类推。

## 3.2、常用命令

## 3.3、应用场景

## 3.4、底层原理

### 1.zipList实现

#### ①.压缩列表zipList实现的列表对象

```c++
robj *createZiplistObject(void) {
    unsigned char *zl = ziplistNew();
    robj *o = createObject(OBJ_LIST,zl);
    o->encoding = OBJ_ENCODING_ZIPLIST;
    return o;
}
unsigned char *ziplistNew(void) {
    unsigned int bytes = ZIPLIST_HEADER_SIZE+ZIPLIST_END_SIZE;
    unsigned char *zl = zmalloc(bytes);
    ZIPLIST_BYTES(zl) = intrev32ifbe(bytes);
    ZIPLIST_TAIL_OFFSET(zl) = intrev32ifbe(ZIPLIST_HEADER_SIZE);
    ZIPLIST_LENGTH(zl) = 0;
    zl[bytes-1] = ZIP_END;
    return zl;
}

```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-zipList%E5%AE%9E%E7%8E%B0.png?raw=true)

压缩列表(zipList)是Redis为了节省内存而开发的，是由一系列特殊编码的连续内存块组成的顺序型[数据结构](https://so.csdn.net/so/search?q=数据结构&spm=1001.2101.3001.7020)，一个压缩列表可以包含任意多个节点（entry），每个节点可以保存一个字节数组或者一个整数值，如图：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-zipList%E7%BB%93%E6%9E%84.png?raw=true)

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-zipList%E7%BB%93%E6%9E%84%E7%9A%84%E5%8F%82%E6%95%B0%E8%A7%A3%E9%87%8A.png?raw=true)

压缩列表的每个节点Entry构成如下：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-zipList%E7%9A%84Entity%E7%BB%93%E6%9E%84.png?raw=true)

+ **previous_entry_ength**：<font color='red'>以字节为单位，记录了压缩列表中前一个字节的长度。</font>利用此原理即当前节点位置减去上一个节点的长度即得到上一个节点的起始位置，压缩列表可以从尾部向头部遍历，这么做很有效地减少了内存的浪费。

+ **encoding**：<font color='red'>记录了节点的 content 属性所保存数据的类型以及长度。</font>

+ **content**：<font color='red'>保存节点的值，节点的值可以是一个字节数组或者整数，值的类型和长度由节点的 encoding 属性决定。</font>

#### ②.ZipList的优缺点

+ 压缩列表ziplist结构本身就是一个连续的内存块，由表头、若干个entry节点和压缩列表尾部标识符zlend组成，通过一系列编码规则，提高内存的利用率，使用于存储整数和短字符串。
+ 压缩列表ziplist结构的缺点是：每次插入或删除一个元素时，都需要进行频繁的调用realloc()函数进行内存的扩展或减小，然后进行数据”搬移”，甚至可能引发连锁更新，造成严重效率的损失。

#### ③.ZipList整体实现

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-ZipList%E6%95%B4%E4%BD%93%E5%AE%9E%E7%8E%B0.png?raw=true)

+ zlbytes：32bit，表示ziplist占用的字节总数。

+ zltail：32bit，表示ziplist表中最后一项（entry）在ziplist中的偏移字节数。通过zltail我们可以很方便地找到最后一项，从而可以在ziplist尾端快速地执行push或pop操作。
+ zlen: 16bit，表示ziplist中数据项（entry）的个数。
+ entry：表示真正存放数据的数据项，长度不定
+ zlend: ziplist最后1个字节，是一个结束标记，值固定等于255。
+ prerawlen: 前一个entry的数据长度。
+ len: entry中数据的长度
+ data: 真实数据存储

**代码实现：**

```c++
robj *createZiplistObject(void) {
    unsigned char *zl = ziplistNew();
    robj *o = createObject(OBJ_LIST,zl);
    o->encoding = OBJ_ENCODING_ZIPLIST;
    return o;
}
unsigned char *ziplistNew(void) {
    unsigned int bytes = ZIPLIST_HEADER_SIZE+ZIPLIST_END_SIZE;
    unsigned char *zl = zmalloc(bytes);
    ZIPLIST_BYTES(zl) = intrev32ifbe(bytes);
    ZIPLIST_TAIL_OFFSET(zl) = intrev32ifbe(ZIPLIST_HEADER_SIZE);
    ZIPLIST_LENGTH(zl) = 0;
    zl[bytes-1] = ZIP_END;
    return zl;
}
robj *createObject(int type, void *ptr) {
    robj *o = zmalloc(sizeof(*o));
    o->type = type;
    o->encoding = OBJ_ENCODING_RAW;
    o->ptr = ptr;
    o->refcount = 1;
    if (server.maxmemory_policy & MAXMEMORY_FLAG_LFU) {
        o->lru = (LFUGetTimeInMinutes()<<8) | LFU_INIT_VAL;  
    } else {
        o->lru = LRU_CLOCK();   // 获取 24bit 当前时间秒数
    }
    return o;
}
```



### 2.LinkedList

 双端链表(LinkedList)实现的列表对象：

链表是一种常用的数据结构，C 语言内部是没有内置这种数据结构的实现，所以Redis自己构建了链表的实现。链表节点定义：

```c++
/* Node, List, and Iterator are the only data structures used currently. */
typedef struct listNode {
    struct listNode *prev;
    struct listNode *next;
    void *value;
} listNode;
```

多个 listNode 可以通过 prev 和 next 指针组成双端链表，结构如下:

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-%E5%8F%8C%E7%AB%AF%E9%93%BE%E8%A1%A8%E7%9A%84%E5%AE%9E%E7%8E%B0.png?raw=true)

 另外提供了操作链表的list结构:

```c++
typedef struct list {
    listNode *head; //表头节点
    listNode *tail; //表尾节点
    void *(*dup)(void *ptr); //链表所包含的节点数量
    void (*free)(void *ptr); //节点值释放函数
    int (*match)(void *ptr, void *key); //节点值对比函数
    unsigned long len;
} list;
```

list结构为链表提供了表头指针 head ，表尾指针 tail 以及链表长度计数器 len ，dup、free、match 成员则是用于实现多态链表所需的类型特定函数。

**Redis链表实现的特性：**

+ **双端**：链表节点带有 prev 和 next 指针，获取某个节点的前置节点和后置节点复杂度都是O(1)。

+ **无环**：表头节点的 prev 指针和表尾节点的 next 指针都指向 NULL，对链表的访问以NULL为终点。

+ **带表头指针和表尾指针**：通过list结构的 head 和 tail 指针，程序获取链表的表头节点和表尾结点的复杂度都是O(1)。

+ **带链表长度计数器**：程序使用 list 结构的 len属性对 list持有的链表节点进行计数，程序获取链表中节点数量的复杂度为O(1)。

+ **多态**：链表节点使用 void* 指针来保存节点值，并且通过 list 结构的 dup、 free、match 三个属性为节点值设置类型特定函数，所以链表可以用于保存各种不同类型的值。

ziplist 与 linkedlist 之间存在着一种编码转换机制，当列表对象可以同时满足下列两个条件时，列表对象采用ziplist编码，否则采用linkedlist编码：

1. 列表对象保存的所有字符串元素的长度都小于64字节；

2. 列表元素保存的元素数量小于512个；

以上两个条件的上限值可以在配置文件中修改 list-max-ziplist-value 选项和 list-max-ziplist-entries 选项 。

另外对于使用 ziplist 编码的列表对象，当以上两个条件中任何一个不能满足时，对象的编码转换操作就会执行，原本保存在压缩列表里面的所有列表元素都会被转移并保存到双端链表里面，对象的编码也从 ziplist 变为 linkedlist 。

### 3.quickList实现

#### ①.介绍

quicklist是由ziplist组成的双向链表，链表中的每一个节点都以压缩列表ziplist的结构保存着数据，而ziplist有多个entry节点，保存着数据。相当于一个quicklist节点保存的是一片数据，而不再是一个数据。

例如：一个quicklist有4个quicklist节点，每个节点都保存着1个ziplist结构，每个ziplist的大小不超过8kb，ziplist的entry节点中的value成员保存着数据。

#### ②.quickList原理

quicklist宏观上是一个双向链表，因此，它具有一个双向链表的优点，进行插入或删除操作时非常方便，虽然复杂度为O(n)，但是不需要内存的复制，提高了效率，而且访问两端元素复杂度为O(1)。
quicklist微观上是一片片entry节点，每一片entry节点内存连续且顺序存储，可以通过二分查找以 log2(n)log2(n) 的复杂度进行定位。
总体来说，quicklist给人的感觉和B树每个节点的存储方式相似。

```c++
typedef struct quicklist {
    //指向头部（最左边）quicklist节点的指针
    quicklistNode *head;
    //指向尾部（最右边）quicklist节点的指针
    quicklistNode *tail;
    //ziplist中的entry节点计数器
    unsigned long count;        /* total count of all entries in all ziplists */
    //quicklist的quicklistNode节点计数器
    unsigned long len;          /* number of quicklistNodes */
    //保存ziplist的大小，配置文件设定，占16bits
    int fill : QL_FILL_BITS;              /* fill factor for individual nodes */
    //保存压缩程度值，配置文件设定，占16bits，0表示不压缩
    unsigned int compress : QL_COMP_BITS; /* depth of end nodes not to compress;0=off */
    unsigned int bookmark_count: QL_BM_BITS;
    quicklistBookmark bookmarks[];
} quicklist;
```

在quicklist表头结构中，有两个成员是fill和compress，其中” : “是位域运算符，表示fill占int类型32位中的16位，compress也占16位。

fill和compress的配置文件是redis.conf。

**fill成员对应的配置：list-max-ziplist-size -2**

当数字为负数，表示以下含义：
-1 每个quicklistNode节点的ziplist字节大小不能超过4kb。（建议）
-2 每个quicklistNode节点的ziplist字节大小不能超过8kb。（默认配置）
-3 每个quicklistNode节点的ziplist字节大小不能超过16kb。（一般不建议）
-4 每个quicklistNode节点的ziplist字节大小不能超过32kb。（不建议）
-5 每个quicklistNode节点的ziplist字节大小不能超过64kb。（正常工作量不建议）
当数字为正数，表示：ziplist结构所最多包含的entry个数。最大值为 215215。

**compress成员对应的配置：list-compress-depth 0**
后面的数字有以下含义：
0 表示不压缩。（默认）
1 表示quicklist列表的两端各有1个节点不压缩，中间的节点压缩。
2 表示quicklist列表的两端各有2个节点不压缩，中间的节点压缩。
3 表示quicklist列表的两端各有3个节点不压缩，中间的节点压缩。
以此类推，最大为 216216。

```c++
typedef struct quicklistNode {
    //前阶段指针
    struct quicklistNode *prev;
    //后节点指针
    struct quicklistNode *next;
    //数据指针。当前节点的数据没有压缩，那么它指向一个ziplist结构；否则，指向一个quicklistLZF结构
    unsigned char *zl;
    //zl指向的ziplist实际占用内存大小。需要注意的是：如果ziplist被压缩了，那么这个sz的值仍然是压缩的。
    unsigned int sz; 
    //ziplist里面包含的数据项的个数
    unsigned int count : 16;    
    //ziplist是否压缩。取值1--ziplist 2--quicklist
    unsigned int encoding : 2;    
    //存储类型，目前使用固定值2表示使用ziplist存储
    unsigned int container : 2;  
    //当我们使用累死lindex这样命令查看了某一项本来压缩的数据时，需要吧数据暂时解压，这时就设置recompress=1做一个标记，等有机会再进行重新压缩
    unsigned int recompress : 1; 
    unsigned int attempted_compress : 1; 
    unsigned int extra : 10;  
} quicklistNode;

```

**quicklist结构图：**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-quicklist%E5%8E%9F%E7%90%86.png?raw=true)

### 4.总结

#### ①.双端链表

1. 双端链表便于在表的两端进行 push 和 pop 操作，但是它的内存开销比较大；

2. 双端链表每个节点上除了要保存数据之外，还要额外保存两个指针；

3. 双端链表的各个节点是单独的内存块，地址不连续，节点多了容易产生内存碎片；

#### ②.压缩列表

1. ziplist 由于是一整块连续内存，所以存储效率很高；

2. ziplist 不利于修改操作，每次数据变动都会引发一次内存的 realloc；

3. 当 ziplist 长度很长的时候，一次 realloc 可能会导致大批量的数据拷贝，进一步降低性能；

#### ③.quickList

1. 空间效率和时间效率的折中；

2. 结合了双端链表和压缩列表的优点；

# 四、Set集合

## 4.1、介绍

Set 为无序的，自动去重的集合数据类型，Set 数据结构底层实现为一个value 为 null 的 字典( dict ),当数据可以用整形表示时，Set集合将被编码为intset数据结构。

两个条件任意满足时Set将用hashtable存储数据：

+ 元素个数大于 set-max-intset-entries     // intset 能存储的最大元素个数，超过则用hashtable编码

+ 元素无法用整形表示 

## 4.2、常用命令

## 4.3、应用场景

## 4.4、底层原理

### 1.set底层存储

redis的[集合](https://so.csdn.net/so/search?q=集合&spm=1001.2101.3001.7020)对象set的底层存储结构特别神奇，我估计一般人想象不到，底层使用了intset和hashtable两种数据结构存储的，intset我们可以理解为数组，hashtable就是普通的哈希表（key为set的值，value为null）。是不是觉得用hashtable存储set是一件很神奇的事情。

 set的底层存储intset和hashtable是存在编码转换的，使用**intset**存储必须满足下面两个条件，否则使用hashtable，条件如下：

- 结合对象保存的所有元素都是整数值
- 集合对象保存的元素数量不超过512个

 hashtable的[数据结构](https://so.csdn.net/so/search?q=数据结构&spm=1001.2101.3001.7020)应该在前面的hash的章节已经介绍过了，所以这里着重讲一下**intset**这个新的数据结构好了。

### 2.intset的数据结构

intset内部其实是一个[数组](https://so.csdn.net/so/search?q=数组&spm=1001.2101.3001.7020)（int8_t coentents[]数组），而且存储数据的时候是有序的，因为在查找数据的时候是通过二分查找来实现的。

```c++
typedef struct intset { 
    // 编码方式
    uint32_t encoding;
    // 集合包含的元素数量
    uint32_t length;
    // 保存元素的数组
    int8_t contents[];
} intset;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-Set%E4%B9%8Bintset%E6%95%B0%E6%8D%AE%E7%BB%93%E6%9E%84.png?raw=true)

### 3.Redis中Set的存储过程

以set的sadd命令为例子，整个添加过程如下：

- 检查set是否存在不存在则创建一个set结合。
- 根据传入的set集合一个个进行添加，添加的时候需要进行内存压缩。
- setTypeAdd执行set添加过程中会判断是否进行编码转换。

```c++
void saddCommand(redisClient *c) {
    robj *set;
    int j, added = 0;
    // 取出集合对象
    set = lookupKeyWrite(c->db,c->argv[1]);
    // 对象不存在，创建一个新的，并将它关联到数据库
    if (set == NULL) {
        set = setTypeCreate(c->argv[2]);
        dbAdd(c->db,c->argv[1],set);
    // 对象存在，检查类型
    } else {
        if (set->type != REDIS_SET) {
            addReply(c,shared.wrongtypeerr);
            return;
        }
    }
    // 将所有输入元素添加到集合中
    for (j = 2; j < c->argc; j++) {
        c->argv[j] = tryObjectEncoding(c->argv[j]);
        // 只有元素未存在于集合时，才算一次成功添加
        if (setTypeAdd(set,c->argv[j])) added++;
    }
    // 如果有至少一个元素被成功添加，那么执行以下程序
    if (added) {
        // 发送键修改信号
        signalModifiedKey(c->db,c->argv[1]);
        // 发送事件通知
        notifyKeyspaceEvent(REDIS_NOTIFY_SET,"sadd",c->argv[1],c->db->id);
    }
    // 将数据库设为脏
    server.dirty += added;
    // 返回添加元素的数量
    addReplyLongLong(c,added);
}
```

稍微深入分析一下set的单个元素的添加过程，首先如果已经是hashtable的编码，那么我们就走正常的hashtable的元素添加，如果原来是intset的情况，那么我们就需要进行如下判断：

- 如果能够转成int的对象（isObjectRepresentableAsLongLong），那么就用intset保存。

- 如果用intset保存的时候，如果长度超过512（REDIS_SET_MAX_INTSET_ENTRIES）就转为hashtable编码。

- 其他情况统一用hashtable进行存储。

- ```c++
  /*
   * 多态 add 操作
   *
   * 添加成功返回 1 ，如果元素已经存在，返回 0 。
   */
  int setTypeAdd(robj *subject, robj *value) {
      long long llval;
      // 字典
      if (subject->encoding == REDIS_ENCODING_HT) {
          // 将 value 作为键， NULL 作为值，将元素添加到字典中
          if (dictAdd(subject->ptr,value,NULL) == DICT_OK) {
              incrRefCount(value);
              return 1;
          }
      // intset
      } else if (subject->encoding == REDIS_ENCODING_INTSET) {
          // 如果对象的值可以编码为整数的话，那么将对象的值添加到 intset 中
          if (isObjectRepresentableAsLongLong(value,&llval) == REDIS_OK) {
              uint8_t success = 0;
              subject->ptr = intsetAdd(subject->ptr,llval,&success);
              if (success) {
                  // 添加成功
                  // 检查集合在添加新元素之后是否需要转换为字典
                  // #define REDIS_SET_MAX_INTSET_ENTRIES 512
                  if (intsetLen(subject->ptr) > server.set_max_intset_entries)
                      setTypeConvert(subject,REDIS_ENCODING_HT);
                  return 1;
              }
          // 如果对象的值不能编码为整数，那么将集合从 intset 编码转换为 HT 编码
          // 然后再执行添加操作
          } else {
              setTypeConvert(subject,REDIS_ENCODING_HT);
   
              redisAssertWithInfo(NULL,value,dictAdd(subject->ptr,value,NULL) == DICT_OK);
              incrRefCount(value);
              return 1;
          }
      // 未知编码
      } else {
          redisPanic("Unknown set encoding");
      }
      // 添加失败，元素已经存在
      return 0;
  }
  ```

# 五、ZSet有序集合

## 5.1、常用命令

+ zadd(key, score, member)：向名称为key的zset中添加元素member，score用于排序。如果该元素已经存在，则根据score更新该元素的顺序；
+ zrem(key, member) ：删除名称为key的zset中的元素member；
+ zincrby(key, increment, member) ：如果在名称为key的zset中已经存在元素member，则该元素的score增加increment；否则向集合中添加该元素，其score的值为increment；
+ zrank(key, member) ：返回名称为key的zset（元素已按score从小到大排序）中member元素的rank（即index，从0开始），若没有member元素，返回“nil”；
+ zrevrank(key, member) ：返回名称为key的zset（元素已按score从大到小排序）中member元素的rank（即index，从0开始），若没有member元素，返回“nil”；
+ zrange(key, start, end)：返回名称为key的zset（元素已按score从小到大排序）中的index从start到end的所有元素；
+ zrevrange(key, start, end)：返回名称为key的zset（元素已按score从大到小排序）中的index从start到end的所有元素；
+ zrangebyscore(key, min, max)：返回名称为key的zset中score >= min且score <= max的所有元素 zcard(key)：返回名称为key的zset的基数；
+ zscore(key, element)：返回名称为key的zset中元素element的score zremrangebyrank(key, min, max)：删除名称为key的zset中rank >= min且rank <= max的所有元素 zremrangebyscore(key, min, max) ：删除名称为key的zset中score >= min且score <= max的所有元素；

## 5.2、应用场景

## 5.3、底层原理

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-zset-ziplist.png?raw=true)

### 1.Zset编码的选择

有序集合对象的编码可以是ziplist或者skiplist。

同时满足以下条件时使用ziplist编码：

+ 元素数量小于128个
+ 所有member的长度都小于64字节
+ **其他：**
  不能满足上面两个条件的使用 skiplist 编码。以上两个条件也可以通过Redis配置文件zset-max-ziplist-entries 选项和 zset-max-ziplist-value 进行修改
  对于一个 REDIS_ENCODING_ZIPLIST 编码的 Zset， 只要满足以上任一条件， 则会被转换为 REDIS_ENCODING_SKIPLIST 编码。

### 2.介绍

<font color='red'>ziplist 编码的 Zset 使用紧挨在一起的压缩列表节点来保存，第一个节点保存 member，第二个保存 score。</font>ziplist 内的集合元素按 score 从小到大排序，其实质是一个双向链表。虽然元素是按 score 有序排序的， 但对 ziplist 的节点指针只能线性地移动，所以在 REDIS_ENCODING_ZIPLIST 编码的 Zset 中， 查找某个给定元素的复杂度为 O(N)。

**添加测试数据：**

```c++
//操作
ZADD price 8.5 apple 5.0 banana 6.0 cherry
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-ZSet%E5%86%85%E9%83%A8%E7%BB%93%E6%9E%84.png?raw=true)

**从以上的布局中，我们可以看到ziplist内存数据结构，由如下5部分构成：**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-ZSet%E4%B8%ADziplist%E6%95%B0%E6%8D%AE%E7%BB%93%E6%9E%84%E6%9E%84%E6%88%90.png?raw=true)

各个部分在内存上是前后相邻的并连续的，每一部分作用如下：

+ zlbytes： 存储一个无符号整数，固定四个字节长度（32bit），用于存储压缩列表所占用的字节（也包括<zlbytes>本身占用的4个字节），当重新分配内存的时候使用，不需要遍历整个列表来计算内存大小。

+ zltail： 存储一个无符号整数，固定四个字节长度（32bit），表示ziplist表中最后一项（entry）在ziplist中的偏移字节数。<zltail>的存在，使得我们可以很方便地找到最后一项（不用遍历整个ziplist），从而可以在ziplist尾端快速地执行push或pop操作。

+ zllen： 压缩列表包含的节点个数，固定两个字节长度（16bit）， 表示ziplist中数据项（entry）的个数。由于zllen字段只有16bit，所以可以表达的最大值为2^16-1。

  注意点：如果ziplist中数据项个数超过了16bit能表达的最大值，ziplist仍然可以表示。ziplist是如何做到的？

  如果<zllen>小于等于2^16-2（也就是不等于2^16-1），那么<zllen>就表示ziplist中数据项的个数；否则，也就是<zllen>等于16bit全为1的情况，那么<zllen>就不表示数据项个数了，这时候要想知道ziplist中数据项总数，那么必须对ziplist从头到尾遍历各个数据项，才能计数出来。

+ entry：表示真正存放数据的数据项，长度不定。一个数据项（entry）也有它自己的内部结构。

+ zlend： ziplist最后1个字节，值固定等于255，其是一个结束标记。

### 3.SkipList

#### ①.介绍

<font color='red'>skiplist 编码的 Zset 底层为一个被称为 zset 的结构体，这个结构体中包含一个字典和一个跳跃表。</font>跳跃表按 score 从小到大保存所有集合元素，查找时间复杂度为平均 O(logN)，最坏 O(N) 。字典则保存着从 member 到 score 的映射，这样就可以用 O(1)的复杂度来查找 member 对应的 score 值。

虽然同时使用两种结构，但它们会通过指针来共享相同元素的 member 和 score，因此不会浪费额外的内存。

#### ②.详解

跳表(skip List)是一种随机化的数据结构，基于并联的链表，实现简单，插入、删除、查找的复杂度均为O(logN)。简单说来跳表也是链表的一种，只不过它在链表的基础上增加了跳跃功能，正是这个跳跃的功能，使得在查找元素时，跳表能够提供O(logN)的时间复杂度。

1. 先来看一个有序链表，如下图（最左侧的灰色节点表示一个空的头结点）：

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-skiplist01.png?raw=true)

   在这样一个链表中，如果我们要查找某个数据，那么需要从头开始逐个进行比较，直到找到包含数据的那个节点，或者找到第一个比给定数据大的节点为止（没找到）。也就是说，时间复杂度为O(n)。同样，当我们要插入新数据的时候，也要经历同样的查找过程，从而确定插入位置。

2. 假如我们每相邻两个节点增加一个指针，让指针指向下下个节点，如下图：

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-skiplist02.png?raw=true)

   这样所有新增加的指针连成了一个新的链表，但它包含的节点个数只有原来的一半（上图中是7, 19, 26）。现在当我们想查找数据的时候，可以先沿着这个新链表进行查找。当碰到比待查数据大的节点时，再回到原来的链表中进行查找。比如，我们想查找23，查找的路径是沿着下图中标红的指针所指向的方向进行的：
   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-skiplist03.png?raw=true)

   - 23首先和7比较，再和19比较，比它们都大，继续向后比较。
   - 但23和26比较的时候，比26要小，因此回到下面的链表（原链表），与22比较。
   - 23比22要大，沿下面的指针继续向后和26比较。23比26小，说明待查数据23在原链表中不存在，而且它的插入位置应该在22和26之间。

   在这个查找过程中，由于新增加的指针，我们不再需要与链表中每个节点逐个进行比较了。需要比较的节点数大概只有原来的一半。

3. 利用同样的方式，我们可以在上层新产生的链表上，继续为每相邻的两个节点增加一个指针，从而产生第三层链表。如下图：

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-skiplist04.png?raw=true)

   在这个新的三层链表结构上，如果我们还是查找23，那么沿着最上层链表首先要比较的是19，发现23比19大，接下来我们就知道只需要到19的后面去继续查找，从而一下子跳过了19前面的所有节点。可以想象，当链表足够长的时候，这种多层链表的查找方式能让我们跳过很多下层节点，大大加快查找的速度。

   skiplist正是受这种多层链表的想法的启发而设计出来的。实际上，按照上面生成链表的方式，上面每一层链表的节点个数，是下面一层的节点个数的一半，这样查找过程就非常类似于一个二分查找，使得查找的时间复杂度可以降低到O(log n)。但是，这种方法在插入数据的时候有很大的问题。新插入一个节点之后，就会打乱上下相邻两层链表上节点个数严格的2:1的对应关系。如果要维持这种对应关系，就必须把新插入的节点后面的所有节点（也包括新插入的节点）重新进行调整，这会让时间复杂度重新蜕化成O(n)。删除数据也有同样的问题。

4. skiplist为了避免这一问题，它不要求上下相邻两层链表之间的节点个数有严格的对应关系，而是为每个节点随机出一个层数(level)。比如，一个节点随机出的层数是3，那么就把它链入到第1层到第3层这三层链表中。为了表达清楚，下图展示了如何通过一步步的插入操作从而形成一个skiplist的过程：
   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-skiplist05.png?raw=true)

   从上面skiplist的创建和插入过程可以看出，每一个节点的层数（level）是随机出来的，而且新插入一个节点不会影响其它节点的层数。因此，插入操作只需要修改插入节点前后的指针，而不需要对很多节点都进行调整。这就降低了插入操作的复杂度。实际上，这是skiplist的一个很重要的特性，这让它在插入性能上明显优于平衡树的方案。这在后面我们还会提到。

   skiplist，指的就是除了最下面第1层链表之外，它会产生若干层稀疏的链表，这些链表里面的指针故意跳过了一些节点（而且越高层的链表跳过的节点越多）。这就使得我们在查找数据的时候能够先在高层的链表中进行查找，然后逐层降低，最终降到第1层链表来精确地确定数据位置。在这个过程中，我们跳过了一些节点，从而也就加快了查找速度。

5. 刚刚创建的这个skiplist总共包含4层链表，现在假设我们在它里面依然查找23，下图给出了查找路径：

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/Redis-skiplist06.png?raw=true)

   需要注意的是，前面演示的各个节点的插入过程，实际上在插入之前也要先经历一个类似的查找过程，在确定插入位置后，再完成插入操作。

   实际应用中的skiplist每个节点应该包含key和value两部分。前面的描述中我们没有具体区分key和value，但实际上列表中是按照key(score)进行排序的，查找过程也是根据key在比较。

   执行插入操作时计算随机数的过程，是一个很关键的过程，它对skiplist的统计特性有着很重要的影响。这并不是一个普通的服从均匀分布的随机数，它的计算过程如下：

   首先，每个节点肯定都有第1层指针（每个节点都在第1层链表里）。
   如果一个节点有第i层(i>=1)指针（即节点已经在第1层到第i层链表中），那么它有第(i+1)层指针的概率为p。
   节点最大的层数不允许超过一个最大值，记为MaxLevel。

   这个计算随机层数的伪码如下所示：

   ```c++
   randomLevel()
   level := 1
   // random()返回一个[0...1)的随机数
   while random() < p and level < MaxLevel do
   level := level + 1
   return level
   ```

   randomLevel()的伪码中包含两个参数，一个是p，一个是MaxLevel。在Redis的skiplist实现中，这两个参数的取值为：

   ```c++
   p = 1/4
   MaxLevel = 32
   ```

#### ③.skiplist与平衡树、哈希表的比较

+ skiplist和各种平衡树（如AVL、红黑树等）的元素是有序排列的，而哈希表不是有序的。因此，在哈希表上只能做单个key的查找，不适宜做范围查找。所谓范围查找，指的是查找那些大小在指定的两个值之间的所有节点。
+ 在做范围查找的时候，平衡树比skiplist操作要复杂。在平衡树上，我们找到指定范围的小值之后，还需要以中序遍历的顺序继续寻找其它不超过大值的节点。如果不对平衡树进行一定的改造，这里的中序遍历并不容易实现。而在skiplist上进行范围查找就非常简单，只需要在找到小值之后，对第1层链表进行若干步的遍历就可以实现。
+ 平衡树的插入和删除操作可能引发子树的调整，逻辑复杂，而skiplist的插入和删除只需要修改相邻节点的指针，操作简单又快速。
  从内存占用上来说，skiplist比平衡树更灵活一些。一般来说，平衡树每个节点包含2个指针（分别指向左右子树），而skiplist每个节点包含的指针数目平均为1/(1-p)，具体取决于参数p的大小。如果像Redis里的实现一样，取p=1/4，那么平均每个节点包含1.33个指针，比平衡树更有优势。
+ 查找单个key，skiplist和平衡树的时间复杂度都为O(log n)，大体相当；而哈希表在保持较低的哈希值冲突概率的前提下，查找时间复杂度接近O(1)，性能更高一些。所以我们平常使用的各种Map或dictionary结构，大都是基于哈希表实现的。
+ 从算法实现难度上来比较，skiplist比平衡树要简单得多。

#### ④.Redis中的skiplist实现

```c++
#define ZSKIPLIST_MAXLEVEL 32
#define ZSKIPLIST_P 0.25
 
typedef struct zskiplistNode {
robj *obj;
double score;
struct zskiplistNode *backward;
struct zskiplistLevel {
struct zskiplistNode *forward;
unsigned int span;
} level[];
} zskiplistNode;
 
typedef struct zskiplist {
struct zskiplistNode *header, *tail;
unsigned long length;
int level;
} zskiplist;
```

简单分析一下几个查询命令：

+ zrevrank由数据查询它对应的排名，这在前面介绍的skiplist中并不支持。
+ zscore由数据查询它对应的分数，这也不是skiplist所支持的。
+ zrevrange根据一个排名范围，查询排名在这个范围内的数据。这在前面介绍的skiplist中也不支持。
+ zrevrangebyscore根据分数区间查询数据集合，是一个skiplist所支持的典型的范围查找（score相当于key，数据相当于value）。

实际上，Redis中sorted set的实现是这样的：

+ 当数据较少时，sorted set是由一个ziplist来实现的。
+ 当数据多的时候，sorted set是由一个dict + 一个skiplist来实现的。简单来讲，dict用来查询数据到分数的对应关系，而skiplist用
+ 根据分数查询数据（可能是范围查找）。

看一下sorted set与skiplist的关系：

+ zscore的查询，不是由skiplist来提供的，而是由那个dict来提供的。
+ 为了支持排名(rank)，Redis里对skiplist做了扩展，使得根据排名能够快速查到数据，或者根据分数查到数据之后，也同时很容易获得排名。而且，根据排名的查找，时间复杂度也为O(log n)。
+ zrevrange的查询，是根据排名查数据，由扩展后的skiplist来提供。
+ zrevrank是先在dict中由数据查到分数，再拿分数到skiplist中去查找，查到后也同时获得了排名。

**总结起来，Redis中的skiplist跟前面介绍的经典的skiplist相比，有如下不同：**

+ 分数(score)允许重复，即skiplist的key允许重复。这在最开始介绍的经典skiplist中是不允许的。
+ 在比较时，不仅比较分数（相当于skiplist的key），还比较数据本身。在Redis的skiplist实现中，数据本身的内容唯一标识这份数据，而不是由key来唯一标识。另外，当多个元素分数相同的时候，还需要根据数据内容来进字典排序。
+ 第1层链表不是一个单向链表，而是一个双向链表。这是为了方便以倒序方式获取一个范围内的元素。
+ 在skiplist中可以很方便地计算出每个元素的排名(rank)。

#### ⑤.Redis为什么用skiplist而不用平衡树？

这里从内存占用、对范围查找的支持和实现难易程度这三方面总结的原因。

There are a few reasons:
1. They are not very memory intensive. It’s up to you basically. Changing parameters about the probability of a node to have a given number of levels will make then less memory intensive than btrees.

   也不是非常耗费内存，实际上取决于生成层数函数里的概率 p，取决得当的话其实和平衡树差不多。

2. A sorted set is often target of many ZRANGE or ZREVRANGE operations, that is, traversing the skip list as a linked list. With this operation the cache locality of skip lists is at least as good as with other kind of balanced trees.

   因为有序集合经常会进行 ZRANGE 或 ZREVRANGE 这样的范围查找操作，跳表里面的双向链表可以十分方便地进行这类操作。

3. They are simpler to implement, debug, and so forth. For instance thanks to the skip list simplicity I received a patch (already in Redis master) with augmented skip lists implementing ZRANK in O(log(N)). It required little changes to the code.

   实现简单，ZRANK 操作还能达到 o(logn)的时间复杂度O
   

# 六、bitmap位图

# 七、Redis Stream

# 八、HyperLogLog






部分引用原文链接：

https://blog.csdn.net/weixin_37545216/article/details/122095110

https://blog.csdn.net/weixin_37545216/article/details/122114840

https://blog.csdn.net/lele52080/article/details/102546304

https://www.jianshu.com/p/28138a5371d0

https://blog.csdn.net/weichi7549/article/details/107335133
