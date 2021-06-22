---
title: "Redis入门"
date: 2021-06-15
draft: false
toc: true
categories: ["学习笔记"]
tags: ["Redis"]
---

NoSQL方便扩展, 因为不像关系型数据库中的数据, 互相之间会有关联. 性能搞, 而且数据类型多种多样, 不用提前设计. Redis代表Remote Dictionary Server. 可以用内存存储/持久化(rdb/aof), 效率高, 集成发布订阅系统, 有计时器和计数器. 有多重数据类型, 支持集群/事务. 

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


1. [Redis最新超详细版教程通俗易懂-狂神说Java](https://www.bilibili.com/video/BV1S54y1R7SB)