---
title: SpringBoot-脚手架（二）
tags: [SpringBoot, scaffolding]
img: https://www.holddie.com/img/20200105162434.png
date: 2018-08-15 08:27:25
categories: SpringBoot
---

时代会为你作出选择，不管你是否愿意。																	——雪莉



### Redis 二级缓存通用配置

一切的前提当然是在开启 `Mybatis` 二级缓存的情况下讨论。

#### 1、RedisTemplate 配置

```java
@Configuration
public class RedisConfig {

    /**
     * RedisTemplate 配置
     *
     * <p>
     * 重写Redis序列化方式，使用Json方式:
     * 当我们的数据存储到Redis的时候，我们的键（key）和值（value）都是通过Spring提供的Serializer序列化到数据库的。
     * RedisTemplate默认使用的是JdkSerializationRedisSerializer，StringRedisTemplate默认使用的是StringRedisSerializer。
     * Spring Data JPA为我们提供了下面的Serializer：
     * GenericToStringSerializer、Jackson2JsonRedisSerializer、JacksonJsonRedisSerializer、JdkSerializationRedisSerializer、OxmSerializer、StringRedisSerializer。
     * 在此我们将自己配置RedisTemplate并定义Serializer。
     * </p>
     * @param redisConnectionFactory redis连接工厂
     * @return RedisTemplate
     * @author HoldDie
     * @email HoldDie@163.com
     * @date 2018/8/13 14:33
     */
    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory redisConnectionFactory) {
        RedisTemplate<String, Object> redisTemplate = new RedisTemplate<>();
        redisTemplate.setConnectionFactory(redisConnectionFactory);

        Jackson2JsonRedisSerializer<Object> jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer<Object>(Object.class);
        ObjectMapper om = new ObjectMapper();
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        om.enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL);
        jackson2JsonRedisSerializer.setObjectMapper(om);

        // 设置键（key）的序列化采用StringRedisSerializer。
        redisTemplate.setKeySerializer(new StringRedisSerializer());

        // 设置值（value）的序列化采用Jackson2JsonRedisSerializer。
        redisTemplate.setValueSerializer(jackson2JsonRedisSerializer);
        redisTemplate.afterPropertiesSet();
        return redisTemplate;
    }

}
```

#### 2、Redis - Mybatis 二级缓存实现

```java
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

#### 3、Mapper 接口配置

```java
@Repository
@DependsOn("springContextHolder")
@CacheNamespaceRef(TestMapper.class)
public interface TestMapper extends BaseDao<Test> {

}
```

#### 4、XML 文件中缓存配置

```xml
<!-- 开启二级缓存 -->
<cache type="com.zeus.oem.config.mybatis.cache.Redis2cnCache">
    <property name="eviction" value="LRU" />
    <property name="flushInterval" value="6000000" />
    <property name="size" value="1024" />
    <property name="readOnly" value="false" />
</cache>
```



### Mybatis 常用小抄

#### 1.参数注入

##### 1.1 用#{0},#{1}的形式，0代表第一个参数，1代表第二个参数　

```java
public List<RecordVo> queryList(String workerId, Integer topNum);
```

对应的 `xml` 配置　

```xml
<select id="queryList" resultType="com.demo.RecordVo">
    SELECT ID id, WORKER_ID workerId, UPDATE_DATE updateDate
    FROM USER_RECORDS t
    WHERE t.WORKER_ID = #{0}
    LIMIT #{1}
</select>
```

##### 1.2 Map或者封装对象,workerId为map里面的键；如果是对象则workerId为对象中的属性，这种方法非常常用

```java
public Integer queryCountByWorkerId(Map queryParam);
```

对应的 `xml` 配置　

```xml
<select id="queryCountByWorkerId" parameterType="java.util.Map" resultType="java.lang.Integer">
    SELECT COUNT(1)
    FROM tableName F
    WHERE F.WORKER_ID = #{workerId}
</select>
```

##### 1.3注解

```java
public Integer queryCountByWorkerId(@param(“workerId”)String workerId);
```

对应的 `xml` 配置　

```xml
<select id="queryCountByWorkerId" parameterType="java.util.Map" resultType="java.lang.Integer">
    SELECT COUNT(1)
    FROM tableName F
    WHERE F.WORKER_ID = #{workerId}
</select>
```

#### 2.返回

##### 2.1映射

```xml
<!-- 实体类与表字段对应 -->
<resultMap type="com.demo.DataModule" id="dataModule">
    <result column="ID" property="id" />
    <result column="CREATE_DATE" property="createDate" />
    <result column="WORKERID" property="workerId" />
    <result column="UPDATE_DATE" property="updateDate" />
    <result column="STATUS" property="status" />
</resultMap>
<select id="queryAll" resultType="dataModule">
    select ID,CREATE_DATE,WORKERID from tableName 
</select>
```

这种方式查询语句查询的字段直接就是数据库里面的字段就好了，就定义映射的column

##### 2.2直接返回对象

```xml
<select id="queryAll" resultType="com.demo.DataModule">
    select ID id,CREATE_DATE createDate,WORKERID workerId from tableName 
</select>
```

这里查询返回的字段别名必须对应返回对象中的属性

#### 3.执行原生sql

##### 3.1sql参数：

```java
public class ParamVo {

    private String sql;
    //getter setter 省略

}
```

##### 3.2接口：

```java
 /**
　　* @功能描述: 创建
　　* @param vo
　　* @return
　　*/
public int excuteCreateSql(ParamVo vo);
 /**
　　* @功能描述: 查询
　　* @param vo
　　* @return
　　*/
public List<Map<String, Object>> excuteSelectSql(ParamVo vo);
```

##### 3.3xml:

```xml
<update id="excuteCreateSql">
    ${sql}
</update>
```

${}不编译sql直接执行，如果用#{sql}可能报错

```xml
<select id="excuteSelectSql" resultType="java.util.Map">
    ${sql}
</select>
```

这里不知道返回类型用map或者hashmap作为返回

#### 4.使用 Include

include:有时候两个方法要返回的字段都一样或者where子句一样，这样为了避免重复写代码，就抽出来用include

##### 4.1定义子句相同部分

```xml
<sql id="queryChild">
    FROM tableName1 F
    RIGHT JOIN tableName2 C ON F.WORKER_ID = C.WORKER_ID 
    WHERE F.STATUS = 1 AND F.WORKER_ID = #{workerId}
    ORDER BY C.CREATE_DATE DESC 
</sql>
```

##### 4.2引用

```xml
<select id="queryCountByWorkerId" parameterType="java.util.Map" resultType="java.lang.Integer">
    SELECT COUNT(1)
    <include refid="queryChild"/>
</select>
<select id="queryListByWorkerId" parameterType="java.util.Map" resultType="com.demo.RecordVo">
    SELECT ID id, WORKER_ID workerId, UPDATE_DATE updateDate,......
    <include refid="queryChild"/>
</select>
```

