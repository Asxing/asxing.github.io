---
title: Spring-Cloud-Gateway-流程细节（四）
author: HoldDie
top: false
cover: false
toc: true
mathjax: true
tags:
  - Gateway
  - Spring-Cloud-Gateway
date: 2021-01-11 14:59:19
img:
coverImg:
password:
summary:
categories: Spring
---

## 1. 思考题

* 如何从 DispatcherHandler 匹配对应的 HandlerMapping？如何从 HandlerMapping 匹配 Route？
* FilteringWebHandler 创建 GatewayFilterChain 处理请求？如何从 HandlerMapping 匹配 Route？
* 如何调用到 FilteringWebHandler 的 handler 方法？
* FilteringWebHandler 创建 GatewayFilterChain 处理请求？
## 2. 简单流程

书接上回:

### 2.1. DispatcherHandler#handle

```java
@Override
	public Mono<Void> handle(ServerWebExchange exchange) {
	   // 对于 handlerMapping 判空 
		if (this.handlerMappings == null) {
			return createNotFoundError();
		}
		return Flux.fromIterable(this.handlerMappings)
				.concatMap(mapping -> mapping.getHandler(exchange))
				.next()
				.switchIfEmpty(createNotFoundError())
				.flatMap(handler -> invokeHandler(exchange, handler))
				.flatMap(result -> handleResult(exchange, result));
	}
```
### 2.2. handlerMappings 详情

此时 handlerMappings 里面有什么内容以及分别有什么作用!

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111150120.png)

其中包括了

* WebFluxEndpointHandlerMapping：使用 Spring WebFlux 使 Web 终结点在 HTTP 上可用的自定义处理程序映射。
* ControllerEndpointHandlerMapping：匹配 @ControllerEndpoint 和 @RestControllerEndpoint
* RouterFunctionMapping：匹配WebFlux的router functions；
* RequestMappingHandlerMapping：匹配 @RequestMapping 标注；
* RoutePredicateHandlerMapping：匹配Gateway中路由断言的集合；
* SimpleUrlHandlerMapping：匹配静态资源；

注意`concatMap(mapping -> mapping.getHandler(exchange))`对于这个语句的理解，是对应的 6 个 handlerMapping 都执行一遍自己的`getHandlerInternal`方法。

### 2.3. AbstractHandlerMapping#getHandler 方法

```java
@Override
public Mono<Object> getHandler(ServerWebExchange exchange) {
   return getHandlerInternal(exchange).map(handler -> {
      if (logger.isDebugEnabled()) {
         logger.debug(exchange.getLogPrefix() + "Mapped to " + handler);
      }
      ServerHttpRequest request = exchange.getRequest();
      if (hasCorsConfigurationSource(handler) || CorsUtils.isPreFlightRequest(request)) {
         CorsConfiguration config = (this.corsConfigurationSource != null ? this.corsConfigurationSource.getCorsConfiguration(exchange) : null);
         CorsConfiguration handlerConfig = getCorsConfiguration(handler, exchange);
         config = (config != null ? config.combine(handlerConfig) : handlerConfig);
         if (!this.corsProcessor.process(config, exchange) || CorsUtils.isPreFlightRequest(request)) {
            return REQUEST_HANDLED_HANDLER;
         }
      }
      return handler;
   });
}
```
其中对于 RoutePredicateHandlerMapping 来说，在执行`getHandlerInternal(exchange)`这一步的时候，调用实际自己的实现，然后最终把`RoutePredicateHandlerMapping`返回的 handler 处理之后继续往上返回。
### 2.4.  RoutePredicateHandlerMapping#getHandlerInternal

```java
@Override
protected Mono<?> getHandlerInternal(ServerWebExchange exchange) {
   logger.info(" -> RoutePredicateHandlerMapping#getHandlerInternal");
   // don't handle requests on management port if set and different than server port
   if (this.managementPortType == DIFFERENT && this.managementPort != null
         && exchange.getRequest().getURI().getPort() == this.managementPort) {
      return Mono.empty();
   }
   logger.info("设置当前处理使用的 GATEWAY_HANDLER_MAPPER_ATTR 是 RoutePredicateHandlerMapping "
         + "-> RoutePredicateHandlerMapping#getHandlerInternal");
   exchange.getAttributes().put(GATEWAY_HANDLER_MAPPER_ATTR, getSimpleName());
   Mono<Route> routeMono = lookupRoute(exchange);
   logger.info("当前匹配的 Route 是：" + routeMono + " -> RoutePredicateHandlerMapping#getHandlerInternal");
   return routeMono
         .log("route-predicate-handler-mapping", Level.FINER) //name this
         .flatMap((Function<Route, Mono<?>>) r -> {
            logger.info("移除当前缓存的 GATEWAY_PREDICATE_ROUTE_ATTR : " + exchange.getAttributes()
                  .get(GATEWAY_PREDICATE_ROUTE_ATTR) + " -> RoutePredicateHandlerMapping#getHandlerInternal");
            exchange.getAttributes().remove(GATEWAY_PREDICATE_ROUTE_ATTR);
            if (logger.isDebugEnabled()) {
               logger.debug(
                     "Mapping [" + getExchangeDesc(exchange) + "] to " + r);
            }
            logger.info("设置当前正在使用的 GATEWAY_ROUTE_ATTR 为：" + r +
                  " -> RoutePredicateHandlerMapping#getHandlerInternal");
            exchange.getAttributes().put(GATEWAY_ROUTE_ATTR, r);
						// 在此处返回了对应的 webHandler，此处特指的是 FilteringWebHandler.
            return Mono.just(webHandler);
         }).switchIfEmpty(Mono.empty().then(Mono.fromRunnable(() -> {
            logger.info("未找到合适的 Route，清理历史 Route 上下文，返回空 -> "
                  + "RoutePredicateHandlerMapping#getHandlerInternal");
            exchange.getAttributes().remove(GATEWAY_PREDICATE_ROUTE_ATTR);
            if (logger.isTraceEnabled()) {
               logger.trace("No RouteDefinition found for ["
                     + getExchangeDesc(exchange) + "]");
            }
         })));
}
```
此处根据谓词规则匹配对应的 Route，然后`exchange.getAttributes().put(GATEWAY_ROUTE_ATTR, r);`把对应的 Route 加载到上下文中，之后返回 FilteringWebHandler。
### 2.5. DispatcherHandler#invokeHandler 执行细节

