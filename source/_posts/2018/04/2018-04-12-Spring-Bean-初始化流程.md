---
title: Spring-Bean-初始化流程
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Spring
  - Bean
  - 初始化
date: 2018-04-12 21:32:16
password:
summary:  
categories: SpringBean
---

SpringBean 初始化流程源码简记，加载碎碎念！



应用程序上下文刷新，万变不离其宗，最终调用的是 `AbstractApplicationContext` 的 `refresh` 方法。

![](https://www.holddie.com/img/20200105153219)



Java Bean 初始化和实例化区别：

- 实例化是通过构造器开辟内存空间，生成一个对象实例。
- 初始化是对已有的实例或者变量进行赋予初始值，不只针对与对象。
- 实例化是初始化的其中一部分，其中初始化还包括类本身的加载，比如静态代码的执行和静态变量的初始化。
- 实例化只是 `new` 一个新对象到堆内存，但是静态化的代码就是类本身拥有的内存空间，被所有 `new` 的实例对象共享。 
- 不管 `new` 多少的对象，类的静态代码只执行一部分，就是在初始化时。
- 当然其中  `初始化` 分很多种，比如 `对象的初始化` 和 `类的初始化` 都属于初始化，静态代码块 和 静态成员变量 都是在类加载的时候进行初始化赋值的。
- 最后的确也是，先加载类，才能创建对象，也个也没有冲突。



### 注册 ApplicationListener

Spring 框架中，可以注册多个 Listener 关注一个  Event，当事件发生时会通知关注改事件的所有 Listener，设计模式中的观察者模式，`ApplicationListener` 接口定义：

```java
@FunctionalInterface
public interface ApplicationListener<E extends ApplicationEvent> extends EventListener {

    void onApplicationEvent(E event);

}
```

ApplicationEvent 为应用程序事件，对应应用程序上下文的事件类型为：

- `ContextClosedEvent`：对应 ApplicationContext 的 `close` 方法
- `ContextRefreshedEvent`：对应 ApplicationContext 的 `finishRefresh` 方法
- `ContextStartedEvent`：对应 ApplicationContext 的 `start` 方法
- `ContextStoppedEvent`：对应 ApplicationContext 的 `stop` 方法

### getBean 阶段

getBean 操作的最终调用是 `DefaultListableBeanFactory` 的 `getBean` 方法

![](https://www.holddie.com/img/20200105153241.png)

这些接口大部分是实现 `BeanPostProcessor` 接口

#### Bean 初始化前后扩展接口

Spring 框架在 `doCreateBean` 的 `initializeBean` 方法里面留有 Bean 初始化前后的扩展接口 `initializeBean` 

```java
protected Object initializeBean(final String beanName, final Object bean, @Nullable RootBeanDefinition mbd) {

    ...
    //(1)
    invokeAwareMethods(beanName, bean);
    ...
    //(2)
    Object wrappedBean = bean;
    if (mbd == null || !mbd.isSynthetic()) {
        wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
    }
    //(3)
    try {
        invokeInitMethods(beanName, wrappedBean, mbd);
    }
    catch (Throwable ex) {
        ...
    }
    //(4)
    if (mbd == null || !mbd.isSynthetic()) {
        wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
    }

    return wrappedBean;
}
```

1、主要是设置`Bean`的 名称，加载方式，BeanFactory

2、调用所有注的实现了 `beanPostProcessor` 接口的 `Bean` 的 `postProcessBeforeInitialization` 方法，实现对 Bean 初始化前做一些定制，`beanFactory` 里面添加了一个叫做 `ApplicationContext` 的 `beanPostProcessor` ，这里看下它的 `postProcessBeforeInitialization` 方法

```java
public Object postProcessBeforeInitialization(final Object bean, String beanName) throws BeansException {
    ...
        invokeAwareInterfaces(bean);
    ...
        return bean;
}
```

此处主要是注入一些 环境变量 或者 上下文 。

3、invokeInitMethods 方法内部会调用 Bean 中的 afterPropertiesSet 方法进行属性设置，如果 Bean 实现了 InitializingBean 接口，就设置一些属性， 调用用户自定义的初始化方法。

4、实现了 `BeanPostProcessor` 接口中的 `postProcessAfterInitialization` 方法

> Spring Bean 的 set 方法设置属性值的时机先于 `afterPropertiesSet`，而 `afterPropertiesSet` 的执行时机又先于用户自定义初始化方法。

### close 阶段

当调用应用程序上下文的 `close`方法后，会关闭该应用程序上下文，并且销毁其管理的 `BeanFactory` 里面的所有 `Beans` 。

![](https://www.holddie.com/img/20200105153300.png)

具体的步骤：

- 给所有注册了 `ContextClosedEvent` 事件的 `ApplicationListener` 发送通知。
  - 应用程序的实现 `ApplicationListener` 接口，重写 `onApplicationEvent` 方法
- 销毁应用程序上下文管理的 `BeanFactory` 里面的所有 Beans。
  - 如果该 `Bean` 实现了 `DisposableBean` 接口的 destory 方法。
  - 那么会在销毁具体的 Bean 前会调用该 `Bean`  的 `destory` 方法
- 关闭 `BeanFactory`。
  - 对应 AbstractApplicationContext 的子类 `ClassPathXmlApplicationContext` 由于是可重复刷新的应用程序上下文，所以把 `BeanFactory` 设置为 `null。`
- `onClose` 留给子类的扩展接口，子类可以实现该末班方法做一些清理工作。
  - 本身是一个空方法，没有实现，留给子类扩展使用。
  - 栗子：SpringBoot 中 Web 应用程序上下文 `EmbeddedWebApplicationContext` 实现的 `onClose` 方法，对应关闭内嵌的 `web` 容器。

### ContextLoaderListener 启动

ContextLoaderListener 一般是用来启动一个 Spring 容器或其他框架的根容器。

![](https://www.holddie.com/img/20200105153313.png)

在 web.xml 中配置 ContextLoaderListener：

```xml
<listener>
    <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
</listener>

<context-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>
        classpath*:spring/*.xml
    </param-value>
</context-param>
```

如上代码会创建一个 `XMLWebApplicationContext` 应用程序上下文，`contextConfigLocation` 配置扫描那些配置文件，把其中的 Bean 注入到 `XMLWebApplicationContext` 管理的`BeanFactory`，这里的 上下文就是我们理解的 `Spring 容器`。

#### Tomcat 启动流程

结合 Tomcat 启动流程，确定加载顺序，知道我们的 WEB 应用在什么时候加载。

![](https://www.holddie.com/img/20200105153328.png)

1、启动一个 StandardContext 代表一个应用

2 和 3、在 Web 应用启动过程中会调用 `mergeParameters` 方法解析 `web.xml` 配置的 `context-param` 参数，并把这些参数设置到 `ApplicationContext` 中。注意这里的 `ApplicationContext` 是 `Tomcat` 中的 `ApplicationContext` 不同于 Spring 框架中的 `ApplicationContext` ，它实现了 `org.pache.catalina.servlet4preview.ServletContext` ,是一个`ServletContext` ，这个 `ApplicationContext` 是应用级别的，每个应用维护这自己的 `APplicationContext` 对象，用来保存应用级别的变量信息，内部是 `ConcurrentHashMap` 实现的 。

 4 、5 、6、初始化所在 `web.xml` 里面配置的 `ServletContextListener` 的实现类，并以 `ApplicationContext`  为构造函数参数创建一个 `ServletContextEvent` 作为 ServletContext 事件（内部实际维护的是 `ApplicationContext`的一个门面类 `ServletContextFacade`），然后调用所有实现类的 `contextInitialized` 方法，并传递 `ServletContextEvent` 作为参数，此处是 `Tomcat` 和 `ContextLoaderListener` 之间关联之处。`Tomcat` 的每个应用启动过程中会调用 `ContextLoaderListener` 的 `contextInitialized` 方法并传递的参数里面包含了该应用级别的一个 `ApplicationContext` 对象，这个对象包含了该应用作用域的变量集合。

#### ContextLoaderListener 启动流程

![](https://www.holddie.com/img/20200105153341.png)

1、 `HttpServletBean` 的 `init` 开始

2、调用 `FrameworkServlet#initServletBean` 

3、调用 `FrameworkServlet#initWebApplicationContext`，创建Spring 应用程序上下文

5、设置 `XMLWebApplicationContext`的 `ServletContext` 为 ApplicationContextFacade。

67、从 ServletContext 获取 contextConfigLocation 变量的值，这里为 `WEB-INF/applicationContext.xml`

8、设置 `XMLWebApplicationContext` 的配置文件为 `WEB-INF/applicationContext.xml`,这意味着会从 `WEB-INF/ApplicationContext.xml` 文件解析 `Bean` 注入到 `XMLWebApplicationContext` 管理的 `BeanFactory` 中。

9、刷新 `XMLWebApplicationContext` 应用程序上下文。

10、保存 `XmlWebApplicationContext` 到 `ServletContext` ，这样应用任何有 `ServletContext` 的地方就可以获取 `XMLWebApplicationContext`，从而可以获取 `XMLWebApplicationContext`管理的所有的 `Bean`。



`DisspatcherServlet` 创建一个 `XmlWebApplicationContext` ，默认管理 `web-info/springmvc-servlet.xml` 里面 `web-info/springmvc-servlet.xml` 里面的 `Controller Bean`![image.png](/img/2018/04/1240.png)

在 `DispatcherServlet` 的初始化方法中，首先从 `ServletContext` 的全局变量表里面获取 `ContextLoaderListener` 创建的 `XMLWebApplicationContext` 上下文，然后使用该 context 作为父上下文创建了 `SpringMVC` 的 `Servlet Context` 容器，并且设置 `namespace` 为 `springmvc-servlet`。这个在查找配置文件时候会用到，最后会拼接为 `springmvc-servlet.xml`，最后刷新 `SpringMVC` 的 `Servlet Context` 上下文。

一般我们在 `listener` 创建的父容器里面配置 bo 类，用来操作具体业务，在 `dispatcher` 子容器里面配置 `Controller` 类，然后 `Controller` 里面调用 bo 类来实现业务。

通过 `Tomcat` 启动过程中调用 `ContextLoaderListener` 的 `contextInitialized` 方法，首先创建了父容器用来管理 `bo Bean`，然后使用 DispatcherServlet 创建了子容器用来管理 `Controller Bean`，`ContextLoaderListener` 让 `SpringMVC` 与 `Tomcat` 容器联系起来了。

#### 参考链接

- [Spring 框架和 Tomcat 容器扩展接口揭秘]: http://gitbook.cn/books/5a893a2f8fdd2712fdada4c5/index.html

  