---
title: Spring-Cloud-Gateway(一)
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - SpringCloud
  - Gateway
  - 网关
date: 2020-12-28 14:54:10
password:
summary: SCG 只能在 Spring Boot 和 Spring Webflux 环境下运行，不能在 War 包形式下运行。
categories: Spring
---

## 介绍

- 基于 Spring Framework 5，Project Reactor 和 Spring Boot 2.0
- 集成 Hystrix 断路器（未来要废）
- 集成 Spring Cloud DiscoveryClient
- Predicates 和 Filters 作用于特定路由，易于编写的 Predicates 和 Filters
- 具备一些网关的高级功能：动态路由、限流、路径重写、提供安全、监控、追踪、弹性
- SCG 只能在 Spring Boot 和 Spring Webflux 环境下运行，不能在 War 包形式下运行。

## 概念

- Route：网关的基本构建块。它由ID，目标URI，谓词集合和过滤器集合定义。如果聚合谓词为true，则匹配路由。
- Predicate：可以匹配 HTTP 中的所有请求。
- Filter：对于请求的拦截，可以修改请求内容。

## 请求流程

- 请求流程

  ![img](https://img.mubu.com/document_image/dccffa45-2741-4d35-9706-99eb7a579b25-172511.jpg)

- Filter 通过责任链模式，可以在请求前和请求后添加自己逻辑。

- 在没有端口的路由中定义的URI，HTTP和HTTPS URI的默认端口值分别为80和443。

## Predicates 匹配规则

- 快捷方式配置

  - 示例

    ![img](https://img.mubu.com/document_image/f805f02f-6019-457e-9fc8-6a319e55ecf1-172511.jpg)

  - 快捷方式配置由过滤器名称识别，后跟等号（=），后跟以逗号（，）分隔的参数值。

- 全称配置

  - 示例

    ![img](https://img.mubu.com/document_image/11fb08da-fcad-4830-a930-e2d31fe45a1d-172511.jpg)

  - 把 Cookie 的全称都写出来，有 name，有 regexp。

## Route 匹配规则

- 规则（时间）之后匹配

  - 示例：所有请求在 2017-01-20 之后可以访问

    ![img](https://img.mubu.com/document_image/2c2b7bf8-07aa-4207-b7e7-e133011b6c37-172511.jpg)

- 规则之前匹配

  - 示例：所有请求在 2017-01-20 之前可以访问

    ![img](https://img.mubu.com/document_image/7d73b67d-9c0e-4103-966a-b5eeb545ef70-172511.jpg)

- 请求两次匹配

  - 示例：两个时间之间可以访问

    ![img](https://img.mubu.com/document_image/279762fc-0f40-4da1-94e2-e7b06809175e-172511.jpg)

- Cookie 匹配

  - 示例：有对应 Cookie 才可以通过

    ![img](https://img.mubu.com/document_image/8c026c16-de80-4b24-98ed-2f6e74bf2a3f-172511.jpg)

- Header 匹配

  - 示例：请求头里面带有 X-reaquest-Id 才能通过

    ![img](https://img.mubu.com/document_image/3d499634-4141-479a-bd46-05aa9ffa270e-172511.jpg)

- Host 匹配

  - 示例：允许二级域名通过

    ![img](https://img.mubu.com/document_image/04b26ab5-ac1e-4579-93c1-eacf772ff356-172511.jpg)

- 方法（GET/POST/PUT/DELETE）匹配

  - 示例：允许 GET 方法通过

    ![img](https://img.mubu.com/document_image/d2b6bc7e-66ea-4588-9f7f-9625ab5456dd-172511.jpg)

- 路径匹配

  - 示例：允许对应路径通过

    ![img](https://img.mubu.com/document_image/98df1694-ff5b-4dd3-916a-2ee7a0450a2a-172511.jpg)

- 请求参数匹配

  - 示例：允许参数通过

    ![img](https://img.mubu.com/document_image/5e4b716e-eaf8-43a4-baa9-6be09f8565d9-172511.jpg)

- 远程IP地址匹配

  - 示例：允许指定 IP 段通过

    ![img](https://img.mubu.com/document_image/f103cad6-ce99-4998-b35d-b2e4c6df94a3-172511.jpg)

- 权重路由匹配

  - 示例：两个服务权重分流

    ![img](https://img.mubu.com/document_image/d845803e-c9a2-4165-8caf-f4a35f5f97e5-172511.jpg)

## 网关拦截器工厂

- 添加请求头

  ![img](https://img.mubu.com/document_image/d8f13372-d32b-4389-b1b8-31ac44fcf6f5-172511.jpg)

  ![img](https://img.mubu.com/document_image/edca4345-63c3-4cd8-923f-6c3b71808fb0-172511.jpg)

- 添加请求参数

  ![img](https://img.mubu.com/document_image/d857fecc-8115-4a3f-9109-0c2782aaf69c-172511.jpg)

  ![img](https://img.mubu.com/document_image/180d9aa6-39ff-4c8e-94dc-d0c745ae713b-172511.jpg)

- 添加返回头

  ![img](https://img.mubu.com/document_image/df650e34-a7ee-45f8-bc27-b7d1c01e5d35-172511.jpg)

  ![img](https://img.mubu.com/document_image/1f3f2fe8-d907-4e55-a2f3-8bcf7982ad3c-172511.jpg)

- 返回头去重

  ![img](https://img.mubu.com/document_image/7960afd7-43f6-430f-a29c-4b33bd804f75-172511.jpg)

- Hystrix 拦截过滤（未来废弃）

  ![img](https://img.mubu.com/document_image/541a0439-d95c-4fd6-9008-8d2f02918623-172511.jpg)

- CiruitBreaker 过滤器

  - 普通拉闸

    ![img](https://img.mubu.com/document_image/5d71679a-f0ca-4ea9-95e2-15308415ebbf-172511.jpg)

  - 高阶拉闸

    ![img](https://img.mubu.com/document_image/4620ec01-fdfb-4765-8bc2-2160e5ad548a-172511.jpg)

- FallbackHeaders 异常转发附加信息

  ![img](https://img.mubu.com/document_image/0cb8701e-908b-4cd0-ad2a-623fdd4197d1-172511.jpg)

- 请求头参数替换

  ![img](https://img.mubu.com/document_image/75331816-40e7-4413-9a1e-dd319cd821c8-172511.jpg)

- 前缀过滤

  ![img](https://img.mubu.com/document_image/192b5a9b-b48e-4d7c-b204-39bf5c324717-172511.jpg)

- 保持 Host 请求头

  ![img](https://img.mubu.com/document_image/539a6f2c-8c88-40c8-8670-02dd1d22e5c5-172511.jpg)

- 请求限流（Redis 实现）

  ![img](https://img.mubu.com/document_image/bbe96f0d-bbf6-405b-a96a-4ec0b65b5d10-172511.jpg)

- 重定向过滤器

  ![img](https://img.mubu.com/document_image/05be8eb3-1ba9-47b2-9299-9e9bc83a9186-172511.jpg)

- 移除请求头

  ![img](https://img.mubu.com/document_image/751729f1-ffc3-4992-8d13-87847400b87a-172511.jpg)

- 移除返回头

  ![img](https://img.mubu.com/document_image/d59031a9-d9ea-4d07-bfbc-49b2f6aaea84-172511.jpg)

- 移除请求参数

  ![img](https://img.mubu.com/document_image/a4172ec9-cece-4c01-8133-b31566a1490a-172511.jpg)

- context路径修改

  ![img](https://img.mubu.com/document_image/905bfcc6-2a28-4f79-9a06-2d585ab1ed5c-172511.jpg)

- 重新返回头

  - RewriteLocationResponseHeader

    ![img](https://img.mubu.com/document_image/61169ebd-7638-46a8-87a4-f43d03e573bc-172511.jpg)

- 替换请求头参数

  ![img](https://img.mubu.com/document_image/ad65e001-7557-4a2e-b20e-3a62a5f981b1-172511.jpg)

- 保存 session

  ![img](https://img.mubu.com/document_image/6320460d-352e-4fa1-83c5-45c377a04fe4-172511.jpg)

- 安全头 SecureHeaders

  ![img](https://img.mubu.com/document_image/b2d593b8-415a-4839-a391-ae5f2b67289f-172511.jpg)

- SetPath 替换 context

  ![img](https://img.mubu.com/document_image/d2034169-8859-4272-a049-a48e7a23134c-172511.jpg)

- 请求头参数全部替换

  ![img](https://img.mubu.com/document_image/87336ae9-c5ff-4624-88d6-e8227f24c67b-172511.jpg)

- 返回头参数全部替换

  ![img](https://img.mubu.com/document_image/e56bf985-917f-48b4-95f8-2ccd3f80134f-172511.jpg)

- 修改返回状态

  ![img](https://img.mubu.com/document_image/4be1566a-fcbb-45fc-9ce8-5fd6bfb48a0b-172511.jpg)

- 踢出请求前缀

  ![img](https://img.mubu.com/document_image/ca03295e-2303-4d16-b57a-931f039e768a-172511.jpg)

- 重试机制

  ![img](https://img.mubu.com/document_image/0bd650b0-bc64-4c13-ae7d-e422843deb79-172511.jpg)

- 请求大小限制

  ![img](https://img.mubu.com/document_image/585bfceb-1dd8-46a5-ba9e-d1a424179940-172511.jpg)

- 替换源请求地址

  ![img](https://img.mubu.com/document_image/d2a17013-6446-4b45-a388-d17b1ab2be25-172511.jpg)

- 修改请求体

- 修改返回体

## Global Filter

- Filter 排序
- Routing 过滤器
- 负载均衡过滤器
- 响应时负载均衡
- Netty routing 过滤
- Netty Routing Filter
- Websocket Filter
- Metrics Filter

## HttpHeadersFilter

- RemoveHopByHop
  - 移除一些请求头
- XForwarded
  - 添加一些 X-Forwarded-* headers

## TLS 和 SSL

- 服务添加 SSL 认证

  ![img](https://img.mubu.com/document_image/38b58306-942c-4b6e-8ec7-cc913a461a5d-172511.jpg)

- GateWay 添加认证

  ![img](https://img.mubu.com/document_image/24034b5e-8020-4543-9dcc-cb9dbfe2f461-172511.jpg)

- TLS 握手配置

  ![img](https://img.mubu.com/document_image/3d015711-2418-4328-8035-05027f8eba0f-172511.jpg)

  

## 配置

- RouteDefinitionLocator 支持多种配置格式

  ![img](https://img.mubu.com/document_image/55c29e5f-3add-4c4e-9554-1176d0f0abd8-172511.jpg)

## Route 元数据配置

- 元数据配置

  ![img](https://img.mubu.com/document_image/47bae230-b9fa-445c-b970-8a9234817400-172511.jpg)

## Http 超时配置

- 全局配置

  ![img](https://img.mubu.com/document_image/a335ef16-a4a3-41ab-b900-4d044af5bd62-172511.jpg)

- 针对单个配置

  ![img](https://img.mubu.com/document_image/89be708a-fc2f-470e-8dc2-5aa0ab7d7235-172511.jpg)

- 支持流式配置

  ![img](https://img.mubu.com/document_image/7e7e9d18-2df7-4fa8-ae93-eab74ea780ec-172511.jpg)

## Netty 访问日志

- 访问日志配置

  ![img](https://img.mubu.com/document_image/f1f565cc-6b6f-43a7-842b-968cfa8d2d0e-172511.jpg)

## 跨域配置（CORS）

- 配置

  ![img](https://img.mubu.com/document_image/8f6041a7-750c-4a53-adcf-d0779416223b-172511.jpg)

## 网关监控

- 启动

  ![img](https://img.mubu.com/document_image/443f926f-97ec-42fa-adcc-916c4e23d8d1-172511.jpg)

- 查看网关 routes 配置信息

  - GET /actuator/gateway/routes

  - 对应开关

    ![img](https://img.mubu.com/document_image/41ea0186-6cf4-4d39-bdd5-258ff3bd8008-172511.jpg)

  - 返回结果

    ![img](https://img.mubu.com/document_image/6dbbc945-c181-45fb-a9d5-0fe0b685eb1d-172511.jpg)

- 检索路由过滤器

  - 全局过滤器

    - GET /actuator/gateway/globalfilters

      ![img](https://img.mubu.com/document_image/a09abed1-5b78-42f1-a9cb-15c12fdfad6d-172511.jpg)

  - 路由过滤器

    - GET /actuator/gateway/routefilters

      ![img](https://img.mubu.com/document_image/de5d7b91-8350-46d7-80b5-66a24025e28a-172511.jpg)

- 刷新路由缓存

  - POST /actuator/gateway/refresh

- 获取 route 列表详情

  - GET  /actuator/gateway/routes

- 获取单个 route 详情

  - GET /actuator/gateway/routes/{id}

- 新增一个 route

  - POST /gateway/routes/{id_route_to_create}

    ![img](https://img.mubu.com/document_image/877b4131-fb73-417d-829e-026dbf7f5117-172511.jpg)

- 删除一个 route

  - DELETE /gateway/routes/{id_route_to_delete}

- 获取所有的 endpoint

  - GET /actuator/gateway

## 常见问题

- 日志级别
  - org.springframework.cloud.gateway
  - org.springframework.http.server.reactive
  - org.springframework.web.reactive
  - org.springframework.boot.autoconfigure.web
  - reactor.netty
  - redisratelimiter
- 启动窃听功能
  - reactor.netty DEBUG、TRACE
  - spring.cloud.gateway.httpserver.wiretap=true
  - spring.cloud.gateway.httpclient.wiretap=true

## 定制网关

- 自定义 Route

  - 需要实现 RoutePredicateFactory 接口，一般继承 AbstractRoutePredicateFactory 类即可

  - 栗子

    ![img](https://img.mubu.com/document_image/c9ed1bf9-fc6c-41aa-8b97-e45934da70e9-172511.jpg)

- 自定义 GatewayFilter

  - 实现 GatewayFilterFactory 接口，一般继承 AbstractGatewayFilterFactory 类即可。

  - PreGatewayFilterFactory

    ![img](https://img.mubu.com/document_image/048ae3a7-107b-4325-9a33-1ccd3217a908-172511.jpg)

  - PostGatewayFilterFactory

    ![img](https://img.mubu.com/document_image/9e6f2c7d-f58b-4338-b039-3aad9d3fabbb-172511.jpg)

- 自定义 Global Filter

  - 实现 GlobalFilter 接口

  - 栗子

    ![img](https://img.mubu.com/document_image/0555fd93-d316-47a0-87f6-8aaddbe1c85b-172511.jpg)

## gateway 网关参数

- spring.cloud.gateway.default-filters
  - List of filter definitions that are applied to every route.
- spring.cloud.gateway.discovery.locator.enabled
  - false
  - Flag that enables DiscoveryClient gateway integration.
- spring.cloud.gateway.discovery.locator.filters
- spring.cloud.gateway.discovery.locator.include-expression
  - true
  - SpEL expression that will evaluate whether to include a service in gateway integration or not, defaults to: true.
- spring.cloud.gateway.discovery.locator.lower-case-service-id	false
  - Option to lower case serviceId in predicates and filters, defaults to false. Useful with eureka when it automatically uppercases serviceId. so MYSERIVCE, would match /myservice/**
- spring.cloud.gateway.discovery.locator.predicates
- spring.cloud.gateway.discovery.locator.route-id-prefix
  - The prefix for the routeId, defaults to discoveryClient.getClass().getSimpleName() + "_". Service Id will be appended to create the routeId.
- spring.cloud.gateway.discovery.locator.url-expression
  - '[lb://'+serviceId](lb://'+serviceId)
  - SpEL expression that create the uri for each route, defaults to: '[lb://'+serviceId](lb://'+serviceId).
- spring.cloud.gateway.enabled true
  - Enables gateway functionality.
- spring.cloud.gateway.fail-on-route-definition-error
  - true
  - Option to fail on route definition errors, defaults to true. Otherwise, a warning is logged.
- spring.cloud.gateway.filter.remove-hop-by-hop.headers
- spring.cloud.gateway.filter.remove-hop-by-hop.order
- spring.cloud.gateway.filter.request-rate-limiter.deny-empty-key
  - true
  - Switch to deny requests if the Key Resolver returns an empty key, defaults to true.
- spring.cloud.gateway.filter.request-rate-limiter.empty-key-status-code
  - HttpStatus to return when denyEmptyKey is true, defaults to FORBIDDEN.
- spring.cloud.gateway.filter.secure-headers.content-security-policy
  - default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline'
- spring.cloud.gateway.filter.secure-headers.content-type-options
  - nosniff
- spring.cloud.gateway.filter.secure-headers.disable
- spring.cloud.gateway.filter.secure-headers.download-options
  - noopen
- spring.cloud.gateway.filter.secure-headers.frame-options
  - DENY
- spring.cloud.gateway.filter.secure-headers.permitted-cross-domain-policies
  - none
- spring.cloud.gateway.filter.secure-headers.referrer-policy
  - no-referrer
- spring.cloud.gateway.filter.secure-headers.strict-transport-security
  - max-age=631138519
- spring.cloud.gateway.filter.secure-headers.xss-protection-header
  - 1 ; mode=block
- spring.cloud.gateway.forwarded.enabled
  - true
  - Enables the ForwardedHeadersFilter.
- spring.cloud.gateway.globalcors.add-to-simple-url-handler-mapping	false
  - If global CORS config should be added to the URL handler.
- spring.cloud.gateway.globalcors.cors-configurations
- spring.cloud.gateway.httpclient.connect-timeout
  - The connect timeout in millis, the default is 45s.
- spring.cloud.gateway.httpclient.max-header-size
  - The max response header size.
- spring.cloud.gateway.httpclient.max-initial-line-length
  - The max initial line length.
- spring.cloud.gateway.httpclient.pool.acquire-timeout
  - Only for type FIXED, the maximum time in millis to wait for aquiring.
- spring.cloud.gateway.httpclient.pool.max-connections
  - Only for type FIXED, the maximum number of connections before starting pending acquisition on existing ones.
- spring.cloud.gateway.httpclient.pool.max-idle-time
  - Time in millis after which the channel will be closed. If NULL, there is no max idle time.
- spring.cloud.gateway.httpclient.pool.max-life-time
  - Duration after which the channel will be closed. If NULL, there is no max life time.
- [spring.cloud.gateway.httpclient.pool.name](http://spring.cloud.gateway.httpclient.pool.name)
  - proxy
  - The channel pool map name, defaults to proxy.
- spring.cloud.gateway.httpclient.pool.type
  - Type of pool for HttpClient to use, defaults to ELASTIC.
- spring.cloud.gateway.httpclient.proxy.host
  - Hostname for proxy configuration of Netty HttpClient.
- spring.cloud.gateway.httpclient.proxy.non-proxy-hosts-pattern
  - Regular expression (Java) for a configured list of hosts. that should be reached directly, bypassing the proxy
- spring.cloud.gateway.httpclient.proxy.password
  - Password for proxy configuration of Netty HttpClient.
- spring.cloud.gateway.httpclient.proxy.port
  - Port for proxy configuration of Netty HttpClient.
- spring.cloud.gateway.httpclient.proxy.username
  - Username for proxy configuration of Netty HttpClient.
- spring.cloud.gateway.httpclient.response-timeout
  - The response timeout.
- spring.cloud.gateway.httpclient.ssl.close-notify-flush-timeout
  - 3000ms
  - SSL close_notify flush timeout. Default to 3000 ms.
- spring.cloud.gateway.httpclient.ssl.close-notify-flush-timeout-millis
- spring.cloud.gateway.httpclient.ssl.close-notify-read-timeout
  - SSL close_notify read timeout. Default to 0 ms.
- spring.cloud.gateway.httpclient.ssl.close-notify-read-timeout-millis
- spring.cloud.gateway.httpclient.ssl.default-configuration-type
  - The default ssl configuration type. Defaults to TCP.
- spring.cloud.gateway.httpclient.ssl.handshake-timeout
  - 10000ms
  - SSL handshake timeout. Default to 10000 ms
- spring.cloud.gateway.httpclient.ssl.handshake-timeout-millis
- spring.cloud.gateway.httpclient.ssl.key-password
  - Key password, default is same as keyStorePassword.
- spring.cloud.gateway.httpclient.ssl.key-store
  - Keystore path for Netty HttpClient.
- spring.cloud.gateway.httpclient.ssl.key-store-password
  - Keystore password.
- spring.cloud.gateway.httpclient.ssl.key-store-provider
  - Keystore provider for Netty HttpClient, optional field.
- spring.cloud.gateway.httpclient.ssl.key-store-type
  - JKS
  - Keystore type for Netty HttpClient, default is JKS.
- spring.cloud.gateway.httpclient.ssl.trusted-x509-certificates
  - Trusted certificates for verifying the remote endpoint’s certificate.
- spring.cloud.gateway.httpclient.ssl.use-insecure-trust-manager
  - false
  - Installs the netty InsecureTrustManagerFactory. This is insecure and not suitable for production.
- spring.cloud.gateway.httpclient.websocket.max-frame-payload-length
  - Max frame payload length.
- spring.cloud.gateway.httpclient.websocket.proxy-ping
  - true
  - Proxy ping frames to downstream services, defaults to true.
- spring.cloud.gateway.httpclient.wiretap
  - false
  - Enables wiretap debugging for Netty HttpClient.
- spring.cloud.gateway.httpserver.wiretap
  - false
  - Enables wiretap debugging for Netty HttpServer.
- spring.cloud.gateway.loadbalancer.use404
  - false
- spring.cloud.gateway.metrics.enabled
  - true
  - Enables the collection of metrics data.
- spring.cloud.gateway.metrics.tags
  - Tags map that added to metrics.
- spring.cloud.gateway.redis-rate-limiter.burst-capacity-header
  - X-RateLimit-Burst-Capacity
  - The name of the header that returns the burst capacity configuration.
- spring.cloud.gateway.redis-rate-limiter.config
- spring.cloud.gateway.redis-rate-limiter.include-headers
  - true
  - Whether or not to include headers containing rate limiter information, defaults to true.
- spring.cloud.gateway.redis-rate-limiter.remaining-header
  - X-RateLimit-Remaining
  - The name of the header that returns number of remaining requests during the current second.
- spring.cloud.gateway.redis-rate-limiter.replenish-rate-header
  - X-RateLimit-Replenish-Rate
  - The name of the header that returns the replenish rate configuration.
- spring.cloud.gateway.redis-rate-limiter.requested-tokens-header
  - X-RateLimit-Requested-Tokens
- The name of the header that returns the requested tokens configuration.
  - spring.cloud.gateway.routes
  - List of Routes.
- spring.cloud.gateway.set-status.original-status-header-name
  - The name of the header which contains http code of the proxied request.
- spring.cloud.gateway.streaming-media-types
- spring.cloud.gateway.x-forwarded.enabled
  - true
  - If the XForwardedHeadersFilter is enabled.
- spring.cloud.gateway.x-forwarded.for-append
  - true
  - If appending X-Forwarded-For as a list is enabled.
- spring.cloud.gateway.x-forwarded.for-enabled
  - true
  - If X-Forwarded-For is enabled.
- spring.cloud.gateway.x-forwarded.host-append
  - true
  - If appending X-Forwarded-Host as a list is enabled.
- spring.cloud.gateway.x-forwarded.host-enabled
  - true
  - If X-Forwarded-Host is enabled.
- spring.cloud.gateway.x-forwarded.order
  - 0
  - The order of the XForwardedHeadersFilter.
- spring.cloud.gateway.x-forwarded.port-append
  - true
  - If appending X-Forwarded-Port as a list is enabled.
- spring.cloud.gateway.x-forwarded.port-enabled
  - true
  - If X-Forwarded-Port is enabled.
- spring.cloud.gateway.x-forwarded.prefix-append
  - true
  - If appending X-Forwarded-Prefix as a list is enabled.
- spring.cloud.gateway.x-forwarded.prefix-enabled
  - true
  - If X-Forwarded-Prefix is enabled.
- spring.cloud.gateway.x-forwarded.proto-append
  - true
  - If appending X-Forwarded-Proto as a list is enabled.
- spring.cloud.gateway.x-forwarded.proto-enabled
  - true
  - If X-Forwarded-Proto is enabled.