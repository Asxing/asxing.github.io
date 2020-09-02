---
title: Java爬虫-Selenium基操（六）
author: HoldDie
tags: [Java,爬虫,Selenium]
top: false
date: 2018-11-22 19:43:41
categories: 爬虫
---



> **战士的坟墓比奴隶的天堂更明亮。 ——陈辉**

## Selenium 一些设置

### 1、Selenium 初始化窗口参数

```java
System.setProperty("webdriver.chrome.driver", "xxx/chromedriver");
// Chrome
ChromeOptions options = new ChromeOptions();
// 启动就最大化
// options.addArguments("start-fullscreen");
// options.addArguments("--start-maximized");
// 禁止弹出拦截
options.addArguments("--disable-popup-blocking");
// 取消沙盘模式
options.addArguments("no-sandbox");
// 禁止扩展
options.addArguments("disable-extensions");
// 禁止默认浏览器检查
options.addArguments("no-default-browser-check");
options.addArguments("about:histograms");
options.addArguments("about:cache");
// 设置浏览器固定大小
options.addArguments("--window-size=1600,900");
// chrome正受到自动测试软件的控制
options.addArguments("disable-infobars");
WebDriver driver=new ChromeDriver(options);
// 设置浏览器的位置：
// Point point=new Point(0,0);
// driver.manage().window().setPosition(point);
// 注意：设定了浏览器固定大小后，浏览器打开后浏览器的位置可能会变到其他位置，因此可以使用设置刘浏览器的位置方法和设置浏览器的大小方法一起使用；
// driver.manage().window().maximize();
// 设置获取页面元素的最大等待时间
driver.manage().timeouts().implicitlyWait(15, TimeUnit.SECONDS);
// 打开网址
driver.get("www.baidu.com");
// 关闭浏览器
driver.quit();
```

### 2、Selenium 元素等待的四种方式

#### 2.1、使用Java 休眠

> 使用**Thread.sleep()**

#### 2.2、隐示等待

> 隐性等待是指当要查找元素，而这个元素没有马上出现时，告诉WebDriver查询Dom一定时间。
>
> 默认值是0,但是设置之后，这个时间将在WebDriver对象实例整个生命周期都起作用。

```java
WebDriver dr = new FirefoxDriver();
dr.manage().timeouts().implicitlyWait(10, TimeUnit.SECONDS); 
```

#### 2.3、使用javascript

```java
WebElement element = driver.findElement(By.xpath(test));
((JavascriptExecutor)driver).executeScript("arguments[0].style.border=\"5px solid yellow\"",element);  
```

#### 2.4、显示等待,推荐使用显示等待

> 显式等待 使用ExpectedConditions类中自带方法， 可以进行显试等待的判断。
>
> 显式等待可以自定义等待的条件，用于更加复杂的页面等待条件
>
> （1）页面元素是否在页面上可用和可被单击：elementToBeClickable(By locator)
>
> （2）页面元素处于被选中状态：elementToBeSelected(WebElement element)
>
> （3）页面元素在页面中存在：presenceOfElementLocated(By locator)
>
> （4）在页面元素中是否包含特定的文本：textToBePresentInElement(By locator)
>
> （5）页面元素值：textToBePresentInElementValue(By locator, java.lang.String text)
>
> （6）标题 (title)：titleContains(java.lang.String title)
>
> 只有满足显式等待的条件满足，测试代码才会继续向后执行后续的测试逻辑
>
> 如果超过设定的最大显式等待时间阈值， 这测试程序会抛出异常。

```java
WebDriverWait wait = new WebDriverWait(dr, 10);
wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("kw")));
```

#### 2.5、实战

```xml
<html>

    <head>
        <title>Set Timeout</title>
        <style>
            .red_box {
            background-color: red;
            width: 20%;
            height: 100px;
            border: none;
            }
        </style>
        <script>
            function show_div() {
            setTimeout("create_div()", 5000);
            }

            function create_div() {
            d = document.createElement('div');
            d.className = "red_box";
            document.body.appendChild(d);
            }
        </script>
    </head>

    <body>
        <button id="b" onclick="show_div()">click</button>
    </body>

</html>
```

##### 隐式操作

```java
// 隐式操作
driver.manage().timeouts().implicitlyWait(20, TimeUnit.SECONDS);
WebElement element = driver.findElement(By.cssSelector(".red_box"));
((JavascriptExecutor)driver).executeScript("arguments[0].style.border = \"5px solid yellow\"",element);
```

##### 显示操作

```java
// 显示操作
WebDriverWait wait = new WebDriverWait(driver, 20);
wait.until(ExpectedConditions.presenceOfElementLocated(By.cssSelector(".red_box")));
WebElement element = driver.findElement(By.cssSelector(".red_box"));
((JavascriptExecutor)driver).executeScript("arguments[0].style.border = \"5px solid yellow\"",element);
```

