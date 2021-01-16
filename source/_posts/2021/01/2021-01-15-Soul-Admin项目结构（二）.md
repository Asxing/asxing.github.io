---
title: Soul-Admin项目结构（二）
author: HoldDie
top: false
cover: false
toc: true
mathjax: true
tags:
  - 网关
  - Spring
date: 2021-01-15 23:31:35
img:
coverImg: 
password: 
summary: 
categories: Soul
---

## Soul-admin 目录结构

### 数据异步配置

我们直接查看 DataSyncConfiguration 这个配置文件，我们可以看到 Soul-admin 同时支持 Http 长轮询、Nacos、Zookeeper、Websocket 四种方式进行异步数据同步。

#### HttpLongPollingListener

```java
@Configuration
@ConditionalOnProperty(name = "soul.sync.http.enabled", havingValue = "true")
@EnableConfigurationProperties(HttpSyncProperties.class)
static class HttpLongPollingListener {

    @Bean
    @ConditionalOnMissingBean(HttpLongPollingDataChangedListener.class)
    public HttpLongPollingDataChangedListener httpLongPollingDataChangedListener(final HttpSyncProperties httpSyncProperties) {
        return new HttpLongPollingDataChangedListener(httpSyncProperties);
    }

}
```

#### ZookeeperListener

```java
@Configuration
@ConditionalOnProperty(prefix = "soul.sync.zookeeper", name = "url")
@Import(ZookeeperConfiguration.class)
static class ZookeeperListener {

    /**
     * Config event listener data changed listener.
     *
     * @param zkClient the zk client
     * @return the data changed listener
     */
    @Bean
    @ConditionalOnMissingBean(ZookeeperDataChangedListener.class)
    public DataChangedListener zookeeperDataChangedListener(final ZkClient zkClient) {
        return new ZookeeperDataChangedListener(zkClient);
    }

    /**
     * Zookeeper data init zookeeper data init.
     *
     * @param zkClient        the zk client
     * @param syncDataService the sync data service
     * @return the zookeeper data init
     */
    @Bean
    @ConditionalOnMissingBean(ZookeeperDataInit.class)
    public ZookeeperDataInit zookeeperDataInit(final ZkClient zkClient, final SyncDataService syncDataService) {
        return new ZookeeperDataInit(zkClient, syncDataService);
    }
}
```

#### NacosListener

```java
@Configuration
@ConditionalOnProperty(prefix = "soul.sync.nacos", name = "url")
@Import(NacosConfiguration.class)
static class NacosListener {

    /**
     * Data changed listener data changed listener.
     *
     * @param configService the config service
     * @return the data changed listener
     */
    @Bean
    @ConditionalOnMissingBean(NacosDataChangedListener.class)
    public DataChangedListener nacosDataChangedListener(final ConfigService configService) {
        return new NacosDataChangedListener(configService);
    }
}
```

#### WebsocketListener

```java
@Configuration
@ConditionalOnProperty(name = "soul.sync.websocket.enabled", havingValue = "true", matchIfMissing = true)
@EnableConfigurationProperties(WebsocketSyncProperties.class)
static class WebsocketListener {

    /**
     * Config event listener data changed listener.
     *
     * @return the data changed listener
     */
    @Bean
    @ConditionalOnMissingBean(WebsocketDataChangedListener.class)
    public DataChangedListener websocketDataChangedListener() {
        return new WebsocketDataChangedListener();
    }

    /**
     * Websocket collector websocket collector.
     *
     * @return the websocket collector
     */
    @Bean
    @ConditionalOnMissingBean(WebsocketCollector.class)
    public WebsocketCollector websocketCollector() {
        return new WebsocketCollector();
    }

    /**
     * Server endpoint exporter server endpoint exporter.
     *
     * @return the server endpoint exporter
     */
    @Bean
    @ConditionalOnMissingBean(ServerEndpointExporter.class)
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }
}
```

### SecretConfiguration配置

```java
@Bean
@ConditionalOnMissingBean(value = SecretProperties.class)
public SecretProperties secretProperties(@Value("${soul.aes.secret.key:2095132720951327}") final String key) {
    SecretProperties secretProperties = new SecretProperties();
    secretProperties.setKey(key);
    return secretProperties;
}
```

### Swagger配置

