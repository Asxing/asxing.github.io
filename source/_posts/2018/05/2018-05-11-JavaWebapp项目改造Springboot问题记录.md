---
title: JavaWebapp项目改造Springboot问题记录
tags: [SpringBoot]
date: 2018-05-11 09:27:03
categories: SpringBoot
---

岁月沉淀，苍生不过是一瞬间。在洪荒的潮流里，剑，劈开了一个时代。——柠烟夏季



## 问题记录

### 1、依赖 JAR

```java
java.lang.IllegalArgumentException: Invalid 'logbackConfigLocation' parameter: /opt/app/Oracle/Middleware/user_projects/domains/base_domain/servers/Server7005/tmp/_WL_user/acc_service_ca/bk1axn/war/WEB-INF/lib/_wl_cls_gen.jar!/logback.xml
```

#### 解决办法

```
Call mvn dependency:tree to see who is importing logback and who is importing slf4j-log4j, then exclude the one that you do not want
```

使用 `mvn` 依赖查看到底哪里使用了这种方式，然后对响应的 JAR 包，去除即可。

```shell
[INFO] |     |  +- org.apache.commons:commons-math3:jar:3.4.1:compile
[INFO] |     |  +- org.apache.httpcomponents:httpmime:jar:4.5.5:compile
[INFO] |     |  \- org.slf4j:jcl-over-slf4j:jar:1.7.25:compile
[INFO] |     +- org.codehaus.woodstox:stax2-api:jar:3.1.4:compile
[INFO] |     +- org.codehaus.woodstox:woodstox-core-asl:jar:4.4.1:compile
[INFO] |     |  \- javax.xml.stream:stax-api:jar:1.0-2:compile
[INFO] |     +- com.googlecode.xmemcached:xmemcached:jar:2.0.0:compile

[INFO] |     +- org.apache.zookeeper:zookeeper:jar:3.4.6:compile
[INFO] |     |  +- org.slf4j:slf4j-log4j12:jar:1.7.25:compile
[INFO] |     |  \- jline:jline:jar:0.9.94:compile

[INFO] |     +- org.imgscalr:imgscalr-lib:jar:4.2:compile
[INFO] |     +- commons-fileupload:commons-fileupload:jar:1.3.1:compile
[INFO] |     +- org.quartz-scheduler:quartz:jar:2.3.0:compile
[INFO] |     |  \- com.mchange:mchange-commons-java:jar:0.2.11:compile
```

定位jar所在的路径。

### 2、问题描述

web.xml 配置全部转成配置实现

#### 实现方式

应为使用的SpringBoot工程项目，所以自然的使用的 `Jar` 的形式进行打包运行，但是使用`Jar`的问题在于，都是使用注解进行完成的，但是对于原先在web.xml中自定的配置的listener，都是在ContextLoaderListener加载完成以后才会加载，然后直接使用Spring的getBean进行获取Bean，对Bean进行操作，但是这样会出现一个问题，就是并不知道所需要的Bean是否加载完成，对于使用各种注解，但是还是不能明确其加载顺序，这样导致，原先工程中，随处都是使用getBean的写法，改造太大了，同时寻求`War` 的形式进行部署，这样就是会继承一个 `SpringBootServletInitializer` 进行重写`Onstartup` 方法，此时就是类似熟悉的`web.xml`的声明的方式。

