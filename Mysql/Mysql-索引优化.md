# 一、Explain工具

使用EXPLAIN关键字可以模拟优化器执行SQL语句，分析你的查询语句或是结构的性能瓶颈。

在 select 语句之前增加 explain 关键字，MySQL 会在查询上设置一个标记，执行查询会返回执行计划的信息，而不是执行这条SQL。

注意：如果 from 中包含子查询，仍会执行该子查询，将结果放入临时表中。

```mysql
示例表： 
DROP TABLE IF EXISTS `actor`; 
CREATE TABLE `actor` ( 
`id` int(11) NOT NULL, 
`name` varchar(45) DEFAULT NULL, 
`update_time` datetime DEFAULT NULL, 
PRIMARY KEY (`id`) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8; 
INSERT INTO `actor` (`id`, `name`, `update_time`) VALUES (1,'a','2017‐12‐22 15:27:18')
                                                        , (2,'b','2017‐12‐22 15:27:18')
                                                        , (3,'c','2017‐12‐22 15:27:18');
DROP TABLE IF EXISTS `film`; 
CREATE TABLE `film` (`id` int(11) NOT NULL AUTO_INCREMENT, 
                     `name` varchar(10) DEFAULT NULL, 
                     PRIMARY KEY (`id`), 
                     KEY `idx_name` (`name`) 
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8; 
INSERT INTO `film` (`id`, `name`) VALUES (3,'film0'),(1,'film1'),(2,'film2'); 
DROP TABLE IF EXISTS `film_actor`; 
CREATE TABLE `film_actor` ( 
    `id` int(11) NOT NULL, 
    `film_id` int(11) NOT NULL, 
    `actor_id` int(11) NOT NULL, 
    `remark` varchar(255) DEFAULT NULL, 
    PRIMARY KEY (`id`), 
    KEY `idx_film_actor_id` (`film_id`,`actor_id`) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8; 
INSERT INTO `film_actor` (`id`, `film_id`, `actor_id`) VALUES (1,1,1),(2,1,2),(3,2,1);
```

```mysql
mysql> explain select * from actor;
```

![img]()

在查询中的每个表会输出一行，如果有两个表通过 join 连接查询，那么会输出两行。

## 1.1、Explain两个变种

### 1.explain extended

explain extended会在 explain 的基础上额外提供一些查询优化的信息。紧随其后通过 show warnings 命令可以得到优化后的查询语句，从而看出优化器优化了什么。额外还有 filtered 列，是一个半分比的值，rows * filtered/100 可以**估算**出将要和 explain 中前一个表进行连接的行数（前一个表指 explain 中的id值比当前表id值小的表）。

```mysql
mysql> explain extended select * from film where id = 1;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-explain%E6%9F%A5%E8%AF%A2.png?raw=true)

```mysql
mysql> show warnings;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-showwarnings.png?raw=true)

### 2.explain partitions

相比 explain 多了 partitions 字段，如果查询是基于分区表的话，会显示查询将访问的分区。

## 1.2、Explain属性列

### 1.id列

+ id列的编号是 select 的序列号，有几个 select 就有几个id，并且id的顺序是按 select 出现的顺序增长的。 

+ id列越大执行优先级越高，id相同则从上往下执行，id为NULL最后执行。

### 2.select_type列

select_type 表示对应行是简单还是复杂的查询。 

#### ①.simple

简单查询。查询不包含子查询和union。

```mysql
mysql> explain select * from film where id = 2;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-selectType%E5%88%9701.png?raw=true)

#### ②.primary

复杂查询中最外层的 select 。

#### ③.subquery

包含在 select 中的子查询（不在 from 子句中） 

#### ④.derived

包含在 from 子句中的子查询。MySQL会将结果存放在一个临时表中，也称为派生表（derived的英文含义）。

用这个例子来了解 primary、subquery 和 derived 类型：

```mysql
mysql> set session optimizer_switch='derived_merge=off'; #关闭mysql5.7新特性对衍生表的合 并优化 
mysql> explain select (select 1 from actor where id = 1) from (select * from film where id = 1) der;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-selectType%E5%88%9702.png?raw=true)

```mysql
mysql> set session optimizer_switch='derived_merge=on'; #还原默认配置
```

#### ⑤.union

