---
title: Spring WebFlux(二)
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Reactive
  - WebFlux
  - WebClient
date: 2021-01-05 00:44:50
password:
summary: Web on Reactive Stack
categories: Spring
---

# Web on Reactive Stack

文档的此部分涵盖对基于 Reactive Streams API构建的反应堆Web应用程序的支持，该API可在非阻塞服务器，例如Netty，Undertow和Servlet 3.1+容器。各个章节涵盖了Spring WebFlux框架，响应式WebClient，对测试的支持以及响应式库。对于Servlet堆栈Web应用程序，请参阅Servlet堆栈上的Web。

## 1. Spring WebFlux

Spring框架中包含的原始Web框架Spring Web MVC是专门为Servlet API和Servlet容器而构建的。反应性堆栈Web框架Spring WebFlux在更高版本5.0中添加。它是完全无阻塞的，支持 Reactive Streams 背压，并且可以在Netty，Undertow和Servlet 3.1+容器等服务器上运行。

这两个Web框架都反映了其源模块的名称（spring-webmvc和spring-webflux），并在Spring框架中并存。每个模块都是可选的。应用程序可以使用一个模块或另一个模块，或者在某些情况下同时使用这两个模块，例如，带有响应式WebClient的Spring MVC控制器。

### 1.1. Overview

为什么创建Spring WebFlux？

一部分答案是需要一个非阻塞式的Web堆栈来处理少量线程的并发并使用更少的硬件资源进行扩展。Servlet 3.1确实提供了用于非阻塞I / O的API。但是，使用它会导致Servlet API的其余部分偏离，在这些API中，合同是同步的（Filter，Servlet）或阻塞的（getParameter，getPart）。这是促使新的通用API成为所有非阻塞运行时的基础的动机。这很重要，因为服务器（例如Netty）在异步，非阻塞空间中已建立良好。

另一部分答案是函数式编程，就像在Java 5中添加注释会创造机会（例如带注释的REST控制器或单元测试）一样，在Java 8中添加lambda表达式也会为Java中的功能API创造机会。这对于无阻塞的应用程序和延续样式的API（如CompletableFuture和ReactiveX所流行）的好处是，它们允许以声明方式构成异步逻辑。在编程模型级别，Java 8使Spring WebFlux能够与带注释的控制器一起提供功能性的Web端点。

#### 1.1.1. Define “Reactive”

我们谈到了“非阻塞”和“功能性”，但是反应式意味着什么？

术语“反应性”是指围绕对更改作出反应而构建的编程模型-网络组件对I / O事件做出反应，UI控制器对鼠标事件做出反应等。从这个意义上说，非阻塞是反应性的，因为我们现在正处于操作完成或数据可用时对通知进行反应的方式，而不是被阻塞。

我们Spring团队还有另一个重要机制与“反应性”相关联，这是非阻塞背压的机制。在同步命令式代码中，阻塞调用是背压的自然形式，它迫使调用者等待。在非阻塞代码中，控制事件的速率很重要，这样快速的生产者就不会击垮消费者。

Reactive Streams是一个小的规范（在Java 9中也采用了），它定义了带有反压力的异步组件之间的交互。例如，数据库（充当发布者）可以生成数据，然后HTTP服务器（充当订阅者）可以将其写入响应。Reactive Streams的主要目的是让订阅者控制发布者生成数据的速度或速度。

> 反应流的目的仅仅是建立机制和边界。如果发布者无法放慢速度，则必须决定是缓冲，删除还是失败。

#### 1.1.2. Reactive API

反应流对于互操作性起着重要作用。库和基础结构组件对此很感兴趣，但由于它太底层了，因此它不适合用作应用程序API。应用程序需要更高级别且功能更丰富的API来构成异步逻辑，这与Java 8 Stream API相似，但不仅适用于集合。这就是反应式库发挥的作用。

Reactor是Spring WebFlux的首选反应库。它通过与ReactiveX运算符词汇对齐的丰富运算符集，提供了Mono和Flux API类型，以处理0..1（Mono）和0..N（Flux）的数据序列。Reactor是Reactive Streams库，因此，它的所有运算符都支持无阻塞背压。Reactor非常注重服务器端Java。它是与Spring紧密合作开发的。

WebFlux要求Reactor作为核心依赖项，但它可以通过Reactive Streams与其他反应式库互操作。通常，WebFlux API接受普通的Publisher作为输入，在内部将其适应于Reactor类型，使用它，然后返回Flux或Mono作为输出。因此，您可以将任何发布服务器作为输入传递，并且可以对输出应用操作，但是您需要调整输出以与另一个反应库一起使用。只要可行（例如，带注释的控制器），WebFlux就会透明地适应RxJava或其他反应式库的使用。有关更多详细信息，请参见反应式类库。

#### 1.1.3. Programming Models

spring-web模块包含Spring WebFlux基础的反应式基础，包括HTTP抽象，用于支持的服务器的Reactive Streams适配器，编解码器，以及与Servlet API类似但具有非阻塞合同的核心WebHandler API。

在此基础上，Spring WebFlux提供了两种编程模型的选择：

- 带注释的控制器：与Spring MVC一致，并基于来自spring-web模块的相同注释。Spring MVC和WebFlux控制器都支持反应式（Reactor和RxJava）返回类型，因此，区分它们并不容易。一个显着的区别是WebFlux还支持反应式@RequestBody参数。
- 功能端点：基于Lambda的轻量级功能编程模型。您可以将其视为一个小型库或一组实用程序，应用程序可以使用它们来路由和处理请求。带注释的控制器的最大区别在于，应用程序负责从头到尾的请求处理，而不是通过注释声明意图并被回调。

#### 1.1.4. Applicability

Spring MVC还是WebFlux？

这是一个很自然的问题，但却建立了一个不合理的二分法。实际上，两者共同努力扩大了可用选项的范围。两者的设计旨在实现彼此的连续性和一致性，它们可以并行使用，并且双方的反馈对双方都有利。下图显示了两者之间的关系，它们的共同点以及各自的独特支持：

![spring mvc and webflux venn](https://cdn.jsdelivr.net/gh/HoldDie/img/20210105004616.png)

我们建议您考虑以下几点：

- 如果您有运行正常的Spring MVC应用程序，则无需更改。命令式编程是编写，理解和调试代码的最简单方法。您有最大的库选择空间，因为从历史上看，大多数库都是阻塞的。
- 如果您已经在选择非阻塞的Web技术栈，Spring WebFlux可以提供与该领域其他服务器相同的执行模型优势，还可以选择服务器（Netty，Tomcat，Jetty，Undertow和Servlet 3.1+容器），选择编程模型（带注释的控制器和功能性Web端点），以及选择反应式库（Reactor，RxJava或其他）。
- 如果您对与Java 8 lambda或Kotlin一起使用的轻量级功能性Web框架感兴趣，则可以使用Spring WebFlux功能性Web端点。对于要求较低复杂性的较小应用程序或微服务（可以受益于更高的透明度和控制）而言，这也是一个不错的选择。
- 在微服务架构中，您可以混合使用带有Spring MVC或Spring WebFlux控制器或带有Spring WebFlux功能端点的应用程序。在两个框架中都支持相同的基于注释的编程模型，这使得重用知识变得更加容易，同时还为正确的工作选择了正确的工具。
- 评估应用程序的一种简单方法是检查其依赖关系。如果您要使用阻塞性持久性API（JPA，JDBC）或网络API，则Spring MVC至少是常见体系结构的最佳选择。使用Reactor和RxJava在单独的线程上执行阻塞调用在技术上都是可行的，但是您不会充分利用非阻塞Web堆栈。
- 如果您的Spring MVC应用程序具有对远程服务的调用，请尝试响应式WebClient。您可以直接从Spring MVC控制器方法返回反应类型（Reactor，RxJava或其他）。每个调用的等待时间或调用之间的相互依赖性越大，好处就越明显。Spring MVC控制器也可以调用其他反应式组件。
- 如果您有庞大的团队，请牢记向非阻塞，功能性和声明性编程的过渡过程中的学习曲线很陡。一种无需完全切换即可开始的实用方法是使用反应式WebClient。除此之外，从小处着手并衡量收益。我们希望对于广泛的应用而言，这种转变是不必要的。如果不确定要寻找什么好处，请先了解无阻塞I / O的工作原理（例如，单线程Node.js上的并发性）及其影响。

#### 1.1.5. Servers

Tomcat，Jetty，Servlet 3.1+容器以及非Servlet运行时（例如Netty和Undertow）都支持Spring WebFlux。所有服务器都适应于低级通用API，因此可以跨服务器支持更高级别的编程模型。

Spring WebFlux不具有内置支持来启动或停止服务器。但是，从Spring配置和WebFlux基础结构组装应用程序并用几行代码运行它很容易。

Spring Boot具有一个WebFlux启动器，可以自动执行这些步骤。默认情况下，入门者使用Netty，但是通过更改Maven或Gradle依赖关系，可以轻松切换到Tomcat，Jetty或Undertow。Spring Boot默认为Netty，因为它在异步，非阻塞空间中得到更广泛的使用，并允许客户端和服务器共享资源。

Tomcat和Jetty可以与Spring MVC和WebFlux一起使用。但是请记住，它们的使用方式非常不同。Spring MVC依靠Servlet阻塞I / O，并允许应用程序在需要时直接使用Servlet API。 Spring WebFlux依赖Servlet 3.1非阻塞I / O，并在低级适配器后面使用Servlet API。请勿将其直接使用。

对于Undertow，Spring WebFlux直接使用Undertow API，而无需使用Servlet API。

#### 1.1.6. Performance

性能最优说服力，反应和非阻塞不一定会使应用程序运行得更快。在某些情况下，它们可以（例如，如果使用WebClient并行运行远程调用）。总体而言，以非阻塞方式进行处理需要更多的工作，这可能会稍微增加所需的处理时间。

反应性和非阻塞性的主要预期好处是能够以较少的固定数量的线程和较少的内存进行扩展。这使应用程序在负载下更具弹性，因为它们以更可预测的方式扩展。但是，为了观察这些好处，您需要有一些延迟（包括缓慢的和不可预测的网络I / O的混合）。这就是反应堆开始显示其优势的地方，差异可能很大。

#### 1.1.7. Concurrency Model

Spring MVC和Spring WebFlux都支持带注释的控制器，但是并发模型和默认的阻塞和线程假设存在关键差异。

在Spring MVC（通常是Servlet应用程序）中，假定应用程序可以阻塞当前线程（例如，用于远程调用）。因此，Servlet容器使用大线程池来吸收请求处理期间的潜在阻塞。

在Spring WebFlux（通常是非阻塞服务器）中，假定应用程序未阻塞。因此，非阻塞服务器使用固定大小的小型线程池（事件循环工作器）来处理请求。

调用阻塞API

如果确实需要使用阻塞库怎么办？ Reactor和RxJava都提供了publishOn运算符以继续在其他线程上进行处理。这意味着容易逃生。但是请记住，阻塞式API不适用于此并发模型。

可变状态

在Reactor和RxJava中，您可以通过运算符声明逻辑。在运行时，会形成一个反应式管道，其中在不同的阶段依次处理数据。这样做的主要好处是，它使应用程序不必保护可变状态，因为该管道中的应用程序代码永远不会被并发调用。

线程模型

您期望在运行Spring WebFlux的服务器上看到哪些线程？

- 在“原始” Spring WebFlux服务器上（例如，没有数据访问权限或其他可选依赖项），您可以期望该服务器有一个线程，而其他几个线程则可以进行请求处理（通常与CPU核心数量一样多）。但是，Servlet容器可能以更多线程开始（例如，Tomcat上为10），以支持Servlet（阻塞）I / O和Servlet 3.1（非阻塞）I / O使用。
- 反应式的“ WebClient”以事件循环的方式运行。因此，您会看到与之相关的固定数量的处理线程（例如，带有Reactor Netty连接器的`reactor-http-nio-`）。但是，如果客户端和服务器都使用Reactor Netty，则默认情况下，两者共享事件循环资源。
- Reactor和RxJava提供了称为调度程序的线程池抽象，以与publishOn运算符配合使用，该运算符用于将处理切换到其他线程池。调度程序具有建议特定并发策略的名称-例如，“并行”（对于具有有限数量的线程的CPU绑定工作）或“弹性”（对于具有大量线程的I / O绑定）。如果看到这样的线程，则意味着某些代码正在使用特定的线程池“ Scheduler”策略。
- 数据访问库和其他第三方依赖性也可以创建和使用自己的线程。

配置

Spring框架不提供启动和停止服务器的支持。要为服务器配置线程模型，您需要使用服务器特定的配置API，或者，如果使用Spring Boot，请检查每个服务器的Spring Boot配置选项。您可以直接配置WebClient。对于所有其他库，请参阅其各自的文档。

### 1.2. Reactive Core

spring-web模块包含以下对响应式Web应用程序的基础支持：

- 对于服务器请求处理，有两个级别的支持。
  - HttpHandler：使用非阻塞I / O和Reactive Streams背压进行HTTP请求处理的基本协定，以及Reactor Netty，Undertow，Tomcat，Jetty和任何Servlet 3.1+容器的适配器。
  - WebHandler API：稍高级别的通用Web API，用于处理请求，在此之上构建了具体的编程模型，例如带注释的控制器和功能端点。
- 对于客户端，有一个基本的ClientHttpConnector协定，以执行具有非阻塞I / O和响应流反压力的HTTP请求，以及用于Reactor Netty，响应式Jetty HttpClient和Apache HttpComponents的适配器。应用程序中使用的更高级别的WebClient基于此基本协定。
- 对于客户端和服务器，编解码器用于HTTP请求和响应内容的序列化和反序列化。

#### 1.2.1. `HttpHandler`

HttpHandler是具有一个用于处理请求和响应的单一方法的简单协定。它是有意的最小化，其主要且唯一的目的是成为对不同HTTP服务器API的最小化抽象。

下表描述了受支持的服务器API：

| Server name           | Server API used                                              | Reactive Streams support                                     |
| :-------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| Netty                 | Netty API                                                    | [Reactor Netty](https://github.com/reactor/reactor-netty)    |
| Undertow              | Undertow API                                                 | spring-web: Undertow to Reactive Streams bridge              |
| Tomcat                | Servlet 3.1 non-blocking I/O; Tomcat API to read and write ByteBuffers vs byte[] | spring-web: Servlet 3.1 non-blocking I/O to Reactive Streams bridge |
| Jetty                 | Servlet 3.1 non-blocking I/O; Jetty API to write ByteBuffers vs byte[] | spring-web: Servlet 3.1 non-blocking I/O to Reactive Streams bridge |
| Servlet 3.1 container | Servlet 3.1 non-blocking I/O                                 | spring-web: Servlet 3.1 non-blocking I/O to Reactive Streams bridge |

下表描述了服务器依赖性（另请参阅受支持的版本）：

| Server name   | Group id                | Artifact name               |
| :------------ | :---------------------- | :-------------------------- |
| Reactor Netty | io.projectreactor.netty | reactor-netty               |
| Undertow      | io.undertow             | undertow-core               |
| Tomcat        | org.apache.tomcat.embed | tomcat-embed-core           |
| Jetty         | org.eclipse.jetty       | jetty-server, jetty-servlet |

下面的代码段显示了对每个服务器API使用HttpHandler适配器的情况：

**Reactor Netty**

```java
HttpHandler handler = ...
ReactorHttpHandlerAdapter adapter = new ReactorHttpHandlerAdapter(handler);
HttpServer.create().host(host).port(port).handle(adapter).bind().block();
```

**Undertow**

```java
HttpHandler handler = ...
UndertowHttpHandlerAdapter adapter = new UndertowHttpHandlerAdapter(handler);
Undertow server = Undertow.builder().addHttpListener(port, host).setHandler(adapter).build();
server.start();
```

**Tomcat**

```java
HttpHandler handler = ...
Servlet servlet = new TomcatHttpHandlerAdapter(handler);

Tomcat server = new Tomcat();
File base = new File(System.getProperty("java.io.tmpdir"));
Context rootContext = server.addContext("", base.getAbsolutePath());
Tomcat.addServlet(rootContext, "main", servlet);
rootContext.addServletMappingDecoded("/", "main");
server.setHost(host);
server.setPort(port);
server.start();
```

**Jetty**

```java
HttpHandler handler = ...
Servlet servlet = new JettyHttpHandlerAdapter(handler);

Server server = new Server();
ServletContextHandler contextHandler = new ServletContextHandler(server, "");
contextHandler.addServlet(new ServletHolder(servlet), "/");
contextHandler.start();

ServerConnector connector = new ServerConnector(server);
connector.setHost(host);
connector.setPort(port);
server.addConnector(connector);
server.start();
```

**Servlet 3.1+ Container**

要将其作为WAR部署到任何Servlet 3.1+容器，您可以扩展WAR并将其包括在AbstractReactiveWebInitializer中。该类使用ServletHttpHandlerAdapter包装HttpHandler并将其注册为Servlet。

#### 1.2.2. `WebHandler` API

org.springframework.web.server包建立在HttpHandler契约的基础上，以提供通用的Web API，以通过多个WebExceptionHandler，多个WebFilter和单个WebHandler组件的链来处理请求。通过简单地指向自动检测组件的Spring ApplicationContext和/或通过向构建器注册组件，可以将该链与WebHttpHandlerBuilder放在一起。

尽管HttpHandler的目标很简单，即抽象化不同HTTP服务器的使用，但WebHandler API的目的是提供Web应用程序中常用的更广泛的功能集，例如：

- 具有属性的用户会话。
- 请求属性。
- 请求的解析的语言环境或主体。
- 访问已解析和缓存的表单数据。
- 多部分数据的抽象。
- 和更多

##### Special bean types

下表列出了WebHttpHandlerBuilder可以在Spring ApplicationContext中自动检测的组件，或者可以直接向其注册的组件：

| Bean name                    | Bean type                    | Count | Description                                                  |
| :--------------------------- | :--------------------------- | :---- | :----------------------------------------------------------- |
| <any>                        | `WebExceptionHandler`        | 0..N  | Provide handling for exceptions from the chain of `WebFilter` instances and the target `WebHandler`. For more details, see [Exceptions](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-exception-handler). |
| <any>                        | `WebFilter`                  | 0..N  | Apply interception style logic to before and after the rest of the filter chain and the target `WebHandler`. For more details, see [Filters](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-filters). |
| `webHandler`                 | `WebHandler`                 | 1     | The handler for the request.                                 |
| `webSessionManager`          | `WebSessionManager`          | 0..1  | The manager for `WebSession` instances exposed through a method on `ServerWebExchange`. `DefaultWebSessionManager` by default. |
| `serverCodecConfigurer`      | `ServerCodecConfigurer`      | 0..1  | For access to `HttpMessageReader` instances for parsing form data and multipart data that is then exposed through methods on `ServerWebExchange`. `ServerCodecConfigurer.create()` by default. |
| `localeContextResolver`      | `LocaleContextResolver`      | 0..1  | The resolver for `LocaleContext` exposed through a method on `ServerWebExchange`. `AcceptHeaderLocaleContextResolver` by default. |
| `forwardedHeaderTransformer` | `ForwardedHeaderTransformer` | 0..1  | For processing forwarded type headers, either by extracting and removing them or by removing them only. Not used by default. |

##### Form Data

ServerWebExchange公开了以下访问表单数据的方法：

```java
Mono<MultiValueMap<String, String>> getFormData();
```

DefaultServerWebExchange使用配置的HttpMessageReader将表单数据（application / x-www-form-urlencoded）解析为MultiValueMap。默认情况下，FormHttpMessageReader配置为由ServerCodecConfigurer Bean使用（请参阅Web Handler API）。

##### Multipart Data

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-multipart)

ServerWebExchange公开了以下访问 multipart 数据的方法：

```java
Mono<MultiValueMap<String, Part>> getMultipartData();
```

DefaultServerWebExchange使用配置的HttpMessageReader >将multipart / form-data内容解析为MultiValueMap。默认情况下，这是DefaultPartHttpMessageReader，它没有任何第三方依赖性。或者，可以使用基于Synchronoss NIO Multipart库的SynchronossPartHttpMessageReader。两者都是通过ServerCodecConfigurer bean进行配置的（请参阅Web Handler API）。

要以流方式解析多部分数据，可以使用从HttpMessageReader 返回的Flux 。例如，在带注释的控制器中，使用@RequestPart意味着按名称对各个部分进行类似于Map的访问，因此需要完整地解析多部分数据。相比之下，您可以使用@RequestBody将内容解码为Flux 而不收集到MultiValueMap。

##### Forwarded Headers

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#filters-forwarded-headers)

当请求通过代理（例如负载平衡器）进行处理时，主机，端口和方案可能会更改。从客户端的角度来看，创建指向正确主机，端口和方案的链接是一个挑战。

RFC 7239定义了代理可以用来提供有关原始请求的信息的HTTP转发头。还有其他非标准标头，包括X-Forwarded-Host，X-Forwarded-Port，X-Forwarded-Proto，X-Forwarded-Ssl和X-Forwarded-Prefix。

ForwardedHeaderTransformer是一个组件，可根据转发的标头修改请求的主机，端口和方案，然后删除这些标头。如果将其声明为名称为forwardedHeaderTransformer的bean，它将被检测到并使用。

对于转发的标头，存在安全方面的考虑，因为应用程序无法知道标头是由代理添加的，还是由恶意客户端添加的。这就是为什么应配置信任边界处的代理以删除来自外部的不受信任的转发流量的原因。您还可以使用removeOnly = true配置ForwardedHeaderTransformer，在这种情况下，它将删除但不使用标头。

#### 1.2.3. Filters

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#filters)

在WebHandler API中，可以使用WebFilter在其余过滤器和目标WebHandler的其余处理链之前和之后应用拦截样式的逻辑。使用WebFlux Config时，注册WebFilter就像将其声明为Spring bean一样简单，并且（可选）通过在bean声明上使用@Order或实现Ordered来表达优先级。

##### CORS

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#filters-cors)

Spring WebFlux通过控制器上的注释为CORS配置提供了细粒度的支持。但是，当您将其与Spring Security结合使用时，我们建议您使用内置的CorsFilter，该产品必须在Spring Security的过滤器链之前订购。

#### 1.2.4. Exceptions

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-customer-servlet-container-error-page)

