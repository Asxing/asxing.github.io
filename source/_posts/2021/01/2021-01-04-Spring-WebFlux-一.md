---
title: Spring WebFlux(一)
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Reactive
  - Webflux
date: 2021-01-04 22:39:41
password:
summary: 
categories: Spring
---

# Reactive

反应系统具有某些特性，使其非常适合低延迟，高吞吐量的工作负载。Project Reactor 和 Spring 产品组合一起使开发人员能够构建可响应，有弹性，有弹性和消息驱动的企业级反应系统。

### 什么是 reactive processing?

响应式处理是使开发人员能够构建可处理背压（流控制）的非阻塞异步应用程序的范例。

### 为什么使用 reactive processing?

反应系统更好地利用了现代处理器。同样，在反应式编程中包含背压可确保解耦组件之间的弹性更好。

## Project Reactor

Project Reactor 是一个完全无阻塞的基础，其中包括背压支持。它是Spring生态系统中反应式堆的基础，并且在诸如Spring WebFlux，Spring Data和Spring Cloud Gateway等项目中得到了突出体现。

## Reactive Microservices

开发人员从阻塞代码转移到非阻塞代码的主要原因之一是效率。反应性代码用更少的资源就能完成更多工作。 Project Reactor 和 Spring WebFlux 使开发人员可以利用下一代多核处理器来处理潜在的大量并发连接。通过反应式处理，您可以使用更少的微服务实例来满足更多并发用户的需求。

## Reactive Microservices With Spring Boot

Spring产品组合提供了两个并行技术栈。一种基于带有Spring MVC和Spring Data结构的Servlet API。另一个是完全响应式堆栈，该技术栈利用了 Spring WebFlux 和 Spring Data 的响应式存储库。在这两种情况下，Spring Security 都为两个技术栈都提供了支持。

![img](https://cdn.jsdelivr.net/gh/HoldDie/img/20210104231206.svg)

## Integration with common technologies

以反应方式访问和处理数据很重要。 MongoDB，Redis和Cassandra在Spring Data中都具有原生响应式支持。许多关系数据库（Postgres，Microsoft SQL Server，MySQL，H2和Google Spanner）都通过R2DBC提供了响应式支持。在消息传递领域，Spring Cloud Stream还支持对 RabbitMQ 和 Kafka 等平台的反应式访问。



# 构建一个反应式 RESTful web 服务

## 构建环境

- Java 1.8 以上
- Maven 3.2 或 Gradle 4 以上

## 操作流程

### 创建一个 Maven 项目，添加 Maven 依赖

```xml
<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <version>2.4.1</version>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
    <version>2.4.1</version>
  </dependency>
  <dependency>
    <groupId>io.projectreactor</groupId>
    <artifactId>reactor-test</artifactId>
    <version>3.4.1</version>
    <scope>test</scope>
  </dependency>
</dependencies>

<build>
  <plugins>
    <plugin>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-maven-plugin</artifactId>
    </plugin>
  </plugins>
</build>
```

### 创建一个 WebFlux Handler(类似之前Service)

```java
package com.holddie.flux.hello;

import reactor.core.publisher.Mono;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;

@Component
public class GreetingHandler {
  public Mono<ServerResponse> hello(ServerRequest request) {
    return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON)
      .body(BodyInserters.fromValue("hello " + request.queryParam("name").get()));
  }
}
```

### 创建一个 Router(类似 Controller 路由注册)

```java
@Configuration
public class GreetingRouter {
	@Bean
	public RouterFunction<ServerResponse> route(GreetingHandler greetingHandler) {
		return RouterFunctions.route(RequestPredicates.GET("/hello")
				.and(RequestPredicates.accept(MediaType.APPLICATION_JSON)), greetingHandler::hello);
	}
}
```

### 创建一个 WebClient

```java
public class GreetingWebClient {

  private WebClient client = WebClient.create("http://localhost:8080");

  private Mono<ClientResponse> result = client.get()
    .uri("/hello?name=thomas")
    .accept(MediaType.APPLICATION_JSON)
    .exchange();

  public String getResult() {
    return ">> result = " + result.flatMap(res -> res.bodyToMono(String.class)).block();
  }
}
```

### 创建一个 SpringBoot 启动类

```java
@SpringBootApplication
public class HelloFluxApplication {
  public static void main(String[] args) {
    SpringApplication.run(HelloFluxApplication.class);
    GreetingWebClient greetingWebClient = new GreetingWebClient();
    System.out.println(greetingWebClient.getResult());
  }
}
```

### 编写测试类

测试访问 `http://localhost:8080/hello?name=thomas` 返回 `hello thomas`。

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.web.reactive.server.WebTestClient;

@ExtendWith(SpringExtension.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class HelloFluxApplicationTest {

  @Autowired
  private WebTestClient webTestClient;

  @Test
  public void testHello() {
    webTestClient.get().uri("hello?name=thomas")
      .accept(MediaType.APPLICATION_JSON)
      .exchange().expectStatus().isOk()
      .expectBody(String.class).isEqualTo("hello thomas");
  }
}
```

