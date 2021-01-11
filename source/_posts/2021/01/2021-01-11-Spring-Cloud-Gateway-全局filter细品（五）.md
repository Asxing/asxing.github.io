---
title: Spring-Cloud-Gateway-全局filter细品（五）
author: HoldDie
top: false
cover: false
toc: true
mathjax: true
tags:
  - 网关
  - Spring-Cloud-Gateway
date: 2021-01-11 15:02:39
img:
coverImg:
password:
summary:
categories: Spring
---

## 目标

* 温故 Java8 常见函数式用法
* 再过一下 lookupRoute 方法
* 过一遍 9 默认全局 Filter

## Java 8 常见函数式用法

### Consumer 表达式

一个消费型的接口，通过传入参数，然后输出值，无返回值。接连两个`consumer`有相同的入参可以使用`addThen`将两个方法链接起来，然后一起`accept`方法接受入参。

```java
Consumer<Integer> add2consumer = x -> {
  int a = x + 2;
  System.out.println(a);
};
Consumer<Integer> add4consumer = x -> {
  int a = x + 4;
  System.out.println(a);
};
add2consumer.andThen(add4consumer).accept(10);
​
//① 使用consumer接口实现方法
Consumer<String> consumer = new Consumer<String>() {
  @Override
  public void accept(String s) {
    System.out.println(s);
  }
};
Stream<String> stream = Stream.of("aaa", "bbb", "ddd", "ccc", "fff");
stream.forEach(consumer);
System.out.println("********************");
​
//② 使用lambda表达式，forEach方法需要的就是一个Consumer接口
stream = Stream.of("aaa", "bbb", "ddd", "ccc", "fff");
Consumer<String> consumer1 = (s) -> System.out.println(s);//lambda表达式返回的就是一个Consumer接口
stream.forEach(consumer1);
//更直接的方式
//stream.forEach((s) -> System.out.println(s));
System.out.println("********************");
​
//③ 使用方法引用，方法引用也是一个consumer
stream = Stream.of("aaa", "bbb", "ddd", "ccc", "fff");
Consumer consumer2 = System.out::println;
stream.forEach(consumer2);
```

### Supplier 表达式

一个供给型的接口，可以用来存储数据，然后可以供其他方法使用的这么一个接口。

```java
//① 使用Supplier接口实现方法,只有一个get方法，无参数，返回一个值
Supplier<Integer> supplier = new Supplier<Integer>() {
  @Override
  public Integer get() {
    //返回一个随机值
    return new Random().nextInt();
  }
};
​
System.out.println(supplier.get());
System.out.println("********************");
​
//② 使用lambda表达式，
supplier = () -> new Random().nextInt();
System.out.println(supplier.get());
System.out.println("********************");
​
//③ 使用方法引用
Supplier<Double> supplier2 = Math::random;
System.out.println(supplier2.get());
​
// 高阶用法
Stream<Integer> stream = Stream.of(1, 2, 3, 4, 5);
//返回一个optional对象
Optional<Integer> first = stream.filter(i -> i > 4)
  .findFirst();
​
//optional对象有需要Supplier接口的方法
//orElse，如果first中存在数，就返回这个数，如果不存在，就放回传入的数
System.out.println(first.orElse(1));
System.out.println(first.orElse(7));
​
System.out.println("********************");
​
Supplier<Integer> integerSupplier = new Supplier<Integer>() {
  @Override
  public Integer get() {
    //返回一个随机值
    return new Random().nextInt();
  }
};
​
//orElseGet，如果first中存在数，就返回这个数，如果不存在，就返回supplier返回的值
System.out.println(first.orElseGet(integerSupplier));
```

### Function 表达式

一个功能型接口，它的一个作用就是转换作用，将输入数据转换成另一种形式的输出数据。

```java
//① 使用map方法，泛型的第一个参数是转换前的类型，第二个是转化后的类型
Function<String, Integer> function = new Function<String, Integer>() {
  @Override
  public Integer apply(String s) {
    return s.length();//获取每个字符串的长度，并且返回
  }
};
​
Stream<String> stream = Stream.of("aaa", "bbbbb", "ccccccv");
Stream<Integer> stream1 = stream.map(function);
stream1.forEach(System.out::println);
System.out.println("********************");
```

