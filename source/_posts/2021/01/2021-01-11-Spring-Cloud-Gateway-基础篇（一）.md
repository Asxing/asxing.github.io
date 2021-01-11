---
title: Spring-Cloud-Gateway-基础篇（一）
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Spring
  - 网关
date: 2021-01-11 13:09:34
password:
summary:
categories: Spring-Cloud-Gateway
---

# 目标

- 了解 SGC 启动加载流程，网关初始化；
- 分析核心组件构建原理；
- 主线(乃道的博客为抓手)
  - http://www.iocoder.cn/Spring-Cloud-Gateway/init/
  - http://www.iocoder.cn/Spring-Cloud-Gateway/ouwenxue/intro/
  - https://docs.spring.io/spring-cloud-gateway/docs/2.2.5.RELEASE/reference/html/#gateway-how-it-works
  - https://blog.csdn.net/qq_19663899/article/details/107939654

# 记录

## 添加 Actuator 监控

### Maven 依赖

```xml
<dependency>   
	<groupId>org.springframework.boot</groupId>   
	<artifactId>spring-boot-starter-actuator</artifactId> 
</dependency>
```

### 配置文件修改

```yaml
management:
  endpoint:
    gateway:
      enabled: true
  endpoints:
    web:
      exposure:
        include: '*'
```

### 数据访问

查看所有 routes： http://localhost:8080/actuator/gateway/routes

![image-20210111133530226](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111133530.png)

查看所有 globalfilters： http://localhost:8080/actuator/gateway/globalfilters

![image-20210111133541930](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111133541.png)

## 目录结构分析

### Spring Cloud Gateway Core

- 工程代码中显示这个项目已经弃用

### spring-cloud-gateway-dependencies

- 都是一些依赖，没有代码

### spring-cloud-gateway-mvc

- 对于 Spring-MVC 的支持

### spring-cloud-gateway-webflux

- 对于 webflux 的支持

### spring-cloud-gateway-server

- 核心中的核心
- 所有关键逻辑的地方

## Spring.factories 配置启动类

```java
# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\\
org.springframework.cloud.gateway.config.GatewayClassPathWarningAutoConfiguration,\\
org.springframework.cloud.gateway.config.GatewayAutoConfiguration,\\
org.springframework.cloud.gateway.config.GatewayHystrixCircuitBreakerAutoConfiguration,\\
org.springframework.cloud.gateway.config.GatewayResilience4JCircuitBreakerAutoConfiguration,\\
org.springframework.cloud.gateway.config.GatewayLoadBalancerClientAutoConfiguration,\\
org.springframework.cloud.gateway.config.GatewayNoLoadBalancerClientAutoConfiguration,\\
org.springframework.cloud.gateway.config.GatewayMetricsAutoConfiguration,\\
org.springframework.cloud.gateway.config.GatewayRedisAutoConfiguration,\\
org.springframework.cloud.gateway.discovery.GatewayDiscoveryClientAutoConfiguration,\\
org.springframework.cloud.gateway.config.SimpleUrlHandlerMappingGlobalCorsAutoConfiguration,\\
org.springframework.cloud.gateway.config.GatewayReactiveLoadBalancerClientAutoConfiguration

org.springframework.boot.env.EnvironmentPostProcessor=\\
org.springframework.cloud.gateway.config.GatewayEnvironmentPostProcessor
```

## 核心配置类(spring-cloud-gateway-server)

### 基础配置

- GatewayAutoConfiguration
- 功能：加载网关基础模块
- 基础模块包块：
  - GatewayActuatorConfiguration
  - HystrixConfiguration
  - NettyConfiguration

### 响应式或非响应式模式配置

- GatewayClassPathWarningAutoConfiguration
- 功能：主要扫描确定是使用 Spring-MVC 的模式，还是 Webflux 的格式。
- 要点：
  - 确保在 GatewayAutoConfiguration 加载前加载
  - 当存在 $org.springframework.web.servlet.DispatcherServlet$ 这个类时，加载 $SpringMvcFoundOnClasspathConfiguration$
  - 当不存在 $org.springframework.web.reactive.DispatcherHandler$ 加载 $WebfluxMissingFromClasspathConfiguration$

### 负载均衡配置

- GatewayLoadBalancerClientAutoConfiguration
- GatewayNoLoadBalancerClientAutoConfiguration
- GatewayReactiveLoadBalancerClientAutoConfiguration

## 监控配置

- GatewayMetricsAutoConfiguration

### Redis 配置

- GatewayRedisAutoConfiguration

### 限流相关配置

- GatewayResilience4JCircuitBreakerAutoConfiguration
- GatewayHystrixCircuitBreakerAutoConfiguration

### URLMapping 配置

- SimpleUrlHandlerMappingGlobalCorsAutoConfiguration

## 启动加载流程

![image-20210111133312255](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111133312.png)

- 根据属性加载，初始化 Netty HttpClient 以及对应的 Netty Bean，以及初始化了NettyRoutingFilter.
- 初始化对应的 GlobalFilter
- 初始化对应的 Filter
- 初始化对应的 Predicate
- 初始化 RouteDefinitionLocator ，收集所有的路由表 GatewayAutoConfiguration#routeDefinitionLocator，这个过程中包括初始化所有的 RoutePredicateFactory
- 初始化 RouteLocator ，根据上一步得到的RouteDedinitionLocator
- 初始化 GatewayControllerEndpoint
- 初始化 FilteringWebHandler ,通过上面收集好的 GlobalFilter，在此过程中并对 GlobalFilter 排序
- 初始化 GlobalCorsProperties
- 初始化 routePredicateHandlerMapping 这个是整个核心入口

## 实际执行流程

### getHandlerInternal 入口

我们可以根据官网的示意图，可知程序的入口是通过 RoutePredicateHandlerMapping 核心处理，因此我们在 对应的 getHandlerInternal 方法打断点，查看请求流程；

![image-20210111133243864](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111133243.png)

根据堆栈我们可以清楚看到实际请求时，DispatcherHandler 到 AbstractHandlerMapping 然后 RoutePredicateHandlerMapping 最后执行到 getHandlerInternal；

### exchange 理解

贯穿程序请求的上下文中，我们一直会看到 exchange 的变量，ServerWebExchange 默认实现是 DefaultServerWebExchange，我们从截图中可以看出这个变量不仅包含请求的上下文，还包括 applicationContext，相当于用啥都不愁了。

![image-20210111133229221](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111133229.png)