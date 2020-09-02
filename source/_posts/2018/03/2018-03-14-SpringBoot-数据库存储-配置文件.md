---
title: SpringBoot-数据库存储-配置文件
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - SpringBoot
  - Config
  - 数据库
date: 2018-03-14 21:32:16
password:
summary:  
categories: SpringBoot
---

SpringBoot 除了 在配置文件中读取配置，是否可以动态的放入数据库中动态的更新？



### SpringBoot 读取配置

- 读取核心配置文件信息 `application.properties` 的内容
- 使用`Environment` 方式读取配置


### 方式一、读取 application.properties 配置

- 这种方式比较简单，只要在配置文件中配置好，就可以在component中使用
- 注解的方式 `@Value("${tset.msg}")` ，变量就可以使用

### 方式二、使用 Environment 方式

- 这种方式依赖注入 Environment 来完成
- 在创建的成员变量 `private Environment env` 上加上 `@Autowired` 注解即可完成依注入
- 然后使用 `env.getProperty("键名")` 即可取出对应的值





### 参考链接

- [Spring-boot中读取config配置文件的两种方式]: http://blog.csdn.net/qq_32786873/article/details/52840745


