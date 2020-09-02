---
title: SpringBoot-源码（一）
tags: [SpringBoot, SourceCode, Java]
img: https://www.holddie.com/img/20200105162458.jpg
date: 2018-08-20 08:27:59
categories: SourceCode
---

即使只能孤单地在黑暗中等待，我也相信，下一秒你就会出现在我眼前，而那一刻，就是黎明。		 ——温虞菲



## 在 Bean 初始化回调前后进行自定义操作

#### InitializingBean  初始化

- 在 Spring 环境中，如果需要在 Bean 自动装配（属性注入）完成后进行自定义操作，通常只需要实现 InitializingBean 接口，在 afterPropertiesSet 方法中执行操作即可。
- 在这个接口回调时，Bean的所有的属性都已经注入完成了。
- 这种方式适合单独的Bean,但是如果有多个Bean都有一样的业务逻辑，那么抽象出来一个共同点类即可。所有的类都继承这个抽象类，但是这样的方式代码侵入性大，不舍用户框架类的项目通用业务逻辑处理。

#### BeanPostProcessor  处理

BeanPostProcessor 接口提供以下方法：

- postProcessBeforeInitialization：在 Bean 初始化回调前调用
- postProcessAfterInitialization：在 Bean 初始化会掉完成后进行调用，而且会在 afterPropertiesSet 方法回调之后。

只要实现这个接口就可以在 Bean 的初始化回调前后进行其他业务操作。

对于所有注解：  @PostConstruct、BeanPostProcessor、InitializingBean 它们之间的调用关系：

**BeanPostProcessor.postProcessBeforeInitialization→ @PostConstruct→ InitializingBean→ BeanPostProcessor.postProcessAfterInitialization**

