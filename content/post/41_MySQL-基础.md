---
title: "MySQL-基础"
date: 2020-11-12
draft: false
toc: true
categories: ["WEB开发"]
tags: ["MySQL"]
---

## MySQL的常见命令
- 查看当前所有的数据库: `show databases;`
- 打开指定的库: `use 库名`
- 查看当前库的所有表: `show tables;`
- 查看其它库的所有表: `show tables from 库名;`
- 创建表:
```
create table 表名(
	列名 列类型,
	列名 列类型
);
```
- 查看表结构: `desc 表名;`
- 查看服务器的版本
	- 登录到mysql服务端: `select version();`
	- 没有登录到mysql服务端: `mysql --version`

## MySQL的语法规范
1. **不区分大小写**, 但建议关键字大写, 表名/列名小写
2. 每条命令最好用分号结尾
3. 注释
	- 单行注释：`# 注释文字`
	- 单行注释：`-- 注释文字`
	- 多行注释：`/* 注释文字 */`

## SQL的语言分类
- DQL(Data Query Language): 数据查询语言 select 
- DML(Data Manipulate Language): 数据操作语言, insert/update/delete
- DDL(Data Define Languge): 数据定义语言, 操作库create/drop/alter
- TCL(Transaction Control Language): 事务控制语言commit/rollback

## DQL语言的学习
### 基础查询
```
SELECT 要查询的东西
FROM 表名;
```

### 条件查询
根据条件过滤原始表的数据, 查询到想要的数据. 常量就是选什么出什么, 列的数量手机原列长. 函数包括之前的`VERSION()`, `LENGTH()`等. 可以用`as`起别名(做题的时候基本都要别名), `DISTINCT`去重.
```
SELECT 
	要查询的字段|表达式|常量值|函数
FROM 
	表
WHERE 
	条件;
```

- 条件表达式: `salary>10000`. 条件运算符有`> < >= <= = != <>`. 用`IS`可以判断`NULL`或`NOT NULL`.
- 逻辑表达式: `salary  >10000 && salary<20000`. 逻辑运算符有`AND(&&) OR(||) NOT(!)`.

> `+`号只能进行数值运算, 字符能转就转, 否则为0. 连接字符用``CONCAT(A, B, C)``. 如果某一项为`NULL`, 可以用`ISNULL(A, 0)`, 用`0`替换`NULL`.

条件查询包括模糊查询比如`last_name LIKE '_a%'`. 其中的`%`表示0个或多个字符, `_`表示一个字符. 可以用`\`转义, 也可以在后面加`ESCAPE `转义, 比如`ESCAPE $`, 代表`$`替代`\`代表转义字符. 

用`WHERE BETWEEN 100 and 120`, 相当于大于等于左边的值, 小于等于右边的值, 所以这两个值顺序不能颠倒.

用`IN (IT_PROT, AD_VP)`代表判断字段的值是否属于列表的某一项.

### 排序查询
```
SELECT
	要查询的东西
FROM
	表
WHERE 
	条件
