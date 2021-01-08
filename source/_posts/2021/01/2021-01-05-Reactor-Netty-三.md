---
title: Reactor Netty(三)
author: HoldDie
img: s
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Netty
  - Reactor
date: 2021-01-05 10:13:16
password:
summary:
categories: Spring
---

# Reactor Netty Reference Guide

##  1. About the Documentation

本节简要概述了Reactor Netty参考文档。您无需线性阅读本指南。尽管每个零件经常引用其他零件，但它们各自独立。

### 1.1. Latest Version and Copyright Notice

Reactor Netty参考指南可作为HTML文档获得。最新的副本位于https://projectreactor.io/docs/netty/release/reference/index.html

本文档的副本可以供您自己使用，也可以分发给他人，但前提是您不对此类副本收取任何费用，并且还应确保每份副本均包含本版权声明（无论是印刷版本还是电子版本）。

### 1.2. Contributing to the Documentation

参考指南是用Asciidoc编写的，您可以在以下位置找到其参考资料 https://github.com/reactor/reactor-netty/tree/master/docs/asciidoc.

如果您有改进，我们将很高兴收到您的拉动请求！

我们建议您签出存储库的本地副本，以便可以通过使用asciidoctor Gradle任务并检查渲染来生成文档。有些部分依赖于包含的文件，因此GitHub渲染并不总是完整的。

### 1.3. Getting Help

有几种方法可以联系Reactor Netty寻求帮助。您可以：

