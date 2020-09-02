---
title: Java爬虫-Appium一波（十二）
author: HoldDie
tags: [Appium,Java]
top: false
date: 2018-12-19 19:43:41
categories: 爬虫
---



**天空没有痕迹，风雨已在心中。 ——长路**

### 准备条件

- Java 环境
- 安卓虚拟机(7.1.1)
- Python环境(3.5)
- Appium 环境

#### Java 环境

#### 安卓虚拟机

- 本次使用的是7.1.1,刚开始使用的是9版本的,
- 基础的 Demo 是跑不通

#### Python 环境

环境也很重要,该开始一直使用的是py2.7之后,然后安装pip,指定版本才可以工作

#### Appium 环境

直接使用桌面版本,下载安装:https://github.com/appium/appium-desktop/releases,直接安装即可

最后使用的就是一段很简单的py代码:

```python
from appium import webdriver

desired_caps = {}
desired_caps['platformName'] = 'Android'
desired_caps['platformVersion'] = '7.1.1'
desired_caps['deviceName'] = 'Android Emulator'
desired_caps['appPackage'] = 'com.android.dialer'
desired_caps['appActivity'] = 'DialtactsActivity'

driver = webdriver.Remote('http://localhost:4723/wd/hub', desired_caps)
driver.find_element_by_id('com.android.dialer:id/search_box_collapsed').click()
search_box = driver.find_element_by_id('com.android.dialer:id/search_view')
search_box.click()
search_box.send_keys('hello toby')
```

查看本地连接设备:

```shell
adb devices
```

### 参考文章:

https://betacat.online/posts/2017-12-10/setup-appium-test-environment-on-mac-osx/