---
title: SpringBoot-平滑关闭-限流（五）
author: HoldDie
tags: [SpringBoot,GracefulKill,限流]
top: false
date: 2019-02-28 19:43:41
categories: SpringBoot
---



**世上只有两种承诺，一个是骗自己的，一种是以为能骗住别人的**

### 1、 限流灵活使用

#### 1.1、Maven 依赖

```xml
<dependency>
    <groupId>com.giffing.bucket4j.spring.boot.starter</groupId>
    <artifactId>bucket4j-spring-boot-starter</artifactId>
    <version>0.1.15</version>
    <exclusions>
        <exclusion>
            <groupId>com.giffing.bucket4j.spring.boot.starter</groupId>
            <artifactId>bucket4j-spring-boot-starter-springboot2</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>com.github.vladimir-bukhtoyarov</groupId>
    <artifactId>bucket4j-hazelcast</artifactId>
    <version>4.3.0</version>
</dependency>
```

#### 1.2、配置文件

```yaml
bucket4j:
    enabled: true
    filters:
    - cache-name: buckets-send-login-sms
      strategy: first
      filter-method: servlet
      filter-order: 1
      url: /api/users/send-sms
      metrics:
          tags:
          - key: IP
            expression: "@webUtils.getClientIp()"
            types: REJECTED_COUNTER # for data privacy reasons the IP should only be collected on bucket rejections CONSUMED_COUNTER REJECTED_COUNTER
      rate-limits:
      - filter-key-type: expression
        execute-condition: "!@webUtils.ipInWhiteList()"
        expression: "@webUtils.getClientIp()"
        bandwidths:
        - capacity: 5
          time: 10
          unit: minutes
        - capacity: 15
          time: 1
          unit: hours
        - capacity: 20
          time: 1
          unit: days
        - capacity: 50
          time: 7
          unit: days
        - capacity: 100
          time: 300
          unit: days
    - cache-name: buckets-login
      strategy: first
      filter-method: servlet
      filter-order: 1
      url: /api/users/login
      metrics:
          tags:
          - key: IP
            expression: "@webUtils.getClientIp()"
            types: REJECTED_COUNTER # for data privacy reasons the IP should only be collected on bucket rejections CONSUMED_COUNTER REJECTED_COUNTER
      rate-limits:
      - filter-key-type: expression
        execute-condition: "!@webUtils.ipInWhiteList()"
        expression: "@webUtils.getClientIp()"
        bandwidths:
        - capacity: 40
          time: 10
          unit: minutes
        - capacity: 75
          time: 1
          unit: hours
        - capacity: 100
          time: 1
          unit: days
        - capacity: 250
          time: 7
          unit: days
        - capacity: 1500
          time: 300
          unit: days
    - cache-name: buckets-by-mobile
      strategy: first
      filter-method: servlet
      filter-order: 1
      url: /api/users/by-mobile
      metrics:
          tags:
          - key: IP
            expression: "@webUtils.getClientIp()"
            types: REJECTED_COUNTER # for data privacy reasons the IP should only be collected on bucket rejections CONSUMED_COUNTER REJECTED_COUNTER
      rate-limits:
      - filter-key-type: expression
        execute-condition: "!@webUtils.ipInWhiteList()"
        expression: "@webUtils.getClientIp()"
        bandwidths:
        - capacity: 100
          time: 10
          unit: minutes
        - capacity: 200
          time: 1
          unit: hours
        - capacity: 500
          time: 1
          unit: days
        - capacity: 2000
          time: 7
          unit: days
    - cache-name: buckets-landing
      strategy: first
      filter-method: servlet
      filter-order: 1
      url: /api/users/landing
      metrics:
          tags:
          - key: IP
            expression: "@webUtils.getClientIp()"
            types: REJECTED_COUNTER # for data privacy reasons the IP should only be collected on bucket rejections CONSUMED_COUNTER REJECTED_COUNTER
      rate-limits:
      - filter-key-type: expression
        execute-condition: "!@webUtils.ipInWhiteList()"
        expression: "@webUtils.getClientIp()"
        bandwidths:
        - capacity: 100
          time: 10
          unit: minutes
        - capacity: 200
          time: 1
          unit: hours
        - capacity: 500
          time: 1
          unit: days
        - capacity: 2000
          time: 7
          unit: days
```

#### 1.3、启动配置

```java
@Configuration
public class MyBucket4jConfiguration {
    @Autowired
    private HazelcastInstance hazelcastInstance;

    @Bean
    public ProxyManager<String> proxyManager() {
        return Bucket4j.extension(Hazelcast.class).proxyManagerForMap(this.hazelcastInstance.getMap("myself-bucket4j"));
    }
}
```

