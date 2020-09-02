---
title: Nginx+Keepalived
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Nginx
  - 高可用
date: 2017-11-10 21:32:16
password:
summary:  
categories: Nginx
---



### 关于 Nginx 部署结构图：

![](https://www.holddie.com/img/20200105142347.png)

### 问题1：阿里云是怎么访问到虚拟ip的？这个ip是个公网的？

![](https://www.holddie.com/img/20200105142356.png)

![](https://www.holddie.com/img/20200105142403.png)

这样就可以直接访问到虚拟ip了, 这个ip是公网的, 然后虚拟ip和端口号又找网络部门映射到我们内网的一个ip:端口号, 对于149和151服务器上的keepalived,实际上是配置的内网的ip.

### nginx作为反向代理时，检测后端服务器是否正常的原理是什么？什么时候会剔除一个节点？什么时候又会把剔除的节点加回来？proxy_connectiom_timeout这个参数一般怎么设置？

+ 这个就涉及到keepalived的原理了,keepalived是基于VRRP协议来实现的, 熟悉网络的读者对VRRP协议应该并不陌生,它是一种主备模式的协议,通过vrrp可以在网络发送故障时,透明地进行设备切换,而不影响主机间的数据通信, 这其中设计到两个概念: 物理路由器和虚拟路由器, vrrp可以将两台或者多台物理路由器设备虚拟成一个虚拟路由, 那我文章中举的例子,就是两台物理路由器(149和151服务器)


+ 这个虚拟路由器通过虚拟ip,对外提供服务,而在虚拟路由器内部,是多个物理路由器协同工作, 同一时间只有一台物理路由器对外提供服务,这台物理路由器就被称为主路由器(处于master角色),一般情况下,master由选举算法产生,它拥有对外服务的虚拟ip,提供各种网络功能, 而其他物理路由器,不拥有对外的虚拟ip,也不提供对外的网络功能,仅仅接收master的vrrp状态通告信息,这些路由器被统称为备份路由器(处于backup角色),当路由器失效时,处于backup角色的备份路由器,将重新进行选举,产生一个新的主路由器进入master角色继续提供对外服务,整个切换过程对用户来说完全透明
+ 每个虚拟路由器都有一个唯一标识,称为VRID,一个VRID与 一组ip地址构成了一个虚拟路由器,在vrrp协议中,所有的报文都是通过ip多播形式发送的,而在一个虚拟路由器中，只有处于MASTER角色的路由器会一直发送VRRP数据包，处于BACKUP角色的路由器只接收MASTER发过来的报文信息，用来监控MASTER运行状态，因此，不会发生BACKUP抢占的现象，除非它的优先级更高。而当MASTER不可用时，BACKUP也就无法收到MASTER发过来的报文信息，于是就认定MASTER出现故障，接着多台BACKUP就会进行选举，优先级最高的BACKUP将成为新的MASTER

### 什么时候会剔除一个节点？Keepalived工作在TCP/IP参考模型的第三、第四和第五层，也就是网络层、传输层和应用层。需要根据tcp/ip参考模型各层所能实现的功能.keepalived运行机制如下:

+ Keepalived在网络层采用的最常见的工作方式是通过ICMP协议向服务器集群中的每个节点发送一个ICMP的数据包（类似于ping实现的功能），如果某个节点没有返回响应数据包，那么就认为此节点发生了故障，Keepalived将报告此节点失效，并从服务器集群中剔除故障节点。
+ Keepalived在传输层就是利用TCP协议的端口连接和扫描技术来判断集群节点是否正常的。比如，对于常见的Web服务默认的80端口、SSH服务默认的22端口等，Keepalived一旦在传输层探测到这些端口没有响应数据返回，就认为这些端口发生异常，然后强制将此端口对应的节点从服务器集群组中移除
+ 在应用层, 用户可以通过自定义keepalived的工作方式,例如我的文章中写的check nginx脚本, 根据用户的设定检测服务是否正常,如果检测结果和用户设定的不一致,keepalived就会把对应的服务从服务器去中移除

#### 什么时候又会把剔除的节点加回来？

+ 当web服务器工作正常后Keepalived自动将web服务器加入到服务器群中

proxy_connectiom_timeout这个参数一般怎么设置？  60

### 集群模式下，session怎么管理呢？

如果是同组的, 有两种方式：

+ 1.tomcat1与tomcat2 之间session同步, 这个修改tomcat配置文件就可以, 两台都得改

```xml
<Engine name="Catalina" defaultHost="localhost"> 
  下面,增加内容: 
<Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster" channelSendOptions="8">  
  <Manager className="org.apache.catalina.ha.session.DeltaManager"  
                  expireSessionsOnShutdown="false"  
                  notifyListenersOnReplication="true"/>  
  
  <Channel className="org.apache.catalina.tribes.group.GroupChannel">  
    <Membership className="org.apache.catalina.tribes.membership.McastService"  
                address="228.0.0.4"  
                port="45564"  
                frequency="500"  
                dropTime="3000"/>  
    <Receiver className="org.apache.catalina.tribes.transport.nio.NioReceiver"  
              address="本机IP"  
              port="4000"  
              autoBind="100"  
              selectorTimeout="5000"  
              maxThreads="6"/>  

    <Sender className="org.apache.catalina.tribes.transport.ReplicationTransmitter">  
      <Transport className="org.apache.catalina.tribes.transport.nio.PooledParallelSender"/>  
    </Sender>  
    <Interceptor className="org.apache.catalina.tribes.group.interceptors.TcpFailureDetector"/>  
    <Interceptor className="org.apache.catalina.tribes.group.interceptors.MessageDispatch15Interceptor"/>  
  </Channel>  

  <Valve className="org.apache.catalina.ha.tcp.ReplicationValve" filter=""/>  
  <Valve className="org.apache.catalina.ha.session.JvmRouteBinderValve"/>  

  <Deployer className="org.apache.catalina.ha.deploy.FarmWarDeployer"  
            tempDir="/tmp/war-temp/"  
            deployDir="/tmp/war-deploy/"  
            watchDir="/tmp/war-listen/"  
            watchEnabled="false"/>  

  <ClusterListener className="org.apache.catalina.ha.session.JvmRouteSessionIDBinderListener"/>  
  <ClusterListener className="org.apache.catalina.ha.session.ClusterSessionListener"/>  
</Cluster>  
```

+ 方式2. session存到第三方,redis服务器中

  ![](https://www.holddie.com/img/20200105142553.png) 

+ 1.2修改配置文件（nginx服务器）： 
  文件路径：/usr/local/nginx-1.10.3/conf/nginx.conf 

  ```properties
  注：其中136和219是一组；224和134是一组 
  upstream dmsdGW_server{ 
  server 192.168.22.136:8080; 
  server 192.168.22.219:8080; 
  } 
  upstream dmsdGW_servergroup{ 
  server 192.168.22.224:8080; 
  server 192.168.22.134:8080; 
  } 
  server { 
  listen 8890; 
  server_name 192.168.22.229; 
  location / { 
  proxy_pass [http://dmsdGW_server](http://dmsdgw_server/); 
  } 
  location /b/ { 
  proxy_pass <http://192.168.22.246:8888/>; 
  } 
  access_log /usr/local/nginx-1.10.3/nginx.log; 
  error_log /usr/local/nginx-1.10.3/nginx_error.log; 
  } 
  server { 
  listen 8891; 
  server_name 192.168.22.229; 
  location / { 
  proxy_pass [http://dmsdGW_servergroup](http://dmsdgw_servergroup/); 
  } 
  location /b/ { 
  proxy_pass <http://192.168.22.246:8888/>; 
  } 
  access_log /usr/local/nginx-1.10.3/nginx.log; 
  error_log /usr/local/nginx-1.10.3/nginx_error.log; 
  } 
  ```

  注：在nginx中，倘若只写一个server，经过测试，那么这两组，共4个服务器，就会全部不一样。 
  但是经过上面的，写了两个server时，就可以正常实现组同步~，两个组互不影响

### Nginx配置中，配置proxy_pass时，nginx proxy_pass后面的url加与不加的区别是什么？

在nginx中配置proxy_pass时，当在后面的url加上了/，相当于是绝对根路径，则nginx不会把location中匹配的路径部分代理走;如果没有/，则会把匹配的路径部分也给代理走。

比如说:
```properties
location  /test/ {
	proxy_pass http://192.168.21.5:8090/;
}
访问nginx代理机器/test/ 就相当于直接访问的http://192.168.21.5:8090/;

location  /test/ {
	proxy_pass http://192.168.21.5:8090;
}
访问nginx代理机器/test/ 就相当于直接访问的http://192.168.21.5:8090/test/;
```
### Nginx如何启用gzip压缩js等文件（启用gzip后，网页与CSS压缩了，但是js文件没有压缩）？

```properties
nginx配置文件中配置  
gzip on; #开启gzip 
gzip_vary on; 
gzip_min_length 1k; #不压缩临界值,大于1k的才压缩,一般不用改 
gzip_buffers 4 16k; 
gzip_comp_level 6; #压缩级别,数字越大压缩的越好 
gzip_types text/plain application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png image/x-icon; #压缩文件类型,缺啥补啥
```

 配置完,reload nginx ,用curl 测试gzip是否成功开启了 

curl -I -H “Accept-Encoding: gzip,deflate” 这里可以输入网页地址,或者静态文件js等”
结果中出现 Content-Encoding: gzip,就证明压缩成功了, 如果没有的话, 看一下js的header信息,看它的content-type 项是什么, 然后就把内容添加到gzip_types中 