```java
private Mono<HandlerResult> invokeHandler(ServerWebExchange exchange, Object handler) {
   if (this.handlerAdapters != null) {
      for (HandlerAdapter handlerAdapter : this.handlerAdapters) {
         if (handlerAdapter.supports(handler)) {
            return handlerAdapter.handle(exchange, handler);
         }
      }
   }
   return Mono.error(new IllegalStateException("No HandlerAdapter: " + handler));
}
```
走到这一步，我们逻辑实现，显示判断是否有对应的 handlerAdapter 处理器，然后对应的 handlerAdapter 是否支持处理 FilteringWebHandler。执行断点我们观察如下，`this.handlerAdapter`包含：
* RequestMappingHandlerAdapter：支持处理 @RequestMapping 方法
* HandlerFunctionAdapter：支持处理 HandlerFuncitons
* SimpleHandlerAdapter：处理普通 Web 处理程序与通用调度器处理程序
### 2.6.  不同 HandlerAdapter 的 support 方法

**RequestMappingHandlerAdapter，是否属于 HandlerMethod**

```java
@Override
public boolean supports(Object handler) {
   return handler instanceof HandlerMethod;
}
```
**HandlerFunctionAdapter，是否属于 HandlerFunction**
```java
@Override
public boolean supports(Object handler) {
   return handler instanceof HandlerFunction;
}
```
**SimpleHandlerAdapter，是否属于 WebHandler**
```java
@Override
public boolean supports(Object handler) {
   return WebHandler.class.isAssignableFrom(handler.getClass());
}
```
根据上述代码，我们已经很清楚了返回的 FilteringWebHandler 当然属于 WebHandler，所以会调用 SimpleHandlerAdapter 的 handle 方法。
### 2.7. SimpleHandlerAdapter#handle

```java
public class SimpleHandlerAdapter implements HandlerAdapter {
 ...
   @Override
   public Mono<HandlerResult> handle(ServerWebExchange exchange, Object handler) {
      WebHandler webHandler = (WebHandler) handler;
      Mono<Void> mono = webHandler.handle(exchange); //①
      return mono.then(Mono.empty());
   }
}
```
周周转转，发现又回到了`webHandler.handle(exchange)`方法，也就是我们`FilteringWebHandler`的`handle`方法。
### 2.8. FilteringWebHandler#handle

```java
@Override
public Mono<Void> handle(ServerWebExchange exchange) {
   logger.info("DispatcherHandler#invokeHandler -> handlerAdapter.handle(exchange, handler); \\n "
         + "执行到 FilteringWebHandler -> FilteringWebHandler#handle");
   Route route = exchange.getRequiredAttribute(GATEWAY_ROUTE_ATTR);
   List<GatewayFilter> gatewayFilters = route.getFilters();
   List<GatewayFilter> combined = new ArrayList<>(this.globalFilters);
   combined.addAll(gatewayFilters);
   logger.info("对 Filter 进行排序 -> FilteringWebHandler#handle");
   AnnotationAwareOrderComparator.sort(combined);
   if (logger.isDebugEnabled()) {
      logger.debug("Sorted gatewayFilterFactories: " + combined);
   }
   logger.info("创建默认的 DefaultGatewayFilterChain -> FilteringWebHandler#handle");
   return new DefaultGatewayFilterChain(combined).filter(exchange);
}
```
通过程序我们可以看到，
* 首先获取在`DispatcherHandler`的`getHandlerInternal`中设置到上下文的 Route；
* 其次获取`Route`下面所有的`filter`，把当前`Route`的`filter`和`Global filter`合并；
* 然后对所有的`filter`进行排序；
* 最后创建`DefaultGatewayFilterChain`，使用责任链模式，链式调用。
3. Reactor 基础知识

[https://mubu.com/doc/1qwRixFnbHv](https://mubu.com/doc/1qwRixFnbHv)![图片](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111150049.png!thumbnail)