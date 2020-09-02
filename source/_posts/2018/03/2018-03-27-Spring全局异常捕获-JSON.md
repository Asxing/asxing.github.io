---
title: Spring全局异常捕获-JSON
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Java
  - Spring
  - Exception
  - SpringBoot
date: 2018-03-27 21:32:16
password:
summary:  
categories: Exception
---

异常，要全局异常，SpringBoot ，实现 Json 和 视图 通杀版。



### Spring 统一处理异常有三种方式

#### 使用 @ExceptionHandler 注解

```java
@Controller      
public class GlobalController {               

    /**    
    * 用于处理异常的    
    * @return    
    */      
    @ExceptionHandler({MyException.class})       
    public String exception(MyException e) {       
        System.out.println(e.getMessage());       
        e.printStackTrace();       
        return "exception";       
    }       

    @RequestMapping("test")       
    public void test() {       
        throw new MyException("出错了！");       
    }                    
} 
```

该方法需要在每个类中处理异常，不适合全局异常处理。

#### 实现 HandlerExceptionResolver 接口

```java
@Component  
public class MyExceptionResolver implements HandlerExceptionResolver {

    @Override
    public ModelAndView resolveException(HttpServletRequest request,
                                         HttpServletResponse response, Object handler, Exception ex) {

        System.out.println("This is exception handler method!");  
        return null;  
    }
} 
```

在Spring MVC中，所有用于处理在请求映射和请求处理过程中抛出的异常的类，都要实现`HandlerExceptionResolver`接口。`AbstractHandlerExceptionResolver`实现该接口和`Orderd`接口，是HandlerExceptionResolver类的实现的基类。`ResponseStatusExceptionResolver`等具体的异常处理类均在`AbstractHandlerExceptionResolver`之上，实现了具体的异常处理方式。一个基于Spring MVC的Web应用程序中，可以存在多个实现了`HandlerExceptionResolver`的异常处理类，他们的执行顺序，由其order属性决定, order值越小，越是优先执行, 在执行到第一个返回不是null的ModelAndView的Resolver时，不再执行后续的尚未执行的Resolver的异常处理方法。