### Predicate 表达式

谓词型接口，其实，这个就是一个类似于 bool 类型的判断的接口。

```java
//① 使用Predicate接口实现方法,只有一个test方法，传入一个参数，返回一个bool值
Predicate<Integer> predicate = new Predicate<Integer>() {
  @Override
  public boolean test(Integer integer) {
    if (integer > 5) {
      return true;
    }
    return false;
  }
};
System.out.println(predicate.test(6));
System.out.println("********************");
​
//② 使用lambda表达式，
predicate = (t) -> t > 5;
System.out.println(predicate.test(1));
System.out.println("********************");
```

### 需要时查看

列举下java8中 java.util.function包下，内置所有的接口简介和表达的意思

1 BiConsumer<T,U>：代表了一个接受两个输入参数的操作，并且不返回任何结果

2 BiFunction<T,U,R>：代表了一个接受两个输入参数的方法，并且返回一个结果

3 BinaryOperator<T>：代表了一个作用于于两个同类型操作符的操作，并且返回了操作符同类型的结果

4 BiPredicate<T,U>：代表了一个两个参数的boolean值方法

5 BooleanSupplier：代表了boolean值结果的提供方

6 Consumer<T>：代表了接受一个输入参数并且无返回的操作

7 DoubleBinaryOperator：代表了作用于两个double值操作符的操作，并且返回了一个double值的结果。

8 DoubleConsumer：代表一个接受double值参数的操作，并且不返回结果。

9 DoubleFunction<R>：代表接受一个double值参数的方法，并且返回结果

10 DoublePredicate：代表一个拥有double值参数的boolean值方法

11 DoubleSupplier：代表一个double值结构的提供方

12 DoubleToIntFunction：接受一个double类型输入，返回一个int类型结果。

13 DoubleToLongFunction：接受一个double类型输入，返回一个long类型结果

14 DoubleUnaryOperator：接受一个参数同为类型double,返回值类型也为double 。

15 Function<T,R>：接受一个输入参数，返回一个结果。

16 IntBinaryOperator：接受两个参数同为类型int,返回值类型也为int 。

17 IntConsumer：接受一个int类型的输入参数，无返回值 。

18 IntFunction<R>：接受一个int类型输入参数，返回一个结果 。

19 IntPredicate：接受一个int输入参数，返回一个布尔值的结果。

20 IntSupplier：无参数，返回一个int类型结果。

21 IntToDoubleFunction：接受一个int类型输入，返回一个double类型结果 。

22 IntToLongFunction：接受一个int类型输入，返回一个long类型结果。

23 IntUnaryOperator：接受一个参数同为类型int,返回值类型也为int 。

24 LongBinaryOperator：接受两个参数同为类型long,返回值类型也为long。

25 LongConsumer：接受一个long类型的输入参数，无返回值。

26 LongFunction<R>：接受一个long类型输入参数，返回一个结果。

27 LongPredicate：R接受一个long输入参数，返回一个布尔值类型结果。

28 LongSupplier：无参数，返回一个结果long类型的值。

29 LongToDoubleFunction：接受一个long类型输入，返回一个double类型结果。

30 LongToIntFunction：接受一个long类型输入，返回一个int类型结果。

31 LongUnaryOperator：接受一个参数同为类型long,返回值类型也为long。

32 ObjDoubleConsumer<T>：接受一个object类型和一个double类型的输入参数，无返回值。

33 ObjIntConsumer<T>：接受一个object类型和一个int类型的输入参数，无返回值。

34 ObjLongConsumer<T>：接受一个object类型和一个long类型的输入参数，无返回值。

35 Predicate<T>：接受一个输入参数，返回一个布尔值结果。

36 Supplier<T>：无参数，返回一个结果。

37 ToDoubleBiFunction<T,U>：接受两个输入参数，返回一个double类型结果

