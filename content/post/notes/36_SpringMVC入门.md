---
title: "SpringMVC"
date: 2021-07-25
draft: false
toc: true
categories: ["学习笔记"]
tags: ["SpringMVC"]
---

## Hello World
项目需要如下的包.
```
<dependencies>
    <!--Junit-->
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.12</version>
    </dependency>
    <!--数据库驱动-->
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>5.1.47</version>
    </dependency>
    <!--数据库连接池-->
    <dependency>
        <groupId>com.mchange</groupId>
        <artifactId>c3p0</artifactId>
        <version>0.9.5.2</version>
    </dependency>

    <!--Servlet-JSP -->
    <dependency>
        <groupId>javax.servlet</groupId>
        <artifactId>servlet-api</artifactId>
        <version>2.5</version>
    </dependency>
    <dependency>
        <groupId>javax.servlet.jsp</groupId>
        <artifactId>jsp-api</artifactId>
        <version>2.2</version>
    </dependency>
    <dependency>
        <groupId>javax.servlet</groupId>
        <artifactId>jstl</artifactId>
        <version>1.2</version>
    </dependency>

    <!--Mybatis-->
    <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis</artifactId>
        <version>3.5.2</version>
    </dependency>
    <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis-spring</artifactId>
        <version>2.0.2</version>
    </dependency>

    <!--Spring-->
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-webmvc</artifactId>
        <version>5.1.9.RELEASE</version>
    </dependency>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-jdbc</artifactId>
        <version>5.1.9.RELEASE</version>
    </dependency>
</dependencies>
```

controller代码如下, 实现`Controller`接口. 返回的`ModelAndView`实例
```
public class HelloController implements Controller {

    public ModelAndView handleRequest(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView mv = new ModelAndView();
        //这里写业务层代码
        mv.addObject("msg", "HelloSpringMVC!");
        mv.setViewName("hello");
        return mv;
    }
}
```

在`resource`目录下新建`springmvc-servlet.xml`. `/WEB-INF/jsp/`和`.jsp`是前缀和后缀, 所以这个目录下放一个名为`hello`的jsp文件, 就可以在文件中用`{msg}`去获取`HelloSpringMVC!`字符串. `InternalResourceViewResolver`就是视图解析器, 解析`ModelAndView`的数据, 并拼接视图数据.
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!--映射器-->
    <bean class="org.springframework.web.servlet.handler.BeanNameUrlHandlerMapping"/>
    <!--适配器-->
    <bean class="org.springframework.web.servlet.mvc.SimpleControllerHandlerAdapter"/>
    <!--视图解析器-->
    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver" id="InternalResourceViewResolver">
        <property name="prefix" value="/WEB-INF/jsp/"/>
        <property name="suffix" value=".jsp"/>
    </bean>

    <bean id="/hello" class="com.kuang.controller.HelloController"/>
</beans>
```

`web.xml`中包含了`DispatcherServlet`前置控制器, 是SpringMVC的**控制中心**. 而`<servlet-mapping>`则是去找映射器. `</url-pattern>`中一般为`/`, 表示只匹配请求, 如果为`/*`, 就会匹配所有文件(包括jsp文件).
```
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">
    <servlet>
        <servlet-name>springmvc</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class><!--spring提供的类-->
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value>classpath:springmvc-servlet.xml</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>

    <!--SpringMVC拦截所有请求-->
    <servlet-mapping>
        <servlet-name>springmvc</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>
</web-app>
```
![](/notes/notes36_1.png)


> 新建maven项目时, 我们可以见一个没有模板的项目, 再在module上右键选择`add framework support`, 选择webapp的版本(通常为4)

> 在`WEB-INF`文件夹下可能没有lib文件夹, 导致网页404, 手动在`project structure`中新建lib文件夹并把包导入即可

## 注解版Hello World
`web.xml`配置文件不变, 改动在`springmvc-servlet.xml`.
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:mvc="http://www.springframework.org/schema/mvc"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
   http://www.springframework.org/schema/beans/spring-beans.xsd
   http://www.springframework.org/schema/context
   http://www.springframework.org/schema/context/spring-context.xsd
   http://www.springframework.org/schema/mvc
   https://www.springframework.org/schema/mvc/spring-mvc.xsd">

    <!--扫描包, 让指定包的注解生效, 由ioc容器统一管理-->
    <context:component-scan base-package="com.kuang.controller"/>
    <!--让SpringMVC不处理静态资源-->
    <mvc:default-servlet-handler/>
    <!--
        在上下文注入DefaultAnnotationHandlerMapping和AnnotationMethodHandlerAdapter实例
    -->
    <mvc:annotation-driven/>

    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver" id="InternalResourceViewResolver">
        <property name="prefix" value="/WEB-INF/jsp/"/>
        <property name="suffix" value=".jsp"/>
    </bean>
</beans>
```

在Controller中只需要用注解`@RequestMapping`映射uri即可. 类上也可以加入一级`@RequestMapping`注解, 再在方法上加入二级注解.
```
@Controller
public class HelloController {

    @RequestMapping("/hello")
    public String hello(Model model) {

        model.addAttribute("msg", "Hello");
        return "hello";
    }
}
```

有时候我们想传值给controller, 可以通过如下方式, 并访问`http://localhost:8080/hello?a=1&b=1`, 就可以看到输出结果.
```
@Controller
public class HelloController {

    @RequestMapping("/hello")
    public String hello(int a, int b, Model model) {
        int res = a + b;
        model.addAttribute("msg", "Hello " + res);
        return "hello";
    }
}
```

要满足RESTful风格, 就需要如下控制器, 并且访问`http://localhost:8080/hello/1/2`.
```
@Controller
public class HelloController {

    @RequestMapping("/hello/{a}/{b}")
    public String hello(@PathVariable int a, @PathVariable int b, Model model) {
        int res = a + b;
        model.addAttribute("msg", "Hello " + res);
        return "hello";
    }
}
```

还可以限制请求的类型, 比如`@RequestMapping(value = "/hello/{a}/{b}", method = RequestMethod.GET)`, 或者直接通过注解`@GetMapping`限制. **所以就算url相同, 也可以通过请求方法的不同区分开.**

在return的时候, 可以通过`return "forward:/WEB-INF/jsp/hello.jsp";`**重定向**, 通过`return "redirect:/index.jsp";`**转发**, 这样视图解析器就失效了, 不会去拼接前缀和后缀.

## 前端交互
### 获取请求参数
第一种方式是用`@RequestParam("username")`, 一般不省略. 第二种是直接传入对象, 但是对象的字段必须一一对应, 否则为null, 这里要注意, 如果对象的字段不是包装类型, 那么int型默认返回0, 所以pojo类通常都需要用包装类型. 
```
@Controller
@RequestMapping("/user")
public class UserController {

    @GetMapping("/t1")
    public String test1(
            @RequestParam("username") String name,
            Model model) {
        System.out.println("name is" + name);
        model.addAttribute("msg", name);
        return "test";
    }

    @GetMapping("t2")
    public String test2(User user) {
        System.out.println(user);
        return "test";
    }
}
```

### 回显
一般用下面的三种类的实例进行数据的存储, 并回显
- Model: 简单存数据
- ModelMap: 继承了LinkMap, 所以有LinkedMap的特性
- ModelAndView: 可以设置返回的逻辑视图, 进行控制显示层跳转(一般不用)

## 参考
1. [SpringMVC最新教程IDEA版通俗易懂-狂神说Java](https://www.bilibili.com/video/BV1aE41167Tu)