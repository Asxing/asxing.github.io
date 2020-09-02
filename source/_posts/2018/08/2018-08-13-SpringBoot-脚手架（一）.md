---
title: SpringBoot-脚手架（一）
tags: [SpringBoot, Hibernate, Validation, Mybatis]
img: https://www.holddie.com/img/20200105162403.jpg
date: 2018-08-13 08:05:35
categories: SpringBoot
---

星辰陨落只为铸就挥剑一瞬，日月无光只因执剑者的刹那回眸。											——莀莘



### `@Validated`/`@Valid` 和`BindingResult`

对于Controller层我们一般做的最多的就是参数校验，判断一个参数是否为空，但是若是对于一个实体的字段特别多的情况我们是否有办法进行统一处理，此时就会用到 Validation 参数校验。

区分：

- `@Valid`是使用`hibernate validation`的时候使用 
- `@Validated` 是只用`spring  Validator` 校验机制使用
- `@Validated`和`BindingResult bindingResult`是配对出现，并且形参顺序是固定的（一前一后） 

#### 使用 `@Valid` 的依赖介绍：

```xml
<dependency> 
     <groupId>javax.validation</groupId> 
     <artifactId>validation-api</artifactId> 
     <version>x.x.x.Final</version> 
 </dependency> 
 
 
 <dependency> 
     <groupId>org.hibernate</groupId> 
     <artifactId>hibernate-validator</artifactId> 
     <version>x.x.x.Final</version> 
 </dependency>
```

#### JSR303 参数校验规则

```java
空检查
 
@Null       验证对象是否为null
 
@NotNull    验证对象是否不为null, 无法查检长度为0的字符串
 
@NotBlank   检查约束字符串是不是Null还有被Trim的长度是否大于0,只对字符串,且会去掉前后空格.
 
@NotEmpty  	检查约束元素是否为NULL或者是EMPTY.
 

Booelan检查
 
@AssertTrue     验证 Boolean 对象是否为 true 
 
@AssertFalse    验证 Boolean 对象是否为 false 
 

长度检查
 
@Size(min=, max=) 验证对象（Array,Collection,Map,String）长度是否在给定的范围之内 
 
@Length(min=, max=) Validates that the annotated string is between min and max included.
 
  
 
日期检查
 
@Past       验证 Date 和 Calendar 对象是否在当前时间之前 
 
@Future     验证 Date 和 Calendar 对象是否在当前时间之后 
 
@Pattern    验证 String 对象是否符合正则表达式的规则
 
  
 
数值检查，建议使用在Stirng,Integer类型，不建议使用在int类型上，因为表单值为“”时无法转换为int，但可以转换为Stirng为"",Integer为null
 
@Min            验证 Number 和 String 对象是否大等于指定的值 
 
@Max            验证 Number 和 String 对象是否小等于指定的值 
 
@DecimalMax 被标注的值必须不大于约束中指定的最大值. 这个约束的参数是一个通过BigDecimal定义的最大值的字符串表示.小数存在精度
 
@DecimalMin 被标注的值必须不小于约束中指定的最小值. 这个约束的参数是一个通过BigDecimal定义的最小值的字符串表示.小数存在精度
 
@Digits     验证 Number 和 String 的构成是否合法 
 
@Digits(integer=,fraction=) 验证字符串是否是符合指定格式的数字，interger指定整数精度，fraction指定小数精度。
 
  
 
@Range(min=, max=) Checks whether the annotated value lies between (inclusive) the specified minimum and maximum.
 
@Range(min=10000,max=50000,message="range.bean.wage")
private BigDecimal wage;
 
  
 
@Valid 递归的对关联对象进行校验, 如果关联对象是个集合或者数组,那么对其中的元素进行递归校验,如果是一个map,则对其中的值部分进行校验.(是否进行递归验证)
 
@CreditCardNumber信用卡验证
 
@Email  验证是否是邮件地址，如果为null,不进行验证，算通过验证。
 
@ScriptAssert(lang= ,script=, alias=)
 
@URL(protocol=,host=, port=,regexp=, flags=)　
```

#### 举个栗子

```java
@PostMapping
public Result register(@RequestBody @Valid final User user, final BindingResult bindingResult) {
    if (bindingResult.hasErrors()) {
        final String msg = Objects.requireNonNull(bindingResult.getFieldError()).getDefaultMessage();
        return ResultUtil.genFailedResult(msg);
    } else {
        this.userService.insert(user);
        return this.getToken(user);
    }
}
```