38 ToDoubleFunction<T>：接受一个输入参数，返回一个double类型结果

39 ToIntBiFunction<T,U>：接受两个输入参数，返回一个int类型结果。

40 ToIntFunction<T>：接受一个输入参数，返回一个int类型结果。

41 ToLongBiFunction<T,U>：接受两个输入参数，返回一个long类型结果。

42 ToLongFunction<T>：接受一个输入参数，返回一个long类型结果。

43 UnaryOperator<T>：接受一个参数为类型T,返回值类型也为T。

## lookupRoute 方法如何调用？

```java
protected Mono<Route> lookupRoute(ServerWebExchange exchange) {
  logger.info("lookupRoute 开始匹配 Route 贼关键 -> RoutePredicateHandlerMapping#lookupRoute");
  return this.routeLocator.getRoutes()
    // 单独处理，以便在出现错误的时候，返回空
    .concatMap(route ->
               Mono.just(route)
               .filterWhen(r -> {
                 logger.info("设置当前执行的 routeId GATEWAY_PREDICATE_ROUTE_ATTR: " +
                             r.getId() + " -> RoutePredicateHandlerMapping#lookupRoute");
                 exchange.getAttributes().put(GATEWAY_PREDICATE_ROUTE_ATTR, r.getId());
                 return r.getPredicate().apply(exchange);
               })
               .doOnError(e -> logger.error(
                 "Error applying predicate for route: " + route.getId(),
                 e))
               .onErrorResume(e -> Mono.empty()))
    .next()
    .map(route -> {
      if (logger.isDebugEnabled()) {
        logger.debug("Route matched: " + route.getId());
      }
      logger.info("校验 Route 的有效性 -> RoutePredicateHandlerMapping#lookupRoute");
      validateRoute(route, exchange);
      return route;
    });
}
```

从方法名我们可以得知，这个方法就是要找出符合规则的 Route。在实际的调用过程中，方法是先返回一个 Mono 空对象，之后自己执行`r.getPredicate().apply(exchange)`使用每个`Route`的谓词规则过滤，返回匹配 Route。

```java
public class Route implements Ordered {
  ...
  // route 的 getPredicate 方法返回 AsyncPredicate 类型
  public AsyncPredicate<ServerWebExchange> getPredicate() {
    return this.predicate;
  }
}
```

route 的 getPredicate 方法返回 AsyncPredicate 类型

```java
class DefaultAsyncPredicate<T> implements AsyncPredicate<T> {
​
  private final Predicate<T> delegate;
​
  public DefaultAsyncPredicate(Predicate<T> delegate) {
    this.delegate = delegate;
  }
​
  @Override
  public Publisher<Boolean> apply(T t) {
    return Mono.just(delegate.test(t));
  }
  ...
}
```

然后执行`Predicate`的`test`方法返回一个`boolean`值，来满足`filterWhen`方法，返回对应 Route。

## 9 个默认全局 Filter

访问对应`http://localhost:8080/actuator/gateway/globalfilters`地址，我们可以看到所有 GlobalFilter 以及对应的`Order`顺序。

```json
{
  "org.springframework.cloud.gateway.filter.RemoveCachedBodyFilter@ffaaaf0": -2147483648,
  "org.springframework.cloud.gateway.filter.AdaptCachedBodyGlobalFilter@537c8c7e": -2147482648,
  "org.springframework.cloud.gateway.filter.NettyWriteResponseFilter@2459319c": -1,
  "org.springframework.cloud.gateway.filter.ForwardPathFilter@33d53216": 0,
  "org.springframework.cloud.gateway.filter.GatewayMetricsFilter@4f3e7344": 0,
  "org.springframework.cloud.gateway.filter.RouteToRequestUrlFilter@1dc76fa1": 10000,
  "org.springframework.cloud.gateway.filter.WebsocketRoutingFilter@69a2b3b6": 2147483646,
  "org.springframework.cloud.gateway.filter.NettyRoutingFilter@3681037": 2147483647,
  "org.springframework.cloud.gateway.filter.ForwardRoutingFilter@5eed2d86": 2147483647,
}
```

