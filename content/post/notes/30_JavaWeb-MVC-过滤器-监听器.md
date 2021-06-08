---
title: "JavaWeb-MVC/过滤器/监听器"
date: 2021-05-31
draft: false
toc: true
categories: ["学习笔记"]
tags: ["JavaWeb"]
---

## MVC三层架构
MVC: Controller专注于业务处理, 它的处理结果就是Model. Model可以是一个JavaBean(pojo), 也可以是一个包含多个对象的Map, Controller只负责把Model传递给View, View只负责把Model给渲染出来开发Controller时无需关注页面. 开发View时无需关心如何创建Model. `Browser`->`Controller: UserServlet`->`Model: User`->`View: user.jsp`.

- Model: 业务处理: 业务逻辑(Service); 数据持久层: CRUD(Dao)
- View: 展示数据; 提供链接发起Servlet请求(a, form, img...)
- Controller(Servlet): 接受用户请求, req请求参数, session信息. 给业务层处理对应代码; 控制试图跳转.

![](/notes/notes30_1.png)
> 登陆->接受用户的登陆请求->处理用户的请求(获取用户登陆的参数, username, password)->交给业务层处理登陆业务(判断用户名和密码是否正确: 事务)->Dao层查询用户名和密码是否正确.

## 过滤器
配置文件中加入要过滤什么.
```
<filter>
    <filter-name>CharacterEncodingFilter</filter-name>
    <filter-class>com.kuang.filter.CharacterEncodingFilter</filter-class>
</filter>
<filter-mapping>
    <filter-name>CharacterEncodingFilter</filter-name>
    <url-pattern>/servlet/*</url-pattern>
</filter-mapping>
```

过滤器代码, 效果是加入了编码, 这样在servlet主要的逻辑中就不用重复加上编码的代码了. 
```
public class CharacterEncodingFilter implements Filter {

    public void init(FilterConfig filterConfig) throws ServletException {
        System.out.println("init");
    }

    /*
        1. 过滤中的所有代码在过滤请求时都会执行
        2. 必须让过滤器继续通行
     */
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        request.setCharacterEncoding("utf-8");
        response.setCharacterEncoding("utf-8");
        response.setContentType("text/html;charset=UTF-8");

        System.out.println("before filter");
        chain.doFilter(request, response); //如果不写, 程序在这里就停了, request/response被拦截
        System.out.println("after filter");
    }

    public void destroy() {
        System.out.println("destroy");
    }
}
```

也就是说, 过滤器实际上作用于web服务器和servlet之间, 可以插入一些逻辑进行过滤.

## 监听器
监听Session的创建和销毁.
```
public class OnlineCountListener implements HttpSessionListener {

    // 创建Session时触发
    public void sessionCreated(HttpSessionEvent se) {

        ServletContext ctx = se.getSession().getServletContext();
        Integer onlineCount = (Integer) ctx.getAttribute("OnlineCount");
        if (onlineCount == null) {
            onlineCount = new Integer(1);
        } else {
            int count = onlineCount.intValue();
            onlineCount = new Integer(count + 1);
        }
        ctx.setAttribute("OnlineCount", onlineCount);
    }

    // 销毁Session时触发
    public void sessionDestroyed(HttpSessionEvent se) {
        ServletContext ctx = se.getSession().getServletContext();
        Integer onlineCount = (Integer) ctx.getAttribute("OnlineCount");
        if (onlineCount == null) {
            onlineCount = new Integer(1);
        } else {
            int count = onlineCount.intValue();
            onlineCount = new Integer(count - 1);
        }
        ctx.setAttribute("OnlineCount", onlineCount);
    }
}
```

配置文件: 
```    
<!--注册监听器-->
<listener>
    <listener-class>com.kuang.listener.OnlineCountListener</listener-class>
</listener>
```

监控现在有多少个Session:
```
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
  <head>
    <title>$Title$</title>
  </head>
  <body>
  <h1>当前有 <span style="color: blue"><%=this.getServletConfig().getServletContext().getAttribute("OnlineCount")%></span> 人在线</h1>
  </body>
</html>
```

第一次运行会发现有3个Session在线, 可实际上只有一个Session id. 所以redeployed一下, 发现就只剩一个人在线了. 用不同的浏览器访问服务器, 就会发现有session增加. 关闭浏览器, 监听器监听到销毁事件, session就会减少.

## 案例: Filter实现权限拦截
实现的功能很简单, 只有名字为admin的y用户可以登陆, 且登录后再注销, 无法访问登陆成功页面. 首先分别写Login和Logout主程序.
```
public class LoginServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        super.doGet(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // 获取前端请求的参数
        String username =req.getParameter("username");
        if (username.equals("admin")) { // success
            req.getSession().setAttribute("USER_SESSION", req.getSession().getId());
            resp.sendRedirect("/sys/success.jsp");
        } else { // fail
            resp.sendRedirect("/error.jsp");
        }
    }
}

public class LogoutServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Object user_session = req.getSession().getAttribute("USER_SESSION");
        if (user_session != null) {
            req.getSession().removeAttribute("USER_SESSION");
            resp.sendRedirect("/Login.jsp");
        } else {
            resp.sendRedirect("/Login.jsp");
        }
    }

    @Override
    protected void doHead(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

    }
}
```

通过一个过滤器去监听没有session的用户的对`/sys/success.jsp`请求, 拒绝并redirect到`/error.jsp`.
```
public class SysLister implements Filter {
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain) throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) resp;

        if (request.getSession().getAttribute("USER_SESSION") == null) {
            response.sendRedirect("/error.jsp");
        }
        chain.doFilter(request, response);
    }

    public void destroy() {
    }
}
```

几个jsp文件, 分别是登陆成功页面, 错误页面和登陆页面:
```
<!--success.jsp-->
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Title</title>
</head>
<body>
    <h1>Success</h1>
    <p><a href="/servlet/logout">Logout</a></p>
</body>
</html>

<!--error.jsp-->
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Title</title>
</head>
<body>
    <h1>Wrong</h1>
    <a href="Login.jsp">Return to login page</a>
</body>
</html>

<!--Login.jsp-->
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Title</title>
</head>
<body>
    <h1>Login</h1>
    <form action="/servlet/login" method="post">
        <input type="text" name="username">
        <input type="submit">
    </form>
</body>
</html>
```

配置文件:
```
<servlet>
    <servlet-name>LoginServlet</servlet-name>
    <servlet-class>com.kuang.servlet.LoginServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>LoginServlet</servlet-name>
    <url-pattern>/servlet/login</url-pattern>
</servlet-mapping>

<servlet>
    <servlet-name>LogoutServlet</servlet-name>
    <servlet-class>com.kuang.servlet.LogoutServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>LogoutServlet</servlet-name>
    <url-pattern>/servlet/logout</url-pattern>
</servlet-mapping>

<filter>
    <filter-name>SysFilter</filter-name>
    <filter-class>com.kuang.listener.SysLister</filter-class>
</filter>
<filter-mapping>
    <filter-name>SysFilter</filter-name>
    <url-pattern>/sys/*</url-pattern>
</filter-mapping>
```


## 参考
1. [JavaWeb入门到实战-狂神说Java](https://www.bilibili.com/video/BV12J411M7Sj?p=1)
2. [廖雪峰Java](https://www.liaoxuefeng.com/wiki/1252599548343744/1266264917931808)