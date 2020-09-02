---
title: SpringBoot-国际化（五）
author: HoldDie
tags: [SpringBoot,I18n]
top: false
date: 2019-02-19 19:43:41
categories: SpringBoot
---

**在最深沉的夜里，连自己的影子都会离你而去。**

目前调研资料

https://blog.csdn.net/haihui_yang/article/details/83987839

https://blog.csdn.net/qq_42564846/article/details/85986481

https://blog.csdn.net/qq_28929589/article/details/79192054

### 1、Maven 依赖：

```xml
spring.messages.encoding=utf_8
spring.messages.basename=i18n/messages/messages
```

### 2、请求头中添加标识

```java
@Configuration
public class LocaleConfiguration implements WebMvcConfigurer {

    @Bean(name = "localeResolver")
    public LocaleResolver localeResolver() {
        AcceptHeaderLocaleResolver acceptHeaderLocaleResolver = new AcceptHeaderLocaleResolver();
        acceptHeaderLocaleResolver.setDefaultLocale(Locale.CHINA);
        return acceptHeaderLocaleResolver;
    }

}
```

### 3、创建异常时消息解析

> 思路：
>
> 1、使用application获取对应的messageResource
>
> 2、直接去查询对应的消息
>
> 3、判空之后，直接返回

#### 3.1、声明注册获取实体Bean

```java
@Component
@Lazy(false)
public class ApplicationContextRegister implements ApplicationContextAware {
    private static final Logger LOGGER = LoggerFactory.getLogger(ApplicationContextRegister.class);
    private static ApplicationContext APPLICATION_CONTEXT;

    /**
     * 设置spring上下文  *  * @param applicationContext spring上下文  * @throws BeansException
     */
    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        LOGGER.debug("ApplicationContext registed-->{}", applicationContext);
        APPLICATION_CONTEXT = applicationContext;
    }

    public static ApplicationContext getApplicationContext() {
        return APPLICATION_CONTEXT;
    }
}
```

#### 3.2、定义 i18n 对应返回标识枚举

```java
public enum I18nMessageEnum {

    ERRORTESTTILTE("error.title"),
    ERRORTESTSUBTITLE("error.subtitle");
    private String messageName;

    I18nMessageEnum(String messageName) {
        this.messageName = messageName;
    }

    public String getMessageName() {
        return messageName;
    }

    public void setMessageName(String messageName) {
        this.messageName = messageName;
    }

    public static I18nMessageEnum getIfPresent(String name) {
        return Enums.getIfPresent(I18nMessageEnum.class, name).orNull();
    }
}
```

#### 3.3、获取对应消息

```java
public class I18nService {

    private static I18nService instance;

    private final MessageSource messageSource;

    private I18nService() {
        MessageSource messageSource = (MessageSource) ApplicationContextRegister.getApplicationContext().getBean("messageSource");
        this.messageSource = messageSource;
    }

    public static I18nService getInstance() {
        if (instance == null) {
            instance = new I18nService();
        }
        return instance;
    }

    public static String getMessage(String key) {
        I18nEnum i18nEnum = I18nEnum.getIfPresent(key);
        if (Objects.nonNull(i18nEnum)) {
            Locale locale = LocaleContextHolder.getLocale();
            key = getInstance().messageSource.getMessage(i18nEnum.getMessageName(), null, locale);
        }
        return key;
    }

    public static String getMessage(I18nEnum i18nEnum) {
        Locale locale = LocaleContextHolder.getLocale();
        String message = getInstance().messageSource.getMessage(i18nEnum.getMessageName(), null, locale);
        return message;
    }
}
```

#### 3.4、使用

```java
I18nService.getMessage(i18nEnum)
```

### 4、返回消息时封装

> 思路：
>
> 1、直接切返回抽象
>
> 2、对异常或者返回实体进行解析

```java
import cn.jiguang.common.utils.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;
import org.springframework.web.servlet.support.RequestContext;

import javax.servlet.http.HttpServletRequest;

@ControllerAdvice(basePackages = {"com.happycheer.newdaichao"})
public class I18nResponseBodyAdvice implements ResponseBodyAdvice<Object> {
    protected Logger logger = LoggerFactory.getLogger(this.getClass());

    @Override
    public Object beforeBodyWrite(Object obj, MethodParameter method,
                                  MediaType type, Class<? extends HttpMessageConverter<?>> converter,
                                  ServerHttpRequest request, ServerHttpResponse response) {
        try {
            if (obj instanceof BadRequestAlertException) {
                //                AbstractThrowableProblem result = (AbstractThrowableProblem) obj;
                //                String title = result.getTitle();
                HttpServletRequest req = ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes()).getRequest();
                String i18nMsg = getMessage(req, "email.activation.title");
                if (!StringUtils.isEmpty(i18nMsg)) {
                    obj = new BadRequestAlertException(i18nMsg);
                }
            }
        } catch (Exception e) {
            logger.error("返回值国际化拦截异常", e);
        }
        return obj;
    }

    @Override
    public boolean supports(MethodParameter arg0,
                            Class<? extends HttpMessageConverter<?>> arg1) {
        return true;
    }

    /**
     * 返回国际化的值
     * @param request
     * @param key
     * @return
     */
    public String getMessage(HttpServletRequest request, String key) {
        String value;
        try {
            RequestContext requestContext = new RequestContext(request);
            value = requestContext.getMessage(key);
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
            value = "";
        }
        return value;
    }
}
```