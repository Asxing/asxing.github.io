---
title: Properties文件常识
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Spring
  - Properties
date: 2017-10-09 21:32:16
password:
summary:  
categories: Properties
---

## Properties 文件常见配置

```properties
#Driver
jdbc.driverClassName=com.mysql.jdbc.Driver
#数据库链接，
jdbc.url=jdbc:mysql://192.168.0.37:3306/project_demo?useUnicode=true&characterEncoding=UTF-8
#帐号
jdbc.username=root
#密码
jdbc.password=xxxx
#检测数据库链接是否有效，必须配置
jdbc.validationQuery=SELECT 'x'
#初始连接数
jdbc.initialSize=3
#最大连接池数量
jdbc.maxActive=10
#去掉，配置文件对应去掉
#jdbc.maxIdle=20
#配置0,当线程池数量不足，自动补充。
jdbc.minIdle=0
#获取链接超时时间为1分钟，单位为毫秒。
jdbc.maxWait=60000
#获取链接的时候，不校验是否可用，开启会有损性能。
jdbc.testOnBorrow=false
#归还链接到连接池的时候校验链接是否可用。
jdbc.testOnReturn=false
#此项配置为true即可，不影响性能，并且保证安全性。意义为：申请连接的时候检测，如果空闲时间大于timeBetweenEvictionRunsMillis，执行validationQuery检测连接是否有效。
jdbc.testWhileIdle=true
#1.Destroy线程会检测连接的间隔时间
#2.testWhileIdle的判断依据
jdbc.timeBetweenEvictionRunsMillis=60000
#一个链接生存的时间（之前的值：25200000，这个时间有点BT，这个结果不知道是怎么来的，换算后的结果是：25200000/1000/60/60 = 7个小时）
jdbc.minEvictableIdleTimeMillis=300000
#链接使用超过时间限制是否回收
jdbc.removeAbandoned=true
#超过时间限制时间（单位秒），目前为5分钟，如果有业务处理时间超过5分钟，可以适当调整。
jdbc.removeAbandonedTimeout=300
#链接回收的时候控制台打印信息，测试环境可以加上true，线上环境false。会影响性能。
jdbc.logAbandoned=false
```

## 常用数据库 validationQuery 检查语句

| 数据库           | validationQuery                          |
| ------------- | ---------------------------------------- |
| Oracle        | select 1 from dual                       |
| mysql         | select 1                                 |
| DB2           | select 1 from sysibm.sysdummy1           |
| microsoft sql | select 1                                 |
| hsqldb        | select 1 from INFORMATION_SCHEMA.SYSTEM_USERS |
| postgresql    | select version()                         |
| ingres        | select 1                                 |
| derby         | select 1                                 |
| H2            | select 1                                 |



参考地址：<http://www.sojson.com/blog/47.html>