```java
@Configuration
@EnableSwagger2
public class SwaggerConfiguration {
    
    @Value("${swagger.enable:false}")
    private boolean enable;
    
    private final BuildProperties buildProperties;
    
    public SwaggerConfiguration(@Autowired(required = false) final BuildProperties buildProperties) {
        this.buildProperties = buildProperties;
    }
    
    /**
     * Configure The Docket with Swagger.
     *
     * @return Docket {@linkplain Docket}
     */
    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(this.apiInfo())
                .enable(enable)
                .select()
                .apis(RequestHandlerSelectors.basePackage("org.dromara.soul.admin.controller"))
                .paths(PathSelectors.any())
                .build();
    }
    
    /**
     * Fetch version information from pom.xml and set title, version, description,
     * contact for Swagger API document.
     *
     * @return Api info
     */
    private ApiInfo apiInfo() {
        String version = "1.0.0";
        if (buildProperties != null) {
            version = buildProperties.getVersion();
        }
        return new ApiInfoBuilder()
                .title("Soul Admin API Document")
                .description("")
                .version(version)
                .contact(new Contact("soul", "https://github.com/dromara/soul", ""))
                .build();
    }
}
```

### 允许跨域访问

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(final CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedHeaders("Access-Control-Allow-Origin",
                        "*",
                        "Access-Control-Allow-Methods",
                        "POST, GET, OPTIONS, PUT, DELETE",
                        "Access-Control-Allow-Headers",
                        "Origin, X-Requested-With, Content-Type, Accept")
                .allowedOrigins("*")
                .allowedMethods("*");
    }
}
```

### applicationContext 上下文

```java
@Component
public class SoulApplicationContextAware implements ApplicationContextAware {

    @Override
    public void setApplicationContext(final ApplicationContext applicationContext) throws BeansException {
        SpringBeanUtils.getInstance().setCfgContext((ConfigurableApplicationContext) applicationContext);
    }

}
```

## 分析表结构关系

![img](https://cdn.jsdelivr.net/gh/HoldDie/img1/20210116000349.png)

- 一个插件对于多个选择器，一个选择器又对应多个规则；

- 一个选择器对应多个选择条件，一个规则对应多个选择条件；

### 元数据概念

理解一下元数据 meta_data 各个字段含义

```sql
CREATE TABLE  IF NOT EXISTS `meta_data` (
  `id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'id',
  `app_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '应用名称',
  `path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '路径,不能重复',
  `path_desc` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '路径描述',
  `rpc_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'rpc类型',
  `service_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '服务名称',
  `method_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '方法名称',
  `parameter_types` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '参数类型 多个参数类型 逗号隔开',
  `rpc_ext` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'rpc的扩展信息，json格式',
  `date_created` datetime(0) NOT NULL COMMENT '创建时间',
  `date_updated` datetime(0) NOT NULL ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '更新时间',
  `enabled` tinyint(4) NOT NULL DEFAULT 0 COMMENT '启用状态',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;
```

`rpc_ext`字段,如果是dubbo类型的服务接口，如果服务接口设置了 group,version字段的时候，会存在这个字段.

- dubbo 类型 字段结构是 如下，那么存储的就是json格式的字符串.

```java
public static class RpcExt {

  private String group;

  private String version;

  private String loadbalance;

  private Integer retries;

  private Integer timeout;

}
```

### 字典配置

字典管理主要用来维护和管理公用数据字典

```sql
CREATE TABLE IF NOT EXISTS `soul_dict` (
   `id` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主键id',
   `type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '类型',
   `dict_code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '字典编码',
   `dict_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '字典名称',
   `dict_value` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '字典值',
   `desc` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '字典描述或备注',
   `sort` int(4) NOT NULL COMMENT '排序',
   `enabled` tinyint(4) DEFAULT NULL COMMENT '是否开启',
   `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
   `date_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
   PRIMARY KEY (`id`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 插件模板

```sql
CREATE TABLE IF NOT EXISTS `plugin_handle` (
  `id` varchar(128) NOT NULL,
  `plugin_id` varchar(128) NOT NULL COMMENT '插件id',
  `field` varchar(100) NOT NULL COMMENT '字段',
  `label` varchar(100) DEFAULT NULL COMMENT '标签',
  `data_type` smallint(6) NOT NULL DEFAULT '1' COMMENT '数据类型 1 数字 2 字符串 3 下拉框',
  `type` smallint(6) NULL COMMENT '类型,1 表示选择器，2 表示规则',
  `sort` int(4)  NULL COMMENT '排序',
  `ext_obj` varchar(1024) DEFAULT NULL COMMENT '额外配置（json格式数据）',
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `date_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `plugin_id_field_type` (`plugin_id`,`field`,`type`)
) ENGINE=InnoDB;
```

## 分析 Controller 处理逻辑

- AppAuthController：主要处理 App 权限控制；

- ConfigController：使用 HttpLongPollingDataChangedListener 轮询时，接收数据；
- DashboardUserController：用户管理；
- IndexController：domain 页面跳转；
- MetaDataController：MetaData 数据控制；
- PlatformController：用户登录和获取枚举值；
- PluginController：插件控制；
- PluginHandleController：插件 Handler 配置；
- RuleController：规则配置；
- SelectorController：选择器配置；
- SoulClientController：各种 SoulClient 的注册；
- SoulDictController：字典的增删改查；