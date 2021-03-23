---
title: "SpringBoot-基础"
date: 2021-01-24
draft: false
toc: true
categories: ["Spring"]
tags: ["SpringBoot"]
---

base在原生的Spring之上, 有自动化配置, 大大简化了开发, 不用去手写xml了, 在microservice/reactive/cloud/web/serverless等都有应用. **是整个Spring生态圈的框架**. 

现在有三个热门的场景. [微服务](https://martinfowler.com/microservices/)是一种架构风格, 把一个应用拆分为一组小型服务. 每个服务运行在自己的进程内, 可独立部署和升级. 服务之间使用轻量级HTTP交互, 围绕业务功能拆分, 并且由全自动部署机制独立部署. 既然有微服务拆分了服务, 自然就形成大型的应用分布式, 通常由SpringBoot+SpringCloud解决. 困难点在远程调用/服务发现/负载均衡/日志管理等等. SpringBoot来编写微服务, SpringCloud把这些服务互联, 数据流由Spring Cloud Data Flow来管理响应式数据流. 而应用想要上云, 又会遇到服务自愈/弹性伸缩/服务隔离/自动化部署/灰度发布/流量治理等问题.

## HelloWorld
SpringBoot版本迭代很快, 视频中用的是老版本的, 配置Maven的时候我是用的视频中的那一套. 写这篇博客的时候SpringBoot已经到了2.4.2.
```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>boot-01-helloworld</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.3.4.RELEASE</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>
</project>
```

新建两个类进行测试, 并直接运行`main`方法. 最后访问`http://localhost:8080/hello`就可以得到输出.
```
@SpringBootApplication
public class MainApplication {
    //主程序引导SpringBoot启动
    public static void main(String[] args) {
        SpringApplication.run(MainApplication.class, args);
    }
}
```
```
@RestController
public class HelloController {

    @RequestMapping("/hello")
    public String handle01(){
        return "Hello, Spring Boot 2!";
    }
}
```

可以在resources中新建`application.properties`文件, 在其中进行配置, 比如加入`server.port=8888`, 就可以在8888端口上打开服务. 而部署的时候也可以直接引入插件, 把项目直接打成jar包, 直接在服务器上运行. 直接在maven中`clean`+`package`, 在target文件夹中就有`boot-01-helloworld-1.0-SNAPSHOT.jar`, 可以被直接执行. 可以用terminal直接输入`java -jar boot-01-helloworld-1.0-SNAPSHOT.jar`进行测试.
```
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```

## 参考
1. [尚硅谷Spring5](https://www.bilibili.com/video/BV19K4y1L7MT?p=1)
2. Spring技术内幕