#### 自定义注解 `PasswordNotNull` 参数校验

```java
@Target(ElementType.FIELD)//作用于的类型，此处为对象的属性
@Retention(RetentionPolicy.RUNTIME)//运行时生效
@Constraint(validatedBy = PasswordNotNullValidator.class)//通过PasswordNotNullValidator类实现注解的相关校验操作
public @interface PasswordNotNull {
    boolean required() default true;
    
    String message() default "密码不能为空";//必填，校验未通过时的提示信息
    
    Class<?>[] groups() default {};//必填，下文会将到此参数的作用
    
    Class<? extends Payload>[] payload() default {};//必填
}
```

#### 自定义注解校验类

```java
public class PasswordNotNullValidator implements ConstraintValidator<PasswordNotNull,Object>{
 
    private Logger logger = LoggerFactory.getLogger(getClass());
 
    private boolean require = false;
    
    @Override
    public void initialize(PasswordNotNull constraintAnnotation) {
        require = constraintAnnotation.required();
        logger.info("初始化passwordNotNull注解");
    }
 
    @Override
    public boolean isValid(Object value, ConstraintValidatorContext context) {
        //返回false代表校验失败，true代表校验通过
        if(require){
            return !StringUtils.isEmpty(s);
        }else {
            return true;
        }
    }
}
```

#### groups 的用法

通常我们会有对于新增和修改的限定不同，此时我们就可以使用groups进行区分，当然这也只是为了说明可以有针对的区分不同的状态。

```java

public class Animal {
    public interface SimpleView{}//创建一个空的接口
    @PasswordNotNull(message = "不能为空啊密码！",groups = {SimpleView.class})
    private String password;
}
```

设置完groups后，方法参数上的Valid需要进行修改如下才会生效，就是将Valid替换为Validated并设置分组信息即可。 

```java
public Map<String,Object> createAnimal(@Validated({Animal.SimpleView.class}) @RequestBody Animal animal,
                                       BindingResult bindingResult){
    logger.info(animal.toString());
    Map<String,Object> result = new HashMap<>();
    if (bindingResult.hasErrors()){
        FieldError error = (FieldError) bindingResult.getAllErrors().get(0);
        result.put("code","400");
        result.put("message",error.getDefaultMessage());
        return result;
    }
    result.put("code","200");
    result.put("data",animal);
    return result;
}
```

此时就完成了有针对的对于注解生效时机把握。

### ActiveRecord 模式

它是一种设计模式，属于ORM层，由Rails最早提出，遵循标准的ORM模型，表映射到记录，记录映射到对象，字段映射到对象属性。配置遵循的命名和配置惯例，能够很大程度的快速实现模型的操作，而且简洁易懂。

#### **ActiveRecord**的主要思想是：

1. 每一个数据库表对应创建一个类，类的每一个对象实例对应于数据库中表的一行记录；通常表的每个字段在类中都有相应的Field；

2. **ActiveRecord**同时负责把自己持久化，在**ActiveRecord**中封装了对数据库的访问，即**CURD**;；

3. **ActiveRecord**是一种领域模型(Domain Model)，封装了部分业务逻辑；

#### **ActiveRecord**比较适用于：

1. 业务逻辑比较简单，当你的类基本上和数据库中的表一一对应时, **ActiveRecord**是非常方便的，即你的业务逻辑大多数是对单表操作；
2. 当发生跨表的操作时, 往往会配合使用事务脚本(Transaction Script)，把跨表事务提升到事务脚本中；
3. **ActiveRecord**最大优点是简单, 直观。 一个类就包括了数据访问和业务逻辑. 如果配合代码生成器使用就更方便了；

这些优点使**ActiveRecord**特别适合WEB快速开发。

#### 单一入口

- 单一入口通常是指一个项目或者应用具有一个统一（但并不一定是唯一）的入口文件，也就是说项目的所有功能操作都是通过这个入口文件进行的，并且往往入口文件是第一步被执行的。
- 单一入口的好处是项目整体比较规范，因为同一个入口，往往其不同操作之间具有相同的规则。另外一个方面就是单一入口带来的好处是控制较为灵活，因为拦截方便了，类似如一些权限控制、用户登录方面的判断和操作可以统一处理了。

#### 对于ORM还存在其他的模型：

##### Row Data Gateway

