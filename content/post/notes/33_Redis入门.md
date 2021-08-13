---
title: "Redis入门"
date: 2021-06-15
draft: false
toc: true
categories: ["学习笔记"]
tags: ["Redis"]
---

NoSQL方便扩展, 因为不像关系型数据库中的数据, 互相之间会有关联. 性能高, 而且数据类型多种多样, 不用提前设计. Redis代表Remote Dictionary Server. 可以用内存存储/持久化(rdb/aof), 效率高, 集成发布订阅系统, 有计时器和计数器. 有多重数据类型, 支持集群/事务. 

> 传统的RDBMS: 有结构化组织, 有严格的一致性, 数据和关系都在单独的表中
>
> NoSql: 没有固定查询语言, 采用键值对(Redis)/列(HBase)/文档存储(MongoDb), 图形数据库(Neo4J). CAP定理和BASE. 高性能/高可用/高可扩.

## 启动
我使用的brew安装的redis, 在路径`/usr/local/etc/redis.conf`下就是redis的配置文件. 将`GENERAL`下的后台运行改为yes: `daemonize yes`. 通过`redis-server redis.conf`由配置文件启动redis, `redis-cli -p 6379`连接redis服务. 通过`set name/get name`命令做测试. 在另外一个terminal用`ps -ef|grep redis`可以看到有两个redis服务, 用`shutdown`就可以断开服务, 用`exit`退出.

可以通过`redis-benchmark`工具测试redis性能. 

## 基础知识
通过`select`可以选择数据库, `flashdb`清空当前数据库, `flashall`清空所有数据库, `keys *`查看所有key. redis默认**16个**数据库. **redis是单线程的**, 是基于内存的操作, 所以它的瓶颈在于急切内存和网络带宽, CPU不是瓶颈. 对于多线程来说, CPU会有上下文切换, 而对于内存没有上下文切换效更率好. 所以高性能服务期不应定时多线程的. *查看命令在官网文档查询即可.*

## 数据类型
### String
常用的有`append`, `strlen`等操作. 对于数字型的字符, 可以用`incr`/`decr`增减, `incrby`/`decrby`还能设置步长. `getrange key1 0 3`代表截取范围[0, 3]的4个字符, 同样也有`setrange key1 1 x`, 代表从编号1的字符开哦按时替换开始替换. `mset k1 v1 k2 v2 k3 v3`可以同时设置多个值. `getset`表示先get, 再set. 
- setex: set with expire, eg. `setex key3 30 "hello"`
- setnx: set if not expire, 分布式锁中常常使用, eg. `getex key4 "hello"`
- ttl: time to live

模拟对象的getter/setter操作:
```
mset user:1:name zhangsan user:1:age 2
mget user:1:name user:1:age
```

### List
`lpush`在头部添加值, `rpush`在尾部添加值, 用`lrange list 0 -1`可以查看所有值. 相对应的`lpop/rpop`就是移除头部/尾部元素的命令. 而`lindex`可以查看某个index的值, `llen`取list的长度. 
- `lrem list 2 one`: 移除list中2个值为one的元素
- `ltrim list 1 2`: 截取元素[1, 2]两个元素
- `rpoplpush list1 list2`: 将list1的最后元素, 移动到list2 
- `linsert list before "world" "hello"`: 在list的world前插入hello, 也通过after可以往后插

可以看出实际上list是一个链表.

### Set
`sadd`添加元素, `srem`移除元素, 查看是否有元素`sismember set1 hello`, 查看所有元素`smembers`. `scard`获取set元素个数. `sdiff`取差集, `sinter`取交集, `sunion`取并集. 
- `srandmember set1 2`: 所以抽选2个元素
- `spop`: 随机删除元素
- `smove set1 set2 "hello"`: 把set1中的hello移动到set2

### Hash
`hset hash1 field1 value`设置值, `hmset`设置多个值, `hmget`获取多个值, `hgetall`获取所有值. `hdel`删除指定的key, `hlen`取hash大小, `hexists`判断key是否存在. `hkeys/hvals`h获取所有的key/value.
- `hincrby hash1 field3 1`: hash1的field3增加1
- `hsetnx hash1 field3 hello`: 有key field3则set, 没有则设置不成功

和String操作很类似, 只是key是用Hash实现的, 所以**对象的存储用hash更加适合, 而String适合String本身的存储**.

### Zset
有序集合. 加三段数据:
```
zadd salary 2500 a
zadd salary 5000 b
zadd salary 500 c
```

从小到大显示全部`zrangebyscore salary -inf +inf`, 加上withscores代表附带成绩. eg. 显示工资小于2500的员工并升序: `zrangebyscore salary -inf 2500`, `zrem`移除, `zcard`获取有序集合中的个数. `zrevrange salary 0 -1`从大到小排序, `zcount`获取指定区间的成员数量. 

### 其他
- Geospatial: 地理空间. 可以把经度纬度和名称添加到key中, eg. `GEOADD cars -115.17087 36.12306 my-car`
- Hyperloglog: 基数统计. 计算一个集合中不重复元素的值, 可能有误差. 

## 事务
**Redis单台命令保证原子性, 但是不保证原子性**. Redis没也有隔离级别概念. 用`multi`开启事务, `exec`执行事务, `discard`取消事务. 如果在事务中用了错误的命令, 所有的命令都不会被执行. 但如果是运行时错误, 其他命令会执行, 只有运行错误的命令不执行, 比如`incr k1`, 而k1是一个字符. 

## 乐观锁
回顾一下乐观的含义: 认为什么时候都不会出问题, 不会做什么都加锁. 而是在更新数据的时候判断一下, 在此期间室友该数据被人修改过. 所以需要获取version/比较version. 在redis就用`watch`去监视一个值, 如果当前事务修改了这个值, 那么另外一个事务就无法再次修改这个值. 通过`unwatch`停止监视. 

## Jedis
maven导入
```
<dependency>
    <groupId>redis.clients</groupId>
    <artifactId>jedis</artifactId>
    <version>3.6.1</version>
</dependency>
```
先new一个Jedis对象, 然后这个对象下的方法就是redis的所有指令.
```
public class TestPing {
    public static void main(String[] args) {
        //1.new Jedis对象
        Jedis jedis = new Jedis("127.0.0.1", 6379);
        //2.jedis的方法包含所有指令
        System.out.println(jedis.ping());
    }
}
```


1. [Redis-狂神说Java](https://www.bilibili.com/video/BV1S54y1R7SB)