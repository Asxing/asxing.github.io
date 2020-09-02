---
title: OpenShift-线上调试
tags: [Debug, OpenShift, Docker, k8s]
img: https://www.holddie.com/img/20200105160432.jpg
date: 2018-06-06 16:41:10
categories: Debug
---

失败，总在成功之前发生，成功路上，放弃就是失败。					——白子



### 本地设置

首先下载oc客户端，解压文件之后，配置oc到path中

设置远程代理，登录命令

```shell
oc login os.quant.corp.ncfgroup.com:8443
```

登录成功之后会罗列出线上所有的命名空间

之后选择dsd环境

```shell
oc project dsd
```

查看 对应环境下的 po

```shell
oc get po
```

然后进行选择，本地代理

```shell
oc port-forward zeus-web-22-4fzbp 5005
```

之后本地就代理了远程的环境。



### OpenShift 设置

- 选择对应的命名空间
- 点击Applications中的Deployments
- 然后选择对应的项目，在对应的环境中设置
  - JAVA_DEBUG=true
  - JAVA_DEBUG_PORT=5005



### 开发工具

- 首先保证和远程运行的代码一致
- 然后选择代码的运行为远程并且，配置本地运行代理



























