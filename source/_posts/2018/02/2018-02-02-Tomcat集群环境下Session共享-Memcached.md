---
title: Tomcat集群环境下Session共享--Memcached
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
  - Memcached
date: 2018-02-02 21:32:16
password:
summary:  
categories: Session
---

主要记录一下 Nginx + Memcached + Tomcat 实现 Session 共享  



## 集群环境信息

|     主机      |  端口   |            开源软件             |
| :---------: | :---: | :-------------------------: |
| 10.10.3.83  |  80   |        Nginx(1.12.2)        |
| 10.15.0.174 | 35080 |         Tomcat(8.5)         |
| 10.15.0.174 | 36080 |         Tomcat(8.5)         |
| 10.15.0.174 | 11211 | Memcached(Memcached-1.4.34) |
| 10.15.0.174 | 11212 | Memcached(Memcached-1.4.34) |

实验拓扑图：

![](https://www.holddie.com/img/20200105144317.png)

## Nginx 配置文件

```coffeescript
upstream xxx {
  server 10.15.0.174:35080;
  server 10.15.0.174:36080;
}
location /xxx/ {
  proxy_pass http://xxx/xxx/;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header REMOTE-HOST $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}

```

## 安装 Memcached

### 安装步骤

```shell
yum -y install libevent libevent-devel
wget http://memcached.org/files/memcached-1.4.34.tar.gz
tar -zvxf memcached-1.4.34.tar.gz
cd memcached-1.4.34
./configure --prefix=/usr/local/memcached
make && make install
```

### 启动 Memcached

```shell
cd /usr/local/memcached/bin
./memcached -d -m 900 -u root -l 10.15.0.174 -p 11211 -c 256 -P /tmp/memcached11211.pid
./memcached -d -m 900 -u root -l 10.15.0.174 -p 11212 -c 256 -P /tmp/memcached11212.pid
```

- -d：启动一个守护线程
- -m：分配给Memcached使用的内存数量，单位是MB，默认64MB
- -M：return error on memory exhausted (rather than removing items)
- -u：运行Memcached的用户，如果当前未root的话，需要使用此参数指定用户
- -l：监听的服务器IP地址，默认为所有网卡
- -p：设置Memcached的TCP监听的端口，最好是1024以上的端口
- -c：最大运行的并发连接数，默认是1024
- -P：设置保存Memcached的pid文件
- -f：chunk size growth factor（default：1.25）

## 安装配置 Tomcat

### 配置 JAR 包下载

这里使用 Gradle 下载相关 JAR 包，自行构建 build.gradle 文件

```groovy
apply plugin: 'java'

repositories{
    maven {
        url "http://maven.aliyun.com/nexus/content/groups/public"
    }
    mavenCentral()
}

dependencies{
   compile group: 'de.javakaffee.msm', name: 'memcached-session-manager-tc8', version: '2.1.1' // 必须
   compile group: 'de.javakaffee.msm', name: 'msm-kryo-serializer', version: '2.1.1' // 非必须
}

task getJars(type: Copy) {
  from configurations.runtime
  into 'lib' // 获取到的jar包位置
}
```

首选确保本地有 Gradle 环境，然后在所在文件目录下运行： `gradle getJars` ，然后运行完成以后，就可以在 lib 文件下得到所需 JAR，然后将其拷贝至 Tomcat 的 lib 目录下面。

### 配置 Manager

修改 `Tomcat/conf/context.xml`，添加如下：

```xml
<Manager className="de.javakaffee.web.msm.MemcachedBackupSessionManager"
            memcachedNodes="n1:10.15.0.174:11211 n2:10.15.0.174:11212"    
            lockingMode="auto"
            sticky="false"
            requestUriIgnorePattern= ".*\.(png|gif|jpg|css|js)$"   
            sessionBackupAsync= "true"  
            sessionBackupTimeout= "1800000"     
            copyCollectionsForSerialization="true"
            transcoderFactoryClass="de.javakaffee.web.msm.serializer.kryo.KryoTranscoderFactory"   
    />
```

参数详解：

- memcachedNodes：Memcached 节点配置信息，可以配置多个Memcached，这里配置了两个。
- sticky：当为 true 时，为 sticky 模式 ，此时Tomcat以本地Session为主，Memcached上的Session为备，配置为 non-sticky 模式，Tomcat 以Memcached上Session为主，本地作为中转。
- requestUriIgnorePattern：当匹配该正则表达式的请求URL到达时，不进行Session备份。

### 配置端口

修改 `Tomcat/conf/context.xml`，修改端口，避免冲突此处就省略了。

## 验证

### 负载均衡：

首先，同一个页面刷新两次，查看访问请求，页面变化：

![](https://www.holddie.com/img/20200105144353.png)

然后，刷新一次：

![](https://www.holddie.com/img/20200105144404.png)

### Memcached 验证

思路：此处实验使用了两台Memcached，因此我们会先访问，查看访问那个节点

![](https://www.holddie.com/img/20200105144425.png)

可以看出，此时 session 来自 Memcached2，此处 n2 对应上述的 Manager 中配置的 n2，此处我们关闭 n2 观察现象

![](https://www.holddie.com/img/20200105144436.png)

关闭 11212 端口的 Memcached ，此时访问观察，

![](https://www.holddie.com/img/20200105144448.png)

观察到此时，缓存来自 n1，但是 Session 并没有发生变化，表明我们搭建的环境没有问题，此处还有个小细节，就是观察 Tomcat 的日志。

![](https://www.holddie.com/img/20200105144455.png)

系统发现 11212 端口的拒绝连接报错，这个就是那个缓存坏掉，此时还会一直尝试连接，若此时我们再把 11212 端口的启动，就会发现 n2 又会加入到这个 Session 集群中，并且不会报错。

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
</table>
```



好，至此简单的搭建 Nginx + Tomcat + Memcached 实现 非粘性 Session 共享，老铁没毛病。



参考链接：

> [Tomcat使用Memcached Session Manager管理Session]: http://www.bijishequ.com/detail/437229
> [基于memcached-session-manager的tomcat session共享集群]: http://blog.51cto.com/732233048/1909682
> [Tomcat集群环境下session共享方案梳理-通过memcached（MSM）方法实现]: http://www.cnblogs.com/kevingrace/p/6398672.html