在 union 中的第二个和随后的 select。

```mysql
explain select 1 union all select 1;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-selectType%E5%88%9703.png?raw=true)

### 3.table列 

这一列表示 explain 的一行正在访问哪个表。 

当 from 子句中有子查询时，table列是 <derivenN> 格式，表示当前查询依赖 id=N 的查询，于是先执行 id=N 的查询。

当有 union 时，UNION RESULT 的 table 列的值为<union1,2>，1和2表示参与 union 的 select 行id。 

### 4.type列

这一列表示**关联类型或访问类型**，即MySQL决定如何查找表中的行，查找数据行记录的大概范围。 

依次从最优到最差分别为：**system > const > eq_ref > ref > range > index > ALL** 

一般来说，**得保证查询达到range级别，最好达到ref**。

#### ①.NULL

mysql能够在优化阶段分解查询语句，在执行阶段用不着再访问表或索引。

例如：在索引列中选取最小值，可以单独查找索引来完成，不需要在执行时访问表。

```mysql
mysql> explain select min(id) from film;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-selectType%E5%88%9701.png?raw=true)

#### ②.system

**system是const的特例**，表里只有一条元组匹配时为system。

#### ③.const

mysql能对查询的某部分进行优化并将其转化成一个常量（可以看show warnings 的结果）。

用于 primary key 或 unique key 的所有列与常数比较时，所以表最多有一个匹配行，读取1次，速度比较快。

```mysql
mysql> explain extended select * from (select * from film where id = 1) tmp;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-type%E5%88%9702.png?raw=true)

```mysql
mysql> show warnings;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-type%E5%88%9703.png?raw=true)

#### ④.eq_ref

primary key 或 unique key 索引的所有部分被连接使用 ，最多只会返回一条符合条件的记录。

这可能是在 const 之外最好的联接类型了，简单的 select 查询不会出现这种 type。 

```mysql
mysql> explain select * from film_actor left join film on film_actor.film_id = film.id
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-type%E5%88%9704.png?raw=true)

#### ⑤.ref

相比 eq_ref，<font color='red'>不使用唯一索引，而是使用普通索引或者唯一性索引的部分前缀，索引要和某个值相比较，可能会找到多个符合条件的行。</font>

1. 简单 select 查询，name是普通索引（非唯一索引）。

   ```mysql
   mysql> explain select * from film where name = 'film1';
   ```

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-type%E5%88%9705.png?raw=true)

2. 关联表查询，idx_film_actor_id是film_id和actor_id的联合索引，这里使用到了film_actor的左边前缀film_id部分。

   ```mysql
   mysql> explain select film_id from film left join film_actor on film.id = film_actor.fi lm_id;
   ```

   ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-type%E5%88%9706.png?raw=true)

#### ⑥.range

范围扫描通常出现在 in()，between、> 、< 、>= 等操作中。使用一个索引来检索给定范围的行。 

```mysql
 mysql> explain select * from actor where id > 1;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-type%E5%88%9707.png?raw=true)

#### ⑦.index

扫描全索引就能拿到结果，一般是扫描某个二级索引，这种扫描不会从索引树根节点开始快速查找，而是直接对二级索引的叶子节点遍历和扫描，速度还是比较慢的。

这种查询一般为使用覆盖索引，二级索引一般比较小，所以这种通常比ALL快一些。

```mysql
mysql> explain select * from film;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-type%E5%88%9708.png?raw=true)

#### ⑧.ALL

即全表扫描，扫描你的聚簇索引的所有叶子节点。通常情况下这需要增加索引来进行优化。

```mysql
mysql> explain select * from actor;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-type%E5%88%9709.png?raw=true)

### 5.possible_keys列 

<font color='red'>这一列显示查询可能使用哪些索引来查找。</font>

explain 时可能出现 possible_keys 有列，而 key 显示 NULL 的情况，这种情况是因为表中数据不多，mysql认为索引对此查询帮助不大，选择了全表查询。 

如果该列是NULL，则没有相关的索引。在这种情况下，可以通过检查 where 子句看是否可以创造一个适当的索引来提高查询性能，然后用 explain 查看效果。 

### 6.key列

<font color='red'>这一列显示mysql实际采用哪个索引来优化对该表的访问。 </font>