ORDER BY 排序的字段|表达式|函数|别名 ASC|DESC
```
这里如果不写`ASC`或`DESC`就默认升序. `ORDER BY`放在最后, `LIMIT`之前.

### 常见函数
#### 单行函数
1. 字符函数: concat拼接, substr截取子串, upper转换成大写, lower转换成小写, trim去前后指定的空格和字符, trim去左边空格, rtrim去右边空格, replace替换, lpad左**填充**(不是添加), rpad右填充, instr返回子串第一次出现的索引, length获取字节个数.
2. 数学函数: round四舍五入, rand随机数, floor向下取整, ceil向上取整, mod取余, truncate截断, 参数指保留小数点的位数.
3. 日期函数, now当前系统日期+时间, curdate当前系统日期, curtime当前系统时间, str_to_date将字符转换成日期
, date_format将日期转换成字符. 取月份: `MONTH(NOW())`, 系统时间`NOW()`, 判断日期差`SELECT DATEDIFF(NOW(), '1995-1-1');`. 
4. 流程控制函数: if处理双分支, `IF(条件, 真, 假)`, case处理多分支(可以直接放条件的值). `SELECT salary CASE WHEN salary>20000 THEN 'A' ... ELSE...ß END`. 
5. 其他: version版本, database当前库, user当前连接用户. 

#### 分组函数
sum求和, max最大值, min最小值, avg平均值, count计数.
> 这五个分组函数都忽略null值，除了count(*)/sum/avg一般用于处理数值. max/min/count可以处理任何数据类型. 都可以搭配distinct使用, 统计去重后的结果.
> count支持字段/\*/常量值, 一般放1(但一般用\*)

### 分组查询
```
select 查询的字段, 分组函数
from 表
group by 分组的字段
```
	
1. 可以按单个字段分组
2. 和分组函数一同查询的字段最好是分组后的字段
3. 分组筛选: 分组前筛选: `原始表 group by的前面 where` , 分组后筛选: `分组后的结果集 group by的后面 having`, `having`的东西本来就不在表中, 所以不能用`where`替代.
4. 可以按多个字段分组, 字段之间用逗号隔开
5. 可以支持排序
6. having后可以支持别名

### 多表连接查询
#### 通过join关键字实现连接
其中`cross`是全连接, 连接也可用`where`直接写条件, 但是推荐用`join`.
```
select 字段, ...
from 表1
[inner|left outer|right outer|cross] join 表2 on 连接条件
[inner|left outer|right outer|cross] join 表3 on 连接条件
[where 筛选条件]
[group by 分组字段]
[having 分组后的筛选条件]
[order by 排序的字段或表达式]
```

#### 自连接
比如查询员工名和直接上级的名称, 利用别名把一个表当成两个表操作.
```
	SELECT e.last_name,m.last_name
	FROM employees e
	JOIN employees m ON e.`manager_id`=m.`employee_id`;
