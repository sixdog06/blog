---
title: "Spring-AOP"
date: 2021-01-22
draft: false
toc: true
categories: ["WEB开发"]
tags: ["Spring"]
---

## 概念
**面向切面编程**, 利用AOP可以对业务逻辑的各个部分进行隔离, 使业务逻辑各部分之间的耦合度降低. 在不修改源代码的情况下, 也可以在主干功能里面添加新功能.

## 动态代理
1. 有接口的情况, 使用JDK动态代理. 创建接口实现类代理对象, 去增强类的方法.
2. 没有接口的情况, 使用CGLIB动态代理; 创建子类的代理对象, 增强类的方法.

我们来针对情况1做一个实验. 首先创建接口和对应的实现类.
```
public interface UserDao {
    public int add(int a, int b);
    public String update(String id);
}
```

```
public class UserDaoImpl implements UserDao {
    @Override
    public int add(int a, int b) {
        return a + b;
    }
    @Override
    public String update(String id) {
        return id;
    }
}
```

再使用Proxy类创建接口代理对象.
```
public class JDKProxy {
    public static void main(String[] args) {
        //创建接口实现类的代理对象
        Class[] interfaces = {UserDao.class};
        UserDaoImpl userDao = new UserDaoImpl();
        /**
         * @param   loader the class loader to define the proxy class
         * @param   interfaces the list of interfaces for the proxy class
         *          to implement
         * @param   接口InvocationHandler的实现类
         */
        //接口实现类的代理对象
        UserDao dao = (UserDao) Proxy.newProxyInstance(JDKProxy.class.getClassLoader(), interfaces, new UserDaoProxy(userDao)); //也可以用匿名内部类代替UserDaoProxy, new InvocationHandler(), 直接Override invoke方法
        int result = dao.add(1, 2);
        System.out.println("result: " + result);
        System.out.println(dao.update("test"));
    }
}

class UserDaoProxy implements InvocationHandler { //也可以用匿名内部类写
    private Object obj;
    public UserDaoProxy(Object obj) { //通过有参构造器传入要代理的对象
        this.obj = obj;
    }
    //增强的逻辑
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("Run before method: " + method.getName() + " Parameters: "+ Arrays.toString(args));
        Object res = method.invoke(obj, args); //(对象, 参数), 被增强的方法执行
        System.out.println("Run after method: " + obj);
        return res;
    }
}
```

> 一些术语:
> 
> 连接点: 类里面哪些可以被增强的方法
> 
> 切入点: **实际被增强**的方法称为切入点
> 
> 通知(增强): 实际增强的逻辑部分称为通知, 包含前置通知/后置通知/环绕通知/异常通知/最终通知
> 
> 切面: 把通知应用到切入点过程

## AOP操作-准备
Spring一般都是基于AspectJ实现AOP操作. 和IOC一样, 可以基于xml配置文件实现, 也可以基于注解方式实现. 需要如下的依赖包:
![](/44_1.png)

通过切入点表达式可以知道对哪个类里面的哪个方法进行增强. `execution([权限修饰符][返回类型][类全路径][方法名称]([参数列表]))`. 其中权限修饰符可以用`*`表示所有类型, 返回类型可以省略. 如果写`com.example.*.*`, 就表示对`com.example`包下的所有类和所有方法进行增强.

## AOP操作-AspectJ
创建两个类:
```
@Component //被增强的类
public class User {
    public void add() {
        System.out.println("add!");
    }
}
```
```
@Component
@Aspect //生成代理对象
public class UserProxy {
    //相同切入点抽取, 后面就可以重复使用了
    @Pointcut(value = "execution(* com.example.aopanno.User.add(..))")
    public void pointdemo() {

    }

    //前置通知
    @Before(value = "pointdemo()")//相同切入点抽取使用
    public void before() {
        System.out.println("before");
    }

    //后置通知
    @AfterReturning(value = "pointdemo()")
    public void afterReturning() {
        System.out.println("afterReturning");
    }

    //最终通知
    @After(value = "pointdemo()")
    public void after() {
        System.out.println("after");
    }

    //异常通知
    @AfterThrowing(value = "pointdemo()")
    public void afterThrowing() {
        System.out.println("afterThrowing");
    }

    //环绕通知
    @Around(value = "pointdemo()")
    public void around(ProceedingJoinPoint proceedingJoinPoint) throws Throwable {
        System.out.println("环绕之前");
        proceedingJoinPoint.proceed(); //被增强的方法执行
        System.out.println("环绕之后");
    }
}
```

创建配置文件:
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                        http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd
                        http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop.xsd">
    <!-- 开启注解扫描 -->
    <context:component-scan base-package="com.example.aopanno"/>

    <!-- 开启Aspect生成代理对象-->
    <aop:aspectj-autoproxy></aop:aspectj-autoproxy>
