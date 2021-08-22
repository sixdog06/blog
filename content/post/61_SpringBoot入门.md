---
title: "SpringBoot入门"
date: 2021-08-15
draft: false
toc: true
categories: ["学习笔记"]
tags: ["SpringBoot"]
---

Spring Boot is an open source Java-based framework used to create a micro Service. It is developed by Pivotal Team and is used to build stand-alone and production ready spring applications. Micro Service is an architecture that allows the developers to develop and deploy services independently. Each service running has its own process and this achieves the lightweight model to support business applications.

## Hello World
SpringBoot生成非常简单, 直接新建一个Spring Initializr project并配置. 比如我们建一个名叫helloworld的项目, 就会生成`HelloworldApplication`的类, 这个类下就包含了启动项目的方法. 在同一个包下, 就可以新建其他包, 写controller等等.

SpringBoot可以用`yaml`文件进行配置, 比如我们配置一个`application.yaml`文件:
```
person:
  name: zhangsan
  age: 20
  happy: false
  birth: 2000/01/01
  maps: {k1: v1, k2: v2}
  lists:
    - code
    - eat
    - sleep
  dog:
    name: 柯基
    age: 1
```

实际上就是给实体类的字段进行了配置, 在实体类上加入注解即可. `prefix`对应是yaml文件的前缀, 而`Dog`类直接用了`Value`进行字段的初始化.
```
@Component
@ConfigurationProperties(prefix = "person")
public class Person {

    private String name;
    private Integer age;
    private Boolean happy;
    private Date birth;
    private Map<String, Object> maps;
    private List<Object> lists;
    private Dog dog;
}

@Component
public class Dog {

    @Value("狗")
    private String name;
    @Value("3")
    private Integer age;
}
```

 如果用`@Autowired`注入这两个类, 打印结果如下, 也就是说`Person`类下的dog实际上已经是在字段初始化后再进行赋值的结果了.
 ```
Dog{name='狗', age=3}
Person{name='zhangsan', age=20, happy=false, birth=Sat Jan 01 00:00:00 CST 2000, maps={k1=v1, k2=v2}, lists=[code, eat, sleep], dog=Dog{name='柯基', age=1}}
 ```

 yaml还支持多环境配置, 通过`---`分开不同环境. 
 ```
server:
  port: 8081
spring:
  profiles:
    active: prod
---
server:
  port: 8083
spring:
  profiles: dev
---
server:
  port: 8084
spring:
  profiles: prod
 ```


给容器中自动配置类添加组件的时候, 会从properties类中获取属性, 我们只需要在配置文件中指定这些属性的值即可. 源码中的`xxxAutoConfigurartion`就是自动配置类(配置类中的`Conditionalxxx`注解会控制配置类是否生效), 而`xxxProperties`封装了配置文件中的相关属性. 在配置文件中加入`debug=true`, 就能打印所有加载的配置. 

> 通过`@Validated`注解, 可以给数据进行**JSR303**(Java Specification Requests)数据校验

## Web开发
### 静态资源导入
可以通过webjars处理, 也可以放在resources下的resources/static/public目录, 优先级依次降低. 而templates中一般放动态页面, 需要通过controller访问. 动态网页传值时需要用模板引擎, springboot推荐的是thymyleaf, 导入如下maven依赖即可.
```
<dependency>
    <groupId>org.thymeleaf</groupId>
    <artifactId>thymeleaf-spring5</artifactId>
    <version>3.0.12.RELEASE</version>
</dependency>
```

编写controller:
```
@Controller
public class IndexController {

    @RequestMapping("/test")
    public String test(Model model) {
        model.addAttribute("msg", "<h1>hello springboot</h1>");
        model.addAttribute("users", Arrays.asList("zhang3", "li4"));
        return "test";
    }
}
```

html文件中通过`th:`与`${}`去取model中传入的值. `text`原封不动地输出了`msg`中的文本, 而`utext`标签下的文本把`<h1>`标签转义了. thymyleaf还可以通过`each`去读取一个list中的元素.
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<div th:text="${msg}">123</div>
<div th:utext="${msg}">123</div>
<div th:each="user:${users}" th:text="${user}"></div>
</body>
</html>
``` 

## 参考
1. [SpringBoot最新教程IDEA版通俗易懂-狂神说Java](https://www.bilibili.com/video/BV1PE411i7CV)
2. [Spring Boot - Introduction](https://www.tutorialspoint.com/spring_boot/spring_boot_introduction.htm)