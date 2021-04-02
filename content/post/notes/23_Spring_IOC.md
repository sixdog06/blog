---
title: "Spring-IOC"
date: 2021-01-16
draft: false
toc: true
categories: ["学习笔记"]
tags: ["Spring"]
---

![](/notes/notes23_2.png)

## 入门-创建对象
教育版的idea没有spring initializer, 建立普通Java工程就好. 创建好工程后将如下的jar文件(spring框架的依赖和日志依赖)添加进工程(project structure中).
![](/notes/notes23_1.png)

新建`User`类.
```
public class User {
    public void add() {
        System.out.println("add......");
    }
}
```

在`src`目录下新建名为`bean1.xml`的文件, 内容如下. 其中配置文件的包名要正确.
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!--配置 User 对象创建-->
    <bean id="user" class="com.example.User"></bean>
</beans>
```

创建一个类做单元测试. 需要`import org.junit.*;`.
```
public class TestSpring5 {

    @Test
    public void testAdd() {
        //1.加载spring配置文件
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        //2.获取配置创建的对象, user就是bean1中的id
        User user = context.getBean("user", User.class);
        System.out.println(user);
        user.add();
    }
}
```

跑通后输出如下. 第一行就是user的地址, 第二是方法的输出.
```
com.example.User@13c27452
add......
```

接下来开始介绍IOC.

## IOC底层原理
IOC(Inversion of control), 也就是控制反转. 把对象创建和对象之间的调用过程, 交给Spring进行管理. 减低耦合度. 通过xml解析->工厂模式->反射降低耦合度.

工厂方法**使得创建对象和使用对象分离**, 客户端总是引用抽象工厂和抽象产品, **子类决定将哪一个类实例化**, 工厂方法模式让一个类的实例化延迟到其子类. 我的理解是, 简单的工厂方法就像`Integer.valueOf(int i)`这种静态工厂方法, 我们一般调用这个静态方法而不是直接`new Integer(int i)`, 这样实际上降低了耦合度, `Integer.valueOf(int i)`内部怎么生产对象都不需要调用者考虑. 这个时候的`Integer`本身即是产品, 又是静态工厂. **用类的静态方法去创建对象**, 调用者只要调用这个静态方法就可以创建对象.

> 有三种方式通过反射在运行期获取class的Class实例
> 
> 1.直接通过class的静态变量class获取: `Class clazz = String.class;`
> 
> 2.如果有实例变量: `String s = "Hello"; Class clazz = s.getClass();`
> 
> 3.知道class的完整类名: `Class clazz = Class.forName("java.lang.String");`

总结一下IOC过程(2步):
1. xml配置文件, 配置创建的对象`<bean id="user" class="com.example.User"></bean>`.

2. 创建工厂类
```
class User {
    add() {...}
}

// User的工厂类
class UserFactory {
    public static User get() {
        String classValue = class属性值; //xml解析出完整类名
        Class clazz = Class.forName(classValue); //通过反射得到Class实例
        return (User)clazz.newInstance(); //通过clazz创建User对象
    }
}
```

最后就可以通过工厂来调用了. 将耦合度降到最低, 对象创建和调用的过程都统一交给Spring处理.
```
class UserService {
    execute() {
        User user = UserFactory.get();
        user.add();
    }
}
```

## IOC容器
- IOC思想**基于IOC容器完成**, IOC容器底层就是对象工厂
- Spring提供IOC容器实现两种方式(接口). `BeanFactory`是IOC容器基本实现, 是Spring内部的使用接口, 不提供开发人员进行使用. 加载配置文件时候不会创建对象, 在获取(使用)对象才去创建对象; `ApplicationContext`是`BeanFactory`接口的子接口, 提供更多更强大的功能, 一般由开发人员进行使用. 加载配置文件时候就会把在配置文件对象进行创建
- `ApplicationContext`接口有实现类: `FileSystemXmlApplicationContext`和`ClassPathXmlApplicationContext`


## IOC操作Bean管理
Bean管理指**Spring创建对象**和**Spirng注入属性**两种操作. 而管理操作有两种实现方式, **基于xml配置文件方式实现**和**基于注解方式实现**. 

### 基于xml方式创建对象
也就是上面的
```
<!--配置 User 对象创建-->
<bean id="user" class="com.example.User"></bean>
```
在spring配置文件中, 使用bean标签, 并在标签里面添加对应属性, 来实现对象的创建. 在bean标签有很多属性, 先了解常用的属性. `id`: 对象的唯一标识(别名); `class`: 类的全路径. 创建对象的时候, 默认是执行无参数的构造方法.

### 基于xml方式注入属性
**Dependency Injection(DI)**是IOC的具体实现, 也就是注入属性. 注入一般有两种方式. 用**set方法注入属性**或者用**有参构造器注入属性**.

#### set方法注入属性
首先我们新建一个`Book`类来进行测试. 
```
public class Book {