如果没有使用索引，则该列是 NULL。如果想强制mysql使用或忽视possible_keys列中的索引，在查询中使用 force index、ignore index。 

### 7.key_len列

<font color='red'>这一列显示了mysql在索引里使用的字节数，通过这个值可以算出具体使用了索引中的哪些列。 </font>

举例来说，film_actor的联合索引 idx_film_actor_id 由 film_id 和 actor_id 两个int列组成，并且每个int是4字节。通过结果中的key_len=4可推断出查询使用了第一个列：film_id列来执行索引查找。 

```mysql
mysql> explain select * from film_actor where film_id = 2;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-keylen%E5%88%9701.png?raw=true)

key_len计算规则如下： 

+ 字符串，char(n)和varchar(n)，5.0.3以后版本中，**n均代表字符数，而不是字节数，**如果是utf-8，一个数字或字母占1个字节，一个汉字占3个字节。
  + char(n)：如果存汉字长度就是 3n 字节
  + varchar(n)：如果存汉字则长度是 3n + 2 字节，加的2字节用来存储字符串长度，因为 varchar是变长字符串。 

+ 数值类型
  + tinyint：1字节 
  + smallint：2字节 
  + int：4字节 
  + bigint：8字节 

+ 时间类型
  + date：3字节
  + timestamp：4字节 
  + datetime：8字节 

+ 如果字段允许为 NULL，需要1字节记录是否为 NULL。

<font color='red'>索引最大长度是768字节，当字符串过长时，mysql会做一个类似左前缀索引的处理，将前半部分的字符提取出来做索引。</font>

### 8.ref列

<font color='red'>这一列显示了在key列记录的索引中，表查找值所用到的列或常量，</font>常见的有：const（常量），字段名（例：film.id）

### 9.rows列

<font color='red'>这一列是mysql估计要读取并检测的行数</font>，注意这个不是结果集里的行数。 

### 10.Extra列 

<font color='red'>这一列展示的是额外信息</font>。常见的重要值如下： 

#### ①.Using index

使用覆盖索引。

**覆盖索引定义**：

mysql执行计划explain结果里的key有使用索引，如果select后面查询的字段都可以从这个索引的树中获取，这种情况一般可以说是用到了覆盖索引，extra里一般都有using index。

覆盖索引一般针对的是辅助索引，整个查询结果只通过辅助索引就能拿到结果，不需要通过辅助索引树找到主键，再通过主键去主键索引树里获取其它字段值。（也就是Using index 就不需要回表）

```mysql
1 mysql> explain select film_id from film_actor where film_id = 1;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-usingindex01.png?raw=true)

#### ②.Using where

使用 where 语句来处理结果，并且查询的列未被索引覆盖。

```mysql
mysql> explain select * from actor where name = 'a';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-usingwhere01.png?raw=true)

#### ③.Using index condition

查询的列不完全被索引覆盖，where条件中是一个前导列的范围。

```mysql
mysql> explain select * from film_actor where film_id > 1;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-usingcondition01.png?raw=true)

#### ④.Using temporary

mysql需要创建一张临时表来处理查询。出现这种情况一般是要进行优化的，首先是想到用索引来优化。

+ actor.name没有索引，此时创建了张临时表来distinct

  ```mysql
  1 mysql> explain select distinct name from actor;
  ```

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-usingtemporary01.png?raw=true)

+ film.name建立了idx_name索引，此时查询时extra是using index,没有用临时表 

  ```mysql
  mysql> explain select distinct name from film;
  ```

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-usingtemporary02.png?raw=true)

#### ⑤.Using filesort

将用外部排序而不是索引排序，数据较小时从内存排序，否则需要在磁盘完成排序。这种情况下一般也是要考虑使用索引来优化的。 

+ actor.name未创建索引，会浏览actor整个表，保存排序关键字name和对应的id，然后排序name并检索行记录。

  ```mysql
   mysql> explain select * from actor order by name;
  ```

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-usingfilesort01.png?raw=true)

+ film.name建立了idx_name索引,此时查询时extra是using index。

  ```mysql
   mysql> explain select * from film order by name;
  ```

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-usingfilesort02.png?raw=true)

#### ⑥.Select tables optimized away

使用某些聚合函数（比如 max、min）来访问存在索引的某个字段。

