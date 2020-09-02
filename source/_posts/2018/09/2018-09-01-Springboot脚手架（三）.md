---
title: Springboot脚手架（三）
tags: [SpringBoot]
date: 2018-09-01 18:06:38
categories: SpringBoot
---

在黑夜迷梦中沉睡，却不知，身旁已是灿烂花开。															——湜霖



### 参数校验：

常见的做法，定义一个实体：

```java
public class Order {

    @NotNull(message = "用户ID不能为空")
    private Long userID;

    @NotNull(message = "收货人地址id不能为空")
    private Long addressID;

    @NotBlank(message = "备注不为空")
    private String comment;

}
```

然后，在 Controller 中使用：

```java
@PostMapping("/createOrders")
public String createOrders(@RequestBody @Valid Order dto, BindingResult results) { 
    if (results.hasErrors()) 
        return results.getFieldError().getDefaultMessage();
    return "success";
}
```

### 部署Tomecat获取域名

```xml
<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
       prefix="localhost_access_log" suffix=".txt"
       pattern="%h %l %u %t &quot;%r&quot; %s %b" />
<Valve className="org.apache.catalina.valves.RemoteIpValve"
       remoteIpHeader="X-Forwarded-For"
       requestAttributesEnabled="true"
       protocolHeader="X-Forwarded-Proto"
       protocolHeaderHttpsValue="https"/>
```

对于目前前端Nginx转发，添加了Header内容，然后后端我们想要获取请求头的内容，此时我们应该在Tomcat中添加响应的配置，以及对应的请求形式。