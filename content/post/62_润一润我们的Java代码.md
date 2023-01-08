---
title: "润一润我们的Java代码"
date: 2021-08-15
draft: false
author: "小拳头"
categories: ["Tech"]
tags: ["Java"]
---

作为一个代码强迫症加代码外貌协会, 写代码的时候总会想提高代码可读性, 不管性能怎么样, 至少要长得好看. 后来又看到有推友的mentor说: "来, 让我润一下你的代码", 被戳中了笑点, 于是就有了这个标题. 对于新手来说, 想一下就写出诗一样的代码是几乎不可能的事, 但是在一定的规范下, 却可以让无论谁写的代码都可以被轻松地理解, 去限制过度个性化, 但又不消灭创造性和优雅性, 提高协同工作的效率, **维护同事之间深厚的友谊**. 于是乎, 我花了将近一周的午休时间刷了一遍Java开发手册嵩山版. 在此记录一下重点内容. 

开发手册有强制/推荐/参考三大类, 其中几乎所有的强制的内容我认为是Java程序员都应该遵守的, 而推荐和参考的内容可以根据自己项目的具体情况使用, 在我自己的这篇博客中不做区分.

## 编程规约
- **杜绝完全不规范的缩写, 避免望文不知义.** 比如desc, 是MySQL的降序关键字, 如果把description也这样缩写, 会引起歧义
- **在常量与变量的命名时, 表示类型的名词放在词尾, 以提升辨识度.** startTime/workQueue/nameList
- **对于Service和DAO类, 基于SOA的理念, 暴露出来的服务一定是接口, 内部的实现类用Impl的后缀与接口区别.** CacheServiceImpl实现CacheService
- **Dao层方法: 单个对象的方法用get做前缀/取多个对象的方法用list做前缀, 复数结尾/获取统计值的方法用count做前缀/插入的方法用 insert做前缀/删除的方法用remove, delete做前缀/修改的方法用update做前缀**
- **不允许任何魔法值直接出现在代码中.** 实际开发中, 有时候还是会见到魔法值, 比如加个括号, 我有时候还是会写魔法值, 但是都会加上相应的注释
- **注释的双斜线与注释内容之间有且仅有一个空格.** 这一点每个人习惯不同, 我觉得把双斜线和文字分开, 在视觉上会更加清晰
- **在进行类型强制转换时，右括号与强制转换值之间不需要任何空格隔开.** `int second = (int)first + 2;`
- **单行字符数限制不超过120个.** 一行写很长的代码会让人很痛苦
- **单个方法的总行数不超过80行.** 把各种逻辑写一起, 不光不好读, 写`try-catch`, 写`ut`的时候也会哭
- **避免通过一个类的对象引用访问此类的静态变量或静态方法, 无谓增加编译器解析成本**
- **Object的equals方法容易抛空指针异常.** JDK7引入`java.util.Objects#equals(Object a, Object b)`, 完美解决NPE.
- **BigDecimal的等值比较应使用`compareTo()`方法, 而不是`equals()`方法.** `equals()`会比较精度, 造成误解
- 构造方法`BigDecimal(double)`存在精度损失风险.** 用`BigDecimal(String)`. 
- 所有的POJO类属性必须使用包装数据类型, RPC方法的返回值和参数必须使用包装数据类型.

### 日期时间
- **正确的时间格式`new SimpleDateFormat("yyyy-MM-dd HH:mm:ss")`.** YYYY代表week in which year, 每周默认从周日开始, 周六结束. 
- **获取当前毫秒数:`System.currentTimeMillis();`.** 
- **不允许在程序任何地方中使用:java.sql.Date/java.sql.Time/java.sql.Timestamp**, 在jdk8可能引发错误

### 集合
- **在使用`java.util.stream.Collectors`类的toMap()方法转为Map集合时, 一定要使用含有参数类型为BinaryOperator, 参数名为mergeFunction的方法, 否则当出现相同key值时会抛出IllegalStateException**. 注意value为null时会抛NPE.
```
Map<String, Double> map = pairArrayList.stream().collect(
    Collectors.toMap(Pair::getKey, Pair::getValue, (v1, v2) -> v2));
```

- **在使用Collection接口任何实现类的addAll()方法时, 都要对输入的集合参数进行NPE判断**
- **使用entrySet遍历Map类集合KV, 而不是keySet方式进行遍历**, 前者效率高, 而JDK8直接使用`Map.forEach`

### 流程控制
- **当switch括号内的变量类型为String并且此变量为外部参数时, 必须先进行null判断**, 且必须包含default.
- **if-else不超过三层**, 改为用卫语句/策略模式/状态模式.
- 逻辑判断的结果赋值给一个有意义的布尔变量名, 以提高可读性

### 注释
- 所有的抽象方法(包括接口中的方法)必须要用Javadoc注释
- 方法内部单行注释, 在被注释语句上方另起一行, 使用//注释
- 谨慎注释掉代码, 在上方详细说明, 而不是简单地注释掉, 如果无用(后期不需要恢复此逻辑),则删除

### 前后端
- 对于需要使用超大整数的场景, 服务端一律使用String字符串类型返回, 禁止使用Long类型
- 在翻页场景中, 用户输入参数的小于1, 则前端返回第一页参数给后端. 后端发现用户输入的参数大于总页数, 直接返回最后一页
- 服务器内部重定向必须使用forward, 外部重定向地址必须使用URL统一代理模块生成, 否则会因线上采用HTTPS协议而导致浏览器提示"不安全", 并且还会带来URL维护不一致的问题

### 其他
- 不要在视图模板中加入任何复杂的逻辑

## MySQL规范
### 建表规约
- 表名/字段名必须使用小写字母或数字, 禁止出现数字开头, 禁止两个下划线中间只出现数字
- **表达是与否概念的字段, 必须用`is_XXX`命名, 数据类型是unsigned tinyint**. 
- 主键索引名为pk_字段, ;唯一索引名为uk_字段名, 普通索引名则为idx_字段名
- **表必备三字段: id, create_time, update_time.** id为主键, 类型为bitint. 时间都是datatime类型, 现在是表示主动式创建, 过去分词表示被动式更新

### 索引规约
- 业务上具有唯一特性的字段, 即使是组合字段, 也必须建成唯一索引
- 页面搜索严禁左模糊或者全模糊, 如果需要请走搜索引擎来解决
- 超过三个表禁止join, 多表关联查询时, 保证被关联的字段需要有索引
- 页面搜索严禁左模糊或者全模糊，如果需要请走搜索引擎来解决

### SQL语句
- 不要使用count(列名)或count(常量)来替代count(*), 这是SQL92标准
- count(distinct col)计算该列除NULL之外的不重复行数, 注意count(distinct col1, col2)如果其中一列全为NULL, 那么即使另一列有不同的值, 也返回为0
- 当某一列的值全是NULL时，count(col)的返回结果为0, 但sum(col)的返回结果为NULL, 因此使用 sum()时需注意NPE问题\
- SQL语句中表的别名前加as, 并且以 t1/t2/t3...的顺序依次命名

### ORM映射
- **一律不要使用*作为查询的字段列表, 需要哪些字段必须明确写明**
- **POJO类的布尔属性不能加is, 而数据库字段必须加is_**, POJO类有is, 在前端解析时会造成歧义 

> 在idea中可以安装Alibaba Java Coding Guidelines, 时刻检查代码规约

## 参考
1. Java开发手册嵩山版