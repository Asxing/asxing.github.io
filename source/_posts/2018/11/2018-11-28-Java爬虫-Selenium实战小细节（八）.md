---
title: Java爬虫-Selenium实战小细节（八）
author: HoldDie
tags: [Java,Selenium]
top: false
date: 2018-11-28 19:43:41
categories: 爬虫
---



**猎人的眼睛从来不会闭上，因为野兽正在暗中注视着他。 ——尘鸟**



### 问题一：**invalid element state: Element must be user-editable in order to clear it**

> invalid element state: Element must be user-editable in order to clear it. (Session info: chrome

解决方法：

> 直接调用element.sendkeys ， 不需要再做一次element.clear()，否则会出现该异常：

### 问题二：unknown error: cannot focus element

> unknown error: cannot focus element

解决方法：

> 元素定位有问题

### 问题三：unexpected alert open: {Alert text : 登录成功}

> unexpected alert open: {Alert text : 登录成功}

解决方法：

> ```java
> driver.switchTo().alert().accept();
> ```
>
> 此处的弹框我们可以选择接受，这个写法在Python和Java中类似哦😯

#### 3.1、有等待的弹框

```java
// 有等待的弹框
WebDriverWait wait = new WebDriverWait(driver, 10);
try {
    Alert alert = wait.until(new ExpectedCondition<Alert>() {
        @Override
        public Alert apply(WebDriver driver) {
            try {
                return driver.switchTo().alert();
            } catch (NoAlertPresentException e) {
                return null;
            }
        }
    });
    alert.accept();
} catch (NullPointerException e) {
    /* Ignore */
    System.out.println("ff2 nullpoint");
}
```

#### 3.2、捕捉和处理Alert都加判断

```java
// 捕捉和处理Alert都加判断
@Test(enabled = false)
public void ff3() {
    System.setProperty(key, value);
    driver = new ChromeDriver();
    driver.get("file:///Users/user/Documents/qiaojiafei/seleniumtest.html");
    driver.findElement(By.xpath("//*[@id='alert']/input")).click();

    boolean flag = false;
    Alert alert = null;
    try {

        new WebDriverWait(driver, 10).until(ExpectedConditions
                                            .alertIsPresent());
        alert = driver.switchTo().alert();
        flag = true;
        // alert.accept();
    } catch (NoAlertPresentException NofindAlert) {
        // TODO: handle exception

        NofindAlert.printStackTrace();
        // throw NofindAlert;
    }

    if (flag) {
        alert.accept();
    }
}
```

#### 3.3、不清楚那块会弹窗时使用

```java
// 不清楚那块会弹窗时使用
@Test(enabled = false)
public void ff4() {
    System.setProperty(key, value);
    driver = new ChromeDriver();
    driver.get("file:///Users/user/Documents/qiaojiafei/seleniumtest.html");
    driver.findElement(By.xpath("//*[@id='alert']/input")).click();
    try {
        System.out.println("ff4正常处理代码1");
        driver.findElement(By.xpath("//*[@id='alert']/input")).click();
    } catch (UnhandledAlertException e) {
        // TODO: handle exception
        driver.switchTo().alert().accept();
        System.out.println("ff4进入UnhandledAlertException异常");
    }
    System.out.println("ff4正常处理代码2");
}
```

#### 3.4、初始化时全局处理

```java
// 初始化时全局处理
@Test(enabled = false)
public void ff5() {
    System.setProperty(key, value);
    DesiredCapabilities dc = new DesiredCapabilities();
    dc.setCapability(CapabilityType.UNEXPECTED_ALERT_BEHAVIOUR,
                     UnexpectedAlertBehaviour.ACCEPT);
    driver = new ChromeDriver(dc);
    driver.get("file:///Users/user/Documents/qiaojiafei/seleniumtest.html");
    driver.findElement(By.xpath("//*[@id='alert']/input")).click();

    driver.findElement(By.xpath("//*[@id='alert']/input")).click();
}
```

#### 3.5、实现事件监听接口WebDriverEventListener

```java
// 实现事件监听接口WebDriverEventListener，alert一般是在click事件之后触发的，所以在afterClickOn方法中对alert进行捕获
@Override
public void afterClickOn(WebElement arg0, WebDriver arg1) {
    // TODO Auto-generated method stub
    boolean flag = false;
    Alert alert = null;
    try {

        new WebDriverWait(arg1, 10).until(ExpectedConditions
                                          .alertIsPresent());
        alert = arg1.switchTo().alert();
        flag = true;
        // alert.accept();
    } catch (NoAlertPresentException NofindAlert) {
        // TODO: handle exception

        NofindAlert.printStackTrace();
        // throw NofindAlert;
    }

    if (flag) {
        alert.accept();
    }
}
```

### 问题四：(y + height) is outside of Raster

问题描述：

> (y + height) is outside of Raster

解决方法：

> 页面元素的定位问题,目前使用的是全屏

### 问题五：时间控件处理

问题描述：

> 获取时间控件的xpath，设置对应的值

解决方法：

> ```
> js.executeScript("document.querySelectorAll('.el-input__inner')[1].readOnly=false;");
> driver.findElement(loanPlatPropertyBo.getStartTimeXpath()).clear();
> driver.findElement(loanPlatPropertyBo.getStartTimeXpath()).sendKeys(startTime);
> 
> // 寻找结束时间编辑框
> js.executeScript("document.querySelectorAll('.el-input__inner')[2].readOnly=false;");
> driver.findElement(loanPlatPropertyBo.getEndTimeXpath()).clear();
> driver.findElement(loanPlatPropertyBo.getEndTimeXpath()).sendKeys(endTime);
> ```

### 问题六：判断登录网页是否刷新

> 暂时网页刷新

解决方法：

> ```java
> driver.navigate().refresh();
> driver.get(driver.getCurrentUrl());
> driver.navigate().to(driver.getCurrentUrl());
> driver.findElement(By.id("Contact-us")).sendKeys(Keys.F5); 
> driver.executeScript("history.go(0)");
> ```
>
> 方法显示判断
>
> ```java
> public static boolean waitPageRefresh(WebElement trigger) {
>     int refreshTime = 0;
>     boolean isRefresh = false;
>     try {
>         for (int i = 1; i < 60; i++) {
>             refreshTime = i;
>             trigger.getTagName();
>             Thread.sleep(1000);
>         }
>     } catch (StaleElementReferenceException e) {
>         isRefresh = true;
>         System.out.println("Page refresh time is:" + refreshTime + " seconds!");
>         return isRefresh;
>     } catch (WebDriverException e) {
>         e.printStackTrace();
>     } catch (InterruptedException e) {
>         e.printStackTrace();
>     }
>     System.out.println("Page didnt refresh in 60 seconds!");
>     return isRefresh;
> }}
> ```

### 问题七：下拉框处理

问题描述：

> 两种方式：
>
> - 一种是根据Xpath获取焦点，然后根据xpath选取对应的值
> - 一种是直接获取select框，设置值

解决方法：

> ```java
> JavascriptExecutor js = (JavascriptExecutor) driver;
> js.executeScript("document.querySelectorAll('.el-input__inner')[0].readOnly=false;");
> // 第一种方式
> driver.findElement(By.xpath("(//*[@class='el-input__inner'])[last()-2]")).click();
> driver.findElement(By.xpath("(//li[contains(@class,'el-select-dropdown__item')])[last()-1]")).click();
> 
> // 第二种方式
> Select userSelect=new Select(driver.findElement(By.xpath("(//*[@class='el-input__inner'])[last()-2]")));
> userSelect.selectByVisibleText("pandoraABLr");
> ```

### 问题八：切换frame框架

问题描述：

> 针对iframe框架页面，需要进行框架的切换，完成指定操作

解决方法：

> driver.switch_to.frame(‘iframe’)

### 问题九：invalid selector: Compound class names not permitted

问题描述：

> invalid selector: Compound class names not permitted

解决方法：

> 使用的Class的选择中间有很多空格，导致大，出现这种情况我们应使用Css定位
>
> 在获取包含多个class名称的tag对象时，建议使用：
>
> find_element_by_css_selector(“**.**xx**.**xxx**.**xxxxx”)
>
> 或者
>
> find_element_by_css_selector(“[class=’xx xxx xxxxx’]”)

### 问题十：原生的Cookie

> 对于登录成功之后可以获得网站的 Cookie，然后我们的思路就是使用Redis进行缓存，在之后的请求时，就不需要进行登录，直接抓取数据，对于获取的Cookie，设置进入Redis没有问题，但是取的时候，遇见很多问题。

**其中使用过Jackson和FastJson都不可以，都会有问题，最后使用 JdkSerializationRedisSerializer 。**

### 问题十一：很多页面有缓存进入不了对应界面

> 针对于有些网站，发现当每次访问登录页面的时候，就会重新生成一个JSESSIONID，这就导致当我们，针对于要抓取数据的网站，每次都必须访问两次，一次是设置Cookie，一次是抓取正确数据，但是当我们在第一次访问的时候，不好意思，直接跳转到登录界面，导致之前的Cookie失效，目前的做法就是直接进入进行操作，缓存的Cookie，作用不大。