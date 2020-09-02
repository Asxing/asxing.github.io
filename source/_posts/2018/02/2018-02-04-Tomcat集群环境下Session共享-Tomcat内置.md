---
title: Tomcat集群环境下Session共享--Tomcat内置
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
date: 2018-02-04 21:32:16
password:
summary:  
categories: Session
---

主要记录一下 Nginx + Tomcat 内置实现 Session 共享  



## 集群环境信息

|     主机      |  端口   |     开源软件      |
| :---------: | :---: | :-----------: |
| 10.10.3.83  |  80   | Nginx(1.12.2) |
| 10.15.0.174 | 39080 |  Tomcat(8.5)  |
| 10.15.0.174 | 40080 |  Tomcat(8.5)  |

实验拓扑图：

  ![](https://www.holddie.com/img/20200105144740.png)

## Nginx 配置文件

```coffeescript
upstream xxx {
  server 10.15.0.174:39080;
  server 10.15.0.174:40080;
}
location /xxx/ {
  proxy_pass http://xxx/xxx/;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header REMOTE-HOST $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}

```

## 安装配置 Tomcat

### 使用 Tomcat 自带集群配置

编辑 Tomcat/conf/server.xml 文件，找到下面这一行：

```xml
<Engine name="Catalina" defaultHost="localhost">  
```

不需要任何修改，添加如下代码：

```xml
        <Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster"
                 channelSendOptions="8">

          <Manager className="org.apache.catalina.ha.session.DeltaManager"
                   expireSessionsOnShutdown="false"
                   notifyListenersOnReplication="true"/>

          <Channel className="org.apache.catalina.tribes.group.GroupChannel">
            <Membership className="org.apache.catalina.tribes.membership.McastService"
                        address="228.0.0.4"
                        port="45564"
                        frequency="500"
                        dropTime="3000"/>
            <Receiver className="org.apache.catalina.tribes.transport.nio.NioReceiver"
                      address="auto"
                      port="4000"
                      autoBind="100"
                      selectorTimeout="5000"
                      maxThreads="6"/>

            <Sender className="org.apache.catalina.tribes.transport.ReplicationTransmitter">
              <Transport className="org.apache.catalina.tribes.transport.nio.PooledParallelSender"/>
            </Sender>
            <Interceptor className="org.apache.catalina.tribes.group.interceptors.TcpFailureDetector"/>
            <Interceptor className="org.apache.catalina.tribes.group.interceptors.MessageDispatchInterceptor"/>
          </Channel>

          <Valve className="org.apache.catalina.ha.tcp.ReplicationValve"
                 filter=""/>
          <Valve className="org.apache.catalina.ha.session.JvmRouteBinderValve"/>

          <Deployer className="org.apache.catalina.ha.deploy.FarmWarDeployer"
                    tempDir="/tmp/war-temp/"
                    deployDir="/tmp/war-deploy/"
                    watchDir="/tmp/war-listen/"
                    watchEnabled="false"/>

          <ClusterListener className="org.apache.catalina.ha.session.ClusterSessionListener"/>
        </Cluster>
```

### 配置项目 web.xml

修改项目中的 `web.xml`，添加如下：

```xml
<distributable/>
```

### 配置端口

修改 `Tomcat/conf/context.xml`，修改端口，避免冲突此处就省略了。

## 验证

### 负载均衡：

首先，同一个页面刷新两次，查看访问请求，页面变化：

![](https://www.holddie.com/img/20200105144750.png)

然后，刷新一次：

![](https://www.holddie.com/img/20200105144802.png)

### 页面示例代码：

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
      <td>39080</td>
    </tr>
</table>
```



好，至此简单的搭建 Nginx + Tomcat 内置实现 Session 共享，更深的文章我们可以参考官方文档，内部讲解有很多模式，当然在服务器不多的情况下，使用此方式简单，当时容器当达到一定的数量，会出现瓶颈。

![wallhaven-161750](/img/2018/02/wallhaven-161750.jpg)

参考链接：

> [Clustering/Session Replication HOW-TO]: https://tomcat.apache.org/tomcat-8.5-doc/cluster-howto.html
> [N个tomcat之间实现Session共享]: http://blog.csdn.net/wlwlwlwl015/article/details/48160433/