</beans>
```

进行测试:
```
public class TestAop {

    @Test
    public void test() {
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        User user = context.getBean("user", User.class);
        user.add();
    }
}
```

最后的输出如下. 我们注意`after`无论是否有异常都会执行.
```
//没有异常输出
环绕之前
before
add!
afterReturning
after
环绕之后
//有异常输出
环绕之前
before
afterThrowing
after
```

如果有多个增强类多同一个方法进行增强, 可以设置增强类优先级. 我们新建一个`PersonProxy`类. 并带上注解`@Order(0)` 而前面的`UserProxy`加上注解`@Order(1)`
```
@Component
@Aspect
@Order(0)
public class PersonProxy {
    @Before(value = "execution(* com.example.aopanno.User.add())")
    public void afterReturning() {
        System.out.println("Person before");
    }
}
```

输出如下, 可以看出数字越小, 优先级越高. 而默认是最低优先级`int value() default 2147483647;`.
```
Person before
环绕之前
before
add!
afterReturning
after
环绕之后
```

## AOP操作-xml中配置aop增强
```
<!--配置 aop 增强-->
<aop:config>
    <!--切入点-->
    <aop:pointcut id="p" expression="execution(* com.example.aopxml.Book.buy())"/>
    <!--配置切面-->
    <aop:aspect ref="bookProxy">
        <!--增强作用在具体的方法上-->
        <aop:before method="before" pointcut-ref="p"/>
    </aop:aspect>
</aop:config>
```

aop也可以使用完全注解, 一般开发中比较少遇到.
```
@Configuration
@ComponentScan(basePackages = {"com.atguigu"}) 
@EnableAspectJAutoProxy(proxyTargetClass = true)
```

## JdbcTemplate
Spring封装了JDBC. 需要如下的依赖包.
![](/44_2.png)

为此次实验创建一个数据库book.
```
create database book;
use book;
create table Book(userId varchar(30), username varchar(30), ustatus varchar(30));
```

配置文件.
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                        http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd
                        http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop.xsd">
    <!-- 1.数据库连接池 -->
    <bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource"
          destroy-method="close">
        <property name="url" value="jdbc:mysql:///book" />
        <property name="username" value="root" />
        <property name="password" value="xxxxxx" />
        <property name="driverClassName" value="com.mysql.jdbc.Driver" />
    </bean>

    <!-- 2.JdbcTemplate对象, 注入DataSource -->
    <bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
        <!--注入 dataSource-->
        <property name="dataSource" ref="dataSource"></property><!--set方式注入-->
    </bean>

    <!-- 组件扫描 -->
    <context:component-scan base-package="com.example"></context:component-scan>
</beans>
```

创建`BookDao`接口并实现.
```
public interface BookDao {
    public void addBook(Book book);
    public void updateBook(Book book);
    public void deleteBook(String id);
    public int selectCount();
    public Book findBookInfo(String id);
    public List<Book> findAllBook();
    public void batchAddBook(List<Object[]> batchArgs);
    public void batchUpdateBook(List<Object[]> batchArgs);
    public void batchDeleteBook(List<Object[]> batchArgs);
}
```

```
@Repository
public class BookDaoImpl implements BookDao{
    @Autowired
    private JdbcTemplate jdbcTemplate; //3.创建service类/dao类, 在dao注入jdbcTemplate对象

    @Override
    public void addBook(Book book) {
        //1.创建sql语句
        String sql = "insert into book values(?,?,?)";
        //2.调用方法实现
        Object[] args = {book.getUserId(), book.getUsername(),book.getUstatus()};
        int update = jdbcTemplate.update(sql, args);
        System.out.println(update);
    }

    @Override
    public void updateBook(Book book) {
        String sql = "update book set username=?,ustatus=? where userid=?";
        Object[] args = {book.getUsername(), book.getUstatus(),book.getUserId()};
        int update = jdbcTemplate.update(sql, args);
        System.out.println(update);
    }

    @Override
    public void deleteBook(String id) {
        String sql = "delete from book where userid=?";
        int update = jdbcTemplate.update(sql, id);
        System.out.println(update);
    }

    @Override
    public int selectCount() {
        String sql = "select count(*) from book";
        int count = jdbcTemplate.queryForObject(sql, Integer.class); //返回类型的class
        return count;
    }

    @Override
    public Book findBookInfo(String id) {
        String sql = "select * from book where userid=?";
        Book book = jdbcTemplate.queryForObject(sql, new BeanPropertyRowMapper<Book>(Book.class), id);
        return book;
    }

    @Override
    public List<Book> findAllBook() {
        String sql = "select * from book";
        List<Book> bookList = jdbcTemplate.query(sql, new BeanPropertyRowMapper<Book>(Book.class));
        return bookList;
    }

    @Override
    public void batchAddBook(List<Object[]> batchArgs) {
        String sql = "insert into book values(?,?,?)";
        int[] ints = jdbcTemplate.batchUpdate(sql, batchArgs); //第二个参数是List集合, 表示添加的多条记录数据
        System.out.println(Arrays.toString(ints));
    }

    @Override
    public void batchUpdateBook(List<Object[]> batchArgs) {
        String sql = "update book set username=?,ustatus=? where userid=?";
        int[] ints = jdbcTemplate.batchUpdate(sql, batchArgs);
        System.out.println(Arrays.toString(ints));
    }

    @Override
    public void batchDeleteBook(List<Object[]> batchArgs) {
        String sql = "delete from book where userid=?";
        int[] ints = jdbcTemplate.batchUpdate(sql, batchArgs);
        System.out.println(Arrays.toString(ints));
    }
}
```

