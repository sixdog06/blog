---
title: "Mybatis入门"
date: 2021-07-09
draft: false
toc: true
categories: ["WEB开发"]
tags: ["数据库"]
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

对于**生命周期和作用域**, 简单的总结是: `SqlSessionFactoryBuilder`创建`SqlSessionFactory`(想象为连接池), `SqlSessionFactory`生产`SqlSession`一个线程, `SqlSession`下包含`Mapper`, `Mapper`就是一个个业务. `SqlSessionFactoryBuilder`在`SqlSessionFactory`创建后就没用了, 但是`SqlSessionFactory`在应用运行期间一直应存在, **最佳作用域是应用的作用域**, 最简单的使用就是单例. 而`SqlSession`是连接到线程池的一个请求, 线程不安全, **最佳作用域是请求或方法作用域**, 用完之后应立刻关闭, 防止资源占用. 

> 对于执行流程, 还有很多是源码做的但我们看不到的, 比如读配置, 事务管理, 创建executor执行器等等. 介意debug的时候看一条sql语句是怎么跑的, 看用到了哪些东西

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

## 分页
分页的目的是减少数据的处理量. 可以通过Limit或者**RowBounds**实现. 对于limit实现实际上就是简单地传入limit的值即可.
```
<!--对应List<User> getUserByLimit(Map<String, Integer> map);-->
<select id="getUserByLimit" parameterType="map" resultMap="UserMap">
    select * from mybatis.user limit #{startIndex},#{pageSize}
</select>
```

**RowBounds**实现, 在写sql时就不需要加limit了, 而是在调用的时候用`RowBounds`作为selectList的参数传入.
```
@Test
public void getUserByRowBounds() {
    SqlSession sqlSession = MybatisUtils.getSqlSession();
    RowBounds rowBounds = new RowBounds(1, 2);
    List<User> userList = sqlSession.selectList("com.kuang.dao.UserMapper.getUserByRowBounds", null, rowBounds);

    for (User user: userList) {
        System.out.println(user);
    }
    sqlSession.close();
}
```
还有诸如`PageHelper`这样的插件可以分页, 甚至公司会有自己私有的分页工具.

## 注解开发
直接删掉`UserMapper.xml`, dao接口直接在方法上加上注解, 依然可以查询. 核心是用反射通过`UserMapper`做到`UserMapper.xml`的配置. 但是这个地方如果数据库的字段和实体类不同就无法读取了. **注意核心配置文件还是要绑定接口**.
```
public interface UserMapper {

    @Select("select * from user")
    List<User> getUsers();
}
```

直接在注解中写sql语句即可.
```
@Select("select * from user")
List<User> getUsers();

//多个参数, 前面加上@Param, 和用ajax前后端交互那种注解类似
@Select("select * from user where id = #{id}")
User getUserById(@Param("id") int id);

@Insert("insert into user(id,name,pwd) values (#{id},#{name},#{pwd})")
int addUser(User user);

@Update("update user set name=#{name} where id = #{id}")
int updateUser(User user);

@Delete("delete from user where id = #{uid}")
int deleteUser(@Param("uid") int id);
```

> 视频讲了lombok插件, 简化写getter/setter, 是否使用仁者见仁智者见智