### **3、定时操作(pollingEvery)**

> 这个是设置个一段时间就去做一件事，例如下面设置隔一秒就去查找元素一次。

```java
 WebDriverWait wait = new WebDriverWait(driver,30);
 wait.pollingEvery(1, TimeUnit.SECONDS);
 driver.findElement(By.xpath("xxxx"));
```

### 4、总结：

> 在此处记录一下我在使用Selenium进行抓取验证码，识别，回填，以及登录的操作。

#### 4.1、验证码识别

 首先从识别验证码的说起🤓，看见网上对于验证码的识别有很多操作，有很多思路，比如二值化，tess4j,然后针对不同验证码格式，我们有不同的方式，当然我要爬取的网站使用的验证码，就比较规整，然后数字之间距离相同，因此可以使用以下方式，将验证码进行切分，然后进行降噪，去除污点，然后我们筛选出来比较规则的图片，并且重新命名，以供之后作为模板对比使用。然后当我们下一次要验证一个验证码的时候，同样的道理进行切分，然后用切分之后的图片和模板进行比较，双重for循环长和宽，对每一个像素进行比较，当两者的像素不一样就加一，然后比较那一次的rank值小，就是接近，然后这样循环往复，可以计算出验证码的每一个值。当然每一种方式都会有成功率，我最后的结果是，当识别100个数字的时候，错误率在16%，可能觉得高，但是反过来想百分之八十的识别率还是很高滴。 :smile:

tips：

 由于此次采用的是像素比较，首先我采用的是肉眼筛选出每一个数字，然后使用了Photoshop进行每一张图片的优化，这样使得我的结果中匹配率会更高一些。

 至此验证码识别说完，而且识别率已达到可接受范围，然后就说一下抓取。

#### 4.2、抓取验证码

 刚开始使用的是Selenium，看见网上的教程针对于验证码普遍做法就是，创建一个快照，进行元素定位，获取图片的宽和高，进行图片剪切，然后将图片存到指定的位置，之后就开始使用。

 同样的思路我也就哼哧哼哧的照着这个方向来，使用Selenium打开登录的页面，进行验证码的截取，存放指定位置，然后调用相应的识别服务，哇，1111，当时心凉，然后我倒指定文件夹📂下看，也是有图片的呀，因为我对自己的图片识别服务肯定有信心的，但是为啥就是识别不出来呢，此时我就打开图片进行浏览，此时返现图片的大小变啦，原本训练的时候是 `70×30`现在我一瞅图片变成了`93×40`，完全不符合心里预期，然后肿么办，自己使用预览工具设置了图片按比例缩放，然后再次调用图片识别服务，此时返回了可靠的数字，因为在使用Selenium的时候可以设置浏览器的大小，心里在想，难道是浏览器的窗口太大了，需要我自己调整一下 `1600*70/93 =1204.3` 、`900*70/93 =677.4`，然后重试，还是不行，这是什么原因，是前端对图片所在的样式进行了缩放，与浏览器的窗口大小没有关系。😳

 然后我的想法就是，那就是现在把下载好的图片进行按比例缩放之后，然后调用图片识别服务，照着这个思路我就迅速在网上找了一个轮子（🤣我当然是不会背了），然后就三下五除二，凑出按比例缩放，🤔继续尝试，然后整个流程进行运行，然后返现验证码还是根本牛头不对马嘴呀，心里犯嘀咕😨，这就是我想要的验证码图片么？咋就不行呢。

 想要验证码模拟登陆，首先就要知道验证码的原理，服务端维护了当前的cookie 和 验证码的对应关系🤝，当我们在页面上刷新验证码的时候，后台服务器进行相应的维护，每次输入验证码之后，服务端进行对比，若相同则登录成功，否则服务端重新生成验证码，以前的验证码失效，如此往复，直至成功为止。

 好的我们继续上面的思路，然后我想这个一定是图片的像素已经严重失真了😭，一次截取，一次等比例压缩，然后再识别。此时这种思路已经行不通了，然后我就在想我训练验证码识别服务的时候，图片是怎么抓取的，现在与当时有什么不同，经过上边的讲述，我们知道就是要维护好cookie，当我们去服务端访问的时候，我们的cookie是不变的，然后我就使用Java原生的请求，将Cookie注入到请求中。然后同样小操作整一波，图片放到指定操作，然后进行图片识别。

#### 4.3、回填、登录

 接下来的坑就没有什么了，只要样式定位准确，然后就是当登录成功之后，我们要使用 Cookie 回填，当以后请求的时候我们只要带上就 `OJBK`👌了。