```java
public class ServletInitializer extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        return application.sources(ZeusWebApplication.class);
    }

    @Override
    public void onStartup(ServletContext servletContext) throws ServletException {
        this.logger = LogFactory.getLog(super.getClass());
        WebApplicationContext rootAppContext = createRootApplicationContext(servletContext);

        if (rootAppContext != null) {

            // 配置 Listener
            // servletContext.addListener(new ContextLoaderListener(rootAppContext));
            servletContext.addListener(new EopSessionListener());
            servletContext.addListener(new EopContextLoaderListener());
            servletContext.addListener(new KeplerContextLoaderListener());

            // 配置 Filter
            servletContext.addFilter("compressFilter",GZIPFilter.class)
                .addMappingForUrlPatterns(EnumSet.of(DispatcherType.REQUEST),false,"*.jsp","*.do","*.html","*.js","*.css");

            FilterRegistration.Dynamic encodingFilter = servletContext.addFilter("encodeFilter", CharacterEncodingFilter.class);
            encodingFilter.setInitParameter("encoding","UTF-8");
            encodingFilter.setInitParameter("forceEncoding","true");
            encodingFilter.addMappingForUrlPatterns(EnumSet.of(DispatcherType.REQUEST),false,"/*");

            servletContext.addFilter("xssSqlFilter",XssFilter.class)
                .addMappingForUrlPatterns(EnumSet.of(DispatcherType.REQUEST),false,"/*");

            FilterRegistration.Dynamic dispatcherFilter = servletContext.addFilter("dispatchFilter",DispatcherFilter.class);
            dispatcherFilter.addMappingForUrlPatterns(EnumSet.of(DispatcherType.REQUEST),false,"/*");

            // 配置 Servlet
            AnnotationConfigWebApplicationContext webContext = new AnnotationConfigWebApplicationContext();
            webContext.setConfigLocations("com.enation","com.ncfgroup","com.zeus");
            ServletRegistration.Dynamic servlet = servletContext.addServlet("springServlet",new DispatcherServlet(webContext));
            servlet.setLoadOnStartup(1);
            servlet.addMapping("*.do","/swagger-resources","/v2/api-docs","/swagger-resources/configuration/ui","/swagger-resources/configuration/security");

            servletContext.addServlet("validServlet",com.enation.eop.sdk.utils.ValidCodeServlet.class)
                .addMapping("/validcode.do");

        } else {
            this.logger.debug(
                "No ContextLoaderListener registered, as createRootApplicationContext() did not return an application context");
        }

    }
}

```

对于上面中的 `createRootApplicationContext(servletContext)` 这一步我理解的就是类似 `ContextLoaderListener` 的作用，加载所有的Bean，Spring 的操作，之后进行原先的操作。

```java
servletContext.addListener(new ContextLoaderListener(rootAppContext));
```

不需要再写了，否则就会声明重复咯，上面的已经包含了这步操作。

### 3、对于SpringMVC的配置

```java
@EnableWebMvc
@Configuration
@ComponentScan(value = {"com.xxx","com.xxx","com.xxx"})
public class SpringMvcConfig extends WebMvcConfigurerAdapter{

    @Bean
    public MappingJackson2HttpMessageConverter mappingJackson2HttpMessageConverter(){
        List<MediaType> list = new LinkedList<>();
        list.add(MediaType.TEXT_HTML);
        list.add(MediaType.APPLICATION_JSON_UTF8);
        MappingJackson2HttpMessageConverter mappingJackson2HttpMessageConverter = new MappingJackson2HttpMessageConverter();
        mappingJackson2HttpMessageConverter.setSupportedMediaTypes(list);
        return mappingJackson2HttpMessageConverter;
    }

    @Bean
    public FreeMarkerViewResolver freeMarkerViewResolver(){
        FreeMarkerViewResolver freeMarkerViewResolver = new FreeMarkerViewResolver();
        freeMarkerViewResolver.setViewClass(org.springframework.web.servlet.view.freemarker.FreeMarkerView.class);
        freeMarkerViewResolver.setSuffix(".html");
        freeMarkerViewResolver.setContentType("text/html;charset=UTF-8");
        freeMarkerViewResolver.setExposeRequestAttributes(true);
        freeMarkerViewResolver.setExposeSessionAttributes(true);
        freeMarkerViewResolver.setExposeSpringMacroHelpers(true);
        return freeMarkerViewResolver;
    }

    @Bean
    public CommonsMultipartResolver commonsMultipartResolver() throws IOException {
        CommonsMultipartResolver commonsMultipartResolver = new CommonsMultipartResolver();
        commonsMultipartResolver.setDefaultEncoding("UTF-8");
        commonsMultipartResolver.setMaxUploadSize(4096000);
        commonsMultipartResolver.setUploadTempDir(new FileSystemResource("/upload"));
        commonsMultipartResolver.setResolveLazily(true);
        return commonsMultipartResolver;
    }

    @Bean
    MethodValidationPostProcessor methodValidationPostProcessor(){
        return new MethodValidationPostProcessor();
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/**").addResourceLocations("/");
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new ChangeRequestInterceptor());
        registry.addInterceptor(new UrlFastRequestIntercepter());
        registry.addInterceptor(new CheckLoginRequestIntercepter());
        registry.addInterceptor(new DemoSiteIntercepter());
    }

}
```

