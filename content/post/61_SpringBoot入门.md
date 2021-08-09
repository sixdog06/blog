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

> 通过`@Validated`注解, 可以给数据进行**JSR303**(Java Specification Requests)数据校验

## 参考
1. [SpringBoot最新教程IDEA版通俗易懂-狂神说Java](https://www.bilibili.com/video/BV1PE411i7CV)
2. [Spring Boot - Introduction](https://www.tutorialspoint.com/spring_boot/spring_boot_introduction.htm)