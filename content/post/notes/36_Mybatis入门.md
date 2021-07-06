---
title: "Mybatis入门"
date: 2021-07-09
draft: false
toc: true
categories: ["学习笔记"]
tags: ["Java"]
---

MyBatis是一款优秀的持久**层**框架, 它支持自定义SQL/存储过程以及高级映射. MyBatis免除了几乎所有的JDBC代码以及设置参数和获取结果集的工作. MyBatis可以通过简单的XML或注解来配置和映射原始类型/接口和Java POJO为数据库中的记录. (官网介绍)

## 第一个Mybatis程序
首先创建一个数据库进行测试.
```
create database `mybatis`;

use `mybatis`;

create table `user` (
	`id` int(20) NOT NULL PRIMARY KEY,
    `name` VARCHAR(30) DEFAULT NULL,
    `pwd` VARCHAR(30) DEFAULT NULL
)ENGINE=INNODB DEFAULT CHARSET=utf8;

INSERT INTO `user`(`id`, `name`, `pwd`) VALUES
(1, 'Harry1', '123a'),
(2, 'Harry2', '123b'),
(3, 'Harry3', '123c')
```

创建一个工具类, 用来生产sqlSession.
```
public class MybatisUtils {

    private static SqlSessionFactory sqlSessionFactory;

    static {
        try {
            //step1, 获取sqlSessionFactory对象
            String resource = "mybatis-config.xml";
            InputStream inputStream = Resources.getResourceAsStream(resource);
            sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    //step2, 获得SqlSession实例, SqlSession完全包含面向数据库执行SQL命令的所有方法
    public static SqlSession getSqlSession() {
        return sqlSessionFactory.openSession();
    }
}
```

而工具类的配置文件如下:
```
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-config.dtd">

<configuration>
    <environments default="development">
        <environment id="development">
            <transactionManager type="JDBC"/>
            <dataSource type="POOLED">
                <property name="driver" value="com.mysql.jdbc.Driver"/>
                <property name="url" value="jdbc:mysql://localhost:3306/mybatis?useSSL=true&amp;useUnicode=true&amp;useUnicode=true&amp;characterEncoding=UTF-8"/>
                <property name="username" value="root"/>
                <property name="password" value="xxxxxx"/>
            </dataSource>
        </environment>
    </environments>

    <!--每个Mapper.xml都需要在MyBatis核心配置文件中注册-->
    <mappers>
        <mapper resource="com/kuang/dao/UserMapper.xml"/>
    </mappers>
</configuration>
```

为了测试再创建一个user的pojo类, 这里省略getter/setter方法.
```
public class User {
  private int id;
  private String name;
  private String pwd;
}
```

同时创建`UserDao`的接口.
```
public interface UserDao {
    List<User> getUserList();
}
```

通过MyBatis, 我们不用自己写`Impl`实现类去实现接口, 而是通过配置实现.
```
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
        PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<!--绑定一个Dao(Mapper)接口-->
<mapper namespace="com.kuang.dao.UserDao">
    <!--相当于用Impl去重写接口方法, resultMap代表返回值-->
    <select id="getUserList" resultType="com.kuang.pojo.User">
        select * from mybatis.user
    </select>
</mapper>
```

最后做个单元测试看能否拿到数据库的数据.
```
public class UserDaoTest {
    
    @Test
    public void test() {
        //1.获得sqlSession对象
        SqlSession sqlSession = MybatisUtils.getSqlSession();
        //2.执行SQL
        UserDao userDao = sqlSession.getMapper(UserDao.class);
        List<User> userList = userDao.getUserList();

        for (User user : userList) {
            System.out.println(user);
        }

        //关闭Session
        sqlSession.close();
    }
}
```

不要忘了maven的配置. 父配置文件如下:
```
<!--import dependency-->
<dependencies>
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>8.0.25</version>
    </dependency>
    <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis</artifactId>
        <version>3.5.7</version>
    </dependency>
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.13.1</version>
    </dependency>
</dependencies>
```

子配置文件继承了父配置文件的包即可.
```
<parent>
    <artifactId>MyBatis-Study</artifactId>
    <groupId>com.kuang</groupId>
    <version>1.0-SNAPSHOT</version>
</parent>
```

