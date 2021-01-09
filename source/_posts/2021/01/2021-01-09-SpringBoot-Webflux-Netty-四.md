---
title: SpringBoot-Webflux-Netty(四)
author: HoldDie
img: images/xxx.jpg
top: false
cover: false
coverImg: images/1.jpg
toc: true
mathjax: true
tags:
  - 1
  - 1
date: 2021-01-09 00:27:07
password:
summary:
categories: Spring
---

## SpringBoot Netty 配置

### 配置启动端口

```java
@Component
public class NettyWebServerFactoryPortCustomizer
      implements WebServerFactoryCustomizer<NettyReactiveWebServerFactory> {
   @Override
   public void customize(NettyReactiveWebServerFactory serverFactory) {
      serverFactory.setPort(8089);
   }
}
```

### 配置 EventLoopGroup

#### EventLoopNettyCustomizer 配置类

```java
public class EventLoopNettyCustomizer implements NettyServerCustomizer {

	@Override
	public HttpServer apply(HttpServer httpServer) {
		EventLoopGroup bossGroup = new NioEventLoopGroup(1);
		EventLoopGroup workGroup = new NioEventLoopGroup();
		return httpServer.tcpConfiguration(tcpServer -> tcpServer
				.bootstrap(serverBootstrap -> serverBootstrap
						.group(bossGroup, workGroup)
						.handler(new LoggingHandler(LogLevel.DEBUG))
						.option(ChannelOption.SO_BACKLOG, 128)
						.option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 5000)
						.channel(NioServerSocketChannel.class)));
	}
}
```

#### NettyReactiveWebServerFactory 工厂类

```java
@Bean
public NettyReactiveWebServerFactory nettyReactiveWebServerFactory() {
   NettyReactiveWebServerFactory webServerFactory = new NettyReactiveWebServerFactory();
   // 同时可以扩展 SSL
   webServerFactory.addServerCustomizers(new EventLoopNettyCustomizer());
   return webServerFactory;
}
```

### 查看日志

要启用Netty访问日志记录，实用配置参数`-Dreactor.netty.http.server.accessLogEnabled = true`。

## 新建两个 SpringBoot 项目

### 使用 Flux 写法

```java
@GetMapping("flux")
public Mono<String> reactor() {
   return Mono.just("hello world");
}
```

### 使用 Mvc 写法

```java
@GetMapping("mvc")
public String hello() {
   return "hello world";
}
```

### 压测看结果

#### Flux 截图

![image-20210109130724515](https://cdn.jsdelivr.net/gh/HoldDie/img/20210109130724.png)

#### Mvc 截图

![image-20210109130900111](https://cdn.jsdelivr.net/gh/HoldDie/img/20210109130900.png)



## 网关代理

### 直接代理（默认参数）

![image-20210109134614688](https://cdn.jsdelivr.net/gh/HoldDie/img/20210109134614.png)

### 自定义 EvenLoopGroup

![image-20210109132310751](https://cdn.jsdelivr.net/gh/HoldDie/img/20210109132310.png)

### 修改参数

![image-20210109132654663](https://cdn.jsdelivr.net/gh/HoldDie/img/20210109132654.png)



### 参考链接

- https://blog.csdn.net/IT_liuzhiyuan/article/details/102367235
- https://www.jdon.com/51947
- https://www.it1352.com/1830786.html