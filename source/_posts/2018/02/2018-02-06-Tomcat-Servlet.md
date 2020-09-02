---
title: Tomcat+Servlet
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Tomcat
  - Servlet
date: 2018-02-06 21:32:16
password:
summary:  
categories: Tomcat
---



一直在用 Tomcat ，一直感觉有些嘘嘘嘘！



## Tomcat 概念

### Connector 运行模式

- BIO（Blocking I/O）

  - 传统的 Java I/O，同步且阻塞IO。

- NIO（Non-Blocking I/O）

  - JDK1.4 开始支持，同步阻塞或同步非阻塞IO。

  ```xml
  <!-- protocol 启用 nio模式，(tomcat8默认使用的是nio)(apr模式利用系统级异步io) -->
      <!-- minProcessors最小空闲连接线程数-->
      <!-- maxProcessors最大连接线程数-->
      <!-- acceptCount允许的最大连接数，应大于等于maxProcessors-->
      <!-- enableLookups 如果为true,requst.getRemoteHost会执行DNS查找，反向解析ip对应域名或主机名-->
  <Connector port="8080" protocol="org.apache.coyote.http11.Http11NioProtocol" 
             connectionTimeout="20000"
             redirectPort="8443"
             maxThreads="500"
             minSpareThreads="100"
             maxSpareThreads="200"
             acceptCount="200"
             enableLookups="false"       
             />
  ```

- APR（Apache Portable Runtime/Apache 可移植运行库）

  - Tomcat 将以 JNI 的形式调用 Apache HTTP 服务器的核心动态链接库来处理文件读取或网络传输操作，从而大大提高 Tomcat 对静态文件的处理性能。

  ```xml
  <Connector port="8080" protocol="org.apache.coyote.http11.Http11AprProtocol"
                 connectionTimeout="20000"
                 redirectPort="8443" />
  ```

### 区分概念

- 同步和异步是针对应用程序和内核的交互而言的。
  - 同步是指用户进程触发IO操作并等待或者轮询的去查看IO是否就绪。
  - 异步是指用户进程触发IO操作以后便开始做自己的事情，而当IO操作已经完成的时候会得到IO完成的通知。
- 阻塞和非阻塞是针对于进程在访问数据的时候，根据 IO 操作的就绪状态来采取不同的方式，是一种读取或者写入操作函数的实现方式，
  - 阻塞方式下读取或者写入函数将一直等待。
  - 非阻塞，读写或者写入函数会立即返回一个状态值。

同步和异步是目的，阻塞和非阻塞是实现方式。

IO操作可以分为3类：同步阻塞（BIO）、同步非阻塞（NIO）、异步非阻塞（AIO）。

#### 同步阻塞：

用户进程在发起一个IO操作后，必须等待IO操作的完成，只有当真正完成了IO操作以后，用户进程才能运行。

适用于连接数目比较小且固定的架构，这种方式对服务器资源要求比较高，并发局限于应用中。

#### 同步非阻塞：

用户进程发起一个IO操作以后便可返回做其他事情，但是用户进程需要是不是的询问IO操作是否就绪，这就要求用户进程不停的去询问，从而引入不必要的CPU资源浪费。

适用于连接数目多比较短（轻操作）的架构，比如聊天服务器，并发局限于应用中。

#### 异步非阻塞：

发起一个IO操作后，不等待内核IO操作的完成，等内核完成以后会得到IO操作完成的通知，此时用户进程只需要对数据进行处理就好了，不需要进行实际的IO读写操作，因为真正的IO读取或者写入操作已经由内核完成了。

适用于连接数目多且连接比较长（重操作）的架构，比如相册服务器，充分调用OS参与并发操作。

## Servlet 来一波

### Servlet生命周期：

- 只要访问 Servlet，Service() 就会被访问。
- init() 只有第一次访问 Servlet 的时候才会被调用。
- destory() 只有在 Tomcat 关闭的时候才会被调用。

### Cookie 和 Session 区别：

- 存储方式：
  - Cookie 只能存储字符串，如果要存储费ASCII字符串还要对其编码
  - Session 可以存储任何类型的数据，可以把 Session 看成一个容器
- 隐私安全性：
  - Cookie 存储在浏览器中，对客户端是可见的，防止泄露，最好加密。
  - Session 存储在服务器上，对客户端是透明的。
- 有效期：
  - Cookie 保存在硬盘上，只需要设置 maxAge 属性为比较大的正整数，即使关闭浏览器，Cookie还是存在的
  - Session 的保存在服务器中，设置 maxInactiveInterval 属性值来确定 Session 的有效期。并且 Session 依赖于名为 JSESSIONID 的 Cookie，该 Cookie 默认的 maxAge 属性为 -1，如果关闭了浏览器，该 Session 虽然没有从服务器中消失，但是也失效了。
- 对服务器的负担：
  - Cookie 保存在客户端，不占用服务器的资源。
  - Session 保存在服务器的，每个用户会产生一个 Session ，如果是并发访问的用户非常多，是不能使用 Session 的，Session会消耗大量的内存。
- 浏览器的支持：
  - 若禁用了 Cookie，那么Cookie是无用的。
  - 若禁用了 Cookie，Session 可以通过 URL 地址重写来进行会话跟踪。
- 跨域名比较：
  - Cookie 可以设置 domain 属性来实现跨域名
  - Session 只在当前的域名内有效，不可跨域名

