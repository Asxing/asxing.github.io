---
title: Spring-Cloud-Gateway-基础篇（二）
author: HoldDie
top: false
cover: false
toc: true
mathjax: true
tags:
  - Gateway
  - Spring-Cloud
date: 2021-01-11 13:12:54
img:
coverImg:
password:
summary:
categories: Spring
---

1. 项目地址

[https://github.com/HoldDie/spring-cloud-gateway](https://github.com/HoldDie/spring-cloud-gateway)

2. 基本概念
## 介绍

* 基于 Spring Framework 5，Project Reactor 和 Spring Boot 2.0
* 集成 Hystrix 断路器（未来要废）
* 集成 Spring Cloud DiscoveryClient
* Predicates 和 Filters 作用于特定路由，易于编写的 Predicates 和 Filters
* 具备一些网关的高级功能：动态路由、限流、路径重写、提供安全、监控、追踪、弹性
* SCG 只能在 Spring Boot 和 Spring Webflux 环境下运行，不能在 War 包形式下运行。
## 概念

* Route：网关的基本构建块。它由ID，目标URI，谓词集合和过滤器集合定义。如果聚合谓词为true，则匹配路由。
* Predicate：可以匹配 HTTP 中的所有请求。
* Filter：对于请求的拦截，可以修改请求内容。
## 请求流程

请求流程

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111135407.png!thumbnail)

* Filter 通过责任链模式，可以在请求前和请求后添加自己逻辑。
* 在没有端口的路由中定义的URI，HTTP和HTTPS URI的默认端口值分别为80和443。
## Predicates 匹配规则

### 快捷方式配置

示例

![](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142526.png)

* 快捷方式配置由过滤器名称识别，后跟等号（=），后跟以逗号（，）分隔的参数值。
### 全称配置

示例

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111135412.png!thumbnail)

* 把 Cookie 的全称都写出来，有 name，有 regexp。
## Route 匹配规则

### 规则（时间）之后匹配

示例：所有请求在 2017-01-20 之后可以访问

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111135419.png!thumbnail)

### 规则之前匹配

示例：所有请求在 2017-01-20 之前可以访问

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142448.png!thumbnail)

### 区间匹配

示例：两个时间之间可以访问

![](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142652.png)

### Cookie 匹配

示例：有对应 Cookie 才可以通过

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142701.png!thumbnail)

### Header 匹配

示例：请求头里面带有 X-reaquest-Id 才能通过

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142709.png!thumbnail)

### Host 匹配

示例：允许二级域名通过

![](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142727.png)

### 方法（GET/POST/PUT/DELETE）匹配

示例：允许 GET 方法通过

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142734.png!thumbnail)

### 路径匹配

示例：允许对应路径通过

![](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142757.png)

### 请求参数匹配

示例：允许参数通过

![](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142831.png)

### 远程IP地址匹配

示例：允许指定 IP 段通过

![](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142851.png)

### 权重路由匹配

示例：两个服务权重分流

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142859.png!thumbnail)

## 网关拦截器工厂

### 添加请求头

![](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142919.png)

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142927.png!thumbnail)

### 添加请求参数

![](https://cdn.jsdelivr.net/gh/HoldDie/img/20210111142943.png)



### 添加返回头

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111143717.png!thumbnail)

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111143802.png)

### 返回头去重

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111143822.png)

### Hystrix 拦截过滤（未来废弃）

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111143829.png!thumbnail)

### CiruitBreaker 过滤器

#### 普通拉闸

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111143859.png)

#### 高阶拉闸

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111143916.png)

### FallbackHeaders 异常转发附加信息

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111143925.png!thumbnail)

### 请求头参数替换

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111143940.png)

### 前缀过滤

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144039.png!thumbnail)

### 保持 Host 请求头

![图片](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144048.png!thumbnail)

### 请求限流（Redis 实现）

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144102.png)

### 重定向过滤器

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144222.png)

### 移除请求头

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144122.png)