    private String name;
    private String author;

    public void setname(String name) {
        this.name = name;
    }
    public void setauthor(String author) {
        this.author = author;
    }
    public void test() {
        System.out.println(this.name + " " + this.author);
    }
}
```
在配置文件中, 用`property`完成属性注入, 其中`name`表示属性名, `property`表示属性注入的值. 
```
<bean id="book" class="com.example.Book">
    <property name="bname" value="zhang3"></property>
    <property name="bauthor" value="li4"></property>
</bean>
```

然后进行测试.
```
public class TestSpring5 {
    @Test
    public void testAdd() {
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        Book book = context.getBean("book", Book.class);
        System.out.println(book);
        book.test(); //打印的值就是配置文件中配置的值
    }
}
```

#### 有参构造器注入
新建`Orders`类, 这里只有有参构造器, 所以上面的方法就不能用了.
```
public class Orders {
    private String name;
    private String address;

    public Orders(String name,String address) {
        this.name = name;
        this.address = address;
    }

    public void test() {
        System.out.println(name + " " + address);
    }
}
```

用有参构造器注入.
```
<bean id="orders" class="com.example.Orders">
    <constructor-arg name="name" value="mobile"></constructor-arg>
    <constructor-arg name="address" value="tokyo"></constructor-arg>
</bean>
```

测试. 打印对应属性. 
```
public class TestSpring5 {

    @Test
    public void testAdd() {
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        Orders orders = context.getBean("orders", Orders.class);
        System.out.println(orders);
        orders.test();
    }
}
```

> 也可以简化操作, 在配置文件加上`xmlns:p="http://www.springframework.org/schema/p"`, bean标签中就只用一行`<bean id="book" class="com.atguigu.spring5.Book" p:bname="very" p:bauthor="good">`进行注入.

### 注入字面量
字面量(默认用等号初始化的属性).
```
<bean id="book" class="com.example.Book">
    <!--null值-->
    <property name="address">
        <null/><!--属性里边添加一个null标签-->
    </property>
    
    <!--特殊符号赋值-->
     <!--属性值包含特殊符号
       a 把<>进行转义, &lt, &gt也可以替代<>
       b 把带特殊符号内容写到CDATA
      -->
        <property name="address">
            <value><![CDATA[<<南京>>]]></value>
        </property>
</bean>
```

### 注入外部Bean
新建`dao` package和`service` package. `dao`下包含`UserDao`接口以及其实现类`UserDaoImpl`. `service`我们直接简化, 用一个类`UserService`.
```
public interface UserDao {
    public void update();
}
```
```
public class UserDaoImpl implements UserDao{
    @Override
    public void update() {
        System.out.println("dao update!");
    }
}
```
```
public class UserService {//service类

    //创建UserDao类型属性, 生成set方法, 这个属性的类型是我们自己创建的
    private UserDao userDao;
    public void setUserDao(UserDao userDao) {
        this.userDao = userDao;
    }

    public void add() {
        System.out.println("service add");
        userDao.update(); //调用dao方法
    }
}
```

配置文件`bean2`. 其中`ref`就是将外部bean的对象注入了进来, 也就是说, `userDaoImpl`对应的是外面的`<bean id="userDaoImpl" class="com.example.dao.UserDaoImpl"></bean>`这个bean. `userDaoImpl`只要名字对应即可, 为了不confusing, 用了和实现类同样的名字.
```
<bean id="userService" class="com.example.service.UserService">
    <!--注入userDao对象
        name属性：类里面的属性名称
        ref属性：创建userDao对象bean标签id值
    -->
    <property name="userDao" ref="userDaoImpl"></property>