这里有一个坑, 就是maven可能会扫描不到我们的`UserMapper.xml`文件, 导致资源导出失败, 那么我们需要在配置文件中加入如下过滤.
```
<build>
    <resources>
        <resource>
            <directory>src/main/resources</directory>
            <includes>
                <include>**/*.properties</include>
                <include>**/*.xml</include>
            </includes>
            <filtering>true</filtering>
        </resource>
        <resource>
            <directory>src/main/java</directory>
            <includes>
                <include>**/*.properties</include>
                <include>**/*.xml</include>
            </includes>
            <filtering>true</filtering>
        </resource>
    </resources>
</build>
```

### 增删改查
1. namespace: namespace中包名要和Dao/Mapper接口的包名一致
2. select: id就是namespace中的方法名, resultType是sql的返回值
3. parameterType

把之前的`UserDao`重构为`UserMapper`, 加入下列方法.
```
//根据id查用户
User getUserById(int id);

//insert一个用户
int addUser(User user);

//update用户
int updateUser(User user);

//delete用户
int deleteUser(int id);
```

`UserMapper.xml`中写sql语句.
```
<select id="getUserById" parameterType="int" resultType="com.kuang.pojo.User">
    select * from mybatis.user where id = #{id};
</select>

<insert id="addUser" parameterType="com.kuang.pojo.User">
    insert into mybatis.user (id, name, pwd) values (#{id}, #{name}, #{pwd});
</insert>

<update id="updateUser" parameterType="com.kuang.pojo.User">
    update mybatis.user set name=#{name}, pwd=#{pwd} where id = #{id};
</update>

<delete id="deleteUser" parameterType="int">
    delete from mybatis.user where id = #{id};
</delete>
```

测试如下, **增删改**必须`commit()`提交事务, 否则不生效.
```
@Test
public void addUser() {
    SqlSession sqlSession = MybatisUtils.getSqlSession();

    UserMapper mapper = sqlSession.getMapper(UserMapper.class);
    int res = mapper.addUser(new User(4, "ha", "12333"));
    System.out.println(res);

    sqlSession.commit();
    sqlSession.close();
}

@Test
public void updateUser() {
    SqlSession sqlSession = MybatisUtils.getSqlSession();

    UserMapper mapper = sqlSession.getMapper(UserMapper.class);
    mapper.updateUser(new User(4, "hehe", "123123"));

    sqlSession.commit();
    sqlSession.close();
}

@Test
public void deleteUser() {
    SqlSession sqlSession = MybatisUtils.getSqlSession();

    UserMapper mapper = sqlSession.getMapper(UserMapper.class);
    mapper.deleteUser(4);

    sqlSession.commit();
    sqlSession.close();
}
```

- 可以用`parameterType=map`并传入Map类型的值, 这样就可以根据Map的键值对传值. 
- 如果只有一个参数, 可以直接在sql中写. 
- 如果传入的是对象, 可以直接取对象的field, `parameterType=Object`.

> like模糊查询注意sql注入问题

## 配置解析
在`mybatis-config.xml`相同的包下加入`db.properties`, 写入
```
driver=com.mysql.jdbc.Driver
url=jdbc:mysql://localhost:3306/mybatis?useSSL=true&useUnicode=true&useUnicode=true&characterEncoding=UTF-8
username=root
password=xxxxxxxx
```

并在`mybatis-config.xml`中的`<configuration>`下加入`<configuration>`. 就可以用`<property name="driver" value="${driver}"/>`的方式去替换我们的配置. `<properties>`这个标签下也可以直接用`<property>`直接配置. 如果两个文件都配置了相同字段, 优先使用外部配置文件的. 

还可以取别名, 这个功能唯一的好处就是方便, 在Mapper中的类名就可以换掉. 可以给类名, 包名取别名, 如下两种方式. 如果是扫描包, 则可以把`@Alias`加在实体类上, 给实体类自定义别名, 否则用类名本身. **基本类型/包装类有默认的别名**.
```
<typeAliases>
    <typeAlias type="com.kuang.pojo.User" alias="User"/>
    <package name="com.kuang.pojo"/>
</typeAliases>
```