在WebHandler API中，可以使用WebExceptionHandler来处理WebFilter实例链和目标WebHandler链中的异常。使用WebFlux Config时，注册WebExceptionHandler就像将其声明为Spring bean一样简单，并且（可选）通过在bean声明上使用@Order或实现Ordered来表达优先级。

下表描述了可用的WebExceptionHandler实现：

| Exception Handler                       | Description                                                  |
| :-------------------------------------- | :----------------------------------------------------------- |
| `ResponseStatusExceptionHandler`        | 通过将响应设置为异常的HTTP状态代码，提供对ResponseStatusException类型的异常的处理。 |
| `WebFluxResponseStatusExceptionHandler` | ResponseStatusExceptionHandler的扩展，它也可以确定任何异常上@ResponseStatus批注的HTTP状态代码。该处理程序在WebFlux Config中声明。 |

#### 1.2.5. Codecs

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/integration.html#rest-message-conversion)

spring-web和spring-core模块提供支持，通过具有Reactive Streams背压的非阻塞I / O，可以在高级对象之间来回串行化字节内容。以下介绍了此支持：

- 编码器和解码器是底层协议，用于独立于HTTP编码和解码内容。
- HttpMessageReader和HttpMessageWriter是对HTTP消息内容进行编码和解码的协定。
- 可以使用EncoderHttpMessageWriter来包装Encoder，以使其适合在Web应用程序中使用，而可以使用DecoderHttpMessageReader来包装Decoder。
- DataBuffer抽象了不同的字节缓冲区表示形式（例如Netty ByteBuf，java.nio.ByteBuffer等），并且是所有编解码器都在处理的内容。有关此主题的更多信息，请参见“ Spring核心”部分中的数据缓冲区和编解码器。

spring-core模块提供byte []，ByteBuffer，DataBuffer，Resource和String编码器和解码器实现。 spring-web模块提供了Jackson JSON，Jackson Smile，JAXB2，Protocol Buffers和其他编码器和解码器，以及仅Web的HTTP消息读取器和写入器实现，用于表单数据，多部分内容，服务器发送的事件等。

ClientCodecConfigurer和ServerCodecConfigurer通常用于配置和自定义要在应用程序中使用的编解码器。请参阅有关配置HTTP消息编解码器的部分。

##### Jackson JSON

当存在Jackson库时，都支持JSON和二进制JSON（Smile）。

“ Jackson2Decoder”的工作方式如下：

- Jackson 的异步，非阻塞解析器用于将字节块流聚合到TokenBuffer的每个块中，每个代表JSON对象。
- 每个TokenBuffer都传递给Jackson的ObjectMapper以创建更高级别的对象。
- 解码为单值发布者（例如Mono）时，有一个TokenBuffer。
- 当解码为多值发布者（例如Flux）时，一旦为完整格式的对象接收到足够的字节，每个TokenBuffer就会传递给ObjectMapper。输入内容可以是JSON数组，也可以是任何以行分隔的JSON格式，例如NDJSON，JSON Lines或JSON Text Sequences。

Jackson2Encoder的工作方式如下：

- 对于单个值发布者（例如Mono），只需通过ObjectMapper对其进行序列化即可。
- 对于具有application / json的多值发布者，默认情况下使用Flux＃collectToList（）收集值，然后序列化结果集合。
- 对于具有流媒体类型（例如application / x-ndjson或application / stream + x-jackson-smile）的多值发布者，请使用行定界的JSON格式分别对每个值进行编码，写入和刷新。其他流媒体类型可以在编码器中注册。
- 对于SSE，将为每个事件调用Jackson2Encoder，并刷新输出以确保交付没有延迟。

##### Form Data

FormHttpMessageReader和FormHttpMessageWriter支持对应用程序/ x-www-form-urlencoded内容进行解码和编码。

在经常需要从多个位置访问表单内容的服务器端，ServerWebExchange提供了专用的getFormData（）方法，该方法通过FormHttpMessageReader解析内容，然后缓存结果以进行重复访问。请参阅WebHandler API部分中的表单数据。

一旦使用getFormData（），就无法再从请求正文中读取原始原始内容。因此，应用程序应始终通过ServerWebExchange来访问缓存的表单数据，而不是从原始请求正文中进行读取。

##### Multipart

MultipartHttpMessageReader和MultipartHttpMessageWriter支持对“ multipart / form-data”内容进行解码和编码。反过来，MultipartHttpMessageReader委托另一个HttpMessageReader进行实际解析为Flux ，然后将这些部分简单地收集到MultiValueMap中。默认情况下，使用DefaultPartHttpMessageReader，但是可以通过ServerCodecConfigurer进行更改。有关DefaultPartHttpMessageReader的更多信息，请参考DefaultPartHttpMessageReader的javadoc。

在可能需要从多个位置访问多部分表单内容的服务器端，ServerWebExchange提供了专用的getMultipartData（）方法，该方法通过MultipartHttpMessageReader解析内容，然后缓存结果以进行重复访问。请参阅WebHandler API部分中的多部分数据。

一旦使用getMultipartData（），就无法再从请求正文中读取原始原始内容。因此，应用程序必须始终使用getMultipartData（）来重复，类似地图地访问零件，否则必须依赖SynchronossPartHttpMessageReader来一次性访问Flux 。

##### Limits

可以对缓冲部分或全部输入流的Decoder和HttpMessageReader实现进行配置，并限制要在内存中缓冲的最大字节数。在某些情况下，由于输入被聚合并表示为单个对象而发生缓冲，例如，具有@RequestBody byte []，x-www-form-urlencoded数据的控制器方法，等等。在分割输入流（例如，定界文本，JSON对象流等）时，流处理也会发生缓冲。对于这些流情况，该限制适用于与流中一个对象关联的字节数。

要配置缓冲区大小，可以检查给定的Decoder或HttpMessageReader是否公开了maxInMemorySize属性，如果这样，则Javadoc将具有有关默认值的详细信息。在服务器端，ServerCodecConfigurer提供了一个设置所有编解码器的位置，请参阅HTTP消息编解码器。在客户端，可以在WebClient.Builder中更改所有编解码器的限制。

对于Multipart解析，maxInMemorySize属性限制了非文件部分的大小。对于文件部件，它确定将部件写入磁盘的阈值。对于写入磁盘的文件部件，还有一个额外的maxDiskUsagePerPart属性可限制每个部件的磁盘空间量。还有一个maxParts属性，用于限制多部分请求中的部分总数。要在WebFlux中配置所有这三个功能，您需要向ServerCodecConfigurer提供一个预先配置的MultipartHttpMessageReader实例。

##### Streaming

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-async-http-streaming)

在流式传输到HTTP响应时（例如，text / event-stream，application / x-ndjson），定期发送数据很重要，这样才能尽快（而不是稍后）可靠地检测到断开连接的客户端。这样的发送可以是仅注释，空的SSE事件或任何其他可以有效充当心跳的“无操作”数据。

##### `DataBuffer`

DataBuffer是WebFlux中字节缓冲区的表示形式。本参考资料的Spring Core部分在“数据缓冲区和编解码器”部分中有更多介绍。要理解的关键点是，在诸如Netty之类的某些服务器上，字节缓冲被池化并计数引用，并且在使用时必须将其释放以避免内存泄漏。

WebFlux应用程序通常不需要关心此类问题，除非它们直接使用或产生数据缓冲区，而不是依赖于编解码器与更高级别的对象之间进行转换，或者除非它们选择创建自定义编解码器。对于这种情况，请查看数据缓冲区和编解码器中的信息，尤其是有关使用数据缓冲区的部分。

#### 1.2.6. Logging

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-logging)

Spring WebFlux中的DEBUG级别日志记录旨在紧凑，最小化并且对用户友好。它关注于一遍又一遍有用的高价值信息，而其他信息则仅在调试特定问题时才有用。

TRACE级别的日志记录通常遵循与DEBUG相同的原理（例如，也不应成为firehose），但可用于调试任何问题。另外，某些日志消息在TRACE vs DEBUG上可能显示不同级别的详细信息。

良好的日志记录来自使用日志的经验。如果发现任何不符合既定目标的东西，请告诉我们。

##### Log Id

在WebFlux中，单个请求可以在多个线程上运行，并且线程ID对于关联属于特定请求的日志消息没有用。这就是为什么WebFlux日志消息默认情况下带有特定于请求的ID的原因。

在服务器端，日志ID存储在ServerWebExchange属性（LOG_ID_ATTRIBUTE）中，而可从ServerWebExchange＃getLogPrefix（）获得基于该ID的全格式前缀。在WebClient端，日志ID存储在ClientRequest属性（LOG_ID_ATTRIBUTE）中，而完全格式的前缀可从ClientRequest＃logPrefix（）获得。

##### Sensitive Data

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-logging-sensitive-data)

DEBUG和TRACE日志记录可以记录敏感信息。这就是默认情况下屏蔽表单参数和标题的原因，并且必须显式启用它们的完整日志记录。

下面的示例说明如何针对服务器端请求执行此操作：

```java
@Configuration
@EnableWebFlux
class MyConfig implements WebFluxConfigurer {

    @Override
    public void configureHttpMessageCodecs(ServerCodecConfigurer configurer) {
        configurer.defaultCodecs().enableLoggingRequestDetails(true);
    }
}
```

以下示例显示了如何针对客户端请求执行此操作

```java
Consumer<ClientCodecConfigurer> consumer = configurer ->
        configurer.defaultCodecs().enableLoggingRequestDetails(true);

WebClient webClient = WebClient.builder()
        .exchangeStrategies(strategies -> strategies.codecs(consumer))
        .build();
```

##### Appenders

日志库（例如SLF4J和Log4J 2）提供了避免阻塞的异步记录器。尽管它们有其自身的缺点，例如可能丢弃无法排队进行日志记录的消息，但它们是当前在反应性，非阻塞应用程序中使用的最佳可用选项。

##### Custom codecs

应用程序可以注册自定义编解码器以支持其他媒体类型，也可以注册默认编解码器不支持的特定行为。

开发人员表达的某些配置选项在默认编解码器上强制执行。自定义编解码器可能希望有机会与这些首选项保持一致，例如强制执行缓冲限制或记录敏感数据。

下面的示例说明如何针对客户端请求执行此操作：

```java
WebClient webClient = WebClient.builder()
        .codecs(configurer -> {
                CustomDecoder decoder = new CustomDecoder();
                configurer.customCodecs().registerWithDefaultConfig(decoder);
        })
        .build();
```

### 1.3. `DispatcherHandler`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-servlet)

Spring WebFlux与Spring MVC类似，是围绕前端控制器模式设计的，其中中央WebHandler DispatcherHandler提供了用于请求处理的共享算法，而实际工作是由可配置的委托组件执行的。该模型非常灵活，并支持多种工作流程。

DispatcherHandler从Spring配置中发现所需的委托组件。它还被设计为Spring Bean本身，并实现ApplicationContextAware来访问其运行的上下文。如果以WebHandler的bean名称声明了DispatcherHandler，则WebHttpHandlerBuilder会发现它，而WebHttpHandlerBuilder会按照WebHandler API中的描述将请求处理链组合在一起。

WebFlux应用程序中的Spring配置通常包含：

- Bean名称为webHandler的DispatcherHandler

- WebFilter和WebExceptionHandler bean

- DispatcherHandler特殊豆

将配置提供给WebHttpHandlerBuilder以构建处理链，如以下示例所示：

```java
ApplicationContext context = ...
HttpHandler handler = WebHttpHandlerBuilder.applicationContext(context).build();
```

生成的HttpHandler已准备好与服务器适配器一起使用。

#### 1.3.1. Special Bean Types

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-servlet-special-bean-types)

DispatcherHandler委托给特殊的bean处理请求并呈现适当的响应。所谓“特殊bean”，是指实现WebFlux框架合同的Spring管理对象实例。这些通常带有内置合同，但是您可以自定义它们的属性，扩展它们或替换它们。

下表列出了DispatcherHandler检测到的特殊bean。请注意，在较低级别还检测到其他一些Bean（请参阅Web Handler API中的特殊Bean类型）。

| Bean type              | Explanation                                                  |
| :--------------------- | :----------------------------------------------------------- |
| `HandlerMapping`       | 将请求映射到处理程序。映射基于某些条件，这些条件的详细信息因HandlerMapping实现而有所不同-带有注释的控制器，简单的URL模式映射以及其他。<br/><br/>主要的HandlerMapping实现是用于@RequestMapping注释方法的RequestMappingHandlerMapping，用于功能端点路由的RouterFunctionMapping和用于URI路径模式和WebHandler实例的显式注册的SimpleUrlHandlerMapping。 |
| `HandlerAdapter`       | 帮助DispatcherHandler调用映射到请求的处理程序，而不管实际如何调用该处理程序。例如，调用带注释的控制器需要解析注释。 HandlerAdapter的主要目的是使DispatcherHandler免受此类细节的影响。 |
| `HandlerResultHandler` | 处理来自处理程序调用的结果，并最终确定响应。请参阅结果处理。 |

#### 1.3.2. WebFlux Config

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-servlet-config)

应用程序可以声明处理请求所需的基础结构bean（在Web Handler API和DispatcherHandler下列出）。但是，在大多数情况下，WebFlux Config是最佳起点。它声明了所需的bean，并提供了更高级别的配置回调API来对其进行自定义。

#### 1.3.3. Processing

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-servlet-sequence)

DispatcherHandler处理请求的方式如下：

- 要求每个HandlerMapping查找一个匹配的处理程序，并使用第一个匹配项。
- 如果找到处理程序，则通过适当的HandlerAdapter运行该处理程序，该处理程序将执行的返回值公开为HandlerResult。
- 通过直接写入响应或使用视图渲染，将HandlerResult提供给适当的HandlerResultHandler以完成处理。

#### 1.3.4. Result Handling

通过HandlerAdapter调用处理程序的返回值连同其他一些上下文一起包装为HandlerResult，并传递给第一个声明支持它的HandlerResultHandler。下表显示了可用的HandlerResultHandler实现，所有实现都在WebFlux Config中声明：

| Result Handler Type           | Return Values                                                | Default Order       |
| :---------------------------- | :----------------------------------------------------------- | :------------------ |
| `ResponseEntityResultHandler` | `ResponseEntity`, typically from `@Controller` instances.    | 0                   |
| `ServerResponseResultHandler` | `ServerResponse`, typically from functional endpoints.       | 0                   |
| `ResponseBodyResultHandler`   | Handle return values from `@ResponseBody` methods or `@RestController` classes. | 100                 |
| `ViewResolutionResultHandler` | `CharSequence`, [`View`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/reactive/result/view/View.html), [Model](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/ui/Model.html), `Map`, [Rendering](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/reactive/result/view/Rendering.html), or any other `Object` is treated as a model attribute.See also [View Resolution](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-viewresolution). | `Integer.MAX_VALUE` |

#### 1.3.5. Exceptions

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-exceptionhandlers)

从HandlerAdapter返回的HandlerResult可以公开基于某些特定于处理程序的机制进行错误处理的函数。在以下情况下将调用此错误函数：

- 处理程序（例如，@ Controller）调用失败。
- 通过HandlerResultHandler处理处理程序返回值失败。

只要在从处理程序返回的反应类型产生任何数据项之前发生错误信号，错误函数就可以更改响应（例如，更改为错误状态）。

这就是支持@Controller类中的@ExceptionHandler方法的方式。相比之下，Spring MVC中对相同功能的支持建立在HandlerExceptionResolver之上。这通常不重要。但是，请记住，在WebFlux中，不能使用@ControllerAdvice来处理在选择处理程序之前发生的异常。

另请参见“带注释的控制器”部分中的“管理异常”或“ WebHandler API”部分中的“异常”。

#### 1.3.6. View Resolution

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-viewresolver)

