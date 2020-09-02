---
title: SpringBoot参数校验规则
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Java
  - Validate
  - Redis
  - Transaction
  - Annotation
date: 2018-03-26 21:32:16
password:
summary:  
categories: Validate
---

参数校验不容小觑，不然你真会哭的。



### 参数规则分类

#### 以String、Integer等简单引用类型传入的参数

- 只需要在需要校验的参数前面添加校验注解和提示语

#### 以封装类型传入的参数

- 需要在controller 上添加 @Validated 注解
- 需要在参数实体前加 @Valid

#### 当传递不同实体参数名相同

提交的表单：

```html
<form action="/test.action" method="post">  
    <input name="user.name">  
    <input name="acc.name">  
    <input type="submit">  
</form> 
```

对应的 Controller 为：

```java
@RequestMapping("/test.action")
public void test(Account account, User user){
    System.out.println(user);
    System.out.println(account);
} 
```

这里要用到@InitBinder这个注解，详细的解释可以找相关资料，这里只讲怎么用。在Controller类添加下面两个方法，作用是把指定的开头标识符的值赋给成指定名字的对象

```java
@InitBinder("account")  
public void initAccountBinder(WebDataBinder binder) {  
    binder.setFieldDefaultPrefix("acc.");  
} 

@InitBinder("user")  
public void initUserBinder(WebDataBinder binder) {  
    binder.setFieldDefaultPrefix("user.");  
}
```

然后把action方法改造成下面这样就可以了。

### 一些常用的校验注解

| 验证注解                                    | 验证的数据类型                                               | 说明                                                         |
| ------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| @AssertFalse                                | Boolean,boolean                                              | 验证注解的元素值是false                                      |
| @AssertTrue                                 | Boolean,boolean                                              | 验证注解的元素值是true                                       |
| @NotNull                                    | 任意类型                                                     | 验证注解的元素值不是null                                     |
| @Null                                       | 任意类型                                                     | 验证注解的元素值是null                                       |
| @Min(value=值)                              | BigDecimal，BigInteger,byte,short,int,long，等任何Number或CharSequence（存储的是数字）子类型 | 验证注解的元素值大于等于@Min指定的value值                    |
| @Max（value=值）                            | 和@Min要求一样                                               | 验证注解的元素值小于等于@Max指定的value值                    |
| @DecimalMin(value=值)                       | 和@Min要求一样                                               | 验证注解的元素值大于等于@DecimalMin指定的value值             |
| @DecimalMax(value=值)                       | 和@Min要求一样                                               | 验证注解的元素值小于等于@DecimalMax指定的value值             |
| @Digits(integer=整数位数,fraction=小数位数) | 和@Min要求一样                                               | 验证注解的元素值的整数位数和小数位数上限                     |
| @Size(min=下限,max=上限)                    | 字符串、Collection、Map、数组等                              | 验证注解的元素值的在min和max（包含）指定区间之内，如字符长度、集合大小 |
| @Past                                       | java.util.Date,java.util.Calendar;JodaTime类库的日期类型     | 验证注解的元素值（日期类型）比当前时间早                     |
| @Future                                     | 与@Past要求一样                                              | 验证注解的元素值（日期类型）比当前时间晚                     |
| @NotBlank                                   | CharSequence子类型                                           | 验证注解的元素值不为空（不为null、去除首位空格后长度为0），不同于@NotEmpty，@NotBlank只应用于字符串且在比较时会去除字符串的首位空格 |
| @Length(min=下限,max=上限)                  | CharSequence子类型                                           | 验证注解的元素值长度在min和max区间内                         |
| @NotEmpty                                   | CharSequence子类型、Collection、Map、数组                    | 验证注解的元素值不为null且不为空（字符串长度不为0、集合大小不为0） |
| @Range(min=最小值,max=最大值)               | BigDecimal,BigInteger,CharSequence,byte,short,int,long等原子类型和包装类型 | 验证注解的元素值在最小值和最大值之间                         |
| @Email(regexp=正则表达式,flag=标志的模式)   | CharSequence子类型（如String）                               | 验证注解的元素值是Email，也可以通过regexp和flag指定自定义的email格式 |
| @Pattern(regexp=正则表达式,flag=标志的模式) | String，任何CharSequence的子类型                             | 验证注解的元素值与指定的正则表达式匹配                       |
| @Valid                                      | 任何非原子类型                                               | 指定递归验证关联的对象；如用户对象中有个地址对象属性，如果想在验证用户对象时一起验证地址对象的话，在地址对象上加@Valid注解即可级联验证 |

如果想了解更多，请参看（hibernatevalidatorreference）

## Spring 事务处理

#### 注意事项

1. 不要在接口上声明@Transactional，而要在具体类的方法上使用 @Transactional 注解，否则注解可能无效。

2. 不要图省事，将@Transactional放置在类级的声明中，放在类声明，会使得所有方法都有事务。故@Transactional应该放在方法级别，不需要使用事务的方法，就不要放置事务，比如查询方法。否则对性能是有影响的。

3. @Transactional 的事务开启 ，或者是基于接口的 或者是基于类的代理被创建。所以在同一个类中一个方法调用另一个方法有事务的方法，事务是不会起作用的 。

4. 用REQUIRES_NEW的时候，发现没有起作用
   分析了一下，原因是A方法（有事务）调用B方法（要独立新事务），如果两个方法写在同一个类里，spring的事务会只处理能同一个。

   ```
   解决方案1：需要将两个方法分别写在不同的类里。
   解决方案2：方法写在同一个类里，但调用B方法的时候，将service自己注入自己，用这个注入对象来调用B方法。
   ```