</bean>
<bean id="userDaoImpl" class="com.example.dao.UserDaoImpl"></bean>
```

最后进行测试.
```
public class TestSpring5 {

    @Test
    public void testAdd() {
        //1.加载spring配置文件
        ApplicationContext context = new ClassPathXmlApplicationContext("bean2.xml");
        //2 获取配置创建的对象
        UserService userService = context.getBean("userService", UserService.class);
        System.out.println(userService);
        userService.add(); //打印service add和dao update!
    }
}
```

### 注入内部bean
效果和外部bean类似, 但是在配置文件中没有用`ref`, 而是直接在`property`内部包含bean, 这个bean的作用是创建对象.
```
public class Dept {

    private String dname;
    public void setDname(String dname) {
        this.dname = dname;
    }
    public String getDname() {
        return dname;
    }
}
```

```
public class Emp {
    private String ename;
    private String gender;
    private Dept dept; //员工属于的部门

    public void setDept(Dept dept) {
        this.dept = dept;
    }
    public void setEname(String ename) {
        this.ename = ename;
    }
    public void setGender(String gender) {
        this.gender = gender;
    }

    public void test() {
        System.out.println(ename + " " + gender + " " + dept.getDname());
    }
}
```

配置文件.
```
<bean id="emp" class="com.example.bean.Emp">
    <!--设置两个普通属性-->
    <property name="ename" value="li4"></property>
    <property name="gender" value="female"></property>

    <!--设置对象类型属性-->
    <property name="dept">
        <!--内部包含一个bean-->
        <bean id="dept" class="com.example.bean.Dept">
            <property name="dname" value="IT_dep"></property>
        </bean>
    </property>
</bean>
```

测试.
```
@Test
public void testBean2() {
    //1.加载spring配置文件
    ApplicationContext context = new ClassPathXmlApplicationContext("bean3.xml");
    //2 获取配置创建的对象
    Emp emp = context.getBean("emp", Emp.class);
    emp.test();
}
```

有时候我们需要**级联赋值**, 也就是给不同的对象都赋值. 一般的配置文件写法如下.
```
<bean id="emp" class="com.example.bean.Emp">
    <!--设置两个普通属性-->
    <property name="ename" value="li4"></property>
    <property name="gender" value="female"></property>
    <!--级联赋值-->
    <property name="dept" ref="dept"></property>
</bean>
<bean id="dept" class="com.example.bean.Dept">
    <property name="dname" value="IT_dep"></property>
</bean>
```

还有一种写法
```
<bean id="emp" class="com.example.bean.Emp">
    <!--设置两个普通属性-->
    <property name="ename" value="li4"></property>
    <property name="gender" value="female"></property>
    <!--级联赋值-->
    <property name="dept" ref="dept"></property>
    <property name="dept.dname" value="IT_dep"></property> //直接用.来指向属性
</bean>
<bean id="dept" class="com.example.bean.Dept">
</bean>
```

这种写法要求在`Emp`类中增加`dept`的getter. 否则拿不到这个属性. 即使`dept`是`public`也需要`getDept`作为一个接口去拿这个属性.

### xml注入集合属性
```
public class Stu {

    private String[] courses;
    private List<String> list;
    private Map<String, String> maps;
    private Set<String> sets;
    private List<Course> courseList;

    public void setSets(Set<String> sets) {
        this.sets = sets;
    }

    public void setCourses(String[] courses) {
        this.courses = courses;
    }

    public void setList(List<String> list) {
        this.list = list;
    }

    public void setMaps(Map<String, String> maps) {
        this.maps = maps;
    }

    public void setCourseList(List<Course> courseList) {
        this.courseList = courseList;
    }