```mysql
mysql> explain select min(id) from film;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-usingfilesort03.png?raw=true)

# 二、索引优化

## 2.1、全职匹配

```mysql
 EXPLAIN SELECT * FROM employees WHERE name= 'LiLei';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%85%A8%E8%81%8C%E5%8C%B9%E9%85%8D01.png?raw=true)

```mysql
EXPLAIN SELECT * FROM employees WHERE name= 'LiLei' AND age = 22;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%85%A8%E8%81%8C%E5%8C%B9%E9%85%8D02.png?raw=true)

```mysql
EXPLAIN SELECT * FROM employees WHERE name= 'LiLei' AND age = 22 AND position ='manage r';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%85%A8%E8%81%8C%E5%8C%B9%E9%85%8D03.png?raw=true)

## 2.2、最左前缀法则

如果索引了多列，要遵守最左前缀法则。指的是查询从索引的最左前列开始并且不跳过索引中的列。 

```mysql
EXPLAIN SELECT * FROM employees WHERE name = 'Bill' and age = 31; 
EXPLAIN SELECT * FROM employees WHERE age = 30 AND position = 'dev';
EXPLAIN SELECT * FROM employees WHERE position = 'manager';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9901.png?raw=true)

## 2.3、不在索引列上做操作

**包括计算、函数、（自动or手动）类型转换，会导致索引失效而转向全表扫描。** 

```mysql
EXPLAIN SELECT * FROM employees WHERE name = 'LiLei'; 
EXPLAIN SELECT * FROM employees WHERE left(name,3) = 'LiLei';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9902.png?raw=true)

给hire_time增加一个普通索引： 

```mysql
ALTER TABLE `employees` ADD INDEX `idx_hire_time` (`hire_time`) USING BTREE ; 
EXPLAIN select * from employees where date(hire_time) ='2018‐09‐30';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9903.png?raw=true)

转化为日期范围查询，有可能会走索引： 

```mysql
EXPLAIN select * from employees where hire_time >='2018‐09‐30 00:00:00' and hire_time < ='2018‐09‐30 23:59:59';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9904.png?raw=true)

还原最初索引状态：

```mysql
ALTER TABLE `employees` DROP INDEX `idx_hire_time`;
```

## 2.4、存储引擎不能使用索引中范围条件右边的列 

```mysql
EXPLAIN SELECT * FROM employees WHERE name= 'LiLei' AND age = 22 AND position ='manage r'; 
EXPLAIN SELECT * FROM employees WHERE name= 'LiLei' AND age > 22 AND position ='manage r';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9905.png?raw=true)

## 2.5、尽量使用覆盖索引

```mysql
EXPLAIN SELECT name,age FROM employees WHERE name= 'LiLei' AND age = 23 AND position ='manager';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9906.png?raw=true)

```mysql
EXPLAIN SELECT * FROM employees WHERE name= 'LiLei' AND age = 23 AND position ='manage r';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9907.png?raw=true)

## 2.6、使用!=/</>/not in/not exists的时候无法使用索引会导致全表扫描

**<** **小于、** **>** **大于、** **<=****、****>=** **这些，mysql内部优化器会根据检索比例、表大小等多个因素整体评估是否使用索引** 

```
EXPLAIN SELECT * FROM employees WHERE name != 'LiLei';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9908.png?raw=true)

## 2.7、避免is null/is not null

```mysql
EXPLAIN SELECT * FROM employees WHERE name is null
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9909.png?raw=true)

## 2.8、like查询的优化

**以通配符开头（'$abc...'）mysql索引失效会变成全表扫描操作**

```mysql
 EXPLAIN SELECT * FROM employees WHERE name like '%Lei'
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9910.png?raw=true)

```mysql
 EXPLAIN SELECT * FROM employees WHERE name like 'Lei%'
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9911.png?raw=true)

问题：解决like'%字符串%'索引不被使用的方法？ 

+ 使用覆盖索引，查询字段必须是建立覆盖索引字段。

  ```mysql
  EXPLAIN SELECT name,age,position FROM employees WHERE name like '%Lei%';
  ```

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9912.png?raw=true)

+ 如果不能使用覆盖索引则可能需要借助搜索引擎 。

## 2.9、字符串不加单引号索引失效

```mysql
EXPLAIN SELECT * FROM employees WHERE name = '1000'; 
EXPLAIN SELECT * FROM employees WHERE name = 1000;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9913.png?raw=true)

