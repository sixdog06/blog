---
title: "JavaWeb-Cookie/Session"
date: 2021-05-24
draft: false
author: "小拳头"
categories: ["WEB开发"]
tags: ["JavaWeb"]
---

cookie: 客户端技术(响应/请求), session: 服务器技术, 把信息或数据放在session中. **都是保存会话的技术**. 现实中的例子就是已经登陆的网站, 下次可以直接登陆. 

## Cookie
先测试cookie, 打印上次登录的时间. 要注意cookie是有大小和数量限制的.
```
public class CookieDemo01 extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("utf-8");
        resp.setCharacterEncoding("utf-8");

        PrintWriter out = resp.getWriter();

        //服务器从客户端获取
        Cookie[] cookies = req.getCookies();

        //判断Cookie是否存在
        if (cookies != null) {
            //存在
            out.write("Last visit time is:");
            for (int i = 0; i < cookies.length; i++) {
                Cookie cookie = cookies[i];
                if (cookie.getName().equals("lastLoginTime")) {
                    //获取Cookie的值
                    long lastLoginTime = Long.parseLong(cookie.getValue());
                    Date date = new Date(lastLoginTime);
                    out.write(date.toString());
                }
            }
        } else {
            out.write("First time to visit this website");
        }

        Cookie cookie = new Cookie("lastLoginTime", String.valueOf(System.currentTimeMillis())); //可以看出Cookie只能存String

        // cookie有效期1天, 如果要删除cookie, 把有效期设置为0即可
        cookie.setMaxAge(24*60*60);
        // 给客户端响应
        resp.addCookie(cookie);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        super.doPost(req, resp);
    }
}
```
## Session
Session中, 服务器会给每个浏览器创建Session对象. 写三个例子, 分别是在session中加对象, 从session中取对象, 和注销session. 其实对服务器来说, 识别客户端依然用了cookie中的session id. 只是存储的数据在服务器中, 是一个映射关系.
```
protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

    req.setCharacterEncoding("UTF-8");
    resp.setCharacterEncoding("UTF-8");
    resp.setContentType("text/html;charset=utf-8");

    // get session
    HttpSession session = req.getSession();
    // save data
    session.setAttribute("name", new Person("Harry", 25));
    // get session id
    String sessionId = session.getId();

    // session existence check
    if (session.isNew()) {
        resp.getWriter().write("session create successfully, session id is"+sessionId);
    } else {
        resp.getWriter().write("session already exists, session id is"+sessionId);
    }
}
```
```
protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

    req.setCharacterEncoding("UTF-8");
    resp.setCharacterEncoding("UTF-8");
    resp.setContentType("text/html;charset=utf-8");

    HttpSession session = req.getSession();
    Person person = (Person) session.getAttribute("name");
    System.out.println(person.toString());
}
```
```
protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
    HttpSession session = req.getSession();
    session.removeAttribute("name");
    session.invalidate();
}
```

## 参考
1. [JavaWeb入门到实战-狂神说Java](https://www.bilibili.com/video/BV12J411M7Sj?p=1)