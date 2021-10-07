---
title: "MySQL-高级"
date: 2020-11-17
draft: false
toc: true
categories: ["WEB开发"]
tags: ["MySQL"]
---

## 回顾
### 性能下降原因
1. 查询写的不好
2. 索引失效(单值, 符合)
3. 关联查询过多join
4. 服务器调优和参数设置不合适

### SQL解析顺序
![](/4_1.png)

### 几种join
注意这种公有部分没有的情况.
```
SELECT ...
FROM A 
LEFT JOIN B ON A.key = B.key
WHERE B.key IS NULL;
```

- inner join: 只有公有
- left join/right join: 公有加主表独有
- full outer join: 全部join, MySQL不支持, 但是可以通过union left join和right join实现, union本来就可以去重, 所以交集重复不考虑

## 索引简介
类似字典, 提高搜索效率, 减少i/o. 通过索引列进行排序, 降低数据库排序成本, 减低CPU消耗.
- 单值索引: 一个索引只包含单个列, 一个表可以有多个单列索引(还有复合索引, 复合的排序顺序和声明的顺序一致)
- 唯一索引: 索引列值唯一, 允许空值

### 语法
- 创建: `CREATE [UNIQUE] INDEX indexName ON table(columnname1, columnname2...);`/`ALTER table ADD [UNIQUE] INDEX [indexName] ON (columnname1, columnname2...);`
- 删除: `DROP INDEX [indexName] ON table;`
- 查看: `SHOW INDEX FROM table;`
- 修改: `ALTER TABLE table ADD PRIMARY KEY(column_list);`/`ALTER TABLE table ADD [UNIQUE]/[INDEX]/[FULL TEXT] index_name (column_list);`: 全文索引

## MySQL索引结构
底层是B+树.

### B树
假设阶数为m, 插入的时候往叶子节点插入, 如果叶子节点的key数量等于m, 那么需要从中间key断开. key数量必须小于等于$m-1$个, 大于等于$ceil(m/2)-1$个. 所以删除时, 如果key数量不够, 需要从父节点拖一个下来.

### B+树
和B树基础一样, 但是除了叶子节点, 其他节点不存数据, 只存索引. 索引大小是子节点key的第一个值, 子节点的开头结点除外, 应该均小于父节点的第一个key. 插入类似B树, 删除时如果不满足大于等于$ceil(m/2)-1$个key的条件, 只需要将叶子节点的一个key拖过来, 在修改索引即可.

### why not hash? 
因为它对于**顺序(order by)/范围查询(大于/小于)**性能会非常差, 没有多值索引那样的情况了, 导致全表扫描降低性能. 而b+树能保证能够保证数据按照键的顺序存储, 只需要查找某个范围的值就可以了. 

### why not BST?
磁盘里的数据加载到内存中的时候, 是以页为单位来加载的, 像之前操作系统中是用的linux0.11为4kb. 对于BST, 每个节点所在的页是不连续的, 所以会一直进行磁盘寻址的操作. 而对于b树/b+树, 一个节点可以存放多个元素, 磁盘寻址操作就会减小. 因为内存速度是很快的, 所以即使b树/b+树看似比BST的比较次数更多, 但是磁盘操作次数少, 所以b树/b+树还是更快. 进而, 在设计的时候也倾向于让树的高度越小越好, 减少磁盘i/o.

### why not B-tree? 
首先, B树和B+树最大的区别就是一个在节点上存数据, 一个只在叶子节点存数据. 那么在用B树查找时, 会进行很多局部的中序遍历, 因为顺序的数据可能存储在不同层的节点上, 而对于B+树, 因为数据都在叶子节点上, 并且叶子节点构成有序的链表, 所以只要找到查找数据的首尾, 就能通过链表找到所有的数据.

### 用/不用?
用:
- 主键自动建立唯一索引
- 频繁所谓查询条件
- 查询与其他相连字段, 外键关系建立索引
- 查询中排序的字段
- 查询中统计和分组字段

不用:
- 频繁更新(否则每次更新还要保存索引)
- 在where中用不到
- 表记录少
- 数据重复且平均分布的字段, 建立了索引用处也不大

### 性能分析
默认有**MySQL Query Optiomizer**, 去优化query, 但不一定是最优的. MySQL一般瓶颈是CPU, IO, 服务器硬件. 我们可以用`EXPLAIN`来为查询设置标记, 使MySQL返回执行计划每一步的信息. 我只写了简单的查询, 所以只有一行. 下面介绍各个表项.
![](/4_2.png)

#### id
判断执行顺序的时候, 如果有多行, 那么对于id一样的行, 执行顺序由上到下. 而对于不同id, 大的id会先被执行. 如果表名是`<derived2>`, 则对应id为`2`的衍生表.