视图分辨率使您可以使用HTML模板和模型渲染到浏览器，而无需将您与特定的视图技术联系在一起。在Spring WebFlux中，通过专用的HandlerResultHandler支持视图解析，该HandlerResultHandler使用ViewResolver实例将String（代表逻辑视图名称）映射到View实例。然后使用视图来呈现响应。

##### Handling

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-handling)

传递给ViewResolutionResultHandler的HandlerResult包含处理程序的返回值和包含请求处理期间添加的属性的模型。返回值将作为以下值之一进行处理：

- 字符串，CharSequence：通过配置的ViewResolver实现列表解析为View的逻辑视图名称。
- void：根据请求路径选择一个默认视图名称，减去前导斜杠和尾部斜杠，然后将其解析为视图。当未提供视图名称（例如，返回模型属性）或异步返回值（例如，Mono完成为空）时，也会发生同样的情况。
- Rendering：用于视图分辨率方案的API。通过代码完成探索IDE中的选项。
- Model、Map：要添加到请求模型的额外模型属性。
- 其他任何其他值：任何其他返回值（由BeanUtils＃isSimpleProperty确定的简单类型除外）都将作为要添加到模型的模型属性。属性名称是通过使用约定从类名称派生的，除非存在处理程序方法@ModelAttribute批注。

该模型可以包含异步，反应式类型（例如，来自Reactor或RxJava）。在渲染之前，AbstractView将这些模型属性解析为具体值并更新模型。单值反应类型被解析为单个值或无值（如果为空），而多值反应类型（例如Flux ）被收集并解析为List 。

配置视图分辨率就像将一个SpringResolutionResultHandler bean添加到您的Spring配置中一样简单。 WebFlux Config提供了专用于视图分辨率的配置API。

有关与Spring WebFlux集成的视图技术的更多信息，请参见View Technologies。

##### Redirecting

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-redirecting-redirect-prefix)

视图名称中的特殊redirect：前缀使您可以执行重定向。 UrlBasedViewResolver（和子类）将其识别为需要重定向的指令。视图名称的其余部分是重定向URL。

最终效果与控制器返回RedirectView或Rendering.redirectTo（“ abc”）。build（）相同，但是现在控制器本身可以根据逻辑视图名称进行操作。视图名称（例如redirect：/ some / resource）相对于当前应用程序，而视图名称（例如redirect：https：//example.com/arbitrary/path）则重定向到绝对URL。

##### Content Negotiation

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-multiple-representations)

ViewResolutionResultHandler支持内容协商。它将请求媒体类型与每个选定视图支持的媒体类型进行比较。使用支持请求的媒体类型的第一个视图。

为了支持JSON和XML之类的媒体类型，Spring WebFlux提供了HttpMessageWriterView，它是通过HttpMessageWriter呈现的特殊视图。通常，您可以通过WebFlux配置将其配置为默认视图。如果默认视图与请求的媒体类型匹配，则始终会选择和使用它们。

### 1.4. Annotated Controllers

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-controller)

Spring WebFlux提供了一个基于注释的编程模型，其中@Controller和@RestController组件使用注释来表达请求映射，请求输入，处理异常等。带注释的控制器具有灵活的方法签名，无需扩展基类或实现特定的接口。

以下清单显示了一个基本示例：

```java
@RestController
public class HelloController {

    @GetMapping("/hello")
    public String handle() {
        return "Hello WebFlux";
    }
}
```

在前面的示例中，该方法返回要写入响应主体的String。

#### 1.4.1. `@Controller`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-controller)

您可以使用标准的Spring bean定义来定义控制器bean。@Controller构造型允许自动检测，并且与Spring常规支持保持一致，以支持在类路径中检测@Component类并为其自动注册Bean定义。它还充当带注释类的构造型，表明其作为Web组件的作用。

要启用对此类@Controller Bean的自动检测，可以将组件扫描添加到Java配置中，如以下示例所示：

```java
@Configuration
@ComponentScan("org.example.web") 
public class WebConfig {

    // ...
}
```

@RestController是一个组合式注释，其本身使用@Controller和@ResponseBody进行了元注释，表示一个控制器，其每个方法都继承了类型级别的@ResponseBody注释，因此，直接将其写入响应主体（与视图分辨率相对）并使用HTML模板。

#### 1.4.2. Request Mapping

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping)

@RequestMapping批注用于将请求映射到控制器方法。它具有各种属性，可以通过URL，HTTP方法，请求参数，标头和媒体类型进行匹配。您可以在类级别使用它来表示共享的映射，也可以在方法级别使用它来缩小到特定的端点映射。

@RequestMapping还有HTTP方法特定的快捷方式：

- `@GetMapping`
- `@PostMapping`
- `@PutMapping`
- `@DeleteMapping`
- `@PatchMapping`

前面的注释是提供的“自定义注释”，因为可以说，大多数控制器方法应映射到特定的HTTP方法，而不是使用@RequestMapping，后者默认情况下与所有HTTP方法匹配。同时，在类级别仍需要@RequestMapping来表示共享映射。

以下示例使用类型和方法级别的映射：

```java
@RestController
@RequestMapping("/persons")
class PersonController {

    @GetMapping("/{id}")
    public Person getPerson(@PathVariable Long id) {
        // ...
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public void add(@RequestBody Person person) {
        // ...
    }
}
```

##### URI Patterns

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-uri-templates)

您可以使用全局模式和通配符来映射请求：

| Pattern         | Description                                                  | Example                                                      |
| :-------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| `?`             | 匹配一个字符                                                 | `"/pages/t?st.html"` matches `"/pages/test.html"` and `"/pages/t3st.html"` |
| `*`             | 匹配路径段中的零个或多个字符                                 | `"/resources/*.png"` matches `"/resources/file.png"``"/projects/*/versions"` matches `"/projects/spring/versions"` but does not match `"/projects/spring/boot/versions"` |
| `**`            | 匹配零个或多个路径段，直到路径结束                           | `"/resources/**"` matches `"/resources/file.png"` and `"/resources/images/file.png"``"/resources/**/file.png"` is invalid as `**` is only allowed at the end of the path. |
| `{name}`        | 匹配路径段并将其捕获为名为“ name”的变量                      | `"/projects/{project}/versions"` matches `"/projects/spring/versions"` and captures `project=spring` |
| `{name:[a-z]+}` | 将正则表达式“ [[a-z] +””匹配为路径变量“ name”                | `"/projects/{project:[a-z]+}/versions"` matches `"/projects/spring/versions"` but not `"/projects/spring1/versions"` |
| `{*path}`       | 匹配零个或多个路径段，直到路径结尾，并将其捕获为名为“ path”的变量 | `"/resources/{*file}"` matches `"/resources/images/file.png"` and captures `file=images/file.png` |

捕获的URI变量可以通过`@PathVariable`访问，如以下示例所示：

```java
@GetMapping("/owners/{ownerId}/pets/{petId}")
public Pet findPet(@PathVariable Long ownerId, @PathVariable Long petId) {
    // ...
}
```

您可以在类和方法级别声明URI变量，如以下示例所示：

```java
@Controller
@RequestMapping("/owners/{ownerId}") 
public class OwnerController {

    @GetMapping("/pets/{petId}") 
    public Pet findPet(@PathVariable Long ownerId, @PathVariable Long petId) {
        // ...
    }
}
```

URI变量会自动转换为适当的类型，或者引发TypeMismatchException。默认情况下，支持简单类型（int，long，Date等），您可以注册对任何其他数据类型的支持。请参阅类型转换和DataBinder。

可以显式命名URI变量（例如，@PathVariable（“ customId”）），但是如果名称相同，则可以省略该详细信息，并使用调试信息或Java 8上的-parameters编译器标志编译代码。 。

语法{* varName}声明了一个与零个或多个剩余路径段匹配的URI变量。例如，/ resources / {* path}匹配/ resources /下的所有文件，并且“ path”变量捕获完整的相对路径。

语法{varName：regex}声明带有正则表达式的URI变量，其语法为：{varName：regex}。例如，给定URL /spring-web-3.0.5 .jar，以下方法提取名称，版本和文件扩展名：

```java
@GetMapping("/{name:[a-z-]+}-{version:\\d\\.\\d\\.\\d}{ext:\\.[a-z]+}")
public void handle(@PathVariable String version, @PathVariable String ext) {
    // ...
}
```

URI路径模式还可以嵌入$ {…}占位符，这些占位符在启动时通过PropertyPlaceHolderConfigurer针对本地，系统，环境和其他属性源进行解析。您可以使用它来例如基于某些外部配置参数化基本URL。

Spring WebFlux不支持后缀模式匹配，这与Spring MVC不同，后者的映射（例如/ person）也匹配到/person.*。对于基于URL的内容协商，如果需要，我们建议使用查询参数，该参数更简单，更明确，并且不易受到基于URL路径的攻击。

##### Pattern Comparison

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-pattern-comparison)

当多个模式与URL匹配时，必须将它们进行比较以找到最佳匹配。这是通过PathPattern.SPECIFICITY_COMPARATOR完成的，该工具查找更具体的模式。

对于每个模式，都会根据URI变量和通配符的数量计算得分，其中URI变量的得分低于通配符。总得分较低的模式将获胜。如果两个模式的分数相同，则选择更长的时间。

包罗万象的模式（例如**，{* varName}）不计入评分，而是始终排在最后。如果两种模式都通用，则选择较长的模式。

##### Consumable Media Types

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-consumes)

您可以根据请求的Content-Type缩小请求映射，如以下示例所示：

```java
@PostMapping(path = "/pets", consumes = "application/json")
public void addPet(@RequestBody Pet pet) {
    // ...
}
```

consumes 属性还支持否定表达式-例如，!text/plain 表示除 text/plain 之外的任何内容类型。

您可以在类级别上声明一个共享的cosumes属性。但是，与大多数其他请求映射属性不同，在类级别使用时，方法级别使用属性覆盖而不是扩展类级别声明。

##### Producible Media Types

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-produces)

您可以根据接受请求标头和控制器方法生成的内容类型列表来缩小请求映射，如以下示例所示：

```java
@GetMapping(path = "/pets/{petId}", produces = "application/json")
@ResponseBody
public Pet getPet(@PathVariable String petId) {
    // ...
}
```

媒体类型可以指定字符集。支持否定表达式-例如，！text / plain表示除text / plain之外的任何内容类型。

您可以在类级别声明共享的Produces属性。但是，与大多数其他请求映射属性不同，在类级别使用方法级别时，方法级别会产生属性覆盖，而不是扩展类级别声明。

##### Parameters and Headers

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-params-and-headers)

您可以根据查询参数条件来缩小请求映射。您可以测试查询参数（myParam）的存在，不存在（！myParam）或特定值（myParam = myValue）。以下示例测试具有值的参数：

```java
@GetMapping(path = "/pets/{petId}", params = "myParam=myValue") 
public void findPet(@PathVariable String petId) {
    // ...
}
```

您还可以将其与请求标头条件一起使用，如以下示例所示：

```java
@GetMapping(path = "/pets", headers = "myHeader=myValue") 
public void findPet(@PathVariable String petId) {
    // ...
}
```

##### HTTP HEAD, OPTIONS

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-head-options)

@GetMapping和@RequestMapping（method = HttpMethod.GET）透明地支持HTTP HEAD，用于请求映射。控制器方法无需更改。在HttpHandler服务器适配器中应用的响应包装器确保将Content-Length标头设置为写入的字节数，而无需实际写入响应。

默认情况下，通过将“允许响应”标头设置为所有具有匹配URL模式的@RequestMapping方法中列出的HTTP方法列表，来处理HTTP OPTIONS。

对于没有HTTP方法声明的@RequestMapping，将Allow标头设置为GET，HEAD，POST，PUT，PATCH，DELETE，OPTIONS。控制器方法应始终声明受支持的HTTP方法（例如，通过使用HTTP方法特定的变体-@ GetMapping，@ PostMapping等）。

您可以将@RequestMapping方法显式映射到HTTP HEAD和HTTP OPTIONS，但这在通常情况下不是必需的。

##### Custom Annotations

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-composed)

Spring WebFlux支持将组合注释用于请求映射。这些注解本身使用@RequestMapping进行元注解，并且旨在以更狭窄，更具体的用途重新声明@RequestMapping属性的子集（或全部）。

@GetMapping，@ PostMapping，@ PutMapping，@ DeleteMapping和@PatchMapping是组合注释的示例。之所以提供它们，是因为可以说，大多数控制器方法应该映射到特定的HTTP方法，而不是使用@RequestMapping，后者默认情况下与所有HTTP方法都匹配。如果需要组合注释的示例，请查看如何声明它们。

Spring WebFlux还支持具有自定义请求匹配逻辑的自定义请求映射属性。这是一个更高级的选项，需要子类化RequestMappingHandlerMapping并覆盖getCustomMethodCondition方法，您可以在其中检查自定义属性并返回自己的RequestCondition。

##### Explicit Registrations

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-registration)

您可以以编程方式注册Handler方法，这些方法可用于动态注册或高级用例，例如同一处理程序在不同URL下的不同实例。以下示例显示了如何执行此操作：

```java
@Configuration
public class MyConfig {

  @Autowired
  public void setHandlerMapping(RequestMappingHandlerMapping mapping, UserHandler handler) 
    throws NoSuchMethodException {

    RequestMappingInfo info = RequestMappingInfo
      .paths("/user/{id}").methods(RequestMethod.GET).build(); 

    Method method = UserHandler.class.getMethod("getUser", Long.class); 

    mapping.registerMapping(info, handler, method); 
  }

}
```

#### 1.4.3. Handler Methods

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-methods)

@RequestMapping处理程序方法具有灵活的签名，可以从一系列受支持的控制器方法参数和返回值中进行选择。

##### Method Arguments

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-arguments)

下表显示了受支持的控制器方法参数。

需要解析I / O（例如，读取请求正文）的自变量支持反应性类型（Reactor，RxJava或其他）。这在“描述”列中进行了标记。不需要阻塞的参数不应使用反应性类型。

支持JDK 1.8的java.util.Optional作为方法参数，并与具有必需属性（例如@ RequestParam，@ RequestHeader等）的注释结合在一起，等效于required = false。

| Controller method argument                                   | Description                                                  |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| `ServerWebExchange`                                          | 访问用于HTTP请求和响应，请求和会话属性，checkNotModified方法等的完整ServerWebExchange容器。 |
| `ServerHttpRequest`, `ServerHttpResponse`                    | 访问HTTP请求或响应。                                         |
| `WebSession`                                                 | 访问会话。除非添加了属性，否则这不会强制开始新的会话。支持反应类型。 |
| `java.security.Principal`                                    | 当前经过身份验证的用户-可能是特定的Principal实现类（如果已知）。支持反应类型。 |
| `org.springframework.http.HttpMethod`                        | 请求的HTTP方法。                                             |
| `java.util.Locale`                                           | 当前的请求区域设置，由最具体的可用LocaleResolver确定，实际上是配置的LocaleResolver / LocaleContextResolver。 |
| `java.util.TimeZone` + `java.time.ZoneId`                    | 与当前请求关联的时区，由LocaleContextResolver确定。          |
| `@PathVariable`                                              | 用于访问URI模板变量。请参阅URI模式。                         |
| `@MatrixVariable`                                            | 用于访问URI路径段中的名称/值对。请参阅矩阵变量。             |
| `@RequestParam`                                              | 用于访问Servlet请求参数。参数值将转换为声明的方法参数类型。请参阅@RequestParam。<br/><br/>请注意，@ RequestParam的使用是可选的，例如可以设置其属性。请参阅此表后面的“其他任何参数”。 |
| `@RequestHeader`                                             | 用于访问请求标头。标头值将转换为声明的方法参数类型。请参阅@RequestHeader。 |
| `@CookieValue`                                               | 用于访问cookie。 Cookie值将转换为声明的方法参数类型。请参阅@CookieValue。 |
| `@RequestBody`                                               | 用于访问HTTP请求正文。正文内容通过使用HttpMessageReader实例转换为声明的方法参数类型。支持反应类型。请参阅@RequestBody。 |
| `HttpEntity<B>`                                              | 用于访问请求标头和正文。主体使用HttpMessageReader实例进行转换。支持反应类型。请参见HttpEntity。 |
| `@RequestPart`                                               | 用于访问multipart / form-data请求中的零件。支持反应类型。请参见多部分内容和多部分数据。 |
| `java.util.Map`, `org.springframework.ui.Model`, and `org.springframework.ui.ModelMap`. | 用于访问HTML控制器中使用的模型，并作为视图渲染的一部分公开给模板。 |
| `@ModelAttribute`                                            | 用于访问已应用数据绑定和验证的模型中现有的属性（如果不存在，则进行实例化）。请参见@ModelAttribute以及Model和DataBinder。<br/><br/>请注意，@ ModelAttribute的使用是可选的，例如可以设置其属性。请参阅此表后面的“其他任何参数”。 |
| `Errors`, `BindingResult`                                    | 为了访问来自验证和命令对象数据绑定的错误，即@ModelAttribute参数。必须在经过验证的方法参数后立即声明Errors或BindingResult参数。 |
| `SessionStatus` + class-level `@SessionAttributes`           | 为了标记表单处理完成，将触发清除通过类级别@SessionAttributes注释声明的会话属性。有关更多详细信息，请参见@SessionAttributes。 |
| `UriComponentsBuilder`                                       | 用于准备相对于当前请求的主机，端口，方案和上下文路径的URL。请参阅URI链接。 |
| `@SessionAttribute`                                          | 用于访问任何会话属性-与通过类级别@SessionAttributes声明存储在会话中的模型属性相反。有关更多详细信息，请参见@SessionAttribute。 |
| `@RequestAttribute`                                          | 用于访问请求属性。有关更多详细信息，请参见@RequestAttribute。 |
| Any other argument                                           | 如果方法参数与以上任何参数都不匹配，则默认情况下，如果它是由BeanUtils＃isSimpleProperty确定的简单类型，则将其解析为@RequestParam，否则将其解析为@ModelAttribute。 |

##### Return Values

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-return-types)

下表显示了受支持的控制器方法返回值。请注意，所有返回值通常都支持Reactor，RxJava之类的库中的反应类型。

