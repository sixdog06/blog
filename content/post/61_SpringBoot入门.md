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

### 配置MVC
可以简单地用以下类测试, 并在`class DispatcherServlet-method doDispatch`中打断点, 可以看到`this-viewResolvers`, 也就是视图解析器实例加载的解析器下包含了我们的`MyMvcConfig`. 除此之外还可以看到其他的视图解析器, 比如我们刚才配置的`ThymeleafViewResolver`.
```
@Configuration
public class MyMvcConfig implements WebMvcConfigurer {

    /**
     * 配置自己的视图解析器
     * @return 自定义的视图解析器class
     */
    @Bean
    public ViewResolver myViewResolver() {
        return new MyViewResolver();
    }

    /**
     * 自定义的视图解析器
     */
    public static class MyViewResolver implements ViewResolver {
        @Override
        public View resolveViewName(String viewName, Locale locale) {
            return null;
        }
    }
}
```

更好的方式是去实现`WebMvcConfigurer`的配置.
```
@Override
public void addViewControllers(ViewControllerRegistry registry) {
    registry.addViewController("/kuang").setViewName("test");
}
```

> 官方文档特别强调不能加入`@EnableWebMvc`配置类, 否则自动配置会因为condition失效

## 整合数据库
### jdbc
我做实验的时候, `spring-boot-starter-parent`已经到了`2.5.4`. 会无法自动注入`DataSource`, 报错的信息是如下, 所以导入**对应版本的依赖**即可.
```
Cannot resolve org.springframework:spring-tx:5.3.9
Cannot resolve com.zaxxer:HikariCP:4.0.3
```

配置数据库:
```
spring:
  datasource:
    username: root
    password: 123
    url: jdbc:mysql://localhost:3306/myemployees?serverTimezone=UTC&useUnicode=true&characterEncoding=utf-8
    driver-class-name: com.mysql.cj.jdbc.Driver
```

配置好吼, 就可以注入`DataSource`, 证明我们的数据源已经被自动配置了. 接下来就可以通过注入`JdbcTemplate`来进行数据库的CRUD. 比如`jdbcTemplate.queryForList(sql);`/`jdbcTemplate.update(sql);`等等操作.

还可以整合Mybatis, 都是配置即可, 我选Mybatis简单了解. 首先导入包, 我们可以发现`artifactid`的开头是`mybatis-spring-boot-xxx`, 而不是`spring-boot-xxx`, 说明这个不是springboot官方提供的包.
```
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>2.1.1</version>
</dependency>
```

mybatis需要在application文件中额外配置如下信息, 直接用即可.
```
mybatis:
  type-aliases-package: com.kuang.pojo
  mapper-locations: classpath/mapper/*.xml
```

## SpringSecurity
用SpringSecurity可以帮助实现登陆的验证. 
```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

首先需要一个controller来做实验, 子页面分别有`level1/level2/level3`构成. 
```
@Controller
public class RouterController {

    @RequestMapping({"/","/index"})
    public String index(){
        return "index";
    }

    @RequestMapping("/toLogin")
    public String toLogin(){
        return "views/login";
    }

    @RequestMapping("/level1/{id}")
    public String level1(@PathVariable("id") int id){
        return "views/level1/"+id;
    }

    @RequestMapping("/level2/{id}")
    public String level2(@PathVariable("id") int id){
        return "views/level2/"+id;
    }

    @RequestMapping("/level3/{id}")
    public String level3(@PathVariable("id") int id){
        return "views/level3/"+id;
    }
}
```

写一个类来拦截请求, 分配权限. 测试的时候就会发现, 对应的用户才能访问对应的资源文件. `BCryptPasswordEncoder`是将密码加密的方法, 业务中通常都会对敏感信息进行加密处理.
```
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests().antMatchers("/").permitAll()
                .antMatchers("/level1/**").hasRole("vip1")
                .antMatchers("/level2/**").hasRole("vip2")
                .antMatchers("/level3/**").hasRole("vip3");
        http.formLogin();
        // 开启注销功能, 注销成功则跳转
        http.logout().logoutSuccessUrl("/");
        // 开启记住我功能
        http.rememberMe();
    }

    //定义认证规则
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {

        auth.inMemoryAuthentication().passwordEncoder(new BCryptPasswordEncoder())
                .withUser("zhangsan").password(new BCryptPasswordEncoder().encode("123")).roles("vip2","vip3")
                .and()
                .withUser("lisi").password(new BCryptPasswordEncoder().encode("123")).roles("vip1","vip2","vip3")
                .and()
                .withUser("wangwu").password(new BCryptPasswordEncoder().encode("123")).roles("vip1","vip2");
    }
}
```

很多情况下, 我们更希望用自己写的登录页面, 也可以通过配置复用SpringSecurity的验证逻辑, 比如配置`http.formLogin().loginPage("/toLogin").usernameParameter("user").passwordParameter("pwd").loginProcessingUrl("login");`, 登陆时就会走`login`.  `xxxParameter`方法可以用来传递参数. `rememberMe`方法也是同样的道理, 用`rememberMeParameter`可以传递这个记住我的参数, 用checkbox组件捕获即可.


## 参考
1. [SpringBoot-狂神说Java](https://www.bilibili.com/video/BV1PE411i7CV)
2. [Spring Boot-Introduction](https://www.tutorialspoint.com/spring_boot/spring_boot_introduction.htm)