#### select_type
- SIMPLE: 简单select查询, 不包含子查询或者UNION
- PRIMARY: 查询中包含子部分, 最外层就是PRIMARY
- SUBQUERY: 在select或where中包含子查询
- DERIVED: from列表中包含的子查询, 被MySQL递归执行, 结果放在临时表中
- UNION: UNION之后的select. 若UNION在FROM子句的子查询中, 外层select被标记为DERIVED
- UNION RESULT: 从UNION表获取结果的select

#### table
表名

#### type
性能从好到坏: system>const>eq_ref>ref>range>index>ALL
- system: 表只有一行记录(等于系统表), const的特例
- const: 通过索引一次就找到了, 用于比较primary key或unique索引. 只匹配一行数据, 所以快. (如主键在where中查询)
- eq_ref: 唯一性索引扫描, 对每个索引键只有**一条记录**与之匹配. 
- ref: 非唯一性索引扫描, 返回匹配单个值的所有行. 可能有多个符合条件的行, 是查找和扫描的结合.
- range: 只检索给定范围的行. key列显示使用了哪个索引, 一般是在where中出现了between/\</\>/in等的查询
- index: full index scan. 只遍历索引树, 通常比all快, 因为索引文件通常小于数据文件
- all: full table scan. 从硬盘中读取, 遍历全表找到匹配的行. (如果没用索引, 表上百万级别, 出现all一定要优化)

#### possible_keys/key
**possible_keys**是**理论上可能应用**到这张表的索引, 一个或多个. 而key是**实际使用**的索引, 若为NULL, 就是没有使用索引. 如果**覆盖索引**, 则只出现在key中. 

> 覆盖索引: **只访问索引的查询**, 也就是select查询的列和索引一一对应, 对应`type`是index.

#### key_len
索引中使用的字节数, 根据`key_len`计算查询中使用的索引的长度. 不损失精确度的情况下越短越好. 是索引字段最大可能的长度, 不是实际长度, 通过计算得到而不是表内搜出来的. 比如`where id = 1`和`where id = 1 and id = 2`搜出来的是一样的数据, 那么前者更好.

#### ref
这个是表头, 不是type中的ref. 表示索引的哪一列被使用, 比如`shared.t2.col1,const`, 表示使用了`shared`库中`t2`表的`col1`字段和一个常量.

#### rows
根据统计信息和索引选用情况, 估计找到所需记录所需要读取的行数. (每张表有多少行被优化器查询)

#### Extra
其他信息:
- Using filesort: MySQL对数据使用了外部的索引排序, 而不是按表内的索引顺序排序. 所以这个需要被优化. 比如对于复合索引`col1_col2_col3`, 排序时我们只用了其中一个`order by col3`.
- Using temporary: 用了临时表保存中间结果. 比如`where col1 in ('a','b','c') group by col2`, 而索引是`idx_col1_col2`, 而`group by col1, col2`就没有此问题.
- Using index: select中使用了**索引覆盖**, 有using where, 那么索引被用来执行索引键值查找. 没有则索引只是用来读取数据, 没有查找动作. 查询的列被索引覆盖, select的的数据列只用从索引中取得, 不用查询数据行
- Using where: 用了where
- Using join buffer: 用了join buffer, 连接缓存
- impossible where: where总是false, 无效
- select tables optimized away: 没有groupby情况下, 基于索引优化min/max操作
- distinct: 优化distinct, 找到第一个匹配的元组后不找了

### 避免索引失效
1. 高精度用全值匹配, 避免使用SELECT *, 否则没建索引的colume会导致全表扫描
2. 最佳左前缀法则, 不要跳过索引中的列, 否则后面也无法用索引. 如果是`const`的搜索, 跳过中间的列, 就可以看出`const`并没有和`select`的列一样多. 这里注意复合索引的每一个元素都作为`const`查询时, 即使顺序与索引不一致, 也会被优化器优化成一致的. `order by`实际上也算用到, 不会造成`filesort`, 但是顺序不能乱
3. 不在索引列上做操作(函数/计算/自动和手动的类型准换), 否则索引失效变成ALL
4. 存储引擎不能索引**范围条件**右边的列, 这个时候的`type`是`range`, 而不是更好地`ref`
5. 尽量使用覆盖索引而不是使用`select *`直接选择硬盘中的数据.
6. 避免使用不等于`!=`/`<>`无法使用索引导致ALL
7. 避免使用`is null`/`is not null`导致ALL
8. 条件是字符串时, 如果`%`在`like`右边, 相当于range类型的检索, 其他会导致索引失效. 如果非要`%`写在左边, 就只能用覆盖索引解决, 这时候就有`using index`了, type是`index`而不是`ALL`.
9. 字符串如果没有加单引号会导致索引失效('2000'和2000), 因为发生了隐式转换, 虽然查询结果是一样的
10. or会导致索引失效

> `group by`分组前通常会排序, 那么可能出现`Using temporary`.

