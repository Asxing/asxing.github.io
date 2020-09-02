---
title: Zookeeper环境搭建
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - CentOS
  - Zookeeper
date: 2017-10-03 21:32:16
password:
summary:  
categories: Zookeeper
---

# Zookeeper 环境搭建

### 1、上传文件并解压

![mark](http://oumk5fhgp.bkt.clouddn.com/blog/170907/9hckf3hK43.png?imageslim) 

### 2、修改环境变量

![mark](http://oumk5fhgp.bkt.clouddn.com/blog/170907/eI5agLh7cC.png?imageslim) 

更新配置文件

![](https://www.holddie.com/img/20200105141608.png)

### 3、修改 zk 的配置文件

```shell
vim /usr/local/zookeeper/conf/zoo.cfg
```

![](https://www.holddie.com/img/20200105141614.png)

主要修改数据文件的地址

### 4、设置 Path 否则不能直接使用命令

### 5、启动 zk

```
zkServer.sh start //启动zk
zkServer.sh status //查看状态
```

![](https://www.holddie.com/img/20200105141621.png)

### 6、客户端连接

```
zkCli.sh //连接
```

![](https://www.holddie.com/img/20200105141630.png)

1. 客户端启动程序来建立一个会话
2. 客户端尝试连接到 localhost/127.0.0.1:2181
3. 客户端连接成功，服务器开始初始化这个新会话
4. 会话初始化成功完成
5. 服务器向客户端发送一个 SyncConnected 事件

### 7、可以飙车了

```
create /sup 123
```

![](https://www.holddie.com/img/20200105141639.png)

 

### 8、备注：

若感觉一辆车飚的不过瘾，可以多搭几台，主要区别就是在 Zookeeper 配置文件 最后添加

```
server.0=zie1:2888:3888
server.1=zie2:2888:3888
server.2=zie3:2888:3888
```

无论几台服务器，对于我们使用者而言，ZK 封装完善，对于用户是透明的，因此用户也无法感知，但是可以通过登录主机查看当前主机的状态，是 `Leader` 还是 `Follower`

在 zookeeper 下 创建 data 文件夹  **`mkdir data`**  

然后在 data 文件夹下： **vim myid**   三台机器依次编号为 **0 1 2** 