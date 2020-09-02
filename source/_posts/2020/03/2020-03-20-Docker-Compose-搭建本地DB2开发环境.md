---
title: Docker-Compose 搭建本地DB2开发环境
author: HoldDie
img: https://www.holddie.com/img/20200320213030.png
top: false
cover: false
coverImg: https://www.holddie.com/img/20200320213030.png
toc: true
mathjax: true
tags:
  - DockerCompose
  - DB2
  - Docker
date: 2020-03-20 20:56:57
password:
summary: 有的时候一个好的经历恰恰来源于一件出错的事情。
categories: Docker
---

![](https://www.holddie.com/img/20200320213030.png)

### 1、编写docker-compose.yml文件

```yml
version: '2.2'
services:
  db2_11:
    image: ibmcom/db2
    container_name: db2_11
    privileged: true
    ports:
      - "50000:50000"
    environment:
      - DB2INST1_PASSWORD=Root123456
      - LICENSE=accept
      - DBNAME=testdb
    volumes:
      - ./database:/database
```

解释：

- username: db2inst1
- password: Root123456
- dbname: testdb
- port: 50000

使用 Docker 命令也可以临时运行

```shell
docker run -itd --name mydb2 --privileged=true -p 50000:50000 -e LICENSE=accept -e DB2INST1_PASSWORD=123123123 -e DBNAME=testdb -v /Users/xxx/docker-db2:/database ibmcom/db2
```



### 2、创建和查看命令

```shell
# 创建对应的环境
docker-compose up -d

# 查看启动情况,这一步很关键，不看日志的话，不清楚当前程序是否启动和启动的情况
docker-compose logs
```



### 3、远程连接

如果走到这一步，没有什么特殊需求的话，基本上就可以本地连接，进行开发了。

接下来如果使用的 Java 语言，那么需要 JDBC Jar包，其他的语言也大同小异，这一步也很关键

```xml
<dependency>
    <groupId>com.ibm.db2.jcc</groupId>
    <artifactId>db2jcc</artifactId>
    <version>db2jcc4</version>
</dependency>
```



一般上到这里的时候，我们就可以使用图形化工具，链接数据库进行图形化操作了，在连接的时候记得还有一个参数 `sslconnection=false`（我就踩了这个坑）。



再补充一点就是数据库连接对应的URL：` "jdbc:db2://${host}:${port}/${dbName}"`



### 4、高阶操作(不影响使用了)

如上基本已经足够了，我们可以使用图形化的工具，创建数据库等等等。

但是如果没有对应的工具，我们也可以使用对应的命令进行创建数据库、用户名等。



```shell
# 进入容器
docker exec -it db2_11 bash

# 切换到对应的用户 db2inst1
su db2inst1

# 查看当先数据库
db2 list db directory

# 之后使用exit，返回root用户，进行创建用户、组
exit

groupadd db2group

useradd -m -g db2group -d /home/test test

passwd test

# 切换到db2inst1用户下给test赋予连接权限
su db2inst1

db2 connect to testdb

db2 grant connect on database to user test

db2 grant DATAACCESS on database to user test

db2 connect reset


# 创建数据库
db2 create db TEST using codeset utf-8 territory CN

db2 list db directory

db2 list tables


# 对于数据的迁移
db2move <database name> export

db2move <database name> import
```