    public void test() {
        System.out.println(Arrays.toString(courses));
        System.out.println(list);
        System.out.println(maps);
        System.out.println(sets);
        System.out.println(courseList);
    }
}
```

配置文件.
```
<bean id="stu" class="com.example.collectiontype.Stu">
    <!--数组类型属性注入-->
    <property name="courses">
        <array>
            <value>array1</value>
            <value>array2</value>
        </array>
    </property>

    <!--list类型属性注入-->
    <property name="list">
        <list>
            <value>list1</value>
            <value>list2</value>
        </list>
    </property>

    <!--map类型属性注入-->
    <property name="maps">
        <map>
            <entry key="key1" value="value1"></entry>
            <entry key="key2" value="value2"></entry>
        </map>
    </property>

    <!--set类型属性注入-->
    <property name="sets">
        <set>
            <value>set1</value>
            <value>set2</value>
        </set>
    </property>

    <!--注入list集合类型, 里面的元素都是Course对象-->
    <property name="courseList">
        <list>
            <ref bean="course1"></ref>
            <ref bean="course2"></ref>
        </list>
    </property>
</bean>

<!--创建多个course对象-->
<bean id="course1" class="com.example.collectiontype.Course">
    <property name="cname" value="c1"></property>
</bean>
<bean id="course2" class="com.example.collectiontype.Course">
    <property name="cname" value="c2"></property>
</bean>
</beans>
```

其中`Course`对应.
```
public class Course {
    private String cname;
    public void setCname(String cname) {
        this.cname = cname;
    }
    @Override
    public String toString() {
        return "Course{" +
                "cname='" + cname + '\'' +
                '}';
    }
}
```

测试代码.
```
public class TestSpringDemo1 {

    @Test
    public void testCollection() {
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        Stu stu = context.getBean("stu", Stu.class);
        stu.test();
    }
}
```

### 集合注入提取
用util标签完成list集合注入提取, 注意这里的配置文件头有了改变.
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:p="http://www.springframework.org/schema/p"
       xmlns:util="http://www.springframework.org/schema/util"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/util
       http://www.springframework.org/schema/util/spring-util.xsd">

        <util:list id="bookList">
            <value>book1</value>
            <value>book2</value>
            <value>book3</value>
        </util:list>

        <!--提取list集合类型属性注入使用-->
        <bean id="book" class="com.example.collectiontype.Book">
            <property name="list" ref="bookList"></property>
        </bean>
</beans>
```

`Book`类如下. 测试代码与前面类似, 最后打印`[book1, book2, book3]`.
```
public class Book {
    private List<String> list;

    public void setList(List<String> list) {
        this.list = list;
    }
    public void test() {
        System.out.println(list);
    }
}
```

### FactoryBean
前面的普通bean, 配置文件中定义bean类型就是返回类型. 而**工厂bean在配置文件中定义的bean类型和返回类型可以不同**.
1. 创建类并让这个类作为工厂bean, 实现接口`FactoryBean`
2. 实现接口里面的方法, 在实现的方法中定义返回的bean类型

做一个测试. 新建`MyBean`类, 去实现`FactoryBean`类, 并重写了三个方法.
```
public class MyBean implements FactoryBean<Course> {

    @Override
    public Course getObject() throws Exception { //返回course对象
        Course course = new Course();
        course.setCname("abc");
        return course;
    }
    @Override
    public Class<?> getObjectType() {
        return null;
    }
    @Override
    public boolean isSingleton() {
        return false;
    }
}
```

配置文件依然是`<bean id="myBean" class="com.example.factorybean.MyBean"></bean>`. 用如下代码测试, 返回的实际上是`Course`类.
```
@Test
public void testCollection3() {
    ApplicationContext context = new ClassPathXmlApplicationContext("bean3.xml");
    //MyBean myBean = context.getBean("myBean", MyBean.class); //普通bean返回相同类对象
    Course course = context.getBean("myBean", Course.class); //工厂bean返回不同类对象
    System.out.println(course);
}
```

