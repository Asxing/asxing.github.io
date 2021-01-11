---
title: Spring-Cloud-Gateway-核心流程（三）
author: HoldDie
top: false
cover: false
toc: true
mathjax: true
tags:
  - Gateway
  - Spring-Cloud
date: 2021-01-11 14:56:59
img:
coverImg:
password:
summary:
categories: Spring
---

## 抓主线

![](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210111150814.png)

## 启动如何注入 DispatcherHandler ?

### 0. ReactorHttpHandlerAdapter

此处长话短说，在 Spring Webflux 启动的过程调用链如下：

```java
<init>:50, ReactorHttpHandlerAdapter (org.springframework.http.server.reactive)
getWebServer:71, NettyReactiveWebServerFactory (org.springframework.boot.web.embedded.netty)
<init>:49, WebServerManager (org.springframework.boot.web.reactive.context)
createWebServer:90, ReactiveWebServerApplicationContext (org.springframework.boot.web.reactive.context)
onRefresh:77, ReactiveWebServerApplicationContext (org.springframework.boot.web.reactive.context)
refresh:545, AbstractApplicationContext (org.springframework.context.support)
refresh:62, ReactiveWebServerApplicationContext (org.springframework.boot.web.reactive.context)
refresh:758, SpringApplication (org.springframework.boot)
refresh:750, SpringApplication (org.springframework.boot)
refreshContext:397, SpringApplication (org.springframework.boot)
run:315, SpringApplication (org.springframework.boot)
run:1237, SpringApplication (org.springframework.boot)
run:1226, SpringApplication (org.springframework.boot)
main:34, AwesomeGatewayApplication (com.holddie.gateway)
```

执行 ReactorHttpHandlerAdapter 的构造方法，注意此时 httpHandler 为空。

```java
public ReactorHttpHandlerAdapter(HttpHandler httpHandler) {
  Assert.notNull(httpHandler, "HttpHandler must not be null");
  this.httpHandler = httpHandler;
}
new WebServerManager.DelayedInitializationHttpHandler(handlerSupplier, lazyInit);
```

### 1. WebFluxConfigurationSupport

在这个类中声明了 DispatcherHandler 实例 Bean

```java
@Bean
public DispatcherHandler webHandler() {
  return new DispatcherHandler();
} 
```

### 2. DispatcherHandler

由于 DispatcherHandler 类本身实现了 ApplicationContextAware 接口，因此会执行 DispatcherHandler(ApplicationContext applicationContext) 方法，然后执行 initStrategies 方法。

```java
@Override
public void setApplicationContext(ApplicationContext applicationContext) {
  initStrategies(applicationContext);
}
​
protected void initStrategies(ApplicationContext context) {
  Map<String, HandlerMapping> mappingBeans = BeanFactoryUtils.beansOfTypeIncludingAncestors(
      context, HandlerMapping.class, true, false);
​
  ArrayList<HandlerMapping> mappings = new ArrayList<>(mappingBeans.values());
  AnnotationAwareOrderComparator.sort(mappings);
  this.handlerMappings = Collections.unmodifiableList(mappings);
​
  Map<String, HandlerAdapter> adapterBeans = BeanFactoryUtils.beansOfTypeIncludingAncestors(
      context, HandlerAdapter.class, true, false);
​
  this.handlerAdapters = new ArrayList<>(adapterBeans.values());
  AnnotationAwareOrderComparator.sort(this.handlerAdapters);
​
  Map<String, HandlerResultHandler> beans = BeanFactoryUtils.beansOfTypeIncludingAncestors(
      context, HandlerResultHandler.class, true, false);
​
  this.resultHandlers = new ArrayList<>(beans.values());
  AnnotationAwareOrderComparator.sort(this.resultHandlers);
}
```

这里一笔带过，我们可以看到有对应的 handleMapping、handleAdapter、resultHandlers 应该都很熟悉。

### 3. HttpHandlerAutoConfiguration

首先注意观察这个 configuration 的注解，声明只有在响应式下才会加载。

```java
@Configuration(
  proxyBeanMethods = false
)
@ConditionalOnClass({DispatcherHandler.class, HttpHandler.class})
@ConditionalOnWebApplication(
  type = Type.REACTIVE
)
@ConditionalOnMissingBean({HttpHandler.class})
@AutoConfigureAfter({WebFluxAutoConfiguration.class})
@AutoConfigureOrder(-2147483638)
public class HttpHandlerAutoConfiguration {
.....
​
@Bean
public HttpHandler httpHandler(ObjectProvider<WebFluxProperties> propsProvider) {
    // 这里使用构造器模式构造 httpHandler，注意 applicationContext 方法 和 build 方法.
    HttpHandler httpHandler = WebHttpHandlerBuilder.applicationContext(this.applicationContext).build();
    WebFluxProperties properties = (WebFluxProperties)propsProvider.getIfAvailable();
    if (properties != null && StringUtils.hasText(properties.getBasePath())) {
        Map<String, HttpHandler> handlersMap = Collections.singletonMap(properties.getBasePath(), httpHandler);
        return new ContextPathCompositeHandler(handlersMap);
    } else {
        return httpHandler;
    }
}
​
.....
}
```

### 4. WebHttpHandlerBuilder

