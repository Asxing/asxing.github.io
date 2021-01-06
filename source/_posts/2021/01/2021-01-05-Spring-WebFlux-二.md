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
  - 1
  - 1
date: 2021-01-05 00:44:50
password:
summary:
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

Spring WebFlux provides an annotation-based programming model, where `@Controller` and `@RestController` components use annotations to express request mappings, request input, handle exceptions, and more. Annotated controllers have flexible method signatures and do not have to extend base classes nor implement specific interfaces.

The following listing shows a basic example:

Java

Kotlin

```java
@RestController
public class HelloController {

    @GetMapping("/hello")
    public String handle() {
        return "Hello WebFlux";
    }
}
```

In the preceding example, the method returns a `String` to be written to the response body.

#### 1.4.1. `@Controller`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-controller)

You can define controller beans by using a standard Spring bean definition. The `@Controller` stereotype allows for auto-detection and is aligned with Spring general support for detecting `@Component` classes in the classpath and auto-registering bean definitions for them. It also acts as a stereotype for the annotated class, indicating its role as a web component.

To enable auto-detection of such `@Controller` beans, you can add component scanning to your Java configuration, as the following example shows:

Java

Kotlin

```java
@Configuration
@ComponentScan("org.example.web") 
public class WebConfig {

    // ...
}
```

|      | Scan the `org.example.web` package. |
| ---- | ----------------------------------- |
|      |                                     |

`@RestController` is a [composed annotation](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#beans-meta-annotations) that is itself meta-annotated with `@Controller` and `@ResponseBody`, indicating a controller whose every method inherits the type-level `@ResponseBody` annotation and, therefore, writes directly to the response body versus view resolution and rendering with an HTML template.

#### 1.4.2. Request Mapping

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping)

The `@RequestMapping` annotation is used to map requests to controllers methods. It has various attributes to match by URL, HTTP method, request parameters, headers, and media types. You can use it at the class level to express shared mappings or at the method level to narrow down to a specific endpoint mapping.

There are also HTTP method specific shortcut variants of `@RequestMapping`:

- `@GetMapping`
- `@PostMapping`
- `@PutMapping`
- `@DeleteMapping`
- `@PatchMapping`

The preceding annotations are [Custom Annotations](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-requestmapping-composed) that are provided because, arguably, most controller methods should be mapped to a specific HTTP method versus using `@RequestMapping`, which, by default, matches to all HTTP methods. At the same time, a `@RequestMapping` is still needed at the class level to express shared mappings.

The following example uses type and method level mappings:

Java

Kotlin

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

You can map requests by using glob patterns and wildcards:

| Pattern         | Description                                                  | Example                                                      |
| :-------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| `?`             | Matches one character                                        | `"/pages/t?st.html"` matches `"/pages/test.html"` and `"/pages/t3st.html"` |
| `*`             | Matches zero or more characters within a path segment        | `"/resources/*.png"` matches `"/resources/file.png"``"/projects/*/versions"` matches `"/projects/spring/versions"` but does not match `"/projects/spring/boot/versions"` |
| `**`            | Matches zero or more path segments until the end of the path | `"/resources/**"` matches `"/resources/file.png"` and `"/resources/images/file.png"``"/resources/**/file.png"` is invalid as `**` is only allowed at the end of the path. |
| `{name}`        | Matches a path segment and captures it as a variable named "name" | `"/projects/{project}/versions"` matches `"/projects/spring/versions"` and captures `project=spring` |
| `{name:[a-z]+}` | Matches the regexp `"[a-z]+"` as a path variable named "name" | `"/projects/{project:[a-z]+}/versions"` matches `"/projects/spring/versions"` but not `"/projects/spring1/versions"` |
| `{*path}`       | Matches zero or more path segments until the end of the path and captures it as a variable named "path" | `"/resources/{*file}"` matches `"/resources/images/file.png"` and captures `file=images/file.png` |

Captured URI variables can be accessed with `@PathVariable`, as the following example shows:

Java

Kotlin

```java
@GetMapping("/owners/{ownerId}/pets/{petId}")
public Pet findPet(@PathVariable Long ownerId, @PathVariable Long petId) {
    // ...
}
```

You can declare URI variables at the class and method levels, as the following example shows:

Java

Kotlin

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

|      | Class-level URI mapping.  |
| ---- | ------------------------- |
|      | Method-level URI mapping. |

URI variables are automatically converted to the appropriate type or a `TypeMismatchException` is raised. Simple types (`int`, `long`, `Date`, and so on) are supported by default and you can register support for any other data type. See [Type Conversion](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-typeconversion) and [`DataBinder`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-initbinder).

URI variables can be named explicitly (for example, `@PathVariable("customId")`), but you can leave that detail out if the names are the same and you compile your code with debugging information or with the `-parameters` compiler flag on Java 8.

The syntax `{*varName}` declares a URI variable that matches zero or more remaining path segments. For example `/resources/{*path}` matches all files under `/resources/`, and the `"path"` variable captures the complete relative path.

The syntax `{varName:regex}` declares a URI variable with a regular expression that has the syntax: `{varName:regex}`. For example, given a URL of `/spring-web-3.0.5 .jar`, the following method extracts the name, version, and file extension:

Java

Kotlin

```java
@GetMapping("/{name:[a-z-]+}-{version:\\d\\.\\d\\.\\d}{ext:\\.[a-z]+}")
public void handle(@PathVariable String version, @PathVariable String ext) {
    // ...
}
```

URI path patterns can also have embedded `${…}` placeholders that are resolved on startup through `PropertyPlaceHolderConfigurer` against local, system, environment, and other property sources. You ca use this to, for example, parameterize a base URL based on some external configuration.

|      | Spring WebFlux uses `PathPattern` and the `PathPatternParser` for URI path matching support. Both classes are located in `spring-web` and are expressly designed for use with HTTP URL paths in web applications where a large number of URI path patterns are matched at runtime. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

Spring WebFlux does not support suffix pattern matching — unlike Spring MVC, where a mapping such as `/person` also matches to `/person.*`. For URL-based content negotiation, if needed, we recommend using a query parameter, which is simpler, more explicit, and less vulnerable to URL path based exploits.

##### Pattern Comparison

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-pattern-comparison)

When multiple patterns match a URL, they must be compared to find the best match. This is done with `PathPattern.SPECIFICITY_COMPARATOR`, which looks for patterns that are more specific.

For every pattern, a score is computed, based on the number of URI variables and wildcards, where a URI variable scores lower than a wildcard. A pattern with a lower total score wins. If two patterns have the same score, the longer is chosen.

Catch-all patterns (for example, `**`, `{*varName}`) are excluded from the scoring and are always sorted last instead. If two patterns are both catch-all, the longer is chosen.

##### Consumable Media Types

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-consumes)

You can narrow the request mapping based on the `Content-Type` of the request, as the following example shows:

Java

Kotlin

```java
@PostMapping(path = "/pets", consumes = "application/json")
public void addPet(@RequestBody Pet pet) {
    // ...
}
```

The consumes attribute also supports negation expressions — for example, `!text/plain` means any content type other than `text/plain`.

You can declare a shared `consumes` attribute at the class level. Unlike most other request mapping attributes, however, when used at the class level, a method-level `consumes` attribute overrides rather than extends the class-level declaration.

|      | `MediaType` provides constants for commonly used media types — for example, `APPLICATION_JSON_VALUE` and `APPLICATION_XML_VALUE`. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

##### Producible Media Types

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-produces)

You can narrow the request mapping based on the `Accept` request header and the list of content types that a controller method produces, as the following example shows:

Java

Kotlin

```java
@GetMapping(path = "/pets/{petId}", produces = "application/json")
@ResponseBody
public Pet getPet(@PathVariable String petId) {
    // ...
}
```

The media type can specify a character set. Negated expressions are supported — for example, `!text/plain` means any content type other than `text/plain`.

You can declare a shared `produces` attribute at the class level. Unlike most other request mapping attributes, however, when used at the class level, a method-level `produces` attribute overrides rather than extend the class level declaration.

|      | `MediaType` provides constants for commonly used media types — e.g. `APPLICATION_JSON_VALUE`, `APPLICATION_XML_VALUE`. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

##### Parameters and Headers

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-params-and-headers)

You can narrow request mappings based on query parameter conditions. You can test for the presence of a query parameter (`myParam`), for its absence (`!myParam`), or for a specific value (`myParam=myValue`). The following examples tests for a parameter with a value:

Java

Kotlin

```java
@GetMapping(path = "/pets/{petId}", params = "myParam=myValue") 
public void findPet(@PathVariable String petId) {
    // ...
}
```

|      | Check that `myParam` equals `myValue`. |
| ---- | -------------------------------------- |
|      |                                        |

You can also use the same with request header conditions, as the follwing example shows:

Java

Kotlin

```java
@GetMapping(path = "/pets", headers = "myHeader=myValue") 
public void findPet(@PathVariable String petId) {
    // ...
}
```

|      | Check that `myHeader` equals `myValue`. |
| ---- | --------------------------------------- |
|      |                                         |

##### HTTP HEAD, OPTIONS

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-head-options)

`@GetMapping` and `@RequestMapping(method=HttpMethod.GET)` support HTTP HEAD transparently for request mapping purposes. Controller methods need not change. A response wrapper, applied in the `HttpHandler` server adapter, ensures a `Content-Length` header is set to the number of bytes written without actually writing to the response.

By default, HTTP OPTIONS is handled by setting the `Allow` response header to the list of HTTP methods listed in all `@RequestMapping` methods with matching URL patterns.

For a `@RequestMapping` without HTTP method declarations, the `Allow` header is set to `GET,HEAD,POST,PUT,PATCH,DELETE,OPTIONS`. Controller methods should always declare the supported HTTP methods (for example, by using the HTTP method specific variants — `@GetMapping`, `@PostMapping`, and others).

You can explicitly map a `@RequestMapping` method to HTTP HEAD and HTTP OPTIONS, but that is not necessary in the common case.

##### Custom Annotations

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-composed)

Spring WebFlux supports the use of [composed annotations](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#beans-meta-annotations) for request mapping. Those are annotations that are themselves meta-annotated with `@RequestMapping` and composed to redeclare a subset (or all) of the `@RequestMapping` attributes with a narrower, more specific purpose.

`@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`, and `@PatchMapping` are examples of composed annotations. They are provided, because, arguably, most controller methods should be mapped to a specific HTTP method versus using `@RequestMapping`, which, by default, matches to all HTTP methods. If you need an example of composed annotations, look at how those are declared.

Spring WebFlux also supports custom request mapping attributes with custom request matching logic. This is a more advanced option that requires sub-classing `RequestMappingHandlerMapping` and overriding the `getCustomMethodCondition` method, where you can check the custom attribute and return your own `RequestCondition`.

##### Explicit Registrations

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-registration)

You can programmatically register Handler methods, which can be used for dynamic registrations or for advanced cases, such as different instances of the same handler under different URLs. The following example shows how to do so:

Java

Kotlin

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

|      | Inject target handlers and the handler mapping for controllers. |
| ---- | ------------------------------------------------------------ |
|      | Prepare the request mapping metadata.                        |
|      | Get the handler method.                                      |
|      | Add the registration.                                        |

#### 1.4.3. Handler Methods

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-methods)

`@RequestMapping` handler methods have a flexible signature and can choose from a range of supported controller method arguments and return values.

##### Method Arguments

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-arguments)

The following table shows the supported controller method arguments.

Reactive types (Reactor, RxJava, [or other](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-reactive-libraries)) are supported on arguments that require blocking I/O (for example, reading the request body) to be resolved. This is marked in the Description column. Reactive types are not expected on arguments that do not require blocking.

JDK 1.8’s `java.util.Optional` is supported as a method argument in combination with annotations that have a `required` attribute (for example, `@RequestParam`, `@RequestHeader`, and others) and is equivalent to `required=false`.

| Controller method argument                                   | Description                                                  |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| `ServerWebExchange`                                          | Access to the full `ServerWebExchange` — container for the HTTP request and response, request and session attributes, `checkNotModified` methods, and others. |
| `ServerHttpRequest`, `ServerHttpResponse`                    | Access to the HTTP request or response.                      |
| `WebSession`                                                 | Access to the session. This does not force the start of a new session unless attributes are added. Supports reactive types. |
| `java.security.Principal`                                    | The currently authenticated user — possibly a specific `Principal` implementation class if known. Supports reactive types. |
| `org.springframework.http.HttpMethod`                        | The HTTP method of the request.                              |
| `java.util.Locale`                                           | The current request locale, determined by the most specific `LocaleResolver` available — in effect, the configured `LocaleResolver`/`LocaleContextResolver`. |
| `java.util.TimeZone` + `java.time.ZoneId`                    | The time zone associated with the current request, as determined by a `LocaleContextResolver`. |
| `@PathVariable`                                              | For access to URI template variables. See [URI Patterns](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-requestmapping-uri-templates). |
| `@MatrixVariable`                                            | For access to name-value pairs in URI path segments. See [Matrix Variables](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-matrix-variables). |
| `@RequestParam`                                              | For access to Servlet request parameters. Parameter values are converted to the declared method argument type. See [`@RequestParam`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-requestparam).Note that use of `@RequestParam` is optional — for example, to set its attributes. See “Any other argument” later in this table. |
| `@RequestHeader`                                             | For access to request headers. Header values are converted to the declared method argument type. See [`@RequestHeader`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-requestheader). |
| `@CookieValue`                                               | For access to cookies. Cookie values are converted to the declared method argument type. See [`@CookieValue`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-cookievalue). |
| `@RequestBody`                                               | For access to the HTTP request body. Body content is converted to the declared method argument type by using `HttpMessageReader` instances. Supports reactive types. See [`@RequestBody`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-requestbody). |
| `HttpEntity<B>`                                              | For access to request headers and body. The body is converted with `HttpMessageReader` instances. Supports reactive types. See [`HttpEntity`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-httpentity). |
| `@RequestPart`                                               | For access to a part in a `multipart/form-data` request. Supports reactive types. See [Multipart Content](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-multipart-forms) and [Multipart Data](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-multipart). |
| `java.util.Map`, `org.springframework.ui.Model`, and `org.springframework.ui.ModelMap`. | For access to the model that is used in HTML controllers and is exposed to templates as part of view rendering. |
| `@ModelAttribute`                                            | For access to an existing attribute in the model (instantiated if not present) with data binding and validation applied. See [`@ModelAttribute`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-modelattrib-method-args) as well as [`Model`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-modelattrib-methods) and [`DataBinder`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-initbinder).Note that use of `@ModelAttribute` is optional — for example, to set its attributes. See “Any other argument” later in this table. |
| `Errors`, `BindingResult`                                    | For access to errors from validation and data binding for a command object, i.e. a `@ModelAttribute` argument. An `Errors`, or `BindingResult` argument must be declared immediately after the validated method argument. |
| `SessionStatus` + class-level `@SessionAttributes`           | For marking form processing complete, which triggers cleanup of session attributes declared through a class-level `@SessionAttributes` annotation. See [`@SessionAttributes`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-sessionattributes) for more details. |
| `UriComponentsBuilder`                                       | For preparing a URL relative to the current request’s host, port, scheme, and context path. See [URI Links](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-uri-building). |
| `@SessionAttribute`                                          | For access to any session attribute — in contrast to model attributes stored in the session as a result of a class-level `@SessionAttributes` declaration. See [`@SessionAttribute`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-sessionattribute) for more details. |
| `@RequestAttribute`                                          | For access to request attributes. See [`@RequestAttribute`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-requestattrib) for more details. |
| Any other argument                                           | If a method argument is not matched to any of the above, it is, by default, resolved as a `@RequestParam` if it is a simple type, as determined by [BeanUtils#isSimpleProperty](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/beans/BeanUtils.html#isSimpleProperty-java.lang.Class-), or as a `@ModelAttribute`, otherwise. |

##### Return Values

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-return-types)

The following table shows the supported controller method return values. Note that reactive types from libraries such as Reactor, RxJava, [or other](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-reactive-libraries) are generally supported for all return values.

| Controller method return value                               | Description                                                  |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| `@ResponseBody`                                              | The return value is encoded through `HttpMessageWriter` instances and written to the response. See [`@ResponseBody`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-responsebody). |
| `HttpEntity<B>`, `ResponseEntity<B>`                         | The return value specifies the full response, including HTTP headers, and the body is encoded through `HttpMessageWriter` instances and written to the response. See [`ResponseEntity`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-responseentity). |
| `HttpHeaders`                                                | For returning a response with headers and no body.           |
| `String`                                                     | A view name to be resolved with `ViewResolver` instances and used together with the implicit model — determined through command objects and `@ModelAttribute` methods. The handler method can also programmatically enrich the model by declaring a `Model` argument (described [earlier](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-viewresolution-handling)). |
| `View`                                                       | A `View` instance to use for rendering together with the implicit model — determined through command objects and `@ModelAttribute` methods. The handler method can also programmatically enrich the model by declaring a `Model` argument (described [earlier](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-viewresolution-handling)). |
| `java.util.Map`, `org.springframework.ui.Model`              | Attributes to be added to the implicit model, with the view name implicitly determined based on the request path. |
| `@ModelAttribute`                                            | An attribute to be added to the model, with the view name implicitly determined based on the request path.Note that `@ModelAttribute` is optional. See “Any other return value” later in this table. |
| `Rendering`                                                  | An API for model and view rendering scenarios.               |
| `void`                                                       | A method with a `void`, possibly asynchronous (for example, `Mono<Void>`), return type (or a `null` return value) is considered to have fully handled the response if it also has a `ServerHttpResponse`, a `ServerWebExchange` argument, or an `@ResponseStatus` annotation. The same is also true if the controller has made a positive ETag or `lastModified` timestamp check. // TODO: See [Controllers](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-caching-etag-lastmodified) for details.If none of the above is true, a `void` return type can also indicate “no response body” for REST controllers or default view name selection for HTML controllers. |
| `Flux<ServerSentEvent>`, `Observable<ServerSentEvent>`, or other reactive type | Emit server-sent events. The `ServerSentEvent` wrapper can be omitted when only data needs to be written (however, `text/event-stream` must be requested or declared in the mapping through the `produces` attribute). |
| Any other return value                                       | If a return value is not matched to any of the above, it is, by default, treated as a view name, if it is `String` or `void` (default view name selection applies), or as a model attribute to be added to the model, unless it is a simple type, as determined by [BeanUtils#isSimpleProperty](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/beans/BeanUtils.html#isSimpleProperty-java.lang.Class-), in which case it remains unresolved. |

##### Type Conversion

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-typeconversion)