#### 1.4、依赖缓存指定

```java
@Component
public class MyBucket4jCacheResolver implements SyncCacheResolver {
    @Autowired
    private HazelcastInstance hazelcastInstance;

    @Override
    public ProxyManager<String> resolve(String cacheName) {
        return Bucket4j.extension(Hazelcast.class).proxyManagerForMap(this.hazelcastInstance.getMap(cacheName));
    }
}
```

#### 1.5、具体处理

```java
@Slf4j
@Primary
@Component
public class Bucket4jMetricHandler implements MetricHandler {

    @Override
    public void handle(MetricType type, String name, long tokens, List<MetricTagResult> tags) {

        List<String> extendedTags = new ArrayList<>();
        extendedTags.add("name");
        extendedTags.add(name);

        tags
            .stream()
            .filter(tag -> tag.getTypes().contains(type))
            .forEach(metricTagResult -> {
                extendedTags.add(metricTagResult.getKey());
                extendedTags.add(metricTagResult.getValue());
            });

        String[] extendedTagsArray = extendedTags.toArray(new String[0]);

        switch (type) {
            case CONSUMED_COUNTER:
                log.info("bucket4jhandler,type:{},name:{},tokens:{},tags:{}", type, name, tokens, StringUtils.join(extendedTagsArray, ","));
                break;
            case REJECTED_COUNTER:
                log.info("bucket4jhandler,type:{},name:{},tokens:{},tags:{}", type, name, tokens, StringUtils.join(extendedTagsArray, ","));
                break;
            default:
                throw new IllegalStateException("Unsupported metric type: " + type);
        }

    }
}
```

#### 1.6、特定业务逻辑

```java
@Service
@Slf4j
public class Bucket4jService {
    @Autowired
    private RedisTemplate redisTemplate;
    @Autowired
    private ProxyManager<String> proxyManager;

    private static final BucketConfiguration bucket4SmsByMobileConfig = Bucket4j.configurationBuilder()
            .addLimit(Bandwidth.simple(20, Duration.ofDays(1)))
            .addLimit(Bandwidth.simple(7, Duration.ofHours(1)))
            .addLimit(Bandwidth.simple(5, Duration.ofMinutes(10)))
            .build();

    public void check4SendLoginCodeByMobile(String mobile) {
        if (BlackAndWhiteList.isWhiteList(mobile)) {
            log.info("手机号白名单不检测, {}", mobile);
            return;
        }

        Bucket bucket = this.proxyManager.getProxy("send-login-mobile:" + mobile, bucket4SmsByMobileConfig);
        if (!bucket.tryConsume(1)) {
            log.error("rate请求频繁, 发送登录验证码, 手机号:{}", mobile);
            throw new BadRequestAlertException("请求频繁, 请稍后再试~~");
        }
    }

    private static final BucketConfiguration bucket4LoginConfig = Bucket4j.configurationBuilder()
            .addLimit(Bandwidth.simple(100, Duration.ofDays(7)))
            .addLimit(Bandwidth.simple(50, Duration.ofDays(1)))
            .addLimit(Bandwidth.simple(30, Duration.ofHours(1)))
            .addLimit(Bandwidth.simple(20, Duration.ofMinutes(10)))
            .build();

    public void check4Login(String mobile) {
        if (BlackAndWhiteList.isWhiteList(mobile)) {
            log.info("手机号白名单不检测, {}", mobile);
            return;
        }

        Bucket bucket = this.proxyManager.getProxy("login:" + mobile, bucket4LoginConfig);
        if (!bucket.tryConsume(1)) {
            log.error("rate请求频繁, 登录, 手机号:{}", mobile);
            throw new BadRequestAlertException("请求频繁请稍后再试");
        }
    }
}
```

### 2、 完美关闭

#### 2.1、Maven 依赖

```xml
<dependency>
    <groupId>ch.sbb</groupId>
    <artifactId>springboot-graceful-shutdown</artifactId>
    <version>2.0.1</version>
</dependency>
```

#### 2.2、启动类设置

```java
public static void main(String[] args) {
    SpringApplication app = new SpringApplication(newdaichao.class);
    DefaultProfileUtil.addDefaultProfile(app);

    app.setRegisterShutdownHook(false);
    ConfigurableApplicationContext applicationContext = app.run(args);
    Runtime.getRuntime().addShutdownHook(new Thread(new GracefulShutdownHook(applicationContext)));

    Environment env = applicationContext.getEnvironment();
    logApplicationStartup(env);
}
```