### 移除返回头

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144305.png)

### 移除请求参数

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144316.png)

### context路径修改

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144327.png)

### 重新返回头

RewriteLocationResponseHeader

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111145033.png)

### 替换请求头参数

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144359.png)

### 保存 session

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144406.png)

### 安全头 SecureHeaders

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144414.png)

### SetPath 替换 context

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144422.png)

### 请求头参数全部替换

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144433.png)

### 返回头参数全部替换

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111145224.png)

### 修改返回状态

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144450.png)

### 踢出请求前缀

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144500.png)

### 重试机制

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144508.png)

### 请求大小限制

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111145240.png)

### 替换源请求地址

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144524.png)

### 修改请求体

### 修改返回体

## Global Filter

### Filter 排序

### Routing 过滤器

### 负载均衡过滤器

### 响应时负载均衡

### Netty routing 过滤

### Netty Routing Filter

### Websocket Filter

### Metrics Filter

## HttpHeadersFilter

### RemoveHopByHop

* 移除一些请求头
### XForwarded

* 添加一些 X-Forwarded-* headers
## TLS 和 SSL

### 服务添加 SSL 认证

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111145106.png)

### GateWay 添加认证

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111145113.png)

### TLS 握手配置

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144549.png)

## 配置

### RouteDefinitionLocator 支持多种配置格式

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144600.png)

## Route 元数据配置

### 元数据配置

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144607.png)

## Http 超时配置

### 全局配置

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144614.png)

### 针对单个配置

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144627.png)

### 支持流式配置

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111145142.png)

## Netty 访问日志

### 访问日志配置

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144704.png)

## 跨域配置（CORS）

### 配置

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144652.png)

## 网关监控

### 启动

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144724.png)

### 查看网关 routes 配置信息

* GET /actuator/gateway/routes

对应开关

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144744.png)

### 返回结果

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144753.png)

### 检索路由过滤器

* 全局过滤器

GET /actuator/gateway/globalfilters

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111145206.png)

* 路由过滤器

GET /actuator/gateway/routefilters

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144820.png)

### 刷新路由缓存

* POST /actuator/gateway/refresh
### 获取 route 列表详情

* GET  /actuator/gateway/routes
### 获取单个 route 详情

* GET /actuator/gateway/routes/{id}
### 新增一个 route

POST /gateway/routes/{id_route_to_create}

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144832.png)

### 删除一个 route

* DELETE /gateway/routes/{id_route_to_delete}
### 获取所有的 endpoint

* GET /actuator/gateway
## 常见问题

### 日志级别

* org.springframework.cloud.gateway
* org.springframework.http.server.reactive
* org.springframework.web.reactive
* org.springframework.boot.autoconfigure.web
* reactor.netty
* redisratelimiter
### 启动窃听功能

* reactor.netty DEBUG、TRACE
* spring.cloud.gateway.httpserver.wiretap=true
* spring.cloud.gateway.httpclient.wiretap=true
## 定制网关

### 自定义 Route

* 需要实现 RoutePredicateFactory 接口，一般继承 AbstractRoutePredicateFactory 类即可

栗子

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144845.png)

### 自定义 GatewayFilter

* 实现 GatewayFilterFactory 接口，一般继承 AbstractGatewayFilterFactory 类即可。

PreGatewayFilterFactory

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144900.png)

### PostGatewayFilterFactory

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144919.png)

### 自定义 Global Filter

* 实现 GlobalFilter 接口

栗子

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111144939.png)

## gateway 网关参数

* spring.cloud.gateway.default-filters
    * List of filter definitions that are applied to every route.
* spring.cloud.gateway.discovery.locator.enabled
    * false
    * Flag that enables DiscoveryClient gateway integration.
* spring.cloud.gateway.discovery.locator.filters
* spring.cloud.gateway.discovery.locator.include-expression
    * true
    * SpEL expression that will evaluate whether to include a service in gateway integration or not, defaults to: true.