### 4、通用标准Beean注入

```java
@Configuration
public class XxlJobConfig {
    private Logger logger = LoggerFactory.getLogger(XxlJobConfig.class);

    @Value("${xxl.job.admin.addresses}")
    private String adminAddresses;

    @Value("${xxl.job.executor.appname}")
    private String appName;

    @Value("${xxl.job.executor.ip}")
    private String ip;

    @Value("${xxl.job.executor.port}")
    private int port;

    @Value("${xxl.job.accessToken}")
    private String accessToken;

    @Value("${xxl.job.executor.logpath}")
    private String logPath;

    @Bean(name = "xxlJob",initMethod = "start", destroyMethod = "destroy")
    public XxlJobExecutor xxlJobExecutor() {
        logger.info(">>>>>>>>>>> xxl-job config init.");
        XxlJobExecutor xxlJobExecutor = new XxlJobExecutor();
        xxlJobExecutor.setAdminAddresses(adminAddresses);
        xxlJobExecutor.setAppName(appName);
        xxlJobExecutor.setIp(ip);
        xxlJobExecutor.setPort(port);
        xxlJobExecutor.setAccessToken(accessToken);
        xxlJobExecutor.setLogPath(logPath);
        return xxlJobExecutor;
    }

}
```

一般都是上面引入配置参数，然后一个方法进行参数设置，同时可以声明`init`和`destory`方法。

### 5、访问静态文件

问题：自己虽然已经改成的SpringBoot的形式，但是问题来了，原先的页面进行打包以后放哪里的了，我程序原先的读取路径，会找不到了，接下来还需要如下设置。

- 首先在跟 java 同级目录下建一个webapp的目录
- 声明一个配置文件继承 `WebMvcConfigurerAdapter` 然后重写父类的 `addResourcehandlers` 方法

```java
@Override
public void addResourceHandlers(ResourceHandlerRegistry registry) {
    registry.addResourceHandler("/**").addResourceLocations("/");
}
```



配置写法：

```java
@Configuration
public class WebConfig extends WebMvcConfigurerAdapter{
    @Bean
    public FilterRegistrationBean getDemoFilter(){
        DemoFilter demoFilter=new DemoFilter();
        FilterRegistrationBean registrationBean=new FilterRegistrationBean();
        registrationBean.setFilter(demoFilter);
        List<String> urlPatterns=new ArrayList<String>();
        urlPatterns.add("/*");//拦截路径，可以添加多个
        registrationBean.setUrlPatterns(urlPatterns);
        registrationBean.setOrder(1);
        return registrationBean;
    }
    @Bean
    public ServletRegistrationBean getDemoServlet(){
        DemoServlet demoServlet=new DemoServlet();
        ServletRegistrationBean registrationBean=new ServletRegistrationBean();
        registrationBean.setServlet(demoServlet);
        List<String> urlMappings=new ArrayList<String>();
        urlMappings.add("/demoservlet");////访问，可以添加多个
        registrationBean.setUrlMappings(urlMappings);
        registrationBean.setLoadOnStartup(1);
        return registrationBean;
    }
    @Bean
    public ServletListenerRegistrationBean<EventListener> getDemoListener(){
        ServletListenerRegistrationBean<EventListener> registrationBean
            =new ServletListenerRegistrationBean<>();
        registrationBean.setListener(new DemoListener());
        //		registrationBean.setOrder(1);
        return registrationBean;
    }
}
```



## 技巧总结

- 对于 `xml` 中的 `Bean` 采用 `configuration` 注解注入实体的属性
- 对于 SpringMVC 加载流程中的 Bean，可以采用集中式的注解，全部声明进行，参数也好设置。
- 对于Bean方法的改造，目前只会使用new一个实例，然后进行属性值的添加，然后并不会销毁方法如何书写。

### 参考链接：

- https://www.boraji.com/spring-boot-using-servlet-filter-and-listener-example-1
- https://blog.csdn.net/songhaifengshuaige/article/details/54138023
- https://www.jianshu.com/p/cb5cb5937686
- https://examples.javacodegeeks.com/enterprise-java/spring/boot/spring-boot-configuration-tutorial/
- http://septem.iteye.com/blog/1117445
- https://www.cnblogs.com/smiler/p/6857167.html

![](https://www.holddie.com/img/20200105154901.jpg)