## 复杂查询
两个表, 1对多, 多对1的查询如何实现. 用下面的表做测试.
```
use mybatis;

CREATE TABLE `teacher` (
  `id` INT(10) NOT NULL,
  `name` VARCHAR(30) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

INSERT INTO teacher(`id`, `name`) VALUES (1, "秦老师"); 

CREATE TABLE `student` (
  `id` INT(10) NOT NULL,teacher
  `name` VARCHAR(30) DEFAULT NULL,
  `tid` INT(10) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fktid` (`tid`),
  CONSTRAINT `fktid` FOREIGN KEY (`tid`) REFERENCES `teacher` (`id`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

INSERT INTO `student` (`id`, `name`, `tid`) VALUES (1, "小明", 1); 
INSERT INTO `student` (`id`, `name`, `tid`) VALUES (2, "小红", 1); 
INSERT INTO `student` (`id`, `name`, `tid`) VALUES (3, "小张", 1); 
INSERT INTO `student` (`id`, `name`, `tid`) VALUES (4, "小李", 1); 
INSERT INTO `student` (`id`, `name`, `tid`) VALUES (5, "小王", 1);
```

### 多对一
要查询所有的学生对应的老师, 首先pojo类中的`Student`会有相对应的`Teacher`字段. 查询时配置如下, 实际上就把`Student`中的`Teacher`字段查询额外绑定了sql语句, 也就是把tid绑定上了Teacher的java类型, 再通过java类型查询. 方法2看起来更简单, 写完所有sql之后再用map绑定.
```
<mapper namespace="com.kuang.dao.StudentMapper">
    <!--1-->
    <select id="getStudent" resultMap="StudentTeacher">
        select * from student;
    </select>
    <resultMap id="StudentTeacher" type="Student">
        <result property="id" column="id"/>
        <result property="name" column="name"/>
        <association property="teacher" column="tid" javaType="Teacher" select="getTeacher"/>
    </resultMap>
    <select id="getTeacher" resultType="Teacher">
        select * from teacher where id = #{tid}
    </select>

    <!--2-->
    <select id="getStudent2" resultMap="StudentTeacher2">
    select s.id sid, s.name sname, t.name tname
    from student s, teacher t
    where s.tid = t.id;
    </select>
    <resultMap id="StudentTeacher2" type="Student">
        <result property="id" column="sid"/>
        <result property="name" column="sname"/>
        <association property="teacher" javaType="Teacher">
            <result property="name" column="tname"/>
        </association>
    </resultMap>
</mapper>
```

> idea的maven项目在resourse目录下会不能new package, 只要创建directory即可, 用`/`分隔不同层级的目录, 否则mapper.xml文件可能会无法绑定

### 一对多
一个老师对应多个学生的情况(Teacher类下有`List<Student>`字段), 可以用`collection`去用`ofType`拿对应的`Student`. 
```
<mapper namespace="com.kuang.dao.TeacherMapper">
    <select id="getTeacher" resultMap="TeacherStudent">
        select s.id sid, s.name sname, t.name tname, t.id id
        from student s,teacher t
        where s.tid = t.id and t.id = #{tid}
    </select>

    <resultMap id="TeacherStudent" type="Teacher">
        <result property="id" column="tid"/>
        <result property="name" column="tname"/>
        <collection property="student" ofType="Student">
            <result property="id" column="sid"/>
            <result property="name" column="sname"/>
            <result property="tid" column="tid"/>
        </collection>
    </resultMap>
</mapper>
```

当然依然可以用几个select去分别读数据, 先读teacher, 拿到id, 再通过id, 到student表中取数据对应`tid`的数据. 
```
<select id="getTeacher2" resultMap="TeacherStudent2">
    select * from mybatis.teacher where id = #{tid}
</select>
<resultMap id="TeacherStudent2" type="Teacher">
    <collection property="student" javaType="ArrayList" ofType="Student" select="getStudentByTeacherId" column="id"/>
</resultMap>
<select id="getStudentByTeacherId" resultType="Student">
    select * from mybatis.student where tid = #{tid}
</select>
```

## 动态sql
建表做实验.
```
CREATE TABLE `blog`(
`id` VARCHAR(50) NOT NULL COMMENT 博客id,
`title` VARCHAR(100) NOT NULL COMMENT 博客标题,
`author` VARCHAR(30) NOT NULL COMMENT 博客作者,
`create_time` DATETIME NOT NULL COMMENT 创建时间,
`views` INT(30) NOT NULL COMMENT 浏览量
)ENGINE=INNODB DEFAULT CHARSET=utf8
```

插入数据. 其中的id通过`UUID.randomUUID().toString().replaceAll("-", "");`生成, 时间通过`new Date()`插入.
```
<insert id="addBlog" parameterType="blog">
    insert into mybatis.blog values (#{id}, #{title}, #{author}, #{createTime}, #{views})
</insert>
```

### if
通过一个Map把`title`和`author`传入, 进行查询. 其中`where 1=1`是一个小技巧, 保证`and`能顺利的加上, 即使没有`and`也是有效的语句.
```
<select id="queryBlogIF" parameterType="map" resultType="Blog">
    select * from mybatis.blog where 1 = 1
    <if test="title != null">
        and title = #{title}
    </if>
    <if test="author != null">
        and author = #{author}
    </if>
</select>
```

### choose/set
choose相当于Java的`switch`, 其中的语句只有一条生效. `where`元素让我们可以省去写`1=1`, 他会判断子句是否有返回, 如果只返回一个子句, 那么子句前面的and/or就会被去掉. 这样我们就可以正常地写sql逻辑了.
```
<select id="queryBlogChoose" parameterType="map" resultType="blog">
    select * from mybatis.blog
    <where>
        <choose>
            <when test="title != null">
                title = #{title}
            </when>
            <when test="author != null">
                and author = #{author}
            </when>
            <otherwise>
                and views = #{views}
            </otherwise>
        </choose>
    </where>
</select>
```

`set`可以动态地把s`et`前置 并且删除自动字段间的逗号.
```
<update id="updateBlog" parameterType="map">
    update mybatis.blog
    <set>
        <if test="title != null">
            title = #{title},
        </if>
        <if test="author != null">
            author = #{author}
        </if>
    </set>
    where id = #{id}
</update>
```

而trim允许我们自定义的去定义首尾的重写, 比如where的功能其实就是`<trim prefix="WHERE" prefixOverrides="AND |OR "></trim>`, 如果开头是And或者OR, 就移除. 而`set`就等同于`<trim prefix="SET" suffixOverrides=","></trim>`.

> `sql`标签可以抽取公共部分的语句, 然后在需要用的地方加上`<include refid="sqlid"></include>`即可. 但是最好用单表定义sql片段, 并且不要放`where`在片段中, 否则没什么复用的效果

### Foreach
相当于去自动生成sql语句的and后或者or后的条件, 如下我们可以传入一个map实例, 最后拼的sql就会加上`id=1 or id=2 ...`.
```
<select id="queryBlogForeach" parameterType="map" resultType="blog">
    select * from mybatis.blog
    <where>
        <foreach collection="ids" item="id" open="and (" close=")" separator="or">
            id = #{id}
        </foreach>
    </where>
</select>
```

## 缓存
### 一级缓存(本地缓存)
也就是前面看到的SqlSession, 对于同一个查询, 第二次就会读缓存. 可以用`<setting name="logImpl" value="STDOUT_LOGGING"/>`标准日志打印做测试, 写两条相同的查询, 从连接到关闭只会实际查询一次数据库. 但是如果在两次查询之间有增删改, 会使缓存失效(因为可能会修改原来的数据, 缓存会刷新). 除此之外, 查不同的Mapper.xml或者手动`sqlSession.clearCache()`清理缓存也会使缓存失效. 

### 二级缓存(全局缓存)
文档只写了二级缓存, 有如下四种, 其中LRU是默认缓存规则. 基于`namespace`级别(在`namespace`下放`<cache/>`). 一个查询的数据放在一级缓存中, **当会话关闭或提交, 一级缓存消失, 就会把一级缓存中的数据存到二级缓存中**. 新的查询也就可以通过二级缓存获取数据. **不同的mapper分别有不同的缓存**.
- LRU(Least Recently Used): Removes objects that haven't been used for the longst period of time.
- FIFO(First In First Out): Removes objects in the order that they entered the cache.
- SOFT(Soft Reference): Removes objects based on the garbage collector state and the rules of Soft References.
- WEAK(Weak Reference): More aggressively removes objects based on the garbage collector state and rules of Weak References.

使用前核心配置文件一般要加入`<setting name="cacheEnabled" value="true"/>`显式开启缓存(为了可读性). 用如下的测试看效果. 当关闭session的操作在1处, 则会查两次数据库. 而在2时就只会查一次数据库. 注意这里的实体类需要序列化`implements Serializable`.
```
@Test
public void test() {
    SqlSession sqlSession = MybatisUtils.getSqlSession();
    SqlSession sqlSession2 = MybatisUtils.getSqlSession();

    UserMapper mapper = sqlSession.getMapper(UserMapper.class);
    UserMapper mapper2 = sqlSession2.getMapper(UserMapper.class);

    User user = mapper.queryUserById(1);
    System.out.println(user);
    sqlSession.close();
    //sqlSession.close(); //2, 不关闭仍然会查两次, 因为一级缓存的数据还没有放到二级缓存

    User user2 = mapper2.queryUserById(1);
    System.out.println(user2);

    sqlSession.close(); //1
    sqlSession2.close();
}
```

> 一级缓存在Session, 二级缓存在Mapper. 查询先看二级缓存, 再看一级缓存, 两个都没有就查数据库

### 自定义缓存
可以用ehcache等多种缓存, 在`Mapper.xml`文件中加入`<cache type="org.mybatis.caches.ehcache.EhcacheCache" />`即可. 我们可以看到实际上缓存就是去实现了`Cache`接口, 所以如果我们强到自己写缓存, 实际上也就是去实现这个接口的方法.  
```
<dependency>
    <groupId>org.mybatis.caches</groupId>
    <artifactId>mybatis-ehcache</artifactId>
    <version>1.2.1</version>
</dependency>
```

## 参考
1. [Mybatis最新完整教程IDEA版通俗易懂-狂神说Java](https://www.bilibili.com/video/BV1NE411Q7Nx)