```

### 子查询
在一条查询语句中又嵌套了另一条完整的select语句, 其中被嵌套的select语句就是子查询或内查询. 而在外面的查询语句叫主查询或外查询.

特点:
1. 子查询都放在小括号内.
2. 子查询可以放在from后/select后/where后/having后, 一般放在条件的右侧. 对于`from`来说, 相当于直接从新的表中进行选择, 所以必须要用这个表的话, 必须用别名.
3. 子查询优先于主查询执行, 主查询使用了子查询的执行结果.
4. 放在`exists`后也叫**相关子查询**, 一般和主查询有关, 加到`where`后面做进一步筛选.

### 进阶8：分页查询
```
select 字段|表达式,...
from 表
[where 条件]
[group by 分组字段]
[having 条件]
[order by 排序的字段]
limit [起始的条目索引, ] 条目数;
```
1. 起始条目索引从0开始
2. limit子句放在查询语句的最后

### 进阶9：联合查询
```
select 字段|常量|表达式|函数 [from 表] [where 条件] union [all]
select 字段|常量|表达式|函数 [from 表] [where 条件] union [all]
select 字段|常量|表达式|函数 [from 表] [where 条件] union [all]
.....
select 字段|常量|表达式|函数 [from 表] [where 条件]
```
1. 多条查询语句的查询的列数必须一致, 列的类型**最好**相同(不同也不会报错), 列名默认是第一条查询
2. `union`代表去重, `union all`代表不去重

## DML语言
### 插入
``
insert into 表名(字段名1, 字段名2, ...)
values(值1, 值2, ...);
``
1. 字段类型和值类型一致或兼容, 而且一一对应
2. 为空的字段, 可以不写字段名, 或用null填充
3. 不可以为空的字段, 必须插入值
4. value可以有多个, 用逗号隔开
5. 如果省略字段就会但默认使用所有字段, 并且顺序和表中的存储顺序一致

### 修改
修改单表语法:
```
update 表名 set 字段=新值, 字段=新值
[where 条件];
```
修改多表语法:
```
update 表1 别名1, 表2 别名2
[表1 join 表2 on ...]
set 字段=新值, 字段=新值
where 连接条件
and 筛选条件;
```

### 删除
#### delete语句 
单表:
```
delete from 表名 [where 筛选条件];
```
多表:
```
delete 别名1, 别名2
from 表1 别名1, 表2 别名2[join on]
where 连接/筛选条件
and 筛选条件;
```

#### truncate语句
```
truncate table 表名
```
1. truncate不能加where
2. truncate删除带自增长的列的表后, 如果再插入数据, 数据从1开始
3. delete删除带自增长列的表后, 如果再插入数据(即使全删除), 数据从上一次的断点处开始
4. delete有返回值, truncate没有返回值
5. 事务中, truncate删除不能回滚, delete删除可以回滚

## DDL语句
### 库的管理
1. 创建库: `create database 库名(if not exsits 库名)`.
2. 删除库: `drop database 库名`.
3. 重命名: `rename database 库名 to 新库名`.
4. 更改字符集: `alter database 库名 character set 字符集名`.

### 表的管理
#### 创建表
```
CREATE TABLE employee(
    id INT,
    name VARCHAR(20),
    gender CHAR,
    birthday DATETIME
);
```

#### 修改表
1. 修改列名: `ALTER TABLE studentinfo CHANGE COLUMN sex gender CHAR;`, 要加类型约束
2. 修改表名: `ALTER TABLE stuinfo RENAME [TO] studentinfo;`
3. 修改列类型和列级约束: ``ALTER TABLE studentinfo MODIFY COLUMN birthday DATE;``
4. 添加字段:`ALTER TABLE studentinfo ADD COLUMN email VARCHAR(20);`
5. 删除字段: `ALTER TABLE studentinfo DROP COLUMN email;`

#### 删除表
`DROP TABLE [IF EXISTS] studentinfo;`

#### 复制表
复制表结构: `CREATE TABLE copy LIKE author;`, 复制结构加数据`CREATE TABLE copy LIKE author SELECT * FROM1 author;`, 也可以加`where`限制, 复制部分数据. 如果用`where 0`, 则可以复制部分列的结构, 但是不带数据

## 常见类型
1. 整型: Tinyint(1)/Smallint(2)/Int, Integer(4)/Bigint(8)
2. 小数: float(M, D) (4)/double(M, D) (8)/decimal(M, D). M是总长度, D是小数部分(都可省略). 超过范围插入临界值. 如果省略, 对于`decimal`的M, D默认为0, 10. 而其他两个根据数值精度来确认.
3. 字符型: char(M) (固定, M默认为1)/varchar(M) (可变, M不能省略)/text/blob(较大的二进制)
4. 日期型: date(4)/datetime(8)/timestamp(4, 受时区影响)/time(3)/year(1).
5. Blob类型

## 常见约束
- NOT NULL: 非空(id, 姓名等)
- DEFAULT: 字段默认的值
- UNIQUE: 唯一, 可以为空(座位号)
- CHECK: 检查约束, 语法支持, MySQL没有效果
- PRIMARY KEY: 主键, 唯一且非空, `CONSTRAINT PRIMARY KEY(id, name)`表示两个字段的组合唯一(id)
- FOREIGN KEY: 外键, 字段来自于主表关联的列的值, 用于引用主表某个值, 一般引用primary key和unique值.

创建表时添加约束:
```
CREATE TABLE student(
	id INT PRIMARY KEY,
	name VARCHAR(20) NOT NULL,
	gender CHAR(1) CHECK (gender='male' OR gender='female'),
	age INT DEFAULT 18,
	majorid INT REFERENCES major(id)
);

