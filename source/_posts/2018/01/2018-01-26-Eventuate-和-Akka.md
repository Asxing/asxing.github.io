---
title: Eventuate 和 Akka
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Eventuate
  - Akka
  - 微服务
date: 2018-01-26 21:32:16
password:
summary:  
categories: 事件驱动
---

Eventuate 和   Akka 的技术架构是怎样的？效率性能如何？

是否可以用于以下的场景：

1） 两个微服务间的数据同步

2） 记录数据变化的历史和审批信息

 

# 对比 Evaluate 和 Akka

本文翻译自：[A comparison of Akka Persistence with Eventuate](http://krasserm.github.io/2015/05/25/akka-persistence-eventuate-comparison/)

```
Akka Persistence和Eventuate都是Scala写的，基于Akka的event-sourcing和CQRS工具，以不同的方式实现分布式系统方案。
```

## Command side

```
在Akka Persistence中，command这边(CQRS中的C)是由`PersistentActor`(PA)来实现的，而Eventuate是由`EventSourcedActor`(EA)来实现的。他们的内部状态代表了应用的写入模型。
```

```
PA和EA根据写入模型来对新的command进行校验，如果校验成功，则生成并持久化一条/多条event,后续用于更新内部状态。当crash或正常的应用重启,内部状态可以通过重演整个event log中已持久化的event或从某一个snapshot开始重演，来恢复内部状态。PA和EA都支持发送消息到其他actor的至少送达一次机制, Akka Persistence提供了`AtleastOnceDelivery`来实现，而Eventuate则使用`ConfirmedDelivery`。
```

```
从这个角度来看，PA和EA非常相似。一个主要的区别是，PA必须是单例，而EA则是可复制和同步修改的多实例。如果Akka Persistence意外地创建和更新了两个具有相同`persistenceId`的PA的实例，那么底层的event log将会被污染，要么是覆盖已有事件，要么把彼此冲突的事件拼接了起来（重演结果将不再准确）。Akka Persitence的event log设计只容许一个*writer*，并且event log本身是不能被共享的。
```

```
在Eventtuate中，EA可以共享同一个event log。基于事先自定义的event路由规则，一个EA发出的的event可以被另一个EA消费。换而言之，EA之间通过这个共享的event log可以进行协作，例如不同类型的EA一起组成一个分布式业务流程，或者实现状态复制中多地址下相同类型的EA的重建和内部状态的更新。这里的多地址甚至可以是全局分布的(*globally distributed*)。多地址间的状态复制是异步的，并保证可靠性。
```

## Event Relations

```
在Akka Persistence中，每个PA产生的event是有序的，而不同PA产生的event之间是没有任何关联性的。即使一个PA产生的event是比另一个PA产生的event早诞生，但是Akka Persistence不会记录这种先后顺序。比如，PA1持久化了一个事件e1，然后发送了一个command给PA2，使得后者在处理该command时持久化了另一个事件e2，那么显然e1是先于e2的，但是系统本身无法通过对比e1和e2来决定他们之间的这种先后的关联性。
```

```
Eventuate额外跟踪记录了这种happened-before的关联性(潜在的因果关系)。例如，如果EA1持久化了事件e1，EA2因为消费了e1而产生了事件e2，那么e1比e2先发生的这种关联性会被记录下来。happen-before关联性由[vector clocks](http://rbmhtechnology.github.io/eventuate/architecture.html#vector-clocks)来跟踪记录，系统可以通过对比两个event的vector timestamps来决定他们之间的关联性是先后发生的还是同时发生的。
```

```
跟踪记录event间的happened-before关联是运行多份EA relica的前提。EA在消费来自于它的replica的event时，必需要清楚它的内部状态的更新到底是先于该事件的，还是同时发生(可能产生冲突)。
```

```
如果最后一次状态更新先于准备消费的event，那么这个准备消费的event可被当作一个普通的更新来处理；但如果是同时产生的，那么该event可能具有冲突性，必须做相应处理，比如，
```

- 如果EA内部状态是[CRDT](http://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)，则该冲突可以被自动解决(详见Eventuate的[operation-based CRDTs](http://rbmhtechnology.github.io/eventuate/user-guide.html#operation-based-crdts))
- 如果EA内部状态不是CRDT，Eventuate提供了进一步的方法来跟踪处理冲突,根据情况选择自动化或手动交互处理的方式。

## Event logs

```
前文提到过，Akka Persistence中，每一个PA有自己的event log。根据不同的存储后端，event log可冗余式的存于多个node上(比如为了保证高可用而采用的同步复制)，也可存于本地。不管是哪种方式，Akka Persistence都要求对event log的强一致性。
```

```
比如，当一个PA挂掉后，在另外一个node上恢复时，必须要保证该PA能够按正确的顺序读取到所有之前写入的event，否则这次恢复就是不完整的，可能会导致这个PA后面会覆写已存在的event，或者把一些与evet log中已有还未读的event有冲突的新event直接拼到event log后面，进而导致状态的不一致。所以，只有支持强一致性的存储后端才能被Akka Persistence使用。
```

```
AKka Persistence的写可用性取决于底层的存储后端的写可用性。根据[CAP理论](http://en.wikipedia.org/wiki/CAP_theorem)，对于强一致性、分布式的存储后端，它的写可用性是有局限性的，所以，Akka Persistence的command side选择CAP中的CP。
```

```
这种限制导致Akka Persistence很难做到全局分布下应用的强一致性，并且所有event的有序性还需要实现全局统一的协调处理。Eventuate在这点上做得要更好：它只要求在一个location上保持强一致性和event的有序性。这个location可以是一个数据中心、一个(微)服务、分布式中的一个节点、单节点下的一个流程等。
```

```
单location的Eventuate应用与Akka Persistence应用具有相同的一致性模型。但是，Eventuate应用通常会有多个location。单个location所产生的event会异步地、可靠地复制到其他location。跨location的evet复制是Eventuate独有的，并且保留了因果事件的存储顺序。不同location的存储后端之间并不直接通信，所以，不同location可以使用不同的存储后端。
```

```
Eventuate中在不同location间复制的event log被称之为**replicated event log**，它在某一个location上的代表被称为**local event log**。在不同location上的EA可以通过共享同一个replicated event log来进行event交换，从而为EA状态的跨location的状态复制提供了可能。即便是跨location的网络发生了隔断(network partition)，EA和它们底层的event log仍保持可写。从这个角度来说，一个多location的Eventuate应用从CAP中选择了AP。网络隔断后，在不同location的写入，可能会导致事件冲突，可用前面提到的方案去解决。
```

```
通过引入分割容忍（系统中任意信息的丢失或失败，不影响系统的继续运作）的location，event的全局完整排序将不再可能。在这种限制下的最强的部分排序是因果排序（casual ordering），例如保证happened-before关联关系的排序。Eventuate中，每一个location保证event以casual order递交给它们的本地EA(以及View，具体参见[下一节](http://edisonxu.org/2017/01/22/akka-persistence-eventuate-comparison.html#Query-side))。并发event在个别location的递交顺序可能不同，但在指定的location可重复提交的。
```

## Query side

```
Akka Persistence中，查询的一端(CQRS中的Q)可以用`PersistentView`(*PV*)来实现。目前一个PV仅限于消费一个PA所产生的event。这种限制在Akka的邮件群里被[大量讨论](https://groups.google.com/forum/#!msg/akka-user/MNDc9cVG1To/blqgyC7sIRgJ)过。从Akka2.4开始，一个比较好的方案是[Akka Persistence Query](http://doc.akka.io/docs/akka/2.4.0/scala/persistence-query.html)：把多个PA产生的event通过storage plugin进行聚合，聚合结果称为[Akka Streams](http://doc.akka.io/docs/akka-stream-and-http-experimental/1.0/scala.html)，把Akka Streams作为PV的输入。
```

```
Eventuate中，查询的这端由`EventsourcedView`(*EV*)来实现。一个EV可以消费来自于所有共享同一个event log的EA所产生的event，即使这些EA是全局分布式的。event永远按照正确的casual order被消费。一个Eventuate应用可以只用一个replicated event log，也可以用类似以topic形式区分的多个event log。未来的一些扩展将允许EV直接消费多个event log，同时，Eventuate的Akka Stream API也在规划中。
```

## Storage plugins

```
从storage plugin的角度看，Akka Persistence中event主要以`persistenceId`来区分管理，即每个PA实例拥有自己的event log。从多个PA实例进行event聚合就要求要么在storage后端创建额外的索引，要么创建实时的event流组成图(*stream composition*)，来服务查询。Eventuate中，从多个EA来的event都存储在同一个共享的event log中。在恢复时，没有预定义`aggregateId`的EA可消费该event log中的所有event，而定义过`aggregateId`的EA则只能作为路由目的地消费对应`aggregateId`的event。这就要求Eventuate的storage plugin必须维护一个独立index，以便于event通过`aggregateId`来重演。
```

```
Akka Persistence提供了一个用以存储日志和snapshot的公共storage plguin API，[社区贡献](http://akka.io/community/)了很多具体实现。Eventuate在未来也会定义一个公共的storage plugin API。就目前而言，可在LevelDB和Canssandra两者间任选一个作为存储后台。
```

## Throughput

```
Akka Persistence中的PA和Eventuate中的EA都可以选择是否保持内部状态与event log中的同步。这关系到应用在写入一个新的event前，需要对新command和内部状态所进行的校验。为了防止被校验的是陈旧状态(*stale state*)，新的command必须要等到当前正在运行的写操作成功结束。PA通过`persist`方法支持该机制(相反对应的是`persistAsync`)，EA则使用一个`stateSync`的布尔变量。
```

```
同步内部状态与event log的后果是造成吞吐率的下降。由于event批量写入实现的不同，Akka Persistence中的这种内部状态同步比Eventuate所造成的的影响要更大。Akka Persistence中，event的批处理只有在使用`persistAsync`时，才是在PA层面的，而Eventuate在EA和storage plugin两个地方分别提供了批处理，所以对于不同的EA实例所产生的event，即使他们与内部状态要同步，也能被批量写入。
```

```
Akka Persistence和Eventuate中，单个PA和EA实例的吞吐率大致上是一样的(前提是所用的storage plugin具有可比性)。但是，Eventuate的整体吞吐率可以通过增加EA实例来得到提升，Akka Persistence就不行。这对于按照每个聚合一个PA/EA的设计，且有成千上万的活跃(可写)实例的应用，就显得特别有意义。仔细阅读Akka Persistence的代码，我认为把批处理逻辑从PA挪到独立的层面去，应该不需要很大的功夫。
```

## Conclusion

```
Eventuate支持与Akka Persistence相同的一致性模型，但是额外支持了因果一致性，对于实现EA的高可用和分隔容忍(CAP中的AP)是必要条件。Eventuate还支持基于因果排序、去重复event流的可靠actor协作。从这些角度来看，Eventuate是Akka Persistence功能性的超集。
```

```
如果选择可用性高于一致性，冲突发现和(自动或交互式的)解决必须是首要考虑。Eventuate通过提供operation-based CRDT以及发现和解决应用状态冲突版本的工具、API，来提供支持。
```

```
对于分布式系统的弹性来说，处理错误比预防错误要显得更为重要。一个临时与其他location掉队分隔的location能继续保持运作，使得Eventuate成为离线场景的一个有意思的选择。
```

 

# Eventuate

Eventuate™是开发使用[微服务架构的](http://microservices.io/patterns/microservices.html)事务性业务应用程序的平台。Eventuate为基于[事件采购](http://microservices.io/patterns/data/event-sourcing.html)和[CQRS的](http://microservices.io/patterns/data/cqrs.html)微服务提供了事件驱动的编程模型。

Eventuate的好处包括：

- 轻松实现跨越多个微服务的最终一致的业务交易
- 每当数据发生变化时自动发布事件
- 使用CQRS物化视图更快，更具可扩展性的查询
- 可靠的审计所有更新
- 内置的时间查询支持

[Eventuate™Local](https://github.com/eventuate-local/eventuate-local)是[Eventuate™](https://github.com/eventuate-local/eventuate-local)的开源版本。它具有与 SaaS版本相同的[客户端框架API](http://eventuate.io/gettingstarted.html)，但具有不同的体系结构。它**使用MySQL数据库来保存事件**，从而保证应用程序可以**持续读取自己的写入**。Eventuate Local会**跟踪**[MySQL事务日志，](http://microservices.io/patterns/data/transaction-log-tailing.html)并将**事件发布到Apache Kafka**，从而使应用程序[可以从Apache Kafka生态系统（包括Kafka Streams等）中受益](http://www.confluent.io/blog/event-sourcing-cqrs-stream-processing-apache-kafka-whats-connection/)。

该图显示了该架构：

![](https://www.holddie.com/img/20200105143433.png)

## Eventuate 体系结构

Eventuate应用程序由四种类型的模块组成，每个模块都有不同的角色和责任。

下图显示了一个Eventuate应用程序的体系结构：

![img](http://eventuate.io/i/EventuateArchBigPicture.png)

Eventuate应用程序由以下类型的模块组成：

- 命令端模块
- 查询侧视图更新模块
- 查询端查看查询模块模块
- 出站网关模块

请注意，这是应用程序的逻辑体系结构。这些模块既可以作为一个整体应用程序一起部署，也可以作为独立的微服务单独部署。

## 命令端模块

Eventuate应用程序的命令端由一个或多个命令端模块组成。命令端模块根据外部更新请求（例如，HTTP POST，PUT和DELETE请求）以及命令端聚合发布的事件来创建和更新聚集。命令端模块由以下组件组成：

- **集合** - 实现大部分业务逻辑，并使用事件采购来坚持
- **服务** - 通过创建和更新聚合来处理外部请求
- **事件处理程序** - 通过创建和更新聚合来处理事件

## 查询端模块

Eventuate应用程序的查询端维护命令端集合的一个或多个物化（CQRS）视图。每个视图都有两个模块：

- **查看更新模块** - 订阅事件并更新视图
- **查看查询模块** - 通过查询视图来处理查询（例如，HTTP GET）请求

## 出站网关模块

出站网关模块通过调用外部服务来处理事件。

 

## Java和Spring的Eventuate客户端框架

Eventuate客户端框架使您能够使用Java和Spring编写Eventuate应用程序。它提供了用于编写应用程序组件的接口，类和注释。

### Javadoc

- [Javadoc](http://eventuate.io/docs/javadoc/0.16.0.RELEASE)

### 事件类型

客户端框架为[定义事件类](http://eventuate.io/docs/java/java-events.html)提供了以下类型：

- `Event` 界面 - 事件的超级界面
- `@EventEntity` 注释 - 指定事件的实体类型名称的注释

### 聚合类型

客户端框架提供了几种不同的类型，可以用来[实现聚合](http://eventuate.io/docs/java/java-aggregates.html)。

聚合必须实现`CommandProcessingAggregate`接口，它定义了两个方法：

- `processCommand()` - 从更新请求中获取命令对象并返回一系列事件
- `applyEvent()`- 接收事件并返回更新的聚合`applyEvent()`当处理请求以更新状态以反映新事件时，调用该方法。当实体的当前状态通过从事件存储器加载它的事件并重放它们而被重构时，这个方法也被调用。

聚合可以扩展`ReflectiveMutableCommandProcessingAggregate`超类，而不是直接实现这个接口。这个类扩展`CommandProcessingAggregate`和实现`processCommand()`和`applyEvent()`使用反射。该`processCommand()`方法`process()`根据命令类型调用适当的。同样，该`applyEvent()`方法`apply()`根据事件类型调用适当的方法。

### 命令类型

客户端框架为[定义命令](http://eventuate.io/docs/java/java-commands.html)提供了以下类型：

- `Command` 接口 - 所有命令的超级接口

### 服务类型

客户端框架为编写[命令端服务](http://eventuate.io/docs/java/java-services.html)提供了以下类型：

- `AggregateRepository` - 定义创建和更新聚合的方法。这是一个帮助程序类，隐藏了样板代码，否则您需要编写该代码以使用事件存储。

### 命令端事件处理程序类型

客户端框架为[编写命令端事件处理程序](http://eventuate.io/docs/java/java-command-side-event-handlers.html)提供了几种类型：

- `@EventSubscriber` - 将Spring bean标识为事件处理程序的注释
- `@EventHandlerMethod` - 将方法标识为事件处理程序方法的注释
- `EventHandlerContext` - 命令端事件处理程序方法的参数类型。它提供对事件的访问，并定义创建和更新聚合的方法。

### 查询方组件和出站网关事件处理程序类型

客户端框架提供了几种用于编写[查询端组件](http://eventuate.io/docs/java/java-defining-query-side-event-handlers.html)和[出站网关](http://eventuate.io/docs/java/java-defining-outbound-gateways.html)事件处理程序的类型：

- `@EventSubscriber` - 将Spring bean标识为事件处理程序的注释
- `@EventHandlerMethod` - 将方法标识为事件处理程序方法的注释
- `DispatchedEvent` - 查询端和出站网关事件处理程序方法的参数类型。它提供了访问的事件。

### 配置类型

客户端框架为[配置Spring应用程序上下文](http://eventuate.io/docs/java/spring-configuration.html)提供了以下类型：

- `@EnableJavaEventHandlers`- `@Configuration`类的注释，使您的自动注册`@EventSubscribers`
- `EventStoreHttpClientConfiguration`- `@Configuration`您`@Import`为了配置Eventuate基于HTTP / STOMP的客户端的类
- `JdbcEventStoreConfiguration`- `@Configuration`您`@Import`为了配置嵌入式测试事件存储的类



# Akka

### 简介

- Akka 是运行JVM上，构建高并发、分布式和事件驱动应用的一个工具类。
- Akka 可用 Java 或 Scala 开发。
- Actors 是 Akka 核心执行单元，Actor 模型是抽象的，可以使我们更容易编写高并发，并行、分布式系统。

## 1. Hello Wold

本例介绍一个简单的Demo，理解 Akka 原理

### 克隆工程

```shell
//克隆地址
git clone  https://github.com/akka/akka-quickstart-java.g8.git
//进入工程
cd akka-quickstart-java
```

### 运行项目

```shell
//若 maven
mvn compile exec:exec
//若 Gradle
gradle run
```

#### 提示：

```
在运行 `maven` 命令的时候，是不是很奇怪为什么会有 `exec：exec` ，当然有时也会见到 `exec:java` 。这里解释一下，两者的区别主要是在**线程管理**上， `exec：exec` 总是启动一个新的线程，并且在只剩下守护线程的时候从 VM 上退出（关闭应用程序）；而 `exec：java` 当所有费守护线程结束时，守护线程会被 `joine` 或 `interrupte`，应该程序不会关闭。
```

```
接下来说一下 `exec：exec` 实际代表什么， 当我们运行 `jar` 包时普通情况下写   `java -DsystemProperty1=value1 -DsystemProperty2=value2 -XX:MaxPermSize=256m -classpath .... com.yourcompany.app.Main arg1 arg2`  一串十分复杂，本示例中通过在pom文件中配置后，只需 `exec` 即可。
```

```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>exec-maven-plugin</artifactId>
    <version>1.6.0</version>
    <configuration>
        <executable>java</executable>
        <arguments>
          <argument>-classpath</argument>
          <classpath />
          <argument>com.lightbend.akka.sample.AkkaQuickstart</argument>
        </arguments>
    </configuration>
</plugin>
```

### 运行结果

![mark](http://oumk5fhgp.bkt.clouddn.com/blog/171222/dGdlkKD214.png?imageslim)

到此，运行程序你可以在屏幕看见输出打招呼的语句，那么恭喜你运行成功了，接下来看

### 实现原理

![1](https://developer.lightbend.com/guides/akka-quickstart-java/images/hello-akka-architecture.png)

#### 首先，通过 main 类创建一个运行 Actors 的环境，创建三个 Greeter Actor 和 一个 Printer Actor。

#### 然后，分别向三个 Greeter Actor 发送信息，它们分别内部存储消息。

#### 最后，给 Greeter Actor 指令触发其向 Printer Actor 发送消息，Printer Actor 将他们输出到控制台。

![](https://www.holddie.com/img/20200105143518.png)

### 使用 Actor Model 的好处

- 事件驱动模型，Actors 通过消息执行工作。Actors 之间异步通信，使得它们之间不需要等待回复阻塞发送消息和继续执行工作。
- 强大的隔离原则，与 Java 中的常规对象不同，就方法调用而言，Actor 没有公共的 API。相反，它的公共API是通过 actor 处理的消息来定义，这阻止了 Actor 之间的任何状态共享，了解其他 actor 的状态唯一的方法是通过发送消息来询问。
- 位置透明，系统通过工厂创建 Actor 并返回其引用， 由于位置不重要，Actor 实例可以启动，停止，移动和重启以缩放以及从意外故障中恢复。
- 轻量级，每个实例只消耗几百字节，这实际允许数百万个并发 Actor 存在于一个应用程序中。

## 2. 定义 Actors 和 message

消息可以是任意类型，你可以发送原始的值（如 `String`，`Integer`，`Boolean`）或者也可以像数组和集合这样普通的数据结构。

上述示例中 Actors 使用了三种不同的消息：

- `WhoToGreet`：接收问候的消息
- `Greet`： 执行问候的指令
- `Greeting`： 包含问候的消息

### 在定义 Actors 和 它的消息时，有如下建议：

- 由于消息是 Actor 的公共API，定义一个具有良好名称和丰富的语义和特定领域含义的消息是一个好习惯，即使他们只是封装你的数据类型。这将更容易使用，理解和基于角色的调试系统。
- 消息应该是不可变的，因为它们在不同的线程之间共享。
- 一个好的习惯的是将 Actor 的相关消息作为静态类放入 Actor 类中，这将更容易理解本 Actor 的期望和处理类型。
- 一个常见的模式是在描述如何构造Actor的 Actor 类中使用静态方法。

### The Greeter Actor

```java
package com.lightbend.akka.sample;
 
import akka.actor.AbstractActor;
import akka.actor.ActorRef;
import akka.actor.Props;
import com.lightbend.akka.sample.Printer.Greeting;
 
//#greeter-messages
public class Greeter extends AbstractActor {
//#greeter-messages
  static public Props props(String message, ActorRef printerActor) {
    return Props.create(Greeter.class, () -> new Greeter(message, printerActor));
  }
 
  //#greeter-messages
  static public class WhoToGreet {
    public final String who;
 
    public WhoToGreet(String who) {
        this.who = who;
    }
  }
 
  static public class Greet {
    public Greet() {
    }
  }
  //#greeter-messages
 
  private final String message;
  private final ActorRef printerActor;
  private String greeting = "";
 
  public Greeter(String message, ActorRef printerActor) {
    this.message = message;
    this.printerActor = printerActor;
  }
 
  @Override
  public Receive createReceive() {
    return receiveBuilder()
        .match(WhoToGreet.class, wtg -> {
          this.greeting = message + ", " + wtg.who;
        })
        .match(Greet.class, x -> {
          //#greeter-send-message
          printerActor.tell(new Greeting(greeting), getSelf());
          //#greeter-send-message
        })
        .build();
  }
//#greeter-messages
}
//#greeter-messages
 
```

#### 现在分解这个类

- `Greeter` 类继承了 `akka.actor.AbstractActor` 类，实现了 `createReceive` 方法
- Greeter 的类构造函数包含两个参数， 第一个参数是： `String message` ，表示问候的消息，第二个参数是： `Actor printerActor` ,是处理输出问候的 `Actor` 的引用。
- `receiveBuilder` 定义 `Actor` 对于不同的消息做出不同的响应。一个 `Actor` 拥有自己的状态，由于受到 `Actor` 模型的保护，访问和改变 `Actor` 内部的状态完全是线程安全的。`createReceive` 方法应该处理 `actor` 期望的消息。在本方法中，它定义了两种类型的消息：`WhoToGreet` 和 `Greet` 。前者将会更新 `greeting` 变量的值，后者将会触发发送 `greeting` 给 `Printer Actor`
- 在 `Actor` 中 `greeting` 值的状态默认是 `""`
- 静态 Props 模板方法返回一个 Props 的引用，Props 是一个配置类，用于指定创建 actors 的选项，将其视为一个不变的因此可以自由共享用于创建包含相关部署信息的 Actor。这个例子只是传递 Actor 在构造时需要的参数。

### Printer Actor

```java
package com.lightbend.akka.sample;
 
import akka.actor.AbstractActor;
import akka.actor.Props;
import akka.event.Logging;
import akka.event.LoggingAdapter;
 
//#printer-messages
public class Printer extends AbstractActor {
//#printer-messages
  static public Props props() {
    return Props.create(Printer.class, () -> new Printer());
  }
 
  //#printer-messages
  static public class Greeting {
    public final String message;
 
    public Greeting(String message) {
      this.message = message;
    }
  }
  //#printer-messages
 
  private LoggingAdapter log = Logging.getLogger(getContext().getSystem(), this);
 
  public Printer() {
  }
 
  @Override
  public Receive createReceive() {
    return receiveBuilder()
        .match(Greeting.class, greeting -> {
            log.info(greeting.message);
        })
        .build();
  }
//#printer-messages
}
//#printer-messages
 
```

#### 要点

- 定义了一个 `log` 变量，可以轻松的使用 `log.info`
- 只处理一种类型的消息 `Greeting`，并记录该消息的内容

## 3. 创建 Actors

```
到此我们已经知道里的如何定义 `Actor` 和 消息。现在我们更加深入理解位置透明以及如何创建 `Actor` 实例。

```

### 位置透明

```
在 Akka 中，我们不能使用 `new` 关键字来创建 `Actor` 实例，相反我们通过工厂类。工厂类并不会返回Actor 实例，而是返回指向 `akka.actor.ActorRef` 的引用。这种间接的方式为分布式系统增加了很多功能和灵活性。

```

```
在 Akka 中位置是不重要的，位置透明意味着 `ActorRef` 可以再保留相同的语义的同时，代表正在运行的进程或远程机器的实例。如果需要，可以在运行时修改运行时`Actor`的位置或整个应用程序拓扑来优化系统。这使得即使出现错误的情况，系统也可以根据错误日志自动修复或者重启保持健康。

```

### Akka 系统

```
这个 `akka.actor.ActorSystem` 工厂类在某种程度上和 `Spring's BeanFactory` 十分相似。它作为一个 `Actor` 容器并管理他们的生命周期。这个 `Actor` 工厂类包含两个参数，一个 `Props` 配置对象和名称。

```

```
`Actor` 和 `ActorSystem` 名称在 `Akka` 中很重要，例如可以根据这个进行查找，还可以使用与领域模型一致的有意义的名称更容易推断出它们的功能。

```

##### 分析一下在 HelloWorld 中定义Actor

```java
//#create-actors
final ActorRef printerActor =
  system.actorOf(Printer.props(), "printerActor");
final ActorRef howdyGreeter =
  system.actorOf(Greeter.props("Howdy", printerActor), "howdyGreeter");
final ActorRef helloGreeter =
  system.actorOf(Greeter.props("Hello", printerActor), "helloGreeter");
final ActorRef goodDayGreeter =
  system.actorOf(Greeter.props("Good day", printerActor), "goodDayGreeter");
//#create-actors
```

#### 要点

- `ActorSystem`上的 `actorOf` 方法创建 `Printer Actor`。正如我们在上一个主题中所讨论的那样，它使用 `Printer` 类的静态`props`方法来获取 `Props` 值。`ActorRef` 提供对新创建的 `Printer Actor` 实例的引用。
- 对于`Greeter`，代码创建三个`Actor`实例，每个实例都有一个特定的问候消息。

## 4. 异步通信

### 要点

- Actors 本身是被动的，由消息驱动。
- Actors 只有在接到消息时，才会执行操作。
- Actors 之间的通信是异步的，这保证了他们不必等待消息的返回，在发送完消息之后就可以去做其他的事情。
- Actors 发送的消息，本质上是一个带有特定排序意义的消息队列。
- 多个Actor发送的消息是交织在一起，单个 Actor 它发送的消息是整体上是有序的。
- 当 Actor 没有接收到消息的时候，它处于暂停状态，除了占用一点内存，不消耗其他任何资源。
- 对于上述的执行结果，当我们多执行几次，对比打印的结果，发现打印顺序不同，这点就是异步最好证明

![mark](http://oumk5fhgp.bkt.clouddn.com/blog/171223/h1defkBdEF.png?imageslim)

### 发送消息给 Actor

将发送的消息加入 Actor 的消息队列，在 ActorRef 上使用 tell 方法。

在 Mian 类中，发送消息到 Greeter Actor 如下：

```java
//#main-send-messages
howdyGreeter.tell(new WhoToGreet("Akka"), ActorRef.noSender());
howdyGreeter.tell(new Greet(), ActorRef.noSender());
 
howdyGreeter.tell(new WhoToGreet("Lightbend"), ActorRef.noSender());
howdyGreeter.tell(new Greet(), ActorRef.noSender());
 
helloGreeter.tell(new WhoToGreet("Java"), ActorRef.noSender());
helloGreeter.tell(new Greet(), ActorRef.noSender());
 
goodDayGreeter.tell(new WhoToGreet("Play"), ActorRef.noSender());
goodDayGreeter.tell(new Greet(), ActorRef.noSender());
//#main-send-messages
```

在 Greeter 类中，发送消息到 Printer Actor 中：

```java
printerActor.tell(new Greeting(greeting), getSelf());
```

到此，我们在回忆一下这张图，有助于理解，消息传递和处理过程。

![1](https://developer.lightbend.com/guides/akka-quickstart-java/images/hello-akka-messages.png)

## 5. Main 类

- 在 Hello world 的 Main 类中创建和控制 Actors
- 使用 ActorSytem 作为一个容器
- 使用 actorOf 方法创建 Actors

```java
package com.lightbend.akka.sample;
 
import akka.actor.ActorRef;
import akka.actor.ActorSystem;
import com.lightbend.akka.sample.Greeter.*;
 
import java.io.IOException;
 
public class AkkaQuickstart {
  public static void main(String[] args) {
    final ActorSystem system = ActorSystem.create("helloakka");
    try {
      //#create-actors
        final ActorRef printerActor =
                system.actorOf(Printer.props(), "printerActor");
        final ActorRef howdyGreeter =
                system.actorOf(Greeter.props("Howdy", printerActor), "howdyGreeter");
        final ActorRef helloGreeter =
                system.actorOf(Greeter.props("Hello", printerActor), "helloGreeter");
        final ActorRef goodDayGreeter =
                system.actorOf(Greeter.props("Good day", printerActor), "goodDayGreeter");
        //#create-actors
 
      //#main-send-messages
      howdyGreeter.tell(new WhoToGreet("Akka"), ActorRef.noSender());
      howdyGreeter.tell(new Greet(), ActorRef.noSender());
 
      howdyGreeter.tell(new WhoToGreet("Lightbend"), ActorRef.noSender());
      howdyGreeter.tell(new Greet(), ActorRef.noSender());
 
      helloGreeter.tell(new WhoToGreet("Java"), ActorRef.noSender());
      helloGreeter.tell(new Greet(), ActorRef.noSender());
 
      goodDayGreeter.tell(new WhoToGreet("Play"), ActorRef.noSender());
      goodDayGreeter.tell(new Greet(), ActorRef.noSender());
      //#main-send-messages
 
      System.out.println(">>> Press ENTER to exit <<<");
      System.in.read();
    } catch (IOException ioe) {
    } finally {
      system.terminate();
    }
  }
}
```

 

# 数据一致性

### 数据一致性的几种实现方式：

传统事务管理：

- 本地事务
- 分布式事务
  - 两阶段提交（2PC）
  - 三阶段提交（3PC）

微服务事务：

- 可靠事件通知模式
  - 同步事件
  - 异步事件
    - 本地事件服务
    - 外部事件服务
- 最大努力通知模式
- 业务补偿模式
- TCC/Try Confirm Cancel 模式

### 微服务数据一致性实现思路

分布式事务2PC或者3PC是否适合于微服务下的事务管理呢？答案是否定的，原因有三点：

- 由于微服务间无法直接进行数据访问，微服务间互相调用通常通过RPC（dubbo）或Http API（SpringCloud）进行，所以已经无法使用TM统一管理微服务的RM。

- 不同的微服务使用的数据源类型可能完全不同，如果微服务使用了NoSQL之类不支持事务的数据库，则事务根本无从谈起。

- 即使微服务使用的数据源都支持事务，那么如果使用一个大事务将许多微服务的事务管理起来，这个大事务维持的时间，将比本地事务长几个数量级。如此长时间的事务及跨服务的事务，将为产生很多锁及数据不可用，严重影响系统性能。

  由此可见，传统的分布式事务已经无法满足微服务架构下的事务管理需求。那么，既然无法满足传统的ACID事务，在微服务下的事务管理必然要遵循新的法则－－BASE理论。

  BASE理论由eBay的架构师Dan Pritchett提出，BASE理论是对CAP理论的延伸，核心思想是即使无法做到强一致性，应用应该可以采用合适的方式达到最终一致性。BASE是指基本可用（Basically Available）、软状态（ Soft State）、最终一致性（ Eventual Consistency）。

> 基本可用：指分布式系统在出现故障的时候，允许损失部分可用性，即保证核心可用。

> 软状态：允许系统存在中间状态，而该中间状态不会影响系统整体可用性。分布式存储中一般一份数据至少会有三个副本，允许不同节点间副本同步的延时就是软状态的体现。

> 最终一致性：最终一致性是指系统中的所有数据副本经过一定时间后，最终能够达到一致的状态。弱一致性和强一致性相反，最终一致性是弱一致性的一种特殊情况。

```
BASE中的最终一致性是对于微服务下的事务管理的根本要求，既基于微服务的事务管理无法达到强一致性，但必须保证最重一致性。那么，有哪些方法可以保证微服务下的事务管理的最终一致性呢，按照实现原理分主要有两类，事件通知型和补偿型，其中事件通知型又可分为可靠事件通知模式及最大努力通知模式，而补偿型又可分为TCC模式、和业务补偿模式两种。这四种模式都可以达到微服务下的数据最终一致性。

```

| 类型   | 名称   | 数据一致性的实时性 | 开发成本 | 上游服务是否依赖下游服务结果 |
| ---- | ---- | --------- | ---- | -------------- |
| 通知型  | 最大努力 | 低         | 低    | 不依赖            |
| 通知型  | 可靠事件 | 高         | 高    | 不依赖            |
| 补偿型  | 业务补偿 | 低         | 低    | 依赖             |
| 补偿型  | TCC  | 高         | 高    | 依赖             |

### 查询难点破解

```
由于微服务或系统的数据库独立，查询变得困难，多表的join无法完成。一个好办法是建立一个汇总库，把各个微服务的数据库数据同步进来，查询在总库完成，从而可以轻松简单解决。对于oracle数据库，同步变得简单，使用rac、adg可以轻松完成。对于mysql数据库，有2个办法。

```

1. 采用消息机制，当代码里数据库发生cud数据，则发送消息，然后调用线程把数据同步到总库。
2. 二根据数据库的log，把变化的数据同步到总库。阿里的mysql同步技术天下第一，开发了oceanbase分布式全球数据库，实现数据同步，为满足双11的天量访问并发提供了坚实的基础。

#### 回归到 Eventuate

```
Eventuate Local **使用MySQL数据库来保存事件**，从而保证应用程序可以**持续读取自己的写入**。Eventuate Local会**跟踪**[MySQL事务日志，](http://microservices.io/patterns/data/transaction-log-tailing.html)并将**事件发布到Apache Kafka**，从而使应用程序[可以从Apache Kafka生态系统（包括Kafka Streams等）中受益](http://www.confluent.io/blog/event-sourcing-cqrs-stream-processing-apache-kafka-whats-connection/)。

```

 

### 根据系统的业务需求，以下是分布式数据一致性实现方式，以供参考：

 

### 1. elephant：https://github.com/yanghuijava/elephant

```
可靠事件系统，用于保证消息生产者生产的消息能可靠的发送出去，即本地事务执行成功，消息也一定要发送成功。无论是SOA系统还是微服务系统，只要是分布式系统就会遇到分布式事务问题，目前业界解决分布式事务问题都是基于BASE理论，保证数据的最终一致性；具体的方案如补偿模式，可靠事件模式和TCC型事务等，而本系统就是基于可靠事件的一种实现。

```

#### 实现原理

[![image](https://github.com/yanghuijava/elephant/raw/master/screenshots/%E4%BA%8B%E5%8A%A1%E6%B6%88%E6%81%AF.png)](https://github.com/yanghuijava/elephant/blob/master/screenshots/%E4%BA%8B%E5%8A%A1%E6%B6%88%E6%81%AF.png)

#### 消息投递流程

[![image](https://github.com/yanghuijava/elephant/raw/master/screenshots/%E5%8F%AF%E9%9D%A0%E6%B6%88%E6%81%AF%E6%8A%95%E9%80%921.png)](https://github.com/yanghuijava/elephant/blob/master/screenshots/%E5%8F%AF%E9%9D%A0%E6%B6%88%E6%81%AF%E6%8A%95%E9%80%921.png)

 

### 2. Ray：https://github.com/luohuazhiyu/Ray

```
这是一个集成Actor,Event Sourcing(事件溯源),Eventual consistency(最终一致性)的无数据库事务，高性能分布式云框架(构建集群请参阅:<http://dotnet.github.io/orleans/>)

```

 

### **3. galaxyLight**： https://github.com/moonufo/galaxyLight

```
目前事务处理的精华，太极分布式事务处理框架MOONWATER，采用可靠消息服务和重试、补偿处理机制，使用事件驱动、最终一致的事务模型，巧妙地运用数据库的事务处理能力，对服务操作结果进行判断，调用应用系统自身的事务处理功能，自动进行事务处理，从而有效地解决微服务的分布式事务处理问题。框架采用消息机制调用服务，速度快、灵活，通过使用缓存，解决服务调用的冥等性和消息的冥等性，在事务处理时，采用异步并行调用对应的服务，提高了性能。MOONWATER是一个非常优秀的框架，优势在于提高了应用的成功率，自动进行分布式事务处理，事务处理速度快，提高了数据的一致性，把对事务的处理由不可控变为可控，需要人工处理的故障可一键完成，简单快捷，实现事务处理的自动化，框架提供SDK…

```

 

参考地址：

- [Akka Persistence和Eventuate的对比](http://edisonxu.org/2017/01/22/akka-persistence-eventuate-comparison.html)
- [微服务下的数据一致性的几种实现方式之概述](https://www.jianshu.com/p/b264a196b177)
- [Akka Documentation](https://doc.akka.io/docs/akka/current/index.html)
- [Eventuate Document](https://rbmhtechnology.github.io/eventuate/index.html)
- [CQRS和Event Sourcing系列（二）：基本概念](http://edisonxu.org/2017/03/23/hello-cqrs.html)