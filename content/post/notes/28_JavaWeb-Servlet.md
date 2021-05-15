---
title: "JavaWeb-Servlet"
date: 2021-05-14
draft: false
toc: true
categories: ["学习笔记"]
tags: ["JavaWeb"]
---

## 实验
在MVN repository中找`Java Servlet API/jsp api`, 导入maven. 除了通过maven导入, 也可以在`Project Structure-Module`导入. 删掉src, 在父项目下创建一个webapp类型的子module, 这个子项目默认继承了父项目的jar包, 将web.xml修改为最新的.
```
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee
        http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
        version="4.0">

</web-app>
```

写Class, 我们重写`doGet`和`doPost`.
```
public class HelloServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        System.out.println("run doGet");
        PrintWriter writer = resp.getWriter();
        writer.print("Hello, Servlet");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        super.doPost(req, resp);
    }
}
```

创建映射并配置Tomcat, 直接run即可. 现实的是默认的hello world界面, 在url后面加上`hello`, `"Hello, Servlet"`就可以被打印了. 还可以用`*`来代替所有, 但是`*`前不能加项目映射路径, `*`通配符的优先级低于固有映射路径.
```
<!--注册Servlet-->
<servlet>
    <servlet-name>hello</servlet-name>
    <servlet-class>com.kuang.servlet.HelloServlet</servlet-class>
</servlet>
<!--Servlet的请求路径-->
<servlet-mapping>
    <servlet-name>hello</servlet-name>
    <url-pattern>/hello</url-pattern>
</servlet-mapping>
```

## ServletContext
web容器(Tomcat), 为每个Web成都旭出在哪构建一个对应的ServletContext对象, 代表当前的Web应用. ServletContext的作用是防止一些数据. 我们新建一个类, 用来放置数据
```
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        System.out.println("Hello");

        ServletContext servletContext = this.getServletContext();
        String username = "Harry";
        servletContext.setAttribute("username", username);
    }
}
```

再建一个类, 用来读取数据, 配置对应的`web.xml`.
```
public class GetServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        ServletContext servletContext = this.getServletContext();
        String username = (String) servletContext.getAttribute("username");

        resp.setContentType("text/html");
        resp.setCharacterEncoding("utf-8");
        resp.getWriter().println("name is "+username);

    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        super.doPost(req, resp);
    }
}
```

```
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee
        http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">
    <servlet>
        <servlet-name>hello</servlet-name>
        <servlet-class>com.kuang.servlet.HelloServlet</servlet-class>
    </servlet>
    <servlet-mapping>
        <servlet-name>hello</servlet-name>
        <url-pattern>/hello</url-pattern>
    </servlet-mapping>

    <servlet>
        <servlet-name>getc</servlet-name>
        <servlet-class>com.kuang.servlet.GetServlet</servlet-class>
    </servlet>
    <servlet-mapping>
        <servlet-name>getc</servlet-name>
        <url-pattern>/getc</url-pattern>
    </servlet-mapping>
</web-app>
```

启动Tomcat, 如果直接进入`getc`路径, 会显示`name is null`. 当加载了`hello`后再打开`getc`路径(也就是加载了数据之后), 就会显示`name is Harry`.

再尝试一下转发(区别于重定向).
```
public class ServletDemo04 extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        ServletContext context = this.getServletContext();
        System.out.println("Demo04");
        context.getRequestDispatcher("/getc").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        super.doGet(req, resp);
    }
}
```

配置如下, 访问sd4实际上就是访问`getc`路径, 状态码是200, 证明并没有重定向.
```
<servlet>
    <servlet-name>sd4</servlet-name>
    <servlet-class>com.kuang.servlet.ServletDemo04</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>sd4</servlet-name>
    <url-pattern>/sd4</url-pattern>
</servlet-mapping>
```

还可以读取资源文件. 现在resource下创建一个资源文件`properties`, 写入`username=root password=123456`做测试.然够直接改上面的代码:
```
protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
    InputStream is = this.getServletContext().getResourceAsStream("/WEB-INF/classes/db.properties");
    Properties prop = new Properties();
    prop.load(is);
    String username = prop.getProperty("username");
    String password = prop.getProperty("password");
    resp.getWriter().println(username+" "+password); //打印root 123456
}
```

## HttpServletResponse
直接看`public interface ServletResponse`, 负责向浏览器发送数据如下. 而set开头的就是负责向浏览器发送响应头的方法.
- public ServletOutputStream getOutputStream() throws IOException;//写中文
- public PrintWriter getWriter() throws IOException;





## 原理
其中首次访问指创建war包的过程, `service`方法定义在`Servlet接口中`.
![](/notes/notes28_1.png)

## 参考
1. [JavaWeb入门到实战-狂神说Java](https://www.bilibili.com/video/BV12J411M7Sj?p=1)