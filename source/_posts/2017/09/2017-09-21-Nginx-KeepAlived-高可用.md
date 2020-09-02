---
title: Nginx-KeepAlived-高可用
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - 高可用
  - 负载均衡
  - 反向代理
date: 2017-09-21 21:32:16
password:
summary:  
categories: Nginx
---



Nginx 和 KeepAlived 构建高可用的应用场景

## 笔记速记

+ Nginx 服务器服务支撑并发量，高可用 和 多个 Nginx 没有关系，只有一个节点对外服务

+ 配置多个 Nginx，当一个Nginx 挂了，切换到其他 Nginx

+ keepAlived 也可以使用到 redis 中，哨兵，服务器高可用、热备、防止单点故障

+ KeepAlived 以 VRRP 协议，实现高可用，VRRP（Virtual Router Redundancy Protocol）协议时用于实现路由器冗余的协议，VRRP 协议将两台或多台路由器设备虚拟成一个设备，对外提供虚拟路由器 IP （一个或多个）

  ![](https://www.holddie.com/img/20200105125411.png)


## KeepAlived 安装步骤

### 快速安装

+ 下载 Keepalived 地址：http://www.keepalived.org/
+ 上传解压：`tar -zxvf  keepalived-1.3.6 -C /usr/local/` 
+ 安装包依赖：`yum install -y openssl openssl-devel` 
+ `cd keepalived-1.3.6/ && ./configure --prefix=/usr/local/keepalive` 
+ `make && make install`  

#### 设置为系统服务

+ 因没有使用 Keepalived 的默认路径安装（默认是 /usr/local），故安装完需要手动复制默认的配置文件到默认路径


+ 复制默认的配置文件到默认路径

  ```shell
  mkdir /etc/keepalived
  cp /usr/local/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/
  ```


+ 复制 Keepalived 服务脚本到默认的地址

  ```shell
  cp /usr/local/keepalived/etc/init.d/keepalived /etc/init.d
  cp /usr/local/keepalived/etc/sysconfig/keepalived /etc/sysconfig
  ln -s /usr/local/sbin/keepalived /usr/sbin/
  ln -s /usr/local/keepalived/sbin/keepalived /sbin/
  ```


+ 设置 keepalived 服务开机启动

  ```shell
  chkconfig keepalived on
  ```

## 配置文件说明

### keepalived.conf

```shell
! Configuration File for keepalived

global_defs {
   router_id zie6  #机器标识，通常可以为 hostname ，故障发送时，邮件通知会用到
}

# 定义脚本，主要是告诉 keepalived 在什么情况下切换，可以定义多个 vrrp_script
vrrp_script chk_nginx {
#       script "killall -0 nginx"
        script "/etc/keepalived/check_nginx.sh" #自己写的检测脚本
        interval 2  #检测时间间隔
        weight -20  #检测失败（脚本返回非 0 ）则优先级 -20
        fall 3	#检测连续两次失败才算是真正的失败
        rise 2  #检测一次成功就算成功，但不修改优先级
}


vrrp_instance VI_1 {
    state MASTER #指定 instance 的初始状态，但是实际的状态还是通过优先级竞选来确定状态，状态分为：MASTER 和 BACKUP
    interface ens33 #实际用于访问网卡
    virtual_router_id 26 #设置 VRID，这里非常重要，相同的 VRID 为一个组，它决定多播的 MAC 地址
    priority 106 #设置本节点的优先级，优先级高的为：master
    advert_int 2 #检查间隔，默认为 1s
    authentication { #定义认证方式和密码，主从必须一样
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress { #设置的虚拟 IP 地址，这里可以设置多个 IP 地址
        192.168.123.66
    }
    track_script { #引用 VRRP 脚本，即在 vrrp_script 部分指定的名字，定期运行它来改变优先级，并最终引发准备切换
        chk_nginx
    }
}
```

### 注意：

+ 周期性的执行自定义的脚本，通知 keepAlived，修改主节点状态
+ 优先级，property 会优先选择优先级高的，当发现有节点坏掉，则权重就会下降，则会选择低权重机器，进行优先级大小对比，优先级高的胜出
+ 保证不同机器起始设置的权重不同
+ 必须保证不同机器中的 `virtual_router_id` 相同

## 检测脚本编写

检测脚本一般有两种写法：

+ 通过脚本执行的返回结果，改变优先级，keepalived 继续发送通告消息，backup 比较优先级再决定
+ 脚本里面检测到异常，直接关闭 keepalived 进程，backup 机器接收不到 advertisement 会抢占 IP

接下来分别提供两个脚本：

### 第一种：(根据状态改变相应的权重)

```shell
#!/bin/bash
# curl -IL http://localhost/
# curl --data "" http://localhost/

count=0
for (( k=0; k<2; k++))
do
	check_code=$( curl --connect-timeout 3 -sL -w "%{http_code}\\n" http://localhost/ -o /dev/null)
	if [ "$check_code" != "200" ]; then
		count=$(expr $count + 1)
		sleep 3
		continue
	else
		count=0
		break
	fi
done
if [ "$count" != "0" ]; then
	exit 1
else
	exit 0
fi
```

### 第二种：(比较暴力直接 kill 服务)

```shell
#!/bin/bash
counter=$(ps -C nginx --no-heading|wc -l)
if [ "${counter}" = "0" ]; then
	/usr/local/nginx/sbin/nginx
	sleep 2
	counter=$(ps -C nginx --no-heading|wc -l)
	if [ "${counter}" = "0" ]; then
		killall keepalived
	fi
fi
```

#### 注意：

+ 优先级不会不断的提高或者降低
+ 可以编写多个检测脚本并未每个检测脚本设置不同的 weight 
+ 不管提高优先级还是降低优先级，最终优先级的范围是 [1,254]，不会出现优先级小于等于 0 或者大于 255 的情况
+ 在 MASTER 节点的 vrrp_instance 中配置 `nopreempt` ,当它异常恢复后，即使它的优先级更高也不会抢占，这样避免在正常情况下做无谓的切换

## 测试截图：

+ 启动三台 Nginx 虚机

![](https://www.holddie.com/img/20200105125513.png) 

![](https://www.holddie.com/img/20200105125528.png)

![](https://www.holddie.com/img/20200105125727.png)



+ 三台主机的的权重分别为：104、105 、106，设置的虚拟的 IP为：`192.168.123.66`，故在第一次启动 keepalived 时,会优先选第三台机器：

![](https://www.holddie.com/img/20200105125746.png)

### 使用第一种脚本

##### 此时我们开始搞事情，使用第一种检测脚本，我们关闭 Nginx 时，由于 curl 不通，第三台机器的权重会 `-20` 此时，轮到了第二台机器上了

停止 Nginx 服务，执行命令： 

![](https://www.holddie.com/img/20200105125809.png)

![](https://www.holddie.com/img/20200105125841.png) 

此时 keepalived 服务还启动着：

![](https://www.holddie.com/img/20200105125855.png)

### 使用第二种脚本

起始状态

![](https://www.holddie.com/img/20200105125908.png)

#### **思路：**

​	首先自己停止 Nginx ，检测脚本就会瞬间启动，效果不明显，我们只有先修改配置，故意少个分号，让启动报错，此时完成场景模拟

修改配置文件：

![](https://www.holddie.com/img/20200105130000.png)

杀死进程：

![](https://www.holddie.com/img/20200105130009.png)

来再切换一波：

![](https://www.holddie.com/img/20200105130009.png)

至此，基本的 Nginx 和 Keepalived 高可用的场景基本搭建完毕。 