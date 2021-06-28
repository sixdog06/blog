---
title: "Mybatis"
date: 2021-06-08
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

## 参考
1. [Mybatis最新完整教程IDEA版通俗易懂-狂神说Java](https://www.bilibili.com/video/BV1NE411Q7Nx)