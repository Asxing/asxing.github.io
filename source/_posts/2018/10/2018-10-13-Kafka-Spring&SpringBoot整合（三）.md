---
title: Kafka-Spring&SpringBoot整合（三）
author: HoldDie
tags: [Kafka,消息中间件]
top: false
date: 2018-10-13 19:43:41
categories: Kafka
---



> 真相就在眼前，却露出戏谑的笑容，只有心如明镜之人才可触碰到。 ——鱼大仙

### 1、Kafka 源码导入

#### 1.1、环境准备

- Gradle
- Scala

#### 1.2、下载源码，然后解压并进入源码目录

```shell
gradle idea
idea build.gradle
```

#### 1.3、导入源码

IDEA 关键配置

### 2、Spring 整合 Kafka

#### 2.1、引入Maven依赖

```xml
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka_2.12</artifactId>
    <version>2.0.0</version>
</dependency>
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
    <version>2.1.10.RELEASE</version>
</dependency>
```

#### 2.2、Spring 配置文件–producer（生产者）

##### 2.2.1、kafka-producer.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- 定义实例化 KafkaProducer 的参数 -->
    <bean id="producerProperties" class="java.util.HashMap">
        <constructor-arg>
            <map>
                <entry key="bootstrap.servers" value="${bootstrap.servers}"/>
                <entry key="key.serializer" value="${key.serializer}"/>
                <entry key="value.serializer" value="${value.serializer}"/>
            </map>
        </constructor-arg>
    </bean>

    <!-- 实例化 DefaultKafkaProducerFactory,用于根据配置创建一个 KafkaProducer 实例  -->
    <bean id="producerFactory" class="org.springframework.kafka.core.DefaultKafkaProducerFactory" >
        <constructor-arg>
            <ref bean="producerProperties"/>
        </constructor-arg>
    </bean>

    <bean id="producerListener" class="com.enation.app.shop.mobile.kafka.SpringKafkaProducerListener"/>
    <!-- 创建kafkatemplate-->
    <bean id="kafkaTemplate" class="org.springframework.kafka.core.KafkaTemplate">
        <!-- 指定ProducerFactory实例 -->
        <constructor-arg index="0" ref="producerFactory"/>
        <!-- 同步模式 -->
        <constructor-arg index="1" value="true"/>
        <!-- 指定一个默认的主题 -->
        <property name="defaultTopic" value="${defaultTopic}"/>
        <!-- 指定一个自定义的ProducerListener -->
        <property name="producerListener" ref="producerListener"/>
    </bean>
</beans>
```

##### 2.2.2、配置属性 `kafka.properties`：

```properties
# 连接 Kafka broker 相关配置
bootstrap.servers=192.168.1.207:9092,192.168.1.208:9092,192.168.1.209:9092
# 消息 key 序列化类
key.serializer=org.apache.kafka.common.serialization.StringSerializer
# 消息序列化类
value.serializer=org.apache.kafka.common.serialization.StringSerializer
# 默认主题，即将当调用不指定主题的 send 方法时消息被发送到的主题
defaultTopic=trade-entrust
# 消息发送方式：true 表示以同步方式发送
autoFlush=true
```

#### 2.3、执行发送消息

##### 2.3.1、KafkaMessageController.java

```java
import com.alibaba.fastjson.JSONObject;
import org.apache.commons.lang3.StringUtils;
import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.PrintWriter;
import java.nio.charset.Charset;

/**
 * Kafka消息测试
 * @author holddie
 * @version 1.0.0
 * @email holddie@163.com
 * @date 2018/10/12 下午5:57
 */
@RestController
@RequestMapping(("kafka"))
public class KafkaMessageController {