| Controller method return value                               | Description                                                  |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| `@ResponseBody`                                              | 返回值通过HttpMessageWriter实例进行编码，并写入响应中。请参阅@ResponseBody。 |
| `HttpEntity<B>`, `ResponseEntity<B>`                         | 返回值指定完整的响应，包括HTTP标头，并且正文通过HttpMessageWriter实例进行编码并写入响应。请参阅ResponseEntity。 |
| `HttpHeaders`                                                | 用于返回不包含标题的响应。                                   |
| `String`                                                     | 要用ViewResolver实例解析的视图名称，并与隐式模型一起使用-通过命令对象和@ModelAttribute方法确定。该处理程序方法还可以通过声明Model参数（如前所述）以编程方式丰富模型。 |
| `View`                                                       | 用于与隐式模型一起呈现的View实例，该隐式模型是通过命令对象和@ModelAttribute方法确定的。该处理程序方法还可以通过声明Model参数（如前所述）以编程方式丰富模型。 |
| `java.util.Map`, `org.springframework.ui.Model`              | 要添加到隐式模型的属性，其中视图名称根据请求路径隐式确定。   |
| `@ModelAttribute`                                            | 要添加到模型的属性，视图名称根据请求路径隐式确定。<br/><br/>请注意，@ ModelAttribute是可选的。请参阅此表后面的“其他任何返回值”。 |
| `Rendering`                                                  | 用于模型和视图渲染方案的API。                                |
| `void`                                                       | 如果方法也具有ServerHttpResponse，ServerWebExchange参数或@ResponseStatus，则该方法具有无效的，可能是异步的（例如，Mono ），返回类型（或返回值为空）的方法被认为已完全处理了响应。注解。如果控制器进行了肯定的ETag或lastModified时间戳检查，也是如此。 // TODO：有关详细信息，请参见控制器。<br/><br/>如果以上所有条件都不成立，则对于REST控制器，void返回类型也可以指示“无响应正文”，对于HTML控制器，则表示默认视图名称选择。 |
| `Flux<ServerSentEvent>`, `Observable<ServerSentEvent>`, or other reactive type | 发出服务器发送的事件。仅需要写入数据时，可以省略ServerSentEvent包装器（但是，必须通过Produces属性在映射中请求或声明文本/事件流）。 |
| Any other return value                                       | 如果返回值不符合以上任何条件，则默认情况下将其视为视图名称，为String或void（适用默认视图名称选择）或将其添加为模型的模型属性，除非它是由BeanUtils＃isSimpleProperty确定的简单类型，否则在这种情况下它将无法解析。 |

##### Type Conversion

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-typeconversion)

如果参数声明为String以外的其他内容，则表示基于String的请求输入的某些带注释的控制器方法参数（例如，@ RequestParam，@ RequestHeader，@ PathVariable，@ MatrixVariable和@CookieValue）可能需要类型转换。

在这种情况下，将根据配置的转换器自动应用类型转换。默认情况下，支持简单类型（例如int，long，Date和其他）。可以通过WebDataBinder（请参阅DataBinder）或通过向FormattingConversionService注册格式化程序（请参见Spring字段格式）来自定义类型转换。

类型转换中的一个实际问题是处理空的String源值。如果此值由于类型转换而变为null，则将其视为丢失。 Long，UUID和其他目标类型可能就是这种情况。如果要允许注入null，请在参数注释上使用必需的标志，或将参数声明为@Nullable。

##### Matrix Variables

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-matrix-variables)

RFC 3986讨论路径段中的名称/值对。在Spring WebFlux中，基于Tim Berners-Lee的“旧帖子”，我们将其称为“矩阵变量”，但它们也可以称为URI路径参数。

矩阵变量可以出现在任何路径段中，每个变量用分号分隔，多个值用逗号分隔，例如“ / cars; color = red，green; year = 2012”。也可以通过重复的变量名来指定多个值，例如“ color = red; color = green; color = blue”。

与Spring MVC不同，在WebFlux中，URL中是否存在矩阵变量不会影响请求映射。换句话说，您不需要使用URI变量来屏蔽变量内容。就是说，如果要从控制器方法访问矩阵变量，则需要将URI变量添加到期望矩阵变量的路径段中。以下示例显示了如何执行此操作：

```java
// GET /pets/42;q=11;r=22

@GetMapping("/pets/{petId}")
public void findPet(@PathVariable String petId, @MatrixVariable int q) {

    // petId == 42
    // q == 11
}
```

鉴于所有路径段都可以包含矩阵变量，因此有时可能需要消除矩阵变量应位于哪个路径变量的歧义，如以下示例所示：

```java
// GET /owners/42;q=11/pets/21;q=22

@GetMapping("/owners/{ownerId}/pets/{petId}")
public void findPet(
        @MatrixVariable(name="q", pathVar="ownerId") int q1,
        @MatrixVariable(name="q", pathVar="petId") int q2) {

    // q1 == 11
    // q2 == 22
}
```

您可以定义一个矩阵变量，可以将其定义为可选变量并指定一个默认值，如以下示例所示：

```java
// GET /pets/42

@GetMapping("/pets/{petId}")
public void findPet(@MatrixVariable(required=false, defaultValue="1") int q) {

    // q == 1
}
```

要获取所有矩阵变量，请使用MultiValueMap，如以下示例所示：

```java
// GET /owners/42;q=11;r=12/pets/21;q=22;s=23

@GetMapping("/owners/{ownerId}/pets/{petId}")
public void findPet(
        @MatrixVariable MultiValueMap<String, String> matrixVars,
        @MatrixVariable(pathVar="petId") MultiValueMap<String, String> petMatrixVars) {

    // matrixVars: ["q" : [11,22], "r" : 12, "s" : 23]
    // petMatrixVars: ["q" : 22, "s" : 23]
}
```

##### `@RequestParam`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestparam)

您可以使用@RequestParam批注将查询参数绑定到控制器中的方法参数。以下代码段显示了用法：

```java
@Controller
@RequestMapping("/pets")
public class EditPetForm {

    // ...

    @GetMapping
    public String setupForm(@RequestParam("petId") int petId, Model model) { 
        Pet pet = this.clinic.loadPet(petId);
        model.addAttribute("pet", pet);
        return "petForm";
    }

    // ...
}
```

默认情况下需要使用@RequestParam批注的方法参数，但是您可以通过将@RequestParam的required标志设置为false或通过使用java.util.Optional包装器声明参数来指定方法参数是可选的。

如果目标方法参数类型不是字符串，则将自动应用类型转换。请参阅类型转换。

在Map 或MultiValueMap 参数上声明@RequestParam批注时，将使用所有查询参数填充该映射。

请注意，@ RequestParam的使用是可选的，例如可以设置其属性。默认情况下，任何简单值类型的参数（由BeanUtils＃isSimpleProperty确定）并且没有被其他任何参数解析器解析，就如同使用@RequestParam进行了注释一样。

##### `@RequestHeader`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestheader)

您可以使用@RequestHeader批注将请求标头绑定到控制器中的方法参数。

以下示例显示了带有标头的请求：

```
Host                    localhost:8080
Accept                  text/html,application/xhtml+xml,application/xml;q=0.9
Accept-Language         fr,en-gb;q=0.7,en;q=0.3
Accept-Encoding         gzip,deflate
Accept-Charset          ISO-8859-1,utf-8;q=0.7,*;q=0.7
Keep-Alive              300
```

以下示例获取Accept-Encoding和Keep-Alive标头的值：

```java
@GetMapping("/demo")
public void handle(
        @RequestHeader("Accept-Encoding") String encoding, 
        @RequestHeader("Keep-Alive") long keepAlive) { 
    //...
}
```

在Map ，MultiValueMap 或HttpHeaders参数上使用@RequestHeader批注时，将使用所有标头值填充该映射。

##### `@CookieValue`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-cookievalue)

您可以使用@CookieValue批注将HTTP cookie的值绑定到控制器中的方法参数。

以下示例显示了一个带有cookie的请求：

```
JSESSIONID=415A4AC178C59DACE0B2C9CA727CDD84
```

以下代码示例演示如何获取cookie值：

```java
@GetMapping("/demo")
public void handle(@CookieValue("JSESSIONID") String cookie) { 
    //...
}
```

如果目标方法参数类型不是字符串，则将自动应用类型转换。请参阅类型转换。

##### `@ModelAttribute`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-modelattrib-method-args)

您可以在方法参数上使用@ModelAttribute批注，以从模型访问属性，或将其实例化（如果不存在）。 model属性还覆盖了名称与字段名称匹配的查询参数和表单字段的值。这称为数据绑定，它使您不必处理解析和转换单个查询参数和表单字段的工作。下面的示例绑定Pet的实例：

```java
@PostMapping("/owners/{ownerId}/pets/{petId}/edit")
public String processSubmit(@ModelAttribute Pet pet) { } 
```

前面示例中的Pet实例解析如下：

- 从模型（如果已通过Model添加）。
- 从HTTP会话通过@SessionAttributes。
- 从默认构造函数的调用开始。
- 从带有匹配查询参数或表单字段的参数的“主要构造函数”的调用开始。参数名称是通过JavaBeans @ConstructorProperties或字节码中运行时保留的参数名称确定的。

获取模型属性实例后，将应用数据绑定。 WebExchangeDataBinder类将查询参数和表单字段的名称与目标Object上的字段名称匹配。必要时在应用类型转换后填充匹配字段。有关数据绑定（和验证）的更多信息，请参见验证。有关自定义数据绑定的更多信息，请参见DataBinder。

数据绑定可能导致错误。默认情况下，引发WebExchangeBindException，但是，要检查控制器方法中的此类错误，可以在@ModelAttribute旁边立即添加BindingResult参数，如以下示例所示：

```java
@PostMapping("/owners/{ownerId}/pets/{petId}/edit")
public String processSubmit(@ModelAttribute("pet") Pet pet, BindingResult result) { 
    if (result.hasErrors()) {
        return "petForm";
    }
    // ...
}
```

您可以在数据绑定之后通过添加javax.validation.Valid注释或Spring的@Validated注释自动应用验证（另请参见Bean验证和Spring验证）。以下示例使用@Valid批注：

```java
@PostMapping("/owners/{ownerId}/pets/{petId}/edit")
public String processSubmit(@Valid @ModelAttribute("pet") Pet pet, BindingResult result) { 
    if (result.hasErrors()) {
        return "petForm";
    }
    // ...
}
```

与Spring MVC不同，Spring WebFlux在模型中支持反应性类型，例如Mono 或io.reactivex.Single 。您可以声明一个@ModelAttribute参数，带或不带反应性类型包装器，并将根据需要将其解析为实际值。但是，请注意，要使用BindingResult参数，必须在@ModelAttribute参数之前声明@ModelAttribute参数，而不必使用反应式类型包装器，如先前所示。另外，您可以通过反应式处理任何错误，如以下示例所示：

```java
@PostMapping("/owners/{ownerId}/pets/{petId}/edit")
public Mono<String> processSubmit(@Valid @ModelAttribute("pet") Mono<Pet> petMono) {
    return petMono
        .flatMap(pet -> {
            // ...
        })
        .onErrorResume(ex -> {
            // ...
        });
}
```

请注意，@ ModelAttribute的使用是可选的，例如可以设置其属性。默认情况下，任何不是简单值类型（由BeanUtils＃isSimpleProperty确定）且未被其他任何参数解析器解析的参数都将被视为使用@ModelAttribute注释。

##### `@SessionAttributes`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-sessionattributes)

@SessionAttributes用于在请求之间的WebSession中存储模型属性。它是类型级别的注释，用于声明特定控制器使用的会话属性。这通常列出应透明地存储在会话中以供后续访问请求的模型属性名称或模型属性类型。

考虑以下示例：

```java
@Controller
@SessionAttributes("pet") 
public class EditPetForm {
    // ...
}
```

在第一个请求上，将名称为pet的模型属性添加到模型后，该属性会自动升级到WebSession并保存在WebSession中。它会一直保留在那里，直到另一个控制器方法使用SessionStatus方法参数来清除存储，如以下示例所示：

```java
@Controller
@SessionAttributes("pet") 
public class EditPetForm {

    // ...

    @PostMapping("/pets/{id}")
    public String handle(Pet pet, BindingResult errors, SessionStatus status) { 
        if (errors.hasErrors()) {
            // ...
        }
            status.setComplete();
            // ...
        }
    }
}
```

##### `@SessionAttribute`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-sessionattribute)

如果您需要访问全局存在（例如，在控制器外部（例如，通过过滤器）管理）并且可能存在或可能不存在的预先存在的会话属性，则可以在方法参数上使用@SessionAttribute注释，以下示例显示：

```java
@GetMapping("/")
public String handle(@SessionAttribute User user) { 
    // ...
}
```

对于需要添加或删除会话属性的用例，请考虑将WebSession注入控制器方法中。

若要将模型属性作为控制器工作流的一部分临时存储在会话中，请考虑使用SessionAttributes，如@SessionAttributes中所述。

##### `@RequestAttribute`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestattrib)

与@SessionAttribute相似，您可以使用@RequestAttribute批注来访问先前创建的预先存在的请求属性（例如，通过WebFilter），如以下示例所示：

```java
@GetMapping("/")
public String handle(@RequestAttribute Client client) { 
    // ...
}
```

##### Multipart Content

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-multipart-forms)

如多部分数据中所述，ServerWebExchange提供对多部分内容的访问。在控制器中处理文件上传表单（例如，从浏览器）的最佳方法是通过将数据绑定到命令对象，如以下示例所示：

```java
class MyForm {

    private String name;

    private MultipartFile file;

    // ...

}

@Controller
public class FileUploadController {

    @PostMapping("/form")
    public String handleFormUpload(MyForm form, BindingResult errors) {
        // ...
    }

}
```

您还可以在RESTful服务方案中从非浏览器客户端提交多部分请求。以下示例将文件与JSON一起使用：

```
POST /someUrl
Content-Type: multipart/mixed

--edt7Tfrdusa7r3lNQc79vXuhIIMlatb7PQg7Vp
Content-Disposition: form-data; name="meta-data"
Content-Type: application/json; charset=UTF-8
Content-Transfer-Encoding: 8bit

{
    "name": "value"
}
--edt7Tfrdusa7r3lNQc79vXuhIIMlatb7PQg7Vp
Content-Disposition: form-data; name="file-data"; filename="file.properties"
Content-Type: text/xml
Content-Transfer-Encoding: 8bit
... File Data ...
```

您可以使用@RequestPart访问各个部分，如以下示例所示：

```java
@PostMapping("/")
public String handle(@RequestPart("meta-data") Part metadata, 
        @RequestPart("file-data") FilePart file) { 
    // ...
}
```

|      | Using `@RequestPart` to get the metadata. |
| ---- | ----------------------------------------- |
|      | Using `@RequestPart` to get the file.     |

要反序列化原始零件的内容（例如，转换为JSON（类似于@RequestBody）），可以声明一个具体的目标Object而不是Part，如以下示例所示：

```java
@PostMapping("/")
public String handle(@RequestPart("meta-data") MetaData metadata) { 
    // ...
}
```

您可以将@RequestPart与javax.validation.Valid或Spring的@Validated注释结合使用，这将导致应用标准Bean验证。验证错误导致WebExchangeBindException，该异常导致响应400（BAD_REQUEST）。异常包含具有错误详细信息的BindingResult，也可以在控制器方法中通过使用异步包装器声明参数，然后使用与错误相关的运算符来处理该异常：

```java
@PostMapping("/")
public String handle(@Valid @RequestPart("meta-data") Mono<MetaData> metadata) {
    // use one of the onError* operators...
}
```

要将所有多部分数据作为MultiValueMap进行访问，可以使用@RequestBody，如以下示例所示：

```java
@PostMapping("/")
public String handle(@RequestBody Mono<MultiValueMap<String, Part>> parts) { 
    // ...
}
```

要以流方式顺序访问多部分数据，可以将@RequestBody与Flux （或Kotlin中的Flow ）一起使用，如以下示例所示：

```java
@PostMapping("/")
public String handle(@RequestBody Flux<Part> parts) { 
    // ...
}
```

##### `@RequestBody`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestbody)

您可以使用@RequestBody批注使请求正文通过HttpMessageReader读取并反序列化为Object。以下示例使用@RequestBody参数：

```java
@PostMapping("/accounts")
public void handle(@RequestBody Account account) {
    // ...
}
```

与Spring MVC不同，在WebFlux中，@RequestBody方法参数支持反应类型以及完全无阻塞的读取和（客户端到服务器）流传输。

```java
@PostMapping("/accounts")
public void handle(@RequestBody Mono<Account> account) {
    // ...
}
```

您可以使用WebFlux Config的HTTP消息编解码器选项来配置或自定义消息阅读器。

您可以将@RequestBody与javax.validation.Valid或Spring的@Validated注释结合使用，这将导致应用标准Bean验证。验证错误会导致WebExchangeBindException，从而导致响应400（BAD_REQUEST）。异常包含具有错误详细信息的BindingResult，可以在控制器方法中通过使用异步包装器声明参数，然后使用与错误相关的运算符来处理该异常：

```java
@PostMapping("/accounts")
public void handle(@Valid @RequestBody Mono<Account> account) {
    // use one of the onError* operators...
}
```

##### `HttpEntity`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-httpentity)

HttpEntity或多或少与使用@RequestBody相同，但它基于公开请求标头和正文的容器对象。以下示例使用HttpEntity：

```java
@PostMapping("/accounts")
public void handle(HttpEntity<Account> entity) {
    // ...
}
```

##### `@ResponseBody`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-responsebody)

您可以在方法上使用@ResponseBody批注，以将返回值通过HttpMessageWriter序列化为响应主体。以下示例显示了如何执行此操作：

```java
@GetMapping("/accounts/{id}")
@ResponseBody
public Account handle() {
    // ...
}
```

在类级别还支持@ResponseBody，在这种情况下，所有控制器方法都将继承它。这就是@RestController的效果，它只不过是带有@Controller和@ResponseBody标记的元注释。

@ResponseBody支持反应类型，这意味着您可以返回Reactor或RxJava类型，并将它们产生的异步值呈现给响应。有关更多详细信息，请参见流和JSON呈现。

您可以将@ResponseBody方法与JSON序列化视图结合使用。有关详细信息，请参见Jackson JSON。

您可以使用WebFlux Config的HTTP消息编解码器选项来配置或自定义消息编写。

##### `ResponseEntity`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-responseentity)

ResponseEntity类似于@ResponseBody，但具有状态和标头。例如：

```java
@GetMapping("/something")
public ResponseEntity<String> handle() {
    String body = ... ;
    String etag = ... ;
    return ResponseEntity.ok().eTag(etag).build(body);
}
```

WebFlux支持使用单值反应类型异步生成ResponseEntity，和/或为主体使用单值和多值反应类型。

##### Jackson JSON

Spring提供了对Jackson JSON库的支持。

###### JSON Views

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-jackson)

Spring WebFlux为Jackson的序列化视图提供了内置支持，该视图仅呈现对象中所有字段的一部分。要将其与@ResponseBody或ResponseEntity控制器方法一起使用，可以使用Jackson的@JsonView批注来激活序列化视图类，如以下示例所示：

```java
@RestController
public class UserController {

    @GetMapping("/user")
    @JsonView(User.WithoutPasswordView.class)
    public User getUser() {
        return new User("eric", "7!jd#h23");
    }
}

public class User {

    public interface WithoutPasswordView {};
    public interface WithPasswordView extends WithoutPasswordView {};

    private String username;
    private String password;

    public User() {
    }

    public User(String username, String password) {
        this.username = username;
        this.password = password;
    }

    @JsonView(WithoutPasswordView.class)
    public String getUsername() {
        return this.username;
    }

    @JsonView(WithPasswordView.class)
    public String getPassword() {
        return this.password;
    }
}
```

@JsonView允许一组视图类，但是每个控制器方法只能指定一个。如果需要激活多个视图，请使用复合界面。

#### 1.4.4. `Model`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-modelattrib-methods)

您可以使用@ModelAttribute批注：