之前`mappers`中我们用了`<mapper resource="com/kuang/dao/UserMapper.xml"/>`注册, 实际上还有`<mapper class="com.kuang.dao.UserMapper"/>`类注册, `<package name="com.kuang.dao"/>`包注册两种方式, 但是要注意接口和配置文件**名称必须一致**, 并且在**同一个包下**.

对于生命周期和作用域, 简单的总结是: `SqlSessionFactoryBuilder`创建`SqlSessionFactory`(想象为连接池), `SqlSessionFactory`生产`SqlSession`一个线程, `SqlSession`下包含`Mapper`, `Mapper`就是一个个业务. `SqlSessionFactoryBuilder`在`SqlSessionFactory`创建后就没用了, 但是`SqlSessionFactory`在应用运行期间一直应存在, **最佳作用域是应用的作用域**, 最简单的使用就是单例. 而`SqlSession`是连接到线程池的一个请求, 线程不安全, **最佳作用域是请求或方法作用域**, 用完之后应立刻关闭, 防止资源占用.

## 结果集映射
前面的例子中, 我们的User Bean中的字段和数据库字段的名称一一对应, 如果不同的话怎么办? 例如把`User`中的`pwd`改为`password`, 那么除了用MySQL的别名, 还可以用mybatis的`resultMap`. 当然这是比较简单的情况, 文档里面说**如果这个世界总是这么简单就好了**, 实际还有更复杂的一对多多对一的情况, 需要用`collections`处理. 
```
<resultMap id="UserMap" type="User">
    <result column="id" property="id"/>
    <result column="name" property="name"/>
    <result column="pwd" property="password"/>
</resultMap>
<!--相当于用Impl去重写接口方法, resultMap代表返回值-->
<select id="getUserById" resultMap="UserMap">
    select * from mybatis.user where id = #{id}
</select>
```

## Mybatis的日志
在配置文件配一下就ok, 这里用的标准输出为例.
```
<settings>
    <setting name="logImpl" value="STDOUT_LOGGING"/>
</settings>
```

会打印:
```
Opening JDBC Connection
Created connection 551479935.
Setting autocommit to false on JDBC Connection [com.mysql.cj.jdbc.ConnectionImpl@20deea7f]
==>  Preparing: select * from mybatis.user where id = ?
==> Parameters: 1(Integer)
<==    Columns: id, name, pwd
<==        Row: 1, Harry1, 123a
<==      Total: 1
User{id=1, name='Harry1', pwd='123a'}
Resetting autocommit to true on JDBC Connection [com.mysql.cj.jdbc.ConnectionImpl@20deea7f]
Closing JDBC Connection [com.mysql.cj.jdbc.ConnectionImpl@20deea7f]
Returned connection 551479935 to pool.
```

再尝试一下`log4j`.
```
<!-- https://mvnrepository.com/artifact/log4j/log4j -->
<dependency>
    <groupId>log4j</groupId>
    <artifactId>log4j</artifactId>
    <version>1.2.17</version>
</dependency>
```

新建`resource`下创建`log4j.properties`, 参照官网配置.
```
# 全局日志配置, 级别有OFF/FATAL(导致程序挂掉的严重错误)/ERROR(发生错误但不影响运行)/WARN(潜在错误)/INFO(打印感兴趣的日志)/DEBUG(帮助debug()/TRACE(一般不用)/ALL
log4j.rootLogger=DEBUG, stdout
# MyBatis 日志配置
log4j.logger.org.mybatis.example.BlogMapper=TRACE
# 控制台输出
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%5p [%t] - %m%n
#
log4j.logger.com.mybatis=DEBUG
```

Mybatis配置改为如下并运行.
```
<settings>
    <setting name="logImpl" value="LOG4j"/>
</settings>
```

**比较标准的使用方式**: 通过`static Logger logger = Logger.getLogger(UserDaoTest.class);`拿到日志对象, 通过`logger.info()/logger.debug()/logger.erroer()`打印日志, 比如在同一个测试类下加入:
```
@Test
public void testLog4j(){
    logger.info("info");
    logger.debug("debug");
    logger.error("error");
}
```

就能打印:
```
 INFO [main] - info
DEBUG [main] - debug
ERROR [main] - error
```

## 参考
1. [Mybatis最新完整教程IDEA版通俗易懂-狂神说Java](https://www.bilibili.com/video/BV1NE411Q7Nx)