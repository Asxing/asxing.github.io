---
title: SpringBoot-单元测试
author: HoldDie
tags: [SpringBoot,Junit,Test]
top: false
date: 2018-10-22 19:43:41
categories: SpringBoot
---

> 当你发现自己付出所有紧握的只是一个谎言，你会不会放手？ ——云间野鹤

#### 1、配置Maven依赖

```xml
<!-- 构建Restful API -->
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger2</artifactId>
    <version>2.6.0</version>
</dependency>
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger-ui</artifactId>
    <version>2.6.0</version>
</dependency>
```

#### 2、Swagger配置文件

```java
@Configuration    // 配置注解，自动在本类上下文加载一些环境变量信息
@EnableSwagger2   // 使swagger2生效
public class SwaggerConfig {

    @Bean
    public Docket swaggerSpringMvcPlugin() {

        ParameterBuilder ticketPar = new ParameterBuilder();
        List<Parameter> pars = new ArrayList<Parameter>();
        ticketPar.name("Authorization").description("Authorization Token")
            .modelRef(new ModelRef("string")).parameterType("header")
            .required(false).build();     //header中的ticket参数非必填，传空也可以
        pars.add(ticketPar.build());    //根据每个方法名也知道当前方法在设置什么参数

        return new Docket(DocumentationType.SWAGGER_2)
            .apiInfo(apiInfo())
            .groupName("business-api")
            .select()   // 选择那些路径和api会生成document
            .apis(RequestHandlerSelectors.basePackage("com.zeus.oem.controller"))
            .paths(PathSelectors.ant("/**"))
            //                .paths(paths())
            //.apis(RequestHandlerSelectors.any())  // 对所有api进行监控
            //.paths(PathSelectors.any())   // 对所有路径进行监控
            .build()
            .securitySchemes(securitySchemes())
            .globalOperationParameters(pars)
            .securityContexts(securityContexts());
    }

    @Profile({"dev","test"})
    @Bean
    public Docket createPigLetsApi() {
        return new Docket(DocumentationType.SWAGGER_2)
            .groupName("OEM分组").apiInfo(apiInfo()).select()
            .paths(PathSelectors.ant("/**"))
            .build();
    }

    private Predicate<String> paths() {
        return or(regex("/*"));
    }

    private List<ApiKey> securitySchemes() {
        return newArrayList(
            new ApiKey("clientId", "客户端ID", "header"),
            new ApiKey("clientSecret", "客户端秘钥", "header"),
            new ApiKey("accessToken", "客户端访问标识", "header"));
    }

    private List<SecurityContext> securityContexts() {
        return newArrayList(
            SecurityContext.builder()
            .securityReferences(defaultAuth())
            .forPaths(PathSelectors.regex("/*.*"))
            .build()
        );
    }

    List<SecurityReference> defaultAuth() {
        AuthorizationScope authorizationScope = new AuthorizationScope("global", "accessEverything");
        AuthorizationScope[] authorizationScopes = new AuthorizationScope[1];
        authorizationScopes[0] = authorizationScope;
        return newArrayList(
            new SecurityReference("clientId", authorizationScopes),
            new SecurityReference("clientSecret", authorizationScopes),
            new SecurityReference("accessToken", authorizationScopes));
    }

    private ApiInfo apiInfo() {
        return new ApiInfoBuilder()
            .title("Spring 中使用Swagger2构建RESTful API")
            .termsOfServiceUrl("https://holddie.com")
            .description("此API提供接口调用")
            .license("License Version 2.0")
            .licenseUrl("https://holddie.com")
            .version("2.0").build();
    }
}
```

#### 3、Controller 中使用注解添加 API 文档