- 在@RequestMapping方法中的方法参数上，可从模型创建或访问对象，并将其通过WebDataBinder绑定到请求。
- 作为@Controller或@ControllerAdvice类中的方法级注释，有助于在任何@RequestMapping方法调用之前初始化模型。
- 在@RequestMapping方法上将其返回值标记为模型属性。

本节讨论@ModelAttribute方法，或前面列表中的第二项。控制器可以具有任意数量的@ModelAttribute方法。所有此类方法均在同一控制器中的@RequestMapping方法之前调用。也可以通过@ControllerAdvice在控制器之间共享@ModelAttribute方法。有关更多详细信息，请参见“控制器建议”部分。

@ModelAttribute方法具有灵活的方法签名。它们支持许多与@RequestMapping方法相同的参数（@ModelAttribute本身以及与请求正文相关的任何东西除外）。

以下示例使用@ModelAttribute方法：

```java
@ModelAttribute
public void populateModel(@RequestParam String number, Model model) {
    model.addAttribute(accountRepository.findAccount(number));
    // add more ...
}
```

以下示例仅添加一个属性：

```java
@ModelAttribute
public Account addAccount(@RequestParam String number) {
    return accountRepository.findAccount(number);
}
```

与Spring MVC不同，Spring WebFlux在模型中显式支持响应类型（例如Mono 或io.reactivex.Single ）。可以在@RequestMapping调用时将此类异步模型属性透明地解析（并更新模型）为其实际值，只要声明了@ModelAttribute参数而没有包装，如以下示例所示：

```java
@ModelAttribute
public void addAccount(@RequestParam String number) {
    Mono<Account> accountMono = accountRepository.findAccount(number);
    model.addAttribute("account", accountMono);
}

@PostMapping("/accounts")
public String handle(@ModelAttribute Account account, BindingResult errors) {
    // ...
}
```

此外，任何具有反应性类型包装器的模型属性都将在视图渲染之前解析为其实际值（并更新了模型）。

您也可以将@ModelAttribute用作@RequestMapping方法上的方法级注释，在这种情况下，@ RequestMapping方法的返回值将解释为模型属性。通常不需要这样做，因为它是HTML控制器的默认行为，除非返回值是一个String，否则它将被解释为视图名称。 @ModelAttribute还可以帮助自定义模型属性名称，如以下示例所示：

```java
@GetMapping("/accounts/{id}")
@ModelAttribute("myAccount")
public Account handle() {
    // ...
    return account;
}
```

#### 1.4.5. `DataBinder`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-initbinder)

@Controller或@ControllerAdvice类可以具有@InitBinder方法，以初始化WebDataBinder的实例。这些依次用于：

- 将请求参数（即表单数据或查询）绑定到模型对象。
- 将基于字符串的请求值（例如请求参数，路径变量，标头，Cookie等）转换为控制器方法参数的目标类型。
- 呈现HTML表单时，将模型对象的值格式化为String值。

@InitBinder方法可以注册特定于控制器的java.beans.PropertyEditor或Spring Converter和Formatter组件。此外，您可以使用WebFlux Java配置在全局共享的FormattingConversionService中注册Converter和Formatter类型。

@InitBinder方法支持与@RequestMapping方法相同的许多参数，除了@ModelAttribute（命令对象）参数。通常，它们使用WebDataBinder参数声明（用于注册）和空返回值。以下示例使用@InitBinder批注：

```java
@Controller
public class FormController {

    @InitBinder 
    public void initBinder(WebDataBinder binder) {
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
        dateFormat.setLenient(false);
        binder.registerCustomEditor(Date.class, new CustomDateEditor(dateFormat, false));
    }

    // ...
}
```

另外，当通过共享的FormattingConversionService使用基于Formatter的设置时，可以重新使用相同的方法并注册特定于控制器的Formatter实例，如以下示例所示：

```java
@Controller
public class FormController {

    @InitBinder
    protected void initBinder(WebDataBinder binder) {
        binder.addCustomFormatter(new DateFormatter("yyyy-MM-dd")); 
    }

    // ...
}
```

#### 1.4.6. Managing Exceptions

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-exceptionhandler)

@Controller和@ControllerAdvice类可以具有@ExceptionHandler方法来处理来自控制器方法的异常。下面的示例包括这样的处理程序方法：

```java
@Controller
public class SimpleController {

    // ...

    @ExceptionHandler 
    public ResponseEntity<String> handle(IOException ex) {
        // ...
    }
}
```

该异常可以与正在传播的顶级异常（即，引发直接IOException）匹配，也可以与顶级包装器异常（例如，包装在IllegalStateException内部的IOException）内的直接原因匹配。

对于匹配的异常类型，最好将目标异常声明为方法参数，如前面的示例所示。或者，注释声明可以缩小异常类型以使其匹配。我们通常建议在参数签名中尽可能具体，并在以相应顺序优先的@ControllerAdvice上声明您的主根异常映射。有关详细信息，请参见MVC部分。

HandlerAdapter为@RequestMapping方法提供了对Spring WebFlux中@ExceptionHandler方法的支持。有关更多详细信息，请参见DispatcherHandler。

##### REST API exceptions

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-rest-exceptions)

REST服务的常见要求是在响应正文中包含错误详细信息。 Spring框架不会自动这样做，因为响应主体中错误详细信息的表示是特定于应用程序的。但是，@ RestController可以将@ExceptionHandler方法与ResponseEntity返回值一起使用，以设置响应的状态和主体。也可以在@ControllerAdvice类中声明此类方法，以将其全局应用。

#### 1.4.7. Controller Advice

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-controller-advice)

通常，@ ExceptionHandler，@ InitBinder和@ModelAttribute方法在声明它们的@Controller类（或类层次结构）中适用。如果要使此类方法更全局地应用（跨控制器），则可以在带有@ControllerAdvice或@RestControllerAdvice注释的类中声明它们。

@ControllerAdvice带有@Component注释，这意味着可以通过组件扫描将此类注册为Spring Bean。 @RestControllerAdvice是由@ControllerAdvice和@ResponseBody注释的组合注释，这实际上意味着@ExceptionHandler方法通过消息转换（而不是视图分辨率或模板渲染）呈现到响应主体。

启动时，@ RequestMapping和@ExceptionHandler方法的基础结构类将检测使用@ControllerAdvice注释的Spring bean，然后在运行时应用其方法。全局@ExceptionHandler方法（来自@ControllerAdvice）在本地方法（来自@Controller）之后应用。相比之下，全局@ModelAttribute和@InitBinder方法在本地方法之前应用。

默认情况下，@ ControllerAdvice方法适用于每个请求（即所有控制器），但是您可以通过使用批注上的属性将其范围缩小到控制器的子集，如以下示例所示：

```java
// Target all Controllers annotated with @RestController
@ControllerAdvice(annotations = RestController.class)
public class ExampleAdvice1 {}

// Target all Controllers within specific packages
@ControllerAdvice("org.example.controllers")
public class ExampleAdvice2 {}

// Target all Controllers assignable to specific classes
@ControllerAdvice(assignableTypes = {ControllerInterface.class, AbstractController.class})
public class ExampleAdvice3 {}
```

前面示例中的选择器在运行时进行评估，如果广泛使用，可能会对性能产生负面影响。有关更多详细信息，请参见@ControllerAdvice javadoc。

### 1.5. Functional Endpoints

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn)

Spring WebFlux包含WebFlux.fn，这是一个轻量级的函数编程模型，其中的函数用于路由和处理请求，而契约则是为不变性而设计的。它是基于注释的编程模型的替代方案，但可以在相同的Reactive Core基础上运行。

#### 1.5.1. Overview

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn-overview)

在WebFlux.fn中，HTTP请求由HandlerFunction处理：该函数接受ServerRequest并返回延迟的ServerResponse（即Mono ）。请求和响应对象都具有不可变的协定，这些协定为JDK 8提供了对HTTP请求和响应的友好访问。 HandlerFunction等效于基于注释的编程模型中@RequestMapping方法的主体。

传入的请求通过RouterFunction路由到处理程序函数：该函数接受ServerRequest并返回延迟的HandlerFunction（即Mono ）。当路由器功能匹配时，返回处理程序功能。否则为空Mono。 RouterFunction等效于@RequestMapping批注，但主要区别在于路由器功能不仅提供数据，还提供行为。

RouterFunctions.route（）提供了一个路由器构建器，可简化路由器的创建过程，如以下示例所示：

```java
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.web.reactive.function.server.RequestPredicates.*;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;

PersonRepository repository = ...
PersonHandler handler = new PersonHandler(repository);

RouterFunction<ServerResponse> route = route()
    .GET("/person/{id}", accept(APPLICATION_JSON), handler::getPerson)
    .GET("/person", accept(APPLICATION_JSON), handler::listPeople)
    .POST("/person", handler::createPerson)
    .build();


public class PersonHandler {

    // ...

    public Mono<ServerResponse> listPeople(ServerRequest request) {
        // ...
    }

    public Mono<ServerResponse> createPerson(ServerRequest request) {
        // ...
    }

    public Mono<ServerResponse> getPerson(ServerRequest request) {
        // ...
    }
}
```

运行RouterFunction的一种方法是将其转换为HttpHandler并通过内置服务器适配器之一进行安装：

- `RouterFunctions.toHttpHandler(RouterFunction)`
- `RouterFunctions.toHttpHandler(RouterFunction, HandlerStrategies)`

大多数应用程序都可以通过WebFlux Java配置运行，请参阅运行服务器。

#### 1.5.2. HandlerFunction

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn-handler-functions)

ServerRequest和ServerResponse是不可变的接口，它们提供JDK 8友好的HTTP请求和响应访问。请求和响应都为反应流提供了对体流的反压力。请求主体用Reactor Flux或Mono表示。响应主体由任何Reactive Streams Publisher代表，包括Flux和Mono。有关更多信息，请参见反应式库。

##### ServerRequest

ServerRequest提供对HTTP方法，URI，标头和查询参数的访问，而通过body方法提供对主体的访问。

以下示例将请求正文提取到Mono ：

```java
Mono<String> string = request.bodyToMono(String.class);
```

以下示例将主体提取到Flux （或Kotlin中的Flow ），其中Person对象从某种序列化形式（例如JSON或XML）解码：

```java
Flux<Person> people = request.bodyToFlux(Person.class);
```

前面的示例是使用更通用的ServerRequest.body（BodyExtractor）的快捷方式，该请求接受BodyExtractor功能策略接口。实用程序类BodyExtractors提供对许多实例的访问。例如，前面的示例也可以编写如下：

```java
Mono<String> string = request.body(BodyExtractors.toMono(String.class));
Flux<Person> people = request.body(BodyExtractors.toFlux(Person.class));
```

下面的示例演示如何访问表单数据：

```java
Mono<MultiValueMap<String, String> map = request.formData();
```

以下示例显示了如何以map的形式访问multipart数据：

```java
Mono<MultiValueMap<String, Part> map = request.multipartData();
```

下面的示例演示如何以流方式一次访问多个部分：

```java
Flux<Part> parts = request.body(BodyExtractors.toParts());
```

##### ServerResponse

ServerResponse提供对HTTP响应的访问，并且由于它是不可变的，因此您可以使用构建方法来创建它。您可以使用构建器来设置响应状态，添加响应标题或提供正文。以下示例使用JSON内容创建200（确定）响应：

```java
Mono<Person> person = ...
ServerResponse.ok().contentType(MediaType.APPLICATION_JSON).body(person, Person.class);
```

下面的示例演示如何构建一个具有Location标头且没有正文的201（已创建）响应：

```java
URI location = ...
ServerResponse.created(location).build();
```

根据所使用的编解码器，可以传递提示参数以自定义主体的序列化或反序列化方式。例如，要指定Jackson JSON视图：

```java
ServerResponse.ok().hint(Jackson2CodecSupport.JSON_VIEW_HINT, MyJacksonView.class).body(...);
```

##### Handler Classes

我们可以将处理程序函数编写为lambda，如以下示例所示：

```java
HandlerFunction<ServerResponse> helloWorld =
  request -> ServerResponse.ok().bodyValue("Hello World");
```

这很方便，但是在应用程序中我们需要多个功能，并且多个内联lambda可能会变得凌乱。因此，将相关的处理程序功能分组到一个处理程序类中很有用，该类的作用与基于注释的应用程序中的@Controller相似。例如，以下类公开了反应型Person存储库：

```java
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.web.reactive.function.server.ServerResponse.ok;

public class PersonHandler {

    private final PersonRepository repository;

    public PersonHandler(PersonRepository repository) {
        this.repository = repository;
    }

    public Mono<ServerResponse> listPeople(ServerRequest request) { 
        Flux<Person> people = repository.allPeople();
        return ok().contentType(APPLICATION_JSON).body(people, Person.class);
    }

    public Mono<ServerResponse> createPerson(ServerRequest request) { 
        Mono<Person> person = request.bodyToMono(Person.class);
        return ok().build(repository.savePerson(person));
    }

    public Mono<ServerResponse> getPerson(ServerRequest request) { 
        int personId = Integer.valueOf(request.pathVariable("id"));
        return repository.getPerson(personId)
            .flatMap(person -> ok().contentType(APPLICATION_JSON).bodyValue(person))
            .switchIfEmpty(ServerResponse.notFound().build());
    }
}
```

##### Validation

功能端点可以使用Spring的验证工具将验证应用于请求正文。例如，给定Person的自定义Spring Validator实现：

```java
public class PersonHandler {

    private final Validator validator = new PersonValidator(); 

    // ...

    public Mono<ServerResponse> createPerson(ServerRequest request) {
        Mono<Person> person = request.bodyToMono(Person.class).doOnNext(this::validate); 
        return ok().build(repository.savePerson(person));
    }

    private void validate(Person person) {
        Errors errors = new BeanPropertyBindingResult(person, "person");
        validator.validate(person, errors);
        if (errors.hasErrors()) {
            throw new ServerWebInputException(errors.toString()); 
        }
    }
}
```

处理程序还可以通过基于LocalValidatorFactoryBean创建和注入全局Validator实例来使用标准的bean验证API（JSR-303）。请参阅春季验证。

#### 1.5.3. `RouterFunction`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn-router-functions)

路由器功能用于将请求路由到相应的HandlerFunction。通常，您不是自己编写路由器功能，而是使用RouterFunctions实用工具类上的方法创建一个。 RouterFunctions.route（）（无参数）为您提供了一个流畅的生成器来创建路由器功能，而RouterFunctions.route（RequestPredicate，HandlerFunction）提供了直接创建路由器的方法。

通常，建议使用route（）生成器，因为它为典型的映射方案提供了便捷的快捷方式，而无需发现静态导入。例如，路由器功能构建器提供了GET（String，HandlerFunction）方法来创建GET请求的映射。和POST（String，HandlerFunction）进行POST。

除了基于HTTP方法的映射外，路由构建器还提供了一种在映射到请求时引入其他谓词的方法。对于每个HTTP方法，都有一个以RequestPredicate作为参数的重载变体，尽管可以表达其他约束。

##### Predicates

您可以编写自己的RequestPredicate，但是RequestPredicates实用程序类根据请求路径，HTTP方法，内容类型等提供常用的实现。以下示例使用请求谓词基于Accept头创建约束：

```java
RouterFunction<ServerResponse> route = RouterFunctions.route()
    .GET("/hello-world", accept(MediaType.TEXT_PLAIN),
        request -> ServerResponse.ok().bodyValue("Hello World")).build();
```

您可以使用以下命令组合多个请求谓词：

- `RequestPredicate.and(RequestPredicate)` — both must match.
- `RequestPredicate.or(RequestPredicate)` — either can match.

RequestPredicates中的许多谓词都是组成的。例如，RequestPredicates.GET（String）由RequestPredicates.method（HttpMethod）和RequestPredicates.path（String）组成。上面显示的示例还使用了两个请求谓词，因为构建器在内部使用RequestPredicates.GET并将其与接受谓词组合在一起。

##### Routes

路由器功能按顺序评估：如果第一个路由不匹配，则评估第二个路由，依此类推。因此，在通用路由之前声明更具体的路由是有意义的。请注意，此行为不同于基于注释的编程模型，在该模型中，将自动选择“最特定”的控制器方法。

使用路由器功能生成器时，所有定义的路由都组成一个RouterFunction，从build（）返回。还有其他方法可以将多个路由器功能组合在一起：

- `add(RouterFunction)` on the `RouterFunctions.route()` builder
- `RouterFunction.and(RouterFunction)`
- `RouterFunction.andRoute(RequestPredicate, HandlerFunction)` — shortcut for `RouterFunction.and()` with nested `RouterFunctions.route()`.

以下示例显示了四种路线的组成：

```java
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.web.reactive.function.server.RequestPredicates.*;

PersonRepository repository = ...
PersonHandler handler = new PersonHandler(repository);

RouterFunction<ServerResponse> otherRoute = ...

RouterFunction<ServerResponse> route = route()
    .GET("/person/{id}", accept(APPLICATION_JSON), handler::getPerson) 
    .GET("/person", accept(APPLICATION_JSON), handler::listPeople) 
    .POST("/person", handler::createPerson) 
    .add(otherRoute) 
    .build();
```

##### Nested Routes

一组路由器功能通常具有共享谓词，例如共享路径。在上面的示例中，共享谓词将是与/ person匹配的路径谓词，由三个路由使用。使用注释时，您可以通过使用映射到/ person的类型级别@RequestMapping注释来删除此重复项。在WebFlux.fn中，可以通过路由器功能构建器上的path方法共享路径谓词。例如，可以通过以下方式使用嵌套路由来改进上面示例的最后几行：

```java
RouterFunction<ServerResponse> route = route()
    .path("/person", builder -> builder 
        .GET("/{id}", accept(APPLICATION_JSON), handler::getPerson)
        .GET(accept(APPLICATION_JSON), handler::listPeople)
        .POST("/person", handler::createPerson))
    .build();
```

尽管基于路径的嵌套是最常见的，但是您可以通过使用构建器上的nest方法来嵌套在任何种类的谓词上。上面的内容仍然包含一些以共享的Accept-header谓词形式出现的重复。我们可以通过将nest方法与accept一起使用来进一步改进：

```java
RouterFunction<ServerResponse> route = route()
    .path("/person", b1 -> b1
        .nest(accept(APPLICATION_JSON), b2 -> b2
            .GET("/{id}", handler::getPerson)
            .GET(handler::listPeople))
        .POST("/person", handler::createPerson))
    .build();
```

#### 1.5.4. Running a Server

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn-running)

如何在HTTP服务器中运行路由器功能？一个简单的选项是使用以下方法之一将路由器功能转换为HttpHandler：

- `RouterFunctions.toHttpHandler(RouterFunction)`
- `RouterFunctions.toHttpHandler(RouterFunction, HandlerStrategies)`

然后，可以通过遵循HttpHandler来获取特定于服务器的指令，将返回的HttpHandler与许多服务器适配器一起使用。

Spring Boot还使用了一个更典型的选项，即通过WebFlux Config与基于DispatcherHandler的设置一起运行，该配置使用Spring配置来声明处理请求所需的组件。 WebFlux Java配置声明以下基础结构组件以支持功能端点：