![](https://www.holddie.com/img/20200105151938.png)

继承 AbstractHandlerExceptionResolver 类实现全局异常处理

```java
public class RestExceptionHandler extends AbstractHandlerExceptionResolver implements InitializingBean {
    @Override
    public void afterPropertiesSet() throws Exception {

    }

    @Override
    protected ModelAndView doResolveException(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        return null;
    }
}
```

#### 使用 @ControllerAdvice 注解

```java
@Slf4j
@ControllerAdvice
public class ExceptionHandlerBean  extends ResponseEntityExceptionHandler {

    /**
     * 数据找不到异常
     * @param ex
     * @param request
     * @return
     * @throws IOException
     */
    @ExceptionHandler({DataNotFoundException.class})
    public ResponseEntity<Object> handleDataNotFoundException(RuntimeException ex, WebRequest request) throws IOException {
        return getResponseEntity(ex,request,ReturnStatusCode.DataNotFoundException);
    }

    /**
     * 根据各种异常构建 ResponseEntity 实体. 服务于以上各种异常
     * @param ex
     * @param request
     * @param specificException
     * @return
     */
    private ResponseEntity<Object> getResponseEntity(RuntimeException ex, WebRequest request, ReturnStatusCode specificException) {

        ReturnTemplate returnTemplate = new ReturnTemplate();
        returnTemplate.setStatusCode(specificException);
        returnTemplate.setErrorMsg(ex.getMessage());

        return handleExceptionInternal(ex, returnTemplate,
                                       new HttpHeaders(), HttpStatus.OK, request);
    }

}
```

@ControllerAdvice + @ExceptionHandler 也可以实现全局的异常处理，继承 ResponseEntityException 类来实现全局异常捕获，并且可以返回自定义Json。

### 自己的实现方式：

SpringHandlerException 主要实现类：

```java
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.serializer.SerializerFeature;
import com.alibaba.fastjson.support.config.FastJsonConfig;
import com.alibaba.fastjson.support.spring.FastJsonJsonView;
import com.didispace.utils.HttpExceptionEnum;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.HttpMediaTypeNotAcceptableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.handler.AbstractHandlerExceptionResolver;
import org.springframework.web.servlet.mvc.multiaction.NoSuchRequestHandlingMethodException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.Map;

/**
 * @author yangze1
 * @version 1.0.0
 * @email holddie@163.com
 * @date 2018/3/27 20:05
 */
@ControllerAdvice
class SpringHandlerExceptionResolver extends AbstractHandlerExceptionResolver {

    private int order = 1;

    public void setOrder(int order) {
        this.order = order;
    }

    public int getOrder() {
        return this.order;
    }

    private static Logger logger = LoggerFactory.getLogger(SpringHandlerExceptionResolver.class);

    @Override
    public ModelAndView resolveException(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        ModelAndView mv = specialExceptionResolve(ex, request);
        if (null == mv) {
            String message = "系统异常，请联系管理员";
            //BaseSystemException是我自定义的异常基类，继承自RuntimeException
            if (ex instanceof BaseSystemException) {
                message = ex.getMessage();
            }
            mv = errorResult(message, "/error", request);
        }
        return mv;
    }

    @Override
    protected ModelAndView doResolveException(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, Object o, Exception e) {
        return null;
    }


    /**
     * 这个方法是拷贝 {@link org.springframework.web.servlet.mvc.support.DefaultHandlerExceptionResolver#doResolveException},
     * 加入自定义处理，实现对400， 404， 405， 406， 415， 500(参数问题导致)， 503的处理
     *
     * @param ex      异常信息
     * @param request 当前请求对象(用于判断当前请求是否为ajax请求)
     * @return 视图模型对象
     */
    private ModelAndView specialExceptionResolve(Exception ex, HttpServletRequest request) {
        try {
            if (ex instanceof NoSuchRequestHandlingMethodException
                || ex instanceof NoHandlerFoundException) {
                return result(HttpExceptionEnum.NOT_FOUND_EXCEPTION, request);
            }
            else if (ex instanceof HttpRequestMethodNotSupportedException) {
                return result(HttpExceptionEnum.NOT_SUPPORTED_METHOD_EXCEPTION, request);
            }
            else if (ex instanceof HttpMediaTypeNotSupportedException) {
                return result(HttpExceptionEnum.NOT_SUPPORTED_MEDIA_TYPE_EXCEPTION, request);
            }
            else if (ex instanceof HttpMediaTypeNotAcceptableException) {
                return result(HttpExceptionEnum.NOT_ACCEPTABLE_MEDIA_TYPE_EXCEPTION, request);
            }
            //            else if (ex instanceof MissingPathVariableException) {
            //                return result(HttpExceptionEnum.NOT_SUPPORTED_METHOD_EXCEPTION, request);
            //            }
            //            else if (ex instanceof MissingServletRequestParameterException) {
            //                return result(HttpExceptionEnum.MISSING_REQUEST_PARAMETER_EXCEPTION, request);
            //            }
            //            else if (ex instanceof ServletRequestBindingException) {
            //                return result(HttpExceptionEnum.REQUEST_BINDING_EXCEPTION, request);
            //            }
            //            else if (ex instanceof ConversionNotSupportedException) {
            //                return result(HttpExceptionEnum.NOT_SUPPORTED_CONVERSION_EXCEPTION, request);
            //            }
            //            else if (ex instanceof TypeMismatchException) {
            //                return result(HttpExceptionEnum.TYPE_MISMATCH_EXCEPTION, request);
            //            }
            //            else if (ex instanceof HttpMessageNotReadableException) {
            //                return result(HttpExceptionEnum.MESSAGE_NOT_READABLE_EXCEPTION, request);
            //            }
            //            else if (ex instanceof HttpMessageNotWritableException) {
            //                return result(HttpExceptionEnum.MESSAGE_NOT_WRITABLE_EXCEPTION, request);
            //            }
            //            else if (ex instanceof MethodArgumentNotValidException) {
            //                return result(HttpExceptionEnum.NOT_VALID_METHOD_ARGUMENT_EXCEPTION, request);
            //            }
            //            else if (ex instanceof MissingServletRequestPartException) {
            //                return result(HttpExceptionEnum.MISSING_REQUEST_PART_EXCEPTION, request);
            //            }
        } catch (Exception handlerException) {
            logger.warn("Handling of [" + ex.getClass().getName() + "] resulted in Exception", handlerException);
        }
        return null;
    }

    /**
     * 判断是否ajax请求
     *
     * @param request 请求对象
     * @return true:ajax请求  false:非ajax请求
     */
    private boolean isAjax(HttpServletRequest request) {
        return "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"));
    }

    /**
     * 返回错误信息
     *
     * @param message 错误信息
     * @param url     错误页url
     * @param request 请求对象
     * @return 模型视图对象
     */
    private ModelAndView errorResult(String message, String url, HttpServletRequest request) {
        logger.warn("请求处理失败，请求url=[{}], 失败原因 : {}", request.getRequestURI(), message);
        if (isAjax(request)) {
            return jsonResult(500, message);
        } else {
            return normalResult(message, url);
        }
    }

    /**
     * 返回异常信息
     *
     * @param httpException 异常信息
     * @param request 请求对象
     * @return 模型视图对象
     */
    private ModelAndView result(HttpExceptionEnum httpException, HttpServletRequest request) {
        logger.warn("请求处理失败，请求url=[{}], 失败原因 : {}", request.getRequestURI(), httpException.getMessage());
        if (isAjax(request)) {
            return jsonResult(httpException.getCode(), httpException.getMessage());
        } else {
            return normalResult(httpException.getMessage(), "/error");
        }
    }

    /**
     * 返回错误页
     *
     * @param message 错误信息
     * @param url     错误页url
     * @return 模型视图对象
     */
    private ModelAndView normalResult(String message, String url) {
        Map<String, String> model = new HashMap<String, String>();
        model.put("errorMessage", message);
        return new ModelAndView(url, model);
    }

    /**
     * 返回错误数据
     *
     * @param message 错误信息
     * @return 模型视图对象
     */
    private ModelAndView jsonResult(int code, String message) {
        ModelAndView mv = new ModelAndView();
        FastJsonJsonView view = new FastJsonJsonView();
        FastJsonConfig fastJsonConfig = new FastJsonConfig();
        fastJsonConfig.setSerializerFeatures(SerializerFeature.PrettyFormat);
        fastJsonConfig.setCharset(Charset.forName("UTF8"));
        view.setFastJsonConfig(fastJsonConfig);
        Map map = new HashMap(16);
        map.put("code",code);
        map.put("message",message);
        view.setAttributesMap((JSONObject) JSON.toJSON(map));
        mv.setView(view);
        return mv;
    }
}

```

自定义异常类：

```java
public class BaseSystemException extends RuntimeException{
    public BaseSystemException(String value){
        super(value);
    }
}
```

常见异常封装

```java
package com.didispace.utils;

/**
 * @author yangze1
 * @version 1.0.0
 * @email holddie@163.com
 * @date 2018/3/27 20:12
 */
public enum HttpExceptionEnum {
    NOT_SUPPORTED_METHOD_EXCEPTION(124,"message not writable exception"),
    NOT_ACCEPTABLE_MEDIA_TYPE_EXCEPTION(125,"message not writable exception"),
    NOT_SUPPORTED_MEDIA_TYPE_EXCEPTION(126,"message not writable exception"),
    NOT_FOUND_EXCEPTION(127,"message not writable exception");

    int code;

    String message;

    HttpExceptionEnum(int code,String message){
        this.code = code;
        this.message = message;
    }

    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}

```

Controller 类测试：

```java
@Controller
public class HelloController {

    @RequestMapping("/hello")
    public String hello() throws Exception {
        throw new Exception("发生错误");
    }

    @RequestMapping("/json")
    public String json(HttpServletRequest request) throws NoSuchRequestHandlingMethodException {
        throw new BaseSystemException("发生错误2");
//        throw new NoSuchRequestHandlingMethodException(request);
    }
}
```



```java
public class CustomSimpleMappingExceptionResolver extends
    SimpleMappingExceptionResolver {

    @Override
    protected ModelAndView doResolveException(HttpServletRequest request,
                                              HttpServletResponse response, Object handler, Exception ex) {
        // Expose ModelAndView for chosen error view.
        String viewName = determineViewName(ex, request);
        if (!(request.getHeader("accept").indexOf("application/json") > -1 || (request
                                                                               .getHeader("X-Requested-With") != null && request
                                                                               .getHeader("X-Requested-With").indexOf("XMLHttpRequest") > -1))) {
            // 如果不是异步请求
            // Apply HTTP status code for error views, if specified.
            // Only apply it if we're processing a top-level request.
            Integer statusCode = determineStatusCode(request, viewName);
            if (statusCode != null) {
                applyStatusCodeIfPossible(request, response, statusCode);
            }
            return getModelAndView(viewName, ex, request);
        } else {// JSON格式返回
            try {
                PrintWriter writer = response.getWriter();
                writer.write(ex.getMessage());
                writer.flush();
            } catch (IOException e) {
                e.printStackTrace();
            }
            return null;

        }
    }
}
```



### 参考链接

- http://daobin.wang/2017/05/spring-restful-api/
- https://blog.csdn.net/king_is_everyone/article/details/53080851
- https://blog.csdn.net/qq_28988969/article/details/79215167
- https://blog.csdn.net/zhangdaiscott/article/details/20832747