    private static final Logger LOG = Logger.getLogger(KafkaMessageController.class);

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @ResponseBody
    @RequestMapping(value = "/trade_entrust", method = { RequestMethod.POST })
    public void signIn(HttpServletRequest request, @RequestBody JSONObject params,
                       HttpServletResponse response) {
        PrintWriter writer = null;
        String rspMsg = "委托失败";
        System.out.println(Charset.defaultCharset());
        try {
            writer = response.getWriter();
            String entrustInfo = params.toString();
            // 这里通过验证请求参数不为空来表示一笔有效的委托
            if(StringUtils.isNotBlank(entrustInfo)){
                kafkaTemplate.sendDefault(entrustInfo);
                rspMsg = "委托成功";
            }else{
                rspMsg = "请求参数非法";
            }
        } catch (Exception e) {
            rspMsg = "消息发送失败";
            LOG.error(rspMsg,e);
        } finally {
            writer.append(rspMsg);
            if (writer != null) {
                writer.close();
            }
        }
    }
}
```

##### 2.3.2、SpringKafkaProducerListener.java

```java
package com.enation.app.shop.mobile.kafka;

import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.log4j.Logger;
import org.springframework.kafka.support.ProducerListener;

import java.nio.charset.Charset;

public class SpringKafkaProducerListener implements ProducerListener<String, String> {

    private static final Logger LOG = Logger.getLogger(SpringKafkaProducerListener.class);

    @Override
    public void onSuccess(String topic, Integer partition, String key, String value,
                          RecordMetadata recordMetadata) {
        LOG.info("委托成功:主题[" + topic + "],分区[" + recordMetadata.partition() + "],委托时间[" + recordMetadata.timestamp() + "],委托信息如下：");
        System.out.println("--------------");
        LOG.info(value);
        LOG.info("执行成功");
        System.out.println(Charset.defaultCharset());
    }

    @Override
    public void onError(String topic, Integer partition, String key, String value,
                        Exception e) {
        LOG.info("消息发送失败:topic:" + topic + ",value" + value + ",exception:"
                 + e.getLocalizedMessage());
    }

    @Override
    public boolean isInterestedInSuccess() {
        return true;// 要onSuccess方法被执行，需要返回true
    }
}
```

### 3、SpringBoot 整合 Kafka

#### 3.1、Maven 依赖

```xml
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka_2.12</artifactId>
    <version>2.0.0</version>
</dependency>
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
    <version>2.1.10.RELEASE</version>
</dependency>
```

#### 3.2、配置

```properties
kafka.consumer.zookeeper.connect=192.168.1.204:2181,192.168.1.205:2181,192.168.1.206:2181
kafka.consumer.servers=192.168.1.207:9092,192.168.1.208:9092,192.168.1.209:9092
kafka.consumer.enable.auto.commit=true
kafka.consumer.session.timeout=6000
kafka.consumer.auto.commit.interval=100
kafka.consumer.auto.offset.reset=latest
kafka.consumer.group.id=test
kafka.consumer.concurrency=10

kafka.producer.servers=192.168.1.207:9092,192.168.1.208:9092,192.168.1.209:9092
kafka.producer.retries=0
kafka.producer.batch.size=4096
kafka.producer.linger=1
kafka.producer.buffer.memory=40960
```

#### 3.3、配置Bean

##### 3.3.1、KafkaConsumerConfig

```java
package com.zeus.oem.config.kafka;

import com.zeus.oem.controller.Listener;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.config.KafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.listener.ConcurrentMessageListenerContainer;

import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableKafka
public class KafkaConsumerConfig {

    @Value("${kafka.consumer.servers}")
    private String servers;
    @Value("${kafka.consumer.enable.auto.commit}")
    private boolean enableAutoCommit;
    @Value("${kafka.consumer.session.timeout}")
    private String sessionTimeout;
    @Value("${kafka.consumer.auto.commit.interval}")
    private String autoCommitInterval;
    @Value("${kafka.consumer.group.id}")
    private String groupId;
    @Value("${kafka.consumer.auto.offset.reset}")
    private String autoOffsetReset;
    @Value("${kafka.consumer.concurrency}")
    private int concurrency;
    @Bean
    public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, String>> kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, String> factory = new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        factory.setConcurrency(concurrency);
        factory.getContainerProperties().setPollTimeout(1500);
        return factory;
    }

    public ConsumerFactory<String, String> consumerFactory() {
        return new DefaultKafkaConsumerFactory<>(consumerConfigs());
    }


    public Map<String, Object> consumerConfigs() {
        Map<String, Object> propsMap = new HashMap<>();
        propsMap.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, servers);
        propsMap.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, enableAutoCommit);
        propsMap.put(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG, autoCommitInterval);
        propsMap.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, sessionTimeout);
        propsMap.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        propsMap.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        propsMap.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        propsMap.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, autoOffsetReset);
        return propsMap;
    }

}
```

##### 3.3.2、KafkaProducerConfig

```java
package com.zeus.oem.config.kafka;