- RouterFunctionMapping：在Spring配置中检测一个或多个RouterFunction <？> bean，通过RouterFunction.andOther组合它们，并将请求路由到生成的组成RouterFunction。
- HandlerFunctionAdapter：简单的适配器，它使DispatcherHandler调用映射到请求的HandlerFunction。
- ServerResponseResultHandler：通过调用ServerResponse的writeTo方法来处理HandlerFunction调用的结果。

前面的组件使功能端点适合于DispatcherHandler请求处理生命周期，并且（可能）与带注释的控制器（如果已声明）并排运行。这也是Spring Boot WebFlux启动器启用功能端点的方式。

以下示例显示了WebFlux Java配置（有关如何运行它，请参见DispatcherHandler）：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Bean
    public RouterFunction<?> routerFunctionA() {
        // ...
    }

    @Bean
    public RouterFunction<?> routerFunctionB() {
        // ...
    }

    // ...

    @Override
    public void configureHttpMessageCodecs(ServerCodecConfigurer configurer) {
        // configure message conversion...
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        // configure CORS...
    }

    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        // configure view resolution for HTML rendering...
    }
}
```

#### 1.5.5. Filtering Handler Functions

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn-handler-filter-function)

您可以通过使用路由功能构建器上的before，after或filter方法来过滤处理程序函数。使用注释，可以通过使用@ ControllerAdvice，ServletFilter或同时使用两者来实现类似的功能。该过滤器将应用于构建器构建的所有路由。这意味着在嵌套路由中定义的过滤器不适用于“顶级”路由。例如，考虑以下示例：

```java
RouterFunction<ServerResponse> route = route()
    .path("/person", b1 -> b1
        .nest(accept(APPLICATION_JSON), b2 -> b2
            .GET("/{id}", handler::getPerson)
            .GET(handler::listPeople)
            .before(request -> ServerRequest.from(request) 
                .header("X-RequestHeader", "Value")
                .build()))
        .POST("/person", handler::createPerson))
    .after((request, response) -> logResponse(response)) 
    .build();
```

路由器构建器上的filter方法采用HandlerFilterFunction：该函数采用ServerRequest和HandlerFunction并返回ServerResponse。 handler函数参数代表链中的下一个元素。这通常是路由到的处理程序，但是如果应用了多个，它也可以是另一个过滤器。

现在，我们可以在路由中添加一个简单的安全过滤器，假设我们拥有一个可以确定是否允许特定路径的SecurityManager。以下示例显示了如何执行此操作：

```java
SecurityManager securityManager = ...

RouterFunction<ServerResponse> route = route()
    .path("/person", b1 -> b1
        .nest(accept(APPLICATION_JSON), b2 -> b2
            .GET("/{id}", handler::getPerson)
            .GET(handler::listPeople))
        .POST("/person", handler::createPerson))
    .filter((request, next) -> {
        if (securityManager.allowAccessTo(request.path())) {
            return next.handle(request);
        }
        else {
            return ServerResponse.status(UNAUTHORIZED).build();
        }
    })
    .build();
```

前面的示例演示了调用next.handle（ServerRequest）是可选的。我们只允许在允许访问时运行处理程序函数。

除了在路由器功能构建器上使用filter方法之外，还可以通过RouterFunction.filter（HandlerFilterFunction）将过滤器应用于现有路由器功能。

### 1.6. URI Links

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-uri-building)

本节描述了Spring框架中用于准备URI的各种选项。

#### 1.6.1. UriComponents

Spring MVC and Spring WebFlux

UriComponentsBuilder有助于从具有变量的URI模板中构建URI，如以下示例所示：

```java
UriComponents uriComponents = UriComponentsBuilder
        .fromUriString("https://example.com/hotels/{hotel}")  
        .queryParam("q", "{q}")  
        .encode() 
        .build(); 

URI uri = uriComponents.expand("Westin", "123").toUri();  
```

可以将前面的示例合并为一个链，并通过buildAndExpand进行缩短，如以下示例所示：

```java
URI uri = UriComponentsBuilder
        .fromUriString("https://example.com/hotels/{hotel}")
        .queryParam("q", "{q}")
        .encode()
        .buildAndExpand("Westin", "123")
        .toUri();
```

您可以通过直接转到URI（这意味着编码）来进一步缩短它，如以下示例所示：

```java
URI uri = UriComponentsBuilder
        .fromUriString("https://example.com/hotels/{hotel}")
        .queryParam("q", "{q}")
        .build("Westin", "123");
```

您可以使用完整的URI模板进一步缩短它，如以下示例所示：

```java
URI uri = UriComponentsBuilder
        .fromUriString("https://example.com/hotels/{hotel}?q={q}")
        .build("Westin", "123");
```

#### 1.6.2. UriBuilder

Spring MVC and Spring WebFlux

riComponentsBuilder实现UriBuilder。您可以依次使用UriBuilderFactory创建UriBuilder。 UriBuilderFactory和UriBuilder一起提供了一种可插入的机制，可以基于共享配置（例如基本URL，编码首选项和其他详细信息）从URI模板构建URI。

您可以使用UriBuilderFactory配置RestTemplate和WebClient以自定义URI的准备。 DefaultUriBuilderFactory是UriBuilderFactory的默认实现，该实现在内部使用UriComponentsBuilder并公开共享的配置选项。

以下示例显示如何配置RestTemplate：

```java
// import org.springframework.web.util.DefaultUriBuilderFactory.EncodingMode;

String baseUrl = "https://example.org";
DefaultUriBuilderFactory factory = new DefaultUriBuilderFactory(baseUrl);
factory.setEncodingMode(EncodingMode.TEMPLATE_AND_VALUES);

RestTemplate restTemplate = new RestTemplate();
restTemplate.setUriTemplateHandler(factory);
```

下面的示例配置一个WebClient：

```java
// import org.springframework.web.util.DefaultUriBuilderFactory.EncodingMode;

String baseUrl = "https://example.org";
DefaultUriBuilderFactory factory = new DefaultUriBuilderFactory(baseUrl);
factory.setEncodingMode(EncodingMode.TEMPLATE_AND_VALUES);

WebClient client = WebClient.builder().uriBuilderFactory(factory).build();
```

此外，您也可以直接使用DefaultUriBuilderFactory。它类似于使用UriComponentsBuilder，但不是静态工厂方法，而是一个包含配置和首选项的实际实例，如以下示例所示：

```java
String baseUrl = "https://example.com";
DefaultUriBuilderFactory uriBuilderFactory = new DefaultUriBuilderFactory(baseUrl);

URI uri = uriBuilderFactory.uriString("/hotels/{hotel}")
        .queryParam("q", "{q}")
        .build("Westin", "123");
```

#### 1.6.3. URI Encoding

Spring MVC and Spring WebFlux

UriComponentsBuilder在两个级别公开了编码选项：

- [UriComponentsBuilder#encode()](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/util/UriComponentsBuilder.html#encode--): 首先对URI模板进行预编码，然后在扩展时严格对URI变量进行编码。
- [UriComponents#encode()](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/util/UriComponents.html#encode--): 扩展URI变量后，对URI组件进行编码。

这两个选项都使用转义的八位字节替换非ASCII和非法字符。但是，第一个选项还会替换出现在URI变量中的具有保留含义的字符。

在大多数情况下，第一个选项可能会产生预期的结果，因为它将URI变量视为要完全编码的不透明数据，而选项2仅在URI变量有意包含保留字符的情况下才有用。

以下示例使用第一个选项：

```java
URI uri = UriComponentsBuilder.fromPath("/hotel list/{city}")
        .queryParam("q", "{q}")
        .encode()
        .buildAndExpand("New York", "foo+bar")
        .toUri();

// Result is "/hotel%20list/New%20York?q=foo%2Bbar"
```

您可以通过直接转到URI（这意味着编码）来缩短前面的示例，如以下示例所示：

```java
URI uri = UriComponentsBuilder.fromPath("/hotel list/{city}")
        .queryParam("q", "{q}")
        .build("New York", "foo+bar")
```

您可以使用完整的URI模板进一步缩短它，如以下示例所示：

```java
URI uri = UriComponentsBuilder.fromPath("/hotel list/{city}?q={q}")
        .build("New York", "foo+bar")
```

WebClient和RestTemplate通过UriBuilderFactory策略在内部扩展和编码URI模板。两者都可以使用自定义策略进行配置。如下例所示：

```java
String baseUrl = "https://example.com";
DefaultUriBuilderFactory factory = new DefaultUriBuilderFactory(baseUrl)
factory.setEncodingMode(EncodingMode.TEMPLATE_AND_VALUES);

// Customize the RestTemplate..
RestTemplate restTemplate = new RestTemplate();
restTemplate.setUriTemplateHandler(factory);

// Customize the WebClient..
WebClient client = WebClient.builder().uriBuilderFactory(factory).build();
```

DefaultUriBuilderFactory实现在内部使用UriComponentsBuilder来扩展和编码URI模板。作为工厂，它提供了一个位置，可以根据以下一种编码模式来配置编码方法：

- TEMPLATE_AND_VALUES：使用UriComponentsBuilder＃encode（）（对应于较早列表中的第一个选项）对URI模板进行预编码，并在扩展时严格编码URI变量。
- VALUES_ONLY：不对URI模板进行编码，而是在将其扩展到模板之前通过UriUtils＃encodeUriUriVariables对URI变量进行严格编码。
- URI_COMPONENT：在扩展URI变量后，使用UriComponents＃encode（）（对应于先前列表中的第二个选项）对URI组件值进行编码。
- NONE：未应用编码。

由于历史原因和向后兼容性，将RestTemplate设置为EncodingMode.URI_COMPONENT。 WebClient依赖于DefaultUriBuilderFactory中的默认值，该默认值已从5.0.x中的EncodingMode.URI_COMPONENT更改为5.1中的EncodingMode.TEMPLATE_AND_VALUES。

### 1.7. CORS

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors)

Spring WebFlux使您可以处理CORS（跨源资源共享）。本节介绍如何执行此操作。

#### 1.7.1. Introduction

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors-intro)

出于安全原因，浏览器禁止AJAX调用当前来源以外的资源。例如，您可以在一个标签页中拥有您的银行帐户，而在另一个标签页中拥有evil.com。来自evil.com的脚本不应使用您的凭据向您的银行API发出AJAX请求。例如，从您的帐户中提取资金！

跨域资源共享（CORS）是由大多数浏览器实现的W3C规范，可让您指定授权哪种类型的跨域请求，而不是使用基于IFRAME或JSONP的安全性较低且功能较弱的变通办法。

#### 1.7.2. Processing

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors-processing)

CORS规范区准备阶段，简单和实际要求。要了解CORS的工作原理，您可以阅读本文以及其他内容，或者参阅规范以获取更多详细信息。

Spring WebFlux HandlerMapping实现为CORS提供内置支持。成功将请求映射到处理程序后，HandlerMapping将检查给定请求和处理程序的CORS配置，并采取进一步的措施。飞行前请求直接处理，而简单和实际的CORS请求被拦截，验证并设置了所需的CORS响应标头。

为了启用跨域请求（即存在Origin标头，并且与请求的主机不同），您需要具有一些显式声明的CORS配置。如果找不到匹配的CORS配置，则飞行前请求将被拒绝。没有将CORS标头添加到简单和实际CORS请求的响应中，因此，浏览器拒绝了它们。

可以使用基于URL模式的CorsConfiguration映射分别配置每个HandlerMapping。在大多数情况下，应用程序使用WebFlux Java配置声明此类映射，从而导致将单个全局映射传递给所有HandlerMapping实现。

您可以将HandlerMapping级别的全局CORS配置与更细粒度的处理程序级别的CORS配置结合使用。例如，带注释的控制器可以使用类或方法级别的@CrossOrigin注释（其他处理程序可以实现CorsConfigurationSource）。

全局和本地配置组合的规则通常是相加的，例如，所有全局和所有本地起源。对于只能接受单个值的那些属性（例如allowCredentials和maxAge），局部属性将覆盖全局值。有关更多详细信息，请参见CorsConfiguration＃combine（CorsConfiguration）。

#### 1.7.3. `@CrossOrigin`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors-controller)

@CrossOrigin批注启用带注释的控制器方法上的跨域请求，如以下示例所示：

```java
@RestController
@RequestMapping("/account")
public class AccountController {

    @CrossOrigin
    @GetMapping("/{id}")
    public Mono<Account> retrieve(@PathVariable Long id) {
        // ...
    }

    @DeleteMapping("/{id}")
    public Mono<Void> remove(@PathVariable Long id) {
        // ...
    }
}
```

By default, `@CrossOrigin` allows:

- All origins.
- All headers.
- All HTTP methods to which the controller method is mapped.

默认情况下，allowCredentials未启用，因为它建立了一个信任级别，可以公开敏感的用户特定信息（例如cookie和CSRF令牌），并且仅在适当的地方使用。启用后，必须将allowOrigins设置为一个或多个特定域（而不是特殊值“ *”），或者可将allowOriginPatterns属性用于匹配动态的一组原点。

maxAge设置为30分钟。

在类级别也支持@CrossOrigin，并且所有方法都继承了@CrossOrigin。以下示例指定了一个特定域，并将maxAge设置为一个小时：

```java
@CrossOrigin(origins = "https://domain2.com", maxAge = 3600)
@RestController
@RequestMapping("/account")
public class AccountController {

    @GetMapping("/{id}")
    public Mono<Account> retrieve(@PathVariable Long id) {
        // ...
    }

    @DeleteMapping("/{id}")
    public Mono<Void> remove(@PathVariable Long id) {
        // ...
    }
}
```

您可以在类和方法级别使用@CrossOrigin，如以下示例所示：

```java
@CrossOrigin(maxAge = 3600) 
@RestController
@RequestMapping("/account")
public class AccountController {

    @CrossOrigin("https://domain2.com") 
    @GetMapping("/{id}")
    public Mono<Account> retrieve(@PathVariable Long id) {
        // ...
    }

    @DeleteMapping("/{id}")
    public Mono<Void> remove(@PathVariable Long id) {
        // ...
    }
}
```

#### 1.7.4. Global Configuration

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors-global)

除了细粒度的控制器方法级配置外，您可能还想定义一些全局CORS配置。您可以在任何HandlerMapping上分别设置基于URL的CorsConfiguration映射。但是，大多数应用程序都使用WebFlux Java配置来执行此操作。

默认情况下，全局配置启用以下功能：

- All origins.
- All headers.
- `GET`, `HEAD`, and `POST` methods.

默认情况下，allowedCredentials未启用，因为它建立了一个信任级别，可以公开敏感的用户特定信息（例如cookie和CSRF令牌），并且仅在适当的地方使用。启用后，必须将allowOrigins设置为一个或多个特定域（而不是特殊值“ *”），或者可将allowOriginPatterns属性用于匹配动态的一组原点。

maxAge设置为30分钟。

要在WebFlux Java配置中启用CORS，可以使用CorsRegistry回调，如以下示例所示：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {

        registry.addMapping("/api/**")
            .allowedOrigins("https://domain2.com")
            .allowedMethods("PUT", "DELETE")
            .allowedHeaders("header1", "header2", "header3")
            .exposedHeaders("header1", "header2")
            .allowCredentials(true).maxAge(3600);

        // Add more mappings...
    }
}
```

#### 1.7.5. CORS `WebFilter`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors-filter)

您可以通过内置的CorsWebFilter应用CORS支持，该功能非常适合功能性端点。

|      | If you try to use the `CorsFilter` with Spring Security, keep in mind that Spring Security has [built-in support](https://docs.spring.io/spring-security/site/docs/current/reference/htmlsingle/#cors) for CORS. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

要配置过滤器，可以声明一个CorsWebFilter bean并将CorsConfigurationSource传递给其构造函数，如以下示例所示：

```java
@Bean
CorsWebFilter corsFilter() {

    CorsConfiguration config = new CorsConfiguration();

    // Possibly...
    // config.applyPermitDefaultValues()

    config.setAllowCredentials(true);
    config.addAllowedOrigin("https://domain1.com");
    config.addAllowedHeader("*");
    config.addAllowedMethod("*");

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", config);

    return new CorsWebFilter(source);
}
```

### 1.8. Web Security

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-web-security)

Spring Security项目为保护Web应用程序免受恶意利用提供了支持。请参阅Spring Security参考文档，包括：

- [WebFlux Security](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#jc-webflux)
- [WebFlux Testing Support](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#test-webflux)
- [CSRF Protection](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#csrf)
- [Security Response Headers](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#headers)

### 1.9. View Technologies

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view)

Spring WebFlux中视图技术的使用是可插入的。是否决定使用Thymeleaf，FreeMarker或其他某种视图技术主要取决于配置更改。本章介绍了与Spring WebFlux集成的视图技术。我们假设您已经熟悉View Resolution。

#### 1.9.1. Thymeleaf

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-thymeleaf)

Thymeleaf是一种现代的服务器端Java模板引擎，它强调可以通过双击在浏览器中预览的自然HTML模板，这对于独立处理UI模板（例如，由设计人员）非常有用，而无需使用正在运行的服务器。 Thymeleaf提供了广泛的功能集，并且正在积极地开发和维护。有关更完整的介绍，请参见Thymeleaf项目主页。

Thymeleaf与Spring WebFlux的集成由Thymeleaf项目管理。该配置涉及一些bean声明，例如SpringResourceTemplateResolver，SpringWebFluxTemplateEngine和ThymeleafReactiveViewResolver。有关更多详细信息，请参见Thymeleaf + Spring和WebFlux集成公告。

#### 1.9.2. FreeMarker

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-freemarker)

Apache FreeMarker是一个模板引擎，用于生成从HTML到电子邮件等的任何类型的文本输出。 Spring框架具有内置的集成，可以将Spring WebFlux与FreeMarker模板一起使用。

##### View Configuration

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-freemarker-contextconfig)

以下示例显示了如何将FreeMarker配置为一种视图技术：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        registry.freeMarker();
    }

    // Configure FreeMarker...

    @Bean
    public FreeMarkerConfigurer freeMarkerConfigurer() {
        FreeMarkerConfigurer configurer = new FreeMarkerConfigurer();
        configurer.setTemplateLoaderPath("classpath:/templates/freemarker");
        return configurer;
    }
}
```

您的模板需要存储在FreeMarkerConfigurer指定的目录中，如上例所示。给定上述配置，如果您的控制器返回视图名称welcome，则解析程序将查找类路径：/templates/freemarker/welcome.ftl模板。

##### FreeMarker Configuration

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-freemarker)

您可以通过在FreeMarkerConfigurer bean上设置适当的bean属性，将FreeMarker的“设置”和“ SharedVariables”直接传递给FreeMarker配置对象（由Spring管理）。 freemarkerSettings属性需要一个java.util.Properties对象，而freemarkerVariables属性需要一个java.util.Map。以下示例显示了如何使用FreeMarkerConfigurer：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    // ...

    @Bean
    public FreeMarkerConfigurer freeMarkerConfigurer() {
        Map<String, Object> variables = new HashMap<>();
        variables.put("xml_escape", new XmlEscape());

        FreeMarkerConfigurer configurer = new FreeMarkerConfigurer();
        configurer.setTemplateLoaderPath("classpath:/templates");
        configurer.setFreemarkerVariables(variables);
        return configurer;
    }
}
```

