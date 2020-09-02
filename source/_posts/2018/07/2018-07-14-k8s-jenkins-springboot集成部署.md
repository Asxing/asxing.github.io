---
title: k8s-jenkins-springboot集成部署
tags: [k8s,Docker,SpringBoot, CI/DI]
img: https://www.holddie.com/img/20200105161747.jpg
date: 2018-07-14 10:43:51
categories: CI/DI
---

生命，如虫翼般轻薄脆弱，似野草般顽强坚韧。														——吾之秦韵



### Win10 Docker Push 信任

首先遇见自己本地Docker镜像打包到阿里云是没有问题，因此假装自己明白，然后部署到本地的docker镜像库中，Harbor 中，根据自己的理解不就是替换一下提交注册中心么？然后把settings文件的用户信息修改一下，然后就没问题了，然鹅事实是：

>  **x509: certificate signed by unknown au thority**

```shell
HoldDie@piglets /d/workspace/zeus-piglets (aliyun)
λ docker login -u=image-puller -p=Image-puller.0 registry.d.peiqi.com
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Error response from daemon: Get https://registry.d.peiqi.com/v2/: x509: certificate signed by unknown authority
```

根据经验就是配置证书，docker client 没有信任，然后我记得大哥们使用的都是MAC，自己在对应的Docker安装目录下添加对应的cert，然鹅，同理在win10下，找了一圈没有找见，最后，破罐子破摔的情况下，添加了如图：

![](https://www.holddie.com/img/20200105161833.png)



### Maven 引入外部  jar 包的几种方式

#### 1、dependency 本地 jar 包

```xml
<dependency>
    <groupId>com.hope.cloud</groupId>  <!--自定义-->
    <artifactId>cloud</artifactId>    <!--自定义-->
    <version>1.0</version> <!--自定义-->
    <scope>system</scope> <!--system，类似provided，需要显式提供依赖的jar以后，Maven就不会在Repository中查找它-->
    <systemPath>${basedir}/lib/cloud.jar</systemPath> <!--项目根目录下的lib文件夹下-->
</dependency> 
```

#### 2、编译阶段指定外部lib

```xml
<plugin>
    <artifactId>maven-compiler-plugin</artifactId>
    <version>2.3.2</version>
    <configuration>
        <source>1.8</source>
        <target>1.8</target>
        <encoding>UTF-8</encoding>
        <compilerArguments>
            <!--指定外部lib-->
            <extdirs>lib</extdirs>
        </compilerArguments>
    </configuration>
</plugin>
```

#### 3、将外部jar打入本地maven仓库

##### 3.1、CMD 进入jar包所在路径，执行以下命令

```shell
mvn install:install-file -Dfile=cloud.jar -DgroupId=com.hope.cloud -DartifactId=cloud -Dversion=1.0 -Dpackaging=jar
```

##### 3.2、引入依赖

```xml
<dependency>
    <groupId>com.hope.cloud</groupId>
    <artifactId>cloud</artifactId>
    <version>1.0</version>
</dependency>
```

下文就是使用Jenkins的pipeline编写两行命令：

- 一个是maven打包，同时就会上传镜像
- 使用对应的命令空间，进行 `kubectl set image xxx` 更新镜像