通过`BookService`类去调用方法.
```
@Service
public class BookService {
    @Autowired
    private BookDao bookDao;

    //添加
    public void addBook(Book book) {
        bookDao.addBook(book);
    }

    //修改
    public void updateBook(Book book) {
        bookDao.updateBook(book);
    }

    //删除
    public void deleteBook(String id) {
        bookDao.deleteBook(id);
    }

    //查询返回某个值
    public int selectCount() {
        return bookDao.selectCount();
    }

    //查询返回对象
    public Book findBookInfo(String id) {
        return bookDao.findBookInfo(id);
    }

    //查询返回集合
    public List<Book> findAllBook() {
        return bookDao.findAllBook();
    }

    //批量添加
    public void batchAddBook(List<Object[]> batchArgs) {
        bookDao.batchAddBook(batchArgs);
    }

    //批量修改
    public void batchUpdateBook(List<Object[]> batchArgs) {
        bookDao.batchUpdateBook(batchArgs);
    }

    //批量删除
    public void batchDeleteBook(List<Object[]> batchArgs) {
        bookDao.batchDeleteBook(batchArgs);
    }
}
```

最后进行测试.
```
public class TestBook {

    @Test
    public void test() {
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);
        //添加
//        Book book = new Book();
//        book.setUserId("1");
//        book.setUsername("zhang3");
//        book.setUstatus("a");
//        bookService.addBook(book);

        //修改
//        book.setUserId("1");
//        book.setUsername("li4");
//        book.setUstatus("a");
//        bookService.updateBook(book);

        //删除
//        bookService.deleteBook("1");

        //查询返回某个值
//        System.out.println(bookService.selectCount());

        //查询返回对象
//        System.out.println(bookService.findBookInfo("1"));

        //查询返回集合
//        System.out.println(bookService.findAllBook());

        //批量添加
//        List<Object[]> batchArgs = new ArrayList<>();
//        Object[] o1 = {"3","wang5","a"};
//        Object[] o2 = {"4","liu6","b"};
//        Object[] o3 = {"5","zhao7","c"};
//        batchArgs.add(o1);
//        batchArgs.add(o2);
//        batchArgs.add(o3);
//        bookService.batchAddBook(batchArgs);

        //批量修改
//        List<Object[]> batchArgs = new ArrayList<>();
//        Object[] o1 = {"wang5","233","3"};
//        Object[] o2 = {"liu6","233","4"};
//        Object[] o3 = {"zhao7","233","5"};
//        batchArgs.add(o1);
//        batchArgs.add(o2);
//        batchArgs.add(o3);
//        bookService.batchUpdateBook(batchArgs);

        //批量删除
        List<Object[]> batchArgs = new ArrayList<>();
        batchArgs.add(new Object[]{"3"});
        batchArgs.add(new Object[]{"4"});
        batchArgs.add(new Object[]{"5"});
        bookService.batchDeleteBook(batchArgs);
    }
}
```

## Spring-操作事务
通过银行的转账作为实现. 像之前一样, service层做业务操作, dao层做数据库操作. 首先创建一个数据库. 配置文件个前面的实验几乎一样. **事务添加到JavaEE三层结构(web/service/dao)里面Service层**. 有编程式事务管理和**声明式事务管理(常用)**, 在Spring中的声明式事务管理会用到AOP. 同样支持注解方式和配置文件方式.
```
create database bank;
use bank;
insert into user values("1","zhang3",100);
insert into user values("2","li4",100);
```

配置文件中, 在之前的基础上, 加入:
```
<!--配置文件中增加-->
xmlns:tx="http://www.springframework.org/schema/tx"
xsi:schemaLocation="http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx.xsd"

<!--创建事务管理器-->
<bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
    <property name="dataSource" ref="dataSource"></property> <!--注入数据源-->
</bean>
<!--开启事务注解-->
<tx:annotation-driven transaction-manager="transactionManager"></tx:annotation-driven>
```