5. 使用了@Transactional的方法，只能是public，@Transactional注解的方法都是被外部其他类调用才有效，故只能是public。道理和上面的有关联。故在 protected、private 或者 package-visible 的方法上使用 @Transactional 注解，它也不会报错，但事务无效。

6. 默认只有RuntimeExcetion会触发回滚，经验证明确实如此，所以rollbackFor可以自行设置如下：rollbackFor = {Exception.class}，当然具体业务具体处理，可能有的业务抛出的某些异常并不需要触发回滚，所以此时应该细化处理异常。

   ```
   @Transactional(propagation = Propagation.REQUIRES_NEW,rollbackFor={/*自定义Exception，可以是多个*/ IOException.class})
   ```

   上面的这个rollbackFor配置，可以理解为：当配置这个事务的方法内返回了IOException，则会触发回滚操作。

7. MySQL数据库表引擎应为InnoDB，否则不支持事务。

## 本地 JAR 开发

### 背景

有一些工程依赖的库是一些jar包，这些jar在公用仓储中没有，比如weibo的或weixin等等。

我们将这些jar包导入到工程中的本地仓储中，以便使maven可以正常依赖

### 目录规划

我们在项目中新建一个目录 “maven-repository ”做为仓储的存放地址。

### 导入jar到仓储中

在命令行中进入到**工程根目录**，执行如下命令

```shell
mvn deploy:deploy-file -Dfile=/yourpath/ojdbc14.jar  -DgroupId=com.oracle -DartifactId=ojdbc -Dversion=1.0 -Dpackaging=jar -Durl=file:./maven-repository/ -DrepositoryId=maven-repository -DupdateReleaseInfo=true
```

### 依赖

在pom.xml中加入仓储声明：

```xml
<repositories>
    <repository>
        <id>maven-repository</id>
        <url>file:///${project.basedir}/maven-repository</url>
    </repository>
</repositories>
```

依赖

```xml
<dependency>
    <groupId>com.oracle</groupId>
    <artifactId>ojdbc</artifactId>
    <version>1.0</version>
</dependency>
```



### 使用 Redis 分布式事务 

#### 创建 `RedisTransactional` 注解

```java
import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
public @interface RedisTransactional {

    /**
     * 获取锁的最长等待时间，以秒为单位
     * 如果不指定，则会一直等待
     */
    int acquireTimeout() default 0;


    /**
     * 锁的超时时间，以秒为单位
     * 如果不指定，则不会超时，只能手工解锁时才会释放
     */
    int lockTimeout() default 0 ;


    /**
     * 锁名字，如果不指定，则使用当前方法的全路径名
     * @return
     */
    String lockName() default "";


}
```

#### RedisTransactional 注解切面逻辑处理

```java
import com.enation.framework.util.StringUtil;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.CodeSignature;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

@Aspect
@Component
public class RedisTransactionalAspect {

    private final Logger logger = LoggerFactory.getLogger(this.getClass());  

    @Autowired
    private RedissonClient redissonClient;

    /**
	 * 对事务注解进行切面
	 * @param pjd 切点
	 * @param transactional 事务注解
	 * @return 原方法返回值
	 * @throws Throwable 可能存在的异常
	 */
    @Around(value = "@annotation(transactional)")
    public Object aroundMethod(ProceedingJoinPoint pjd, RedisTransactional transactional) throws Throwable {

        String lockName  = transactional.lockName();

        if(StringUtil.isEmpty(lockName)) {
            //生成 lock key name
            CodeSignature signature = (CodeSignature) pjd.getSignature();
            lockName = signature.toLongString();
        }

        //获取锁
        RLock lock = redissonClient.getLock(lockName);
        String tname  = Thread.currentThread().getName();
        try {
            //上锁

            //获取锁的最长时间
            int acquireTimeout = transactional.acquireTimeout();

            //锁的超时间
            int lockTime  = transactional.lockTimeout();

            //如果没指定超时时间则直接上锁
            if(lockTime == 0 && acquireTimeout ==0 ) {
                lock.lock();
            }

            //如果指定了超时间则尝试上锁
            if(acquireTimeout!=0  && lockTime!=0){
                boolean lockResult     = lock.tryLock(acquireTimeout,lockTime, TimeUnit.SECONDS);
                if(!lockResult ) {
                    throw new RuntimeException(lockName + " 获取锁失败");
                }
            }

            //如果指定了 锁的超时间，但没有指定获取锁的时间
            if(acquireTimeout==0  && lockTime!=0){
                lock.lock(lockTime, TimeUnit.SECONDS);
            }

            //执行切面方法
            Object result = pjd.proceed();
            return result;

        } catch (Throwable e) {
            if( logger.isErrorEnabled()){
                this.logger.error("redis事务失败",e);
            }
            throw e;
        } finally {
            //解锁
            lock.unlock();
        }
    }
}

```

#### 使用注意：

- 如果多个方法对同一个分布式对象可能有并发事务操作时，则应该使用同一个锁名。

- 如果只有一个方法操作了分布式对象，则可以使用默认的锁名。

- 举个栗子：

  ```java
  @RedisTransactional(lockName = "test_lock",acquireTimeout=10,lockTimeout = 10)
  public String add(){
      Integer value  = cache.get(key);
      value++;
      cache.put(key,value);
      return "ok";
  }
  ```