有关设置和变量应用于Configuration对象的详细信息，请参见FreeMarker文档。

##### Form Handling

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-freemarker-forms)

Spring提供了一个供JSP使用的标签库，其中包含一个元素。该元素主要允许表单显示来自表单支持对象的值，并显示来自Web或业务层中Validator的验证失败的结果。 Spring还支持FreeMarker中的相同功能，并带有用于生成表单输入元素本身的附加便利宏。

###### The Bind Macros

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-bind-macros)

FreeMarker的spring-webflux.jar文件中维护了一组标准宏，因此它们始终可用于经过适当配置的应用程序。

Spring模板库中定义的某些宏被视为内部（私有）宏，但是在宏定义中不存在这种范围，使所有宏对调用代码和用户模板可见。以下各节仅关注您需要从模板内直接调用的宏。如果您希望直接查看宏代码，则该文件名为spring.ftl，位于org.springframework.web.reactive.result.view.freemarker包中。

有关绑定支持的更多详细信息，请参见Spring MVC的简单绑定。

###### Form Macros

有关Spring对FreeMarker模板的表单宏支持的详细信息，请参阅Spring MVC文档的以下部分。

- [Input Macros](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-form-macros)
- [Input Fields](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-form-macros-input)
- [Selection Fields](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-form-macros-select)
- [HTML Escaping](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-form-macros-html-escaping)

#### 1.9.3. Script Views

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-script)

Spring框架具有内置的集成，可以将Spring WebFlux与可以在JSR-223 Java脚本引擎之上运行的任何模板库一起使用。下表显示了我们在不同脚本引擎上测试过的模板库：

| Scripting Library                                            | Scripting Engine                                      |
| :----------------------------------------------------------- | :---------------------------------------------------- |
| [Handlebars](https://handlebarsjs.com/)                      | [Nashorn](https://openjdk.java.net/projects/nashorn/) |
| [Mustache](https://mustache.github.io/)                      | [Nashorn](https://openjdk.java.net/projects/nashorn/) |
| [React](https://facebook.github.io/react/)                   | [Nashorn](https://openjdk.java.net/projects/nashorn/) |
| [EJS](https://www.embeddedjs.com/)                           | [Nashorn](https://openjdk.java.net/projects/nashorn/) |
| [ERB](https://www.stuartellis.name/articles/erb/)            | [JRuby](https://www.jruby.org/)                       |
| [String templates](https://docs.python.org/2/library/string.html#template-strings) | [Jython](https://www.jython.org/)                     |
| [Kotlin Script templating](https://github.com/sdeleuze/kotlin-script-templating) | [Kotlin](https://kotlinlang.org/)                     |

##### Requirements

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-script-dependencies)

您需要在类路径上具有脚本引擎，其细节因脚本引擎而异：

- Java 8+随附了Nashorn JavaScript引擎。强烈建议使用可用的最新更新版本。
- [JRuby](https://www.jruby.org/) 应该将JRuby添加为对Ruby支持的依赖。
- [Jython](https://www.jython.org/) 应该添加为对Python支持的依赖。
- `org.jetbrains.kotlin:kotlin-script-util` dependency and a `META-INF/services/javax.script.ScriptEngineFactory` file containing a `org.jetbrains.kotlin.script.jsr223.KotlinJsr223JvmLocalScriptEngineFactory` line should be added for Kotlin script support. See [this example](https://github.com/sdeleuze/kotlin-script-templating) for more detail.

您需要具有脚本模板库。针对Javascript的一种方法是通过WebJars。

##### Script Templates

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-script-integrate)

您可以声明一个ScriptTemplateConfigurer bean来指定要使用的脚本引擎，要加载的脚本文件，调用呈现模板的函数等等。以下示例使用Mustache模板和Nashorn JavaScript引擎：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        registry.scriptTemplate();
    }

    @Bean
    public ScriptTemplateConfigurer configurer() {
        ScriptTemplateConfigurer configurer = new ScriptTemplateConfigurer();
        configurer.setEngineName("nashorn");
        configurer.setScripts("mustache.js");
        configurer.setRenderObject("Mustache");
        configurer.setRenderFunction("render");
        return configurer;
    }
}
```

使用以下参数调用render函数：

- `String template`: The template content
- `Map model`: The view model
- `RenderingContext renderingContext`: The [`RenderingContext`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/servlet/view/script/RenderingContext.html) that gives access to the application context, the locale, the template loader, and the URL (since 5.0)

Mustache.render（）与该签名本地兼容，因此您可以直接调用它。

如果您的模板技术需要一些自定义，则可以提供一个实现自定义渲染功能的脚本。例如，Handlerbars需要在使用模板之前先对其进行编译，并且需要使用polyfill来模拟服务器端脚本引擎中不可用的某些浏览器功能。以下示例显示如何设置自定义渲染功能：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        registry.scriptTemplate();
    }

    @Bean
    public ScriptTemplateConfigurer configurer() {
        ScriptTemplateConfigurer configurer = new ScriptTemplateConfigurer();
        configurer.setEngineName("nashorn");
        configurer.setScripts("polyfill.js", "handlebars.js", "render.js");
        configurer.setRenderFunction("render");
        configurer.setSharedEngine(false);
        return configurer;
    }
}
```

|      | Setting the `sharedEngine` property to `false` is required when using non-thread-safe script engines with templating libraries not designed for concurrency, such as Handlebars or React running on Nashorn. In that case, Java SE 8 update 60 is required, due to [this bug](https://bugs.openjdk.java.net/browse/JDK-8076099), but it is generally recommended to use a recent Java SE patch release in any case. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

polyfill.js仅定义Handlebars正常运行所需的window对象，如以下代码片段所示：

```javascript
var window = {};
```

这个基本的render.js实现在使用模板之前先对其进行编译。生产就绪的实现还应该存储和重用缓存的模板或预编译的模板。这可以在脚本端以及您需要的任何自定义（例如，管理模板引擎配置）上完成。以下示例显示了如何编译模板：

```javascript
function render(template, model) {
    var compiledTemplate = Handlebars.compile(template);
    return compiledTemplate(model);
}
```

查看Spring Framework单元测试，Java和资源，以获取更多配置示例。

#### 1.9.4. JSON and XML

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-jackson)

出于内容协商的目的，根据客户端请求的内容类型，能够在使用HTML模板呈现模型或以其他格式（例如JSON或XML）呈现模型之间进行切换非常有用。为了支持此操作，Spring WebFlux提供了HttpMessageWriterView，您可以使用它插入spring-web中的任何可用编解码器，例如Jackson2JsonEncoder，Jackson2SmileEncoder或Jaxb2XmlEncoder。

与其他视图技术不同，HttpMessageWriterView不需要ViewResolver，而是配置为默认视图。您可以配置一个或多个此类默认视图，并包装不同的HttpMessageWriter实例或Encoder实例。在运行时使用与请求的内容类型匹配的内容。

在大多数情况下，模型包含多个属性。要确定要序列化的对象，可以使用模型属性的名称配置HttpMessageWriterView进行渲染。如果模型仅包含一个属性，则使用该属性。

### 1.10. HTTP Caching

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-caching)

HTTP缓存可以显着提高Web应用程序的性能。 HTTP缓存围绕Cache-Control响应标头和后续的条件请求标头（例如Last-Modified和ETag）。 Cache-Control建议私有（例如浏览器）和公共（例如代理）缓存如何缓存和重新使用响应。 ETag标头用于发出条件请求，如果内容未更改，则可能导致没有主体的304（NOT_MODIFIED）。 ETag可以看作是Last-Modified头的更复杂的后继者。

本节描述了Spring WebFlux中与HTTP缓存相关的选项。

#### 1.10.1. `CacheControl`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-caching-cachecontrol)

CacheControl支持配置与Cache-Control标头相关的设置，并在许多地方作为参数被接受：

- [Controllers](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-caching-etag-lastmodified)
- [Static Resources](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-caching-static-resources)

RFC 7234描述了Cache-Control响应标头的所有可能的指令，而CacheControl类型采用了针对用例的方法，着重于常见方案，如以下示例所示：

```java
// Cache for an hour - "Cache-Control: max-age=3600"
CacheControl ccCacheOneHour = CacheControl.maxAge(1, TimeUnit.HOURS);

// Prevent caching - "Cache-Control: no-store"
CacheControl ccNoStore = CacheControl.noStore();

// Cache for ten days in public and private caches,
// public caches should not transform the response
// "Cache-Control: max-age=864000, public, no-transform"
CacheControl ccCustom = CacheControl.maxAge(10, TimeUnit.DAYS).noTransform().cachePublic();
```

#### 1.10.2. Controllers

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-caching-etag-lastmodified)

控制器可以添加对HTTP缓存的显式支持。我们建议您这样做，因为需要先计算资源的lastModified或ETag值，然后才能将其与条件请求标头进行比较。控制器可以将ETag和Cache-Control设置添加到ResponseEntity，如以下示例所示：

```java
@GetMapping("/book/{id}")
public ResponseEntity<Book> showBook(@PathVariable Long id) {

    Book book = findBook(id);
    String version = book.getVersion();

    return ResponseEntity
            .ok()
            .cacheControl(CacheControl.maxAge(30, TimeUnit.DAYS))
            .eTag(version) // lastModified is also available
            .body(book);
}
```

如果与条件请求标头的比较表明内容未更改，则前面的示例发送带有空主体的304（NOT_MODIFIED）响应。否则，ETag和Cache-Control标头将添加到响应中。

您还可以在控制器中针对条件请求标头进行检查，如以下示例所示：

```java
@RequestMapping
public String myHandleMethod(ServerWebExchange exchange, Model model) {

    long eTag = ... 

    if (exchange.checkNotModified(eTag)) {
        return null; 
    }

    model.addAttribute(...); 
    return "myViewName";
}
```

可以使用三种变体来检查针对eTag值，lastModified值或两者的条件请求。对于有条件的GET和HEAD请求，可以将响应设置为304（NOT_MODIFIED）。对于条件POST，PUT和DELETE，您可以将响应设置为412（PRECONDITION_FAILED），以防止并发修改。

#### 1.10.3. Static Resources

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-caching-static-resources)

您应该为静态资源提供Cache-Control和条件响应标头，以实现最佳性能。请参阅有关配置静态资源的部分。

### 1.11. WebFlux Config

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config)

WebFlux Java配置声明使用带注释的控制器或功能端点来声明处理请求所必需的组件，并且它提供了用于自定义配置的API。这意味着您不需要了解Java配置创建的底层bean。但是，如果您想了解它们，则可以在WebFluxConfigurationSupport中查看它们，或阅读有关特殊Bean类型中的内容的更多信息。

对于配置API中没有的更高级的自定义设置，您可以通过“高级配置模式”获得对配置的完全控制。

#### 1.11.1. Enabling WebFlux Config

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-enable)

您可以在Java配置中使用@EnableWebFlux批注，如以下示例所示：

```java
@Configuration
@EnableWebFlux
public class WebConfig {
}
```

前面的示例注册了许多Spring WebFlux基础结构Bean，并适应了classpath上可用的依赖关系（对于JSON，XML等）。

#### 1.11.2. WebFlux config API

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-customize)

在Java配置中，可以实现WebFluxConfigurer接口，如以下示例所示：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    // Implement configuration methods...
}
```

#### 1.11.3. Conversion, formatting

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-conversion)

默认情况下，将安装各种数字和日期类型的格式化程序，并支持通过字段上的@NumberFormat和@DateTimeFormat自定义。

要在Java配置中注册自定义格式器和转换器，请使用以下命令：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void addFormatters(FormatterRegistry registry) {
        // ...
    }

}
```

默认情况下，Spring WebFlux在解析和格式化日期值时会考虑请求区域设置。这适用于使用“输入”表单字段将日期表示为字符串的表单。但是，对于“日期”和“时间”表单字段，浏览器使用HTML规范中定义的固定格式。在这种情况下，日期和时间格式可以按以下方式自定义：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void addFormatters(FormatterRegistry registry) {
        DateTimeFormatterRegistrar registrar = new DateTimeFormatterRegistrar();
        registrar.setUseIsoFormat(true);
        registrar.registerFormatters(registry);
    }
}
```

#### 1.11.4. Validation

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-validation)

默认情况下，如果Bean验证存在于类路径中（例如，Hibernate Validator），则LocalValidatorFactoryBean将注册为全局验证器，以与@Valid和@Controller方法参数中的@Validated一起使用。

在Java配置中，您可以自定义全局Validator实例，如以下示例所示：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public Validator getValidator(); {
        // ...
    }

}
```

请注意，您还可以在本地注册Validator实现，如以下示例所示：

```java
@Controller
public class MyController {

    @InitBinder
    protected void initBinder(WebDataBinder binder) {
        binder.addValidators(new FooValidator());
    }

}
```

#### 1.11.5. Content Type Resolvers

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-content-negotiation)

您可以配置Spring WebFlux如何根据请求为@Controller实例确定所请求的媒体类型。默认情况下，仅选中Accept标头，但您也可以启用基于查询参数的策略。

以下示例显示如何自定义请求的内容类型解析：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void configureContentTypeResolver(RequestedContentTypeResolverBuilder builder) {
        // ...
    }
}
```

#### 1.11.6. HTTP message codecs

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-message-converters)

以下示例显示如何自定义读取和写入请求和响应正文的方式：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void configureHttpMessageCodecs(ServerCodecConfigurer configurer) {
        configurer.defaultCodecs().maxInMemorySize(512 * 1024);
    }
}
```

ServerCodecConfigurer提供了一组默认的读取器和写入器。您可以使用它来添加更多读取器和写入器，自定义默认读取器或完全替换默认读取器。

对于Jackson JSON和XML，请考虑使用Jackson2ObjectMapperBuilder，该工具使用以下属性自定义Jackson的默认属性：