Row Data Gateway模式中每个对象也封装了数据库记录的状态和持久化到数据库的访问方法; 这两个有时候很难区分. 细微的区别在于**Row Data Gateway不封装任何业务逻辑**;

##### TableGateway

TableGateway是一种数据访问模式, 对每个表有一个类, 类的方法封装了对单个表的数据操作, 如CRUD; 方法的接受表字段的值作为参数;

比如说对表Person有Person DAO, 有以下方法:

```
int Create(string name, bool isMale)
DataSet Find(int personId)
void Delete(int personId)
void Update(int personId, string name, bool isMale)
```

ActiveRecord的区别在于`ActiveRecord`的对象中保持了记录的值, 是有状态的, 而`TableGateway`是没有状态的, 只是一系列数据库访问方法的集合;

##### Table Module

Table Module是一种领域逻辑模式, 一个类对应于数据库中的一个表; Table Module通常和Table Gateway合作, 前者负责基本的业务逻辑, 后者负责数据库访问, 以达到逻辑层和持久化层的隔离; 实例代码经常使用这两者, 如对表Person, 通常会定义两个类, `PersonBL`和 `PersonDB`, 在`PersonBL`中处理验证等逻辑, 并调用`PersonDB`访问数据库, 层间调用使用`DataSet`或自定义数据传输对象传输数据。

在业务逻辑比较简单并且有和表的一一对应时, ActiveRecord相对来说更简单, 因为它在一个类中包括了业务逻辑对象和数据访问, 而且不需要数据传输对象, 减少了维护的工作量;和Table Module比较起来, ActiveRecord与数据库耦合更紧。

### Redis 作为 Mybatis 二级缓存

#### 1、首先集成 Redis

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

配置啥的我就不贴了，不一样

#### 2、开启 Mybatis-cache 配置

```properties
mybatis-plus.configuration.cache-enabled=true
```

#### 3、编写工具类

```java
import com.zeus.oem.core.context.SpringContextHolder;
import io.jsonwebtoken.lang.Collections;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.cache.Cache;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.RedisTemplate;

import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

/**
 * Redis 作 Mybatis 的二级缓存
 * @author HoldDie
 * @version 1.0.0
 * @email holddie@163.com
 * @date 2018/8/13 14:15
 */
@Slf4j
public class Redis2cnCache implements Cache {

    /**
     * 读写锁
     */
    private final ReadWriteLock readWriteLock = new ReentrantReadWriteLock(true);

    /**
     * redisTemplate
     */
    private RedisTemplate<String, Object> redisTemplate = SpringContextHolder.getBean("redisTemplate");

    private final static String PRE_FIX_REDIS2CN_CACHE = "Redis2cnCache:";

    private String id;

    public Redis2cnCache(String id) {
        if (id == null) {
            throw new IllegalArgumentException("Cache instances require an ID");
        }

        log.info("Redis2cnCache for Mybatis-plus id: " + id);
        this.id = id;
    }

    /**
     * 获取缓存标识
     * <p></p>
     * @return 缓存标识
     * @author HoldDie
     * @email HoldDie@163.com
     * @date 2018/8/13 14:42
     */
    @Override
    public String getId() {
        return this.id;
    }

    /**
     * 插入缓存
     * <p></p>
     * @param key   Can be any object but usually it is a {@link org.apache.ibatis.cache.CacheKey}
     * @param value The result of a select.
     * @author HoldDie
     * @email HoldDie@163.com
     * @date 2018/8/13 14:43
     */
    @Override
    public void putObject(Object key, Object value) {
        if (value != null) {
            // 向Redis中添加数据，有效时间为2天
            redisTemplate.opsForValue().set(PRE_FIX_REDIS2CN_CACHE + key.toString(), value, 2, TimeUnit.DAYS);
        }
    }

    /**
     * 获取缓存值
     * <p></p>
     * @param key The key
     * @return The object stored in the cache.
     * @author HoldDie
     * @email HoldDie@163.com
     * @date 2018/8/13 14:53
     */
    @Override
    public Object getObject(Object key) {

        try {
            if (key != null) {
                return redisTemplate.opsForValue().get(PRE_FIX_REDIS2CN_CACHE + key.toString());
            }
        } catch (Exception e) {
            e.printStackTrace();
            log.info("Redis2cnCache for Mybatis-plus 获取缓存失败,对应的 key : {}, 错误异常: {}", key.toString(), e.getMessage());
        }
        return null;
    }

    /**
     * As of 3.3.0 this method is only called during a rollback
     * for any previous value that was missing in the cache.
     * This lets any blocking cache to release the lock that
     * may have previously put on the key.
     * A blocking cache puts a lock when a value is null
     * and releases it when the value is back again.
     * This way other threads will wait for the value to be
     * available instead of hitting the database.
     * @param key The key
     * @return Not used
     */
    @Override
    public Object removeObject(Object key) {
        try {
            if (key != null) {
                return redisTemplate.delete(PRE_FIX_REDIS2CN_CACHE + key.toString());
            }
        } catch (Exception e) {
            e.printStackTrace();
            log.info("Redis2cnCache for Mybatis-plus 删除缓存失败,对应的 key : {}, 错误异常: {}", key.toString(), e.getMessage());
        }
        return null;
    }

    /**
     * Clears this cache instance
     */
    @Override
    public void clear() {
        log.info("清空 Redis2cnCache for Mybatis-plus 缓存");
        try {
            Set<String> keys = redisTemplate.keys(PRE_FIX_REDIS2CN_CACHE + "*");
            if (!Collections.isEmpty(keys)) {
                redisTemplate.delete(keys);
            }
        } catch (Exception e) {
            e.printStackTrace();
            log.info("清空 Redis2cnCache for Mybatis-plus 缓存异常: {}", e.getMessage());
        }
    }

    /**
     * Optional. This method is not called by the core.
     * @return The number of elements stored in the cache (not its capacity).
     */
    @Override
    public int getSize() {
        Long size = redisTemplate.execute(new RedisCallback<Long>() {
            @Override
            public Long doInRedis(RedisConnection connection) throws DataAccessException {
                return connection.dbSize();
            }
        });
        return size != null ? size.intValue() : 0;
    }

    /**
     * Optional. As of 3.2.6 this method is no longer called by the core.
     * <p>
     * Any locking needed by the cache must be provided internally by the cache provider.
     * @return A ReadWriteLock
     */
    @Override
    public ReadWriteLock getReadWriteLock() {
        return this.readWriteLock;
    }
}

```