## 2.10、少用or或in

**少用or或in，用它查询时，mysql不一定使用索引，mysql内部优化器会根据检索比例、表大小等多个因素整体评估是否使用索引，详见范围查询优化** 

```mysql
EXPLAIN SELECT * FROM employees WHERE name = 'LiLei' or name = 'HanMeimei';
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9914.png?raw=true)

## 2.11、范围查询优化

给年龄添加单值索引 

```mysql
ALTER TABLE `employees` ADD INDEX `idx_age` (`age`) USING BTREE ; 
explain select * from employees where age >=1 and age <=2000;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9915.png?raw=true)

**没走索引原因：**

mysql内部优化器会根据检索比例、表大小等多个因素整体评估是否使用索引。比如这个例子，可能是由于单次数据量查询过大导致优化器最终选择不走索引。 

**优化方法：**

可以将大的范围拆分成多个小范围。

```mysql
explain select * from employees where age >=1 and age <=1000; 
explain select * from employees where age >=1001 and age <=2000;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E6%9C%80%E5%B7%A6%E5%89%8D%E7%BC%80%E6%B3%95%E5%88%9916.png?raw=true)

还原最初索引状态：

```mysql
ALTER TABLE `employees` DROP INDEX `idx_age`;
```

## 2.12、总结

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E7%B4%A2%E5%BC%95%E6%80%BB%E7%BB%93.png?raw=true)

<font color='red'>like KK%相当于=常量，%KK和%KK% 相当于范围 </font>

```mysql
‐‐ mysql5.7关闭ONLY_FULL_GROUP_BY报错 
select version(), @@sql_mode;
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
```

# 三、分页查询优化

```mysql
--示例表： 
CREATE TABLE `employees` (  `id` int(11) NOT NULL AUTO_INCREMENT, 
                          `name` varchar(24) NOT NULL DEFAULT '' COMMENT '姓名', 
                          `age` int(11) NOT NULL DEFAULT '0' COMMENT '年龄', 
                          `position` varchar(20) NOT NULL DEFAULT '' COMMENT '职位', 
                          `hire_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入职时间', 							  PRIMARY KEY (`id`), 
                          KEY `idx_name_age_position` (`name`,`age`,`position`) USING BTREE 
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='员工记录表'; 
```

很多时候我们业务系统实现分页功能可能会用如下sql实现 

```mysql
mysql> select * from employees limit 10000,10; 
```

表示从表 employees 中取出从 10001 行开始的 10 行记录。看似只查询了 10 条记录，实际这条 SQL 是先读取 10010 条记录，然后抛弃前 10000 条记录，然后读到后面 10 条想要的数据。因此要查询一张大表比较靠后的数据，执行效率是非常低的。 

## 3.1、根据自增且连续的主键排序的分页查询

首先来看一个根据自增且连续主键排序的分页查询的例子： 

```mysql
 mysql> select * from employees limit 90000,5;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9601.png?raw=true)

该 SQL 表示查询从第 90001开始的五行数据，没添加单独 order by，表示通过**主键排序**。我们再看表 employees ，因为主键是自增并且连续的，所以可以改写成按照主键去查询从第 90001开始的五行数据，如下：

```mysql
mysql> select * from employees where id > 90000 limit 5;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9602.png?raw=true)

查询的结果是一致的。我们再对比一下执行计划：

```mysql
 mysql> EXPLAIN select * from employees limit 90000,5;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9603.png?raw=true)

```mysql
mysql> EXPLAIN select * from employees where id > 90000 limit 5;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9604.png?raw=true)

显然改写后的 SQL 走了索引，而且扫描的行数大大减少，执行效率更高。

但是，这条改写的SQL 在很多场景并不实用，因为表中可能某些记录被删后，主键空缺，导致结果不一致，如下图试验。

所示（先删除一条前面的记录，然后再测试原 SQL 和优化后的 SQL）：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9605.png?raw=true)

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9606.png?raw=true)

两条 SQL 的结果并不一样，因此，如果主键不连续，不能使用上面描述的优化方法。 

