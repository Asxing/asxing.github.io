---
title: SpringBoot-优雅日志（五）
author: HoldDie
tags: [SpringBoot,Log,Standard]
top: false
date: 2019-01-08 19:43:41
categories: SpringBoot
---



**行走在两个世界的边缘，得到更多。——毛穿云**

### 一、背景

> 随着业务不断增加，不同的业务在不同的环境中，输入日志格式不一，再由于现有的业务（阿里云），根据日志进行报警（😳），就有必要再对日志进行多唠叨一句。

### 二、分类

- 一种是所有交易都记录的系统基础日志，日志中会包含系统时间、请求返回报文、用户名等等信息；
- 一种是业务相关的逻辑日志。

### 作用：

- #### 查看程序当前运行状态

- #### 查看程序历史运行轨迹

- #### 排查系统问题

- #### 优化系统性能

- #### 安全审计的基石

### 三、打日志要点

> 对于逻辑日志，我们应在代码分支的地方记录分支条件的日志。

- 在常用的日志中，分为两类：日志框架（commons-logging、SLF4J）、实际使用日志（log4j、logback）。

- 推荐使用 `slf4j + logback`。当然也可以使用`slf4j + log4j`、`commons-logging + log4j` 这两种日志组合框架。

- #### 日志优先级别标准顺序为：

  > ALL < TRACE < DEBUG < INFO < WARN < ERROR < FATAL < OFF

- #### 正确使用日志

```java
private static final Logger log = LoggerFactory.getLogger(this.getClass());
```

- ##### 使用参数化形式`{}`占位，`[]` 进行参数隔离

```java
log.debug("Save order with order no：[{}], and order amount：[{}]");
```

- #### 输出日志不同级别

  - ERROR（错误）

  > 一般用来记录程序中发生的任何异常错误信息（Throwable），或者是记录业务逻辑出错。

  - WARN（警告）

  > 一般用来记录一些用户输入参数错误、

  - INFO（信息）

  > 这个也是平时用的最低的，也是默认的日志级别，用来记录程序运行中的一些有用的信息。如程序运行开始、结束、耗时、重要参数等信息，需要注意有选择性的有意义的输出，到时候自己找问题看一堆日志却找不到关键日志就没意义了。

  - DEBUG（调试）

  > 这个级别一般记录一些运行中的中间参数信息，只允许在开发环境开启，选择性在测试环境开启。

- #### 不要使用 `System.out.print..`

- #### 不要使用 `e.printStackTrace()`

- #### 不要抛出异常后又输出日志

- #### 不要使用具体的日志实现类

- #### 没有输出全部错误信息

```java
try {
    // ...
} catch (Exception e) {
    // 错误
    LOG.error('XX 发生异常', e.getMessage());

    // 正确
    LOG.error('XX 发生异常', e);
}
```

- #### 不要使用错误的日志级别

- #### 不要在千层循环中打印日志

- #### 禁止在线上环境开启 `debug`

### 四、日志注解环绕

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface SysLog {

    String value() default "";
}

@Aspect
@Component
public class SysLogAspect {
    @Autowired
    private SysLogService sysLogService;
    //定义切入点Pointcut
    @Pointcut("@annotation(com.monkey01.log.aspect.SysLog)")
    public void logPointCut() {
    }

    @Around("logPointCut()")
    public Object around(ProceedingJoinPoint point) throws Throwable {
        long beginTime = System.currentTimeMillis();
        //执行业务逻辑方法
        Object result = point.proceed();
        //执行时长(毫秒)
        long time = System.currentTimeMillis() - beginTime;

        //保存日志
        saveSysLog(point, time);

        return result;
    }

    private void saveSysLog(ProceedingJoinPoint joinPoint, long time) {
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();

        SysLogEntity sysLog = new SysLogEntity();
        SysLog syslog = method.getAnnotation(SysLog.class);
        if(syslog != null){
            //注解上的描述
            sysLog.setOperation(syslog.value());
        }

        //请求的方法名
        String className = joinPoint.getTarget().getClass().getName();
        String methodName = signature.getName();
        sysLog.setMethod(className + "." + methodName + "()");

        //请求的参数
        Object[] args = joinPoint.getArgs();
        try{
            String params = new Gson().toJson(args[0]);
            sysLog.setParams(params);
        }catch (Exception e){

        }

        sysLog.setTime(time);
        sysLog.setCreateDate(new Date());
        //保存系统日志
        sysLogService.save(sysLog);
    }
}
```

### 五、日志服务

> 当然我们最好的就是使用日志服务，这样兼顾不同服务。

### 六、自定义日志