#### 4、设置配置获取关键Bean

```java
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

/**
 * 以静态变量保存Spring ApplicationContext, 可在任何代码任何地方任何时候中取出ApplicaitonContext.
 *
 * <p>
 * @author HoldDie
 * @version v1.0.0
 * @email HoldDie@163.com
 * @date 2018/8/13 14:46
 */
@Service
@Lazy(false)
public class SpringContextHolder implements ApplicationContextAware {

    private static ApplicationContext applicationContext;

    /**
     * 实现ApplicationContextAware接口的context注入函数, 将其存入静态变量.
     */
    @Override
    public void setApplicationContext(ApplicationContext applicationContext) {
        // NOSONAR
        SpringContextHolder.applicationContext = applicationContext;
    }

    /**
     * 取得存储在静态变量中的ApplicationContext.
     */
    public static ApplicationContext getApplicationContext() {
        checkApplicationContext();
        return applicationContext;
    }

    /**
     * 从静态变量ApplicationContext中取得Bean, 自动转型为所赋值对象的类型.
     */
    @SuppressWarnings("unchecked")
    public static <T> T getBean(String name) {
        checkApplicationContext();
        return (T) applicationContext.getBean(name);
    }

    /**
     * 从静态变量ApplicationContext中取得Bean, 自动转型为所赋值对象的类型.
     */
    @SuppressWarnings("unchecked")
    public static <T> T getBean(Class<T> clazz) {
        checkApplicationContext();
        return (T) applicationContext.getBeansOfType(clazz);
    }

    /**
     * 清除applicationContext静态变量.
     */
    public static void cleanApplicationContext() {
        applicationContext = null;
    }

    private static void checkApplicationContext() {
        if (applicationContext == null) {
            throw new IllegalStateException(" applicaitonContext 未注入,请在 applicationContext.xml 中定义SpringContextHolder");
        }
    }
}
```

#### 5、具体的Mapper文件配置缓存

```xml
<!-- 开启二级缓存 -->
<cache type="com.zeus.oem.config.mybatis.cache.Redis2cnCache">
    <property name="eviction" value="LRU" />
    <property name="flushInterval" value="6000000" />
    <property name="size" value="1024" />
    <property name="readOnly" value="false" />
</cache>
```

至此，后端基本稳住！