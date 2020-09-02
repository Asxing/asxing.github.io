---
title: Eventuate 用户指导
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Eventuate
  - 微服务
date: 2018-01-25 21:32:16
password:
summary:  
categories: Eventuate
---

这是一个关于 Eventuate  的简要用户指导。

在此之前推荐先阅读总览和架构设计。基于一些简单的案例，你将学到：

- 实现一个 事件源 actor
- 使用事件源来复制 actor 状态
- 检测状态的并发更新
- 追踪并发更新的冲突
- 自动交互解决冲突
- 基于 CRDT 的无冲突的并发更新
- 对事件源 actors 执行一个事件源视图
- 在事件源 actors 执行事件驱动交流

这个指导只能触及 Eventuate 的表面，更深入的可以参考这个[Reference](https://rbmhtechnology.github.io/eventuate/reference.html#reference)。

## 事件源 actors

```
事件源 actor 是一个能够感知其内部状态变化的 actor。它将这些变化都记录在事件日志内，当遇到紧急情况或定期重启时可以根据日志恢复。这是事件溯源背后的基本理念，不仅仅是存储当前应用的状态，而是所有历史变化都被作为不变的事实，并且当前状态是由这些历史得出。
```

```
事件源 actors 区分命令和事件。在命令执行时，它通常对内部状态和外部命令进行验证，如果验证成功，就会往他们的日志中写入一个或更多事件。在事件处理期间，它们执行已经被写入的事件并通过处理这些事件来更新内部状态。
```

 

> 提示
>
> ```
> 事件源 actors 也可以在事件执行期间创建新的事件，这部分被事件驱动交流部分覆盖。
> ```

具体的 事件源 actors 必须实现 EventsourceActor 的特性

 

通过修改当前状态，应用发送的命令可以被 onCommand handler 处理。通过一个附加的命令，处理器派生出来一个附件事件，并将其记录在事件日志中。如何存储成功，这个命令的发送者将会收到成功处理，如果存储失败，发送者将会受到失败消息，并且询问是否继续。

 

 