### RemoveCachedBodyFilter

```java
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
  return chain.filter(exchange).doFinally(s -> {
    log.info("执行到 RemoveCachedBodyFilter#filter ");
    // 移除上下文中 cachedRequestBody 属性
    Object attribute = exchange.getAttributes().remove(CACHED_REQUEST_BODY_ATTR);
    // PooledDataBuffer 是 DataBuffer 的扩展，允许共享一块内存共享池 
    if (attribute != null && attribute instanceof PooledDataBuffer) {
      PooledDataBuffer dataBuffer = (PooledDataBuffer) attribute;
      // 如果还有占用，则释放
      if (dataBuffer.isAllocated()) {
        if (log.isTraceEnabled()) {
          log.trace("releasing cached body in exchange attribute");
        }
        dataBuffer.release();
      }
    }
  });
}
```

### AdaptCachedBodyGlobalFilter

```java
@Override
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
  logger.info("执行到 AdaptCachedBodyGlobalFilter#filter");
  ServerHttpRequest cachedRequest = exchange
    .getAttributeOrDefault(CACHED_SERVER_HTTP_REQUEST_DECORATOR_ATTR, null);
  if (cachedRequest != null) {
    exchange.getAttributes().remove(CACHED_SERVER_HTTP_REQUEST_DECORATOR_ATTR);
    // 如果不为空，直接使用 DefaultServerWebExchangeBuilder 构建一个，并将 cachedRequest 加入到其中
    return chain.filter(exchange.mutate().request(cachedRequest).build());
  }
​
  DataBuffer body = exchange.getAttributeOrDefault(CACHED_REQUEST_BODY_ATTR, null);
  Route route = exchange.getAttribute(GATEWAY_ROUTE_ATTR);
​
  // 如果上下文中，没有 cachedRequestBody 缓存，并且本地方法中没有缓存过改 Route 则继续
  if (body != null || !this.routesToCache.containsKey(route.getId())) {
    return chain.filter(exchange);
  }
​
  return ServerWebExchangeUtils.cacheRequestBody(exchange, (serverHttpRequest) -> {
    // 如果是相同的则不 build 了
    if (serverHttpRequest == exchange.getRequest()) {
      return chain.filter(exchange);
    }
    return chain.filter(exchange.mutate().request(serverHttpRequest).build());
  });
}
```

### NettyWriteResponseFilter

```java
@Override
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
  log.info("执行到 NettyWriteResponseFilter#filter");
  // NOTICE: nothing in "pre" filter stage as CLIENT_RESPONSE_CONN_ATTR is not added
  // until the NettyRoutingFilter is run
  // @formatter:off
  return chain.filter(exchange)
    .doOnError(throwable -> cleanup(exchange))
    .then(Mono.defer(() -> {
      // 获取 gatewayClientResponseConnection 连接
      Connection connection = exchange.getAttribute(CLIENT_RESPONSE_CONN_ATTR);
​
      if (connection == null) {
        return Mono.empty();
      }
      if (log.isTraceEnabled()) {
        log.trace("NettyWriteResponseFilter start inbound: "
                  + connection.channel().id().asShortText() + ", outbound: "
                  + exchange.getLogPrefix());
      }
      ServerHttpResponse response = exchange.getResponse();
      
      final Flux<DataBuffer> body = connection
        .inbound()
        .receive()
        .retain()
        // byteBuf -> DataBuffer, netty 数据结构到 spring 数据结构 
        .map(byteBuf -> wrap(byteBuf, response));
​
      MediaType contentType = null;
      try {
        contentType = response.getHeaders().getContentType();
      }
      catch (Exception e) {
        if (log.isTraceEnabled()) {
          log.trace("invalid media type", e);
        }
      }
      // 根据不同类型，是否直接刷盘发送
      return (isStreamingMediaType(contentType)
              ? response.writeAndFlushWith(body.map(Flux::just))
              : response.writeWith(body));
    })).doOnCancel(() -> cleanup(exchange));
  // @formatter:on
}
```

