---
title: Java爬虫-HeadlessChrome+Selenium+ChromeDriver无头抓取（七）
author: HoldDie
tags: [Java,爬虫,Headless,Selenium]
top: false
date: 2018-11-26 19:43:41
categories: 爬虫
---



**汹涌浪潮先消磨你的心智，水下暗礁在摇摆间把你的航船击沉。 ——你的名字**



> 线下开发一切很顺利，然后细细一想，上线之后都是用Docker驱动，哪里来的Chrome界面，供我操作，故作此篇。😳

### 0、重要流程

```shell
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

yum clean all

curl https://intoli.com/install-google-chrome.sh | bash

ldd /opt/google/chrome/chrome | grep "not found"

google-chrome-stable --no-sandbox --headless --disable-gpu --screenshot https://www.suning.com/

yum install  \
 ipa-gothic-fonts \
 xorg-x11-fonts-100dpi \
 xorg-x11-fonts-75dpi \
 xorg-x11-utils \
 xorg-x11-fonts-cyrillic \
 xorg-x11-fonts-Type1 \
 xorg-x11-fonts-misc -y

# 安装最新的ChromeDriver
# 绑定127.0.0.1 localhost
vim  /etc/hosts
# 下载对应的ChromeDriver https://npm.taobao.org/mirrors/chromedriver/
# 将对应的ChromeDriver放置到 /opt/drivers 文件夹下
# 然后
./chromedriver
```

### 1、Docker 镜像制作：

```shell
docker  pull centos

docker images

docker run -it centos:lastest /bin/bash

.....

docker commit -a="holddie" -m="init test" xxxxxx centos:v2

docker run -it -p 8080:60513 centos:v2 /bin/bash
```

### 2、DockerFile 文件

```dockerfile
FROM registry.cn-beijing.aliyuncs.com/zeus-mall/zeus-spider:init

WORKDIR  /opt/drivers

ENV PORT 60513
EXPOSE 60513

COPY *.jar /opt/drivers

ENV LANG zh_CN.UTF-8

ENV TZ="Asia/Shanghai"

ENV JAVA_OPTS="$JAVA_OPTS -Xms512m -Xmx512m"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

CMD mkdir logs && java -Dfile.encoding="utf-8"  $JAVA_OPTS -jar *.jar 2>&1 | tee ./logs/app.log


可以 nohup启动
nohup java -jar motorcade_new.jar > nohup.out 2>&1 & 
```

### 3、上传阿里云

```shell
sudo docker login --username=yangze@ucfgroup registry.cn-beijing.aliyuncs.com
sudo docker tag [ImageId] registry.cn-beijing.aliyuncs.com/zeus-mall/zeus-spider:[镜像版本号]
sudo docker push registry.cn-beijing.aliyuncs.com/zeus-mall/zeus-spider:[镜像版本号]
```

### 4、`Java` 代码主要修改体现：

```java
/**
     * 配置ChromeDriver
     * @return WebDriver
     * @author HoldDie
     * @email HoldDie@163.com
     * @date 2018/11/28 6:59 PM
     */
public static WebDriver initChromeDriverProperty() {
    // 设置驱动程序路径
    // Chrome
    System.setProperty("webdriver.chrome.driver", ProjectConstant.WEBDRIVER_CHROME_DRIVER);
    ChromeOptions options = new ChromeOptions();
    // 禁止弹出拦截
    options.addArguments("--disable-popup-blocking");
    // 取消沙盘模式
    options.addArguments("--no-sandbox");
    // 无头声明
    options.addArguments("--headless");
    // 禁止GPU
    options.addArguments("--disable-gpu");
    options.addArguments("--disable-dev-shm-usage");
    options.addArguments("blink-settings=imagesEnabled=false");
    // 禁止扩展
    options.addArguments("--disable-extensions");
    // 禁止默认浏览器检查
    options.addArguments("--no-default-browser-check");
    options.addArguments("about:histograms");
    options.addArguments("about:cache");
    // 设置浏览器固定大小
    options.addArguments("--window-size=1600,900");
    // chrome正受到自动测试软件的控制
    options.addArguments("--disable-infobars");
    WebDriver driver = new ChromeDriver(options);
    // 设置获取页面元素的最大等待时间
    driver.manage().timeouts().implicitlyWait(20, TimeUnit.SECONDS);
    return driver;
}
```

> 最主要的就是要禁用GPU和无头声明。