另外如果原 SQL 是 order by 非主键的字段，按照上面说的方法改写会导致两条 SQL 的结果不一致。

所以这种改写得满足以下两个条件： 

+ 主键自增且连续 

+ 结果是按照主键排序的

## 3.2、根据非主键字段排序的分页查询

再看一个根据非主键字段排序的分页查询，SQL 如下： 

```mysql
mysql> select * from employees ORDER BY name limit 90000,5;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9607.png?raw=true)

```mysql
mysql> EXPLAIN select * from employees ORDER BY name limit 90000,5;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9608.png?raw=true)

发现并没有使用 name 字段的索引（key 字段对应的值为 null）。

具体原因：**扫描整个索引并查找到没索引的行(可能要遍历多个索引树)的成本比扫描全表的成本更高，所以优化器放弃使用索引**。 

**知道不走索引的原因，那么怎么优化呢？** 

其实关键是**让排序时返回的字段尽可能少**，所以可以让排序和分页操作先查出主键，然后根据主键查到对应的记录，SQL改写如下：

```mysql
mysql> select * from employees e inner join (select id from employees order by name limit 90000,5) ed on e.id = ed.id;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9609.png?raw=true)

需要的结果与原 SQL 一致，执行时间减少了一半以上，我们再对比优化前后sql的执行计划： 

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-%E5%88%86%E9%A1%B5%E6%9F%A5%E8%AF%A2%E4%BC%98%E5%8C%9610.png?raw=true)

原 SQL 使用的是 filesort 排序，而优化后的 SQL 使用的是索引排序。 

# 四、Join查询优化

```mysql
‐‐ 示例表： 
CREATE TABLE `t1` ( `id` int(11) NOT NULL AUTO_INCREMENT, 
                    `a` int(11) DEFAULT NULL, 
                    `b` int(11) DEFAULT NULL, 
                    PRIMARY KEY (`id`), 
                    KEY `idx_a` (`a`) 
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8; 
create table t2 like t1; 
‐‐ 插入一些示例数据 
‐‐ 往t1表插入1万行记录 
drop procedure if exists insert_t1; 
delimiter ;; 
create procedure insert_t1() 
begin 
	declare i int; 
	set i=1; 
	while(i<=10000)do 
		insert into t1(a,b) values(i,i); 
        set i=i+1; 
    end while; 
end;; 
delimiter ;
call insert_t1(); 
‐‐ 往t2表插入100行记录 
drop procedure if exists insert_t2; 
delimiter ;; 
create procedure insert_t2() 
begin 
	declare i int; 
    set i=1; 
    while(i<=100)do 
    	insert into t2(a,b) 
    	values(i,i); 
        set i=i+1; 
    end while; 
end;; 
delimiter ; 
call insert_t2();
```

**mysql的表关联常见有两种算法** 

+ Nested-Loop Join 算法 

+ Block Nested-Loop Join 算法 

## 4.1、嵌套循环连接 Nested-Loop Join(NLJ) 算法 

一次一行循环地从第一张表（称为**驱动表**）中读取行，在这行数据中取到关联字段，根据关联字段在另一张表（**被驱动表**）里取出满足条件的行，然后取出两张表的结果合集。 

```mysql
mysql> EXPLAIN select * from t1 inner join t2 on t1.a= t2.a;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-join%E4%BC%98%E5%8C%9601.png?raw=true)

从执行计划中可以看到这些信息： 

+ 驱动表是 t2，被驱动表是 t1。先执行的就是驱动表(执行计划结果的id如果一样则按从上到下顺序执行sql)；优化器一般会优先选择**小表做驱动表**。**所以使用 inner join 时，排在前面的表并不一定就是驱动表。** 

+ 当使用left join时，左表是驱动表，右表是被驱动表，当使用right join时，右表时驱动表，左表是被驱动表，当使用join时，mysql会选择数据量比较小的表作为驱动表，大表作为被驱动表。 

+ 使用了 NLJ算法。一般 join 语句中，如果执行计划 Extra 中未出现 **Using join buffer** 则表示使用的 join 算法是 NLJ。

**上面sql的大致流程如下：** 

1. 从表 t2 中读取一行数据（如果t2表有查询过滤条件的，会从过滤结果里取出一行数据）； 