> 为什么索引失效? 为什么最佳左前缀, 因为在b+树中, 如果是联合索引`(col1, col2)`, 只有在col1下同一个key中, col2的key才有序. 为什么范围不行, 因为范围下的`col1`互相之间不能保证`col2`下的key有序. 字符串用`like`筛选也是一样的, 只有相同前缀字母, 才能保证后面的字母有序.

## 查询截取分析
### in/exists
通常用小表驱动大表, 若A>B, 用in. 若A\<B, 用exists. 实际上具体问题具体分析.
- exist: `select * from A where exists (select 1 from B where B.id=A.id);`. 将主查询数据放到子查询做验证, 根据验证结果(TRUE/FALSE)来决定主查询数据结果是否保留.
- in: `select * from A where id in (select id from B);`.

### order by
和之前讲的一样, MySQL有FileSort(效率低)和Index(效率高)两种排序. 所以最好要按照索引最佳左前缀排序, 而且最好默认升序, 否则依然会FileSort. 

双路排序: 慢, 单路排序: 快. 但是单路排序会用更多空间, 如果**sort_buffer_size**缓冲区满了, 反而会造成更多的i/o. 也可尝试增加**max_length_for_sort_data**.

### group by
先排序后分组, 能用`where`就不用`having`. 同样也可**尝试**通过调整上面两个参数优化.

### 慢查询日志
默认不开启, 若打开, 可通过**long_query_time**设置慢查询的阈值. 
- `SHOW VARIABLES LIKE '%slow_query_log%'`查看是否开启
- `set global slow_query_log=1`开启
- `SHOW VARIABLES LIKE 'long_query_time%'`查看阈值
- `set global long_query_time=5`改变阈值, 再重新开启会话

通过日志分析工具**mysqldumpslow**可以用来分析慢查询日志. 命令是`mysqldumpslow 日志名`

## 锁机制
用`show open tables;`查看锁. 

### 表锁
偏向**MyISAM**存储引擎, 开销小, 加锁快. **MyISAM**读写锁调度是**写优先**, 不适合做主表引擎. 否则大量更新然查询很难得到锁, 一直被阻塞. 输入`show status like 'table%';`, 可以看到`Table_locks_waited`表示等待表锁的次数, 每次等待就自加1. **读锁**阻塞写不阻塞读, **写锁**阻塞读写. `select`前, MyISAM会自动加读锁, `update/delete/insert`前, 会自定加表锁. 一般不需要显示地用`lock table`命令.

默认情况下, 写锁比读锁具有更高的优先级. 当一个锁释放时, 这个锁会优先给写锁队列中等候的获取锁请求, 然后再给读锁队列中等候的获取锁请求. 所以MyISAM不适合有大量更新操作和查询操作的应用, 因为查询操作很难获得读锁, 一直阻塞.

- 读锁(共享锁): `lock table 表名 read;`, 对同一份数据, 多个读操作可以同时进行而不会互相影响. 上锁之后不能读其他没锁的表, 也不能修改自己. 其他session则可以查询上了锁的表, 但是修改会被阻塞.
- 写锁(排他锁): `lock table 表名 write;`, 当前操作没有完成前, 会阻断其他写锁和读锁. 其他session的读写都会被阻塞.
- `unlock tables`解锁.

### 行锁
偏向**InnoDB**, **InnoDB**实现了行级锁定. 对一行的更新会有锁, 导致阻塞, 直到一个session `commit`, 但是更新不同行并不影响. 读的时候, 只要某个事务没提交, 读的就是修改之前的数据. 用`show status like 'innodb_row_lock%';`, 查询行锁状态. 
- Innodb_row_lock_time_avg: 等待平均时长
- Innodb_row_lock_waits: 等待总次数
- Innodb_row_lock_time: 等待总时长

#### 行锁变表锁
当没有索引的时候, 只能全表扫描, 那么一直是表锁. 还有一种情况, 即使有索引, 但是搜索的时候把varchar的单引号漏掉了, 更新记录后导致索引失效, 行锁升级为表锁, 就算修改不同的行, 也会阻塞.

#### 间隙锁危害
用范围条件检索数据, InnoDB会给范围内的数据全部加锁, 所以就算一个数据不存在, 其他session `insert`的数据在这个范围内, 也会被阻塞.

#### 如何锁定一行
`begin;`, `select * from table where a=8 for update;`. 其他session不能操作本行, 直到锁定的行`commit`.

## 主从复制
**todo, after learning redis**

## 参考
1. [尚硅谷MySQL](https://www.bilibili.com/video/BV12b411K7Zu?p=12)
2. MySQL必知必会
3. 高性能MySQL(第三版)
4. [面试官问你B树和B+树, 就把这篇文章丢给他](https://zhuanlan.zhihu.com/p/130482609)
5. [为什么MySQL使用B+树](https://draveness.me/whys-the-design-mysql-b-plus-tree/)