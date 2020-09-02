---
title: SpringCloud-Gateway扫盲
tags: [SpringCloud, Gateway]
img: https://www.holddie.com/img/20200105161400.jpg
date: 2018-07-08 14:37:01
categories: SpringCloud
---

你的命，如物，却不在你手中！															——白二丫头



# Spring Cloud Gateway

------

**Table of Contents

- 

- [1. How to Include Spring Cloud Gateway](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#gateway-starter)

- [2. Glossary](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_glossary)

- [3. How It Works](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#gateway-how-it-works)

- [4. Route Predicate Factories](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#gateway-request-predicates-factories)

  [4.1. After Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_after_route_predicate_factory)[4.2. Before Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_before_route_predicate_factory)[4.3. Between Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_between_route_predicate_factory)[4.4. Cookie Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_cookie_route_predicate_factory)[4.5. Header Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_header_route_predicate_factory)[4.6. Host Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_host_route_predicate_factory)[4.7. Method Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_method_route_predicate_factory)[4.8. Path Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_path_route_predicate_factory)[4.9. Query Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_query_route_predicate_factory)[4.10. RemoteAddr Route Predicate Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_remoteaddr_route_predicate_factory)[4.10.1. Modifying the way remote addresses are resolved](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_modifying_the_way_remote_addresses_are_resolved)

- [5. GatewayFilter Factories](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_gatewayfilter_factories)

  [5.1. AddRequestHeader GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_addrequestheader_gatewayfilter_factory)[5.2. AddRequestParameter GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_addrequestparameter_gatewayfilter_factory)[5.3. AddResponseHeader GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_addresponseheader_gatewayfilter_factory)[5.4. Hystrix GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_hystrix_gatewayfilter_factory)[5.5. PrefixPath GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_prefixpath_gatewayfilter_factory)[5.6. PreserveHostHeader GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_preservehostheader_gatewayfilter_factory)[5.7. RequestRateLimiter GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_requestratelimiter_gatewayfilter_factory)[5.7.1. Redis RateLimiter](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_redis_ratelimiter)[5.8. RedirectTo GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_redirectto_gatewayfilter_factory)[5.9. RemoveNonProxyHeaders GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_removenonproxyheaders_gatewayfilter_factory)[5.10. RemoveRequestHeader GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_removerequestheader_gatewayfilter_factory)[5.11. RemoveResponseHeader GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_removeresponseheader_gatewayfilter_factory)[5.12. RewritePath GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_rewritepath_gatewayfilter_factory)[5.13. SaveSession GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_savesession_gatewayfilter_factory)[5.14. SecureHeaders GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_secureheaders_gatewayfilter_factory)[5.15. SetPath GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_setpath_gatewayfilter_factory)[5.16. SetResponseHeader GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_setresponseheader_gatewayfilter_factory)[5.17. SetStatus GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_setstatus_gatewayfilter_factory)[5.18. StripPrefix GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_stripprefix_gatewayfilter_factory)[5.19. Retry GatewayFilter Factory](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_retry_gatewayfilter_factory)

- [6. Global Filters](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_global_filters)

  [6.1. Combined Global Filter and GatewayFilter Ordering](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_combined_global_filter_and_gatewayfilter_ordering)[6.2. Forward Routing Filter](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_forward_routing_filter)[6.3. LoadBalancerClient Filter](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_loadbalancerclient_filter)[6.4. Netty Routing Filter](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_netty_routing_filter)[6.5. Netty Write Response Filter](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_netty_write_response_filter)[6.6. RouteToRequestUrl Filter](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_routetorequesturl_filter)[6.7. Websocket Routing Filter](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_websocket_routing_filter)[6.8. Making An Exchange As Routed](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_making_an_exchange_as_routed)

- [7. Configuration](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_configuration)

  [7.1. Fluent Java Routes API](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_fluent_java_routes_api)[7.2. DiscoveryClient Route Definition Locator](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_discoveryclient_route_definition_locator)

- [8. Actuator API](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_actuator_api)

- [9. Developer Guide](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_developer_guide)

  [9.1. Writing Custom Route Predicate Factories](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_writing_custom_route_predicate_factories)[9.2. Writing Custom GatewayFilter Factories](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_writing_custom_gatewayfilter_factories)[9.3. Writing Custom Global Filters](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_writing_custom_global_filters)[9.4. Writing Custom Route Locators and Writers](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_writing_custom_route_locators_and_writers)

- [10. Building a Simple Gateway Using Spring MVC or Webflux](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#_building_a_simple_gateway_using_spring_mvc_or_webflux)

# 

**2.0.1.BUILD-SNAPSHOT**

This project provides an API Gateway built on top of the Spring Ecosystem, including: Spring 5, Spring Boot 2 and Project Reactor. Spring Cloud Gateway aims to provide a simple, yet effective way to route to APIs and provide cross cutting concerns to them such as: security, monitoring/metrics, and resiliency.

# 1. How to Include Spring Cloud Gateway

To include Spring Cloud Gateway in your project use the starter with group `org.springframework.cloud` and artifact id `spring-cloud-starter-gateway`. See the [Spring Cloud Project page](https://projects.spring.io/spring-cloud/) for details on setting up your build system with the current Spring Cloud Release Train.

If you include the starter, but, for some reason, you do not want the gateway to be enabled, set `spring.cloud.gateway.enabled=false`.

| ![[Important]](https://cloud.spring.io/spring-cloud-gateway/single/images/important.png) | Important |
| ------------------------------------------------------------ | --------- |
| Spring Cloud Gateway requires the Netty runtime provided by Spring Boot and Spring Webflux. It does not work in a traditional Servlet Container or built as a WAR. |           |

# 2. Glossary

- **Route**: Route the basic building block of the gateway. It is defined by an ID, a destination URI, a collection of predicates and a collection of filters. A route is matched if aggregate predicate is true.
- **Predicate**: This is a [Java 8 Function Predicate](https://docs.oracle.com/javase/8/docs/api/java/util/function/Predicate.html). The input type is a [Spring Framework `ServerWebExchange`](https://docs.spring.io/spring/docs/5.0.x/javadoc-api/org/springframework/web/server/ServerWebExchange.html). This allows developers to match on anything from the HTTP request, such as headers or parameters.
- **Filter**: These are instances [Spring Framework `GatewayFilter`](https://docs.spring.io/spring/docs/5.0.x/javadoc-api/org/springframework/web/server/GatewayFilter.html) constructed in with a specific factory. Here, requests and responses can be modified before or after sending the downstream request.

# 3. How It Works

![Spring Cloud Gateway Diagram](https://raw.githubusercontent.com/spring-cloud/spring-cloud-gateway/master/docs/src/main/asciidoc/images/spring_cloud_gateway_diagram.png)

Clients make requests to Spring Cloud Gateway. If the Gateway Handler Mapping determines that a request matches a Route, it is sent to the Gateway Web Handler. This handler runs sends the request through a filter chain that is specific to the request. The reason the filters are divided by the dotted line, is that filters may execute logic before the proxy request is sent or after. All "pre" filter logic is executed, then the proxy request is made. After the proxy request is made, the "post" filter logic is executed.

| ![[Note]](https://cloud.spring.io/spring-cloud-gateway/single/images/note.png) |
| ------------------------------------------------------------ |
| URIs defined in routes without a port will get a default port set to 80 and 443 for HTTP and HTTPS URIs respectively. |

# 4. Route Predicate Factories

Spring Cloud Gateway matches routes as part of the Spring WebFlux `HandlerMapping` infrastructure. Spring Cloud Gateway includes many built-in Route Predicate Factories. All of these predicates match on different attributes of the HTTP request. Multiple Route Predicate Factories can be combined and are combined via logical `and`.

## 4.1 After Route Predicate Factory

The After Route Predicate Factory takes one parameter, a datetime. This predicate matches requests that happen after the current datetime.

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: after_route
        uri: http://example.org
        predicates:
        - After=2017-01-20T17:42:47.789-07:00[America/Denver]
```

This route matches any request after Jan 20, 2017 17:42 Mountain Time (Denver).

## 4.2 Before Route Predicate Factory

The Before Route Predicate Factory takes one parameter, a datetime. This predicate matches requests that happen before the current datetime.

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: before_route
        uri: http://example.org
        predicates:
        - Before=2017-01-20T17:42:47.789-07:00[America/Denver]
```

This route matches any request before Jan 20, 2017 17:42 Mountain Time (Denver).

## 4.3 Between Route Predicate Factory

The Between Route Predicate Factory takes two parameters, datetime1 and datetime2. This predicate matches requests that happen after datetime1 and before datetime2. The datetime2 parameter must be after datetime1.

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: between_route
        uri: http://example.org
        predicates:
        - Between=2017-01-20T17:42:47.789-07:00[America/Denver], 2017-01-21T17:42:47.789-07:00[America/Denver]
```

This route matches any request after Jan 20, 2017 17:42 Mountain Time (Denver) and before Jan 21, 2017 17:42 Mountain Time (Denver). This could be useful for maintenance windows.

## 4.4 Cookie Route Predicate Factory

The Cookie Route Predicate Factory takes two parameters, the cookie name and a regular expression. This predicate matches cookies that have the given name and the value matches the regular expression.

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: cookie_route
        uri: http://example.org
        predicates:
        - Cookie=chocolate, ch.p
```

This route matches the request has a cookie named `chocolate` who’s value matches the `ch.p` regular expression.

## 4.5 Header Route Predicate Factory

The Header Route Predicate Factory takes two parameters, the header name and a regular expression. This predicate matches with a header that has the given name and the value matches the regular expression.

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: header_route
        uri: http://example.org
        predicates:
        - Header=X-Request-Id, \d+
```

This route matches if the request has a header named `X-Request-Id` whos value matches the `\d+` regular expression (has a value of one or more digits).

## 4.6 Host Route Predicate Factory

The Host Route Predicate Factory takes one parameter: the host name pattern. The pattern is an Ant style pattern with `.` as the separator. This predicates matches the `Host` header that matches the pattern.

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: host_route
        uri: http://example.org
        predicates:
        - Host=**.somehost.org
```

This route would match if the request has a `Host` header has the value `www.somehost.org` or `beta.somehost.org`.

## 4.7 Method Route Predicate Factory

The Method Route Predicate Factory takes one parameter: the HTTP method to match.

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: method_route
        uri: http://example.org
        predicates:
        - Method=GET
```

This route would match if the request method was a `GET`.

## 4.8 Path Route Predicate Factory

The Path Route Predicate Factory takes one parameter: a Spring `PathMatcher` pattern.

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: host_route
        uri: http://example.org
        predicates:
        - Path=/foo/{segment}
```

This route would match if the request path was, for example: `/foo/1` or `/foo/bar`.

This predicate extracts the URI template variables (like `segment` defined in the example above) as a map of names and values and places it in the `ServerWebExchange.getAttributes()` with a key defined in `PathRoutePredicate.URL_PREDICATE_VARS_ATTR`. Those values are then available for use by [GatewayFilter Factories](https://cloud.spring.io/spring-cloud-gateway/single/spring-cloud-gateway.html#gateway-route-filters)

## 4.9 Query Route Predicate Factory

The Query Route Predicate Factory takes two parameters: a required `param` and an optional `regexp`.

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: query_route
        uri: http://example.org
        predicates:
        - Query=baz
```

This route would match if the request contained a `baz` query parameter.

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: query_route
        uri: http://example.org
        predicates:
        - Query=foo, ba.
```

This route would match if the request contained a `foo` query parameter whose value matched the `ba.` regexp, so `bar` and `baz` would match.

## 4.10 RemoteAddr Route Predicate Factory

The RemoteAddr Route Predicate Factory takes a list (min size 1) of CIDR-notation (IPv4 or IPv6) strings, e.g. `192.168.0.1/16` (where `192.168.0.1` is an IP address and `16` is a subnet mask).

**application.yml.** 

```
spring:
  cloud:
    gateway:
      routes:
      - id: remoteaddr_route
        uri: http://example.org
        predicates:
        - RemoteAddr=192.168.1.1/24
```

This route would match if the remote address of the request was, for example, `192.168.1.10`.

### 4.10.1 Modifying the way remote addresses are resolved

By default the RemoteAddr Route Predicate Factory uses the remote address from the incoming request. This may not match the actual client IP address if Spring Cloud Gateway sits behind a proxy layer.

You can customize the way that the remote address is resolved by setting a custom `RemoteAddressResolver`. Spring Cloud Gateway comes with one non-default remote address resolver which is based off of the [X-Forwarded-For header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For), `XForwardedRemoteAddressResolver`.

`XForwardedRemoteAddressResolver` has two static constructor methods which take different approaches to security:

`XForwardedRemoteAddressResolver::trustAll` returns a `RemoteAddressResolver` which always takes the first IP address found in the `X-Forwarded-For`header. This approach is vulnerable to spoofing, as a malicious client could set an initial value for the `X-Forwarded-For` which would be accepted by the resolver.

`XForwardedRemoteAddressResolver::maxTrustedIndex` takes an index which correlates to the number of trusted infrastructure running in front of Spring Cloud Gateway. If Spring Cloud Gateway is, for example only accessible via HAProxy, then a value of 1 should be used. If two hops of trusted infrastructure are required before Spring Cloud Gateway is accessible, then a value of 2 should be used.

Given the following header value:

```
X-Forwarded-For: 0.0.0.1, 0.0.0.2, 0.0.0.3
```

The `maxTrustedIndex` values below will yield the following remote addresses.

| `maxTrustedIndex`        | result                                                      |
| ------------------------ | ----------------------------------------------------------- |
| [`Integer.MIN_VALUE`,0]  | (invalid, `IllegalArgumentException` during initialization) |
| 1                        | 0.0.0.3                                                     |
| 2                        | 0.0.0.2                                                     |
| 3                        | 0.0.0.1                                                     |
| [4, `Integer.MAX_VALUE`] | 0.0.0.1                                                     |

Using Java config:

GatewayConfig.java

```yaml
RemoteAddressResolver resolver = XForwardedRemoteAddressResolver
    .maxTrustedIndex(1);

...

.route("direct-route",
    r -> r.remoteAddr("10.1.1.1", "10.10.1.1/24")
        .uri("https://downstream1")
.route("proxied-route",
    r -> r.remoteAddr(resolver,  "10.10.1.1", "10.10.1.1/24")
        .uri("https://downstream2")
)
```

# 5. GatewayFilter Factories

Route filters allow the modification of the incoming HTTP request or outgoing HTTP response in some manner. Route filters are scoped to a particular route. Spring Cloud Gateway includes many built-in GatewayFilter Factories.

NOTE For more detailed examples on how to use any of the following filters, take a look at the [unit tests](https://github.com/spring-cloud/spring-cloud-gateway/tree/master/spring-cloud-gateway-core/src/test/java/org/springframework/cloud/gateway/filter/factory).

## 5.1 AddRequestHeader GatewayFilter Factory

The AddRequestHeader GatewayFilter Factory takes a name and value parameter.

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: add_request_header_route
        uri: http://example.org
        filters:
        - AddRequestHeader=X-Request-Foo, Bar
```

This will add `X-Request-Foo:Bar` header to the downstream request’s headers for all matching requests.

## 5.2 AddRequestParameter GatewayFilter Factory

The AddRequestParameter GatewayFilter Factory takes a name and value parameter.

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: add_request_parameter_route
        uri: http://example.org
        filters:
        - AddRequestParameter=foo, bar
```

This will add `foo=bar` to the downstream request’s query string for all matching requests.

## 5.3 AddResponseHeader GatewayFilter Factory

The AddResponseHeader GatewayFilter Factory takes a name and value parameter.

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: add_request_header_route
        uri: http://example.org
        filters:
        - AddResponseHeader=X-Response-Foo, Bar
```

This will add `X-Response-Foo:Bar` header to the downstream response’s headers for all matching requests.

## 5.4 Hystrix GatewayFilter Factory

[Hystrix](https://github.com/Netflix/Hystrix) is a library from Netflix that implements the [circuit breaker pattern](https://martinfowler.com/bliki/CircuitBreaker.html). The Hystrix GatewayFilter allows you to introduce circuit breakers to your gateway routes, protecting your services from cascading failures and allowing you to provide fallback responses in the event of downstream failures.

To enable Hystrix GatewayFilters in your project, add a dependency on `spring-cloud-starter-netflix-hystrix` from [Spring Cloud Netflix](https://cloud.spring.io/spring-cloud-netflix/).

The Hystrix GatewayFilter Factory requires a single `name` parameter, which is the name of the `HystrixCommand`.

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: hystrix_route
        uri: http://example.org
        filters:
        - Hystrix=myCommandName
```

This wraps the remaining filters in a `HystrixCommand` with command name `myCommandName`.

The Hystrix filter can also accept an optional `fallbackUri` parameter. Currently, only `forward:` schemed URIs are supported. If the fallback is called, the request will be forwarded to the controller matched by the URI.

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: hystrix_route
        uri: lb://backing-service:8088
        predicates:
        - Path=/consumingserviceendpoint
        filters:
        - name: Hystrix
          args:
            name: fallbackcmd
            fallbackUri: forward:/incaseoffailureusethis
        - RewritePath=/consumingserviceendpoint, /backingserviceendpoint
```

This will forward to the `/incaseoffailureusethis` URI when the Hystrix fallback is called. Note that this example also demonstrates (optional) Spring Cloud Netflix Ribbon load-balancing via the `lb` prefix on the destination URI.

Hystrix settings (such as timeouts) can be configured with global defaults or on a route by route basis using application properties as explained on the [Hystrix wiki](https://github.com/Netflix/Hystrix/wiki/Configuration).

To set a 5 second timeout for the example route above, the following configuration would be used:

**application.yml.** 

```properties
hystrix.command.fallbackcmd.execution.isolation.thread.timeoutInMilliseconds: 5000
```

## 5.5 PrefixPath GatewayFilter Factory

PrefixPath 过滤器需要一个 prefix 参数，就是添加添加前缀，在访问的请求前面添加一个路径参数。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: prefixpath_route
        uri: http://example.org
        filters:
        - PrefixPath=/mypath
```

使用 PrefixPath 参数，但我们原本访问 `/hello` 路径的时候，此时访问后端的时候，我们就会添加 `/mypath` 前缀，最后的发送到后端的路径为：`/mypath/hello`。

## 5.6 PreserveHostHeader GatewayFilter Factory

保留请求头过滤器不需要参数，使用测试过滤器可以透传客户端访问时参数的后端访问到的参数。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: preserve_host_route
        uri: http://example.org
        filters:
        - PreserveHostHeader
```

## 5.7 RequestRateLimiter GatewayFilter Factory

The RequestRateLimiter GatewayFilter Factory is uses a `RateLimiter` implementation to determine if the current request is allowed to proceed. If it is not, a status of `HTTP 429 - Too Many Requests` (by default) is returned.

This filter takes an optional `keyResolver` parameter and parameters specific to the rate limiter (see below).

`keyResolver` is a bean that implements the `KeyResolver` interface. In configuration, reference the bean by name using SpEL. `#{@myKeyResolver}` is a SpEL expression referencing a bean with the name `myKeyResolver`.

**KeyResolver.java.** 

```java
public interface KeyResolver {
	Mono<String> resolve(ServerWebExchange exchange);
}
```

The `KeyResolver` interface allows pluggable strategies to derive the key for limiting requests. In future milestones, there will be some `KeyResolver` implementations.

The default implementation of `KeyResolver` is the `PrincipalNameKeyResolver` which retrieves the `Principal` from the `ServerWebExchange` and calls `Principal.getName()`.

| ![[Note]](https://cloud.spring.io/spring-cloud-gateway/single/images/note.png) |
| ------------------------------------------------------------ |
| The RequestRateLimiter is not configurable via the "shortcut" notation. The example below is *invalid* |

**application.properties.** 

```properties
# INVALID SHORTCUT CONFIGURATION
spring.cloud.gateway.routes[0].filters[0]=RequestRateLimiter=2, 2, #{@userkeyresolver}
```

### 5.7.1 Redis RateLimiter

The redis implementation is based off of work done at [Stripe](https://stripe.com/blog/rate-limiters). It requires the use of the `spring-boot-starter-data-redis-reactive` Spring Boot starter.

The algorithm used is the [Token Bucket Algorithm](https://en.wikipedia.org/wiki/Token_bucket).

The `redis-rate-limiter.replenishRate` is how many requests per second do you want a user to be allowed to do, without any dropped requests. This is the rate that the token bucket is filled.

The `redis-rate-limiter.burstCapacity` is the maximum number of requests a user is allowed to do in a single second. This is the number of tokens the token bucket can hold. Setting this value to zero will block all requests.

A steady rate is accomplished by setting the same value in `replenishRate` and `burstCapacity`. Temporary bursts can be allowed by setting `burstCapacity` higher than `replenishRate`. In this case, the rate limiter needs to be allowed some time between bursts (according to `replenishRate`), as 2 consecutive bursts will result in dropped requests (`HTTP 429 - Too Many Requests`).

**application.yml.** 

```java
spring:
  cloud:
    gateway:
      routes:
      - id: requestratelimiter_route
        uri: http://example.org
        filters:
        - name: RequestRateLimiter
          args:
            redis-rate-limiter.replenishRate: 10
            redis-rate-limiter.burstCapacity: 20
```

**Config.java.** 

```java
@Bean
KeyResolver userKeyResolver() {
    return exchange -> Mono.just(exchange.getRequest().getQueryParams().getFirst("user"));
}
```

This defines a request rate limit of 10 per user. A burst of 20 is allowed, but the next second only 10 requests will be available. The `KeyResolver` is a simple one that gets the `user` request parameter (note: this is not recommended for production).

A rate limiter can also be defined as a bean implementing the `RateLimiter` interface. In configuration, reference the bean by name using SpEL. `#{@myRateLimiter}`is a SpEL expression referencing a bean with the name `myRateLimiter`.

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: requestratelimiter_route
        uri: http://example.org
        filters:
        - name: RequestRateLimiter
          args:
            rate-limiter: "#{@myRateLimiter}"
            key-resolver: "#{@userKeyResolver}"
```

## 5.8 RedirectTo GatewayFilter Factory

The RedirectTo GatewayFilter Factory takes a `status` and a `url` parameter. The status should be a 300 series redirect http code, such as 301. The url should be a valid url. This will be the value of the `Location` header.

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: prefixpath_route
        uri: http://example.org
        filters:
        - RedirectTo=302, http://acme.org
```

This will send a status 302 with a `Location:http://acme.org` header to perform a redirect.

## 5.9 RemoveNonProxyHeaders GatewayFilter Factory

The RemoveNonProxyHeaders GatewayFilter Factory removes headers from forwarded requests. The default list of headers that is removed comes from the [IETF](https://tools.ietf.org/html/draft-ietf-httpbis-p1-messaging-14#section-7.1.3).

**The default removed headers are:**

- Connection
- Keep-Alive
- Proxy-Authenticate
- Proxy-Authorization
- TE
- Trailer
- Transfer-Encoding
- Upgrade

To change this, set the `spring.cloud.gateway.filter.remove-non-proxy-headers.headers` property to the list of header names to remove.

## 5.10 RemoveRequestHeader GatewayFilter Factory

移除请求头参数，需要制定一个参数名称，被指定的参数将会被过滤传送给下游。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: removerequestheader_route
        uri: http://example.org
        filters:
        - RemoveRequestHeader=X-Request-Foo
```

## 5.11 RemoveResponseHeader GatewayFilter Factory

同理制定返回时请求头的过滤参数，被指定的参数会被忽略，返回给请求端的时候，去除掉指定的参数。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: removeresponseheader_route
        uri: http://example.org
        filters:
        - RemoveResponseHeader=X-Response-Foo
```

## 5.12 RewritePath GatewayFilter Factory

重定向过滤器需要**匹配一个正则表达式**和**要一个跳转的参数**，使用java的正则表达式更加灵活重定向请求地址。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: rewritepath_route
        uri: http://example.org
        predicates:
        - Path=/foo/**
        filters:
        - RewritePath=/foo/(?<segment>.*), /$\{segment}
```

对于 `/foo/bar` 的请求转发到下游为 `/bar`，在YAML规范中，我们会注意到使用 `$\` 来代替 `$`。

## 5.13 SaveSession GatewayFilter Factory

使用SaveSession过滤器，在跳转下游的时候强制进行 `WebSession::save` 操作。

这是常用的一个操作使用Spring Session进行数据懒加载，在进行跳转前需要确保session已经被存储。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: save_session
        uri: http://example.org
        predicates:
        - Path=/foo/**
        filters:
        - SaveSession
```

如果要将Spring Security与Spring Session集成，并且希望确保将安全性详细信息转发到远程进程，则这很关键。

## 5.14 SecureHeaders GatewayFilter Factory

为了确保返回时请求头的安全，在请求头添加数字，来确保这些，具体建议参考这篇文章：https://blog.appcanary.com/2017/http-security-headers.html

**The following headers are added (allong with default values):**

- `X-Xss-Protection:1; mode=block`
- `Strict-Transport-Security:max-age=631138519`
- `X-Frame-Options:DENY`
- `X-Content-Type-Options:nosniff`
- `Referrer-Policy:no-referrer`
- `Content-Security-Policy:default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline'`
- `X-Download-Options:noopen`
- `X-Permitted-Cross-Domain-Policies:none`

上述展示的是默认属性，若我们想要修改对应的值，所有的值在：`spring.cloud.gateway.filter.secure-headers` 命名空间里：

**Property to change:**

- `xss-protection-header`
- `strict-transport-security`
- `frame-options`
- `content-type-options`
- `referrer-policy`
- `content-security-policy`
- `download-options`
- `permitted-cross-domain-policies`

## 5.15 SetPath GatewayFilter Factory

SetPath 过滤器使用路径模板参数，他通过使用自定义模板参数方式操作请求路径，在此处使用了SpringFramework的URI模板方法。多个请求的段也是可以的。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: setpath_route
        uri: http://example.org
        predicates:
        - Path=/foo/{segment}
        filters:
        - SetPath=/{segment}
```

对于一个 `/foo/bar` 的请求，在发送的下游的时候会把路径定义为 `/bar`。

## 5.16 SetResponseHeader GatewayFilter Factory

设置返回头所带参数，过滤器需要使用name和value参数。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: setresponseheader_route
        uri: http://example.org
        filters:
        - SetResponseHeader=X-Response-Foo, Bar
```

网关返回头过滤器，将会按照配置完全替换对应的头信息，而不是把对应的参数添加进去。举个栗子，如果下游返回的结果头中包含 `X-Response-Foo:1234` ，那么过滤器将会 `X-Response-Foo:Bar` 进行替换，最终返回给客户端。

## 5.17 SetStatus GatewayFilter Factory

SetStatus 过滤器需要一个表示状态的参数，底层使用的是`HttpStatus` 枚举对应的状态，因此可以使用数字 `404` 表示，也可以使用 `NOT_FOUND`。

```java
public static final int SC_NOT_FOUND = 404;
```

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: setstatusstring_route
        uri: http://example.org
        filters:
        - SetStatus=BAD_REQUEST
      - id: setstatusint_route
        uri: http://example.org
        filters:
        - SetStatus=401
```

对于这种情况，我们默认返回 `401` HTTP状态码。

## 5.18 StripPrefix GatewayFilter Factory

StripPrefix 过滤器需要一个 `parts` 参数，数字`parts`表示在请求转发到下游之前忽略的路径数。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: nameRoot
        uri: http://nameservice
        predicates:
        - Path=/name/**
        filters:
        - StripPrefix=2
```

此处表示当一个请求为 `/name/bar/foo` 经过网关后，到达后端服务时地址为：`http://nameservice/foo`,对于中间的 `/name/bar`路径就被忽略了。

## 5.19 Retry GatewayFilter Factory

The Retry GatewayFilter Factory takes `retries`, `statuses`, `methods`, and `series` as parameters.

对于Retry 过滤器来说需要 `retries`，`statuses`，`methods` 和 `series` 四个参数。 

- `retries`: 请求尝试次数

- `statuses`:需要被尝试的状态码，详情参考 `org.springframework.http.HttpStatus` 规范

- `methods`: 会尝试的请求方法, 详情参考 `org.springframework.http.HttpMethod`。

  ```java
  public enum HttpMethod {
      GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE;
  }
  ```

- `series`: 那个大的系列要被重试, 参考使用 `org.springframework.http.HttpStatus.Series`

  ```java
  public enum Series {
      INFORMATIONAL(1),
      SUCCESSFUL(2),
      REDIRECTION(3),
      CLIENT_ERROR(4),
      SERVER_ERROR(5);
  }
  ```

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: retry_test
        uri: http://localhost:8080/flakey
        predicates:
        - Host=*.retry.com
        filters:
        - name: Retry
          args:
            retries: 3
            statuses: BAD_GATEWAY
```

| ![[Note]](https://cloud.spring.io/spring-cloud-gateway/single/images/note.png) |
| ------------------------------------------------------------ |
| 此时当我们URI使用了跳转协议，不支持重试过滤器。              |

# 6. Global Filters

全局过滤器接口 和`GatewayFilter` 拥有相同的特性，这里有些特殊的过滤器将会被应用于全局routes。

## 6.1 Combined Global Filter and GatewayFilter Ordering

当一个请求来临（或者匹配到Route）时，`Filtering Web Handler` 将会添加所有的`GlobalFilter`实例以及具体的`Route实例`到过滤请求链中。这个混合的请求链因为实现 Order 接口而排序，对于 Filter 可以使用 `getOrder` 方法或 `@Order` 注解设置`Order` 顺序。

由于Spring Cloud Gateway区分了过滤器逻辑执行的“前”和“后”阶段（请参阅：工作原理），具有最高优先级的过滤器将是“前”阶段中的第一个和“后”阶段中的最后一个 。

**ExampleConfiguration.java.** 

```java
@Bean
@Order(-1)
public GlobalFilter a() {
    return (exchange, chain) -> {
        log.info("first pre filter");
        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            log.info("third post filter");
        }));
    };
}

@Bean
@Order(0)
public GlobalFilter b() {
    return (exchange, chain) -> {
        log.info("second pre filter");
        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            log.info("second post filter");
        }));
    };
}

@Bean
@Order(1)
public GlobalFilter c() {
    return (exchange, chain) -> {
        log.info("third pre filter");
        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            log.info("first post filter");
        }));
    };
}
```

## 6.2 Forward Routing Filter

跳转路由过滤器在 `ServerWebExchangeUtils.GATEWAY_REQUEST_URL_ATTR` 属性寻找 `URI` 。如果 URL 有 forward 跳转模式（ie `forward:///localendpoint`）,他将默认使用`spring`中的 `DispatherHandler`去处理这个请求。未定义的原始RUL将会被追加到 `ServerWebExchangeUtils.GATEWAY_ORIGINAL_REQUEST_URL_ATTR` 属性列表中。

## 6.3 LoadBalancerClient Filter

负载均衡客户端过滤器 同理在 `ServerWebExchangeUtils.GATEWAY_REQUEST_URL_ATTR` 的属性中寻找URI。如果一个URL中有一个`lb`模式（ie  `lb:myservice`）,那么那将会使用SpringCloud的负载均衡客户端去解析这个名称最终打到一个真实的Host和Port端口上，未定义的原始URL将会被追加到未定的属性列表中。这个过滤器同样也会去`ServerWebExchangeUtils.GATEWAY_SCHEME_PREFIX_ATTR` 属性列表中去寻找URI，如果等于`lb`然后规则和上述相同。

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: myRoute
        uri: lb://service
        predicates:
        - Path=/service/**
```

## 6.4 Netty Routing Filter

The Netty Routing Filter runs if the url located in the `ServerWebExchangeUtils.GATEWAY_REQUEST_URL_ATTR` exchange attribute has a `http` or `https` scheme. It uses the Netty `HttpClient` to make the downstream proxy request. The response is put in the `ServerWebExchangeUtils.CLIENT_RESPONSE_ATTR` exchange attribute for use in a later filter. (There is an experimental `WebClientHttpRoutingFilter` that performs the same function, but does not require netty)

## 6.5 Netty Write Response Filter

The `NettyWriteResponseFilter` runs if there is a Netty `HttpClientResponse` in the `ServerWebExchangeUtils.CLIENT_RESPONSE_ATTR` exchange attribute. It is run after all other filters have completed and writes the proxy response back to the gateway client response. (There is an experimental `WebClientWriteResponseFilter` that performs the same function, but does not require netty)

## 6.6 RouteToRequestUrl Filter

The `RouteToRequestUrlFilter` runs if there is a `Route` object in the `ServerWebExchangeUtils.GATEWAY_ROUTE_ATTR` exchange attribute. It creates a new URI, based off of the request URI, but updated with the URI attribute of the `Route` object. The new URI is placed in the `ServerWebExchangeUtils.GATEWAY_REQUEST_URL_ATTR` exchange attribute.

If the URI has a scheme prefix, such as `lb:ws://serviceid`, the `lb` scheme is stripped from the URI and placed in the `ServerWebExchangeUtils.GATEWAY_SCHEME_PREFIX_ATTR` for use later in the filter chain.

## 6.7 Websocket Routing Filter

The Websocket Routing Filter runs if the url located in the `ServerWebExchangeUtils.GATEWAY_REQUEST_URL_ATTR` exchange attribute has a `ws` or `wss` scheme. It uses the Spring Web Socket infrastructure to forward the Websocket request downstream.

Websockets may be load-balanced by prefixing the URI with `lb`, such as `lb:ws://serviceid`.

| ![[Note]](https://cloud.spring.io/spring-cloud-gateway/single/images/note.png) |
| ------------------------------------------------------------ |
| If you are using [SockJS](https://github.com/sockjs) as a fallback over normal http, you should configure a normal HTTP route as well as the Websocket Route. |

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      # SockJS route
      - id: websocket_sockjs_route
        uri: http://localhost:3001
        predicates:
        - Path=/websocket/info/**
      # Normwal Websocket route
      - id: websocket_route
        uri: ws://localhost:3001
        predicates:
        - Path=/websocket/**
```

## 6.8 Making An Exchange As Routed

After the Gateway has routed a `ServerWebExchange` it will mark that exchange as "routed" by adding `gatewayAlreadyRouted` to the exchange attributes. Once a request has been marked as routed, other routing filters will not route the request again, essentially skipping the filter. There are convenience methods that you can use to mark an exchange as routed or check if an exchange has already been routed.

- `ServerWebExchangeUtils.isAlreadyRouted` takes a `ServerWebExchange` object and checks if it has been "routed"
- `ServerWebExchangeUtils.setAlreadyRouted` takes a `ServerWebExchange` object and marks it as "routed"

# 7. Configuration

Configuration for Spring Cloud Gateway is driven by a collection of `RouteDefinitionLocator`s.

**RouteDefinitionLocator.java.** 

```java
public interface RouteDefinitionLocator {
	Flux<RouteDefinition> getRouteDefinitions();
}
```

By default, a `PropertiesRouteDefinitionLocator` loads properties using Spring Boot’s `@ConfigurationProperties` mechanism.

The configuration examples above all use a shortcut notation that uses positional arguments rather than named ones. The two examples below are equivalent:

**application.yml.** 

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: setstatus_route
        uri: http://example.org
        filters:
        - name: SetStatus
          args:
            status: 401
      - id: setstatusshortcut_route
        uri: http://example.org
        filters:
        - SetStatus=401
```

For some usages of the gateway, properties will be adequate, but some production use cases will benefit from loading configuration from an external source, such as a database. Future milestone versions will have `RouteDefinitionLocator` implementations based off of Spring Data Repositories such as: Redis, MongoDB and Cassandra.

## 7.1 Fluent Java Routes API

为了在 Java 中简便配置，我们使用了流式的定义，就是一直点点点（...）在`RouteLocatorBuilder` 中。

**GatewaySampleApplication.java.** 

```java
// static imports from GatewayFilters and RoutePredicates
@Bean
public RouteLocator customRouteLocator(RouteLocatorBuilder builder, ThrottleGatewayFilterFactory throttle) {
    return builder.routes()
        .route(r -> r.host("**.abc.org").and().path("/image/png")
               .filters(f ->
                        f.addResponseHeader("X-TestHeader", "foobar"))
               .uri("http://httpbin.org:80")
         	     )
        .route(r -> r.path("/image/webp")
               .filters(f ->
                        f.addResponseHeader("X-AnotherHeader", "baz"))
               .uri("http://httpbin.org:80")
              )
        .route(r -> r.order(-1)
               .host("**.throttle.org").and().path("/get")
               .filters(f -> f.filter(throttle.apply(1,
                                                     1,
                                                     10,
                                                     TimeUnit.SECONDS)))
               .uri("http://httpbin.org:80")
              )
        .build();
}
```

This style also allows for more custom predicate assertions. The predicates defined by `RouteDefinitionLocator` beans are combined using logical `and`. By using the fluent Java API, you can use the `and()`, `or()` and `negate()` operators on the `Predicate` class.

## 7.2 DiscoveryClient Route Definition Locator

The Gateway can be configured to create routes based on services registered with a `DiscoveryClient` compatible service registry.

To enable this, set `spring.cloud.gateway.discovery.locator.enabled=true` and make sure a `DiscoveryClient` implementation is on the classpath and enabled (such as Netflix Eureka, Consul or Zookeeper).

# 8. Actuator API

TODO: document the `/gateway` actuator endpoint

# 9. Developer Guide

TODO: overview of writing custom integrations

## 9.1 Writing Custom Route Predicate Factories

TODO: document writing Custom Route Predicate Factories

## 9.2 Writing Custom GatewayFilter Factories

为了实现网关过滤你应该实现 `GatewayFilterFactory`接口，同时也有一个 `AbstractGatewayFilterFactory` 抽象类可以继承。

**PreGatewayFilterFactory.java.** 

```java
public class PreGatewayFilterFactory extends AbstractGatewayFilterFactory<PreGatewayFilterFactory.Config> {

	public PreGatewayFilterFactory() {
		super(Config.class);
	}

	@Override
	public GatewayFilter apply(Config config) {
		// grab configuration from Config object
		return (exchange, chain) -> {
            //If you want to build a "pre" filter you need to manipulate the
            //request before calling change.filter
            ServerHttpRequest.Builder builder = exchange.getRequest().mutate();
            //use builder to manipulate the request
            return chain.filter(exchange.mutate().request(request).build());
		};
	}

	public static class Config {
        //Put the configuration properties for your filter here
	}

}
```

**PostGatewayFilterFactory.java.** 

```java
public class PostGatewayFilterFactory extends AbstractGatewayFilterFactory<PostGatewayFilterFactory.Config> {

	public PostGatewayFilterFactory() {
		super(Config.class);
	}

	@Override
	public GatewayFilter apply(Config config) {
		// grab configuration from Config object
		return (exchange, chain) -> {
			return chain.filter(exchange).then(Mono.fromRunnable(() -> {
				ServerHttpResponse response = exchange.getResponse();
				//Manipulate the response in some way
			}));
		};
	}

	public static class Config {
        //Put the configuration properties for your filter here
	}

}
```

## 9.3 Writing Custom Global Filters

TODO: document writing Custom Global Filters

## 9.4 Writing Custom Route Locators and Writers

TODO: document writing Custom Route Locators and Writers

# 10. Building a Simple Gateway Using Spring MVC or Webflux

Spring Cloud Gateway provides a utility object called `ProxyExchange` which you can use inside a regular Spring web handler as a method parameter. It supports basic downstream HTTP exchanges via methods that mirror the HTTP verbs. With MVC it also supports forwarding to a local handler via the `forward()` method. To use the `ProxyExchange` just include the right module in your classpath (either `spring-cloud-gateway-mvc` or `spring-cloud-gateway-webflux`).

MVC example (proxying a request to "/test" downstream to a remote server):

```java
@RestController
@SpringBootApplication
public class GatewaySampleApplication {

	@Value("${remote.home}")
	private URI home;

	@GetMapping("/test")
	public ResponseEntity<?> proxy(ProxyExchange<byte[]> proxy) throws Exception {
		return proxy.uri(home.toString() + "/image/png").get();
	}

}
```

The same thing with Webflux:

```java
@RestController
@SpringBootApplication
public class GatewaySampleApplication {

	@Value("${remote.home}")
	private URI home;

	@GetMapping("/test")
	public Mono<ResponseEntity<?>> proxy(ProxyExchange<byte[]> proxy) throws Exception {
		return proxy.uri(home.toString() + "/image/png").get();
	}

}
```

There are convenience methods on the `ProxyExchange` to enable the handler method to discover and enhance the URI path of the incoming request. For example you might want to extract the trailing elements of a path to pass them downstream:

```java
@GetMapping("/proxy/path/**")
public ResponseEntity<?> proxyPath(ProxyExchange<byte[]> proxy) throws Exception {
  String path = proxy.path("/proxy/path/");
  return proxy.uri(home.toString() + "/foos/" + path).get();
}
```

All the features of Spring MVC or Webflux are available to Gateway handler methods. So you can inject request headers and query parameters, for instance, and you can constrain the incoming requests with declarations in the mapping annotation. See the documentation for `@RequestMapping` in Spring MVC for more details of those features.

Headers can be added to the downstream response using the `header()` methods on `ProxyExchange`.

You can also manipulate response headers (and anything else you like in the response) by adding a mapper to the `get()` etc. method. The mapper is a `Function` that takes the incoming `ResponseEntity` and converts it to an outgoing one.

First class support is provided for "sensitive" headers ("cookie" and "authorization" by default) which are not passed downstream, and for "proxy" headers (`x-forwarded-*`).