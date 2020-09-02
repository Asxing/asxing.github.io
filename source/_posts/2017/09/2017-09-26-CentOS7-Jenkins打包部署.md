---
title: CentOS7-Jenkins-Git-Tomcat-集成部署
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Jenkins
  - Tomcat
  - Git
date: 2017-09-26 21:32:16
password:
summary:  
categories: Jenkins
---

CentOS 上 Jenkins-Git-Tmocat 集成部署

### 配置信息：

+ CentOS：7.2


+ Jenkins：2.79


+ Java Version：1.8
+ Maven：3.5
+ Git：1.8

### 安装 jenkins

因使用 yum 安装 jenkins ，故更新版本库

```shell
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
```

安装命令

```shell
yum install jenkins
```

若系统直接使用 yum 安装 Java 此时 JAVA_HOME 路径不用修改，可以直接启动 Jenkins，否则，应该编辑添加 java_home 路径：

```shell
vim /etc/init.d/jenkins
```

查看 JAVA_HOME 路径

```shell
echo $JAVA_HOME
```

![](https://www.holddie.com/img/20200105135957.png)

修改内容如下

![](https://www.holddie.com/img/20200105140007.png)

在运行过程中检查防火墙端口启动状况

```shell
systemctl status jenkins
systemctl start jenkins
systemctl start firewalld
firewall-cmd --zone=public --permanent --add-port=18080/tcp
firewall-cmd --reload
firewall-cmd --list-port
```

运行成功后访问：

![](https://www.holddie.com/img/20200105140019.png)

查看本地初始化密码：

```shell
cat /var/lib/jenkins/secrets/initialAdminPassword
```

选择插件默认点击左侧，

![](https://www.holddie.com/img/20200105140029.png)

然后稍等就会出现下面界面

![](https://www.holddie.com/img/20200105140038.png)

设置个人账号，然后点击下一步

![](https://www.holddie.com/img/20200105140047.png)

最后回到经典的页面：

![](https://www.holddie.com/img/20200105140058.png)

### Jenkins 部署 maven 项目 到 Tomcat

#### 插件安装

1. 首先 Jenkins 安装两个关键插件
   1. git plugin 插件（用于从 git 拉取最新的代码）
   2. publish over ssh 插件（用于上传打包好的项目到远程 Linux）
2. 进入系统管理 --> 插件管理 --> 可选插件，在搜索框中搜索，点击安装即可。
   + ![](https://www.holddie.com/img/20200105140107.png)
   + ![](https://www.holddie.com/img/20200105140107.png)
   + ![](https://www.holddie.com/img/20200105140127.png)

#### 项目构建

1. 新建项目

   ![](https://www.holddie.com/img/20200105140138.png)

2. 选择 构建一个 Maven 项目

   ![](https://www.holddie.com/img/20200105140150.png)

   可以我进来一看，哎，咋没这个选项呢（说好的呢），问了一下，狗爹，原来少安装 Maven 插件：`Maven Integration plugin`

   ![](https://www.holddie.com/img/20200105140159.png)

   二话不说，点击直接安装，然后又回去默默的点击了新建项目

   ![](https://www.holddie.com/img/20200105140231.png)

   看见没，乖乖的出来了。

3. 默默写上我收藏的Git，设计模式地址

   ![](https://www.holddie.com/img/20200105140239.png)

   填写 URL 地址

   ![](https://www.holddie.com/img/20200105140250.png)

   发现底下红线报错了，定眼一看，问题是没有配置 Git ，

   然后我回手就是一个 yum install git，服不服

   ```shell
   git --version
   ```

   ![](https://www.holddie.com/img/20200105140303.png)

   然后平息

4. 发现又有一处报错，没有配置 maven 选项

   ![](https://www.holddie.com/img/20200105140311.png)

   点击其中的 the tool configuration，缺少 maven 进行配置

   ![](https://www.holddie.com/img/20200105140321.png)

5. 在构建后操作中，我们选择 deploy war/jar to a container

   ![](https://www.holddie.com/img/20200105140402.png)

   ![](https://www.holddie.com/img/20200105140417.png)



6. 编译过程遇见错误：

   ![](https://www.holddie.com/img/20200105140440.png)

   主要原因：jenkins 系统的 jdk 是使用自带的，那个不靠谱，后来自己又手动自己设置了一遍

   ![](https://www.holddie.com/img/20200105140502.png)

7. 关于 Tomcat 配置

   1. 创建用户给用户权限，文件目录在 `apache-tomcat/conf/tomcat-users.xml`

      ```xml
      <role rolename="manager-gui"/>
      <role rolename="admin-gui" />
      <role rolename="manager-script" />
      <role rolename="admin-script" />
      <role rolename="manager-status" />
      <user username="tomcat" password="123456" roles="manager-gui,admin-gui, admin-script, manager-script, manager-status"/>
      ```

   2. 解决外网访问问题， 文件路径 `apache-tomcat/webapps/manager/META-INF/context.xml`

      ```xml
      <Valve className="org.apache.catalina.valves.RemoteAddrValve"
               allow="\d+\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
      ```

      ![](https://www.holddie.com/img/20200105140516.png)

      ![](https://www.holddie.com/img/20200105140525.png)

   3. 然后继续发布，这下不会错了

      ![](https://www.holddie.com/img/20200105140552.png)

   4. 我立马启动我准备已久的 Tomcat，验证一波，发现 war 包是放上去了，但是我正一访问，我滴哥，还是没有反应

      ![](https://www.holddie.com/img/20200105140607.png)

   5. 心急火燎，原来是没有 Tomcat 重启，自然看不见咯

8. Jenkins 部署 Tomcat 执行脚本重启（自以为），实则 maven 中的配置文件 pom 格式不对，一定要注意格式，不能瞎胡删除，要不错了都不知道

9. 最后模拟一遍流程

   1. 首先修改代码

      ![](https://www.holddie.com/img/20200105140623.png)

   2. 进行 Git 提交

      ![](https://www.holddie.com/img/20200105140633.png)

      上传成功

      ![](https://www.holddie.com/img/20200105140645.png)


   3. 进行 jenkins 打包

      ![](https://www.holddie.com/img/20200105140657.png)

      打包时状态

      ![](https://www.holddie.com/img/20200105140754.png)

   4. 访问网页操作

      ![](https://www.holddie.com/img/20200105140811.png)

   5. 出现乱码就是 pom 配置，有点问题，添加配置依赖

      ![](https://www.holddie.com/img/20200105140829.png)

   6. 重新打包依赖流程走一遍之后，访问网页，然而没有解决

7. 打包Maven编译错误：编码 GBK 的不可映射字符

  + 在项目 pom.xml 文件中添加配置

    ```xml
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    ```

  + 在 project/build/plugins/ 下的编译插件声明

    ```xml
    <encoding>UTF-8</encoding>
    ```