### ForwardPathFilter

```java
@Override
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
  logger.info("执行到 ForwardPathFilter#filter");
  Route route = exchange.getAttribute(GATEWAY_ROUTE_ATTR);
  URI routeUri = route.getUri();
  String scheme = routeUri.getScheme();
  // 是否已经转发过(gatewayAlreadyRouted) 或 没有包含 forward 关键字
  if (isAlreadyRouted(exchange) || !"forward".equals(scheme)) {
    return chain.filter(exchange);
  }
  exchange = exchange.mutate()
    .request(exchange.getRequest().mutate().path(routeUri.getPath()).build())
    .build();
  return chain.filter(exchange);
}
```

### GatewayMetricsFilter

```java
@Override
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
  log.info("执行到 GatewayMetricsFilter#filter");
  Sample sample = Timer.start(meterRegistry);
  // 添加对于成功或异常调用的方法
  return chain.filter(exchange)
    .doOnSuccess(aVoid -> endTimerRespectingCommit(exchange, sample))
    .doOnError(throwable -> endTimerRespectingCommit(exchange, sample));
}
​
private void endTimerRespectingCommit(ServerWebExchange exchange, Sample sample) {
  ServerHttpResponse response = exchange.getResponse();
  if (response.isCommitted()) {
    endTimerInner(exchange, sample);
  }
  else {
    response.beforeCommit(() -> {
      endTimerInner(exchange, sample);
      return Mono.empty();
    });
  }
}
```

### RouteToRequestUrlFilter

```java
@Override
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
  log.info("执行到 RouteToRequestUrlFilter#filter");
  Route route = exchange.getAttribute(GATEWAY_ROUTE_ATTR);
  if (route == null) {
    return chain.filter(exchange);
  }
  log.trace("RouteToRequestUrlFilter start");
  URI uri = exchange.getRequest().getURI();
  boolean encoded = containsEncodedParts(uri);
  URI routeUri = route.getUri();
​
  if (hasAnotherScheme(routeUri)) {
    // 设置相应的 schema
    exchange.getAttributes().put(GATEWAY_SCHEME_PREFIX_ATTR, routeUri.getScheme());
    routeUri = URI.create(routeUri.getSchemeSpecificPart());
  }
​
  // 对于 loadbalance 的判断
  if ("lb".equalsIgnoreCase(routeUri.getScheme()) && routeUri.getHost() == null) {
    throw new IllegalStateException("Invalid host: " + routeUri.toString());
  }
​
  URI mergedUrl = UriComponentsBuilder.fromUri(uri)
    // .uri(routeUri)
    .scheme(routeUri.getScheme()).host(routeUri.getHost())
    .port(routeUri.getPort()).build(encoded).toUri();
  exchange.getAttributes().put(GATEWAY_REQUEST_URL_ATTR, mergedUrl);
  return chain.filter(exchange);
}
```

### WebsocketRoutingFilter

```java
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
  log.info("执行到 -> WebsocketRoutingFilter#filter");
  // 如果是 ws 则修改 gatewayRequestUrl, 这个参数在 RouteToRequestUrlFilter 中设置
  changeSchemeIfIsWebSocketUpgrade(exchange);
  // 然后获取上一步设置好的 gatewayRequestUrl 值
  URI requestUrl = exchange.getRequiredAttribute(GATEWAY_REQUEST_URL_ATTR);
  String scheme = requestUrl.getScheme();
​
  // 如果已经 gatewayAlreadyRouted 已经为 true 或者 scheme 不是 ws 或 wss 则略过
  if (isAlreadyRouted(exchange)
      || (!"ws".equals(scheme) && !"wss".equals(scheme))) {
    return chain.filter(exchange);
  }
  setAlreadyRouted(exchange);
​
  HttpHeaders headers = exchange.getRequest().getHeaders();
  HttpHeaders filtered = filterRequest(getHeadersFilters(), exchange);
​
  List<String> protocols = headers.get(SEC_WEBSOCKET_PROTOCOL);
  if (protocols != null) {
    protocols = headers.get(SEC_WEBSOCKET_PROTOCOL).stream().flatMap(
      header -> Arrays.stream(commaDelimitedListToStringArray(header)))
      .map(String::trim).collect(Collectors.toList());
  }
​
  return this.webSocketService.handleRequest(exchange, new ProxyWebSocketHandler(
    requestUrl, this.webSocketClient, filtered, protocols));
}
```