* spring.cloud.gateway.discovery.locator.lower-case-service-id	false
    * Option to lower case serviceId in predicates and filters, defaults to false. Useful with eureka when it automatically uppercases serviceId. so MYSERIVCE, would match /myservice/**
* spring.cloud.gateway.discovery.locator.predicates
* spring.cloud.gateway.discovery.locator.route-id-prefix
    * The prefix for the routeId, defaults to discoveryClient.getClass().getSimpleName() + "_". Service Id will be appended to create the routeId.
* spring.cloud.gateway.discovery.locator.url-expression
    * '[lb://'+serviceId](lb://%27+serviceId)
    * SpEL expression that create the uri for each route, defaults to: '[lb://'+serviceId](lb://%27+serviceId).
* spring.cloud.gateway.enabled true
    * Enables gateway functionality.
* spring.cloud.gateway.fail-on-route-definition-error
    * true
    * Option to fail on route definition errors, defaults to true. Otherwise, a warning is logged.
* spring.cloud.gateway.filter.remove-hop-by-hop.headers
* spring.cloud.gateway.filter.remove-hop-by-hop.order
* spring.cloud.gateway.filter.request-rate-limiter.deny-empty-key
    * true
    * Switch to deny requests if the Key Resolver returns an empty key, defaults to true.
* spring.cloud.gateway.filter.request-rate-limiter.empty-key-status-code
    * HttpStatus to return when denyEmptyKey is true, defaults to FORBIDDEN.
* spring.cloud.gateway.filter.secure-headers.content-security-policy
    * default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline'
* spring.cloud.gateway.filter.secure-headers.content-type-options
    * nosniff
* spring.cloud.gateway.filter.secure-headers.disable
* spring.cloud.gateway.filter.secure-headers.download-options
    * noopen
* spring.cloud.gateway.filter.secure-headers.frame-options
    * DENY
* spring.cloud.gateway.filter.secure-headers.permitted-cross-domain-policies
    * none
* spring.cloud.gateway.filter.secure-headers.referrer-policy
    * no-referrer
* spring.cloud.gateway.filter.secure-headers.strict-transport-security
    * max-age=631138519
* spring.cloud.gateway.filter.secure-headers.xss-protection-header
    * 1 ; mode=block
* spring.cloud.gateway.forwarded.enabled
    * true
    * Enables the ForwardedHeadersFilter.
* spring.cloud.gateway.globalcors.add-to-simple-url-handler-mapping	false
    * If global CORS config should be added to the URL handler.
* spring.cloud.gateway.globalcors.cors-configurations
* spring.cloud.gateway.httpclient.connect-timeout
    * The connect timeout in millis, the default is 45s.
* spring.cloud.gateway.httpclient.max-header-size
    * The max response header size.
* spring.cloud.gateway.httpclient.max-initial-line-length
    * The max initial line length.
* spring.cloud.gateway.httpclient.pool.acquire-timeout
    * Only for type FIXED, the maximum time in millis to wait for aquiring.
* spring.cloud.gateway.httpclient.pool.max-connections
    * Only for type FIXED, the maximum number of connections before starting pending acquisition on existing ones.
* spring.cloud.gateway.httpclient.pool.max-idle-time
    * Time in millis after which the channel will be closed. If NULL, there is no max idle time.
* spring.cloud.gateway.httpclient.pool.max-life-time
    * Duration after which the channel will be closed. If NULL, there is no max life time.
* [spring.cloud.gateway.httpclient.pool.name](http://spring.cloud.gateway.httpclient.pool.name)
    * proxy
    * The channel pool map name, defaults to proxy.
* spring.cloud.gateway.httpclient.pool.type
    * Type of pool for HttpClient to use, defaults to ELASTIC.
* spring.cloud.gateway.httpclient.proxy.host
    * Hostname for proxy configuration of Netty HttpClient.
* spring.cloud.gateway.httpclient.proxy.non-proxy-hosts-pattern
    * Regular expression (Java) for a configured list of hosts. that should be reached directly, bypassing the proxy
* spring.cloud.gateway.httpclient.proxy.password
    * Password for proxy configuration of Netty HttpClient.
* spring.cloud.gateway.httpclient.proxy.port
    * Port for proxy configuration of Netty HttpClient.
* spring.cloud.gateway.httpclient.proxy.username
    * Username for proxy configuration of Netty HttpClient.
* spring.cloud.gateway.httpclient.response-timeout
    * The response timeout.
* spring.cloud.gateway.httpclient.ssl.close-notify-flush-timeout
    * 3000ms
    * SSL close_notify flush timeout. Default to 3000 ms.
* spring.cloud.gateway.httpclient.ssl.close-notify-flush-timeout-millis
* spring.cloud.gateway.httpclient.ssl.close-notify-read-timeout
    * SSL close_notify read timeout. Default to 0 ms.
* spring.cloud.gateway.httpclient.ssl.close-notify-read-timeout-millis
* spring.cloud.gateway.httpclient.ssl.default-configuration-type
    * The default ssl configuration type. Defaults to TCP.
* spring.cloud.gateway.httpclient.ssl.handshake-timeout
    * 10000ms
    * SSL handshake timeout. Default to 10000 ms
* spring.cloud.gateway.httpclient.ssl.handshake-timeout-millis
* spring.cloud.gateway.httpclient.ssl.key-password
    * Key password, default is same as keyStorePassword.
* spring.cloud.gateway.httpclient.ssl.key-store
    * Keystore path for Netty HttpClient.
* spring.cloud.gateway.httpclient.ssl.key-store-password
    * Keystore password.
* spring.cloud.gateway.httpclient.ssl.key-store-provider
    * Keystore provider for Netty HttpClient, optional field.
* spring.cloud.gateway.httpclient.ssl.key-store-type
    * JKS
    * Keystore type for Netty HttpClient, default is JKS.
* spring.cloud.gateway.httpclient.ssl.trusted-x509-certificates
    * Trusted certificates for verifying the remote endpoint’s certificate.
* spring.cloud.gateway.httpclient.ssl.use-insecure-trust-manager
    * false
    * Installs the netty InsecureTrustManagerFactory. This is insecure and not suitable for production.
* spring.cloud.gateway.httpclient.websocket.max-frame-payload-length
    * Max frame payload length.
* spring.cloud.gateway.httpclient.websocket.proxy-ping
    * true
    * Proxy ping frames to downstream services, defaults to true.
* spring.cloud.gateway.httpclient.wiretap
    * false
    * Enables wiretap debugging for Netty HttpClient.
* spring.cloud.gateway.httpserver.wiretap
    * false
    * Enables wiretap debugging for Netty HttpServer.
* spring.cloud.gateway.loadbalancer.use404
    * false
* spring.cloud.gateway.metrics.enabled
    * true
    * Enables the collection of metrics data.
* spring.cloud.gateway.metrics.tags
    * Tags map that added to metrics.
* spring.cloud.gateway.redis-rate-limiter.burst-capacity-header
    * X-RateLimit-Burst-Capacity
    * The name of the header that returns the burst capacity configuration.
* spring.cloud.gateway.redis-rate-limiter.config
* spring.cloud.gateway.redis-rate-limiter.include-headers
    * true
    * Whether or not to include headers containing rate limiter information, defaults to true.
* spring.cloud.gateway.redis-rate-limiter.remaining-header
    * X-RateLimit-Remaining
    * The name of the header that returns number of remaining requests during the current second.
* spring.cloud.gateway.redis-rate-limiter.replenish-rate-header
    * X-RateLimit-Replenish-Rate
    * The name of the header that returns the replenish rate configuration.
* spring.cloud.gateway.redis-rate-limiter.requested-tokens-header
    * X-RateLimit-Requested-Tokens
* The name of the header that returns the requested tokens configuration.
    * spring.cloud.gateway.routes
    * List of Routes.
* spring.cloud.gateway.set-status.original-status-header-name
    * The name of the header which contains http code of the proxied request.
* spring.cloud.gateway.streaming-media-types
* spring.cloud.gateway.x-forwarded.enabled
    * true
    * If the XForwardedHeadersFilter is enabled.
* spring.cloud.gateway.x-forwarded.for-append
    * true
    * If appending X-Forwarded-For as a list is enabled.
* spring.cloud.gateway.x-forwarded.for-enabled
    * true
    * If X-Forwarded-For is enabled.
* spring.cloud.gateway.x-forwarded.host-append
    * true
    * If appending X-Forwarded-Host as a list is enabled.
* spring.cloud.gateway.x-forwarded.host-enabled
    * true
    * If X-Forwarded-Host is enabled.
* spring.cloud.gateway.x-forwarded.order
    * 0
    * The order of the XForwardedHeadersFilter.
* spring.cloud.gateway.x-forwarded.port-append
    * true
    * If appending X-Forwarded-Port as a list is enabled.
* spring.cloud.gateway.x-forwarded.port-enabled
    * true
    * If X-Forwarded-Port is enabled.
* spring.cloud.gateway.x-forwarded.prefix-append
    * true
    * If appending X-Forwarded-Prefix as a list is enabled.
* spring.cloud.gateway.x-forwarded.prefix-enabled
    * true
    * If X-Forwarded-Prefix is enabled.
* spring.cloud.gateway.x-forwarded.proto-append
    * true
    * If appending X-Forwarded-Proto as a list is enabled.
* spring.cloud.gateway.x-forwarded.proto-enabled
    * true
    * If X-Forwarded-Proto is enabled.
3. 运行栗子
### 正常接口代理

```shell
curl http://localhost:8080/get
{
"args": {},
"headers": {
"Accept": "*/*",
"Content-Length": "0",
"Forwarded": "proto=http;host=\"localhost:8080\";for=\"0:0:0:0:0:0:0:1:58265\"",
"Host": "httpbin.org",
"User-Agent": "curl/7.64.1",
"X--------------": "1.1.1.1",
"X-Amzn-Trace-Id": "Root=1-5fea8da1-49ecda5f16a83c4225d66956",
"X-Forwarded-Host": "localhost:8080"
},
"origin": "203.90.236.199",
"url": "http://localhost:8080/get"
}
```
### 使用 Hystrix

```plain
curl --dump-header - --header 'Host: www.hystrix.com'
http://localhost:8080/get
HTTP/1.1 200 OK
Date: Tue, 29 Dec 2020 03:07:11 GMT
Content-Type: application/json
Content-Length: 472
Server: gunicorn/19.9.0
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
{
"args": {},
"headers": {
"Accept": "*/*",
"Content-Length": "0",
"Forwarded": "proto=http;host=www.hystrix.com;for=\"0:0:0:0:0:0:0:1:60205\"",
"Hello": "World",
"Host": "httpbin.org",
"User-Agent": "curl/7.64.1",
"X--------------": "1.1.1.1",
"X-Amzn-Trace-Id": "Root=1-5fea9d5f-621231a47d809f3718c485f4",
"X-Forwarded-Host": "www.hystrix.com"
},
"origin": "203.90.236.199",
"url": "http://www.hystrix.com/get"
}
```
### 压测结果

```plain
wrk -t8 -c40 -d60s --latency http://localhost:8080/get
Running 1m test @ http://localhost:8080/get
8 threads and 40 connections
Thread Stats   Avg      Stdev     Max   +/- Stdev
Latency   294.07ms   65.96ms   1.61s    96.86%
Req/Sec    17.46      8.40    40.00     52.41%
Latency Distribution
50%  285.59ms
75%  288.15ms
90%  289.87ms
99%  601.29ms
8215 requests in 1.00m, 5.26MB read
Socket errors: connect 0, read 0, write 0, timeout 1
Requests/sec:    136.69
Transfer/sec:     89.71KB
```

