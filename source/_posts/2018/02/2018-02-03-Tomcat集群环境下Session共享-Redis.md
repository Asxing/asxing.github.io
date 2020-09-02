---
title: Tomcat集群环境下Session共享--Redis
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Tomcat
  - Session
  - Redis
date: 2018-02-03 21:32:16
password:
summary:  
categories: Session
---



继续怼一下，Nginx + Redis + Tomcat 实现 Session 共享。

## 集群环境信息

|     主机      |  端口   |     开源软件      |
| :---------: | :---: | :-----------: |
| 10.10.3.83  |  80   | Nginx(1.12.2) |
| 10.15.0.174 | 37080 |  Tomcat(8.5)  |
| 10.15.0.174 | 38080 |  Tomcat(8.5)  |
| 10.15.0.174 | 6379  | Redis(3.2.10) |

实验拓扑图：

![](https://www.holddie.com/img/20200105144558.png)



## Nginx 配置文件

```coffeescript
upstream xxx {
  server 10.15.0.174:37080;
  server 10.15.0.174:38080;
}
location /xxx/ {
  proxy_pass http://xxx/xxx/;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header REMOTE-HOST $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

没有安装 Nginx，请出门左转 --> [Nginx-KeepAlived-高可用](https://www.holddie.com/2018/01/31/2017-9-2017-09-21-Nginx-KeepAlived-%E9%AB%98%E5%8F%AF%E7%94%A8/)

以及想更深入了解一波原理的，请出门右转 --> [Nginx+Keepalived基本原理](https://www.holddie.com/2018/01/31/2017-11-2017-11-10-Keepalived-Nginx/)

## 安装Redis

Redis 的安装，此处也省了网上很多，最简单就是 `yum install redis`，记得配置 存储模式 和 绑定的IP，最多还有个端口冲突，其他的此处用不到。

```bash
[root@localhost jsp]# redis-cli 
127.0.0.1:6379> info
# Server
redis_version:3.2.10
redis_git_sha1:00000000
redis_git_dirty:0
redis_build_id:c8b45a0ec7dc67c6
redis_mode:standalone
os:Linux 3.10.0-229.el7.x86_64 x86_64
arch_bits:64
multiplexing_api:epoll
gcc_version:4.8.5
process_id:24349
run_id:9f3fdbc4a4106f1d0f53f81efe32ad1cefec249e
tcp_port:6379
uptime_in_seconds:655
uptime_in_days:0
hz:10
lru_clock:7786509
executable:/usr/bin/redis-server
config_file:/etc/redis.conf
```

确保正常就可以了。

## 配置Tomcat

- 首先访问 GitHub，下载 [**tomcat-cluster-redis-session-manager.zip**](https://github.com/ran-jit/tomcat-cluster-redis-session-manager/releases/download/2.0.2/tomcat-cluster-redis-session-manager.zip) 

- 然后把相应的 lib 下 JAR 包 放置到 Tomcat lib文件夹下

- 在 redis-data-cache.properties 文件配置 Redis 信息后，放置到 Tomcat conf 文件夹下

- 编辑 Tomcat/conf/context.xml 文件，添加以下内容：

   ```xml
   <Valve className="tomcat.request.session.redis.SessionHandlerValve" />
   <Manager className="tomcat.request.session.redis.SessionManager" />
   ```

- 编辑 Tomcat/conf/web.xml 文件，修改以下内容：

   ```xml
   <session-config>
   	<session-timeout>60<session-timeout>
   <session-config>
   ```

另外一点，启动多个 Tomcat 注意修改配置文件，避免端口冲突。

## 验证

首先，同一个页面刷新两次，查看访问请求，页面变化：

![](https://www.holddie.com/img/20200105144641.png)

然后，刷新一次：

![](https://www.holddie.com/img/20200105144650.png)



​	至此，简单地使用 Redis 同步 Session 已经完成了目的，当然考虑到后期的高可用性，当然在 Redis 这一方还可以发挥，使用 Redis 哨兵模式，做高可用等等。

## 页面示例代码

```html
<table align="center" border="1">
	<tr>
		<td>Session ID</td>
			<% session.setAttribute("1","1"); %>
		<td><%= session.getId() %></td>
	</tr>
	<tr>
		<td>Created on</td>
		<td><%= session.getCreationTime() %></td>
	</tr>
  	<tr>
    	<td>Server Port</td>
    	<td>38080</td>
 	</tr>
</table>
```



参考链接：

> [nginx和tomcat 集群使用redis 保证session 同步]: https://www.jianshu.com/p/08f66e4a34d1
> [搭建Tomcat集群&amp;通过Redis缓存共享session的一种流行方案]: https://segmentfault.com/a/1190000009591087