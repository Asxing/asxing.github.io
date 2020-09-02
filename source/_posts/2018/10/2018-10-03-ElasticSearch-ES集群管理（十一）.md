---
title: ElasticSearch-Java客户端（十）
author: HoldDie
tags: [ElasticSearch,搜索,聚合分析]
top: false
date: 2018-10-03 19:43:41
categories: ElasticSearch
---



> 即便是微不足道的蝼蚁，穿过黑暗的沼泽，也算顶天立地。 ——骨子

### ES Client 简介

- ES 整体是一个 `C/S` 架构，有 Client 访问集群的状态，进行状态搜索。
- 链接的时候可以任意选择连接那个节点
- Rest 接口：
  - 最外层，端口9200
- transport：
  - 传输层，端口9300
  - 默认是Http协议
  - 同时支持thrift、memcached

发现有JavaScript 版本，某些特殊场所可以直接前段直接访问，很方便。

#### Java rest client 两个版本：

- 一个低版本
  - 通过HTTP与集群交互，用户需要自己编组请求JSON串，及解析相应JSON串，兼容所有 ES 版本。
  - 底层使用HTTPClient，
- 一个高版本（从6.0.0开始）
  - 给予低级别的REST客户端，增加了编组请求，解析响应等相关api。
  - 从 6.0.0 开始加入，目的就是以Java面向对象的方式进行请求，响应处理。
  - 每个API，支持 同步、异步 两种方式，同步方式直接返回一个结果对象。
  - 异步方式以 async 为后缀，通过 listener 参数来通知结果
  - 高级Java Rest 客户端依赖 ElasticSearch core project

#### 创建索引

- 可以创建mapping、setting、alias

对于底层客户端代码跟自己使用json先沟通呢，只需要自己配置即可，此时可可以看底层的代码，我们可以自己复习一遍，启动一个SpringBoot-ES工程，自己对于聚合、高亮、查询建议、就是构造器模式记性构造。

得到响应结果，可以分析，结果中的Hits集合。

获取聚合结果、查询结果

#### 使用 hightlight 高亮

使用对象进行JSON 格式的封装，

Java Client

- 起初就存在的，使用 TransportClient，各种操作本质上是异步的（可以用listener 或 Future）
- 使用的是 log4j2 日志组件、如果要使用其他的日志组件，可以使用slf4j作为桥
- 连接的时使用9300端口，在使用完client时，记得关闭客户端对象。