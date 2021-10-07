---
title: "JavaWeb-Servlet"
date: 2021-05-14
draft: false
toc: true
categories: ["WEB开发"]
tags: ["JavaWeb"]
---

## 原理
其中首次访问指创建war包的过程, `service`方法定义在`Servlet接口中`.
![](/48_1.png)

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
web容器(Tomcat), 为每个Web应用程序构建一个对应的ServletContext对象, 代表当前的Web应用. ServletContext的作用是防止一些数据. 我们新建一个类, 用来放置数据
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

### 下载文件
```
public class FileServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, IOException {
        // 1.获取文件下载路径
        String realPath = "/Users/harry/IdeaProjects/javaweb-02-servlet/response/target/classes/1.png"; //对应target中的1.png路径
        // 2.文件名
        String filename = realPath.substring(realPath.lastIndexOf("\\") + 1);
        // 3.让浏览器支持(Content-Disposition)下载我们需要的东西
        resp.setHeader("Content-Disposition", "attachment;filename"+ URLEncoder.encode(filename, "UTF-8"));
        // 4.获取下载文件的输入流
        FileInputStream in = new FileInputStream(realPath);
        // 5.创建缓冲区
        int len = 0;
        byte[] buffer = new byte[1024];
        // 6.获取OutputStream对象
        ServletOutputStream out = resp.getOutputStream();
        // 7. 将FileOutputSteam写入buffer, 用OutputStream将缓冲区中的数据输出到客户端
        while ((len=in.read(buffer)) > 0) {
            out.write(buffer, 0, len);
        }
        in.close();
        out.close();
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException, ServletException {
        super.doPost(req, resp);
    }
}
```

### 验证码实现
重点在于缓存策略, 是`no-cache`, 看`response header`中, 其实就对应了我们的程序.
```
public class ImageServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // 浏览器3s刷新一次
        resp.setHeader("refresh", "3");
        // 在内存中创建一张图片
        BufferedImage bufferedImage = new BufferedImage(80, 20, BufferedImage.TYPE_INT_RGB);
        // 得到图片
        Graphics2D g = (Graphics2D) bufferedImage.getGraphics();
        // 设置背景颜色
        g.setColor(Color.white);
        g.fillRect(0, 0, 80, 20);
        // 给图片写数据
        g.setColor(Color.BLUE);
        g.setFont(new Font(null, Font.BOLD, 20));
        g.drawString(makeNum(), 0, 20);
        // 告诉浏览器, 这个请求用图片的方式打开
        resp.setContentType("image/jpeg");
        // 网站存在缓存, 不让浏览器缓存
        resp.setDateHeader("expires", -1); //缓存策略
        resp.setHeader("Cache-Control", "no-cache"); //浏览器不缓存
        resp.setHeader("Pragma", "no-cache");

        // 图片写给浏览器
        ImageIO.write(bufferedImage, "jpg", resp.getOutputStream());
    }

    // 生成随机数
    private String makeNum() {
        Random random = new Random();
        String num = random.nextInt(9999999) + "";
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < 7 - num.length(); i++) {
            sb.append("0");
        }
        String s = sb.toString() + num;
        return num;
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        super.doPost(req, resp);
    }
}
```

## Response重定向
```
//        resp.setHeader("Location", "imageservlet");
//        resp.setStatus(302);
        resp.sendRedirect("/imageservlet"); //做的就是上里面的两行代码
```
重定向(302)和请求转发(307)的区别? 相同的是页面都会跳转, 但是**转发**的时候url不会产生变化, **重定向**的时候, url地址会变化. 
```
<html>
<body>
<h2>Hello World!</h2>

<%--${pageContext.request.contextPath}代表当前项目--%>
<form action="${pageContext.request.contextPath}/login" method="get">
    username: <input type="text" name="username"> <br>
    password: <input type="password" name="password"> <br>
    <input type="submit">
</form>
</body>
</html>
```

```
public class RequestTest extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

        String username = req.getParameter("username");
        String password = req.getParameter("password");
        System.out.println(username + ":" + "password");

        resp.sendRedirect("/success.jsp"); //登录后跳转页面
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        super.doPost(req, resp);
    }
}
```

## Request转发
视频中在`doGet`中写的逻辑, 实测会报错, 所以改为在doPost中写. `success.jsp`放在`index.jsp`目录下, 随便测试即可
```
public class LoginServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        super.doGet(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setCharacterEncoding("utf-8");
        req.setCharacterEncoding("utf-8");

        String username = req.getParameter("username");
        String password = req.getParameter("password");
        String[] hobbys = req.getParameterValues("hobby");

        System.out.println("==============================");
        System.out.println(username);
        System.out.println(password);
        System.out.println(Arrays.toString(hobbys));
        System.out.println("==============================");

        req.getRequestDispatcher("/success.jsp").forward(req, resp);
    }
}
```

```
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<body>
<h1>Login</h1>

<div>
    <form action="${pageContext.request.contextPath}/login" method="post">
        username: <input type="text" name="username"> <br>
        password: <input type="password" name="password"> <br>
        <input type="checkbox" name="hobby" value="girl">girl
        <input type="checkbox" name="hobby" value="code">code
        <input type="checkbox" name="hobby" value="sing">sing
        <input type="checkbox" name="hobby" value="film">film

        <br>
        <input type="submit">
    </form>
</div>
</body>
```

可以看到登录后的url并没有变, 但是加载了`success.jsp`.

> mac idea tomcsat 1099 is already in use解决方案: 在host文件中配置上`localhost host`. 打开方式是: `sudo vim /etc/hosts`.


## 参考
1. [JavaWeb-狂神说Java](https://www.bilibili.com/video/BV12J411M7Sj?p=1)