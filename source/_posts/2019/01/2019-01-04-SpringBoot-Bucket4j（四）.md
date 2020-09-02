---
title: SpringBoot-Bucket4j（四）
author: HoldDie
tags: [Bucket4j,SpringBoot]
top: false
date: 2019-01-04 19:43:41
categories: SpringBoot
---



**空谷足音，听到的却是自己的心。——诸葛菲菲**

### 1、背景

> 当业务的量起来以后，就会面临有恶意请求攻击接口，此时为了有效过滤这种情况，使用接口限速。

### 2、优势

- 使用了IT行业基础设施有名的限速算法
- 有效无锁实现，强力扩展多线程
- 计算精度准确，全部使用整数
- 支持多种的缓存
- 自定义桶的宽度
- 兼容同步和异步API
- 允许实现监听接口完善监控和日志
- 支持将Bucket作为一个调度任务

### 3、介绍

- 防止DOS攻击，
- 请求特定限制
  - 具体地域限制
  - 未登录限制
  - 未支付用户

### 4、开始

#### 4.1、关键依赖

```xml
<dependency>
    <groupId>com.giffing.bucket4j.spring.boot.starter</groupId>
    <artifactId>bucket4j-spring-boot-starter</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
<dependency>
    <groupId>org.ehcache</groupId>
    <artifactId>ehcache</artifactId>
</dependency>
```

#### 4.2、限制介绍

```yml
bucket4j:
  enabled: true
  filters:
  - cache-name: buckets
    url: .*
    rate-limits:
    - bandwidths:
      - capacity: 5
        time: 10
        unit: seconds
```

当然也可以使用配置文件，配置形式如下

```yaml
spring:
  cache:
    jcache:
      config: classpath:ehcache.xml
```

配置文件：

```xml
<config xmlns="...">
    <cache alias="buckets">
        <expiry>
            <ttl unit="seconds">3600</ttl>
        </expiry>
        <heap unit="entries">1000000</heap>
    </cache>
</config>
```

#### 4.3、Bucket4j Properties

```properties
# 是否启用
bucket4j.enabled=true 
# 缓存名称
bucket4j.filters[0].cache-name=buckets 
# 拦截方式 [servlet,zuul,webflux]
bucket4j.filters[0].filter-method=servlet 
# 默认值是10，将它的值设置大于零的时候生效
bucket4j.filters[0].filter-order= 
# 返回的JSON结果中，添加如下内容
bucket4j.filters[0].http-response-body={ "message": "Too many requests" }
# 对于请求链接的正则表达式
bucket4j.filters[0].url=.* 
bucket4j.filters[0].metrics.enabled=true
# (选填) 如果你对消费计数不感兴趣，可以选择拒绝计数 
bucket4j.filters[0].metrics.types=CONSUMED_COUNTER,REJECTED_COUNTER 
bucket4j.filters[0].metrics.tags[0].key=IP
bucket4j.filters[0].metrics.tags[0].expression=getRemoteAddr()
# (选填) 这个参数只在拒绝计数类型时起作用
bucket4j.filters[0].metrics.tags[0].types=REJECTED_COUNTER 
bucket4j.filters[0].metrics.tags[1].key=URL
bucket4j.filters[0].metrics.tags[1].expression=getRequestURI()
bucket4j.filters[0].metrics.tags[2].key=USERNAME
bucket4j.filters[0].metrics.tags[2].expression="@securityService.username() != null ? @securityService.username() : 'anonym'"
# [first, all] 选择first时，如果配置多个限速配置，只会第一个有效
bucket4j.filters[0].strategy=first 
bucket4j.filters[0].rate-limits[0].filter-key-type=expression [default, ip, expression]
# 如果filter-key-type是一个表达式，则可以通过Spring Expression Language
bucket4j.filters[0].rate-limits[0].expression=getRemoteAddress() 
# (选填) 一个SpEL表达式，用于决定是否执行速率限制
bucket4j.filters[0].rate-limits[0].execute-condition=1==1 
# (选填) 一个SpELl表达式，用于决定是否跳过速率限制
bucket4j.filters[0].rate-limits[0].skip-condition=1==1 
bucket4j.filters[0].rate-limits[0].bandwidths[0].capacity=10
bucket4j.filters[0].rate-limits[0].bandwidths[0].time=1
bucket4j.filters[0].rate-limits[0].bandwidths[0].unit=minutes
bucket4j.filters[0].rate-limits[0].bandwidths[0].fixed-refill-interval=0
bucket4j.filters[0].rate-limits[0].bandwidths[0].fixed-refill-interval-unit=minutes
```

#### 4.4、filter-key-type

> 过滤器的类型决定如何限制请求，默认的参数没有任何区分，仅仅是一般限制

##### 4.4.1、IP