Some annotated controller method arguments that represent String-based request input (for example, `@RequestParam`, `@RequestHeader`, `@PathVariable`, `@MatrixVariable`, and `@CookieValue`) can require type conversion if the argument is declared as something other than `String`.

For such cases, type conversion is automatically applied based on the configured converters. By default, simple types (such as `int`, `long`, `Date`, and others) are supported. Type conversion can be customized through a `WebDataBinder` (see [`DataBinder`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-initbinder)) or by registering `Formatters` with the `FormattingConversionService` (see [Spring Field Formatting](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#format)).

A practical issue in type conversion is the treatment of an empty String source value. Such a value is treated as missing if it becomes `null` as a result of type conversion. This can be the case for `Long`, `UUID`, and other target types. If you want to allow `null` to be injected, either use the `required` flag on the argument annotation, or declare the argument as `@Nullable`.

##### Matrix Variables

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-matrix-variables)

[RFC 3986](https://tools.ietf.org/html/rfc3986#section-3.3) discusses name-value pairs in path segments. In Spring WebFlux, we refer to those as “matrix variables” based on an [“old post”](https://www.w3.org/DesignIssues/MatrixURIs.html) by Tim Berners-Lee, but they can be also be referred to as URI path parameters.

Matrix variables can appear in any path segment, with each variable separated by a semicolon and multiple values separated by commas — for example, `"/cars;color=red,green;year=2012"`. Multiple values can also be specified through repeated variable names — for example, `"color=red;color=green;color=blue"`.

Unlike Spring MVC, in WebFlux, the presence or absence of matrix variables in a URL does not affect request mappings. In other words, you are not required to use a URI variable to mask variable content. That said, if you want to access matrix variables from a controller method, you need to add a URI variable to the path segment where matrix variables are expected. The following example shows how to do so:

Java

Kotlin

```java
// GET /pets/42;q=11;r=22

@GetMapping("/pets/{petId}")
public void findPet(@PathVariable String petId, @MatrixVariable int q) {

    // petId == 42
    // q == 11
}
```

Given that all path segments can contain matrix variables, you may sometimes need to disambiguate which path variable the matrix variable is expected to be in, as the following example shows:

Java

Kotlin

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

You can define a matrix variable may be defined as optional and specify a default value as the following example shows:

Java

Kotlin

```java
// GET /pets/42

@GetMapping("/pets/{petId}")
public void findPet(@MatrixVariable(required=false, defaultValue="1") int q) {

    // q == 1
}
```

To get all matrix variables, use a `MultiValueMap`, as the following example shows:

Java

Kotlin

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

You can use the `@RequestParam` annotation to bind query parameters to a method argument in a controller. The following code snippet shows the usage:

Java

Kotlin

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

|      | Using `@RequestParam`. |
| ---- | ---------------------- |
|      |                        |

|      | The Servlet API “request parameter” concept conflates query parameters, form data, and multiparts into one. However, in WebFlux, each is accessed individually through `ServerWebExchange`. While `@RequestParam` binds to query parameters only, you can use data binding to apply query parameters, form data, and multiparts to a [command object](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-modelattrib-method-args). |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

Method parameters that use the `@RequestParam` annotation are required by default, but you can specify that a method parameter is optional by setting the required flag of a `@RequestParam` to `false` or by declaring the argument with a `java.util.Optional` wrapper.

Type conversion is applied automatically if the target method parameter type is not `String`. See [Type Conversion](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-typeconversion).

When a `@RequestParam` annotation is declared on a `Map<String, String>` or `MultiValueMap<String, String>` argument, the map is populated with all query parameters.

Note that use of `@RequestParam` is optional — for example, to set its attributes. By default, any argument that is a simple value type (as determined by [BeanUtils#isSimpleProperty](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/beans/BeanUtils.html#isSimpleProperty-java.lang.Class-)) and is not resolved by any other argument resolver is treated as if it were annotated with `@RequestParam`.

##### `@RequestHeader`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestheader)

You can use the `@RequestHeader` annotation to bind a request header to a method argument in a controller.

The following example shows a request with headers:

```
Host                    localhost:8080
Accept                  text/html,application/xhtml+xml,application/xml;q=0.9
Accept-Language         fr,en-gb;q=0.7,en;q=0.3
Accept-Encoding         gzip,deflate
Accept-Charset          ISO-8859-1,utf-8;q=0.7,*;q=0.7
Keep-Alive              300
```

The following example gets the value of the `Accept-Encoding` and `Keep-Alive` headers:

Java

Kotlin

```java
@GetMapping("/demo")
public void handle(
        @RequestHeader("Accept-Encoding") String encoding, 
        @RequestHeader("Keep-Alive") long keepAlive) { 
    //...
}
```

|      | Get the value of the `Accept-Encoging` header. |
| ---- | ---------------------------------------------- |
|      | Get the value of the `Keep-Alive` header.      |

Type conversion is applied automatically if the target method parameter type is not `String`. See [Type Conversion](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-typeconversion).

When a `@RequestHeader` annotation is used on a `Map<String, String>`, `MultiValueMap<String, String>`, or `HttpHeaders` argument, the map is populated with all header values.

|      | Built-in support is available for converting a comma-separated string into an array or collection of strings or other types known to the type conversion system. For example, a method parameter annotated with `@RequestHeader("Accept")` may be of type `String` but also of `String[]` or `List<String>`. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

##### `@CookieValue`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-cookievalue)

You can use the `@CookieValue` annotation to bind the value of an HTTP cookie to a method argument in a controller.

The following example shows a request with a cookie:

```
JSESSIONID=415A4AC178C59DACE0B2C9CA727CDD84
```

The following code sample demonstrates how to get the cookie value:

Java

Kotlin

```java
@GetMapping("/demo")
public void handle(@CookieValue("JSESSIONID") String cookie) { 
    //...
}
```

|      | Get the cookie value. |
| ---- | --------------------- |
|      |                       |

Type conversion is applied automatically if the target method parameter type is not `String`. See [Type Conversion](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-typeconversion).

##### `@ModelAttribute`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-modelattrib-method-args)

You can use the `@ModelAttribute` annotation on a method argument to access an attribute from the model or have it instantiated if not present. The model attribute is also overlain with the values of query parameters and form fields whose names match to field names. This is referred to as data binding, and it saves you from having to deal with parsing and converting individual query parameters and form fields. The following example binds an instance of `Pet`:

Java

Kotlin

```java
@PostMapping("/owners/{ownerId}/pets/{petId}/edit")
public String processSubmit(@ModelAttribute Pet pet) { } 
```

|      | Bind an instance of `Pet`. |
| ---- | -------------------------- |
|      |                            |

The `Pet` instance in the preceding example is resolved as follows:

- From the model if already added through [`Model`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-modelattrib-methods).
- From the HTTP session through [`@SessionAttributes`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-sessionattributes).
- From the invocation of a default constructor.
- From the invocation of a “primary constructor” with arguments that match query parameters or form fields. Argument names are determined through JavaBeans `@ConstructorProperties` or through runtime-retained parameter names in the bytecode.

After the model attribute instance is obtained, data binding is applied. The `WebExchangeDataBinder` class matches names of query parameters and form fields to field names on the target `Object`. Matching fields are populated after type conversion is applied where necessary. For more on data binding (and validation), see [Validation](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#validation). For more on customizing data binding, see [`DataBinder`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-initbinder).

Data binding can result in errors. By default, a `WebExchangeBindException` is raised, but, to check for such errors in the controller method, you can add a `BindingResult` argument immediately next to the `@ModelAttribute`, as the following example shows:

Java

Kotlin

```java
@PostMapping("/owners/{ownerId}/pets/{petId}/edit")
public String processSubmit(@ModelAttribute("pet") Pet pet, BindingResult result) { 
    if (result.hasErrors()) {
        return "petForm";
    }
    // ...
}
```

|      | Adding a `BindingResult`. |
| ---- | ------------------------- |
|      |                           |

You can automatically apply validation after data binding by adding the `javax.validation.Valid` annotation or Spring’s `@Validated` annotation (see also [Bean Validation](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#validation-beanvalidation) and [Spring validation](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#validation)). The following example uses the `@Valid` annotation:

Java

Kotlin

```java
@PostMapping("/owners/{ownerId}/pets/{petId}/edit")
public String processSubmit(@Valid @ModelAttribute("pet") Pet pet, BindingResult result) { 
    if (result.hasErrors()) {
        return "petForm";
    }
    // ...
}
```

|      | Using `@Valid` on a model attribute argument. |
| ---- | --------------------------------------------- |
|      |                                               |

Spring WebFlux, unlike Spring MVC, supports reactive types in the model — for example, `Mono<Account>` or `io.reactivex.Single<Account>`. You can declare a `@ModelAttribute` argument with or without a reactive type wrapper, and it will be resolved accordingly, to the actual value if necessary. However, note that, to use a `BindingResult` argument, you must declare the `@ModelAttribute` argument before it without a reactive type wrapper, as shown earlier. Alternatively, you can handle any errors through the reactive type, as the following example shows:

Java

Kotlin

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

Note that use of `@ModelAttribute` is optional — for example, to set its attributes. By default, any argument that is not a simple value type( as determined by [BeanUtils#isSimpleProperty](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/beans/BeanUtils.html#isSimpleProperty-java.lang.Class-)) and is not resolved by any other argument resolver is treated as if it were annotated with `@ModelAttribute`.

##### `@SessionAttributes`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-sessionattributes)

`@SessionAttributes` is used to store model attributes in the `WebSession` between requests. It is a type-level annotation that declares session attributes used by a specific controller. This typically lists the names of model attributes or types of model attributes that should be transparently stored in the session for subsequent requests to access.

Consider the following example:

Java

Kotlin

```java
@Controller
@SessionAttributes("pet") 
public class EditPetForm {
    // ...
}
```

|      | Using the `@SessionAttributes` annotation. |
| ---- | ------------------------------------------ |
|      |                                            |

On the first request, when a model attribute with the name, `pet`, is added to the model, it is automatically promoted to and saved in the `WebSession`. It remains there until another controller method uses a `SessionStatus` method argument to clear the storage, as the following example shows:

Java

Kotlin

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

|      | Using the `@SessionAttributes` annotation. |
| ---- | ------------------------------------------ |
|      | Using a `SessionStatus` variable.          |

##### `@SessionAttribute`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-sessionattribute)

If you need access to pre-existing session attributes that are managed globally (that is, outside the controller — for example, by a filter) and may or may not be present, you can use the `@SessionAttribute` annotation on a method parameter, as the following example shows:

Java

Kotlin

```java
@GetMapping("/")
public String handle(@SessionAttribute User user) { 
    // ...
}
```

|      | Using `@SessionAttribute`. |
| ---- | -------------------------- |
|      |                            |

For use cases that require adding or removing session attributes, consider injecting `WebSession` into the controller method.

For temporary storage of model attributes in the session as part of a controller workflow, consider using `SessionAttributes`, as described in [`@SessionAttributes`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-sessionattributes).

##### `@RequestAttribute`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestattrib)

Similarly to `@SessionAttribute`, you can use the `@RequestAttribute` annotation to access pre-existing request attributes created earlier (for example, by a `WebFilter`), as the following example shows:

Java

Kotlin

```java
@GetMapping("/")
public String handle(@RequestAttribute Client client) { 
    // ...
}
```

|      | Using `@RequestAttribute`. |
| ---- | -------------------------- |
|      |                            |

##### Multipart Content

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-multipart-forms)

As explained in [Multipart Data](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-multipart), `ServerWebExchange` provides access to multipart content. The best way to handle a file upload form (for example, from a browser) in a controller is through data binding to a [command object](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-modelattrib-method-args), as the following example shows:

Java

Kotlin

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

You can also submit multipart requests from non-browser clients in a RESTful service scenario. The following example uses a file along with JSON:

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

You can access individual parts with `@RequestPart`, as the following example shows:

Java

Kotlin

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

To deserialize the raw part content (for example, to JSON — similar to `@RequestBody`), you can declare a concrete target `Object`, instead of `Part`, as the following example shows:

Java

Kotlin

```java
@PostMapping("/")
public String handle(@RequestPart("meta-data") MetaData metadata) { 
    // ...
}
```

|      | Using `@RequestPart` to get the metadata. |
| ---- | ----------------------------------------- |
|      |                                           |

You can use `@RequestPart` in combination with `javax.validation.Valid` or Spring’s `@Validated` annotation, which causes Standard Bean Validation to be applied. Validation errors lead to a `WebExchangeBindException` that results in a 400 (BAD_REQUEST) response. The exception contains a `BindingResult` with the error details and can also be handled in the controller method by declaring the argument with an async wrapper and then using error related operators:

Java

Kotlin

```java
@PostMapping("/")
public String handle(@Valid @RequestPart("meta-data") Mono<MetaData> metadata) {
    // use one of the onError* operators...
}
```

To access all multipart data as a `MultiValueMap`, you can use `@RequestBody`, as the following example shows:

Java

Kotlin

```java
@PostMapping("/")
public String handle(@RequestBody Mono<MultiValueMap<String, Part>> parts) { 
    // ...
}
```

|      | Using `@RequestBody`. |
| ---- | --------------------- |
|      |                       |

To access multipart data sequentially, in streaming fashion, you can use `@RequestBody` with `Flux<Part>` (or `Flow<Part>` in Kotlin) instead, as the following example shows:

Java

Kotlin

```java
@PostMapping("/")
public String handle(@RequestBody Flux<Part> parts) { 
    // ...
}
```

|      | Using `@RequestBody`. |
| ---- | --------------------- |
|      |                       |

##### `@RequestBody`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestbody)

You can use the `@RequestBody` annotation to have the request body read and deserialized into an `Object` through an [HttpMessageReader](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-codecs). The following example uses a `@RequestBody` argument:

Java

Kotlin

```java
@PostMapping("/accounts")
public void handle(@RequestBody Account account) {
    // ...
}
```

Unlike Spring MVC, in WebFlux, the `@RequestBody` method argument supports reactive types and fully non-blocking reading and (client-to-server) streaming.

Java

Kotlin

```java
@PostMapping("/accounts")
public void handle(@RequestBody Mono<Account> account) {
    // ...
}
```

You can use the [HTTP message codecs](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config-message-codecs) option of the [WebFlux Config](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config) to configure or customize message readers.

You can use `@RequestBody` in combination with `javax.validation.Valid` or Spring’s `@Validated` annotation, which causes Standard Bean Validation to be applied. Validation errors cause a `WebExchangeBindException`, which results in a 400 (BAD_REQUEST) response. The exception contains a `BindingResult` with error details and can be handled in the controller method by declaring the argument with an async wrapper and then using error related operators:

Java

Kotlin

```java
@PostMapping("/accounts")
public void handle(@Valid @RequestBody Mono<Account> account) {
    // use one of the onError* operators...
}
```

##### `HttpEntity`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-httpentity)

`HttpEntity` is more or less identical to using [`@RequestBody`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-requestbody) but is based on a container object that exposes request headers and the body. The following example uses an `HttpEntity`:

Java

Kotlin

```java
@PostMapping("/accounts")
public void handle(HttpEntity<Account> entity) {
    // ...
}
```

##### `@ResponseBody`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-responsebody)

You can use the `@ResponseBody` annotation on a method to have the return serialized to the response body through an [HttpMessageWriter](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-codecs). The following example shows how to do so:

Java

Kotlin

```java
@GetMapping("/accounts/{id}")
@ResponseBody
public Account handle() {
    // ...
}
```

`@ResponseBody` is also supported at the class level, in which case it is inherited by all controller methods. This is the effect of `@RestController`, which is nothing more than a meta-annotation marked with `@Controller` and `@ResponseBody`.

`@ResponseBody` supports reactive types, which means you can return Reactor or RxJava types and have the asynchronous values they produce rendered to the response. For additional details, see [Streaming](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-codecs-streaming) and [JSON rendering](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-codecs-jackson).

You can combine `@ResponseBody` methods with JSON serialization views. See [Jackson JSON](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-jackson) for details.

You can use the [HTTP message codecs](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config-message-codecs) option of the [WebFlux Config](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config) to configure or customize message writing.

##### `ResponseEntity`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-responseentity)

`ResponseEntity` is like [`@ResponseBody`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-responsebody) but with status and headers. For example:

Java

Kotlin

```java
@GetMapping("/something")
public ResponseEntity<String> handle() {
    String body = ... ;
    String etag = ... ;
    return ResponseEntity.ok().eTag(etag).build(body);
}
```

WebFlux supports using a single value [reactive type](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-reactive-libraries) to produce the `ResponseEntity` asynchronously, and/or single and multi-value reactive types for the body.

##### Jackson JSON

Spring offers support for the Jackson JSON library.

###### JSON Views

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-jackson)

Spring WebFlux provides built-in support for [Jackson’s Serialization Views](https://www.baeldung.com/jackson-json-view-annotation), which allows rendering only a subset of all fields in an `Object`. To use it with `@ResponseBody` or `ResponseEntity` controller methods, you can use Jackson’s `@JsonView` annotation to activate a serialization view class, as the following example shows:

Java

Kotlin

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

|      | `@JsonView` allows an array of view classes but you can only specify only one per controller method. Use a composite interface if you need to activate multiple views. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

#### 1.4.4. `Model`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-modelattrib-methods)

You can use the `@ModelAttribute` annotation:

- On a [method argument](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-modelattrib-method-args) in `@RequestMapping` methods to create or access an Object from the model and to bind it to the request through a `WebDataBinder`.
- As a method-level annotation in `@Controller` or `@ControllerAdvice` classes, helping to initialize the model prior to any `@RequestMapping` method invocation.
- On a `@RequestMapping` method to mark its return value as a model attribute.

This section discusses `@ModelAttribute` methods, or the second item from the preceding list. A controller can have any number of `@ModelAttribute` methods. All such methods are invoked before `@RequestMapping` methods in the same controller. A `@ModelAttribute` method can also be shared across controllers through `@ControllerAdvice`. See the section on [Controller Advice](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-controller-advice) for more details.

`@ModelAttribute` methods have flexible method signatures. They support many of the same arguments as `@RequestMapping` methods (except for `@ModelAttribute` itself and anything related to the request body).

The following example uses a `@ModelAttribute` method:

Java

Kotlin

```java
@ModelAttribute
public void populateModel(@RequestParam String number, Model model) {
    model.addAttribute(accountRepository.findAccount(number));
    // add more ...
}
```

The following example adds one attribute only:

Java

Kotlin

```java
@ModelAttribute
public Account addAccount(@RequestParam String number) {
    return accountRepository.findAccount(number);
}
```

|      | When a name is not explicitly specified, a default name is chosen based on the type, as explained in the javadoc for [`Conventions`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/core/Conventions.html). You can always assign an explicit name by using the overloaded `addAttribute` method or through the name attribute on `@ModelAttribute` (for a return value). |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

Spring WebFlux, unlike Spring MVC, explicitly supports reactive types in the model (for example, `Mono<Account>` or `io.reactivex.Single<Account>`). Such asynchronous model attributes can be transparently resolved (and the model updated) to their actual values at the time of `@RequestMapping` invocation, provided a `@ModelAttribute` argument is declared without a wrapper, as the following example shows:

Java

Kotlin

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

In addition, any model attributes that have a reactive type wrapper are resolved to their actual values (and the model updated) just prior to view rendering.

You can also use `@ModelAttribute` as a method-level annotation on `@RequestMapping` methods, in which case the return value of the `@RequestMapping` method is interpreted as a model attribute. This is typically not required, as it is the default behavior in HTML controllers, unless the return value is a `String` that would otherwise be interpreted as a view name. `@ModelAttribute` can also help to customize the model attribute name, as the following example shows:

Java

Kotlin

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

`@Controller` or `@ControllerAdvice` classes can have `@InitBinder` methods, to initialize instances of `WebDataBinder`. Those, in turn, are used to:

- Bind request parameters (that is, form data or query) to a model object.
- Convert `String`-based request values (such as request parameters, path variables, headers, cookies, and others) to the target type of controller method arguments.
- Format model object values as `String` values when rendering HTML forms.

`@InitBinder` methods can register controller-specific `java.beans.PropertyEditor` or Spring `Converter` and `Formatter` components. In addition, you can use the [WebFlux Java configuration](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config-conversion) to register `Converter` and `Formatter` types in a globally shared `FormattingConversionService`.

`@InitBinder` methods support many of the same arguments that `@RequestMapping` methods do, except for `@ModelAttribute` (command object) arguments. Typically, they are declared with a `WebDataBinder` argument, for registrations, and a `void` return value. The following example uses the `@InitBinder` annotation:

Java

Kotlin

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

|      | Using the `@InitBinder` annotation. |
| ---- | ----------------------------------- |
|      |                                     |

Alternatively, when using a `Formatter`-based setup through a shared `FormattingConversionService`, you could re-use the same approach and register controller-specific `Formatter` instances, as the following example shows:

Java

Kotlin

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

|      | Adding a custom formatter (a `DateFormatter`, in this case). |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

#### 1.4.6. Managing Exceptions

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-exceptionhandler)

`@Controller` and [@ControllerAdvice](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-ann-controller-advice) classes can have `@ExceptionHandler` methods to handle exceptions from controller methods. The following example includes such a handler method:

Java

Kotlin

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

|      | Declaring an `@ExceptionHandler`. |
| ---- | --------------------------------- |
|      |                                   |

The exception can match against a top-level exception being propagated (that is, a direct `IOException` being thrown) or against the immediate cause within a top-level wrapper exception (for example, an `IOException` wrapped inside an `IllegalStateException`).

For matching exception types, preferably declare the target exception as a method argument, as shown in the preceding example. Alternatively, the annotation declaration can narrow the exception types to match. We generally recommend being as specific as possible in the argument signature and to declare your primary root exception mappings on a `@ControllerAdvice` prioritized with a corresponding order. See [the MVC section](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-exceptionhandler) for details.

|      | An `@ExceptionHandler` method in WebFlux supports the same method arguments and return values as a `@RequestMapping` method, with the exception of request body- and `@ModelAttribute`-related method arguments. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

Support for `@ExceptionHandler` methods in Spring WebFlux is provided by the `HandlerAdapter` for `@RequestMapping` methods. See [`DispatcherHandler`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-dispatcher-handler) for more detail.

##### REST API exceptions

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-rest-exceptions)

A common requirement for REST services is to include error details in the body of the response. The Spring Framework does not automatically do so, because the representation of error details in the response body is application-specific. However, a `@RestController` can use `@ExceptionHandler` methods with a `ResponseEntity` return value to set the status and the body of the response. Such methods can also be declared in `@ControllerAdvice` classes to apply them globally.

|      | Note that Spring WebFlux does not have an equivalent for the Spring MVC `ResponseEntityExceptionHandler`, because WebFlux raises only `ResponseStatusException` (or subclasses thereof), and those do not need to be translated to an HTTP status code. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

#### 1.4.7. Controller Advice

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-controller-advice)

Typically, the `@ExceptionHandler`, `@InitBinder`, and `@ModelAttribute` methods apply within the `@Controller` class (or class hierarchy) in which they are declared. If you want such methods to apply more globally (across controllers), you can declare them in a class annotated with `@ControllerAdvice` or `@RestControllerAdvice`.

`@ControllerAdvice` is annotated with `@Component`, which means that such classes can be registered as Spring beans through [component scanning](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#beans-java-instantiating-container-scan). `@RestControllerAdvice` is a composed annotation that is annotated with both `@ControllerAdvice` and `@ResponseBody`, which essentially means `@ExceptionHandler` methods are rendered to the response body through message conversion (versus view resolution or template rendering).

On startup, the infrastructure classes for `@RequestMapping` and `@ExceptionHandler` methods detect Spring beans annotated with `@ControllerAdvice` and then apply their methods at runtime. Global `@ExceptionHandler` methods (from a `@ControllerAdvice`) are applied *after* local ones (from the `@Controller`). By contrast, global `@ModelAttribute` and `@InitBinder` methods are applied *before* local ones.

By default, `@ControllerAdvice` methods apply to every request (that is, all controllers), but you can narrow that down to a subset of controllers by using attributes on the annotation, as the following example shows:

Java

Kotlin

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

The selectors in the preceding example are evaluated at runtime and may negatively impact performance if used extensively. See the [`@ControllerAdvice`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/bind/annotation/ControllerAdvice.html) javadoc for more details.

### 1.5. Functional Endpoints

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn)

Spring WebFlux includes WebFlux.fn, a lightweight functional programming model in which functions are used to route and handle requests and contracts are designed for immutability. It is an alternative to the annotation-based programming model but otherwise runs on the same [Reactive Core](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-reactive-spring-web) foundation.

#### 1.5.1. Overview

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn-overview)

In WebFlux.fn, an HTTP request is handled with a `HandlerFunction`: a function that takes `ServerRequest` and returns a delayed `ServerResponse` (i.e. `Mono<ServerResponse>`). Both the request and the response object have immutable contracts that offer JDK 8-friendly access to the HTTP request and response. `HandlerFunction` is the equivalent of the body of a `@RequestMapping` method in the annotation-based programming model.

Incoming requests are routed to a handler function with a `RouterFunction`: a function that takes `ServerRequest` and returns a delayed `HandlerFunction` (i.e. `Mono<HandlerFunction>`). When the router function matches, a handler function is returned; otherwise an empty Mono. `RouterFunction` is the equivalent of a `@RequestMapping` annotation, but with the major difference that router functions provide not just data, but also behavior.

`RouterFunctions.route()` provides a router builder that facilitates the creation of routers, as the following example shows:

Java

Kotlin

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

One way to run a `RouterFunction` is to turn it into an `HttpHandler` and install it through one of the built-in [server adapters](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-httphandler):

- `RouterFunctions.toHttpHandler(RouterFunction)`
- `RouterFunctions.toHttpHandler(RouterFunction, HandlerStrategies)`

Most applications can run through the WebFlux Java configuration, see [Running a Server](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-fn-running).

#### 1.5.2. HandlerFunction

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn-handler-functions)

`ServerRequest` and `ServerResponse` are immutable interfaces that offer JDK 8-friendly access to the HTTP request and response. Both request and response provide [Reactive Streams](https://www.reactive-streams.org/) back pressure against the body streams. The request body is represented with a Reactor `Flux` or `Mono`. The response body is represented with any Reactive Streams `Publisher`, including `Flux` and `Mono`. For more on that, see [Reactive Libraries](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-reactive-libraries).

##### ServerRequest

`ServerRequest` provides access to the HTTP method, URI, headers, and query parameters, while access to the body is provided through the `body` methods.

The following example extracts the request body to a `Mono<String>`:

Java

Kotlin

```java
Mono<String> string = request.bodyToMono(String.class);
```

The following example extracts the body to a `Flux<Person>` (or a `Flow<Person>` in Kotlin), where `Person` objects are decoded from someserialized form, such as JSON or XML:

Java

Kotlin

```java
Flux<Person> people = request.bodyToFlux(Person.class);
```

The preceding examples are shortcuts that use the more general `ServerRequest.body(BodyExtractor)`, which accepts the `BodyExtractor` functional strategy interface. The utility class `BodyExtractors` provides access to a number of instances. For example, the preceding examples can also be written as follows:

Java

Kotlin

```java
Mono<String> string = request.body(BodyExtractors.toMono(String.class));
Flux<Person> people = request.body(BodyExtractors.toFlux(Person.class));
```

The following example shows how to access form data:

Java

Kotlin

```java
Mono<MultiValueMap<String, String> map = request.formData();
```

The following example shows how to access multipart data as a map:

Java

Kotlin

```java
Mono<MultiValueMap<String, Part> map = request.multipartData();
```

The following example shows how to access multiparts, one at a time, in streaming fashion:

Java

Kotlin

```java
Flux<Part> parts = request.body(BodyExtractors.toParts());
```

##### ServerResponse

`ServerResponse` provides access to the HTTP response and, since it is immutable, you can use a `build` method to create it. You can use the builder to set the response status, to add response headers, or to provide a body. The following example creates a 200 (OK) response with JSON content:

Java

Kotlin

```java
Mono<Person> person = ...
ServerResponse.ok().contentType(MediaType.APPLICATION_JSON).body(person, Person.class);
```

The following example shows how to build a 201 (CREATED) response with a `Location` header and no body:

Java

Kotlin

```java
URI location = ...
ServerResponse.created(location).build();
```

Depending on the codec used, it is possible to pass hint parameters to customize how the body is serialized or deserialized. For example, to specify a [Jackson JSON view](https://www.baeldung.com/jackson-json-view-annotation):

Java

Kotlin

```java
ServerResponse.ok().hint(Jackson2CodecSupport.JSON_VIEW_HINT, MyJacksonView.class).body(...);
```

##### Handler Classes

We can write a handler function as a lambda, as the following example shows:

Java

Kotlin

```java
HandlerFunction<ServerResponse> helloWorld =
  request -> ServerResponse.ok().bodyValue("Hello World");
```

That is convenient, but in an application we need multiple functions, and multiple inline lambda’s can get messy. Therefore, it is useful to group related handler functions together into a handler class, which has a similar role as `@Controller` in an annotation-based application. For example, the following class exposes a reactive `Person` repository:

Java

Kotlin

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

|      | `listPeople` is a handler function that returns all `Person` objects found in the repository as JSON. |
| ---- | ------------------------------------------------------------ |
|      | `createPerson` is a handler function that stores a new `Person` contained in the request body. Note that `PersonRepository.savePerson(Person)` returns `Mono<Void>`: an empty `Mono` that emits a completion signal when the person has been read from the request and stored. So we use the `build(Publisher<Void>)` method to send a response when that completion signal is received (that is, when the `Person` has been saved). |
|      | `getPerson` is a handler function that returns a single person, identified by the `id` path variable. We retrieve that `Person` from the repository and create a JSON response, if it is found. If it is not found, we use `switchIfEmpty(Mono<T>)` to return a 404 Not Found response. |

##### Validation

A functional endpoint can use Spring’s [validation facilities](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#validation) to apply validation to the request body. For example, given a custom Spring [Validator](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#validation) implementation for a `Person`:

Java

Kotlin

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

|      | Create `Validator` instance.        |
| ---- | ----------------------------------- |
|      | Apply validation.                   |
|      | Raise exception for a 400 response. |

Handlers can also use the standard bean validation API (JSR-303) by creating and injecting a global `Validator` instance based on `LocalValidatorFactoryBean`. See [Spring Validation](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#validation-beanvalidation).

#### 1.5.3. `RouterFunction`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#webmvc-fn-router-functions)

Router functions are used to route the requests to the corresponding `HandlerFunction`. Typically, you do not write router functions yourself, but rather use a method on the `RouterFunctions` utility class to create one. `RouterFunctions.route()` (no parameters) provides you with a fluent builder for creating a router function, whereas `RouterFunctions.route(RequestPredicate, HandlerFunction)` offers a direct way to create a router.

Generally, it is recommended to use the `route()` builder, as it provides convenient short-cuts for typical mapping scenarios without requiring hard-to-discover static imports. For instance, the router function builder offers the method `GET(String, HandlerFunction)` to create a mapping for GET requests; and `POST(String, HandlerFunction)` for POSTs.

Besides HTTP method-based mapping, the route builder offers a way to introduce additional predicates when mapping to requests. For each HTTP method there is an overloaded variant that takes a `RequestPredicate` as a parameter, though which additional constraints can be expressed.

##### Predicates

You can write your own `RequestPredicate`, but the `RequestPredicates` utility class offers commonly used implementations, based on the request path, HTTP method, content-type, and so on. The following example uses a request predicate to create a constraint based on the `Accept` header:

Java

Kotlin

```java
RouterFunction<ServerResponse> route = RouterFunctions.route()
    .GET("/hello-world", accept(MediaType.TEXT_PLAIN),
        request -> ServerResponse.ok().bodyValue("Hello World")).build();
```

You can compose multiple request predicates together by using:

- `RequestPredicate.and(RequestPredicate)` — both must match.
- `RequestPredicate.or(RequestPredicate)` — either can match.

Many of the predicates from `RequestPredicates` are composed. For example, `RequestPredicates.GET(String)` is composed from `RequestPredicates.method(HttpMethod)` and `RequestPredicates.path(String)`. The example shown above also uses two request predicates, as the builder uses `RequestPredicates.GET` internally, and composes that with the `accept` predicate.

##### Routes

Router functions are evaluated in order: if the first route does not match, the second is evaluated, and so on. Therefore, it makes sense to declare more specific routes before general ones. Note that this behavior is different from the annotation-based programming model, where the "most specific" controller method is picked automatically.

When using the router function builder, all defined routes are composed into one `RouterFunction` that is returned from `build()`. There are also other ways to compose multiple router functions together:

- `add(RouterFunction)` on the `RouterFunctions.route()` builder
- `RouterFunction.and(RouterFunction)`
- `RouterFunction.andRoute(RequestPredicate, HandlerFunction)` — shortcut for `RouterFunction.and()` with nested `RouterFunctions.route()`.

The following example shows the composition of four routes:

Java

Kotlin

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

|      | `GET /person/{id}` with an `Accept` header that matches JSON is routed to `PersonHandler.getPerson` |
| ---- | ------------------------------------------------------------ |
|      | `GET /person` with an `Accept` header that matches JSON is routed to `PersonHandler.listPeople` |
|      | `POST /person` with no additional predicates is mapped to `PersonHandler.createPerson`, and |
|      | `otherRoute` is a router function that is created elsewhere, and added to the route built. |

##### Nested Routes

It is common for a group of router functions to have a shared predicate, for instance a shared path. In the example above, the shared predicate would be a path predicate that matches `/person`, used by three of the routes. When using annotations, you would remove this duplication by using a type-level `@RequestMapping` annotation that maps to `/person`. In WebFlux.fn, path predicates can be shared through the `path` method on the router function builder. For instance, the last few lines of the example above can be improved in the following way by using nested routes:

Java

Kotlin

```java
RouterFunction<ServerResponse> route = route()
    .path("/person", builder -> builder 
        .GET("/{id}", accept(APPLICATION_JSON), handler::getPerson)
        .GET(accept(APPLICATION_JSON), handler::listPeople)
        .POST("/person", handler::createPerson))
    .build();
```

|      | Note that second parameter of `path` is a consumer that takes the a router builder. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

Though path-based nesting is the most common, you can nest on any kind of predicate by using the `nest` method on the builder. The above still contains some duplication in the form of the shared `Accept`-header predicate. We can further improve by using the `nest` method together with `accept`:

Java

Kotlin

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

How do you run a router function in an HTTP server? A simple option is to convert a router function to an `HttpHandler` by using one of the following:

- `RouterFunctions.toHttpHandler(RouterFunction)`
- `RouterFunctions.toHttpHandler(RouterFunction, HandlerStrategies)`

You can then use the returned `HttpHandler` with a number of server adapters by following [HttpHandler](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-httphandler) for server-specific instructions.

A more typical option, also used by Spring Boot, is to run with a [`DispatcherHandler`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-dispatcher-handler)-based setup through the [WebFlux Config](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config), which uses Spring configuration to declare the components required to process requests. The WebFlux Java configuration declares the following infrastructure components to support functional endpoints:

- `RouterFunctionMapping`: Detects one or more `RouterFunction<?>` beans in the Spring configuration, combines them through `RouterFunction.andOther`, and routes requests to the resulting composed `RouterFunction`.
- `HandlerFunctionAdapter`: Simple adapter that lets `DispatcherHandler` invoke a `HandlerFunction` that was mapped to a request.
- `ServerResponseResultHandler`: Handles the result from the invocation of a `HandlerFunction` by invoking the `writeTo` method of the `ServerResponse`.

The preceding components let functional endpoints fit within the `DispatcherHandler` request processing lifecycle and also (potentially) run side by side with annotated controllers, if any are declared. It is also how functional endpoints are enabled by the Spring Boot WebFlux starter.

The following example shows a WebFlux Java configuration (see [DispatcherHandler](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-dispatcher-handler) for how to run it):

Java

Kotlin

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

You can filter handler functions by using the `before`, `after`, or `filter` methods on the routing function builder. With annotations, you can achieve similar functionality by using `@ControllerAdvice`, a `ServletFilter`, or both. The filter will apply to all routes that are built by the builder. This means that filters defined in nested routes do not apply to "top-level" routes. For instance, consider the following example:

Java

Kotlin

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

|      | The `before` filter that adds a custom request header is only applied to the two GET routes. |
| ---- | ------------------------------------------------------------ |
|      | The `after` filter that logs the response is applied to all routes, including the nested ones. |

The `filter` method on the router builder takes a `HandlerFilterFunction`: a function that takes a `ServerRequest` and `HandlerFunction` and returns a `ServerResponse`. The handler function parameter represents the next element in the chain. This is typically the handler that is routed to, but it can also be another filter if multiple are applied.

Now we can add a simple security filter to our route, assuming that we have a `SecurityManager` that can determine whether a particular path is allowed. The following example shows how to do so:

Java

Kotlin

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

The preceding example demonstrates that invoking the `next.handle(ServerRequest)` is optional. We only let the handler function be run when access is allowed.

Besides using the `filter` method on the router function builder, it is possible to apply a filter to an existing router function via `RouterFunction.filter(HandlerFilterFunction)`.

|      | CORS support for functional endpoints is provided through a dedicated [`CorsWebFilter`](https://docs.spring.io/spring-framework/docs/current/reference/html/webflux-cors.html#webflux-cors-webfilter). |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

### 1.6. URI Links

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-uri-building)

This section describes various options available in the Spring Framework to prepare URIs.

#### 1.6.1. UriComponents

Spring MVC and Spring WebFlux

`UriComponentsBuilder` helps to build URI’s from URI templates with variables, as the following example shows:

Java

Kotlin

```java
UriComponents uriComponents = UriComponentsBuilder
        .fromUriString("https://example.com/hotels/{hotel}")  
        .queryParam("q", "{q}")  
        .encode() 
        .build(); 

URI uri = uriComponents.expand("Westin", "123").toUri();  
```

|      | Static factory method with a URI template.                  |
| ---- | ----------------------------------------------------------- |
|      | Add or replace URI components.                              |
|      | Request to have the URI template and URI variables encoded. |
|      | Build a `UriComponents`.                                    |
|      | Expand variables and obtain the `URI`.                      |

The preceding example can be consolidated into one chain and shortened with `buildAndExpand`, as the following example shows:

Java

Kotlin

```java
URI uri = UriComponentsBuilder
        .fromUriString("https://example.com/hotels/{hotel}")
        .queryParam("q", "{q}")
        .encode()
        .buildAndExpand("Westin", "123")
        .toUri();
```

You can shorten it further by going directly to a URI (which implies encoding), as the following example shows:

Java

Kotlin

```java
URI uri = UriComponentsBuilder
        .fromUriString("https://example.com/hotels/{hotel}")
        .queryParam("q", "{q}")
        .build("Westin", "123");
```

You shorter it further still with a full URI template, as the following example shows:

Java

Kotlin

```java
URI uri = UriComponentsBuilder
        .fromUriString("https://example.com/hotels/{hotel}?q={q}")
        .build("Westin", "123");
```

#### 1.6.2. UriBuilder

Spring MVC and Spring WebFlux

[`UriComponentsBuilder`](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#web-uricomponents) implements `UriBuilder`. You can create a `UriBuilder`, in turn, with a `UriBuilderFactory`. Together, `UriBuilderFactory` and `UriBuilder` provide a pluggable mechanism to build URIs from URI templates, based on shared configuration, such as a base URL, encoding preferences, and other details.

You can configure `RestTemplate` and `WebClient` with a `UriBuilderFactory` to customize the preparation of URIs. `DefaultUriBuilderFactory` is a default implementation of `UriBuilderFactory` that uses `UriComponentsBuilder` internally and exposes shared configuration options.

The following example shows how to configure a `RestTemplate`:

Java

Kotlin

```java
// import org.springframework.web.util.DefaultUriBuilderFactory.EncodingMode;

String baseUrl = "https://example.org";
DefaultUriBuilderFactory factory = new DefaultUriBuilderFactory(baseUrl);
factory.setEncodingMode(EncodingMode.TEMPLATE_AND_VALUES);

RestTemplate restTemplate = new RestTemplate();
restTemplate.setUriTemplateHandler(factory);
```

The following example configures a `WebClient`:

Java

Kotlin

```java
// import org.springframework.web.util.DefaultUriBuilderFactory.EncodingMode;

String baseUrl = "https://example.org";
DefaultUriBuilderFactory factory = new DefaultUriBuilderFactory(baseUrl);
factory.setEncodingMode(EncodingMode.TEMPLATE_AND_VALUES);

WebClient client = WebClient.builder().uriBuilderFactory(factory).build();
```

In addition, you can also use `DefaultUriBuilderFactory` directly. It is similar to using `UriComponentsBuilder` but, instead of static factory methods, it is an actual instance that holds configuration and preferences, as the following example shows:

Java

Kotlin

```java
String baseUrl = "https://example.com";
DefaultUriBuilderFactory uriBuilderFactory = new DefaultUriBuilderFactory(baseUrl);

URI uri = uriBuilderFactory.uriString("/hotels/{hotel}")
        .queryParam("q", "{q}")
        .build("Westin", "123");
```

#### 1.6.3. URI Encoding

Spring MVC and Spring WebFlux

`UriComponentsBuilder` exposes encoding options at two levels:

- [UriComponentsBuilder#encode()](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/util/UriComponentsBuilder.html#encode--): Pre-encodes the URI template first and then strictly encodes URI variables when expanded.
- [UriComponents#encode()](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/util/UriComponents.html#encode--): Encodes URI components *after* URI variables are expanded.

Both options replace non-ASCII and illegal characters with escaped octets. However, the first option also replaces characters with reserved meaning that appear in URI variables.

|      | Consider ";", which is legal in a path but has reserved meaning. The first option replaces ";" with "%3B" in URI variables but not in the URI template. By contrast, the second option never replaces ";", since it is a legal character in a path. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

For most cases, the first option is likely to give the expected result, because it treats URI variables as opaque data to be fully encoded, while option 2 is useful only if URI variables intentionally contain reserved characters.

The following example uses the first option:

Java

Kotlin

```java
URI uri = UriComponentsBuilder.fromPath("/hotel list/{city}")
        .queryParam("q", "{q}")
        .encode()
        .buildAndExpand("New York", "foo+bar")
        .toUri();

// Result is "/hotel%20list/New%20York?q=foo%2Bbar"
```

You can shorten the preceding example by going directly to the URI (which implies encoding), as the following example shows:

Java

Kotlin

```java
URI uri = UriComponentsBuilder.fromPath("/hotel list/{city}")
        .queryParam("q", "{q}")
        .build("New York", "foo+bar")
```

You can shorten it further still with a full URI template, as the following example shows:

Java

Kotlin

```java
URI uri = UriComponentsBuilder.fromPath("/hotel list/{city}?q={q}")
        .build("New York", "foo+bar")
```

The `WebClient` and the `RestTemplate` expand and encode URI templates internally through the `UriBuilderFactory` strategy. Both can be configured with a custom strategy. as the following example shows:

Java

Kotlin

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

The `DefaultUriBuilderFactory` implementation uses `UriComponentsBuilder` internally to expand and encode URI templates. As a factory, it provides a single place to configure the approach to encoding, based on one of the below encoding modes:

- `TEMPLATE_AND_VALUES`: Uses `UriComponentsBuilder#encode()`, corresponding to the first option in the earlier list, to pre-encode the URI template and strictly encode URI variables when expanded.
- `VALUES_ONLY`: Does not encode the URI template and, instead, applies strict encoding to URI variables through `UriUtils#encodeUriUriVariables` prior to expanding them into the template.
- `URI_COMPONENT`: Uses `UriComponents#encode()`, corresponding to the second option in the earlier list, to encode URI component value *after* URI variables are expanded.
- `NONE`: No encoding is applied.

The `RestTemplate` is set to `EncodingMode.URI_COMPONENT` for historic reasons and for backwards compatibility. The `WebClient` relies on the default value in `DefaultUriBuilderFactory`, which was changed from `EncodingMode.URI_COMPONENT` in 5.0.x to `EncodingMode.TEMPLATE_AND_VALUES` in 5.1.

### 1.7. CORS

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors)

Spring WebFlux lets you handle CORS (Cross-Origin Resource Sharing). This section describes how to do so.

#### 1.7.1. Introduction

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors-intro)

For security reasons, browsers prohibit AJAX calls to resources outside the current origin. For example, you could have your bank account in one tab and evil.com in another. Scripts from evil.com should not be able to make AJAX requests to your bank API with your credentials — for example, withdrawing money from your account!

Cross-Origin Resource Sharing (CORS) is a [W3C specification](https://www.w3.org/TR/cors/) implemented by [most browsers](https://caniuse.com/#feat=cors) that lets you specify what kind of cross-domain requests are authorized, rather than using less secure and less powerful workarounds based on IFRAME or JSONP.

#### 1.7.2. Processing

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors-processing)

The CORS specification distinguishes between preflight, simple, and actual requests. To learn how CORS works, you can read [this article](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS), among many others, or see the specification for more details.

Spring WebFlux `HandlerMapping` implementations provide built-in support for CORS. After successfully mapping a request to a handler, a `HandlerMapping` checks the CORS configuration for the given request and handler and takes further actions. Preflight requests are handled directly, while simple and actual CORS requests are intercepted, validated, and have the required CORS response headers set.

In order to enable cross-origin requests (that is, the `Origin` header is present and differs from the host of the request), you need to have some explicitly declared CORS configuration. If no matching CORS configuration is found, preflight requests are rejected. No CORS headers are added to the responses of simple and actual CORS requests and, consequently, browsers reject them.

Each `HandlerMapping` can be [configured](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/reactive/handler/AbstractHandlerMapping.html#setCorsConfigurations-java.util.Map-) individually with URL pattern-based `CorsConfiguration` mappings. In most cases, applications use the WebFlux Java configuration to declare such mappings, which results in a single, global map passed to all `HandlerMapping` implementations.

You can combine global CORS configuration at the `HandlerMapping` level with more fine-grained, handler-level CORS configuration. For example, annotated controllers can use class- or method-level `@CrossOrigin` annotations (other handlers can implement `CorsConfigurationSource`).

The rules for combining global and local configuration are generally additive — for example, all global and all local origins. For those attributes where only a single value can be accepted, such as `allowCredentials` and `maxAge`, the local overrides the global value. See [`CorsConfiguration#combine(CorsConfiguration)`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/cors/CorsConfiguration.html#combine-org.springframework.web.cors.CorsConfiguration-) for more details.

|      | To learn more from the source or to make advanced customizations, see:`CorsConfiguration``CorsProcessor` and `DefaultCorsProcessor``AbstractHandlerMapping` |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

#### 1.7.3. `@CrossOrigin`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors-controller)

The [`@CrossOrigin`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/bind/annotation/CrossOrigin.html) annotation enables cross-origin requests on annotated controller methods, as the following example shows:

Java

Kotlin

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

`allowCredentials` is not enabled by default, since that establishes a trust level that exposes sensitive user-specific information (such as cookies and CSRF tokens) and should be used only where appropriate. When it is enabled either `allowOrigins` must be set to one or more specific domain (but not the special value `"*"`) or alternatively the `allowOriginPatterns` property may be used to match to a dynamic set of origins.

`maxAge` is set to 30 minutes.

`@CrossOrigin` is supported at the class level, too, and inherited by all methods. The following example specifies a certain domain and sets `maxAge` to an hour:

Java

Kotlin

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

You can use `@CrossOrigin` at both the class and the method level, as the following example shows:

Java

Kotlin

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

|      | Using `@CrossOrigin` at the class level.  |
| ---- | ----------------------------------------- |
|      | Using `@CrossOrigin` at the method level. |

#### 1.7.4. Global Configuration

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors-global)

In addition to fine-grained, controller method-level configuration, you probably want to define some global CORS configuration, too. You can set URL-based `CorsConfiguration` mappings individually on any `HandlerMapping`. Most applications, however, use the WebFlux Java configuration to do that.

By default global configuration enables the following:

- All origins.
- All headers.
- `GET`, `HEAD`, and `POST` methods.

`allowedCredentials` is not enabled by default, since that establishes a trust level that exposes sensitive user-specific information( such as cookies and CSRF tokens) and should be used only where appropriate. When it is enabled either `allowOrigins` must be set to one or more specific domain (but not the special value `"*"`) or alternatively the `allowOriginPatterns` property may be used to match to a dynamic set of origins.

`maxAge` is set to 30 minutes.

To enable CORS in the WebFlux Java configuration, you can use the `CorsRegistry` callback, as the following example shows:

Java

Kotlin

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

You can apply CORS support through the built-in [`CorsWebFilter`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/cors/reactive/CorsWebFilter.html), which is a good fit with [functional endpoints](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-fn).

|      | If you try to use the `CorsFilter` with Spring Security, keep in mind that Spring Security has [built-in support](https://docs.spring.io/spring-security/site/docs/current/reference/htmlsingle/#cors) for CORS. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

To configure the filter, you can declare a `CorsWebFilter` bean and pass a `CorsConfigurationSource` to its constructor, as the following example shows:

Java

Kotlin

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

The [Spring Security](https://projects.spring.io/spring-security/) project provides support for protecting web applications from malicious exploits. See the Spring Security reference documentation, including:

- [WebFlux Security](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#jc-webflux)
- [WebFlux Testing Support](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#test-webflux)
- [CSRF Protection](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#csrf)
- [Security Response Headers](https://docs.spring.io/spring-security/site/docs/current/reference/html5/#headers)

### 1.9. View Technologies

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view)

The use of view technologies in Spring WebFlux is pluggable. Whether you decide to use Thymeleaf, FreeMarker, or some other view technology is primarily a matter of a configuration change. This chapter covers the view technologies integrated with Spring WebFlux. We assume you are already familiar with [View Resolution](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-viewresolution).

#### 1.9.1. Thymeleaf

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-thymeleaf)

Thymeleaf is a modern server-side Java template engine that emphasizes natural HTML templates that can be previewed in a browser by double-clicking, which is very helpful for independent work on UI templates (for example, by a designer) without the need for a running server. Thymeleaf offers an extensive set of features, and it is actively developed and maintained. For a more complete introduction, see the [Thymeleaf](https://www.thymeleaf.org/) project home page.

The Thymeleaf integration with Spring WebFlux is managed by the Thymeleaf project. The configuration involves a few bean declarations, such as `SpringResourceTemplateResolver`, `SpringWebFluxTemplateEngine`, and `ThymeleafReactiveViewResolver`. For more details, see [Thymeleaf+Spring](https://www.thymeleaf.org/documentation.html) and the WebFlux integration [announcement](http://forum.thymeleaf.org/Thymeleaf-3-0-8-JUST-PUBLISHED-td4030687.html).

#### 1.9.2. FreeMarker

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-freemarker)

[Apache FreeMarker](https://freemarker.apache.org/) is a template engine for generating any kind of text output from HTML to email and others. The Spring Framework has built-in integration for using Spring WebFlux with FreeMarker templates.

##### View Configuration

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-freemarker-contextconfig)

The following example shows how to configure FreeMarker as a view technology:

Java

Kotlin

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

Your templates need to be stored in the directory specified by the `FreeMarkerConfigurer`, shown in the preceding example. Given the preceding configuration, if your controller returns the view name, `welcome`, the resolver looks for the `classpath:/templates/freemarker/welcome.ftl` template.

##### FreeMarker Configuration

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-freemarker)

You can pass FreeMarker 'Settings' and 'SharedVariables' directly to the FreeMarker `Configuration` object (which is managed by Spring) by setting the appropriate bean properties on the `FreeMarkerConfigurer` bean. The `freemarkerSettings` property requires a `java.util.Properties` object, and the `freemarkerVariables` property requires a `java.util.Map`. The following example shows how to use a `FreeMarkerConfigurer`:

Java

Kotlin

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

See the FreeMarker documentation for details of settings and variables as they apply to the `Configuration` object.

##### Form Handling

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-freemarker-forms)

Spring provides a tag library for use in JSPs that contains, among others, a `<spring:bind/>` element. This element primarily lets forms display values from form-backing objects and show the results of failed validations from a `Validator` in the web or business tier. Spring also has support for the same functionality in FreeMarker, with additional convenience macros for generating form input elements themselves.

###### The Bind Macros

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-bind-macros)

A standard set of macros are maintained within the `spring-webflux.jar` file for FreeMarker, so they are always available to a suitably configured application.

Some of the macros defined in the Spring templating libraries are considered internal (private), but no such scoping exists in the macro definitions, making all macros visible to calling code and user templates. The following sections concentrate only on the macros you need to directly call from within your templates. If you wish to view the macro code directly, the file is called `spring.ftl` and is in the `org.springframework.web.reactive.result.view.freemarker` package.

For additional details on binding support, see [Simple Binding](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-simple-binding) for Spring MVC.

###### Form Macros

For details on Spring’s form macro support for FreeMarker templates, consult the following sections of the Spring MVC documentation.

- [Input Macros](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-form-macros)
- [Input Fields](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-form-macros-input)
- [Selection Fields](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-form-macros-select)
- [HTML Escaping](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-views-form-macros-html-escaping)

#### 1.9.3. Script Views

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-script)

The Spring Framework has a built-in integration for using Spring WebFlux with any templating library that can run on top of the [JSR-223](https://www.jcp.org/en/jsr/detail?id=223) Java scripting engine. The following table shows the templating libraries that we have tested on different script engines:

| Scripting Library                                            | Scripting Engine                                      |
| :----------------------------------------------------------- | :---------------------------------------------------- |
| [Handlebars](https://handlebarsjs.com/)                      | [Nashorn](https://openjdk.java.net/projects/nashorn/) |
| [Mustache](https://mustache.github.io/)                      | [Nashorn](https://openjdk.java.net/projects/nashorn/) |
| [React](https://facebook.github.io/react/)                   | [Nashorn](https://openjdk.java.net/projects/nashorn/) |
| [EJS](https://www.embeddedjs.com/)                           | [Nashorn](https://openjdk.java.net/projects/nashorn/) |
| [ERB](https://www.stuartellis.name/articles/erb/)            | [JRuby](https://www.jruby.org/)                       |
| [String templates](https://docs.python.org/2/library/string.html#template-strings) | [Jython](https://www.jython.org/)                     |
| [Kotlin Script templating](https://github.com/sdeleuze/kotlin-script-templating) | [Kotlin](https://kotlinlang.org/)                     |

|      | The basic rule for integrating any other script engine is that it must implement the `ScriptEngine` and `Invocable` interfaces. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

##### Requirements

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-script-dependencies)

You need to have the script engine on your classpath, the details of which vary by script engine:

- The [Nashorn](https://openjdk.java.net/projects/nashorn/) JavaScript engine is provided with Java 8+. Using the latest update release available is highly recommended.
- [JRuby](https://www.jruby.org/) should be added as a dependency for Ruby support.
- [Jython](https://www.jython.org/) should be added as a dependency for Python support.
- `org.jetbrains.kotlin:kotlin-script-util` dependency and a `META-INF/services/javax.script.ScriptEngineFactory` file containing a `org.jetbrains.kotlin.script.jsr223.KotlinJsr223JvmLocalScriptEngineFactory` line should be added for Kotlin script support. See [this example](https://github.com/sdeleuze/kotlin-script-templating) for more detail.

You need to have the script templating library. One way to do that for Javascript is through [WebJars](https://www.webjars.org/).

##### Script Templates

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-script-integrate)

You can declare a `ScriptTemplateConfigurer` bean to specify the script engine to use, the script files to load, what function to call to render templates, and so on. The following example uses Mustache templates and the Nashorn JavaScript engine:

Java

Kotlin

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

The `render` function is called with the following parameters:

- `String template`: The template content
- `Map model`: The view model
- `RenderingContext renderingContext`: The [`RenderingContext`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/servlet/view/script/RenderingContext.html) that gives access to the application context, the locale, the template loader, and the URL (since 5.0)

`Mustache.render()` is natively compatible with this signature, so you can call it directly.

If your templating technology requires some customization, you can provide a script that implements a custom render function. For example, [Handlerbars](https://handlebarsjs.com/) needs to compile templates before using them and requires a [polyfill](https://en.wikipedia.org/wiki/Polyfill) in order to emulate some browser facilities not available in the server-side script engine. The following example shows how to set a custom render function:

Java

Kotlin

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

`polyfill.js` defines only the `window` object needed by Handlebars to run properly, as the following snippet shows:

```javascript
var window = {};
```

This basic `render.js` implementation compiles the template before using it. A production ready implementation should also store and reused cached templates or pre-compiled templates. This can be done on the script side, as well as any customization you need (managing template engine configuration for example). The following example shows how compile a template:

```javascript
function render(template, model) {
    var compiledTemplate = Handlebars.compile(template);
    return compiledTemplate(model);
}
```

Check out the Spring Framework unit tests, [Java](https://github.com/spring-projects/spring-framework/tree/master/spring-webflux/src/test/java/org/springframework/web/reactive/result/view/script), and [resources](https://github.com/spring-projects/spring-framework/tree/master/spring-webflux/src/test/resources/org/springframework/web/reactive/result/view/script), for more configuration examples.

#### 1.9.4. JSON and XML

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-view-jackson)

For [Content Negotiation](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-multiple-representations) purposes, it is useful to be able to alternate between rendering a model with an HTML template or as other formats (such as JSON or XML), depending on the content type requested by the client. To support doing so, Spring WebFlux provides the `HttpMessageWriterView`, which you can use to plug in any of the available [Codecs](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-codecs) from `spring-web`, such as `Jackson2JsonEncoder`, `Jackson2SmileEncoder`, or `Jaxb2XmlEncoder`.

Unlike other view technologies, `HttpMessageWriterView` does not require a `ViewResolver` but is instead [configured](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config-view-resolvers) as a default view. You can configure one or more such default views, wrapping different `HttpMessageWriter` instances or `Encoder` instances. The one that matches the requested content type is used at runtime.

In most cases, a model contains multiple attributes. To determine which one to serialize, you can configure `HttpMessageWriterView` with the name of the model attribute to use for rendering. If the model contains only one attribute, that one is used.

### 1.10. HTTP Caching

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-caching)

HTTP caching can significantly improve the performance of a web application. HTTP caching revolves around the `Cache-Control` response header and subsequent conditional request headers, such as `Last-Modified` and `ETag`. `Cache-Control` advises private (for example, browser) and public (for example, proxy) caches how to cache and re-use responses. An `ETag` header is used to make a conditional request that may result in a 304 (NOT_MODIFIED) without a body, if the content has not changed. `ETag` can be seen as a more sophisticated successor to the `Last-Modified` header.

This section describes the HTTP caching related options available in Spring WebFlux.

#### 1.10.1. `CacheControl`

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-caching-cachecontrol)

[`CacheControl`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/http/CacheControl.html) provides support for configuring settings related to the `Cache-Control` header and is accepted as an argument in a number of places:

- [Controllers](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-caching-etag-lastmodified)
- [Static Resources](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-caching-static-resources)

While [RFC 7234](https://tools.ietf.org/html/rfc7234#section-5.2.2) describes all possible directives for the `Cache-Control` response header, the `CacheControl` type takes a use case-oriented approach that focuses on the common scenarios, as the following example shows:

Java

Kotlin

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

Controllers can add explicit support for HTTP caching. We recommend doing so, since the `lastModified` or `ETag` value for a resource needs to be calculated before it can be compared against conditional request headers. A controller can add an `ETag` and `Cache-Control` settings to a `ResponseEntity`, as the following example shows:

Java

Kotlin

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

The preceding example sends a 304 (NOT_MODIFIED) response with an empty body if the comparison to the conditional request headers indicates the content has not changed. Otherwise, the `ETag` and `Cache-Control` headers are added to the response.

You can also make the check against conditional request headers in the controller, as the following example shows:

Java

Kotlin

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

|      | Application-specific calculation.                            |
| ---- | ------------------------------------------------------------ |
|      | Response has been set to 304 (NOT_MODIFIED). No further processing. |
|      | Continue with request processing.                            |

There are three variants for checking conditional requests against `eTag` values, `lastModified` values, or both. For conditional `GET` and `HEAD` requests, you can set the response to 304 (NOT_MODIFIED). For conditional `POST`, `PUT`, and `DELETE`, you can instead set the response to 412 (PRECONDITION_FAILED) to prevent concurrent modification.

#### 1.10.3. Static Resources

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-caching-static-resources)

You should serve static resources with a `Cache-Control` and conditional response headers for optimal performance. See the section on configuring [Static Resources](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config-static-resources).

### 1.11. WebFlux Config

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config)

The WebFlux Java configuration declares the components that are required to process requests with annotated controllers or functional endpoints, and it offers an API to customize the configuration. That means you do not need to understand the underlying beans created by the Java configuration. However, if you want to understand them, you can see them in `WebFluxConfigurationSupport` or read more about what they are in [Special Bean Types](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-special-bean-types).

For more advanced customizations, not available in the configuration API, you can gain full control over the configuration through the [Advanced Configuration Mode](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config-advanced-java).

#### 1.11.1. Enabling WebFlux Config

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-enable)

You can use the `@EnableWebFlux` annotation in your Java config, as the following example shows:

Java

Kotlin

```java
@Configuration
@EnableWebFlux
public class WebConfig {
}
```

The preceding example registers a number of Spring WebFlux [infrastructure beans](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-special-bean-types) and adapts to dependencies available on the classpath — for JSON, XML, and others.

#### 1.11.2. WebFlux config API

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-customize)

In your Java configuration, you can implement the `WebFluxConfigurer` interface, as the following example shows:

Java

Kotlin

```java
@Configuration
@EnableWebFlux
public class WebConfig implements WebFluxConfigurer {

    // Implement configuration methods...
}
```

#### 1.11.3. Conversion, formatting

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-conversion)

By default, formatters for various number and date types are installed, along with support for customization via `@NumberFormat` and `@DateTimeFormat` on fields.

To register custom formatters and converters in Java config, use the following:

Java

Kotlin

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

By default Spring WebFlux considers the request Locale when parsing and formatting date values. This works for forms where dates are represented as Strings with "input" form fields. For "date" and "time" form fields, however, browsers use a fixed format defined in the HTML spec. For such cases date and time formatting can be customized as follows:

Java

Kotlin

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

|      | See [`FormatterRegistrar` SPI](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#format-FormatterRegistrar-SPI) and the `FormattingConversionServiceFactoryBean` for more information on when to use `FormatterRegistrar` implementations. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

#### 1.11.4. Validation

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-validation)

By default, if [Bean Validation](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#validation-beanvalidation-overview) is present on the classpath (for example, the Hibernate Validator), the `LocalValidatorFactoryBean` is registered as a global [validator](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#validator) for use with `@Valid` and `@Validated` on `@Controller` method arguments.

In your Java configuration, you can customize the global `Validator` instance, as the following example shows:

Java

Kotlin

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

Note that you can also register `Validator` implementations locally, as the following example shows:

Java

Kotlin

```java
@Controller
public class MyController {

    @InitBinder
    protected void initBinder(WebDataBinder binder) {
        binder.addValidators(new FooValidator());
    }

}
```

|      | If you need to have a `LocalValidatorFactoryBean` injected somewhere, create a bean and mark it with `@Primary` in order to avoid conflict with the one declared in the MVC config. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

#### 1.11.5. Content Type Resolvers

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-content-negotiation)

You can configure how Spring WebFlux determines the requested media types for `@Controller` instances from the request. By default, only the `Accept` header is checked, but you can also enable a query parameter-based strategy.

The following example shows how to customize the requested content type resolution:

Java

Kotlin

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

The following example shows how to customize how the request and response body are read and written:

Java

Kotlin

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

`ServerCodecConfigurer` provides a set of default readers and writers. You can use it to add more readers and writers, customize the default ones, or replace the default ones completely.

For Jackson JSON and XML, consider using [`Jackson2ObjectMapperBuilder`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/http/converter/json/Jackson2ObjectMapperBuilder.html), which customizes Jackson’s default properties with the following ones:

- [`DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES`](https://fasterxml.github.io/jackson-databind/javadoc/2.6/com/fasterxml/jackson/databind/DeserializationFeature.html#FAIL_ON_UNKNOWN_PROPERTIES) is disabled.
- [`MapperFeature.DEFAULT_VIEW_INCLUSION`](https://fasterxml.github.io/jackson-databind/javadoc/2.6/com/fasterxml/jackson/databind/MapperFeature.html#DEFAULT_VIEW_INCLUSION) is disabled.

It also automatically registers the following well-known modules if they are detected on the classpath:

- [`jackson-datatype-joda`](https://github.com/FasterXML/jackson-datatype-joda): Support for Joda-Time types.
- [`jackson-datatype-jsr310`](https://github.com/FasterXML/jackson-datatype-jsr310): Support for Java 8 Date and Time API types.
- [`jackson-datatype-jdk8`](https://github.com/FasterXML/jackson-datatype-jdk8): Support for other Java 8 types, such as `Optional`.
- [`jackson-module-kotlin`](https://github.com/FasterXML/jackson-module-kotlin): Support for Kotlin classes and data classes.

#### 1.11.7. View Resolvers

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-view-resolvers)

The following example shows how to configure view resolution:

Java

Kotlin

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

The `ViewResolverRegistry` has shortcuts for view technologies with which the Spring Framework integrates. The following example uses FreeMarker (which also requires configuring the underlying FreeMarker view technology):

Java

Kotlin

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

You can also plug in any `ViewResolver` implementation, as the following example shows:

Java

Kotlin

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

To support [Content Negotiation](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-multiple-representations) and rendering other formats through view resolution (besides HTML), you can configure one or more default views based on the `HttpMessageWriterView` implementation, which accepts any of the available [Codecs](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-codecs) from `spring-web`. The following example shows how to do so:

Java

Kotlin

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

See [View Technologies](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-view) for more on the view technologies that are integrated with Spring WebFlux.

#### 1.11.8. Static Resources

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-static-resources)

This option provides a convenient way to serve static resources from a list of [`Resource`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/core/io/Resource.html)-based locations.

In the next example, given a request that starts with `/resources`, the relative path is used to find and serve static resources relative to `/static` on the classpath. Resources are served with a one-year future expiration to ensure maximum use of the browser cache and a reduction in HTTP requests made by the browser. The `Last-Modified` header is also evaluated and, if present, a `304` status code is returned. The following list shows the example:

Java

Kotlin

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

The resource handler also supports a chain of [`ResourceResolver`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/reactive/resource/ResourceResolver.html) implementations and [`ResourceTransformer`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/reactive/resource/ResourceTransformer.html) implementations, which can be used to create a toolchain for working with optimized resources.

You can use the `VersionResourceResolver` for versioned resource URLs based on an MD5 hash computed from the content, a fixed application version, or other information. A `ContentVersionStrategy` (MD5 hash) is a good choice with some notable exceptions (such as JavaScript resources used with a module loader).

The following example shows how to use `VersionResourceResolver` in your Java configuration:

Java

Kotlin

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

You can use `ResourceUrlProvider` to rewrite URLs and apply the full chain of resolvers and transformers (for example, to insert versions). The WebFlux configuration provides a `ResourceUrlProvider` so that it can be injected into others.

Unlike Spring MVC, at present, in WebFlux, there is no way to transparently rewrite static resource URLs, since there are no view technologies that can make use of a non-blocking chain of resolvers and transformers. When serving only local resources, the workaround is to use `ResourceUrlProvider` directly (for example, through a custom element) and block.

Note that, when using both `EncodedResourceResolver` (for example, Gzip, Brotli encoded) and `VersionedResourceResolver`, they must be registered in that order, to ensure content-based versions are always computed reliably based on the unencoded file.

[WebJars](https://www.webjars.org/documentation) are also supported through the `WebJarsResourceResolver` which is automatically registered when the `org.webjars:webjars-locator-core` library is present on the classpath. The resolver can re-write URLs to include the version of the jar and can also match against incoming URLs without versions — for example, from `/jquery/jquery.min.js` to `/jquery/1.2.0/jquery.min.js`.

#### 1.11.9. Path Matching

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-config-path-matching)

You can customize options related to path matching. For details on the individual options, see the [`PathMatchConfigurer`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/web/reactive/config/PathMatchConfigurer.html) javadoc. The following example shows how to use `PathMatchConfigurer`:

Java

Kotlin

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

|      | Spring WebFlux relies on a parsed representation of the request path called `RequestPath` for access to decoded path segment values, with semicolon content removed (that is, path or matrix variables). That means, unlike in Spring MVC, you need not indicate whether to decode the request path nor whether to remove semicolon content for path matching purposes.Spring WebFlux also does not support suffix pattern matching, unlike in Spring MVC, where we are also [recommend](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-ann-requestmapping-suffix-pattern-match) moving away from reliance on it. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

#### 1.11.10. WebSocketService

The WebFlux Java config declares of a `WebSocketHandlerAdapter` bean which provides support for the invocation of WebSocket handlers. That means all that remains to do in order to handle a WebSocket handshake request is to map a `WebSocketHandler` to a URL via `SimpleUrlHandlerMapping`.

In some cases it may be necessary to create the `WebSocketHandlerAdapter` bean with a provided `WebSocketService` service which allows configuring WebSocket server properties. For example:

Java

Kotlin

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

`@EnableWebFlux` imports `DelegatingWebFluxConfiguration` that:

- Provides default Spring configuration for WebFlux applications
- detects and delegates to `WebFluxConfigurer` implementations to customize that configuration.

For advanced mode, you can remove `@EnableWebFlux` and extend directly from `DelegatingWebFluxConfiguration` instead of implementing `WebFluxConfigurer`, as the following example shows:

Java

Kotlin

```java
@Configuration
public class WebConfig extends DelegatingWebFluxConfiguration {

    // ...
}
```

You can keep existing methods in `WebConfig`, but you can now also override bean declarations from the base class and still have any number of other `WebMvcConfigurer` implementations on the classpath.

### 1.12. HTTP/2

[Web MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-http2)

HTTP/2 is supported with Reactor Netty, Tomcat, Jetty, and Undertow. However, there are considerations related to server configuration. For more details, see the [HTTP/2 wiki page](https://github.com/spring-projects/spring-framework/wiki/HTTP-2-support).

## 2. WebClient

Spring WebFlux includes a client to perform HTTP requests with. `WebClient` has a functional, fluent API based on Reactor, see [Reactive Libraries](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-reactive-libraries), which enables declarative composition of asynchronous logic without the need to deal with threads or concurrency. It is fully non-blocking, it supports streaming, and relies on the same [codecs](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-codecs) that are also used to encode and decode request and response content on the server side.

`WebClient` needs an HTTP client library to perform requests with. There is built-in support for the following:

- [Reactor Netty](https://github.com/reactor/reactor-netty)
- [Jetty Reactive HttpClient](https://github.com/jetty-project/jetty-reactive-httpclient)
- [Apache HttpComponents](https://hc.apache.org/index.html)
- Others can be plugged via `ClientHttpConnector`.

### 2.1. Configuration

The simplest way to create a `WebClient` is through one of the static factory methods:

- `WebClient.create()`
- `WebClient.create(String baseUrl)`

You can also use `WebClient.builder()` with further options:

- `uriBuilderFactory`: Customized `UriBuilderFactory` to use as a base URL.
- `defaultUriVariables`: default values to use when expanding URI templates.
- `defaultHeader`: Headers for every request.
- `defaultCookie`: Cookies for every request.
- `defaultRequest`: `Consumer` to customize every request.
- `filter`: Client filter for every request.
- `exchangeStrategies`: HTTP message reader/writer customizations.
- `clientConnector`: HTTP client library settings.

For example:

Java

Kotlin

```java
WebClient client = WebClient.builder()
        .codecs(configurer -> ... )
        .build();
```

Once built, a `WebClient` is immutable. However, you can clone it and build a modified copy as follows:

Java

Kotlin

```java
WebClient client1 = WebClient.builder()
        .filter(filterA).filter(filterB).build();

WebClient client2 = client1.mutate()
        .filter(filterC).filter(filterD).build();

// client1 has filterA, filterB

// client2 has filterA, filterB, filterC, filterD
```

#### 2.1.1. MaxInMemorySize

Codecs have [limits](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-codecs-limits) for buffering data in memory to avoid application memory issues. By the default those are set to 256KB. If that’s not enough you’ll get the following error:

```
org.springframework.core.io.buffer.DataBufferLimitException: Exceeded limit on max bytes to buffer
```

To change the limit for default codecs, use the following:

Java

Kotlin

```java
WebClient webClient = WebClient.builder()
        .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024))
        .build();
```

#### 2.1.2. Reactor Netty

To customize Reactor Netty settings, provide a pre-configured `HttpClient`:

Java

Kotlin

```java
HttpClient httpClient = HttpClient.create().secure(sslSpec -> ...);

WebClient webClient = WebClient.builder()
        .clientConnector(new ReactorClientHttpConnector(httpClient))
        .build();
```

##### Resources

By default, `HttpClient` participates in the global Reactor Netty resources held in `reactor.netty.http.HttpResources`, including event loop threads and a connection pool. This is the recommended mode, since fixed, shared resources are preferred for event loop concurrency. In this mode global resources remain active until the process exits.

If the server is timed with the process, there is typically no need for an explicit shutdown. However, if the server can start or stop in-process (for example, a Spring MVC application deployed as a WAR), you can declare a Spring-managed bean of type `ReactorResourceFactory` with `globalResources=true` (the default) to ensure that the Reactor Netty global resources are shut down when the Spring `ApplicationContext` is closed, as the following example shows:

Java

Kotlin

```java
@Bean
public ReactorResourceFactory reactorResourceFactory() {
    return new ReactorResourceFactory();
}
```

You can also choose not to participate in the global Reactor Netty resources. However, in this mode, the burden is on you to ensure that all Reactor Netty client and server instances use shared resources, as the following example shows:

Java

Kotlin

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

|      | Create resources independent of global ones.                 |
| ---- | ------------------------------------------------------------ |
|      | Use the `ReactorClientHttpConnector` constructor with resource factory. |
|      | Plug the connector into the `WebClient.Builder`.             |

##### Timeouts

To configure a connection timeout:

Java

Kotlin

```java
import io.netty.channel.ChannelOption;

HttpClient httpClient = HttpClient.create()
        .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000);

WebClient webClient = WebClient.builder()
        .clientConnector(new ReactorClientHttpConnector(httpClient))
        .build();
```

To configure a read or write timeout:

Java

Kotlin

```java
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;

HttpClient httpClient = HttpClient.create()
        .doOnConnected(conn -> conn
                .addHandlerLast(new ReadTimeoutHandler(10))
                .addHandlerLast(new WriteTimeoutHandler(10)));

// Create WebClient...
```

To configure a response timeout for all requests:

Java

Kotlin

```java
HttpClient httpClient = HttpClient.create()
        .responseTimeout(Duration.ofSeconds(2));

// Create WebClient...
```

To configure a response timeout for a specific request:

Java

Kotlin

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

The following example shows how to customize Jetty `HttpClient` settings:

Java

Kotlin

```java
HttpClient httpClient = new HttpClient();
httpClient.setCookieStore(...);

WebClient webClient = WebClient.builder()
        .clientConnector(new JettyClientHttpConnector(httpClient))
        .build();
```

By default, `HttpClient` creates its own resources (`Executor`, `ByteBufferPool`, `Scheduler`), which remain active until the process exits or `stop()` is called.

You can share resources between multiple instances of the Jetty client (and server) and ensure that the resources are shut down when the Spring `ApplicationContext` is closed by declaring a Spring-managed bean of type `JettyResourceFactory`, as the following example shows:

Java

Kotlin

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

|      | Use the `JettyClientHttpConnector` constructor with resource factory. |
| ---- | ------------------------------------------------------------ |
|      | Plug the connector into the `WebClient.Builder`.             |

#### 2.1.4. HttpComponents

The following example shows how to customize Apache HttpComponents `HttpClient` settings:

Java

Kotlin

```java
HttpAsyncClientBuilder clientBuilder = HttpAsyncClients.custom();
clientBuilder.setDefaultRequestConfig(...);
CloseableHttpAsyncClient client = clientBuilder.build();
ClientHttpConnector connector = new HttpComponentsClientHttpConnector(client);

WebClient webClient = WebClient.builder().clientConnector(connector).build();
```

### 2.2. `retrieve()`

The `retrieve()` method can be used to declare how to extract the response. For example:

Java

Kotlin

```java
WebClient client = WebClient.create("https://example.org");

Mono<ResponseEntity<Person>> result = client.get()
        .uri("/persons/{id}", id).accept(MediaType.APPLICATION_JSON)
        .retrieve()
        .toEntity(Person.class);
```

Or to get only the body:

Java

Kotlin

```java
WebClient client = WebClient.create("https://example.org");

Mono<Person> result = client.get()
        .uri("/persons/{id}", id).accept(MediaType.APPLICATION_JSON)
        .retrieve()
        .bodyToMono(Person.class);
```

To get a stream of decoded objects:

Java

Kotlin

```java
Flux<Quote> result = client.get()
        .uri("/quotes").accept(MediaType.TEXT_EVENT_STREAM)
        .retrieve()
        .bodyToFlux(Quote.class);
```

By default, 4xx or 5xx responses result in an `WebClientResponseException`, including sub-classes for specific HTTP status codes. To customize the handling of error responses, use `onStatus` handlers as follows:

Java

Kotlin

```java
Mono<Person> result = client.get()
        .uri("/persons/{id}", id).accept(MediaType.APPLICATION_JSON)
        .retrieve()
        .onStatus(HttpStatus::is4xxClientError, response -> ...)
        .onStatus(HttpStatus::is5xxServerError, response -> ...)
        .bodyToMono(Person.class);
```

### 2.3. Exchange

The `exchangeToMono()` and `exchangeToFlux()` methods (or `awaitExchange { }` and `exchangeToFlow { }` in Kotlin) are useful for more advanced cases that require more control, such as to decode the response differently depending on the response status:

Java

Kotlin

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

When using the above, after the returned `Mono` or `Flux` completes, the response body is checked and if not consumed it is released to prevent memory and connection leaks. Therefore the response cannot be decoded further downstream. It is up to the provided function to declare how to decode the response if needed.

### 2.4. Request Body

The request body can be encoded from any asynchronous type handled by `ReactiveAdapterRegistry`, like `Mono` or Kotlin Coroutines `Deferred` as the following example shows:

Java

Kotlin

```java
Mono<Person> personMono = ... ;

Mono<Void> result = client.post()
        .uri("/persons/{id}", id)
        .contentType(MediaType.APPLICATION_JSON)
        .body(personMono, Person.class)
        .retrieve()
        .bodyToMono(Void.class);
```

You can also have a stream of objects be encoded, as the following example shows:

Java

Kotlin

```java
Flux<Person> personFlux = ... ;

Mono<Void> result = client.post()
        .uri("/persons/{id}", id)
        .contentType(MediaType.APPLICATION_STREAM_JSON)
        .body(personFlux, Person.class)
        .retrieve()
        .bodyToMono(Void.class);
```

Alternatively, if you have the actual value, you can use the `bodyValue` shortcut method, as the following example shows:

Java

Kotlin

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

To send form data, you can provide a `MultiValueMap<String, String>` as the body. Note that the content is automatically set to `application/x-www-form-urlencoded` by the `FormHttpMessageWriter`. The following example shows how to use `MultiValueMap<String, String>`:

Java

Kotlin

```java
MultiValueMap<String, String> formData = ... ;

Mono<Void> result = client.post()
        .uri("/path", id)
        .bodyValue(formData)
        .retrieve()
        .bodyToMono(Void.class);
```

You can also supply form data in-line by using `BodyInserters`, as the following example shows:

Java

Kotlin

```java
import static org.springframework.web.reactive.function.BodyInserters.*;

Mono<Void> result = client.post()
        .uri("/path", id)
        .body(fromFormData("k1", "v1").with("k2", "v2"))
        .retrieve()
        .bodyToMono(Void.class);
```

#### 2.4.2. Multipart Data

To send multipart data, you need to provide a `MultiValueMap<String, ?>` whose values are either `Object` instances that represent part content or `HttpEntity` instances that represent the content and headers for a part. `MultipartBodyBuilder` provides a convenient API to prepare a multipart request. The following example shows how to create a `MultiValueMap<String, ?>`:

Java

Kotlin

```java
MultipartBodyBuilder builder = new MultipartBodyBuilder();
builder.part("fieldPart", "fieldValue");
builder.part("filePart1", new FileSystemResource("...logo.png"));
builder.part("jsonPart", new Person("Jason"));
builder.part("myPart", part); // Part from a server request

MultiValueMap<String, HttpEntity<?>> parts = builder.build();
```

In most cases, you do not have to specify the `Content-Type` for each part. The content type is determined automatically based on the `HttpMessageWriter` chosen to serialize it or, in the case of a `Resource`, based on the file extension. If necessary, you can explicitly provide the `MediaType` to use for each part through one of the overloaded builder `part` methods.

Once a `MultiValueMap` is prepared, the easiest way to pass it to the `WebClient` is through the `body` method, as the following example shows:

Java

Kotlin

```java
MultipartBodyBuilder builder = ...;

Mono<Void> result = client.post()
        .uri("/path", id)
        .body(builder.build())
        .retrieve()
        .bodyToMono(Void.class);
```

If the `MultiValueMap` contains at least one non-`String` value, which could also represent regular form data (that is, `application/x-www-form-urlencoded`), you need not set the `Content-Type` to `multipart/form-data`. This is always the case when using `MultipartBodyBuilder`, which ensures an `HttpEntity` wrapper.

As an alternative to `MultipartBodyBuilder`, you can also provide multipart content, inline-style, through the built-in `BodyInserters`, as the following example shows:

Java

Kotlin

```java
import static org.springframework.web.reactive.function.BodyInserters.*;

Mono<Void> result = client.post()
        .uri("/path", id)
        .body(fromMultipartData("fieldPart", "value").with("filePart", resource))
        .retrieve()
        .bodyToMono(Void.class);
```

### 2.5. Filters

You can register a client filter (`ExchangeFilterFunction`) through the `WebClient.Builder` in order to intercept and modify requests, as the following example shows:

Java

Kotlin

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

This can be used for cross-cutting concerns, such as authentication. The following example uses a filter for basic authentication through a static factory method:

Java

Kotlin

```java
import static org.springframework.web.reactive.function.client.ExchangeFilterFunctions.basicAuthentication;

WebClient client = WebClient.builder()
        .filter(basicAuthentication("user", "password"))
        .build();
```

You can create a new `WebClient` instance by using another as a starting point. This allows insert or removing filters without affecting the original `WebClient`. Below is an example that inserts a basic authentication filter at index 0:

Java

Kotlin

```java
import static org.springframework.web.reactive.function.client.ExchangeFilterFunctions.basicAuthentication;

WebClient client = webClient.mutate()
        .filters(filterList -> {
            filterList.add(0, basicAuthentication("user", "password"));
        })
        .build();
```

### 2.6. Attributes

You can add attributes to a request. This is convenient if you want to pass information through the filter chain and influence the behavior of filters for a given request. For example:

Java

Kotlin

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

Note that you can configure a `defaultRequest` callback globally at the `WebClient.Builder` level which lets you insert attributes into all requests, which could be used for example in a Spring MVC application to populate request attributes based on `ThreadLocal` data.

### 2.7. Context

[Attributes](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-client-attributes) provide a convenient way to pass information to the filter chain but they only influence the current request. If you want to pass information that propagates to additional requests that are nested, e.g. via `flatMap`, or executed after, e.g. via `concatMap`, then you’ll need to use the Reactor `Context`.

The Reactor `Context` needs to be populated at the end of a reactive chain in order to apply to all operations. For example:

Java

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

`WebClient` can be used in synchronous style by blocking at the end for the result:

Java

Kotlin

```java
Person person = client.get().uri("/person/{id}", i).retrieve()
    .bodyToMono(Person.class)
    .block();

List<Person> persons = client.get().uri("/persons").retrieve()
    .bodyToFlux(Person.class)
    .collectList()
    .block();
```

However if multiple calls need to be made, it’s more efficient to avoid blocking on each response individually, and instead wait for the combined result:

Java

Kotlin

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

The above is merely one example. There are lots of other patterns and operators for putting together a reactive pipeline that makes many remote calls, potentially some nested, inter-dependent, without ever blocking until the end.

|      | With `Flux` or `Mono`, you should never have to block in a Spring MVC or Spring WebFlux controller. Simply return the resulting reactive type from the controller method. The same principle apply to Kotlin Coroutines and Spring WebFlux, just use suspending function or return `Flow` in your controller method . |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

### 2.9. Testing

To test code that uses the `WebClient`, you can use a mock web server, such as the [OkHttp MockWebServer](https://github.com/square/okhttp#mockwebserver). To see an example of its use, check out [`WebClientIntegrationTests`](https://github.com/spring-projects/spring-framework/blob/master/spring-webflux/src/test/java/org/springframework/web/reactive/function/client/WebClientIntegrationTests.java) in the Spring Framework test suite or the [`static-server`](https://github.com/square/okhttp/tree/master/samples/static-server) sample in the OkHttp repository.

## 3. WebSockets

[Same as in the Servlet stack](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#websocket)

This part of the reference documentation covers support for reactive-stack WebSocket messaging.

### 3.1. Introduction to WebSocket

The WebSocket protocol, [RFC 6455](https://tools.ietf.org/html/rfc6455), provides a standardized way to establish a full-duplex, two-way communication channel between client and server over a single TCP connection. It is a different TCP protocol from HTTP but is designed to work over HTTP, using ports 80 and 443 and allowing re-use of existing firewall rules.

A WebSocket interaction begins with an HTTP request that uses the HTTP `Upgrade` header to upgrade or, in this case, to switch to the WebSocket protocol. The following example shows such an interaction:

```yaml
GET /spring-websocket-portfolio/portfolio HTTP/1.1
Host: localhost:8080
Upgrade: websocket 
Connection: Upgrade 
Sec-WebSocket-Key: Uc9l9TMkWGbHFD2qnFHltg==
Sec-WebSocket-Protocol: v10.stomp, v11.stomp
Sec-WebSocket-Version: 13
Origin: http://localhost:8080
```

|      | The `Upgrade` header.           |
| ---- | ------------------------------- |
|      | Using the `Upgrade` connection. |

Instead of the usual 200 status code, a server with WebSocket support returns output similar to the following:

```yaml
HTTP/1.1 101 Switching Protocols 
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: 1qVdfYHU9hPOl4JYYNXF623Gzn0=
Sec-WebSocket-Protocol: v10.stomp
```

|      | Protocol switch |
| ---- | --------------- |
|      |                 |

After a successful handshake, the TCP socket underlying the HTTP upgrade request remains open for both the client and the server to continue to send and receive messages.

A complete introduction of how WebSockets work is beyond the scope of this document. See RFC 6455, the WebSocket chapter of HTML5, or any of the many introductions and tutorials on the Web.

Note that, if a WebSocket server is running behind a web server (e.g. nginx), you likely need to configure it to pass WebSocket upgrade requests on to the WebSocket server. Likewise, if the application runs in a cloud environment, check the instructions of the cloud provider related to WebSocket support.

#### 3.1.1. HTTP Versus WebSocket

Even though WebSocket is designed to be HTTP-compatible and starts with an HTTP request, it is important to understand that the two protocols lead to very different architectures and application programming models.

In HTTP and REST, an application is modeled as many URLs. To interact with the application, clients access those URLs, request-response style. Servers route requests to the appropriate handler based on the HTTP URL, method, and headers.

By contrast, in WebSockets, there is usually only one URL for the initial connect. Subsequently, all application messages flow on that same TCP connection. This points to an entirely different asynchronous, event-driven, messaging architecture.

WebSocket is also a low-level transport protocol, which, unlike HTTP, does not prescribe any semantics to the content of messages. That means that there is no way to route or process a message unless the client and the server agree on message semantics.

WebSocket clients and servers can negotiate the use of a higher-level, messaging protocol (for example, STOMP), through the `Sec-WebSocket-Protocol` header on the HTTP handshake request. In the absence of that, they need to come up with their own conventions.

#### 3.1.2. When to Use WebSockets

WebSockets can make a web page be dynamic and interactive. However, in many cases, a combination of Ajax and HTTP streaming or long polling can provide a simple and effective solution.

For example, news, mail, and social feeds need to update dynamically, but it may be perfectly okay to do so every few minutes. Collaboration, games, and financial apps, on the other hand, need to be much closer to real-time.

Latency alone is not a deciding factor. If the volume of messages is relatively low (for example, monitoring network failures) HTTP streaming or polling can provide an effective solution. It is the combination of low latency, high frequency, and high volume that make the best case for the use of WebSocket.

Keep in mind also that over the Internet, restrictive proxies that are outside of your control may preclude WebSocket interactions, either because they are not configured to pass on the `Upgrade` header or because they close long-lived connections that appear idle. This means that the use of WebSocket for internal applications within the firewall is a more straightforward decision than it is for public facing applications.

### 3.2. WebSocket API

[Same as in the Servlet stack](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#websocket-server)

The Spring Framework provides a WebSocket API that you can use to write client- and server-side applications that handle WebSocket messages.

#### 3.2.1. Server

[Same as in the Servlet stack](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#websocket-server-handler)

To create a WebSocket server, you can first create a `WebSocketHandler`. The following example shows how to do so:

Java

Kotlin

```java
import org.springframework.web.reactive.socket.WebSocketHandler;
import org.springframework.web.reactive.socket.WebSocketSession;

public class MyWebSocketHandler implements WebSocketHandler {

    @Override
    public Mono<Void> handle(WebSocketSession session) {
        // ...
    }
}
```

Then you can map it to a URL:

Java

Kotlin

```java
@Configuration
class WebConfig {

    @Bean
    public HandlerMapping handlerMapping() {
        Map<String, WebSocketHandler> map = new HashMap<>();
        map.put("/path", new MyWebSocketHandler());
        int order = -1; // before annotated controllers

        return new SimpleUrlHandlerMapping(map, order);
    }
}
```

If using the [WebFlux Config](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config) there is nothing further to do, or otherwise if not using the WebFlux config you’ll need to declare a `WebSocketHandlerAdapter` as shown below:

Java

Kotlin

```java
@Configuration
class WebConfig {

    // ...

    @Bean
    public WebSocketHandlerAdapter handlerAdapter() {
        return new WebSocketHandlerAdapter();
    }
}
```

#### 3.2.2. `WebSocketHandler`

The `handle` method of `WebSocketHandler` takes `WebSocketSession` and returns `Mono<Void>` to indicate when application handling of the session is complete. The session is handled through two streams, one for inbound and one for outbound messages. The following table describes the two methods that handle the streams:

| `WebSocketSession` method                      | Description                                                  |
| :--------------------------------------------- | :----------------------------------------------------------- |
| `Flux<WebSocketMessage> receive()`             | Provides access to the inbound message stream and completes when the connection is closed. |
| `Mono<Void> send(Publisher<WebSocketMessage>)` | Takes a source for outgoing messages, writes the messages, and returns a `Mono<Void>` that completes when the source completes and writing is done. |

A `WebSocketHandler` must compose the inbound and outbound streams into a unified flow and return a `Mono<Void>` that reflects the completion of that flow. Depending on application requirements, the unified flow completes when:

- Either the inbound or the outbound message stream completes.
- The inbound stream completes (that is, the connection closed), while the outbound stream is infinite.
- At a chosen point, through the `close` method of `WebSocketSession`.

When inbound and outbound message streams are composed together, there is no need to check if the connection is open, since Reactive Streams signals end activity. The inbound stream receives a completion or error signal, and the outbound stream receives a cancellation signal.

The most basic implementation of a handler is one that handles the inbound stream. The following example shows such an implementation:

Java

Kotlin

```java
class ExampleHandler implements WebSocketHandler {

    @Override
    public Mono<Void> handle(WebSocketSession session) {
        return session.receive()            
                .doOnNext(message -> {
                    // ...                  
                })
                .concatMap(message -> {
                    // ...                  
                })
                .then();                    
    }
}
```

|      | Access the stream of inbound messages.                       |
| ---- | ------------------------------------------------------------ |
|      | Do something with each message.                              |
|      | Perform nested asynchronous operations that use the message content. |
|      | Return a `Mono<Void>` that completes when receiving completes. |

|      | For nested, asynchronous operations, you may need to call `message.retain()` on underlying servers that use pooled data buffers (for example, Netty). Otherwise, the data buffer may be released before you have had a chance to read the data. For more background, see [Data Buffers and Codecs](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#databuffers). |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

The following implementation combines the inbound and outbound streams:

Java

Kotlin

```java
class ExampleHandler implements WebSocketHandler {

    @Override
    public Mono<Void> handle(WebSocketSession session) {

        Flux<WebSocketMessage> output = session.receive()               
                .doOnNext(message -> {
                    // ...
                })
                .concatMap(message -> {
                    // ...
                })
                .map(value -> session.textMessage("Echo " + value));    

        return session.send(output);                                    
    }
}
```

|      | Handle the inbound message stream.                           |
| ---- | ------------------------------------------------------------ |
|      | Create the outbound message, producing a combined flow.      |
|      | Return a `Mono<Void>` that does not complete while we continue to receive. |

Inbound and outbound streams can be independent and be joined only for completion, as the following example shows:

Java

Kotlin

```java
class ExampleHandler implements WebSocketHandler {

    @Override
    public Mono<Void> handle(WebSocketSession session) {

        Mono<Void> input = session.receive()                                
                .doOnNext(message -> {
                    // ...
                })
                .concatMap(message -> {
                    // ...
                })
                .then();

        Flux<String> source = ... ;
        Mono<Void> output = session.send(source.map(session::textMessage)); 

        return Mono.zip(input, output).then();                              
    }
}
```

|      | Handle inbound message stream.                               |
| ---- | ------------------------------------------------------------ |
|      | Send outgoing messages.                                      |
|      | Join the streams and return a `Mono<Void>` that completes when either stream ends. |

#### 3.2.3. `DataBuffer`

`DataBuffer` is the representation for a byte buffer in WebFlux. The Spring Core part of the reference has more on that in the section on [Data Buffers and Codecs](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#databuffers). The key point to understand is that on some servers like Netty, byte buffers are pooled and reference counted, and must be released when consumed to avoid memory leaks.

When running on Netty, applications must use `DataBufferUtils.retain(dataBuffer)` if they wish to hold on input data buffers in order to ensure they are not released, and subsequently use `DataBufferUtils.release(dataBuffer)` when the buffers are consumed.

#### 3.2.4. Handshake

[Same as in the Servlet stack](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#websocket-server-handshake)

`WebSocketHandlerAdapter` delegates to a `WebSocketService`. By default, that is an instance of `HandshakeWebSocketService`, which performs basic checks on the WebSocket request and then uses `RequestUpgradeStrategy` for the server in use. Currently, there is built-in support for Reactor Netty, Tomcat, Jetty, and Undertow.

`HandshakeWebSocketService` exposes a `sessionAttributePredicate` property that allows setting a `Predicate<String>` to extract attributes from the `WebSession` and insert them into the attributes of the `WebSocketSession`.

#### 3.2.5. Server Configation

[Same as in the Servlet stack](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#websocket-server-runtime-configuration)

The `RequestUpgradeStrategy` for each server exposes configuration specific to the underlying WebSocket server engine. When using the WebFlux Java config you can customize such properties as shown in the corresponding section of the [WebFlux Config](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-config-websocket-service), or otherwise if not using the WebFlux config, use the below:

Java

Kotlin

```java
@Configuration
class WebConfig {

    @Bean
    public WebSocketHandlerAdapter handlerAdapter() {
        return new WebSocketHandlerAdapter(webSocketService());
    }

    @Bean
    public WebSocketService webSocketService() {
        TomcatRequestUpgradeStrategy strategy = new TomcatRequestUpgradeStrategy();
        strategy.setMaxSessionIdleTimeout(0L);
        return new HandshakeWebSocketService(strategy);
    }
}
```

Check the upgrade strategy for your server to see what options are available. Currently, only Tomcat and Jetty expose such options.

#### 3.2.6. CORS

[Same as in the Servlet stack](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#websocket-server-allowed-origins)

The easiest way to configure CORS and restrict access to a WebSocket endpoint is to have your `WebSocketHandler` implement `CorsConfigurationSource` and return a `CorsConfiguration` with allowed origins, headers, and other details. If you cannot do that, you can also set the `corsConfigurations` property on the `SimpleUrlHandler` to specify CORS settings by URL pattern. If both are specified, they are combined by using the `combine` method on `CorsConfiguration`.

#### 3.2.7. Client

Spring WebFlux provides a `WebSocketClient` abstraction with implementations for Reactor Netty, Tomcat, Jetty, Undertow, and standard Java (that is, JSR-356).

|      | The Tomcat client is effectively an extension of the standard Java one with some extra functionality in the `WebSocketSession` handling to take advantage of the Tomcat-specific API to suspend receiving messages for back pressure. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

To start a WebSocket session, you can create an instance of the client and use its `execute` methods:

Java

Kotlin

```java
WebSocketClient client = new ReactorNettyWebSocketClient();

URI url = new URI("ws://localhost:8080/path");
client.execute(url, session ->
        session.receive()
                .doOnNext(System.out::println)
                .then());
```

Some clients, such as Jetty, implement `Lifecycle` and need to be stopped and started before you can use them. All clients have constructor options related to configuration of the underlying WebSocket client.

## 4. Testing

[Same in Spring MVC](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#testing)

The `spring-test` module provides mock implementations of `ServerHttpRequest`, `ServerHttpResponse`, and `ServerWebExchange`. See [Spring Web Reactive](https://docs.spring.io/spring-framework/docs/current/reference/html/testing.html#mock-objects-web-reactive) for a discussion of mock objects.

[`WebTestClient`](https://docs.spring.io/spring-framework/docs/current/reference/html/testing.html#webtestclient) builds on these mock request and response objects to provide support for testing WebFlux applications without an HTTP server. You can use the `WebTestClient` for end-to-end integration tests, too.

## 5. RSocket

This section describes Spring Framework’s support for the RSocket protocol.

### 5.1. Overview

RSocket is an application protocol for multiplexed, duplex communication over TCP, WebSocket, and other byte stream transports, using one of the following interaction models:

- `Request-Response` — send one message and receive one back.
- `Request-Stream` — send one message and receive a stream of messages back.
- `Channel` — send streams of messages in both directions.
- `Fire-and-Forget` — send a one-way message.

Once the initial connection is made, the "client" vs "server" distinction is lost as both sides become symmetrical and each side can initiate one of the above interactions. This is why in the protocol calls the participating sides "requester" and "responder" while the above interactions are called "request streams" or simply "requests".

These are the key features and benefits of the RSocket protocol:

- [Reactive Streams](https://www.reactive-streams.org/) semantics across network boundary — for streaming requests such as `Request-Stream` and `Channel`, back pressure signals travel between requester and responder, allowing a requester to slow down a responder at the source, hence reducing reliance on network layer congestion control, and the need for buffering at the network level or at any level.
- Request throttling — this feature is named "Leasing" after the `LEASE` frame that can be sent from each end to limit the total number of requests allowed by other end for a given time. Leases are renewed periodically.
- Session resumption — this is designed for loss of connectivity and requires some state to be maintained. The state management is transparent for applications, and works well in combination with back pressure which can stop a producer when possible and reduce the amount of state required.
- Fragmentation and re-assembly of large messages.
- Keepalive (heartbeats).

RSocket has [implementations](https://github.com/rsocket) in multiple languages. The [Java library](https://github.com/rsocket/rsocket-java) is built on [Project Reactor](https://projectreactor.io/), and [Reactor Netty](https://github.com/reactor/reactor-netty) for the transport. That means signals from Reactive Streams Publishers in your application propagate transparently through RSocket across the network.

#### 5.1.1. The Protocol

One of the benefits of RSocket is that it has well defined behavior on the wire and an easy to read [specification](https://rsocket.io/docs/Protocol) along with some protocol [extensions](https://github.com/rsocket/rsocket/tree/master/Extensions). Therefore it is a good idea to read the spec, independent of language implementations and higher level framework APIs. This section provides a succinct overview to establish some context.

**Connecting**

Initially a client connects to a server via some low level streaming transport such as TCP or WebSocket and sends a `SETUP` frame to the server to set parameters for the connection.

The server may reject the `SETUP` frame, but generally after it is sent (for the client) and received (for the server), both sides can begin to make requests, unless `SETUP` indicates use of leasing semantics to limit the number of requests, in which case both sides must wait for a `LEASE` frame from the other end to permit making requests.

**Making Requests**

Once a connection is established, both sides may initiate a request through one of the frames `REQUEST_RESPONSE`, `REQUEST_STREAM`, `REQUEST_CHANNEL`, or `REQUEST_FNF`. Each of those frames carries one message from the requester to the responder.

The responder may then return `PAYLOAD` frames with response messages, and in the case of `REQUEST_CHANNEL` the requester may also send `PAYLOAD` frames with more request messages.

When a request involves a stream of messages such as `Request-Stream` and `Channel`, the responder must respect demand signals from the requester. Demand is expressed as a number of messages. Initial demand is specified in `REQUEST_STREAM` and `REQUEST_CHANNEL` frames. Subsequent demand is signaled via `REQUEST_N` frames.

Each side may also send metadata notifications, via the `METADATA_PUSH` frame, that do not pertain to any individual request but rather to the connection as a whole.

**Message Format**

RSocket messages contain data and metadata. Metadata can be used to send a route, a security token, etc. Data and metadata can be formatted differently. Mime types for each are declared in the `SETUP` frame and apply to all requests on a given connection.

While all messages can have metadata, typically metadata such as a route are per-request and therefore only included in the first message on a request, i.e. with one of the frames `REQUEST_RESPONSE`, `REQUEST_STREAM`, `REQUEST_CHANNEL`, or `REQUEST_FNF`.

Protocol extensions define common metadata formats for use in applications:

- [Composite Metadata](https://github.com/rsocket/rsocket/blob/master/Extensions/CompositeMetadata.md)-- multiple, independently formatted metadata entries.
- [Routing](https://github.com/rsocket/rsocket/blob/master/Extensions/Routing.md) — the route for a request.

#### 5.1.2. Java Implementation

The [Java implementation](https://github.com/rsocket/rsocket-java) for RSocket is built on [Project Reactor](https://projectreactor.io/). The transports for TCP and WebSocket are built on [Reactor Netty](https://github.com/reactor/reactor-netty). As a Reactive Streams library, Reactor simplifies the job of implementing the protocol. For applications it is a natural fit to use `Flux` and `Mono` with declarative operators and transparent back pressure support.

The API in RSocket Java is intentionally minimal and basic. It focuses on protocol features and leaves the application programming model (e.g. RPC codegen vs other) as a higher level, independent concern.

The main contract [io.rsocket.RSocket](https://github.com/rsocket/rsocket-java/blob/master/rsocket-core/src/main/java/io/rsocket/RSocket.java) models the four request interaction types with `Mono` representing a promise for a single message, `Flux` a stream of messages, and `io.rsocket.Payload` the actual message with access to data and metadata as byte buffers. The `RSocket` contract is used symmetrically. For requesting, the application is given an `RSocket` to perform requests with. For responding, the application implements `RSocket` to handle requests.

This is not meant to be a thorough introduction. For the most part, Spring applications will not have to use its API directly. However it may be important to see or experiment with RSocket independent of Spring. The RSocket Java repository contains a number of [sample apps](https://github.com/rsocket/rsocket-java/tree/master/rsocket-examples) that demonstrate its API and protocol features.

#### 5.1.3. Spring Support

The `spring-messaging` module contains the following:

- [RSocketRequester](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-requester) — fluent API to make requests through an `io.rsocket.RSocket` with data and metadata encoding/decoding.
- [Annotated Responders](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-annot-responders) — `@MessageMapping` annotated handler methods for responding.

The `spring-web` module contains `Encoder` and `Decoder` implementations such as Jackson CBOR/JSON, and Protobuf that RSocket applications will likely need. It also contains the `PathPatternParser` that can be plugged in for efficient route matching.

Spring Boot 2.2 supports standing up an RSocket server over TCP or WebSocket, including the option to expose RSocket over WebSocket in a WebFlux server. There is also client support and auto-configuration for an `RSocketRequester.Builder` and `RSocketStrategies`. See the [RSocket section](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#boot-features-rsocket) in the Spring Boot reference for more details.

Spring Security 5.2 provides RSocket support.

Spring Integration 5.2 provides inbound and outbound gateways to interact with RSocket clients and servers. See the Spring Integration Reference Manual for more details.

Spring Cloud Gateway supports RSocket connections.

### 5.2. RSocketRequester

`RSocketRequester` provides a fluent API to perform RSocket requests, accepting and returning objects for data and metadata instead of low level data buffers. It can be used symmetrically, to make requests from clients and to make requests from servers.

#### 5.2.1. Client Requester

To obtain an `RSocketRequester` on the client side is to connect to a server which involves sending an RSocket `SETUP` frame with connection settings. `RSocketRequester` provides a builder that helps to prepare an `io.rsocket.core.RSocketConnector` including connection settings for the `SETUP` frame.

This is the most basic way to connect with default settings:

Java

Kotlin

```java
RSocketRequester requester = RSocketRequester.builder().tcp("localhost", 7000);

URI url = URI.create("https://example.org:8080/rsocket");
RSocketRequester requester = RSocketRequester.builder().webSocket(url);
```

The above does not connect immediately. When requests are made, a shared connection is established transparently and used.

##### Connection Setup

`RSocketRequester.Builder` provides the following to customize the initial `SETUP` frame:

- `dataMimeType(MimeType)` — set the mime type for data on the connection.
- `metadataMimeType(MimeType)` — set the mime type for metadata on the connection.
- `setupData(Object)` — data to include in the `SETUP`.
- `setupRoute(String, Object…)` — route in the metadata to include in the `SETUP`.
- `setupMetadata(Object, MimeType)` — other metadata to include in the `SETUP`.

For data, the default mime type is derived from the first configured `Decoder`. For metadata, the default mime type is [composite metadata](https://github.com/rsocket/rsocket/blob/master/Extensions/CompositeMetadata.md) which allows multiple metadata value and mime type pairs per request. Typically both don’t need to be changed.

Data and metadata in the `SETUP` frame is optional. On the server side, [@ConnectMapping](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-annot-connectmapping) methods can be used to handle the start of a connection and the content of the `SETUP` frame. Metadata may be used for connection level security.

##### Strategies

`RSocketRequester.Builder` accepts `RSocketStrategies` to configure the requester. You’ll need to use this to provide encoders and decoders for (de)-serialization of data and metadata values. By default only the basic codecs from `spring-core` for `String`, `byte[]`, and `ByteBuffer` are registered. Adding `spring-web` provides access to more that can be registered as follows:

Java

Kotlin

```java
RSocketStrategies strategies = RSocketStrategies.builder()
    .encoders(encoders -> encoders.add(new Jackson2CborEncoder()))
    .decoders(decoders -> decoders.add(new Jackson2CborDecoder()))
    .build();

RSocketRequester requester = RSocketRequester.builder()
    .rsocketStrategies(strategies)
    .tcp("localhost", 7000);
```

`RSocketStrategies` is designed for re-use. In some scenarios, e.g. client and server in the same application, it may be preferable to declare it in Spring configuration.

##### Client Responders

`RSocketRequester.Builder` can be used to configure responders to requests from the server.

You can use annotated handlers for client-side responding based on the same infrastructure that’s used on a server, but registered programmatically as follows:

Java

Kotlin

```java
RSocketStrategies strategies = RSocketStrategies.builder()
    .routeMatcher(new PathPatternRouteMatcher())  
    .build();

SocketAcceptor responder =
    RSocketMessageHandler.responder(strategies, new ClientHandler()); 

RSocketRequester requester = RSocketRequester.builder()
    .rsocketConnector(connector -> connector.acceptor(responder)) 
    .tcp("localhost", 7000);
```

|      | Use `PathPatternRouteMatcher`, if `spring-web` is present, for efficient route matching. |
| ---- | ------------------------------------------------------------ |
|      | Create a responder from a class with `@MessageMaping` and/or `@ConnectMapping` methods. |
|      | Register the responder.                                      |

Note the above is only a shortcut designed for programmatic registration of client responders. For alternative scenarios, where client responders are in Spring configuration, you can still declare `RSocketMessageHandler` as a Spring bean and then apply as follows:

Java

Kotlin

```java
ApplicationContext context = ... ;
RSocketMessageHandler handler = context.getBean(RSocketMessageHandler.class);

RSocketRequester requester = RSocketRequester.builder()
    .rsocketConnector(connector -> connector.acceptor(handler.responder()))
    .tcp("localhost", 7000);
```

For the above you may also need to use `setHandlerPredicate` in `RSocketMessageHandler` to switch to a different strategy for detecting client responders, e.g. based on a custom annotation such as `@RSocketClientResponder` vs the default `@Controller`. This is necessary in scenarios with client and server, or multiple clients in the same application.

See also [Annotated Responders](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-annot-responders), for more on the programming model.

##### Advanced

`RSocketRequesterBuilder` provides a callback to expose the underlying `io.rsocket.core.RSocketConnector` for further configuration options for keepalive intervals, session resumption, interceptors, and more. You can configure options at that level as follows:

Java

Kotlin

```java
RSocketRequester requester = RSocketRequester.builder()
    .rsocketConnector(connector -> {
        // ...
    })
    .tcp("localhost", 7000);
```

#### 5.2.2. Server Requester

To make requests from a server to connected clients is a matter of obtaining the requester for the connected client from the server.

In [Annotated Responders](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-annot-responders), `@ConnectMapping` and `@MessageMapping` methods support an `RSocketRequester` argument. Use it to access the requester for the connection. Keep in mind that `@ConnectMapping` methods are essentially handlers of the `SETUP` frame which must be handled before requests can begin. Therefore, requests at the very start must be decoupled from handling. For example:

Java

Kotlin

```java
@ConnectMapping
Mono<Void> handle(RSocketRequester requester) {
    requester.route("status").data("5")
        .retrieveFlux(StatusReport.class)
        .subscribe(bar -> { 
            // ...
        });
    return ... 
}
```

|      | Start the request asynchronously, independent from handling. |
| ---- | ------------------------------------------------------------ |
|      | Perform handling and return completion `Mono<Void>`.         |

#### 5.2.3. Requests

Once you have a [client](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-requester-client) or [server](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-requester-server) requester, you can make requests as follows:

Java

Kotlin

```java
ViewBox viewBox = ... ;

Flux<AirportLocation> locations = requester.route("locate.radars.within") 
        .data(viewBox) 
        .retrieveFlux(AirportLocation.class); 
```

|      | Specify a route to include in the metadata of the request message. |
| ---- | ------------------------------------------------------------ |
|      | Provide data for the request message.                        |
|      | Declare the expected response.                               |

The interaction type is determined implicitly from the cardinality of the input and output. The above example is a `Request-Stream` because one value is sent and a stream of values is received. For the most part you don’t need to think about this as long as the choice of input and output matches an RSocket interaction type and the types of input and output expected by the responder. The only example of an invalid combination is many-to-one.

The `data(Object)` method also accepts any Reactive Streams `Publisher`, including `Flux` and `Mono`, as well as any other producer of value(s) that is registered in the `ReactiveAdapterRegistry`. For a multi-value `Publisher` such as `Flux` which produces the same types of values, consider using one of the overloaded `data` methods to avoid having type checks and `Encoder` lookup on every element:

```java
data(Object producer, Class<?> elementClass);
data(Object producer, ParameterizedTypeReference<?> elementTypeRef);
```

The `data(Object)` step is optional. Skip it for requests that don’t send data:

Java

Kotlin

```java
Mono<AirportLocation> location = requester.route("find.radar.EWR"))
    .retrieveMono(AirportLocation.class);
```

Extra metadata values can be added if using [composite metadata](https://github.com/rsocket/rsocket/blob/master/Extensions/CompositeMetadata.md) (the default) and if the values are supported by a registered `Encoder`. For example:

Java

Kotlin

```java
String securityToken = ... ;
ViewBox viewBox = ... ;
MimeType mimeType = MimeType.valueOf("message/x.rsocket.authentication.bearer.v0");

Flux<AirportLocation> locations = requester.route("locate.radars.within")
        .metadata(securityToken, mimeType)
        .data(viewBox)
        .retrieveFlux(AirportLocation.class);
```

For `Fire-and-Forget` use the `send()` method that returns `Mono<Void>`. Note that the `Mono` indicates only that the message was successfully sent, and not that it was handled.

For `Metadata-Push` use the `sendMetadata()` method with a `Mono<Void>` return value.

### 5.3. Annotated Responders

RSocket responders can be implemented as `@MessageMapping` and `@ConnectMapping` methods. `@MessageMapping` methods handle individual requests while `@ConnectMapping` methods handle connection-level events (setup and metadata push). Annotated responders are supported symmetrically, for responding from the server side and for responding from the client side.

#### 5.3.1. Server Responders

To use annotated responders on the server side, add `RSocketMessageHandler` to your Spring configuration to detect `@Controller` beans with `@MessageMapping` and `@ConnectMapping` methods:

Java

Kotlin

```java
@Configuration
static class ServerConfig {

    @Bean
    public RSocketMessageHandler rsocketMessageHandler() {
        RSocketMessageHandler handler = new RSocketMessageHandler();
        handler.routeMatcher(new PathPatternRouteMatcher());
        return handler;
    }
}
```

Then start an RSocket server through the Java RSocket API and plug the `RSocketMessageHandler` for the responder as follows:

Java

Kotlin

```java
ApplicationContext context = ... ;
RSocketMessageHandler handler = context.getBean(RSocketMessageHandler.class);

CloseableChannel server =
    RSocketServer.create(handler.responder())
        .bind(TcpServerTransport.create("localhost", 7000))
        .block();
```

`RSocketMessageHandler` supports [composite](https://github.com/rsocket/rsocket/blob/master/Extensions/CompositeMetadata.md) and [routing](https://github.com/rsocket/rsocket/blob/master/Extensions/Routing.md) metadata by default. You can set its [MetadataExtractor](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-metadata-extractor) if you need to switch to a different mime type or register additional metadata mime types.

You’ll need to set the `Encoder` and `Decoder` instances required for metadata and data formats to support. You’ll likely need the `spring-web` module for codec implementations.

By default `SimpleRouteMatcher` is used for matching routes via `AntPathMatcher`. We recommend plugging in the `PathPatternRouteMatcher` from `spring-web` for efficient route matching. RSocket routes can be hierarchical but are not URL paths. Both route matchers are configured to use "." as separator by default and there is no URL decoding as with HTTP URLs.

`RSocketMessageHandler` can be configured via `RSocketStrategies` which may be useful if you need to share configuration between a client and a server in the same process:

Java

Kotlin

```java
@Configuration
static class ServerConfig {

    @Bean
    public RSocketMessageHandler rsocketMessageHandler() {
        RSocketMessageHandler handler = new RSocketMessageHandler();
        handler.setRSocketStrategies(rsocketStrategies());
        return handler;
    }

    @Bean
    public RSocketStrategies rsocketStrategies() {
        return RSocketStrategies.builder()
            .encoders(encoders -> encoders.add(new Jackson2CborEncoder()))
            .decoders(decoders -> decoders.add(new Jackson2CborDecoder()))
            .routeMatcher(new PathPatternRouteMatcher())
            .build();
    }
}
```

#### 5.3.2. Client Responders

Annotated responders on the client side need to be configured in the `RSocketRequester.Builder`. For details, see [Client Responders](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-requester-client-responder).

#### 5.3.3. @MessageMapping

Once [server](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-annot-responders-server) or [client](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-annot-responders-client) responder configuration is in place, `@MessageMapping` methods can be used as follows:

Java

Kotlin

```java
@Controller
public class RadarsController {

    @MessageMapping("locate.radars.within")
    public Flux<AirportLocation> radars(MapRequest request) {
        // ...
    }
}
```

The above `@MessageMapping` method responds to a Request-Stream interaction having the route "locate.radars.within". It supports a flexible method signature with the option to use the following method arguments:

| Method Argument                | Description                                                  |
| :----------------------------- | :----------------------------------------------------------- |
| `@Payload`                     | The payload of the request. This can be a concrete value of asynchronous types like `Mono` or `Flux`.**Note:** Use of the annotation is optional. A method argument that is not a simple type and is not any of the other supported arguments, is assumed to be the expected payload. |
| `RSocketRequester`             | Requester for making requests to the remote end.             |
| `@DestinationVariable`         | Value extracted from the route based on variables in the mapping pattern, e.g. `@MessageMapping("find.radar.{id}")`. |
| `@Header`                      | Metadata value registered for extraction as described in [MetadataExtractor](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-metadata-extractor). |
| `@Headers Map<String, Object>` | All metadata values registered for extraction as described in [MetadataExtractor](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-metadata-extractor). |

The return value is expected to be one or more Objects to be serialized as response payloads. That can be asynchronous types like `Mono` or `Flux`, a concrete value, or either `void` or a no-value asynchronous type such as `Mono<Void>`.

The RSocket interaction type that an `@MessageMapping` method supports is determined from the cardinality of the input (i.e. `@Payload` argument) and of the output, where cardinality means the following:

| Cardinality | Description                                                  |
| :---------- | :----------------------------------------------------------- |
| 1           | Either an explicit value, or a single-value asynchronous type such as `Mono<T>`. |
| Many        | A multi-value asynchronous type such as `Flux<T>`.           |
| 0           | For input this means the method does not have an `@Payload` argument.For output this is `void` or a no-value asynchronous type such as `Mono<Void>`. |

The table below shows all input and output cardinality combinations and the corresponding interaction type(s):

| Input Cardinality | Output Cardinality | Interaction Types                 |
| :---------------- | :----------------- | :-------------------------------- |
| 0, 1              | 0                  | Fire-and-Forget, Request-Response |
| 0, 1              | 1                  | Request-Response                  |
| 0, 1              | Many               | Request-Stream                    |
| Many              | 0, 1, Many         | Request-Channel                   |

#### 5.3.4. @ConnectMapping

`@ConnectMapping` handles the `SETUP` frame at the start of an RSocket connection, and any subsequent metadata push notifications through the `METADATA_PUSH` frame, i.e. `metadataPush(Payload)` in `io.rsocket.RSocket`.

`@ConnectMapping` methods support the same arguments as [@MessageMapping](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-annot-messagemapping) but based on metadata and data from the `SETUP` and `METADATA_PUSH` frames. `@ConnectMapping` can have a pattern to narrow handling to specific connections that have a route in the metadata, or if no patterns are declared then all connections match.

`@ConnectMapping` methods cannot return data and must be declared with `void` or `Mono<Void>` as the return value. If handling returns an error for a new connection then the connection is rejected. Handling must not be held up to make requests to the `RSocketRequester` for the connection. See [Server Requester](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#rsocket-requester-server) for details.

### 5.4. MetadataExtractor

Responders must interpret metadata. [Composite metadata](https://github.com/rsocket/rsocket/blob/master/Extensions/CompositeMetadata.md) allows independently formatted metadata values (e.g. for routing, security, tracing) each with its own mime type. Applications need a way to configure metadata mime types to support, and a way to access extracted values.

`MetadataExtractor` is a contract to take serialized metadata and return decoded name-value pairs that can then be accessed like headers by name, for example via `@Header` in annotated handler methods.

`DefaultMetadataExtractor` can be given `Decoder` instances to decode metadata. Out of the box it has built-in support for ["message/x.rsocket.routing.v0"](https://github.com/rsocket/rsocket/blob/master/Extensions/Routing.md) which it decodes to `String` and saves under the "route" key. For any other mime type you’ll need to provide a `Decoder` and register the mime type as follows:

Java

Kotlin

```java
DefaultMetadataExtractor extractor = new DefaultMetadataExtractor(metadataDecoders);
extractor.metadataToExtract(fooMimeType, Foo.class, "foo");
```

Composite metadata works well to combine independent metadata values. However the requester might not support composite metadata, or may choose not to use it. For this, `DefaultMetadataExtractor` may needs custom logic to map the decoded value to the output map. Here is an example where JSON is used for metadata:

Java

Kotlin

```java
DefaultMetadataExtractor extractor = new DefaultMetadataExtractor(metadataDecoders);
extractor.metadataToExtract(
    MimeType.valueOf("application/vnd.myapp.metadata+json"),
    new ParameterizedTypeReference<Map<String,String>>() {},
    (jsonMap, outputMap) -> {
        outputMap.putAll(jsonMap);
    });
```

When configuring `MetadataExtractor` through `RSocketStrategies`, you can let `RSocketStrategies.Builder` create the extractor with the configured decoders, and simply use a callback to customize registrations as follows:

Java

Kotlin

```java
RSocketStrategies strategies = RSocketStrategies.builder()
    .metadataExtractorRegistry(registry -> {
        registry.metadataToExtract(fooMimeType, Foo.class, "foo");
        // ...
    })
    .build();
```

## 6. Reactive Libraries

`spring-webflux` depends on `reactor-core` and uses it internally to compose asynchronous logic and to provide Reactive Streams support. Generally, WebFlux APIs return `Flux` or `Mono` (since those are used internally) and leniently accept any Reactive Streams `Publisher` implementation as input. The use of `Flux` versus `Mono` is important, because it helps to express cardinality — for example, whether a single or multiple asynchronous values are expected, and that can be essential for making decisions (for example, when encoding or decoding HTTP messages).

For annotated controllers, WebFlux transparently adapts to the reactive library chosen by the application. This is done with the help of the [`ReactiveAdapterRegistry`](https://docs.spring.io/spring-framework/docs/5.3.2/javadoc-api/org/springframework/core/ReactiveAdapterRegistry.html), which provides pluggable support for reactive library and other asynchronous types. The registry has built-in support for RxJava 2/3, RxJava 1 (via RxJava Reactive Streams bridge), and `CompletableFuture`, but you can register others, too.

|      | As of Spring Framework 5.3, support for RxJava 1 is deprecated. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

For functional APIs (such as [Functional Endpoints](https://docs.spring.io/spring-framework/docs/current/reference/html/web-reactive.html#webflux-fn), the `WebClient`, and others), the general rules for WebFlux APIs apply — `Flux` and `Mono` as return values and a Reactive Streams `Publisher` as input. When a `Publisher`, whether custom or from another reactive library, is provided, it can be treated only as a stream with unknown semantics (0..N). If, however, the semantics are known, you can wrap it with `Flux` or `Mono.from(Publisher)` instead of passing the raw `Publisher`.

For example, given a `Publisher` that is not a `Mono`, the Jackson JSON message writer expects multiple values. If the media type implies an infinite stream (for example, `application/json+stream`), values are written and flushed individually. Otherwise, values are buffered into a list and rendered as a JSON array.