CREATE TABLE major(
	id INT PRIMARY KEY
);
```

也可以使用表级约束
```
CREATE TABLE student(
	id INT,
	name VARCHAR(20) NOT NULL,
	gender CHAR(1) CHECK (gender='male' OR gender='female'),
	age INT DEFAULT ,
	majorid INT,

	CONSTRAINT PRIMARY KEY(id),
	CONSTRAINT FOREIGN KEY(majorid) REFERENCES major(id)
);
```

修改表时添加约束, `ALTER TABLE student MODIFY COLUMN name VARCHAR(20) NOT NULL`. 或表级约束`ALTER TABLE student ADD UNIQUE(name))`.

删除约束, 同样用`ALTER`, 不加约束就好, 如果是`NOT NULL`, 则改为`NULL`. 删除键用`DROP`. 

标识列: `AUTO_INCREMENT`, 默认起始值为1, 自增长, 必须被索引, 一个表只能有一个. 起始值可以通过第一个插入的值来计算.

## 数据库事务
### 含义
**事务**通过一组逻辑操作单元(一个或多个SQL语句), 他们相互依赖. `innodb`支持事务, 但不是所有存储引擎支持事务.

### 特点
ACID
- 原子性(Atomicity): 要么都发生, 要么都回滚, 事务是最小的单位
- 一致性(Consistency):  执行事务后, 事务必须使数据库从一个一致性状态到另外一个一致性状态
- 隔离性(Isolation): 多个事务同时操作相同数据库的同一个数据时, 一个事务的执行不受另外一个事务的干扰, 各并发事务之间数据库是独立的
- 持久性(Durability): 一个事务一旦提交, 改变就是永久的, 即使数据库发生故障也不应该对其有任何影响

### 事务的分类
**隐式事务**没有明显的开启和结束事务的标志. 比如`insert/update/delete`语句本身就是一个事务. **显式事务**具有明显的开启和结束事务的标志. 显式事务步骤如下:
1. 开启事务: 取消自动提交事务的功能. `set autocommit=0;`. 可选`start transaction;`, 因为`set autocommit=0;`默认开启了事务.
2. 编写事务的一组逻辑操作单元(多条SQL语句). 如`insert/update/delete`.
3. 结束事务(提交/回滚): `commit`(提交)/`rollback`(撤销修改).

### 隔离级别
并发事务带来的问题:
- 脏读: 一个事务读取到了另外一个事务**更新但是未提交**的数据
- 不可重复读: 同一个事务中, 多次读取到的数据不一致, 原因是另一个事务对数据进行了进行了**更新**
- 幻读: 一个事务读取数据时, 另外一个事务进行**插入**了新的数据, 这个事务再次读取就会发现多了原本没有的记录
	
避免事务的并发问题, 可以设置事务的隔离级别: 
1. `READ UNCOMMITTED(读取未提交)`都不可避免
2. `READ COMMITTED(读取已提交)`可以避免脏读(Oracle默认)
3. `REPEATABLE READ(可重复读)` 可以避免脏读, 不可重复读(MySQL默认)
4. `SERIALIZABLE(可串行化)`可以避免脏读, 不可重复读和幻读(阻塞新的插入), 效率低. 但是完全符合ACID. 
	
- 设置隔离级别: `set session|global transaction isolation level 隔离级别名;`
- 查看隔离级别: `select @@tx_isolation;`
- 设置保存点`SAVEPOINT a`, 回滚到保存点`ROLLBACK TO a`.

> InnoDB在`REPEATABLE-READ`下使用的是Next-Key Lock锁算法, 所以也可以避免幻读. 达到了SQL标准的`SERIALIZABLE`隔离级别

## 视图
一张虚拟的表, **只**包含使用时动态检索数据的查询. 与表的使用方式完全相同, 但是不占用实际的物理空间. 使用视图的原因: 重用SQL语句/简化复杂的SQL操作/使用表的组成部分而不是整个表/保护数据/更改数据格式和表示.

### 视图的操作
#### 创建
```
CREATE VIEW 视图名
AS
查询语句;
```

#### 修改
```
CREATE OR REPLACE VIEW 视图名
AS
查询语句;
```

```
ALTER VIEW 视图名
AS
查询语句;
```

#### 删除
`DROP VIEW 视图名1, 视图名2;`

#### 查看
`SHOW CREATE view vieweg;`, 当然`desc`也行.

#### 视图的增删改查
1. 查看视图的数据: `SELECT * FROM vieweg;`
2. 插入视图的数据: `INSERT INTO vieweg(last_name,department_id) VALUES('a', 90);`
3. 修改视图的数据: `UPDATE vieweg SET last_name ='a' WHERE last_name='b';`
4. 删除视图的数据: `DELETE FROM vieweg WHERE last_name='b';`

但是一般不更新视图. 并且很多视图不允许改, 比如加了`distinct`/`groupby`等, 则增删改视图会报错.

## 变量
前两个是系统变量, 后两个是自定义的变量. 
### 全局变量
- 查看系统变量: `show global variables like '%char%';`
- 查看指定系统变量的值: `select @@global.autocommit;`/`select @@tx_isolasion;`
- 为某个系统变量赋值: `set @@global.autocommit=0`

### 会话变量
- 查看会话变量: `show session variables like '%char%';`
- 查看指定会话变量值`select @@tx_isolation;`/`select session.tx_isolation;`
- 赋值`set @@tx_isolation='read-uncommitted';`/`set session tx_isolation='read-uncommitted'`

### 用户变量/局部变量
作用域在当前对话, 也可在BEGIN/END中, 那么就会变成局部变量. 局部变量不需要加`@`, 并且为BEGIN/END中第一句话. 
```
# 声明
set @name='lisi'
set @count=1;