IP 过滤器是基于IP地址的限制（通过httpServletRequest.getRemoteAddr()方法），因此每一个IP地址是独立的。

##### 4.4.2、Expression

- 表达式过滤器是基于SpELl表达式，旨在提供一种灵活的拦截方式。
- 他可以实现在不改一行代码的情况下，修改拦截规则
- 根据过滤方法[servlet，zuul，webflux]，可以在表达式中使用不同的SpEL根对象，以便可以直接访问这些请求对象的方法：
  - **servlet**: `javax.servlet.http.HttpServletRequest (e.g. getRemoteAddr() or getRequestURI())`
  - **zuul**: `javax.servlet.http.HttpServletRequest`
  - **webflux**: `org.springframework.http.server.reactive.ServerHttpRequest`

基于IP限制

```java
getRemoteAddress();
```

首先使用用户名，没有登录情况下使用IP

```java
@securityService.username()?: getRemoteAddr()

@Service
public class SecurityService {

    public String username() {
        String name = SecurityContextHolder.getContext().getAuthentication().getName();
        if(name == "anonymousUser") {
            return null;
        }
        return name;
    }

}
```

#### 4.5、拦截策略

> 过滤策略定义了如何执行速率限制

```properties
# [first, all]
bucket4j.filters[0].strategy=first 
```

### 5、监控

> 该starter很好的支持监控，如果你需要监控哪个桶的数量，如果自己感兴趣可以直接定制Tags进行自定义监控。

```yaml
bucket4j:
  enabled: true
  filters:
  - cache-name: buckets
    filter-method: servlet
    filter-order: 1
    url: .*
    metrics:
      tags:
        - key: IP
          expression: getRemoteAddr()
          # for data privacy reasons the IP should only be collected on bucket rejections
          types: REJECTED_COUNTER 
        - key: USERNAME
          expression: "@securityService.username() != null ? @securityService.username() : 'anonym'"
        - key: URL
          expression: request.getRequestURI()
    rate-limits:
    - filter-key-type: expression
      execute-condition:  "@securityService.username() == 'admin'"
      expression: "@securityService.username()?: getRemoteAddr()"
      bandwidths:
      - capacity: 30
        time: 1
        unit: minutes
```

### 6、通过Properties配置

#### 6.1、简单的通过用户进行限速

```yaml
bucket4j:
  enabled: true
  filters:
  - cache-name: buckets
    url: .*
    rate-limits:
    - filter-key-type: default
      bandwidths:
      - capacity: 5
        time: 10
        unit: seconds
```

#### 6.2、根据匿名或登录用户进行条件筛选

> 因为bucket4j.filters [0] .strategy是first，不会检查用户登录的第二个速率限制。只执行第一个。

```yaml
bucket4j:
  enabled: true
  filters:
  - cache-name: buckets
    filter-method: servlet
    url: .*
    rate-limits:
    - filter-key-type: expression
      # only for not logged in users
      execute-condition:  @securityService.notSignedIn() 
      expression: "getRemoteAddr()"
      bandwidths:
      - capacity: 10
        time: 1
        unit: minutes
    - filter-key-type: expression
      # strategy is only evaluate first. so the user must be logged in and user is not admin
      execute-condition: "@securityService.username() != 'admin'" 
      expression: @securityService.username()
      bandwidths:
      - capacity: 1000
        time: 1
        unit: minutes
    - filter-key-type: expression
      # user is admin
      execute-condition:  "@securityService.username() == 'admin'"  
      expression: @securityService.username()
      bandwidths:
      - capacity: 1000000000
        time: 1
        unit: minutes
```

#### 6.3、配置多个独立的拦截来声明具体的限速配置

```yaml
bucket4j:
  enabled: true
  # 每一个配置实体，创建一个Servlet拦截或者Zuul拦截
  filters: 
  # 使用Bucket4j创建一个新的Servlet拦截
  - cache-name: buckets 
    url: /admin*
    rate-limits:
    # 过滤所有的请求
    - filter-key-type: default 
      # 10s内最多5个请求
      bandwidths: 
      - capacity: 5
        time: 10
        unit: seconds
  - cache-name: buckets
    url: /public*
    rate-limits:
    # 根据IP拦截
    - filter-key-type: ip 
      # 10s内最多5个请求
      bandwidths: 
      - capacity: 5
        time: 10
        unit: seconds
  - cache-name: buckets
    url: /users*
    rate-limits:
    # 通过表达式
    - filter-key-type: expression 
          # 如果是 admin ，则跳过
          skip-condition: "@securityService.username() == 'admin'" 
          # 使用用户名作为key，如果通过身份验证则使用IP地址
          expression: "@securityService.username()?: getRemoteAddr()" 
      bandwidths:
    - capacity: 100
      time: 1
      unit: seconds
    - capacity: 10000
      time: 1
      unit: minutes
```