```java
public static WebHttpHandlerBuilder applicationContext(ApplicationContext context) {
  WebHttpHandlerBuilder builder = new WebHttpHandlerBuilder(
      context.getBean(WEB_HANDLER_BEAN_NAME, WebHandler.class), context);
.....
}
​
private WebHttpHandlerBuilder(WebHandler webHandler, @Nullable ApplicationContext applicationContext) {
  Assert.notNull(webHandler, "WebHandler must not be null");
  this.webHandler = webHandler;
  this.applicationContext = applicationContext;
}
```

此处的`context.getBean(WEB_HANDLER_BEAN_NAME, WebHandler.class)`获取的就是前边声明的 DispatcherHandler Bean，然后赋值给`this.webHandler`为`build`方法使用方便。

```java
public HttpHandler build() {
    WebHandler decorated = new FilteringWebHandler(this.webHandler, this.filters);
    decorated = new ExceptionHandlingWebHandler(decorated,  this.exceptionHandlers);
​
    HttpWebHandlerAdapter adapted = new HttpWebHandlerAdapter(decorated);
......
}
```

执行 build 方法，这里使用装饰器模式，将不同类型的`WebHandler`一层层包装起来。此处需要额外留意一下`FilteringWebHandler`，这个为之后的执行`DispatcherHandler`的`handle`方法铺垫。

## 如何调用到 DispatcherHandler 的 handle 方法?

### FilteringWebHandler

按照上述流程加载完毕之后，当有一个请求打过来之后，使用 ReactorHttpHandlerAdapter 处理请求，请求堆栈如下：

```java
filter:119, DefaultWebFilterChain (org.springframework.web.server.handler)
handle:59, FilteringWebHandler (org.springframework.web.server.handler)
handle:56, WebHandlerDecorator (org.springframework.web.server.handler)
handle:70, ExceptionHandlingWebHandler (org.springframework.web.server.handler)
handle:235, HttpWebHandlerAdapter (org.springframework.web.server.adapter)
handle:97, WebServerManager$DelayedInitializationHttpHandler (org.springframework.boot.web.reactive.context)
apply:65, ReactorHttpHandlerAdapter (org.springframework.http.server.reactive)
apply:40, ReactorHttpHandlerAdapter (org.springframework.http.server.reactive)
onStateChange:64, HttpServerHandle (reactor.netty.http.server)
onStateChange:514, ReactorNetty$CompositeConnectionObserver (reactor.netty)
onStateChange:267, TcpServerBind$ChildObserver (reactor.netty.tcp)
onInboundNext:462, HttpServerOperations (reactor.netty.http.server)
channelRead:96, ChannelOperationsHandler (reactor.netty.channel)
invokeChannelRead:379, AbstractChannelHandlerContext (io.netty.channel)
invokeChannelRead:365, AbstractChannelHandlerContext (io.netty.channel)
fireChannelRead:357, AbstractChannelHandlerContext (io.netty.channel)
channelRead:170, HttpTrafficHandler (reactor.netty.http.server)
invokeChannelRead:379, AbstractChannelHandlerContext (io.netty.channel)
invokeChannelRead:365, AbstractChannelHandlerContext (io.netty.channel)
fireChannelRead:357, AbstractChannelHandlerContext (io.netty.channel)
fireChannelRead:436, CombinedChannelDuplexHandler$DelegatingChannelHandlerContext (io.netty.channel)
fireChannelRead:324, ByteToMessageDecoder (io.netty.handler.codec)
channelRead:296, ByteToMessageDecoder (io.netty.handler.codec)
channelRead:251, CombinedChannelDuplexHandler (io.netty.channel)
invokeChannelRead:379, AbstractChannelHandlerContext (io.netty.channel)
invokeChannelRead:365, AbstractChannelHandlerContext (io.netty.channel)
fireChannelRead:357, AbstractChannelHandlerContext (io.netty.channel)
channelRead:1410, DefaultChannelPipeline$HeadContext (io.netty.channel)
invokeChannelRead:379, AbstractChannelHandlerContext (io.netty.channel)
invokeChannelRead:365, AbstractChannelHandlerContext (io.netty.channel)
fireChannelRead:919, DefaultChannelPipeline (io.netty.channel)
read:163, AbstractNioByteChannel$NioByteUnsafe (io.netty.channel.nio)
processSelectedKey:714, NioEventLoop (io.netty.channel.nio)
processSelectedKeysOptimized:650, NioEventLoop (io.netty.channel.nio)
processSelectedKeys:576, NioEventLoop (io.netty.channel.nio)
run:493, NioEventLoop (io.netty.channel.nio)
run:989, SingleThreadEventExecutor$4 (io.netty.util.concurrent)
run:74, ThreadExecutorMap$2 (io.netty.util.internal)
run:30, FastThreadLocalRunnable (io.netty.util.concurrent)
run:748, Thread (java.lang)
```

对应`FilteringWebHandler`代码上

```java
public Mono<Void> filter(ServerWebExchange exchange) {
  return Mono.defer(() ->
      this.currentFilter != null && this.chain != null ?
          invokeFilter(this.currentFilter, this.chain, exchange) :
          this.handler.handle(exchange));
}
```

此处的 this.handler.handle(exchange) 方法中的 handler 就是最开始在 build 方法里面装饰器模式包装的 DispatcherHandler ，之后就会调用 DispatcherHandler 的 handle 方法。