- 与社区保持联系 [Gitter](https://gitter.im/reactor/reactor-netty).
- 在react-netty上的stackoverflow.com上提问。
- 报告Github问题中的错误。存储库如下：[reactor-netty](https://github.com/reactor/reactor-netty/issues)。

## 2. Getting Started

本节包含的信息应有助于您使用Reactor Netty。它包含以下信息：

- [Introducing Reactor Netty](https://projectreactor.io/docs/netty/release/reference/index.html#getting-started-introducing-reactor-netty)
- [Prerequisites](https://projectreactor.io/docs/netty/release/reference/index.html#prerequisites)
- [Understanding the BOM and versioning scheme](https://projectreactor.io/docs/netty/release/reference/index.html#getting-started-understanding-bom)
- [Getting Reactor Netty](https://projectreactor.io/docs/netty/release/reference/index.html#getting)

### 2.1. Introducing Reactor Netty

适用于微服务架构，Reactor Netty为HTTP（包括Websockets），TCP和UDP提供了支持背压的网络引擎。

### 2.2. Prerequisites

Reactor Netty在Java 8及更高版本上运行。

它具有以下传递依赖项：

- Reactive Streams v1.0.3
- Reactor Core v3.x
- Netty v4.1.x

### 2.3. 了解BOM和版本控制方案

Reactor Netty是Project Reactor BOM的一部分（因为铝释放链）。尽管这些工件中可能存在不同的版本控制方案，但该精选列表将旨在良好协作的工件分组，提供了相关版本。

工件遵循MAJOR.MINOR.PATCH-QUALIFIER的版本控制方案，而BOM使用受CalVer启发的YYYY.MINOR.PATCH-QUALIFIER的方案进行版本控制，其中：

- MAJOR是当前的Reactor一代，每个新一代的Reactor都可以对项目结构带来根本性的改变（这可能意味着需要进行更大的移植工作）
- YYYY是给定发行周期中首次发布GA的年份（如1.0.x的1.0.0）
- .MINOR是从0开始的数字，每个新发行周期递增
  - 就项目而言，它通常反映了更广泛的变化，并且可以表明进行了适度的迁移工作
  - 在BOM表的情况下，如果两个在同一年首次发布，则可以区分发布周期
- .PATCH是基于0的数字，随每个服务版本递增
- -QUALIFIER是文本限定符，在GA版本中会省略（请参见下文）

因此，遵循该约定的第一个发行周期是2020.0.x，代号Europium。该方案按顺序使用以下限定符（注意使用破折号）：

- `-M1`..`-M9`: 里程碑（我们预计每个服务版本不会超过9个）
- `-RC1`..`-RC9`: 候选版本（我们预计每个服务版本不会超过9个）
- `-SNAPSHOT`: 快照
- *对于GA版本没有限定符*

每个发布周期都被赋予一个代号，与以前的基于代号的方案相一致，可用于更非正式地引用它（例如在讨论，博客文章等中）。代号代表传统上的MAJOR.MINOR号。它们（大多数）来自元素周期表，按字母顺序递增。

### 2.4. Getting Reactor Netty

如前所述，在核心中使用Reactor Netty的最简单方法是使用BOM，并将相关的依赖项添加到项目中。请注意，添加此类依赖项时，必须省略版本，以便从BOM表中提取该版本。

但是，如果您要强制使用特定工件的版本，则可以像通常那样在添加依赖项时指定它。您也可以完全放弃BOM表，并通过工件版本指定依赖关系。

#### 2.4.1. Maven Installation

BOM概念由Maven原生支持。首先，您需要通过将以下代码段添加到pom.xml来导入BOM。如果您的pom中已经存在顶部（dependencyManagement），则仅添加内容。

```xml
<dependencyManagement> 
    <dependencies>
        <dependency>
            <groupId>io.projectreactor</groupId>
            <artifactId>reactor-bom</artifactId>
            <version>Dysprosium-SR10</version> 
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

接下来，照常将依赖项添加到相关的reactor项目中（不用使用`<version>`）。以下清单显示了如何执行此操作：

```xml
<dependencies>
    <dependency>
        <groupId>io.projectreactor.netty</groupId>
        <artifactId>reactor-netty-core</artifactId> 
    </dependency>
</dependencies>
<dependencies>
    <dependency>
        <groupId>io.projectreactor.netty</groupId>
        <artifactId>reactor-netty-http</artifactId>
    </dependency>
</dependencies>
```

#### 2.4.2. Gradle Installation

从版本5开始，Gradle支持BOM表概念。以下清单显示了如何导入BOM表并向Reactor Netty添加依赖项：

```groovy
dependencies {
    // import a BOM
    implementation platform('io.projectreactor:reactor-bom:Dysprosium-SR10') 

    // define dependencies without versions
    implementation 'io.projectreactor.netty:reactor-netty-core' 
    implementation 'io.projectreactor.netty:reactor-netty-http'
}
```

#### 2.4.3. Milestones and Snapshots

里程碑和开发人员预览是通过Spring Milestones存储库而不是Maven Central分发的。要将其添加到您的构建配置文件中，请使用以下代码段：

```xml
<repositories>
	<repository>
		<id>spring-milestones</id>
		<name>Spring Milestones Repository</name>
		<url>https://repo.spring.io/milestone</url>
	</repository>
</repositories>
```

对于Gradle，请使用以下代码段：

```groovy
repositories {
  maven { url 'https://repo.spring.io/milestone' }
  mavenCentral()
}
```

同样，快照也可在单独的专用存储库中使用（适用于Maven和Gradle）：

-SNAPSHOTs in Maven

```xml
<repositories>
	<repository>
		<id>spring-snapshots</id>
		<name>Spring Snapshot Repository</name>
		<url>https://repo.spring.io/snapshot</url>
	</repository>
</repositories>
```

-SNAPSHOTs in Gradle

```groovy
repositories {
  maven { url 'https://repo.spring.io/snapshot' }
  mavenCentral()
}
```

## 3. TCP Server

Reactor Netty提供了易于使用和配置的TcpServer。它隐藏了创建TCP服务器所需的大多数Netty功能，并增加了Reactive Streams背压。

### 3.1. Starting and Stopping

要启动TCP服务器，必须创建并配置TcpServer实例。默认情况下，主机配置为使用任何本地地址，并且在调用绑定操作时，系统会选择一个临时端口。以下示例显示如何创建和配置TcpServer实例：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/create/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()   
				         .bindNow(); 

		server.onDispose()
		      .block();
	}
}
```

返回的DisposableServer提供了一个简单的服务器API，包括disposeNow（），它以阻塞方式关闭服务器。

#### 3.1.1. Host and Port

要在特定的主机和端口上提供服务，可以将以下配置应用于TCP服务器：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/address/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()
				         .host("localhost") 
				         .port(8080)        
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 3.2. Writing Data

为了将数据发送到连接的客户端，必须附加一个I / O处理程序。 I / O处理程序有权访问NettyOutbound以便写入数据。以下示例显示了如何附加I / O处理程序：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/send/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()
				         .handle((inbound, outbound) -> outbound.sendString(Mono.just("hello"))) 
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 3.3. Consuming Data

为了从连接的客户端接收数据，必须附加I / O处理程序。 I / O处理程序可以访问NettyInbound以便读取数据。以下示例显示了如何使用它：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/read/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()
				         .handle((inbound, outbound) -> inbound.receive().then()) 
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 3.4. Lifecycle Callbacks

提供以下生命周期回调，以便您扩展TCP服务器：

- `doOnBind`:当服务器通道即将绑定时调用。
- `doOnBound`: 绑定服务器通道时调用。
- `doOnConnection`: 连接远程客户端时调用
- `doOnUnbound`: 服务器通道未绑定时调用。

以下示例使用doOnConnection回调：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/lifecycle/Application.java

```java
import io.netty.handler.timeout.ReadTimeoutHandler;
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;
import java.util.concurrent.TimeUnit;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()
				         .doOnConnection(conn ->
				             conn.addHandler(new ReadTimeoutHandler(10, TimeUnit.SECONDS))) 
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 3.5. TCP-level Configurations

本节描述了可以在TCP级别上使用的三种配置：

- [Setting Channel Options](https://projectreactor.io/docs/netty/release/reference/index.html#server-tcp-level-configurations-channel-options)
- [Using a Wire Logger](https://projectreactor.io/docs/netty/release/reference/index.html#server-tcp-level-configurations-event-wire-logger)
- [Using an Event Loop Group](https://projectreactor.io/docs/netty/release/reference/index.html#server-tcp-level-configurations-event-loop-group)

#### 3.5.1. Setting Channel Options

默认情况下，TCP服务器配置有以下选项：

./../../reactor-netty-core/src/main/java/reactor/netty/tcp/TcpServerBind.java

```java
TcpServerBind() {
	Map<ChannelOption<?>, Boolean> childOptions = new HashMap<>(2);
	childOptions.put(ChannelOption.AUTO_READ, false);
	childOptions.put(ChannelOption.TCP_NODELAY, true);
	this.config = new TcpServerConfig(
			Collections.singletonMap(ChannelOption.SO_REUSEADDR, true),
			childOptions,
			() -> new InetSocketAddress(DEFAULT_PORT));
}
```

如果需要其他选项，或者需要更改当前选项，则可以应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/channeloptions/Application.java

```java
import io.netty.channel.ChannelOption;
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()
				         .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000)
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

您可以在以下链接中找到有关Netty频道选项的更多信息：

- [`ChannelOption`](https://netty.io/4.1/api/io/netty/channel/ChannelOption.html)
- [Socket Options](https://docs.oracle.com/javase/8/docs/technotes/guides/net/socketOpt.html)

#### 3.5.2. Using a Wire Logger

当需要检查对等点之间的流量时，Reactor Netty提供有线记录。默认情况下，禁用有线日志记录。要启用它，必须将logger的react.netty.tcp.TcpServer级别设置为DEBUG并应用以下配置；

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/wiretap/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()
				         .wiretap(true) 
				         .bindNow();

		server.onDispose()
		      .block();
	}
```

#### 3.5.3. Using an Event Loop Group

默认情况下，TCP服务器使用“事件循环组”，其中工作线程数等于初始化时可用于运行时的处理器数（但最小值为4）。需要其他配置时，可以使用LoopResource＃create方法之一。

事件循环组的默认配置如下：

./../../reactor-netty-core/src/main/java/reactor/netty/ReactorNetty.java

```java
/**
 * Default worker thread count, fallback to available processor
 * (but with a minimum value of 4)
 */
public static final String IO_WORKER_COUNT = "reactor.netty.ioWorkerCount";
/**
 * Default selector thread count, fallback to -1 (no selector thread)
 */
public static final String IO_SELECT_COUNT = "reactor.netty.ioSelectCount";
/**
 * Default worker thread count for UDP, fallback to available processor
 * (but with a minimum value of 4)
 */
public static final String UDP_IO_THREAD_COUNT = "reactor.netty.udp.ioThreadCount";
/**
 * Default quiet period that guarantees that the disposal of the underlying LoopResources
 * will not happen, fallback to 2 seconds.
 */
public static final String SHUTDOWN_QUIET_PERIOD = "reactor.netty.ioShutdownQuietPeriod";
/**
 * Default maximum amount of time to wait until the disposal of the underlying LoopResources
 * regardless if a task was submitted during the quiet period, fallback to 15 seconds.
 */
public static final String SHUTDOWN_TIMEOUT = "reactor.netty.ioShutdownTimeout";

/**
 * Default value whether the native transport (epoll, kqueue) will be preferred,
 * fallback it will be preferred when available
 */
```

如果需要更改这些设置，则可以应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/eventloop/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.resources.LoopResources;
import reactor.netty.tcp.TcpServer;

public class Application {

	public static void main(String[] args) {
		LoopResources loop = LoopResources.create("event-loop", 1, 4, true);

		DisposableServer server =
				TcpServer.create()
				         .runOn(loop)
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 3.6. SSL and TLS

当需要SSL或TLS时，可以应用下清单中显示的配置。默认情况下，如果OpenSSL可用，则将SslProvider.OPENSSL提供程序用作提供程序。否则，将使用SslProvider.JDK。可以通过SslContextBuilder或通过设置-Dio.netty.handler.ssl.noOpenSsl = true来切换提供程序。

以下示例使用SslContextBuilder：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/security/Application.java

```java
import io.netty.handler.ssl.SslContextBuilder;
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;
import java.io.File;

public class Application {

	public static void main(String[] args) {
		File cert = new File("certificate.crt");
		File key = new File("private.key");

		SslContextBuilder sslContextBuilder = SslContextBuilder.forServer(cert, key);

		DisposableServer server =
				TcpServer.create()
				         .secure(spec -> spec.sslContext(sslContextBuilder))
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

#### 3.6.1. Server Name Indication

您可以配置具有映射到特定域的多个SslContext的TCP服务器。配置SNI映射时，可以使用确切的域名或包含通配符的域名。

以下示例使用包含通配符的域名：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/sni/Application.java

```java
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslContextBuilder;
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;

import java.io.File;

public class Application {

	public static void main(String[] args) throws Exception {
		File defaultCert = new File("default_certificate.crt");
		File defaultKey = new File("default_private.key");

		File testDomainCert = new File("default_certificate.crt");
		File testDomainKey = new File("default_private.key");

		SslContext defaultSslContext = SslContextBuilder.forServer(defaultCert, defaultKey).build();
		SslContext testDomainSslContext = SslContextBuilder.forServer(testDomainCert, testDomainKey).build();

		DisposableServer server =
				TcpServer.create()
				         .secure(spec -> spec.sslContext(defaultSslContext)
				                             .addSniMapping("*.test.com",
				                                     testDomainSpec -> testDomainSpec.sslContext(testDomainSslContext)))
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 3.7. Metrics

TCP服务器支持与Micrometer的内置集成。它使用前缀Reactor.netty.tcp.server公开所有度量。

下表提供了有关TCP服务器指标的信息：

| metric name                                 | type                | description                  |
| :------------------------------------------ | :------------------ | :--------------------------- |
| reactor.netty.tcp.server.data.received      | DistributionSummary | 接收到的数据量，以字节为单位 |
| reactor.netty.tcp.server.data.sent          | DistributionSummary | 发送的数据量（以字节为单位） |
| reactor.netty.tcp.server.errors             | Counter             | 发生的错误数                 |
| reactor.netty.tcp.server.tls.handshake.time | Timer               | TLS握手花费的时间            |

这些其他指标也可用：

`ByteBufAllocator` metrics

| metric name                                             | type  | description                                                  |
| :------------------------------------------------------ | :---- | :----------------------------------------------------------- |
| reactor.netty.bytebuf.allocator.used.heap.memory        | Gauge | 堆内存的字节数                                               |
| reactor.netty.bytebuf.allocator.used.direct.memory      | Gauge | 直接存储器的字节数                                           |
| reactor.netty.bytebuf.allocator.used.heap.arenas        | Gauge | The number of heap arenas (when `PooledByteBufAllocator`)    |
| reactor.netty.bytebuf.allocator.used.direct.arenas      | Gauge | The number of direct arenas (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.threadlocal.caches | Gauge | The number of thread local caches (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.tiny.cache.size    | Gauge | The size of the tiny cache (when `PooledByteBufAllocator`)   |
| reactor.netty.bytebuf.allocator.used.small.cache.size   | Gauge | The size of the small cache (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.normal.cache.size  | Gauge | The size of the normal cache (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.chunk.size         | Gauge | The chunk size for an arena (when `PooledByteBufAllocator`)  |

以下示例启用了该集成：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/metrics/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()
				         .metrics(true) 
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

当与非Micrometer的系统集成时需要TCP服务器度量标准，或者要与Micrometer集成时，可以提供自己的度量记录器，如下所示：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/metrics/custom/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.channel.ChannelMetricsRecorder;
import reactor.netty.tcp.TcpServer;

import java.net.SocketAddress;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()
				         .metrics(true, CustomChannelMetricsRecorder::new) 
				         .bindNow();

		server.onDispose()
		      .block();
	}
```

### 3.8. Unix Domain Sockets

使用本地传输时，TCP服务器支持Unix域套接字（UDS）。

以下示例显示了如何使用UDS支持：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/server/uds/Application.java

```java
import io.netty.channel.unix.DomainSocketAddress;
import reactor.netty.DisposableServer;
import reactor.netty.tcp.TcpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				TcpServer.create()
				         .bindAddress(() -> new DomainSocketAddress("/tmp/test.sock")) 
				         .bindNow();

		server.onDispose()
		      .block();
	}
}
```

## 4. TCP Client

Reactor Netty提供了易于使用和易于配置的TcpClient。它隐藏了创建TCP客户端所需的大多数Netty功能，并增加了Reactive Streams背压。

### 4.1. Connect and Disconnect

要将TCP客户端连接到给定的端点，必须创建并配置TcpClient实例。默认情况下，主机是localhost，端口是12012。以下示例显示如何创建TcpClient：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/create/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()      
				         .connectNow(); 

		connection.onDispose()
		          .block();
	}
}
```

返回的Connection提供了一个简单的连接API，包括disposeNow（），该API以阻塞的方式关闭了客户端。

#### 4.1.1. Host and Port

要连接到特定的主机和端口，可以将以下配置应用于TCP客户端。以下示例显示了如何执行此操作：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/address/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .host("example.com") 
				         .port(80)            
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

### 4.2. Writing Data

要将数据发送到给定的端点，必须附加一个I / O处理程序。 I / O处理程序有权访问NettyOutbound以便写入数据。

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/send/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .host("example.com")
				         .port(80)
				         .handle((inbound, outbound) -> outbound.sendString(Mono.just("hello"))) 
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

### 4.3. Consuming Data

要从给定的端点接收数据，必须附加一个I / O处理程序。 I / O处理程序可以访问NettyInbound以便读取数据。以下示例显示了如何执行此操作：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/read/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .host("example.com")
				         .port(80)
				         .handle((inbound, outbound) -> inbound.receive().then()) 
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

### 4.4. Lifecycle Callbacks

提供以下生命周期回调，以便您扩展TCP客户端。

- `doOnConnect`: 在通道即将连接时调用。
- `doOnConnected`: 连接通道后调用。
- `doOnDisconnected`: 断开通道后，调用此按钮。

以下示例使用doOnConnected回调：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/lifecycle/Application.java

```java
import io.netty.handler.timeout.ReadTimeoutHandler;
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;
import java.util.concurrent.TimeUnit;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .host("example.com")
				         .port(80)
				         .doOnConnected(conn ->
				             conn.addHandler(new ReadTimeoutHandler(10, TimeUnit.SECONDS))) 
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

### 4.5. TCP-level Configurations

本节描述了可以在TCP级别上使用的三种配置：

- [Channel Options](https://projectreactor.io/docs/netty/release/reference/index.html#client-tcp-level-configurations-channel-options)
- [Wire Logger](https://projectreactor.io/docs/netty/release/reference/index.html#client-tcp-level-configurations-event-wire-logger)
- [Event Loop Group](https://projectreactor.io/docs/netty/release/reference/index.html#client-tcp-level-configurations-event-loop-group)

#### 4.5.1. Channel Options

默认情况下，TCP客户端配置有以下选项：

./../../reactor-netty-core/src/main/java/reactor/netty/tcp/TcpClientConnect.java

```java
TcpClientConnect(ConnectionProvider provider) {
	this.config = new TcpClientConfig(
			provider,
			Collections.singletonMap(ChannelOption.AUTO_READ, false),
			() -> AddressUtils.createUnresolved(NetUtil.LOCALHOST.getHostAddress(), DEFAULT_PORT));
}
```

如果需要其他选项，或者需要更改当前选项，则可以应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/channeloptions/Application.java

```java
import io.netty.channel.ChannelOption;
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .host("example.com")
				         .port(80)
				         .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000)
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

您可以在以下链接中找到有关Netty频道选项的更多信息：

- [`ChannelOption`](https://netty.io/4.1/api/io/netty/channel/ChannelOption.html)
- [Socket Options](https://docs.oracle.com/javase/8/docs/technotes/guides/net/socketOpt.html)

#### 4.5.2. Wire Logger

当需要检查对等点之间的流量时，Reactor Netty提供有线记录。默认情况下，禁用有线日志记录。要启用它，必须将记录器react.netty.tcp.TcpClient级别设置为DEBUG并应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/wiretap/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .wiretap(true) 
				         .host("example.com")
				         .port(80)
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

#### 4.5.3. Event Loop Group

默认情况下，TCP客户端使用“事件循环组”，其中工作线程数等于初始化时可用于运行时的处理器数（但最小值为4）。需要其他配置时，可以使用LoopResource＃create方法之一。

以下清单显示了事件循环组的默认配置：

./../../reactor-netty-core/src/main/java/reactor/netty/ReactorNetty.java

```java
/**
 * Default worker thread count, fallback to available processor
 * (but with a minimum value of 4)
 */
public static final String IO_WORKER_COUNT = "reactor.netty.ioWorkerCount";
/**
 * Default selector thread count, fallback to -1 (no selector thread)
 */
public static final String IO_SELECT_COUNT = "reactor.netty.ioSelectCount";
/**
 * Default worker thread count for UDP, fallback to available processor
 * (but with a minimum value of 4)
 */
public static final String UDP_IO_THREAD_COUNT = "reactor.netty.udp.ioThreadCount";
/**
 * Default quiet period that guarantees that the disposal of the underlying LoopResources
 * will not happen, fallback to 2 seconds.
 */
public static final String SHUTDOWN_QUIET_PERIOD = "reactor.netty.ioShutdownQuietPeriod";
/**
 * Default maximum amount of time to wait until the disposal of the underlying LoopResources
 * regardless if a task was submitted during the quiet period, fallback to 15 seconds.
 */
public static final String SHUTDOWN_TIMEOUT = "reactor.netty.ioShutdownTimeout";

/**
 * Default value whether the native transport (epoll, kqueue) will be preferred,
 * fallback it will be preferred when available
 */
```

如果需要更改这些设置，则可以应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/eventloop/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.resources.LoopResources;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		LoopResources loop = LoopResources.create("event-loop", 1, 4, true);

		Connection connection =
				TcpClient.create()
				         .host("example.com")
				         .port(80)
				         .runOn(loop)
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

### 4.6. Connection Pool

默认情况下，TCP客户端使用“固定”连接池，其中最大通道数为500，最大注册请求数为1000，以保留在挂起队列中（对于其余配置，请检查系统属性下面）。这意味着如果有人尝试获取频道但池中没有频道，则实现会创建一个新频道。当达到池中通道的最大数目时，新的获取通道的尝试将延迟，直到再次将通道返回到池中为止。

./../../reactor-netty-core/src/main/java/reactor/netty/ReactorNetty.java

```java
/**
 * Default max connections. Fallback to
 * available number of processors (but with a minimum value of 16)
 */
public static final String POOL_MAX_CONNECTIONS = "reactor.netty.pool.maxConnections";
/**
 * Default acquisition timeout (milliseconds) before error. If -1 will never wait to
 * acquire before opening a new
 * connection in an unbounded fashion. Fallback 45 seconds
 */
public static final String POOL_ACQUIRE_TIMEOUT = "reactor.netty.pool.acquireTimeout";
/**
 * Default max idle time, fallback - max idle time is not specified.
 */
public static final String POOL_MAX_IDLE_TIME = "reactor.netty.pool.maxIdleTime";
/**
 * Default max life time, fallback - max life time is not specified.
 */
public static final String POOL_MAX_LIFE_TIME = "reactor.netty.pool.maxLifeTime";
/**
 * Default leasing strategy (fifo, lifo), fallback to fifo.
 * <ul>
 *     <li>fifo - The connection selection is first in, first out</li>
 *     <li>lifo - The connection selection is last in, first out</li>
 * </ul>
 */
```

如果需要禁用连接池，则可以应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/pool/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.newConnection()
				         .host("example.com")
				         .port(80)
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

如果需要为连接池中的通道指定空闲时间，则可以应用以下配置

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/pool/config/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.resources.ConnectionProvider;
import reactor.netty.tcp.TcpClient;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		ConnectionProvider provider =
				ConnectionProvider.builder("fixed")
				                  .maxConnections(50)
				                  .pendingAcquireTimeout(Duration.ofMillis(30000))
				                  .maxIdleTime(Duration.ofMillis(60))
				                  .build();

		Connection connection =
				TcpClient.create(provider)
				         .host("example.com")
				         .port(80)
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

#### 4.6.1. Metrics

池中的ConnectionProvider支持与Micrometer的内置集成。它使用前缀react.netty.connection.provider公开所有度量。

Pooled `ConnectionProvider` metrics

| metric name                                           | type  | description                                                  |
| :---------------------------------------------------- | :---- | :----------------------------------------------------------- |
| reactor.netty.connection.provider.total.connections   | Gauge | The number of all connections, active or idle                |
| reactor.netty.connection.provider.active.connections  | Gauge | The number of the connections that have been successfully acquired and are in active use |
| reactor.netty.connection.provider.idle.connections    | Gauge | The number of the idle connections                           |
| reactor.netty.connection.provider.pending.connections | Gauge | The number of requests that are waiting for a connection     |

以下示例启用了该集成：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/pool/metrics/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.resources.ConnectionProvider;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		ConnectionProvider provider =
				ConnectionProvider.builder("fixed")
				                  .maxConnections(50)
				                  .metrics(true) 
				                  .build();

		Connection connection =
				TcpClient.create(provider)
				         .host("example.com")
				         .port(80)
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

### 4.7. SSL and TLS

当需要SSL或TLS时，可以应用以下配置。默认情况下，如果OpenSSL可用，则将SslProvider.OPENSSL提供程序用作提供程序。否则，提供程序为SslProvider.JDK。您可以通过使用SslContextBuilder或通过设置-Dio.netty.handler.ssl.noOpenSsl = true来切换提供程序。

以下示例使用SslContextBuilder：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/security/Application.java

```java
import io.netty.handler.ssl.SslContextBuilder;
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		SslContextBuilder sslContextBuilder = SslContextBuilder.forClient();

		Connection connection =
				TcpClient.create()
				         .host("example.com")
				         .port(443)
				         .secure(spec -> spec.sslContext(sslContextBuilder))
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

#### 4.7.1. Server Name Indication

默认情况下，TCP客户端将远程主机名作为SNI服务器名发送。当需要更改此默认设置时，可以按以下方式配置TCP客户端：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/sni/Application.java

```java
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslContextBuilder;
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

import javax.net.ssl.SNIHostName;

public class Application {

	public static void main(String[] args) throws Exception {
		SslContext sslContext = SslContextBuilder.forClient().build();

		Connection connection =
				TcpClient.create()
				         .host("127.0.0.1")
				         .port(8080)
				         .secure(spec -> spec.sslContext(sslContext)
				                             .serverNames(new SNIHostName("test.com")))
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

### 4.8. Proxy Support

TCP客户端支持Netty提供的代理功能，并提供了一种通过ProxyProvider构建器指定“非代理主机”的方法。以下示例使用ProxyProvider：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/proxy/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.transport.ProxyProvider;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .host("example.com")
				         .port(80)
				         .proxy(spec -> spec.type(ProxyProvider.Proxy.SOCKS4)
				                            .host("proxy")
				                            .port(8080)
				                            .nonProxyHosts("localhost"))
				        .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

### 4.9. Metrics

TCP客户端支持与Micrometer的内置集成。它使用前缀react.netty.tcp.client公开所有度量。

下表提供了有关TCP客户端指标的信息：

| metric name                                 | type                | description                                     |
| :------------------------------------------ | :------------------ | :---------------------------------------------- |
| reactor.netty.tcp.client.data.received      | DistributionSummary | Amount of the data received, in bytes           |
| reactor.netty.tcp.client.data.sent          | DistributionSummary | Amount of the data sent, in bytes               |
| reactor.netty.tcp.client.errors             | Counter             | Number of errors that occurred                  |
| reactor.netty.tcp.client.tls.handshake.time | Timer               | Time spent for TLS handshake                    |
| reactor.netty.tcp.client.connect.time       | Timer               | Time spent for connecting to the remote address |
| reactor.netty.tcp.client.address.resolver   | Timer               | Time spent for resolving the address            |

这些其他指标也可用：

Pooled `ConnectionProvider` metrics

| metric name                                           | type  | description                                                  |
| :---------------------------------------------------- | :---- | :----------------------------------------------------------- |
| reactor.netty.connection.provider.total.connections   | Gauge | The number of all connections, active or idle                |
| reactor.netty.connection.provider.active.connections  | Gauge | The number of the connections that have been successfully acquired and are in active use |
| reactor.netty.connection.provider.idle.connections    | Gauge | The number of the idle connections                           |
| reactor.netty.connection.provider.pending.connections | Gauge | The number of requests that are waiting for a connection     |

`ByteBufAllocator` metrics

| metric name                                             | type  | description                                                  |
| :------------------------------------------------------ | :---- | :----------------------------------------------------------- |
| reactor.netty.bytebuf.allocator.used.heap.memory        | Gauge | The number of the bytes of the heap memory                   |
| reactor.netty.bytebuf.allocator.used.direct.memory      | Gauge | The number of the bytes of the direct memory                 |
| reactor.netty.bytebuf.allocator.used.heap.arenas        | Gauge | The number of heap arenas (when `PooledByteBufAllocator`)    |
| reactor.netty.bytebuf.allocator.used.direct.arenas      | Gauge | The number of direct arenas (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.threadlocal.caches | Gauge | The number of thread local caches (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.tiny.cache.size    | Gauge | The size of the tiny cache (when `PooledByteBufAllocator`)   |
| reactor.netty.bytebuf.allocator.used.small.cache.size   | Gauge | The size of the small cache (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.normal.cache.size  | Gauge | The size of the normal cache (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.chunk.size         | Gauge | The chunk size for an arena (when `PooledByteBufAllocator`)  |

以下示例启用了该集成：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/metrics/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .host("example.com")
				         .port(80)
				         .metrics(true) 
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

当需要TCP客户端度量标准来与Micrometer以外的系统集成时，或者您想要提供自己与Micrometer的集成时，可以提供自己的度量记录器，如下所示：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/metrics/custom/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.channel.ChannelMetricsRecorder;
import reactor.netty.tcp.TcpClient;

import java.net.SocketAddress;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .host("example.com")
				         .port(80)
				         .metrics(true, CustomChannelMetricsRecorder::new) 
				         .connectNow();

		connection.onDispose()
		          .block();
	}
```

|      | Enables TCP client metrics and provides [`ChannelMetricsRecorder`](https://projectreactor.io/docs/netty/release/api/reactor/netty/channel/ChannelMetricsRecorder.html) implementation. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

### 4.10. Unix Domain Sockets

使用本地传输时，TCP客户端支持Unix域套接字（UDS）。

以下示例显示了如何使用UDS支持：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/tcp/client/uds/Application.java

```java
import io.netty.channel.unix.DomainSocketAddress;
import reactor.netty.Connection;
import reactor.netty.tcp.TcpClient;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				TcpClient.create()
				         .remoteAddress(() -> new DomainSocketAddress("/tmp/test.sock")) 
				         .connectNow();

		connection.onDispose()
		          .block();
	}
}
```

## 5. HTTP Server

Reactor Netty提供了易于使用和易于配置的HttpServer类。它隐藏了创建HTTP服务器所需的大多数Netty功能，并增加了Reactive Streams背压。

### 5.1. Starting and Stopping

要启动HTTP服务器，您必须创建并配置HttpServer实例。默认情况下，主机配置为使用任何本地地址，并且在调用绑定操作时，系统会选择一个临时端口。以下示例显示如何创建HttpServer实例：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/create/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()   
				          .bindNow(); 

		server.onDispose()
		      .block();
	}
}
```

返回的DisposableServer提供了一个简单的服务器API，包括disposeNow（），它以阻塞方式关闭服务器。

#### 5.1.1. Host and Port

要在特定的主机和端口上提供服务，可以将以下配置应用于HTTP服务器：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/address/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .host("localhost") 
				          .port(8080)        
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 5.2. Routing HTTP

定义HTTP服务器的路由需要配置提供的HttpServerRoutes构建器。以下示例显示了如何执行此操作：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/routing/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .route(routes ->
				              routes.get("/hello",        
				                        (request, response) -> response.sendString(Mono.just("Hello World!")))
				                    .post("/echo",        
				                        (request, response) -> response.send(request.receive().retain()))
				                    .get("/path/{param}", 
				                        (request, response) -> response.sendString(Mono.just(request.param("param"))))
				                    .ws("/ws",            
				                        (wsInbound, wsOutbound) -> wsOutbound.send(wsInbound.receive().retain())))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

#### 5.2.1. SSE

以下代码显示了如何配置HTTP服务器以服务于服务器发送的事件：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/sse/Application.java

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.ByteBufAllocator;
import org.reactivestreams.Publisher;
import reactor.core.publisher.Flux;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;
import reactor.netty.http.server.HttpServerRequest;
import reactor.netty.http.server.HttpServerResponse;

import java.io.ByteArrayOutputStream;
import java.nio.charset.Charset;
import java.time.Duration;
import java.util.function.BiFunction;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .route(routes -> routes.get("/sse", serveSse()))
				          .bindNow();

		server.onDispose()
		      .block();
	}

	/**
	 * Prepares SSE response
	 * The "Content-Type" is "text/event-stream"
	 * The flushing strategy is "flush after every element" emitted by the provided Publisher
	 */
	private static BiFunction<HttpServerRequest, HttpServerResponse, Publisher<Void>> serveSse() {
		Flux<Long> flux = Flux.interval(Duration.ofSeconds(10));
		return (request, response) ->
		        response.sse()
		                .send(flux.map(Application::toByteBuf), b -> true);
	}

	/**
	 * Transforms the Object to ByteBuf following the expected SSE format.
	 */
	private static ByteBuf toByteBuf(Object any) {
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		try {
			out.write("data: ".getBytes(Charset.defaultCharset()));
			MAPPER.writeValue(out, any);
			out.write("\n\n".getBytes(Charset.defaultCharset()));
		}
		catch (Exception e) {
			throw new RuntimeException(e);
		}
		return ByteBufAllocator.DEFAULT
		                       .buffer()
		                       .writeBytes(out.toByteArray());
	}

	private static final ObjectMapper MAPPER = new ObjectMapper();
}
```

#### 5.2.2. Static Resources

以下代码显示了如何配置HTTP服务器以提供静态资源：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/staticresources/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;

public class Application {

	public static void main(String[] args) throws URISyntaxException {
		Path file = Paths.get(Application.class.getResource("/logback.xml").toURI());
		DisposableServer server =
				HttpServer.create()
				          .route(routes -> routes.file("/index.html", file))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 5.3. Writing Data

要将数据发送到已连接的客户端，必须使用handle（...）或route（...）附加I / O处理程序。 I / O处理程序有权访问HttpServerResponse，以便能够写入数据。以下示例使用handle（…）方法：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/send/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .handle((request, response) -> response.sendString(Mono.just("hello"))) 
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

#### 5.3.1. Adding Headers and Other Metadata

将数据发送到连接的客户端时，可能需要发送其他标头，cookie，状态代码和其他元数据。您可以使用HttpServerResponse提供此附加元数据。以下示例显示了如何执行此操作：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/send/headers/Application.java

```java
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpResponseStatus;
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .route(routes ->
				              routes.get("/hello",
				                  (request, response) ->
				                      response.status(HttpResponseStatus.OK)
				                              .header(HttpHeaderNames.CONTENT_LENGTH, "12")
				                              .sendString(Mono.just("Hello World!"))))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

#### 5.3.2. Compression

您可以配置HTTP服务器以发送压缩的响应，具体取决于请求标头Accept-Encoding。

Reactor Netty提供了三种用于压缩传出数据的策略：

- compress（boolean）：根据提供的布尔值，启用压缩（true）还是禁用压缩（false）。
- compress（int）：一旦响应大小超过给定值（以字节为单位），就执行压缩。
- compress（BiPredicate ）：如果谓词返回true，则执行压缩。

以下示例使用compress方法（设置为true）启用压缩：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/compression/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;

public class Application {

	public static void main(String[] args) throws URISyntaxException {
		Path file = Paths.get(Application.class.getResource("/logback.xml").toURI());
		DisposableServer server =
				HttpServer.create()
				          .compress(true)
				          .route(routes -> routes.file("/index.html", file))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 5.4. Consuming Data

要从已连接的客户端接收数据，必须使用handle（...）或route（...）附加I / O处理程序。 I / O处理程序有权访问HttpServerRequest，以便能够读取数据。

以下示例使用handle（…）方法：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/read/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .handle((request, response) -> request.receive().then()) 
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

#### 5.4.1. Reading Headers, URI Params, and other Metadata

从连接的客户端接收数据时，可能需要检查请求标头，参数和其他元数据。您可以使用HttpServerRequest获得此其他元数据。以下示例显示了如何执行此操作：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/read/headers/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .route(routes ->
				              routes.get("/{param}",
				                  (request, response) -> {
				                      if (request.requestHeaders().contains("Some-Header")) {
				                          return response.sendString(Mono.just(request.param("param")));
				                      }
				                      return response.sendNotFound();
				                  }))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

##### Obtaining the Remote (Client) Address

除了可以从请求中获取的元数据之外，您还可以接收主机（服务器）地址，远程（客户端）地址和方案。根据选择的工厂方法，您可以直接从通道或使用Forwarded或X-Forwarded- * HTTP请求标头检索信息。以下示例显示了如何执行此操作：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/clientaddress/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .forwarded(true) 
				          .route(routes ->
				              routes.get("/clientip",
				                  (request, response) ->
				                      response.sendString(Mono.just(request.remoteAddress() 
				                                                           .getHostString()))))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

还可以自定义Forwarded或X-Forwarded- *标头处理程序的行为。以下示例显示了如何执行此操作：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/clientaddress/CustomForwardedHeaderHandlerApplication.java

```java
import java.net.InetSocketAddress;

import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;
import reactor.netty.transport.AddressUtils;

public class CustomForwardedHeaderHandlerApplication {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .forwarded((connectionInfo, request) -> {  
				              String hostHeader = request.headers().get("X-Forwarded-Host");
				              if (hostHeader != null) {
				                  String[] hosts = hostHeader.split(",", 2);
				                  InetSocketAddress hostAddress = AddressUtils.createUnresolved(
				                      hosts[hosts.length - 1].trim(),
				                      connectionInfo.getHostAddress().getPort());
				                  connectionInfo = connectionInfo.withHostAddress(hostAddress);
				              }
				              return connectionInfo;
				          })
				          .route(routes ->
				              routes.get("/clientip",
				                  (request, response) ->
				                      response.sendString(Mono.just(request.remoteAddress() 
				                                                           .getHostString()))))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

#### 5.4.2. HTTP Request Decoder

默认情况下，Netty为传入请求配置一些限制，例如：

- 初始行的最大长度。
- 请求头的最大长度。
- 内容或每个块的最大长度。

有关更多信息，请参见HttpRequestDecoder和HttpServerUpgradeHandler。

默认情况下，HTTP服务器配置有以下设置：

./../../reactor-netty-http/src/main/java/reactor/netty/http/HttpDecoderSpec.java

```java
public static final int DEFAULT_MAX_INITIAL_LINE_LENGTH = 4096;
public static final int DEFAULT_MAX_HEADER_SIZE         = 8192;
public static final int DEFAULT_MAX_CHUNK_SIZE          = 8192;
public static final boolean DEFAULT_VALIDATE_HEADERS    = true;
public static final int DEFAULT_INITIAL_BUFFER_SIZE     = 128;
```

./../../reactor-netty-http/src/main/java/reactor/netty/http/server/HttpRequestDecoderSpec.java

```java
/**
 * The maximum length of the content of the HTTP/2.0 clear-text upgrade request.
 * By default the server will reject an upgrade request with non-empty content,
 * because the upgrade request is most likely a GET request.
 */
public static final int DEFAULT_H2C_MAX_CONTENT_LENGTH = 0;
```

当需要更改这些默认设置时，可以按以下方式配置HTTP服务器：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/requestdecoder/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .httpRequestDecoder(spec -> spec.maxHeaderSize(16384)) 
				          .handle((request, response) -> response.sendString(Mono.just("hello")))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 5.5. TCP-level Configuration

当需要在TCP级别上更改配置时，可以使用以下代码段扩展默认的TCP服务器配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/channeloptions/Application.java

```java
import io.netty.channel.ChannelOption;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000)
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

有关TCP级别配置的更多详细信息，请参见TCP Server。

#### 5.5.1. Wire Logger

当您需要检查对等方之间的流量时，Reactor Netty提供了线路日志记录。默认情况下，禁用有线日志记录。要启用它，必须将记录器react.netty.http.server.HttpServer级别设置为DEBUG并应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/wiretap/Application.java

```java
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .wiretap(true) 
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 5.6. SSL and TLS

当需要SSL或TLS时，可以应用下一个示例中显示的配置。默认情况下，如果OpenSSL可用，则将SslProvider.OPENSSL提供程序用作提供程序。否则，将使用SslProvider.JDK。您可以通过使用SslContextBuilder或通过设置-Dio.netty.handler.ssl.noOpenSsl = true来切换提供程序。

以下示例使用SslContextBuilder：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/security/Application.java

```java
import io.netty.handler.ssl.SslContextBuilder;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;
import java.io.File;

public class Application {

	public static void main(String[] args) {
		File cert = new File("certificate.crt");
		File key = new File("private.key");

		SslContextBuilder sslContextBuilder = SslContextBuilder.forServer(cert, key);

		DisposableServer server =
				HttpServer.create()
				          .secure(spec -> spec.sslContext(sslContextBuilder))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

#### 5.6.1. Server Name Indication

您可以为HTTP服务器配置多个映射到特定域的SslContext。配置SNI映射时，可以使用确切的域名或包含通配符的域名。

以下示例使用包含通配符的域名：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/sni/Application.java

```java
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslContextBuilder;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

import java.io.File;

public class Application {

	public static void main(String[] args) throws Exception {
		File defaultCert = new File("default_certificate.crt");
		File defaultKey = new File("default_private.key");

		File testDomainCert = new File("default_certificate.crt");
		File testDomainKey = new File("default_private.key");

		SslContext defaultSslContext = SslContextBuilder.forServer(defaultCert, defaultKey).build();
		SslContext testDomainSslContext = SslContextBuilder.forServer(testDomainCert, testDomainKey).build();

		DisposableServer server =
				HttpServer.create()
				          .secure(spec -> spec.sslContext(defaultSslContext)
				                              .addSniMapping("*.test.com",
				                                      testDomainSpec -> testDomainSpec.sslContext(testDomainSslContext)))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

### 5.7. HTTP Access Log

当前的日志支持仅提供“通用日志格式”。

您可以使用-Dreactor.netty.http.server.accessLogEnabled = true启用HTTP访问日志。默认情况下，它是禁用的。

您可以使用以下配置（用于Logback或类似的日志记录框架）来拥有单独的HTTP访问日志文件：

```xml
<appender name="accessLog" class="ch.qos.logback.core.FileAppender">
    <file>access_log.log</file>
    <encoder>
        <pattern>%msg%n</pattern>
    </encoder>
</appender>
<appender name="async" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="accessLog" />
</appender>

<logger name="reactor.netty.http.server.AccessLog" level="INFO" additivity="false">
    <appender-ref ref="async"/>
</logger>
```

### 5.8. HTTP/2

默认情况下，HTTP服务器支持HTTP / 1.1。如果需要HTTP / 2，则可以通过配置获取它。除了协议配置之外，如果您需要H2而不是H2C（明文），则还必须配置SSL。

以下清单提供了一个简单的H2示例：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/http2/H2Application.java

```java
import io.netty.handler.ssl.SslContextBuilder;
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.HttpProtocol;
import reactor.netty.http.server.HttpServer;
import java.io.File;

public class H2Application {

	public static void main(String[] args) {
		File cert = new File("certificate.crt");
		File key = new File("private.key");

		SslContextBuilder sslContextBuilder = SslContextBuilder.forServer(cert, key);

		DisposableServer server =
				HttpServer.create()
				          .port(8080)
				          .protocol(HttpProtocol.H2)                          
				          .secure(spec -> spec.sslContext(sslContextBuilder)) 
				          .handle((request, response) -> response.sendString(Mono.just("hello")))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

现在，应用程序的行为应如下所示：

```bash
$ curl --http2 https://localhost:8080 -i
HTTP/2 200

hello
```

以下清单提供了一个简单的H2C示例：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/http2/H2CApplication.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.HttpProtocol;
import reactor.netty.http.server.HttpServer;

public class H2CApplication {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .port(8080)
				          .protocol(HttpProtocol.H2C)
				          .handle((request, response) -> response.sendString(Mono.just("hello")))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

现在，应用程序的行为应如下所示：

```bash
$ curl --http2-prior-knowledge http://localhost:8080 -i
HTTP/2 200

hello
```

#### 5.8.1. Protocol Selection

./../../reactor-netty-http/src/main/java/reactor/netty/http/HttpProtocol.java

```java
public enum HttpProtocol {

	/**
	 * The default supported HTTP protocol by HttpServer and HttpClient
	 */
	HTTP11,

	/**
	 * HTTP/2.0 support with TLS
	 * <p>If used along with HTTP/1.1 protocol, HTTP/2.0 will be the preferred protocol.
	 * While negotiating the application level protocol, HTTP/2.0 or HTTP/1.1 can be chosen.
	 * <p>If used without HTTP/1.1 protocol, HTTP/2.0 will always be offered as a protocol
	 * for communication with no fallback to HTTP/1.1.
	 */
	H2,

	/**
	 * HTTP/2.0 support with clear-text.
	 * <p>If used along with HTTP/1.1 protocol, will support H2C "upgrade":
	 * Request or consume requests as HTTP/1.1 first, looking for HTTP/2.0 headers
	 * and {@literal Connection: Upgrade}. A server will typically reply a successful
	 * 101 status if upgrade is successful or a fallback HTTP/1.1 response. When
	 * successful the client will start sending HTTP/2.0 traffic.
	 * <p>If used without HTTP/1.1 protocol, will support H2C "prior-knowledge": Doesn't
	 * require {@literal Connection: Upgrade} handshake between a client and server but
	 * fallback to HTTP/1.1 will not be supported.
	 */
	H2C
}
```

### 5.9. Metrics

HTTP服务器支持与Micrometer的内置集成。它使用前缀react..netty.http.server公开所有度量。

| metric name                                  | type                | description                           |
| :------------------------------------------- | :------------------ | :------------------------------------ |
| reactor.netty.http.server.data.received      | DistributionSummary | Amount of the data received, in bytes |
| reactor.netty.http.server.data.sent          | DistributionSummary | Amount of the data sent, in bytes     |
| reactor.netty.http.server.errors             | Counter             | Number of errors that occurred        |
| reactor.netty.http.server.data.received.time | Timer               | Time spent in consuming incoming data |
| reactor.netty.http.server.data.sent.time     | Timer               | Time spent in sending outgoing data   |
| reactor.netty.http.server.response.time      | Timer               | Total time for the request/response   |

These additional metrics are also available:

`ByteBufAllocator` metrics

| metric name                                             | type  | description                                                  |
| :------------------------------------------------------ | :---- | :----------------------------------------------------------- |
| reactor.netty.bytebuf.allocator.used.heap.memory        | Gauge | The number of the bytes of the heap memory                   |
| reactor.netty.bytebuf.allocator.used.direct.memory      | Gauge | The number of the bytes of the direct memory                 |
| reactor.netty.bytebuf.allocator.used.heap.arenas        | Gauge | The number of heap arenas (when `PooledByteBufAllocator`)    |
| reactor.netty.bytebuf.allocator.used.direct.arenas      | Gauge | The number of direct arenas (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.threadlocal.caches | Gauge | The number of thread local caches (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.tiny.cache.size    | Gauge | The size of the tiny cache (when `PooledByteBufAllocator`)   |
| reactor.netty.bytebuf.allocator.used.small.cache.size   | Gauge | The size of the small cache (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.normal.cache.size  | Gauge | The size of the normal cache (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.chunk.size         | Gauge | The chunk size for an arena (when `PooledByteBufAllocator`)  |

以下示例启用了该集成：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/metrics/Application.java

```java
import io.micrometer.core.instrument.Metrics;
import io.micrometer.core.instrument.config.MeterFilter;
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		Metrics.globalRegistry 
		       .config()
		       .meterFilter(MeterFilter.maximumAllowableTags("reactor.netty.http.server", "URI", 100, MeterFilter.deny()));

		DisposableServer server =
				HttpServer.create()
				          .metrics(true, s -> {
				              if (s.startsWith("/stream/")) { 
				                  return "/stream/{n}";
				              }
				              else if (s.startsWith("/bytes/")) {
				                  return "/bytes/{n}";
				              }
				              return s;
				          }) 
				          .route(r ->
				              r.get("/stream/{n}",
				                   (req, res) -> res.sendString(Mono.just(req.param("n"))))
				               .get("/bytes/{n}",
				                   (req, res) -> res.sendString(Mono.just(req.param("n")))))
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

当需要与Micrometer以外的系统集成时需要HTTP服务器指标，或者您想与Micrometer提供自己的集成时，可以提供自己的指标记录器，如下所示：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/metrics/custom/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.DisposableServer;
import reactor.netty.channel.ChannelMetricsRecorder;
import reactor.netty.http.server.HttpServer;

import java.net.SocketAddress;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .metrics(true, CustomHttpServerMetricsRecorder::new) 
				          .route(r ->
				              r.get("/stream/{n}",
				                   (req, res) -> res.sendString(Mono.just(req.param("n"))))
				               .get("/bytes/{n}",
				                   (req, res) -> res.sendString(Mono.just(req.param("n")))))
				          .bindNow();

		server.onDispose()
		      .block();
	}
```

### 5.10. Unix Domain Sockets

使用本机传输时，HTTP服务器支持Unix域套接字（UDS）。

以下示例显示了如何使用UDS支持：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/server/uds/Application.java

```java
import io.netty.channel.unix.DomainSocketAddress;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

public class Application {

	public static void main(String[] args) {
		DisposableServer server =
				HttpServer.create()
				          .bindAddress(() -> new DomainSocketAddress("/tmp/test.sock")) 
				          .bindNow();

		server.onDispose()
		      .block();
	}
}
```

## 6. HTTP Client

Reactor Netty提供了易于使用和易于配置的HttpClient。它隐藏了创建HTTP客户端所需的大多数Netty功能，并增加了Reactive Streams背压。

### 6.1. Connect

要将HTTP客户端连接到给定的HTTP端点，必须创建并配置HttpClient实例。以下示例显示了如何执行此操作：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/connect/Application.java

```java
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client = HttpClient.create();  

		client.get()                      
		      .uri("http://example.com/") 
		      .response()                 
		      .block();
	}
}
```

以下示例使用WebSocket：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/websocket/Application.java

```java
import io.netty.buffer.Unpooled;
import io.netty.util.CharsetUtil;
import reactor.core.publisher.Flux;
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client = HttpClient.create();

		client.websocket()
		      .uri("wss://echo.websocket.org")
		      .handle((inbound, outbound) -> {
		          inbound.receive()
		                 .asString()
		                 .take(1)
		                 .subscribe(System.out::println);

		          final byte[] msgBytes = "hello".getBytes(CharsetUtil.ISO_8859_1);
		          return outbound.send(Flux.just(Unpooled.wrappedBuffer(msgBytes), Unpooled.wrappedBuffer(msgBytes)))
		                         .neverComplete();
		      })
		      .blockLast();
	}
}
```

#### 6.1.1. Host and Port

为了连接到特定的主机和端口，可以将以下配置应用于HTTP客户端：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/address/Application.java

```java
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .host("example.com") 
				          .port(80);           

		client.get()
		      .uri("/")
		      .response()
		      .block();
	}
}
```

### 6.2. Writing Data

要将数据发送到给定的HTTP端点，可以使用send（Publisher）方法提供一个Publisher。默认情况下，Transfer-Encoding：chunked适用于预期请求正文的那些HTTP方法。通过请求标头提供的Content-Length会禁用Transfer-Encoding：分块（如有必要）。以下示例发送hello：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/send/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.ByteBufFlux;
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client = HttpClient.create();

		client.post()
		      .uri("http://example.com/")
		      .send(ByteBufFlux.fromString(Mono.just("hello"))) 
		      .response()
		      .block();
	}
}
```

#### 6.2.1. Adding Headers and Other Metadata

将数据发送到给定的HTTP端点时，您可能需要发送其他标头，cookie和其他元数据。您可以使用以下配置来这样做：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/send/headers/Application.java

```java
import io.netty.handler.codec.http.HttpHeaderNames;
import reactor.core.publisher.Mono;
import reactor.netty.ByteBufFlux;
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .headers(h -> h.set(HttpHeaderNames.CONTENT_LENGTH, 5)); 

		client.post()
		      .uri("http://example.com/")
		      .send(ByteBufFlux.fromString(Mono.just("hello")))
		      .response()
		      .block();
	}
}
```

##### Compression

您可以在HTTP客户端上启用压缩，这意味着将请求标头Accept-Encoding添加到了请求标头中。以下示例显示了如何执行此操作：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/compression/Application.java

```java
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .compress(true);

		client.get()
		      .uri("http://example.com/")
		      .response()
		      .block();
	}
}
```

##### Auto-Redirect Support

您可以配置HTTP客户端以启用自动重定向支持。

Reactor Netty提供了两种不同的自动重定向支持策略：

- followRedirect（boolean）：指定是否为状态301 | 302 | 307 | 308启用HTTP自动重定向支持。
- followRedirect（BiPredicate ）：如果提供的谓词匹配，则启用自动重定向支持。

以下示例使用followRedirect（true）：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/redirect/Application.java

```java
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .followRedirect(true);

		client.get()
		      .uri("http://example.com/")
		      .response()
		      .block();
	}
}
```

### 6.3. Consuming Data

要从给定的HTTP端点接收数据，可以使用HttpClient.ResponseReceiver中的一种方法。以下示例使用responseContent方法：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/read/Application.java

```java
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client = HttpClient.create();

		client.get()
		      .uri("http://example.com/")
		      .responseContent() 
		      .aggregate()       
		      .asString()        
		      .block();
	}
}
```

#### 6.3.1. Reading Headers and Other Metadata

从给定的HTTP端点接收数据时，您可以检查响应标头，状态代码和其他元数据。您可以使用HttpClientResponse获得此其他元数据。以下示例显示了如何执行此操作。

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/read/status/Application.java

```java
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client = HttpClient.create();

		client.get()
		      .uri("http://example.com/")
		      .responseSingle((resp, bytes) -> {
		          System.out.println(resp.status()); 
		          return bytes.asString();
		      })
		      .block();
	}
}
```

#### 6.3.2. HTTP Response Decoder

默认情况下，Netty为传入的响应配置一些限制，例如：

- 初始行的最大长度。
- 请求头的最大长度。
- 内容或每个块的最大长度。

有关更多信息，请参见HttpResponseDecoder。

默认情况下，HTTP客户端配置有以下设置：

./../../reactor-netty-http/src/main/java/reactor/netty/http/HttpDecoderSpec.java

```java
public static final int DEFAULT_MAX_INITIAL_LINE_LENGTH = 4096;
public static final int DEFAULT_MAX_HEADER_SIZE         = 8192;
public static final int DEFAULT_MAX_CHUNK_SIZE          = 8192;
public static final boolean DEFAULT_VALIDATE_HEADERS    = true;
public static final int DEFAULT_INITIAL_BUFFER_SIZE     = 128;
```

./../../reactor-netty-http/src/main/java/reactor/netty/http/client/HttpResponseDecoderSpec.java

```java
public static final boolean DEFAULT_FAIL_ON_MISSING_RESPONSE         = false;
public static final boolean DEFAULT_PARSE_HTTP_AFTER_CONNECT_REQUEST = false;

/**
 * The maximum length of the content of the HTTP/2.0 clear-text upgrade request.
 * By default the client will allow an upgrade request with up to 65536 as
 * the maximum length of the aggregated content.
 */
public static final int DEFAULT_H2C_MAX_CONTENT_LENGTH = 65536;
```

当需要更改这些默认设置时，可以按以下方式配置HTTP客户端：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/responsedecoder/Application.java

```java
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .httpResponseDecoder(spec -> spec.maxHeaderSize(16384)); 

		client.get()
		      .uri("http://example.com/")
		      .responseContent()
		      .aggregate()
		      .asString()
		      .block();
	}
}
```

### 6.4. TCP-level Configuration



./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/channeloptions/Application.java

```java
import io.netty.channel.ChannelOption;
import reactor.netty.http.client.HttpClient;
import java.net.InetSocketAddress;

public class Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .bindAddress(() -> new InetSocketAddress("host", 1234))
				          .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000);

		String response =
				client.get()
				      .uri("http://example.com/")
				      .responseContent()
				      .aggregate()
				      .asString()
				      .block();

		System.out.println("Response " + response);
	}
}
```

#### 6.4.1. Wire Logger

当需要检查对等点之间的流量时，Reactor Netty提供有线记录。默认情况下，禁用有线日志记录。要启用它，必须将记录器react.netty.http.client.HttpClient级别设置为DEBUG并应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/wiretap/Application.java

```java
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .wiretap(true); 

		client.get()
		      .uri("http://example.com/")
		      .response()
		      .block();
	}
}
```

### 6.5. SSL and TLS

当需要SSL或TLS时，可以应用下一个示例中显示的配置。默认情况下，如果OpenSSL可用，则将SslProvider.OPENSSL提供程序用作提供程序。否则，将使用SslProvider.JDK提供程序。您可以通过使用SslContextBuilder或通过设置-Dio.netty.handler.ssl.noOpenSsl = true来切换提供程序。以下示例使用SslContextBuilder：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/security/Application.java

```java
import io.netty.handler.ssl.SslContextBuilder;
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		SslContextBuilder sslContextBuilder = SslContextBuilder.forClient();

		HttpClient client =
				HttpClient.create()
				          .secure(spec -> spec.sslContext(sslContextBuilder));

		client.get()
		      .uri("https://example.com/")
		      .response()
		      .block();
	}
}
```

#### 6.5.1. Server Name Indication

默认情况下，HTTP客户端将远程主机名作为SNI服务器名发送。当需要更改此默认设置时，可以按以下方式配置HTTP客户端：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/sni/Application.java

```java
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslContextBuilder;
import reactor.netty.http.client.HttpClient;

import javax.net.ssl.SNIHostName;

public class Application {

	public static void main(String[] args) throws Exception {
		SslContext sslContext = SslContextBuilder.forClient().build();

		HttpClient client =
				HttpClient.create()
				          .secure(spec -> spec.sslContext(sslContext)
				                              .serverNames(new SNIHostName("test.com")));

		client.get()
		      .uri("https://127.0.0.1:8080/")
		      .response()
		      .block();
	}
}
```

### 6.6. Retry Strategies

默认情况下，如果HTTP客户端在TCP级别中止，则HTTP客户端将重试该请求一次。

### 6.7. HTTP/2

默认情况下，HTTP客户端支持HTTP / 1.1。如果需要HTTP / 2，则可以通过配置获取它。除了协议配置之外，如果您需要H2而不是H2C（明文），则还必须配置SSL。

以下清单提供了一个简单的“ H2”示例：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/http2/H2Application.java

```java
import io.netty.handler.codec.http.HttpHeaders;
import reactor.core.publisher.Mono;
import reactor.netty.http.HttpProtocol;
import reactor.netty.http.client.HttpClient;
import reactor.util.function.Tuple2;

public class H2Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .protocol(HttpProtocol.H2) 
				          .secure();                 

		Tuple2<String, HttpHeaders> response =
				client.get()
				      .uri("https://example.com/")
				      .responseSingle((res, bytes) -> bytes.asString()
				                                           .zipWith(Mono.just(res.responseHeaders())))
				      .block();

		System.out.println("Used stream ID: " + response.getT2().get("x-http2-stream-id"));
		System.out.println("Response: " + response.getT1());
	}
}
```

以下清单展示了一个简单的“ H2C”示例：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/http2/H2CApplication.java

```java
import io.netty.handler.codec.http.HttpHeaders;
import reactor.core.publisher.Mono;
import reactor.netty.http.HttpProtocol;
import reactor.netty.http.client.HttpClient;
import reactor.util.function.Tuple2;

public class H2CApplication {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .protocol(HttpProtocol.H2C);

		Tuple2<String, HttpHeaders> response =
				client.get()
				      .uri("http://localhost:8080/")
				      .responseSingle((res, bytes) -> bytes.asString()
				                                           .zipWith(Mono.just(res.responseHeaders())))
				      .block();

		System.out.println("Used stream ID: " + response.getT2().get("x-http2-stream-id"));
		System.out.println("Response: " + response.getT1());
	}
}
```

#### 6.7.1. Protocol Selection

./../../reactor-netty-http/src/main/java/reactor/netty/http/HttpProtocol.java

```java
public enum HttpProtocol {

	/**
	 * The default supported HTTP protocol by HttpServer and HttpClient
	 */
	HTTP11,

	/**
	 * HTTP/2.0 support with TLS
	 * <p>If used along with HTTP/1.1 protocol, HTTP/2.0 will be the preferred protocol.
	 * While negotiating the application level protocol, HTTP/2.0 or HTTP/1.1 can be chosen.
	 * <p>If used without HTTP/1.1 protocol, HTTP/2.0 will always be offered as a protocol
	 * for communication with no fallback to HTTP/1.1.
	 */
	H2,

	/**
	 * HTTP/2.0 support with clear-text.
	 * <p>If used along with HTTP/1.1 protocol, will support H2C "upgrade":
	 * Request or consume requests as HTTP/1.1 first, looking for HTTP/2.0 headers
	 * and {@literal Connection: Upgrade}. A server will typically reply a successful
	 * 101 status if upgrade is successful or a fallback HTTP/1.1 response. When
	 * successful the client will start sending HTTP/2.0 traffic.
	 * <p>If used without HTTP/1.1 protocol, will support H2C "prior-knowledge": Doesn't
	 * require {@literal Connection: Upgrade} handshake between a client and server but
	 * fallback to HTTP/1.1 will not be supported.
	 */
	H2C
}
```

### 6.8. Metrics

HTTP客户端支持与Micrometer的内置集成。它使用前缀react.netty.http.client公开所有度量。

| metric name                                  | type                | description                                     |
| :------------------------------------------- | :------------------ | :---------------------------------------------- |
| reactor.netty.http.client.data.received      | DistributionSummary | Amount of the data received, in bytes           |
| reactor.netty.http.client.data.sent          | DistributionSummary | Amount of the data sent, in bytes               |
| reactor.netty.http.client.errors             | Counter             | Number of errors that occurred                  |
| reactor.netty.http.client.tls.handshake.time | Timer               | Time spent for TLS handshake                    |
| reactor.netty.http.client.connect.time       | Timer               | Time spent for connecting to the remote address |
| reactor.netty.http.client.address.resolver   | Timer               | Time spent for resolving the address            |
| reactor.netty.http.client.data.received.time | Timer               | Time spent in consuming incoming data           |
| reactor.netty.http.client.data.sent.time     | Timer               | Time spent in sending outgoing data             |
| reactor.netty.http.client.response.time      | Timer               | Total time for the request/response             |

These additional metrics are also available:

Pooled `ConnectionProvider` metrics

| metric name                                           | type  | description                                                  |
| :---------------------------------------------------- | :---- | :----------------------------------------------------------- |
| reactor.netty.connection.provider.total.connections   | Gauge | The number of all connections, active or idle                |
| reactor.netty.connection.provider.active.connections  | Gauge | The number of the connections that have been successfully acquired and are in active use |
| reactor.netty.connection.provider.idle.connections    | Gauge | The number of the idle connections                           |
| reactor.netty.connection.provider.pending.connections | Gauge | The number of requests that are waiting for a connection     |

`ByteBufAllocator` metrics

| metric name                                             | type  | description                                                  |
| :------------------------------------------------------ | :---- | :----------------------------------------------------------- |
| reactor.netty.bytebuf.allocator.used.heap.memory        | Gauge | The number of the bytes of the heap memory                   |
| reactor.netty.bytebuf.allocator.used.direct.memory      | Gauge | The number of the bytes of the direct memory                 |
| reactor.netty.bytebuf.allocator.used.heap.arenas        | Gauge | The number of heap arenas (when `PooledByteBufAllocator`)    |
| reactor.netty.bytebuf.allocator.used.direct.arenas      | Gauge | The number of direct arenas (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.threadlocal.caches | Gauge | The number of thread local caches (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.tiny.cache.size    | Gauge | The size of the tiny cache (when `PooledByteBufAllocator`)   |
| reactor.netty.bytebuf.allocator.used.small.cache.size   | Gauge | The size of the small cache (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.normal.cache.size  | Gauge | The size of the normal cache (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.chunk.size         | Gauge | The chunk size for an arena (when `PooledByteBufAllocator`)  |

以下示例启用了该集成：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/metrics/Application.java

```java
import io.micrometer.core.instrument.Metrics;
import io.micrometer.core.instrument.config.MeterFilter;
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		Metrics.globalRegistry 
		       .config()
		       .meterFilter(MeterFilter.maximumAllowableTags("reactor.netty.http.client", "URI", 100, MeterFilter.deny()));

		HttpClient client =
				HttpClient.create()
				          .metrics(true, s -> {
				              if (s.startsWith("/stream/")) { 
				                  return "/stream/{n}";
				              }
				              else if (s.startsWith("/bytes/")) {
				                  return "/bytes/{n}";
				              }
				              return s;
				          }); 

		client.get()
		      .uri("http://httpbin.org/stream/2")
		      .responseContent()
		      .blockLast();

		client.get()
		      .uri("http://httpbin.org/bytes/1024")
		      .responseContent()
		      .blockLast();
	}
}
```

如果要与Micrometer以外的系统进行集成时需要HTTP客户端指标，或者您想与自己的Micrometer提供集成，则可以提供自己的指标记录器，如下所示：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/metrics/custom/Application.java

```java
import reactor.netty.channel.ChannelMetricsRecorder;
import reactor.netty.http.client.HttpClient;

import java.net.SocketAddress;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .metrics(true, CustomHttpClientMetricsRecorder::new); 

		client.get()
		      .uri("https://httpbin.org/stream/2")
		      .response()
		      .block();
	}
```

### 6.9. Unix Domain Sockets

使用本地传输时，HTTP客户端支持Unix域套接字（UDS）。

以下示例显示了如何使用UDS支持：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/http/client/uds/Application.java

```java
import io.netty.channel.unix.DomainSocketAddress;
import reactor.netty.http.client.HttpClient;

public class Application {

	public static void main(String[] args) {
		HttpClient client =
				HttpClient.create()
				          .remoteAddress(() -> new DomainSocketAddress("/tmp/test.sock")); 

		client.get()
		      .uri("/")
		      .response()
		      .block();
	}
}
```

## 7. UDP Server

Reactor Netty提供了易于使用和易于配置的UdpServer。它隐藏了创建UDP服务器所需的大多数Netty功能，并增加了Reactive Streams背压。

### 7.1. Starting and Stopping

要启动UDP服务器，必须创建和配置UdpServer实例。默认情况下，主机配置为localhost，端口配置为12012。以下示例显示如何创建和启动UDP服务器：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/create/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.udp.UdpServer;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection server =
				UdpServer.create()                         
				         .bindNow(Duration.ofSeconds(30)); 

		server.onDispose()
		      .block();
	}
}
```

返回的Connection提供了一个简单的服务器API，包括disposeNow（），该API以阻塞的方式关闭了服务器。

#### 7.1.1. Host and Port

为了在特定主机和端口上提供服务，可以将以下配置应用于UDP服务器：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/address/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.udp.UdpServer;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection server =
				UdpServer.create()
				         .host("localhost") 
				         .port(8080)        
				         .bindNow(Duration.ofSeconds(30));

		server.onDispose()
		      .block();
	}
}
```

### 7.2. Writing Data

要将数据发送到远程对等方，必须附加I / O处理程序。 I / O处理程序有权访问UdpOutbound，以便能够写入数据。以下示例显示如何发送hello：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/send/Application.java

```java
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.socket.DatagramPacket;
import io.netty.util.CharsetUtil;
import reactor.core.publisher.Mono;
import reactor.netty.Connection;
import reactor.netty.udp.UdpServer;

import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection server =
				UdpServer.create()
				         .handle((in, out) ->
				             out.sendObject(
				                 in.receiveObject()
				                   .map(o -> {
				                       if (o instanceof DatagramPacket) {
				                           DatagramPacket p = (DatagramPacket) o;
				                           ByteBuf buf = Unpooled.copiedBuffer("hello", CharsetUtil.UTF_8);
				                           return new DatagramPacket(buf, p.sender()); 
				                       }
				                       else {
				                           return Mono.error(new Exception("Unexpected type of the message: " + o));
				                       }
				                   })))
				         .bindNow(Duration.ofSeconds(30));

		server.onDispose()
		      .block();
	}
}
```

### 7.3. Consuming Data

要从远程对等方接收数据，必须附加一个I / O处理程序。 I / O处理程序有权访问UdpInbound，以便能够读取数据。以下示例显示了如何使用数据：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/read/Application.java

```java
import io.netty.channel.socket.DatagramPacket;
import reactor.core.publisher.Mono;
import reactor.netty.Connection;
import reactor.netty.udp.UdpServer;

import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection server =
				UdpServer.create()
				         .handle((in, out) ->
				             out.sendObject(
				                 in.receiveObject()
				                   .map(o -> {
				                       if (o instanceof DatagramPacket) {
				                           DatagramPacket p = (DatagramPacket) o;
				                           return new DatagramPacket(p.content().retain(), p.sender()); 
				                       }
				                       else {
				                           return Mono.error(new Exception("Unexpected type of the message: " + o));
				                       }
				                   })))
				         .bindNow(Duration.ofSeconds(30));

		server.onDispose()
		      .block();
	}
}
```

### 7.4. Lifecycle Callbacks

提供以下生命周期回调，以便您扩展UDP服务器：

- `doOnBind`:当服务器通道即将绑定时调用。
- doOnBound：绑定服务器通道时调用。
- doOnUnbound：当服务器通道未绑定时调用。

以下示例使用doOnBound方法：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/lifecycle/Application.java

```java
import io.netty.handler.codec.LineBasedFrameDecoder;
import reactor.netty.Connection;
import reactor.netty.udp.UdpServer;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection server =
				UdpServer.create()
				         .doOnBound(conn -> conn.addHandler(new LineBasedFrameDecoder(8192))) 
				         .bindNow(Duration.ofSeconds(30));

		server.onDispose()
		      .block();
	}
}
```

### 7.5. Connection Configuration

本节描述了可以在UDP级别上使用的三种配置：

- [Channel Options](https://projectreactor.io/docs/netty/release/reference/index.html#server-udp-connection-configurations-channel-options)
- [Wire Logger](https://projectreactor.io/docs/netty/release/reference/index.html#server-udp-connection-configurations-wire-logger)
- [Event Loop Group](https://projectreactor.io/docs/netty/release/reference/index.html#server-udp-connection-configurations-event-loop-group)

#### 7.5.1. Channel Options

默认情况下，UDP服务器配置有以下选项：

./../../reactor-netty-core/src/main/java/reactor/netty/udp/UdpServerBind.java

```java
UdpServerBind() {
  this.config = new UdpServerConfig(
    Collections.singletonMap(ChannelOption.AUTO_READ, false),
    () -> new InetSocketAddress(NetUtil.LOCALHOST, DEFAULT_PORT));
}
```

如果需要其他选项或需要更改当前选项，则可以应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/channeloptions/Application.java

```java
import io.netty.channel.ChannelOption;
import reactor.netty.Connection;
import reactor.netty.udp.UdpServer;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection server =
				UdpServer.create()
				         .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000)
				         .bindNow(Duration.ofSeconds(30));

		server.onDispose()
		      .block();
	}
}
```

有关Netty频道选项的更多信息，请参见以下链接：

- [`ChannelOption`](https://netty.io/4.1/api/io/netty/channel/ChannelOption.html)
- [Socket Options](https://docs.oracle.com/javase/8/docs/technotes/guides/net/socketOpt.html)

#### 7.5.2. Wire Logger

当需要检查对等点之间的流量时，Reactor Netty提供有线记录。默认情况下，禁用有线日志记录。要启用它，您必须将记录器react.netty.udp.UdpServer级别设置为DEBUG并应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/wiretap/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.udp.UdpServer;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection server =
				UdpServer.create()
				         .wiretap(true) 
				         .bindNow(Duration.ofSeconds(30));

		server.onDispose()
		      .block();
	}
}
```

#### 7.5.3. Event Loop Group

默认情况下，UDP服务器使用“事件循环组”，其中工作线程数等于初始化时可用于运行时的处理器数（但最小值为4）。需要其他配置时，可以使用LoopResource＃create方法之一。

“事件循环组”的默认配置如下：

./../../reactor-netty-core/src/main/java/reactor/netty/ReactorNetty.java

```java
/**
 * Default worker thread count, fallback to available processor
 * (but with a minimum value of 4)
 */
public static final String IO_WORKER_COUNT = "reactor.netty.ioWorkerCount";
/**
 * Default selector thread count, fallback to -1 (no selector thread)
 */
public static final String IO_SELECT_COUNT = "reactor.netty.ioSelectCount";
/**
 * Default worker thread count for UDP, fallback to available processor
 * (but with a minimum value of 4)
 */
public static final String UDP_IO_THREAD_COUNT = "reactor.netty.udp.ioThreadCount";
/**
 * Default quiet period that guarantees that the disposal of the underlying LoopResources
 * will not happen, fallback to 2 seconds.
 */
public static final String SHUTDOWN_QUIET_PERIOD = "reactor.netty.ioShutdownQuietPeriod";
/**
 * Default maximum amount of time to wait until the disposal of the underlying LoopResources
 * regardless if a task was submitted during the quiet period, fallback to 15 seconds.
 */
public static final String SHUTDOWN_TIMEOUT = "reactor.netty.ioShutdownTimeout";

/**
 * Default value whether the native transport (epoll, kqueue) will be preferred,
 * fallback it will be preferred when available
 */
```

如果需要更改这些设置，则可以应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/eventloop/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.resources.LoopResources;
import reactor.netty.udp.UdpServer;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		LoopResources loop = LoopResources.create("event-loop", 1, 4, true);

		Connection server =
				UdpServer.create()
				         .runOn(loop)
				         .bindNow(Duration.ofSeconds(30));

		server.onDispose()
		      .block();
	}
}
```

### 7.6. Metrics

UDP服务器支持与Micrometer的内置集成。它使用前缀react.netty.udp.server公开所有度量。

下表提供了有关UDP服务器指标的信息：

| metric name                            | type                | description                           |
| :------------------------------------- | :------------------ | :------------------------------------ |
| reactor.netty.udp.server.data.received | DistributionSummary | Amount of the data received, in bytes |
| reactor.netty.udp.server.data.sent     | DistributionSummary | Amount of the data sent, in bytes     |
| reactor.netty.udp.server.errors        | Counter             | Number of errors that occurred        |

These additional metrics are also available:

`ByteBufAllocator` metrics

| metric name                                             | type  | description                                                  |
| :------------------------------------------------------ | :---- | :----------------------------------------------------------- |
| reactor.netty.bytebuf.allocator.used.heap.memory        | Gauge | The number of the bytes of the heap memory                   |
| reactor.netty.bytebuf.allocator.used.direct.memory      | Gauge | The number of the bytes of the direct memory                 |
| reactor.netty.bytebuf.allocator.used.heap.arenas        | Gauge | The number of heap arenas (when `PooledByteBufAllocator`)    |
| reactor.netty.bytebuf.allocator.used.direct.arenas      | Gauge | The number of direct arenas (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.threadlocal.caches | Gauge | The number of thread local caches (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.tiny.cache.size    | Gauge | The size of the tiny cache (when `PooledByteBufAllocator`)   |
| reactor.netty.bytebuf.allocator.used.small.cache.size   | Gauge | The size of the small cache (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.normal.cache.size  | Gauge | The size of the normal cache (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.chunk.size         | Gauge | The chunk size for an arena (when `PooledByteBufAllocator`)  |

The following example enables that integration:

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/metrics/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.udp.UdpServer;

import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection server =
				UdpServer.create()
				         .metrics(true) 
				         .bindNow(Duration.ofSeconds(30));

		server.onDispose()
		      .block();
	}
}
```

|      | Enables the built-in integration with Micrometer |
| ---- | ------------------------------------------------ |
|      |                                                  |

如果要与Micrometer以外的系统集成需要UDP服务器度量标准，或者要与Micrometer提供自己的集成，则可以提供自己的度量记录器，如下所示：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/server/metrics/custom/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.channel.ChannelMetricsRecorder;
import reactor.netty.udp.UdpServer;

import java.net.SocketAddress;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection server =
				UdpServer.create()
				         .metrics(true, CustomChannelMetricsRecorder::new) 
				         .bindNow(Duration.ofSeconds(30));

		server.onDispose()
		      .block();
	}
```

|      | Enables UDP server metrics and provides [`ChannelMetricsRecorder`](https://projectreactor.io/docs/netty/release/api/reactor/netty/channel/ChannelMetricsRecorder.html) implementation. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

[Suggest Edit](https://github.com/reactor/reactor-netty/edit/master/docs/asciidoc/udp-server.adoc) to "[UDP Server](https://projectreactor.io/docs/netty/release/reference/index.html#udp-server)"

## 8. UDP Client

Reactor Netty提供了易于使用和易于配置的UdpClient。它隐藏了创建UDP客户端所需的大多数Netty功能，并增加了Reactive Streams背压。

### 8.1. Connecting and Disconnecting

要将UDP客户端连接到给定的端点，必须创建并配置UdpClient实例。默认情况下，主机配置为localhost，端口为12012。以下示例显示如何创建和连接UDP客户端：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/create/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.udp.UdpClient;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				UdpClient.create()                            
				         .connectNow(Duration.ofSeconds(30)); 

		connection.onDispose()
		          .block();
	}
}
```

返回的Connection提供了一个简单的连接API，包括disposeNow（），该API以阻塞的方式关闭了客户端。

#### 8.1.1. Host and Port

要连接到特定的主机和端口，可以将以下配置应用于UDP客户端：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/address/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.udp.UdpClient;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				UdpClient.create()
				         .host("example.com") 
				         .port(80)            
				         .connectNow(Duration.ofSeconds(30));

		connection.onDispose()
		          .block();
	}
}
```

### 8.2. Writing Data

要将数据发送到给定的对等方，必须附加I / O处理程序。 I / O处理程序有权访问UdpOutbound，以便能够写入数据。

以下示例显示如何发送hello：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/send/Application.java

```java
import reactor.core.publisher.Mono;
import reactor.netty.Connection;
import reactor.netty.udp.UdpClient;

import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				UdpClient.create()
				         .host("example.com")
				         .port(80)
				         .handle((udpInbound, udpOutbound) -> udpOutbound.sendString(Mono.just("hello"))) 
				         .connectNow(Duration.ofSeconds(30));

		connection.onDispose()
		          .block();
	}
}
```

|      | Sends `hello` string to the remote peer. |
| ---- | ---------------------------------------- |
|      |                                          |

### 8.3. Consuming Data

要从给定的对等方接收数据，必须附加I / O处理程序。 I / O处理程序有权访问UdpInbound，以便能够读取数据。以下示例显示了如何使用数据：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/read/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.udp.UdpClient;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				UdpClient.create()
				         .host("example.com")
				         .port(80)
				         .handle((udpInbound, udpOutbound) -> udpInbound.receive().then()) 
				         .connectNow(Duration.ofSeconds(30));

		connection.onDispose()
		          .block();
	}
}
```

### 8.4. Lifecycle Callbacks

提供以下生命周期回调，以便您扩展UDP客户端：

- doOnConnect：通道即将连接时调用。
- doOnConnected：连接通道后调用。
- doOnDisconnected：断开通道后调用。

以下示例使用doOnConnected方法：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/lifecycle/Application.java

```java
import io.netty.handler.codec.LineBasedFrameDecoder;
import reactor.netty.Connection;
import reactor.netty.udp.UdpClient;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				UdpClient.create()
				         .host("example.com")
				         .port(80)
				         .doOnConnected(conn -> conn.addHandler(new LineBasedFrameDecoder(8192))) 
				         .connectNow(Duration.ofSeconds(30));

		connection.onDispose()
		          .block();
	}
}
```

### 8.5. Connection Configuration

本节描述了可以在UDP级别上使用的三种配置：

- [Channel Options](https://projectreactor.io/docs/netty/release/reference/index.html#client-udp-connection-configurations-channel-options)
- [Wire Logger](https://projectreactor.io/docs/netty/release/reference/index.html#client-udp-connection-configurations-wire-logger)
- [Event Loop Group](https://projectreactor.io/docs/netty/release/reference/index.html#client-udp-connection-configurations-event-loop-group)

#### 8.5.1. Channel Options

默认情况下，UDP客户端配置有以下选项：

./../../reactor-netty-core/src/main/java/reactor/netty/udp/UdpClientConnect.java

```java
UdpClientConnect() {
	this.config = new UdpClientConfig(
			ConnectionProvider.newConnection(),
			Collections.singletonMap(ChannelOption.AUTO_READ, false),
			() -> new InetSocketAddress(NetUtil.LOCALHOST, DEFAULT_PORT));
}
```

如果需要其他选项或需要更改当前选项，则可以应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/channeloptions/Application.java

```java
import io.netty.channel.ChannelOption;
import reactor.netty.Connection;
import reactor.netty.udp.UdpClient;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				UdpClient.create()
				         .host("example.com")
				         .port(80)
				         .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000)
				         .connectNow(Duration.ofSeconds(30));

		connection.onDispose()
		          .block();
	}
}
```

您可以在以下链接中找到有关Netty频道选项的更多信息：

- [`ChannelOption`](https://netty.io/4.1/api/io/netty/channel/ChannelOption.html)
- [Socket Options](https://docs.oracle.com/javase/8/docs/technotes/guides/net/socketOpt.html)

#### 8.5.2. Wire Logger

当需要检查对等点之间的流量时，Reactor Netty提供有线记录。默认情况下，禁用有线日志记录。要启用它，必须将logger的反应堆.netty.udp.UdpClient级别设置为DEBUG并应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/wiretap/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.udp.UdpClient;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				UdpClient.create()
				         .host("example.com")
				         .port(80)
				         .wiretap(true) 
				         .connectNow(Duration.ofSeconds(30));

		connection.onDispose()
		          .block();
	}
}
```

#### 8.5.3. Event Loop Group

缺省情况下，UDP客户端使用“事件循环组”，其中工作线程数等于初始化时可用于运行时的处理器数（但最小值为4）。当需要其他配置时，可以使用LoopResources＃create方法之一。

以下清单显示了“事件循环组”的默认配置：

./../../reactor-netty-core/src/main/java/reactor/netty/ReactorNetty.java

```java
/**
 * Default worker thread count, fallback to available processor
 * (but with a minimum value of 4)
 */
public static final String IO_WORKER_COUNT = "reactor.netty.ioWorkerCount";
/**
 * Default selector thread count, fallback to -1 (no selector thread)
 */
public static final String IO_SELECT_COUNT = "reactor.netty.ioSelectCount";
/**
 * Default worker thread count for UDP, fallback to available processor
 * (but with a minimum value of 4)
 */
public static final String UDP_IO_THREAD_COUNT = "reactor.netty.udp.ioThreadCount";
/**
 * Default quiet period that guarantees that the disposal of the underlying LoopResources
 * will not happen, fallback to 2 seconds.
 */
public static final String SHUTDOWN_QUIET_PERIOD = "reactor.netty.ioShutdownQuietPeriod";
/**
 * Default maximum amount of time to wait until the disposal of the underlying LoopResources
 * regardless if a task was submitted during the quiet period, fallback to 15 seconds.
 */
public static final String SHUTDOWN_TIMEOUT = "reactor.netty.ioShutdownTimeout";

/**
 * Default value whether the native transport (epoll, kqueue) will be preferred,
 * fallback it will be preferred when available
 */
```

如果需要更改这些设置，则可以应用以下配置：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/eventloop/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.resources.LoopResources;
import reactor.netty.udp.UdpClient;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		LoopResources loop = LoopResources.create("event-loop", 1, 4, true);

		Connection connection =
				UdpClient.create()
				         .host("example.com")
				         .port(80)
				         .runOn(loop)
				         .connectNow(Duration.ofSeconds(30));

		connection.onDispose()
		          .block();
	}
}
```

### 8.6. Metrics

UDP客户端支持与Micrometer的内置集成。它使用前缀react.netty.udp.client公开所有度量。

The following table provides information for the UDP client metrics:

| metric name                               | type                | description                                     |
| :---------------------------------------- | :------------------ | :---------------------------------------------- |
| reactor.netty.udp.client.data.received    | DistributionSummary | Amount of the data received, in bytes           |
| reactor.netty.udp.client.data.sent        | DistributionSummary | Amount of the data sent, in bytes               |
| reactor.netty.udp.client.errors           | Counter             | Number of errors that occurred                  |
| reactor.netty.udp.client.connect.time     | Timer               | Time spent for connecting to the remote address |
| reactor.netty.udp.client.address.resolver | Timer               | Time spent for resolving the address            |

These additional metrics are also available:

`ByteBufAllocator` metrics

| metric name                                             | type  | description                                                  |
| :------------------------------------------------------ | :---- | :----------------------------------------------------------- |
| reactor.netty.bytebuf.allocator.used.heap.memory        | Gauge | The number of the bytes of the heap memory                   |
| reactor.netty.bytebuf.allocator.used.direct.memory      | Gauge | The number of the bytes of the direct memory                 |
| reactor.netty.bytebuf.allocator.used.heap.arenas        | Gauge | The number of heap arenas (when `PooledByteBufAllocator`)    |
| reactor.netty.bytebuf.allocator.used.direct.arenas      | Gauge | The number of direct arenas (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.threadlocal.caches | Gauge | The number of thread local caches (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.tiny.cache.size    | Gauge | The size of the tiny cache (when `PooledByteBufAllocator`)   |
| reactor.netty.bytebuf.allocator.used.small.cache.size   | Gauge | The size of the small cache (when `PooledByteBufAllocator`)  |
| reactor.netty.bytebuf.allocator.used.normal.cache.size  | Gauge | The size of the normal cache (when `PooledByteBufAllocator`) |
| reactor.netty.bytebuf.allocator.used.chunk.size         | Gauge | The chunk size for an arena (when `PooledByteBufAllocator`)  |

The following example enables that integration:

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/metrics/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.udp.UdpClient;

import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				UdpClient.create()
				         .host("example.com")
				         .port(80)
				         .metrics(true) 
				         .connectNow(Duration.ofSeconds(30));

		connection.onDispose()
		          .block();
	}
}
```

如果要与Micrometer以外的系统进行集成时需要UDP客户端指标，或者您想与Micrometer提供自己的集成，则可以提供自己的指标记录器，如下所示：

./../../reactor-netty-examples/src/main/java/reactor/netty/examples/documentation/udp/client/metrics/custom/Application.java

```java
import reactor.netty.Connection;
import reactor.netty.channel.ChannelMetricsRecorder;
import reactor.netty.udp.UdpClient;

import java.net.SocketAddress;
import java.time.Duration;

public class Application {

	public static void main(String[] args) {
		Connection connection =
				UdpClient.create()
				         .host("example.com")
				         .port(80)
				         .metrics(true, CustomChannelMetricsRecorder::new) 
				         .connectNow(Duration.ofSeconds(30));

		connection.onDispose()
		          .block();
	}
```