### NettyRoutingFilter

```java
@Override
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
  URI requestUrl = exchange.getRequiredAttribute(GATEWAY_REQUEST_URL_ATTR);
​
  String scheme = requestUrl.getScheme();
  if (isAlreadyRouted(exchange)
      || (!"http".equals(scheme) && !"https".equals(scheme))) {
    return chain.filter(exchange);
  }
  setAlreadyRouted(exchange);
​
  ServerHttpRequest request = exchange.getRequest();
​
  HttpMethod method = request.getMethod();
​
  HttpHeaders filteredHeaders = filterRequest(getHeadersFilters(), exchange);
​
  // 判断是否 保留主机标头属性名称
  boolean preserveHost = exchange
    .getAttributeOrDefault(PRESERVE_HOST_HEADER_ATTRIBUTE, false);
​
​
  /*
    * 在 GatewayAutoConfiguration 中有如下一块注释，说我们可以自定义 WebClient 来覆盖 netty
    * @Bean //TODO: default over netty? configurable public WebClientHttpRoutingFilter
    * webClientHttpRoutingFilter() { //TODO: WebClient bean return new
    * WebClientHttpRoutingFilter(WebClient.routes().build()); }
    *
    * @Bean public WebClientWriteResponseFilter webClientWriteResponseFilter() { return
    * new WebClientWriteResponseFilter(); }
    */
  // 使用 webClient 
  RequestBodySpec bodySpec = this.webClient.method(method).uri(requestUrl)
    .headers(httpHeaders -> {
      httpHeaders.addAll(filteredHeaders);
      // TODO: can this support preserviceHostHeader?
      if (!preserveHost) {
        httpHeaders.remove(HttpHeaders.HOST);
      }
    });
​
  RequestHeadersSpec<?> headersSpec;
  if (requiresBody(method)) {
    headersSpec = bodySpec.body(BodyInserters.fromDataBuffers(request.getBody()));
  }
  else {
    headersSpec = bodySpec;
  }
​
  return headersSpec.exchange()
    .log("webClient route")
    .flatMap(res -> {
      // 将返回的结构再次封装到 exchange 中,同时设置 gatewayClientResponse
      ServerHttpResponse response = exchange.getResponse();
      response.getHeaders().putAll(res.headers().asHttpHeaders());
      response.setStatusCode(res.statusCode());
      // Defer committing the response until all route filters have run
      // Put client response as ServerWebExchange attribute and write
      // response later NettyWriteResponseFilter
      exchange.getAttributes().put(CLIENT_RESPONSE_ATTR, res);
      return chain.filter(exchange);
    });
}
```

### ForwardRoutingFilter

```java
@Override
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
   log.info("执行到 -> ForwardRoutingFilter#filter");
   URI requestUrl = exchange.getRequiredAttribute(GATEWAY_REQUEST_URL_ATTR);
   String scheme = requestUrl.getScheme();
   if (isAlreadyRouted(exchange) || !"forward".equals(scheme)) {
      return chain.filter(exchange);
   }
   if (log.isTraceEnabled()) {
      log.trace("Forwarding to URI: " + requestUrl);
   }
   return this.getDispatcherHandler().handle(exchange);
}
```

## 参考链接

* [https://www.cnblogs.com/rever/p/9725173.html](https://www.cnblogs.com/rever/p/9725173.html)
* [https://www.cnblogs.com/SIHAIloveYAN/p/11288064.html](https://www.cnblogs.com/SIHAIloveYAN/p/11288064.html)