- [`DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES`](https://fasterxml.github.io/jackson-databind/javadoc/2.6/com/fasterxml/jackson/databind/DeserializationFeature.html#FAIL_ON_UNKNOWN_PROPERTIES) is disabled.
- [`MapperFeature.DEFAULT_VIEW_INCLUSION`](https://fasterxml.github.io/jackson-databind/javadoc/2.6/com/fasterxml/jackson/databind/MapperFeature.html#DEFAULT_VIEW_INCLUSION) is disabled.

如果在类路径中检测到以下知名模块，它将自动注册以下知名模块：

- [`jackson-datatype-joda`](https://github.com/FasterXML/jackson-datatype-joda): Support for Joda-Time types.
- [`jackson-datatype-jsr310`](https://github.com/FasterXML/jackson-datatype-jsr310): Support for Java 8 Date and Time API types.
- [`jackson-datatype-jdk8`](https://github.com/FasterXML/jackson-datatype-jdk8): Support for other Java 8 types, such as `Optional`.
- [`jackson-module-kotlin`](https://github.com/FasterXML/jackson-module-kotlin): Support for Kotlin classes and data classes.

#### 1.11.7. View Resolvers

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-view-resolvers)

下面的示例显示如何配置视图分辨率：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        // ...
    }
}
```

ViewResolverRegistry具有与Spring Framework集成的视图技术的快捷方式。以下示例使用FreeMarker（这也需要配置基础FreeMarker视图技术）：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {


    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        registry.freeMarker();
    }

    // Configure Freemarker...

    @Bean
    public FreeMarkerConfigurer freeMarkerConfigurer() {
        FreeMarkerConfigurer configurer = new FreeMarkerConfigurer();
        configurer.setTemplateLoaderPath("classpath:/templates");
        return configurer;
    }
}
```

您还可以插入任何ViewResolver实现，如以下示例所示：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {


    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        ViewResolver resolver = ... ;
        registry.viewResolver(resolver);
    }
}
```

为了支持“ [Content Negotiation](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-multiple-representations) ”并通过视图分辨率（除HTML之外）呈现其他格式，您可以基于HttpMessageWriterView实现配置一个或多个默认视图，该实现接受spring-web中的任何可用编解码器。以下示例显示了如何执行此操作：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {


    @Override
    public void configureViewResolvers(ViewResolverRegistry registry) {
        registry.freeMarker();

        Jackson2JsonEncoder encoder = new Jackson2JsonEncoder();
        registry.defaultViews(new HttpMessageWriterView(encoder));
    }

    // ...
}
```

有关与Spring WebFlux集成的视图技术的更多信息，请参见View Technologies。

#### 1.11.8. Static Resources

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-static-resources)

此选项提供了一种方便的方法来从基于资源的位置列表中提供静态资源。

在下一个示例中，给定一个以/ resources开头的请求，相对路径用于在类路径上查找和提供相对于/ static的静态资源。资源的有效期为一年，以确保最大程度地利用浏览器缓存并减少浏览器发出的HTTP请求。还评估Last-Modified头，如果存在，则返回304状态码。以下列表显示了示例：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/resources/**")
            .addResourceLocations("/public", "classpath:/static/")
            .setCacheControl(CacheControl.maxAge(365, TimeUnit.DAYS));
    }

}
```

资源处理程序还支持一系列ResourceResolver实现和ResourceTransformer实现，可用于创建用于优化资源的工具链。

您可以根据从内容，固定应用程序版本或其他信息计算出的MD5哈希，将VersionResourceResolver用于版本化的资源URL。 ContentVersionStrategy（MD5哈希）是一个不错的选择，但有一些明显的例外（例如与模块加载器一起使用的JavaScript资源）。

以下示例显示如何在Java配置中使用VersionResourceResolver：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/resources/**")
                .addResourceLocations("/public/")
                .resourceChain(true)
                .addResolver(new VersionResourceResolver().addContentVersionStrategy("/**"));
    }

}
```

您可以使用ResourceUrlProvider重写URL并应用完整的解析器和转换器链（例如，插入版本）。 WebFlux配置提供了ResourceUrlProvider，以便可以将其注入其他资源。

与Spring MVC不同，目前，在WebFlux中，由于没有视图技术可以利用解析器和转换器的无阻塞链，因此无法透明地重写静态资源URL。当仅提供本地资源时，解决方法是直接使用ResourceUrlProvider（例如，通过自定义元素）并进行阻止。

请注意，在同时使用EncodedResourceResolver（例如，Gzip，Brotli编码）和VersionedResourceResolver时，必须按该顺序注册它们，以确保始终基于未编码文件可靠地计算基于内容的版本。

WebJars也通过WebJarsResourceResolver支持，当org.webjars：webjars-locator-core库存在于类路径中时，WebJars将自动注册。解析程序可以重写URL以包括jar的版本，还可以与没有版本的传入URL进行匹配，例如，从/jquery/jquery.min.js到/jquery/1.2.0/jquery.min.js。

#### 1.11.9. Path Matching

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-path-matching)

您可以自定义与路径匹配有关的选项。有关各个选项的详细信息，请参见PathMatchConfigurer javadoc。以下示例显示如何使用PathMatchConfigurer：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        configurer
            .setUseCaseSensitiveMatch(true)
            .setUseTrailingSlashMatch(false)
            .addPathPrefix("/api",
                    HandlerTypePredicate.forAnnotation(RestController.class));
    }
}
```

#### 1.11.10. WebSocketService

WebFlux Java配置声明了一个WebSocketHandlerAdapter bean，该bean为WebSocket处理程序的调用提供支持。这意味着要处理WebSocket握手请求，剩下要做的就是通过SimpleUrlHandlerMapping将WebSocketHandler映射到URL。

在某些情况下，可能需要使用提供的WebSocketService服务创建WebSocketHandlerAdapter bean，该服务允许配置WebSocket服务器属性。例如：

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    @Override
    public WebSocketService getWebSocketService() {
        TomcatRequestUpgradeStrategy strategy = new TomcatRequestUpgradeStrategy();
        strategy.setMaxSessionIdleTimeout(0L);
        return new HandshakeWebSocketService(strategy);
    }
}
```

#### 1.11.11. Advanced Configuration Mode

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-advanced-java)

@EnableWebFlux导入DelegatingWebFluxConfiguration：

为WebFlux应用程序提供默认的Spring配置

检测并委托给WebFluxConfigurer实现以自定义该配置。

对于高级模式，您可以删除@EnableWebFlux并直接从DelegatingWebFluxConfiguration扩展而不是实现WebFluxConfigurer，如以下示例所示：

```java
@Configuration
public class WebConfig extends DelegatingWebFluxConfiguration {

    // ...
}
```

您可以将现有方法保留在Web Config中，但是现在您还可以覆盖基类中的bean声明，并且在类路径上仍然具有任意数量的其他WebMvcConfigurer实现。

### 1.12. HTTP/2

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-http2)

Reactor Netty，Tomcat，Jetty和Undertow支持HTTP / 2。但是，有一些与服务器配置有关的注意事项。有关更多详细信息，请参见HTTP / 2 Wiki页面。

## 2. WebClient

Spring WebFlux包括一个用于执行HTTP请求的客户端。 WebClient具有一个基于Reactor的功能性，流畅的API，请参阅Reactive Libraries，它可以以声明方式构成异步逻辑，而无需处理线程或并发。它是完全非阻塞的，它支持流传输，并且依赖于相同的编解码器，该编解码器还用于在服务器端对请求和响应内容进行编码和解码。

WebClient需要一个HTTP客户端库来执行请求。内置支持以下内容：

- [Reactor Netty](https://github.com/reactor/reactor-netty)
- [Jetty Reactive HttpClient](https://github.com/jetty-project/jetty-reactive-httpclient)
- [Apache HttpComponents](https://hc.apache.org/index.html)
- Others can be plugged via `ClientHttpConnector`.

### 2.1. Configuration

创建WebClient的最简单方法是通过静态工厂方法之一：

- `WebClient.create()`
- `WebClient.create(String baseUrl)`

您还可以将`WebClient.builder()` 与其他选项一起使用：s

- `uriBuilderFactory`:自定义的UriBuilderFactory用作基本URL。
- `defaultUriVariables`: 扩展URI模板时使用的默认值。
- `defaultHeader`:默认请求头
- `defaultCookie`: 默认 cookie
- `defaultRequest`: 默认请求
- `filter`: 默认客户端拦截器
- `exchangeStrategies`: 定制HTTP消息读取、写入。
- `clientConnector`: HTTP客户端库设置.

```java
WebClient client = WebClient.builder()
        .codecs(configurer -> ... )
        .build();
```

建立之后，`WebClient`是不可变的。但是，您可以克隆它并按如下所示构建修改后的副本：

```java
WebClient client1 = WebClient.builder()
        .filter(filterA).filter(filterB).build();

WebClient client2 = client1.mutate()
        .filter(filterC).filter(filterD).build();

// client1 has filterA, filterB

// client2 has filterA, filterB, filterC, filterD
```

#### 2.1.1. MaxInMemorySize

编解码器具有在内存中缓冲数据的限制，以避免出现应用程序内存问题。默认情况下，这些设置为256KB。如果这还不够，则会出现以下错误：

```
org.springframework.core.io.buffer.DataBufferLimitException: Exceeded limit on max bytes to buffer
```

要更改默认编解码器的限制，请使用以下命令：

```java
WebClient webClient = WebClient.builder()
        .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024))
        .build();
```

#### 2.1.2. Reactor Netty

要自定义Reactor Netty设置，请提供一个预配置的HttpClient：

```java
HttpClient httpClient = HttpClient.create().secure(sslSpec -> ...);

WebClient webClient = WebClient.builder()
        .clientConnector(new ReactorClientHttpConnector(httpClient))
        .build();
```

##### Resources

默认情况下，HttpClient会参与Reactor.netty.http.HttpResources中包含的全局Reactor Netty资源，包括事件循环线程和连接池。这是推荐的模式，因为固定的共享资源是事件循环并发的首选。在这种模式下，全局资源将保持活动状态，直到进程退出。

如果服务器与进程同步，通常不需要显式关闭。但是，如果服务器可以启动或停止进程内（例如，部署为WAR的Spring MVC应用程序），则可以声明类型为ReactorResourceFactory的Spring托管Bean，其具有globalResources = true（默认值）以确保Reactor关闭Spring ApplicationContext时，将关闭Netty全局资源，如以下示例所示：

```java
@Bean
public ReactorResourceFactory reactorResourceFactory() {
    return new ReactorResourceFactory();
}
```

您也可以选择不参与全局Reactor Netty资源。但是，在这种模式下，确保所有Reactor Netty客户端和服务器实例使用共享资源是您的重担，如以下示例所示：

```java
@Bean
public ReactorResourceFactory resourceFactory() {
    ReactorResourceFactory factory = new ReactorResourceFactory();
    factory.setUseGlobalResources(false); 
    return factory;
}

@Bean
public WebClient webClient() {

    Function<HttpClient, HttpClient> mapper = client -> {
        // Further customizations...
    };

    ClientHttpConnector connector =
            new ReactorClientHttpConnector(resourceFactory(), mapper); 

    return WebClient.builder().clientConnector(connector).build(); 
}
```

##### Timeouts

要配置连接超时：

```java
import io.netty.channel.ChannelOption;

HttpClient httpClient = HttpClient.create()
        .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000);

WebClient webClient = WebClient.builder()
        .clientConnector(new ReactorClientHttpConnector(httpClient))
        .build();
```

要配置读取或写入超时：

```java
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;

HttpClient httpClient = HttpClient.create()
        .doOnConnected(conn -> conn
                .addHandlerLast(new ReadTimeoutHandler(10))
                .addHandlerLast(new WriteTimeoutHandler(10)));

// Create WebClient...
```

要为所有请求配置响应超时：

```java
HttpClient httpClient = HttpClient.create()
        .responseTimeout(Duration.ofSeconds(2));

// Create WebClient...
```

要为特定请求配置响应超时：

```java
WebClient.create().get()
        .uri("https://example.org/path")
        .httpRequest(httpRequest -> {
            HttpClientRequest reactorRequest = httpRequest.getNativeRequest();
            reactorRequest.responseTimeout(Duration.ofSeconds(2));
        })
        .retrieve()
        .bodyToMono(String.class);
```

#### 2.1.3. Jetty

以下示例显示如何自定义Jetty HttpClient设置：

```java
HttpClient httpClient = new HttpClient();
httpClient.setCookieStore(...);

WebClient webClient = WebClient.builder()
        .clientConnector(new JettyClientHttpConnector(httpClient))
        .build();
```

默认情况下，HttpClient创建自己的资源（执行程序，ByteBufferPool，调度程序），这些资源将保持活动状态，直到进程退出或调用stop（）为止。

您可以在Jetty客户端（和服务器）的多个实例之间共享资源，并通过声明类型为JettyResourceFactory的Spring托管Bean来确保在关闭Spring ApplicationContext时关闭资源，如以下示例所示：

```java
@Bean
public JettyResourceFactory resourceFactory() {
    return new JettyResourceFactory();
}

@Bean
public WebClient webClient() {

    HttpClient httpClient = new HttpClient();
    // Further customizations...

    ClientHttpConnector connector =
            new JettyClientHttpConnector(httpClient, resourceFactory()); 

    return WebClient.builder().clientConnector(connector).build(); 
}
```

#### 2.1.4. HttpComponents

以下示例显示了如何自定义Apache HttpComponents HttpClient设置：

```java
HttpAsyncClientBuilder clientBuilder = HttpAsyncClients.custom();
clientBuilder.setDefaultRequestConfig(...);
CloseableHttpAsyncClient client = clientBuilder.build();
ClientHttpConnector connector = new HttpComponentsClientHttpConnector(client);

WebClient webClient = WebClient.builder().clientConnector(connector).build();
```

### 2.2. `retrieve()`

Retrieve（）方法可用于声明如何提取响应。例如：

```java
WebClient client = WebClient.create("https://example.org");

Mono<ResponseEntity<Person>> result = client.get()
        .uri("/persons/{id}", id).accept(MediaType.APPLICATION_JSON)
        .retrieve()
        .toEntity(Person.class);
```

或者获取 JSON body

```java
WebClient client = WebClient.create("https://example.org");

Mono<Person> result = client.get()
        .uri("/persons/{id}", id).accept(MediaType.APPLICATION_JSON)
        .retrieve()
        .bodyToMono(Person.class);
```

或者获取解码对象流

```java
Flux<Quote> result = client.get()
        .uri("/quotes").accept(MediaType.TEXT_EVENT_STREAM)
        .retrieve()
        .bodyToFlux(Quote.class);
```

默认情况下，4xx或5xx响应会导致WebClientResponseException，包括特定HTTP状态代码的子类。要自定义错误响应的处理，请使用onStatus处理程序，如下所示：

```java
Mono<Person> result = client.get()
        .uri("/persons/{id}", id).accept(MediaType.APPLICATION_JSON)
        .retrieve()
        .onStatus(HttpStatus::is4xxClientError, response -> ...)
        .onStatus(HttpStatus::is5xxServerError, response -> ...)
        .bodyToMono(Person.class);
```

### 2.3. Exchange

exchangeToMono（）和exchangeToFlux（）方法（或Kotlin中的awaitExchange {}和exchangeToFlow {}）对于需要更多控制的更高级情况很有用，例如根据响应状态不同地解码响应：

```java
Mono<Object> entityMono = client.get()
        .uri("/persons/1")
        .accept(MediaType.APPLICATION_JSON)
        .exchangeToMono(response -> {
            if (response.statusCode().equals(HttpStatus.OK)) {
                return response.bodyToMono(Person.class);
            }
            else if (response.statusCode().is4xxClientError()) {
                // Suppress error status code
                return response.bodyToMono(ErrorContainer.class);
            }
            else {
                // Turn to error
                return response.createException().flatMap(Mono::error);
            }
        });
```

使用上述方法时，在返回的Mono或Flux完成后，将检查响应主体，如果未消耗响应主体，则将其释放以防止内存和连接泄漏。因此，无法在下游进一步解码响应。如果需要，由提供的函数声明如何解码响应。

### 2.4. Request Body

可以使用ReactiveAdapterRegistry处理的任何异步类型对请求主体进行编码，例如Mono或Deferred的Kotlin Coroutines，如以下示例所示：

```java
Mono<Person> personMono = ... ;

Mono<Void> result = client.post()
        .uri("/persons/{id}", id)
        .contentType(MediaType.APPLICATION_JSON)
        .body(personMono, Person.class)
        .retrieve()
        .bodyToMono(Void.class);
```

您还可以对对象流进行编码，如以下示例所示：

```java
Flux<Person> personFlux = ... ;

Mono<Void> result = client.post()
        .uri("/persons/{id}", id)
        .contentType(MediaType.APPLICATION_STREAM_JSON)
        .body(personFlux, Person.class)
        .retrieve()
        .bodyToMono(Void.class);
```

或者，如果您具有实际值，则可以使用bodyValue快捷方式，如以下示例所示：

```java
Person person = ... ;

Mono<Void> result = client.post()
        .uri("/persons/{id}", id)
        .contentType(MediaType.APPLICATION_JSON)
        .bodyValue(person)
        .retrieve()
        .bodyToMono(Void.class);
```

#### 2.4.1. Form Data

要发送表单数据，可以提供MultiValueMap 作为正文。请注意，内容由FormHttpMessageWriter自动设置为application / x-www-form-urlencoded。下面的示例演示如何使用MultiValueMap ：

```java
MultiValueMap<String, String> formData = ... ;

Mono<Void> result = client.post()
        .uri("/path", id)
        .bodyValue(formData)
        .retrieve()
        .bodyToMono(Void.class);
```

您还可以使用BodyInserters在线提供表单数据，如以下示例所示：

```java
import static org.springframework.web.reactive.function.BodyInserters.*;

Mono<Void> result = client.post()
        .uri("/path", id)
        .body(fromFormData("k1", "v1").with("k2", "v2"))
        .retrieve()
        .bodyToMono(Void.class);
```

#### 2.4.2. Multipart Data

要发送多部分数据，您需要提供一个MultiValueMap ，其值可以是代表零件内容的Object实例或代表零件内容和标题的HttpEntity实例。MultipartBodyBuilder提供了一个方便的API来准备多部分请求。下面的示例演示如何创建MultiValueMap ：

```java
MultipartBodyBuilder builder = new MultipartBodyBuilder();
builder.part("fieldPart", "fieldValue");
builder.part("filePart1", new FileSystemResource("...logo.png"));
builder.part("jsonPart", new Person("Jason"));
builder.part("myPart", part); // Part from a server request

MultiValueMap<String, HttpEntity<?>> parts = builder.build();
```

在大多数情况下，您不必为每个部分指定Content-Type。内容类型是根据选择用于对其进行序列化的HttpMessageWriter自动确定的，对于资源来说，取决于文件扩展名。如有必要，您可以通过重载的构建器part方法之一显式提供MediaType以供每个零件使用。

准备好MultiValueMap之后，将其传递给WebClient的最简单方法是通过body方法，如以下示例所示：

```java
MultipartBodyBuilder builder = ...;

Mono<Void> result = client.post()
        .uri("/path", id)
        .body(builder.build())
        .retrieve()
        .bodyToMono(Void.class);
```

如果MultiValueMap包含至少一个非String值，它也可以表示常规表单数据（即application / x-www-form-urlencoded），则无需将Content-Type设置为multipart / form-data。使用MultipartBodyBuilder时，总是这样，以确保HttpEntity包装器。

作为MultipartBodyBuilder的替代方案，您还可以通过内置的BodyInserters以内联样式提供多部分内容，如以下示例所示：

```java
import static org.springframework.web.reactive.function.BodyInserters.*;

Mono<Void> result = client.post()
        .uri("/path", id)
        .body(fromMultipartData("fieldPart", "value").with("filePart", resource))
        .retrieve()
        .bodyToMono(Void.class);
```

### 2.5. Filters

您可以通过WebClient.Builder注册客户端过滤器（ExchangeFilterFunction），以拦截和修改请求，如以下示例所示：

```java
WebClient client = WebClient.builder()
        .filter((request, next) -> {

            ClientRequest filtered = ClientRequest.from(request)
                    .header("foo", "bar")
                    .build();

            return next.exchange(filtered);
        })
        .build();
```

这可以用于跨领域的关注，例如身份验证。以下示例使用过滤器通过静态工厂方法进行基本身份验证：

```java
import static org.springframework.web.reactive.function.client.ExchangeFilterFunctions.basicAuthentication;

WebClient client = WebClient.builder()
        .filter(basicAuthentication("user", "password"))
        .build();
```

您可以通过使用另一个实例作为起点来创建新的WebClient实例。这允许在不影响原始WebClient的情况下插入或删除过滤器。以下是在索引0处插入基本身份验证过滤器的示例：

```java
import static org.springframework.web.reactive.function.client.ExchangeFilterFunctions.basicAuthentication;

WebClient client = webClient.mutate()
        .filters(filterList -> {
            filterList.add(0, basicAuthentication("user", "password"));
        })
        .build();
```

### 2.6. Attributes

您可以向请求添加属性。如果要通过筛选器链传递信息并影响给定请求的筛选器行为，这将很方便。例如：

```java
WebClient client = WebClient.builder()
        .filter((request, next) -> {
            Optional<Object> usr = request.attribute("myAttribute");
            // ...
        })
        .build();

client.get().uri("https://example.org/")
        .attribute("myAttribute", "...")
        .retrieve()
        .bodyToMono(Void.class);

    }
```

请注意，可以在WebClient.Builder级别上全局配置defaultRequest回调，该回调使您可以将属性插入所有请求，例如，可以在Spring MVC应用程序中使用该属性来基于ThreadLocal数据填充请求属性。

### 2.7. Context

属性提供了一种将信息传递到筛选器链的便捷方法，但是它们仅影响当前请求。如果您想传递传播到嵌套的其他请求的信息，例如通过flatMap或在之后执行通过concatMap，则需要使用Reactor Context。

为了应用于所有操作，需要在反应链的末尾填充Reactor上下文。例如：

```java
WebClient client = WebClient.builder()
        .filter((request, next) ->
                Mono.deferContextual(contextView -> {
                    String value = contextView.get("foo");
                    // ...
                }))
        .build();

client.get().uri("https://example.org/")
        .retrieve()
        .bodyToMono(String.class)
        .flatMap(body -> {
                // perform nested request (context propagates automatically)...
        })
        .contextWrite(context -> context.put("foo", ...));
```

### 2.8. Synchronous Use

通过在结果末尾进行阻塞，可以以同步方式使用WebClient：

```java
Person person = client.get().uri("/person/{id}", i).retrieve()
    .bodyToMono(Person.class)
    .block();

List<Person> persons = client.get().uri("/persons").retrieve()
    .bodyToFlux(Person.class)
    .collectList()
    .block();
```

但是，如果需要进行多次通话，则可以避免单独阻塞每个响应，而不必等待合并结果，这样会更有效：

```java
Mono<Person> personMono = client.get().uri("/person/{id}", personId)
        .retrieve().bodyToMono(Person.class);

Mono<List<Hobby>> hobbiesMono = client.get().uri("/person/{id}/hobbies", personId)
        .retrieve().bodyToFlux(Hobby.class).collectList();

Map<String, Object> data = Mono.zip(personMono, hobbiesMono, (person, hobbies) -> {
            Map<String, String> map = new LinkedHashMap<>();
            map.put("person", person);
            map.put("hobbies", hobbies);
            return map;
        })
        .block();
```

以上仅是一个示例。还有许多其他模式和运算符可用于构建响应式管道，该响应式管道可进行许多远程调用（可能是嵌套的，相互依赖的），而不会阻塞到最后。

使用Flux或Mono，您永远不必阻塞Spring MVC或Spring WebFlux控制器。只需从controller方法返回结果类型即可。相同的原则适用于Kotlin Coroutines和Spring WebFlux，只需在控制器方法中使用暂停功能或返回Flow即可。

### 2.9. Testing

若要测试使用WebClient的代码，可以使用模拟Web服务器，例如OkHttp MockWebServer。要查看其用法示例，请查看Spring Framework测试套件中的WebClientIntegrationTests或OkHttp存储库中的静态服务器示例。