```java
@Slf4j
@RestController
@RequestMapping(value = "oss")
public class AliyunOssController {/**
     * 根据fileName获取对应临时Token
     * @param file 文件对象
     * @return 对应Token
     * @author HoldDie
     * @email HoldDie@163.com
     * @date 2018/9/7 0:17
     */
    @PostMapping("/getToken")
    public Result getToken(@RequestBody JSONObject file) {
        //设置别名
        String roleSessionName = "door-001";
        //默认900s（15min），无需修改
        Long tokenExpireTime = 900L;
        // 此处必须为 HTTPS
        ProtocolType protocolType = ProtocolType.HTTPS;
        String fileName = UUID.randomUUID().toString() + "-" + file.get("fileName");
        //获取文件的字符串
        String stringpolicy = policy.replace("holddie", replace + fileName);
        //创建json对象
        JSONObject respMap = new JSONObject();
        try {
            AssumeRoleResponse stsResponse = assumeRole(accessKey,
                                                        accessKeySecret,
                                                        roleArn,
                                                        roleSessionName,
                                                        stringpolicy,
                                                        protocolType,
                                                        tokenExpireTime);
            if (stsResponse != null && stsResponse.getCredentials() != null) {
                //设置获取阿里云对象存储成功的值
                respMap.put(STATUS_CODE, "200");
                respMap.put("AccessKeyId", stsResponse.getCredentials().getAccessKeyId());
                respMap.put("AccessKeySecret", stsResponse.getCredentials().getAccessKeySecret());
                respMap.put("SecurityToken", stsResponse.getCredentials().getSecurityToken());
                respMap.put("Expiration", stsResponse.getCredentials().getExpiration());
                respMap.put("Path", baseCdn + fileName);
                respMap.put("Bucket", bucket);
                respMap.put("Key", store + "/" + fileName);
            } else {
                respMap.put(STATUS_CODE, "500");
                respMap.put("Message", "获取状态异常");
            }
            return ResultUtil.genOkObjectResult(respMap);
        } catch (ClientException e) {
            //设置获取阿里云对象存储失败的值
            respMap.put(STATUS_CODE, "500");
            log.error("阿里云图片上传客户端获取子账号异常：{}", e);
        }
        return ResultUtil.genFailedResult("获取验证失败");
    }
}
```

#### 4、SpringMVC 的配置

##### 4.1、针对 SpringBoot

```java
@Configuration
public class WebMvcConfig extends WebMvcConfigurationSupport {

    /**
     * 资源路径配置
     * @author HoldDie
     * @email HoldDie@163.com
     * @date 2018/8/13 11:01
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("swagger-ui.html")
            .addResourceLocations("classpath:/META-INF/resources/");

        registry.addResourceHandler("/webjars/**")
            .addResourceLocations("classpath:/META-INF/resources/webjars/");
    }
}
```

##### 4.2、针对传统 SpringMVC

###### 4.2.1、web.xml 配置文件

```xml
<servlet>
    <servlet-name>dispatcher</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <init-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>classpath*:/spring-mvc.xml</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
</servlet>
<servlet-mapping>
    <servlet-name>dispatcher</servlet-name>
    <url-pattern>*.do</url-pattern>
</servlet-mapping>
<servlet-mapping>
    <servlet-name>dispatcher</servlet-name>
    <url-pattern>/v2/api-docs</url-pattern>
</servlet-mapping>
<!--说明：Springmvc前端控制器扫描路径增加“/v2/api-docs”，用于扫描Swagger的 /v2/api-docs，否则 /v2/api-docs无法生效。-->
```

###### 4.2.1、spring-mvc.xml 添加自动扫描 Swagger

```xml
<!-- 使用 Swagger Restful API文档时，添加此注解 -->
<mvc:default-servlet-handler />
<mvc:annotation-driven/>
或者
<mvc:resources location="classpath:/META-INF/resources/" mapping="swagger-ui.html"/>
<mvc:resources location="classpath:/META-INF/resources/webjars/" mapping="/webjars/**"/>
```

#### 5、此时就可以访问

#### 6、接口添加 Token 授权

