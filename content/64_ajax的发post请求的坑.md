---
title: "ajax的发post请求的坑"
date: 2021-09-21
draft: false
toc: true
categories: ["Web开发"]
---

在前端通过ajax请求向服务端发送请求是非常常见的场景, 在Java Web开发中, 通常用SpringMVC去取得请求体的数据. 而用ajax做post请求, 用的工具通常是jquery或者vue中推荐的axios. 但是这两者装载post请求体的方式其实是不同的, 这是个小小的坑, 做个小实验看看.

后端就是一个平平无奇的`ajaxIndexPage`做html文件的跳转, `handleAjaxRequest`作为接口响应前端请求. 我们用`@RequestParam`注解去取得post的data, 总所周知, 这个注解只能取到`url?xxx=1&xxx=2`这样的数据.
```
@Controller
public class AjaxController {

    @RequestMapping(value = {"/", "/index"})
    public String ajaxIndexPage() {
        return "ajax-test/index";
    }


    @RequestMapping("/api/ajax-query")
    @ResponseBody
    public String handleAjaxRequest(@RequestParam(value= "requestNumber", defaultValue = "0") Integer requestNumber) {
        System.out.println("the number is " + requestNumber);
        return "good";
    }
}
```

前端页面更加平平无奇, 用两个按钮发送jquery post和axios post, 看似请求时一模一样的, 也就是说, 后端如果能拿到requestNumber, 就证明请求的data成功被`@RequestParam`注解拿到了, 如果没有拿到, 那么后端的requestNumber就会是默认值0.
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<div id="app">
    <button @click="query1">jquery</button>
    <button @click="query2">axios</button>
</div>
</body>

<!--注意这里的路径不能带static-->
<script src="../../vue.min.js"></script>
<script src="../../jquery-3.6.0.min.js"></script>
<script src="../../axios.min.js"></script>
<script type="module">
    new Vue({
        el: '#app',
        methods: {
            query1() {
                $.ajax({
                    url : "/api/ajax-query",
                    type : "POST",
                    contentType : "application/x-www-form-urlencoded",
                    dataType : "json",
                    data: {
                        requestNumber: 1
                    },
                    success: function (response) {
                        debugger;
                        console.log(response);
                    },
                });
            },
            query2() {
                axios({
                    url: '/api/ajax-query',
                    method: 'POST',
                    headers: {
                        'content-type': 'application/x-www-form-urlencoded'
                    },
                    data: {
                        requestNumber: 2
                    }
                }).then(function (response) {
                    debugger;
                    console.log(response);
                });
            }
        },
    })
</script>

</html>
```

接下来就是开心的实验时刻, 会发现jquery post让后端输出了`the number is 1`, 而axios post让后端输出了`the number is 0`, 一个成功了, 一个不成功, 这是怎么回事呢. 首先从chrome的开发者工具入手, 发现请求响应本身是没有问题的, 而问题就出在post是如何装载数据的, 为了清楚地看到post请求主题是什么样的, 我们用wireshark抓包试试. 选择`Loopback: lo0`就能抓去本地的请求响应. 

上图是jquery post的请求体, 下图是axios post的请求体. 前者是类似我们`url?xxx=1&xxx=2`的形式, 而后者是一个对象的形式. 所以说, 如果用axios做发送请求的工具, 想让后端通过`@RequestParam`去拿到亲情中的字段, 我们还是只有通过写`data: 'requestNumber=2'`, 去使得请求体不是对象的形式.
![](/64_1.png)
![](/64_2.png)

## 参考
1. [POST方法](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Methods/POST)