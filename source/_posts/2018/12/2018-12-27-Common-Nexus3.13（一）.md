---
title: Common-Nexus3.13（一）
author: HoldDie
tags: [Nexus,Maven,Common]
top: false
date: 2018-12-27 19:43:41
categories: Maven
---

**死亡能带走生命，却带不走生命的痕迹。 ——泡沫**

> 常用基础工具，Nexus

### 1、仓库说明

**maven-central**：maven中央库，默认从https://repo1.maven.org/maven2/拉取jar

**maven-releases**：私库发行版jar

**maven-snapshots**：私库快照（调试版本）jar

**maven-public**：仓库分组，把上面三个仓库组合在一起对外提供服务，在本地maven基础配置settings.xml中使用。

#### 1.1、 **仓库类型:**

- **group(仓库组类型)**:又叫组仓库，用于方便开发人员自己设定的仓库；
- **hosted(宿主类型)**:内部项目的发布仓库(内部开发人员，发布上去存放的仓库);
- **proxy(代理类型)**:从远程中央仓库中寻找数据的仓库。

### 2、配置说明

#### 2.1、setting文件配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" 
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
    <!-- <localRepository>D:\environment\apache-maven-3.5.2\repo</localRepository> -->
    <mirrors>
        <mirror>
            <id>nexus-peiqi</id>
            <name>nexus-peiqi maven</name>
            <url>http://nexus.d.peiqi.com/repository/maven-central/</url>
            <mirrorOf>central</mirrorOf>
        </mirror>
        <mirror>
            <id>alimaven</id>
            <name>aliyun maven</name>
            <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
            <mirrorOf>central</mirrorOf>
        </mirror>
    </mirrors>
    <servers>
        <server>
            <id>loan-local-k8s</id>
            <username>admin</username>
            <password>Harbor12345</password>
        </server>
        <server>
            <id>loan-aliyun</id>
            <username>yangze@ucfgroup</username>
            <password>Yangzea2018$</password>
        </server>
        <server>
            <id>nexus-peiqi-release</id>
            <username>yangze</username>
            <password>123456</password>
        </server>
        <server>
            <id>nexus-peiqi-snapshot</id>
            <username>yangze</username>
            <password>123456</password>
        </server>
    </servers>
    <profiles>
        <profile>
            <id>dev</id>
            <!-- 配置远程仓库列表 -->
            <repositories>
                <!-- 远程仓库的配置信息 -->
                <repository>
                    <!-- 远程仓库唯一标识-->
                    <id>nexus-peiqi-central</id>
                    <!-- 远程仓库名称 -->
                    <name>nexus for peiqi develop</name>
                    <!-- 远程仓库URL -->
                    <url>http://nexus.d.peiqi.com/repository/maven-central/</url>
                    <releases>
                        <!--是否使用这个资源库下载这种类型的构件 默认值：true-->
                        <enabled>true</enabled>
                        <!--指定下载更新的频率。这里的选项是：always（一直），daily（每日，默认值），interval：X（这里X是指分钟），或者never（从不）。 -->
                        <updatePolicy>always</updatePolicy>
                        <!--当Maven验证构件校验文件失败时该怎么做fail（失败）或者warn（告警）。-->
                        <checksumPolicy>warn</checksumPolicy>
                    </releases>
                    <snapshots>
                        <!--是否使用这个资源库下载这种类型的构件 默认值：true-->
                        <enabled>true</enabled>
                        <!--指定下载更新的频率。这里的选项是：always（一直），daily（每日，默认值），interval：X（这里X是指分钟），或者never（从不）。 -->
                        <updatePolicy>always</updatePolicy>
                        <!--当Maven验证构件校验文件失败时该怎么做fail（失败）或者warn（告警）。-->
                        <checksumPolicy>warn</checksumPolicy>
                    </snapshots>
                </repository>
            </repositories>
        </profile>
    </profiles>
</settings>
```

#### 2.2、pom文件配置

```xml
<distributionManagement>
    <repository>
        <!-- id需要与setting.xml server中配置的 id 一致 -->
        <id>releases</id>
        <name>maven-releases</name>
        <url>http://xxx.xxx.xxx.xxx/repository/maven-releases/</url>
    </repository>
    <snapshotRepository>
        <id>snapshots</id>
        <name>maven-snapshots</name>
        <url>http://xxx.xxx.xxx.xxx/repository/maven-snapshots/</url>
    </snapshotRepository>
</distributionManagement>
```

#### 2.3、仓库配置

> 设置允许提交

### 3、遇见问题

#### 3.1、下载包时，权限不足

> Plugin org.apache.maven.plugins:maven-clean-plugin:3.1.0 or one of its dependencies could not be resolved: Failed to read artifact descriptor for org.apache.maven.plugins:maven-clean-plugin:jar:3.1.0: Could not transfer artifact org.apache.maven.plugins:maven-clean-plugin:pom:3.1.0 from/to nexus-peiqi (http://nexus.d.peiqi.com/repository/maven-public/): Not authorized , ReasonPhrase: Unauthorized. -> [Help 1]

大概率是使用对应的账号不对应，至此对应的问题基本没有了。