# 修改
set @name='zhangsan'
select count(*) into @count from employees;

# 查看
select @count;
```

## 存储
一组经过预先编译的sql语句的集合. 提高了sql语句的重用性, 提高了效率, 减少了连接数据库服务器次数.

### 创建存储过程(procedure)
```
delimiter $
create procedure 存储过程名(in|out|inout 参数名 参数类型, ...)
begin
	存储过程体(一组SQL语句)
end $
```

对于参数模式:
- 默认无返回无参
- in: 该参数可以作为传入值
- out: 该参数可以作为返回值
- inout: 可输入可输出

procedure的结束标记是`delimiter`, 如`delimiter $`, 就是用`$`作为标记, 如同SQL中的`;`. procedure中可以有多条SQL语句, 如果仅仅一条sql语句, 可省略begin/end. `call 存储过程名(实参列表)$`便可调用procedure.

返回输入值的两倍, 举例:
```
create procedure proc(INOUT a int, INOUT b int)
BEGIN
	SET a=a*2;
	SET b=b*2;
END $

set @m=10$
set @n=20$
call proc(@m,@n)$ #输入不能是常量

select @m,@n;
```

## 函数
有且仅有一个返回, 所以procedure适合批量插入/更新, 而函数一般用来处理数据. 
### 创建函数
```
CREATE FUNCTION 函数名(参数名 参数类型, ...) RETURNS 返回类型
BEGIN
	函数体
END
```

举例, 返回员工数量: 
```
create function fun() returns int
begin
	declare c int default 0; # set @c=0; 定义用户变量也是一会事

	select count(*) into c # @c
	from employees;

	return c; # @c
end $

SELECT fun()$
```

### 查看/删除函数
`show create function fun;`/`drop function fun;`

## 流程控制结构
### if函数
`if(条件, 值1, 值2)`

### case语句
类似于Java的switch
```
case 变量/表达式/字段
when 值1 then 结果1或语句1(如果是语句, 需要加分号)
when 值2 then 结果2或语句2(如果是语句, 需要加分号)
...
else 结果n或语句n(如果是语句, 需要加分号)
end [case] (如果是放在begin end中需要加上case, 如果放在select后面不需要)
```

类似于Java的多重if
```
case 
when 条件1 then 结果1或语句1(如果是语句, 需要加分号) 
when 条件2 then 结果2或语句2(如果是语句, 需要加分号)
...
else 结果n或语句n(如果是语句, 需要加分号)
end [case] (如果是放在begin end中需要加上case, 如果放在select后面不需要)
```

### if-elseif语句
**只能用在begin end中**.
```
if 情况1 then 语句1;
elseif 情况2 then 语句2;
...
else 语句n;
end if;
```

### 循环
`只能放在BEGIN END里面`, 可以用`leave`跳出, 但是`leave`需要搭配标签. 
```
标签: WHILE 循环条件 DO
		循环体
	END WHILE [标签];
```

举例, 插入名字:
```
create procedure test(IN incount INT)
BEGIN
	declare i int default 0;
	a: while i<= incount do
			set i=i+1
			if mod(i,2) != 0 then iterate a;
			end if;

			insert into admin(username, `password`) values(concat('zhang', i), 123);
	end while a;
END $

call test(10)$
```

## 参考
1. [尚硅谷MySQL](https://www.bilibili.com/video/BV12b411K7Zu?p=12)
2. MySQL必知必会