```java
@Bean
public Docket swaggerSpringMvcPlugin() {

    ParameterBuilder ticketPar = new ParameterBuilder();
    List<Parameter> pars = new ArrayList<Parameter>();
    ticketPar.name("Authorization").description("Authorization Token")
        .modelRef(new ModelRef("string")).parameterType("header")
        .required(false).build(); //header中的ticket参数非必填，传空也可以
    pars.add(ticketPar.build());    //根据每个方法名也知道当前方法在设置什么参数

    return new Docket(DocumentationType.SWAGGER_2)
        .apiInfo(apiInfo())
        .groupName("business-api")
        .select()   // 选择那些路径和api会生成document
        .apis(RequestHandlerSelectors.basePackage("com.zeus.oem.controller"))
        .paths(PathSelectors.ant("/**"))
        //.apis(RequestHandlerSelectors.any())  // 对所有api进行监控
        //.paths(PathSelectors.any())   // 对所有路径进行监控
        .build()
        .globalOperationParameters(pars);
}
```

#### 7、自定义 Swagger 请求访问路径

##### 7.1、下载 Swagger 源文件

###### 7.1.1、Github 下载源文件： https://github.com/swagger-api/swagger-ui/tree/2.x

###### 7.1.2、源代码中的dist文件夹防止到工程的 resource 目录下

###### 7.1.3、修改dist中的index.html文件

![image-20181022205912568](../../../../../../../../images/2018/10/image-20181022205912568.png)

##### 7.2、配置解析路径

SpringMVC 映射解析添加

```java
@Configuration
public class WebMvcConfig extends WebMvcConfigurationSupport {

    /**
     * 资源路径配置
     * @author HoldDie
     * @email HoldDie@163.com
     * @date 2018/8/13 11:01
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/dayin/dayin/swagger/**")
            .addResourceLocations("classpath:/swagger/");
    }
}
```

##### 7.3、resource下的 `swagger.properties` 配置

```properties
springfox.documentation.swagger.v2.path=/dayin/dayin/swagger
```

##### 7.4、Swagger 配置文件

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.context.annotation.PropertySource;
import springfox.documentation.builders.ApiInfoBuilder;
import springfox.documentation.builders.PathSelectors;
import springfox.documentation.builders.RequestHandlerSelectors;
import springfox.documentation.service.ApiInfo;
import springfox.documentation.spi.DocumentationType;
import springfox.documentation.spring.web.plugins.Docket;
import springfox.documentation.swagger2.annotations.EnableSwagger2;

/**
 * swagger2配置文件
 * @author HoldDie
 * @version 1.0.0
 * @email holddie@163.com
 * @date 2018/5/18 18:31
 */
@Configuration
@EnableSwagger2
@PropertySource("classpath:swagger.properties")
public class Swagger2Config {

    @Profile({"dev","test"})
    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.SWAGGER_2)
            .apiInfo(apiInfo())
            .select()
            .apis(RequestHandlerSelectors.basePackage("com.xxx.xxx.controller"))
            .paths(PathSelectors.ant("/**"))
            .build();
    }


    @Profile({"dev","test"})
    @Bean
    public Docket createPigLetsApi() {
        return new Docket(DocumentationType.SWAGGER_2)

            .groupName("OEM分组").apiInfo(apiInfo()).select()
            .paths(PathSelectors.ant("/**")).build();
    }
    @Profile({"dev","test"})
    @Bean
    public Docket createPigLetsApi12() {
        return new Docket(DocumentationType.SWAGGER_2)

            .groupName("OEM234分组").apiInfo(apiInfo()).select()
            .paths(PathSelectors.ant("/**")).build();
    }

    private ApiInfo apiInfo() {
        return new ApiInfoBuilder()
            .title("OEM Document by Swagger2")
            .description("好香~")
            .termsOfServiceUrl("https://www.holddie.com")
            .version("1.0.0")
            .build();
    }
}
```