创建UserDao接口并实现它.
```
@Repository
public class UserDaoImpl implements UserDao {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void addMoney() {
        String sql = "update user set money=money+? where username=?";
        jdbcTemplate.update(sql, 100, "li4");
    }

    @Override
    public void reduceMoney() {
        String sql = "update user set money=money-? where username=?";
        jdbcTemplate.update(sql, 100, "zhang3");
    }
}
```

Service层如下. 如果这里的转账业务两个方法之间发成了错误, 那么可能张三的钱少了但是李四的钱不增加, 添加事务就避免了这个问题.
```
@Service
@Transactional //给类里面的所有方法都添加事务, 也可以加在类上
public class UserService {

    //注入dao
    @Autowired
    private UserDao userDao;

    //转账的业务方法, 需要加入一个事务
    public void transferMoney() {
        userDao.reduceMoney();
        userDao.addMoney();
    }
}
```

### 事务注解参数
`Propagation propagation() default Propagation.REQUIRED;`(事务传播行为)一共有7种. 配置时就写`propagation = Propagation.REQUIRED`.
![](/44_3.png)

`Isolation isolation() default Isolation.DEFAULT;`(事务隔离级别). 有4个隔离级别`READ UNCOMMITED`/`READ COMMITED`/`REPEATABLE READ`/`SERIALIZABLE`. MySQL默认是可重复度.
- 脏读(问题): 一个未提交事务读取到另一个未提交事务的数据
- 不可重复度(现象): 一个未提交事务读取到另一提交事务修改数据
- 幻读: 一个未提交事务读取到另一提交事务添加数据

`int timeout() default -1;`(超时时间): 单位是秒, 表示事务开启和提交的时间长度.

`boolean readOnly() default false;`(是否只读): 读就是查询, 写就是增删改.

`Class<? extends Throwable>[] rollbackFor() default {};`: 出现哪些异常进行事务回滚

`Class<? extends Throwable>[] noRollbackFor() default {};`: 出现哪些异常不进行事务回滚

## XML声明式事务管理
在组件下面, 加入如下配置. 测试的时候可以在`transferMoney`的两个方法中引入错误, 最后数据库操作会回滚.
```
<!-- 1.创建事务管理器 -->
<bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
    <property name="dataSource" ref="dataSource"></property> <!--注入数据源-->
</bean>

<!-- 2.配置通知 -->
<tx:advice id="txadvice">
    <!-- 配置事务参数 -->
    <tx:attributes>
        <!-- 指定哪种规则的方法上面添加事务 -->
        <tx:method name="transferMoney" propagation="REQUIRED"/>
        <!--<tx:method name="trans*"/>-->
        </tx:attributes>
</tx:advice>
<!-- 配置切入点 -->
<aop:config>
    <aop:pointcut id="pt" expression="execution(* com.example.service.UserService.*(..))"/>
    <!-- 配置切面 -->
    <aop:advisor advice-ref="txadvice" pointcut-ref="pt"/>
</aop:config>
```

## 完全注解声明式事务管理
通过配置类替代配置文件. 测试的时候, context改为`ApplicationContext context = new AnnotationConfigApplicationContext(TxConfig.class);`.
```
@Configuration //配置类
@ComponentScan(basePackages = "com.example") //组件扫描
@EnableTransactionManagement //开启事务
public class TxConfig {
    //创建数据库连接池, 和配置文件效果一样
    @Bean
    public DruidDataSource getDruidDataSource() {
        DruidDataSource dataSource = new DruidDataSource();
        dataSource.setDriverClassName("com.mysql.jdbc.Driver");
        dataSource.setUrl("jdbc:mysql:///bank");
        dataSource.setUsername("root");
        dataSource.setPassword("jiayou1221");
        return dataSource;
    }

    //创建JdbcTemplate对象
    @Bean
    public JdbcTemplate getJdbcTemplate(DataSource dataSource) { //到ioc容器中根据类型找到dataSource
        JdbcTemplate jdbcTemplate = new JdbcTemplate();
        //注入dataSource, 不用再次getDruidDataSource()
        jdbcTemplate.setDataSource(dataSource);
        return jdbcTemplate;
    }

    //创建事务管理器
    @Bean
    public DataSourceTransactionManager getDataSourceTransactionManager(DataSource dataSource) {
        DataSourceTransactionManager transactionManager = new DataSourceTransactionManager();
        transactionManager.setDataSource(dataSource);
        return transactionManager;
    }
}
```


## 参考
1. [尚硅谷Spring5](https://www.bilibili.com/video/BV1Vf4y127N5?p=1)
2. Spring技术内幕