import java.util.HashMap;
import java.util.Map;

import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;

@Configuration
@EnableKafka
public class KafkaProducerConfig {

    @Value("${kafka.producer.servers}")
    private String servers;
    @Value("${kafka.producer.retries}")
    private int retries;
    @Value("${kafka.producer.batch.size}")
    private int batchSize;
    @Value("${kafka.producer.linger}")
    private int linger;
    @Value("${kafka.producer.buffer.memory}")
    private int bufferMemory;


    public Map<String, Object> producerConfigs() {
        Map<String, Object> props = new HashMap<>();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, servers);
        props.put(ProducerConfig.RETRIES_CONFIG, retries);
        props.put(ProducerConfig.BATCH_SIZE_CONFIG, batchSize);
        props.put(ProducerConfig.LINGER_MS_CONFIG, linger);
        props.put(ProducerConfig.BUFFER_MEMORY_CONFIG, bufferMemory);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        return props;
    }

    public ProducerFactory<String, String> producerFactory() {
        return new DefaultKafkaProducerFactory<>(producerConfigs());
    }

    @Bean
    public KafkaTemplate<String, String> kafkaTemplate() {
        return new KafkaTemplate<String, String>(producerFactory());
    }
}
```

#### 3.4、消息Producer

```java
@RestController
@RequestMapping("/kafka")
public class CollectController {
    protected final Logger logger = LoggerFactory.getLogger(this.getClass());
    @Autowired
    private KafkaTemplate kafkaTemplate;

    @RequestMapping(value = "/send", method = RequestMethod.GET)
    public Result sendKafka(HttpServletRequest request, HttpServletResponse response) {
        try {
            String message = request.getParameter("message");
            logger.info("kafka的消息={}", message);
            kafkaTemplate.send("trade-entrust", "key", message);
            logger.info("发送kafka成功.");
            return ResultUtil.genOkResult("发送kafka成功");
        } catch (Exception e) {
            logger.error("发送kafka失败", e);
            return ResultUtil.genFailedResult("发送kafka失败");
        }
    }
}
```

#### 3.5、消息Consumer

```java
@Component
public class Listener {
    protected final Logger logger = LoggerFactory.getLogger(this.getClass());

    @KafkaListener(topics = {"trade-entrust"})
    public void listen(ConsumerRecord<?, ?> record) {
        logger.info("kafka的key: " + record.key());
        logger.info("kafka的value: " + record.value().toString());
    }
}
```

#### 3.6、执行验证

##### 3.6.1、发送消息

```verilog
1716894 INFO  [2018-10-12 19:27:14]  委托成功:主题[trade-entrust],分区[0],委托时间[1539343634438],委托信息如下：
--------------
1716894 INFO  [2018-10-12 19:27:14]  {"sec_price":"10.01","sec_name":"中国","user_id":"1000000","sec_code":"601766"}
1716894 INFO  [2018-10-12 19:27:14]  执行成功
UTF-8
UTF-8
11828156 INFO  [2018-10-12 22:15:45]  委托成功:主题[trade-entrust],分区[0],委托时间[1539353745679],委托信息如下：
--------------
11828157 INFO  [2018-10-12 22:15:45]  {"sec_price":"10.01","sec_name":"中国","user_id":"1000000","sec_code":"601766"}
11828157 INFO  [2018-10-12 22:15:45]  执行成功
UTF-8
```

##### 3.6.2、消费消息

```verilog
2018-10-12 22:15:45.784  INFO 32383 --- [ntainer#0-0-C-1] com.zeus.oem.controller.Listener         : kafka的key: null
2018-10-12 22:15:45.786  INFO 32383 --- [ntainer#0-0-C-1] com.zeus.oem.controller.Listener         : kafka的value: {"sec_price":"10.01","sec_name":"中国","user_id":"1000000","sec_code":"601766"}
```

至此，基本Demo级别，跑通，剩下就是深入核心组件。