## Bean的作用域
Spring中, 可以设置创建bean实例是**单实例**还是**多实例**(默认是单实例). 比如用前面的`Book`类做测试, 在测试的时候创建两个`Book`对象并打印, 会发现他们的对象地址是一样的. 改为多实例后:
```
    <bean id="book" class="com.example.collectiontype.Book" scope="prototype">
        <property name="list" ref="bookList"></property>
    </bean>
```
打印的对象地址就不同了. 而如果scope是`singleton`(默认), 那么实际上在加载配置文件的的时候就已经就已经会创建单实例对象. 反之, 在多实例作用域下, 在调用getBean的时候才会创建多实例对象. 除此之外还有request(一次请求)和session(一次对话).

## Bean生命周期
Bean生命周期指**对象创建到对象销毁的过程**. 
1. 通过构造器创建Bean实例(无参数构造)
2. 为Bean的属性设置值和对其他Bean引用(调用set方法)
3. 调用Bean的初始化的方法(初始化的方法需要配置)
4. Bean可以用了, 也就是说获取到了对象
5. 当容器关闭时候, 调用Bean的销毁的方法(销毁的方法需要配置)
对生命周期进行测试, 新建`Orders`类. 
```
public class Orders {
    public Orders() {
        System.out.println("1.执行无参数构造创建bean实例");
    }

    private String oname;
    public void setOname(String oname) {
        this.oname = oname;
        System.out.println("2.调用set方法设置属性值");
    }

    public void initMethod() {
        System.out.println("3.执行初始化的方法");
    }

    public void destroyMethod() {
        System.out.println("5.执行销毁的方法");
    }
}
```

在配置文件中:
```
    <bean id="orders" class="com.example.bean.Orders" init-method="initMethod" destroy-method="destroyMethod"> <!--对应初始化和销毁-->
        <property name="oname" value="手机"></property>
    </bean>
```

最后测试:
```
    @Test
    public void testCollection4() {
        ApplicationContext context = new ClassPathXmlApplicationContext("bean4.xml");
        Orders orders = context.getBean("orders", Orders.class);
        System.out.println(orders);
        System.out.println("4.获取bean实例对象");
        //ApplicationContext中没有close()方法, 所以这里向下转型
        //或者初始化的时候直接让指针为ClassPathXmlApplicationContext也可
        ((ClassPathXmlApplicationContext) context).close();
    }
```

在初始化之前和之后也可以执行方法. 新建一个类`MyBeanPost`去实现`BeanPostProcessor`.
```
public class MyBeanPost implements BeanPostProcessor {
    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        System.out.println("在初始化之前执行的方法");
        return bean;
    }
    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        System.out.println("在初始化之后执行的方法");
        return bean;
    }
}
```

在配置文件中加入`<bean id="myBeanPost" class="com.example.bean.MyBeanPost"></bean>`. 那么整个输出就如下.
```
1.执行无参数构造创建bean实例
2.调用set方法设置属性值
在初始化之前执行的方法
3.执行初始化的方法
在初始化之后执行的方法
com.example.bean.Orders@2a70a3d8
4.获取bean实例对象
5.执行销毁的方法
```

## xml自动装配
根据指定装配规则(属性名称/属性类型), Spring自动将匹配的属性值进行注入. 声明两个类进行测试.
```
public class Dept {

    @Override
    public String toString() {
        return "Dept{}";
    }
}

public class Emp {

    private Dept dept;

    public void setDept(Dept dept) {
        this.dept = dept;
    }

    @Override
    public String toString() {
        return "Emp{" +
                "dept=" + dept +
                '}';
    }

    public void test() {
        System.out.println(dept);
    }
}
```

那么配置文件中需要手动注入`dept`.
```
<bean id="emp" class="com.example.autowire.Emp">
    <property name="dept" ref="dept"></property> <!--手动注入-->
</bean>
<bean id="dept" class="com.example.autowire.Dept"></bean>
```

而自动注入有两种, 如果是`byName`那么如下. 但是这个名字一定要**属性名称和bean的id对应**. 也可以`byType`, 要求只有一个该类型的属性.
```
<bean id="emp" class="com.example.autowire.Emp" autowire="byName"></bean>
<bean id="dept" class="com.example.autowire.Dept"></bean>
```