2. 从第 1 步的数据中，取出关联字段 a，到表 t1 中查找； 

3. 取出表 t1 中满足条件的行，跟 t2 中获取到的结果合并，作为结果返回给客户端； 

4. 重复上面 3 步。

整个过程会读取 t2 表的所有数据(**扫描100行**)，然后遍历这每行数据中字段 a 的值，根据 t2 表中 a 的值索引扫描 t1 表中的对应行(**扫描100次 t1 表的索引，1次扫描可以认为最终只扫描 t1 表一行完整数据，也就是总共 t1 表也扫描了100行**)。因此整个过程扫描了 **200 行**。 

如果被驱动表的关联字段没索引，**使用NLJ算法性能会比较低(下面有详细解释)**，mysql会选择Block Nested-Loop Join 算法。

## 4.2、 基于块的嵌套循环连接 Block Nested-Loop Join(BNL)算法 

把**驱动表**的数据读入到 join_buffer 中，然后扫描**被驱动表**，把**被驱动表**每一行取出来跟 join_buffer 中的数据做对比。

```mysql
mysql>EXPLAIN select * from t1 inner join t2 on t1.b= t2.b;
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-join%E4%BC%98%E5%8C%9602.png?raw=true)

Extra 中 的Using join buffer (Block Nested Loop)说明该关联查询使用的是 BNL 算法。 

**上面sql的大致流程如下：** 

1. 把 t2 的所有数据放入到 **join_buffer** 中 

2. 把表 t1 中每一行取出来，跟 join_buffer 中的数据做对比 

3. 返回满足 join 条件的数据

整个过程对表 t1 和 t2 都做了一次全表扫描，因此扫描的总行数为10000(表 t1 的数据总量) + 100(表 t2 的数据总量) = **10100**。并且 join_buffer 里的数据是无序的，因此对表 t1 中的每一行，都要做 100 次判断，所以内存中的判断次数是 100 * 10000= **100 万次**。 

**这个例子里表 t2 才 100 行，要是表 t2 是一个大表，join_buffer 放不下怎么办呢？** 

join_buffer 的大小是由参数 join_buffer_size 设定的，默认值是 256k。

如果放不下表 t2 的所有数据话，策略很简单， 就是**分段放**。 

比如 t2 表有1000行记录， join_buffer 一次只能放800行数据，那么执行过程就是先往 join_buffer 里放800行记录，然后从 t1 表里取数据跟 join_buffer 中数据对比得到部分结果，然后清空 join_buffer ，再放入 t2 表剩余200行记录，再次从 t1 表里取数据跟 join_buffer 中数据对比。所以就多扫了一次 t1 表。 

**被驱动表的关联字段没索引为什么要选择使用 BNL 算法而不使用 Nested-Loop Join 呢？**

+ 如果上面第二条sql使用 Nested-Loop Join，那么扫描行数为 100 * 10000 = 100万次，这个是**磁盘扫描**。 

+ 很显然，用BNL磁盘扫描次数少很多，相比于磁盘扫描，BNL的内存计算会快得多。 

+ 因此MySQL对于被驱动表的关联字段没索引的关联查询，一般都会使用 BNL 算法。如果有索引一般选择 NLJ 算法，有索引的情况下 NLJ 算法比 BNL算法性能更高。

**对于关联sql的优化** 

+ **关联字段加索引**，让mysql做 join 操作时尽量选择NLJ算法。

+ **小表驱动大表**，写多表连接sql时如果**明确知道**哪张表是小表可以用straight_join写法固定连接驱动方式，省去mysql优化器自己判断的时间。

+ **straight_join解释：straight_join**功能同join类似，但能让左边的表来驱动右边的表，能改表优化器对于联表查询的执行顺序。 

  比如：

  ```mysql
  select * from t2 straight_join t1 on t2.a = t1.a; 
  ```

  代表指定mysql选着 t2 表作为驱动表。 

+ **straight_join**只适用于inner join，并不适用于left join，right join。（因为left join，right join已经代表指定了表的执行顺序） 

+ 尽可能让优化器去判断，因为大部分情况下mysql优化器是比人要聪明的。使用**straight_join**一定要慎重，因为部分情况下人为指定的执行顺序并不一定会比优化引擎要靠谱。 

**对于小表定义的明确** 

在决定哪个表做驱动表的时候，应该是两个表按照各自的条件过滤，**过滤完成之后**，计算参与 join 的各个字段的总数据量，**数据量小的那个表，就是“小表”**，应该作为驱动表。 

**in和exsits优化**

原则：**小表驱动大表**，即小的数据集驱动大的数据集 

**in：**当B表的数据集小于A表的数据集时，in优于exists 

```mysql
select * from A where id in (select id from B)
```

 等价于： 

```mysql
for(select id from B){ 
	select * from A where A.id = B.id 
} 
```

**exists：**当A表的数据集小于B表的数据集时，exists优于in 

将主查询A的数据，放到子查询B中做条件验证，根据验证结果（true或false）来决定主查询的数据是否保留。

```mysql
select * from A where exists (select 1 from B where B.id = A.id) 
#等价于: 
for(select * from A){
	select * from B where B.id = A.id 
} 
#A表与B表的ID字段应建立索引 
```

1. EXISTS (subquery)只返回TRUE或FALSE,因此子查询中的SELECT * 也可以用SELECT 1替换,官方说法是实际执行时会 忽略SELECT清单,因此没有区别。
2. EXISTS子查询的实际执行过程可能经过了优化而不是我们理解上的逐条对比。
3. EXISTS子查询往往也可以用JOIN来代替，何种最优需要具体问题具体分析。

# 五、count(\*)查询优化

```mysql
‐‐ 临时关闭mysql查询缓存，为了查看sql多次执行的真实时间 
mysql> set global query_cache_size=0; 
mysql> set global query_cache_type=0; 
mysql> EXPLAIN select count(1) from employees; 
mysql> EXPLAIN select count(id) from employees; 
mysql> EXPLAIN select count(name) from employees; 
mysql> EXPLAIN select count(*) from employees;
```

**注意：以上4条sql只有根据某个字段count不会统计字段为null值的数据行**。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-count%E4%BC%98%E5%8C%9601.png?raw=true)

**四个sql的执行计划一样，说明这四个sql执行效率应该差不多：**

## 5.1、比较

+ **字段有索引：**

  <font color='red'>count(*) ≈ count(1) > count(字段) > count(主键 id)</font>

  **字段有索引，count(字段)统计走二级索引，二级索引存储数据比主键索引少，所以count(字段)>count(主键 id)。**

+ **字段无索引：**

  <font color='red'>count(*) ≈ count(1) > count(主键 id) > count(字段) </font>

  **字段没有索引count(字段)统计走不了索引， count(主键 id)还可以走主键索引，所以count(主键 id)>count(字段)。** 

count(1)跟count(字段)执行过程类似，不过count(1)不需要取出字段统计，就用常量1做统计，count(字段)还需要取出字段，所以理论上count(1)比count(字段)会快一点。 

count(*)  是例外，mysql并不会把全部字段取出来，而是专门做了优化：

+ <font color='red'>不取值，按行累加，效率很高，所以不需要用count(列名)或count(常量)来替代 count(*)。</font> 

为什么对于count(id)，mysql最终选择辅助索引而不是主键聚集索引？因为二级索引相对主键索引存储数据更少，检索性能应该更高，mysql内部做了点优化(应该是在5.7版本才优化)。

## 5.2、常见优化方法

### 1.查询mysql自己维护的总行数

对于**myisam存储引擎**的表做不带where条件的count查询性能是很高的，因为myisam存储引擎的表的总行数会被mysql存储在磁盘上，查询不需要计算。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-count%E4%BC%98%E5%8C%9602.png?raw=true)

对于**innodb存储引擎**的表mysql不会存储表的总记录行数(因为有MVCC机制，后面会讲)，查询count需要实时计算。

### 2.show table status

如果只需要知道表总行数的估计值可以用如下sql查询，性能很高

```mysql
show table status like 'employees'
```

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/mysql-count%E4%BC%98%E5%8C%9603.png?raw=true)

### 3.将总数维护到Redis里

插入或删除表数据行的时候同时维护redis里的表总行数key的计数值(用incr或decr命令)，但是这种方式可能不准，很难保证表操作和redis操作的事务一致性。

### 4.增加数据库计数表

插入或删除表数据行的时候同时维护计数表，让他们在同一个事务里操作。