### 外部属性文件
用阿里的德鲁伊连接池做测试. 
1. 直接配置数据库信息
```
<!--直接配置连接池-->
<bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource">
    <property name="driverClassName" value="com.mysql.jdbc.Driver"></property>
    <property name="url" value="jdbc:mysql://localhost:3306/userDb"></property>
    <property name="username" value="root"></property>
    <property name="password" value="root"></property>
</bean>
```

2. 引入外部属性文件配置数据库连接池
```
prop.driverClass=com.mysql.jdbc.Driver
prop.url=jdbc:mysql://localhost:3306/userDb
prop.userName=root
prop.password=root
```

3. 最后我们用相对路径重新写`bean`
```
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd"><!--引入context名称空间-->
    <!--引入外部属性文件-->
    <context:property-placeholder location="classpath:jdbc.properties"/>

    <!--配置连接池-->
    <bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource">
        <property name="driverClassName" value="${prop.driverClass}"></property>
        <property name="url" value="${prop.url}"></property>
        <property name="username" value="${prop.userName}"></property>
        <property name="password" value="${prop.password}"></property>
    </bean>
</beans>
```

## 注解方式
### 创建类
使用注解目就可以简化xml配置(类/方法/属性上). 有`@Component/@Service/@Controller/@Repository`这4个注解, 他们的功能一样, 都可以用来创建bean实例.

首先把`spring-aop-5.3.2.jar`包加入工程. 在配置文件中依然引入context名称空间, 并加入: `<context:component-scan base-package="com.example"> </context:component-scan>`, 如果有多个包, 则用逗号隔开. 这一步的目的是确认组件扫描的位置.

对应的类如下, 
```
//在注解中value默认值是类名称(首字母小写), 会被注解扫描扫描到
@Component(value = "userService") //<bean id="userService" class=".."/>
public class UserService {
    public void add() {
        System.out.println("service add..");
    }
}
```

扫描可以具体去配置. `use-defaultfilters="false"`表示不适用默认的filter
```
<context:component-scan base-package="com.example" use-defaultfilters="false">
<context:include-filter type="annotation" expression="org.springframework.stereotype.Controller"/><!--只扫描Controller注解的类-->
</context:component-scan>

<context:component-scan base-package="com.example">
<context:exclude-filter type="annotation" expression="org.springframework.stereotype.Controller"/><!--扫描除了Controller注解的类-->
</context:component-scan>
```

### 属性注入
1. `@Autowired`: 根据类型注入.
2. `@Qualifier`: 根据名称进行注入, 和上面`@Autowired`一起使用.
```
@Autowired //根据类型进行注入
@Qualifier(value = "userDaoImpl1") //根据名称进行注入, 否则是与类名相同的默认名(首字母小写)
private UserDao userDao; //内部就可以不用setter了
```
3. `@Resource`: 可以根据类型或名称注入. 什么都不加则根据类型注入, 用`@Resource(name = "userDaoImpl1")`则根据名称进行注入, 对应对象的名字`@Repository(value = "userDaoImpl1")`. 这个是在javax扩展包的注解, 而不是spring中的.
4. `@Value`: 注入普通类型属性. 不管是String还是整形浮点型, 都要加双引号.
```
@Value(value = "abc") 
private String name;
```

### 纯注解开发
不用xml配置文件. 而是新建一个配置类, 来完成包扫描.
```
@Configuration //作为配置类, 替代xml配置文件
@ComponentScan(basePackages = {"com.example"})
public class SpringConfig {

}
```

在测试的时候, 用`AnnotationConfigApplicationContext.class`来加载配置类, 其他操作和之前一样.
```
@Test
public void test6() {
    ApplicationContext context = new AnnotationConfigApplicationContext(SpringConfig.class);
    UserService userService = context.getBean("userService", UserService.class);
    userService.add();
}
```

## 参考
1. [尚硅谷Spring5](https://www.bilibili.com/video/BV1Vf4y127N5?p=1)
2. Spring技术内幕
3. [工厂模式](https://www.liaoxuefeng.com/wiki/1252599548343744/1281319170474017)