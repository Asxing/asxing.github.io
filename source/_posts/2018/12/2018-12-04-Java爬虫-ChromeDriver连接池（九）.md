---
title: Java爬虫-ChromeDriver连接池（九）
author: HoldDie
tags: [Java,爬虫,连接池,ChromeDriver]
top: false
date: 2018-12-04 19:43:41
categories: 爬虫
---



**汹涌浪潮先消磨你的心智，水下暗礁在摇摆间把你的航船击沉。 ——你的名字**

## ChromeDriver 连接池

> 基本的抓取功能完善以后，接下来就是优化的过程，本节使用**`Apache commons-pool`**实现连接池。

### 1、Pool 设计思想

>  commons-pool实现思想非常简单,它主要的作用就是将”对象集合”池化,任何通过pool进行对象存取的操作,都会严格按照”pool配置”(比如池的大小)实时的创建对象/阻塞控制/销毁对象等。它在一定程度上,实现了对象集合的管理以及对象的分发。

#### 1.1、主要步骤：

- 将创建对象的方式,使用工厂模式;
- 通过”pool配置”来约束对象存取的时机
- 将对象列表保存在队列中(LinkedList)

#### 1.2、生命周期

![image-20181204172859102](../../../../../../../../images/2018/12/image-20181204172859102.png)

#### 1.3、连接池配置参数

> 这些属性均可以在org.apache.commons.pool.impl.GenericObjectPool.Config中进行设定。

1. maxActive: 链接池中最大连接数,默认为8.
2. maxIdle: 链接池中最大空闲的连接数,默认为8.
3. minIdle: 连接池中最少空闲的连接数,默认为0.
4. maxWait: 当连接池资源耗尽时，调用者最大阻塞的时间，超时将跑出异常。单位，毫秒数;默认为-1.表示永不超时.
5. minEvictableIdleTimeMillis: 连接空闲的最小时间，达到此值后空闲连接将可能会被移除。负值(-1)表示不移除。
6. softMinEvictableIdleTimeMillis: 连接空闲的最小时间，达到此值后空闲链接将会被移除，且保留“minIdle”个空闲连接数。默认为-1.
7. numTestsPerEvictionRun: 对于“空闲链接”检测线程而言，每次检测的链接资源的个数。默认为3.
8. testOnBorrow: 向调用者输出“链接”资源时，是否检测是有有效，如果无效则从连接池中移除，并尝试获取继续获取。默认为false。建议保持默认值.
9. testOnReturn: 向连接池“归还”链接时，是否检测“链接”对象的有效性。默认为false。建议保持默认值.
10. testWhileIdle: 向调用者输出“链接”对象时，是否检测它的空闲超时；默认为false。如果“链接”空闲超时，将会被移除。建议保持默认值.
11. timeBetweenEvictionRunsMillis: “空闲链接”检测线程，检测的周期，毫秒数。如果为负值，表示不运行“检测线程”。默认为-1.
12. whenExhaustedAction: 当“连接池”中active数量达到阀值时，即“链接”资源耗尽时，连接池需要采取的手段, 默认为1：
    -> 0 : 抛出异常，
    -> 1 : 阻塞，直到有可用链接资源
    -> 2 : 强制创建新的链接资源

### 2、实现原理

#### 2.1、对象创建

> public GenericObjectPool(PoolableObjectFactory factory, GenericObjectPool.Config config) :

- 此方法创建一个GenericObjectPool实例,GenericObjectPool类已经实现了和对象池有关的所有核心操作,开发者可以通过继承或者封装的方式来使用它.通过此构造函数。
- 一个Pool中需要指定PoolableObjectFactory 实例,以及此对象池的Config信息。
- PoolableObjectFactory主要用来”创建新对象”，比如当对象池中的对象不足时,可以使用 PoolableObjectFactory.makeObject()方法来创建对象,并交付给Pool管理。
- 此构造函数实例化了一个LinkedList作为”对象池”容器,用来存取”对象”。
- 此外还会根据timeBetweenEvictionRunsMillis的值来决定是否启动一个后台线程,此线程用来周期性扫描pool中的对象列表,已检测”对象池中的对象”空闲(idle)的时间是否达到了阀值,如果是,则移除此对象.

#### 2.2、对象工厂接口

>  commons-pool通过使用ObjectFactory(工厂模式)的方式将”对象池中的对象”的创建/检测/销毁等特性解耦出来,这是一个非常良好的设计思想.此接口有一个抽象类BasePoolableObjectFactory,可供开发者继承和实现。

- Object makeObject() : 创建一个新对象;当对象池中的对象个数不足时,将会使用此方法来”输出”一个新的”对象”,并交付给对象池管理.
- void destroyObject(Object obj) : 销毁对象,如果对象池中检测到某个”对象”idle的时间超时,或者操作者向对象池”归还对象”时检测到”对象”已经无效,那么此时将会导致”对象销毁”;”销毁对象”的操作设计相差甚远,但是必须明确:当调用此方法时,”对象”的生命周期必须结束.如果object是线程,那么此时线程必须退出;如果object是socket操作,那么此时socket必须关闭;如果object是文件流操作,那么此时”数据flush”且正常关闭.
- boolean validateObject(Object obj) : 检测对象是否”有效”;Pool中不能保存无效的”对象”,因此”后台检测线程”会周期性的检测Pool中”对象”的有效性,如果对象无效则会导致此对象从Pool中移除,并destroy;此外在调用者从Pool获取一个”对象”时,也会检测”对象”的有效性,确保不能讲”无效”的对象输出给调用者;当调用者使用完毕将”对象归还”到Pool时,仍然会检测对象的有效性.所谓有效性,就是此”对象”的状态是否符合预期,是否可以对调用者直接使用;如果对象是Socket,那么它的有效性就是socket的通道是否畅通/阻塞是否超时等.
- void activateObject(Object obj) : “激活”对象,当Pool中决定移除一个对象交付给调用者时额外的”激活”操作,比如可以在activateObject方法中”重置”参数列表让调用者使用时感觉像一个”新创建”的对象一样;如果object是一个线程,可以在”激活”操作中重置”线程中断标记”,或者让线程从阻塞中唤醒等;如果 object是一个socket,那么可以在”激活操作”中刷新通道,或者对socket进行链接重建(假如socket意外关闭)等.
- void void passivateObject(Object obj) : “钝化”对象,当调用者”归还对象”时,Pool将会”钝化对象”;钝化的言外之意,就是此”对象”暂且需要”休息”一下.如果object是一个 socket,那么可以passivateObject中清除buffer,将socket阻塞;如果object是一个线程,可以在”钝化”操作中将线程sleep或者将线程中的某个对象wait.需要注意的时,activateObject和passivateObject两个方法需要对应,避免死锁或者”对象”状态的混乱.

#### 2.3、ObjectPool 接口

>  对象池是commons-pool的核心接口,用来维护”对象列表”的存取;其中GenericObjectPool是其实现类,它已经实现了相关的功能。

- Object borrowObject() : 从Pool获取一个对象,此操作将导致一个”对象”从Pool移除(脱离Pool管理),调用者可以在获得”对象”引用后即可使用,且需要在使用结束后”归还”。
- void returnObject(Object obj) : “归还”对象,当”对象”使用结束后,需要归还到Pool中,才能维持Pool中对象的数量可控,如果不归还到Pool,那么将意味着在Pool之外,将有大量的”对象”存在,那么就使用了”对象池”的意义。
- void invalidateObject(Object obj) : 销毁对象,直接调用ObjectFactory.destroyObject(obj)。
- void addObject() : 开发者可以直接调用addObject方法用于直接创建一个”对象”并添加到Pool中。

### 3、代码实现：

#### 3.1、WebDriverFactory

```java
public class WebDriverFactory {

    public static WebDriver getWebDriver(String path, Browser browser, Proxy proxy) {

        switch (browser) {

            case CHROME:

                return Browser.CHROME.init(path, proxy);

            case FIREFOX:

                return Browser.FIREFOX.init(path, proxy);

            case IE:

                return Browser.IE.init(path, proxy);

            case PHANTOMJS:

                return Browser.PHANTOMJS.init(path, proxy);
        }

        return null;

    }
}
```

#### 3.2、WebDriverPool

```java
/**
 * WebDriver 连接池
 * @author HoldDie
 * @version v1.0.0
 * @email HoldDie@163.com
 * @date 2018/12/3 6:08 PM
 */
public class WebDriverPool {

    private static GenericObjectPool<WebDriver> webDriverPool = null;

    /**
     * 如果需要使用WebDriverPool，则必须先调用这个init()方法
     * @param config
     */
    public static void init(WebDriverPoolConfig config) {

        webDriverPool = new GenericObjectPool<>(new WebDriverPooledFactory(config));
        webDriverPool.setMaxTotal(Integer.parseInt(System.getProperty(
            "webdriver.pool.max.total", "5"))); // 最多能放多少个对象
        webDriverPool.setMinIdle(Integer.parseInt(System.getProperty(
            "webdriver.pool.min.idle", "5")));   // 最少有几个闲置对象
        webDriverPool.setMaxIdle(Integer.parseInt(System.getProperty(
            "webdriver.pool.max.idle", "5"))); // 最多允许多少个闲置对象

        try {
            webDriverPool.preparePool();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public static WebDriver borrowOne() {

        if (webDriverPool != null) {
            try {
                return webDriverPool.borrowObject();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }

        return null;
    }

    public static void returnOne(WebDriver driver) {

        if (webDriverPool != null) {
            driver.quit();
            webDriverPool.returnObject(driver);
        }
    }

    public static void destory() {

        if (webDriverPool != null) {

            webDriverPool.clear();
            webDriverPool.close();
        }
    }

    public static boolean hasWebDriverPool() {

        return webDriverPool != null;
    }
}
```

#### 3.2、WebDriverPoolConfig

```java
public class WebDriverPoolConfig {

    private String path;

    private Browser browser;

    private List<Proxy> proxies;

    public WebDriverPoolConfig(String path) {

        this.path = path;

        if (path.contains("chrome")) {

            this.browser = Browser.CHROME;
        } else if (path.contains("firefox")){

            this.browser = Browser.FIREFOX;
        } else if (path.contains("ie")) {

            this.browser = Browser.IE;
        } else if (path.contains("phatomjs")){

            this.browser = Browser.PHANTOMJS;
        }
    }

    public WebDriverPoolConfig(String path, Browser browser) {

        this.path = path;
        this.browser = browser;
    }

    public WebDriverPoolConfig(String path, Browser browser,List<Proxy> proxies) {

        this.path = path;
        this.browser = browser;
        this.proxies = proxies;
    }

    public String getPath() {
        return path;
    }

    public Browser getBrowser() {
        return browser;
    }

    public List<Proxy> getProxies() {
        return proxies;
    }
}
```

#### 3.3、WebDriverPooledFactory

```java
public final class WebDriverPooledFactory implements PooledObjectFactory<WebDriver> {

    private String path;
    private Browser browser;

    public WebDriverPooledFactory(WebDriverPoolConfig config) {

        this.path = config.getPath();
        this.browser = config.getBrowser();
        ProxyPool.addProxyList(config.getProxies());
    }

    /**
     * 创建一个对象
     * @return
     * @throws Exception
     */
    @Override
    public PooledObject<WebDriver> makeObject() throws Exception {

        Proxy proxy =  ProxyPool.getProxy();

        if (proxy!=null && HttpManager.get().checkProxy(proxy)) {

            return new DefaultPooledObject<>(WebDriverFactory.getWebDriver(path,browser,proxy));
        } else { // 重试第一次获取Proxy

            proxy = ProxyPool.getProxy();

            if (proxy!=null && HttpManager.get().checkProxy(proxy)) {

                return new DefaultPooledObject<>(WebDriverFactory.getWebDriver(path,browser,proxy));
            } else { // 重试第二次获取Proxy

                proxy = ProxyPool.getProxy();

                if (proxy!=null && HttpManager.get().checkProxy(proxy)) {

                    return new DefaultPooledObject<>(WebDriverFactory.getWebDriver(path, browser, proxy));
                }
            }
        }

        return new DefaultPooledObject<>(WebDriverFactory.getWebDriver(path,browser,null)); // 不使用Proxy
    }

    /**
     * 销毁一个对象
     * @param p
     * @throws Exception
     */
    @Override
    public void destroyObject(PooledObject<WebDriver> p) throws Exception {
        p.getObject().quit();
    }

    /**
     * 对象是否有效
     * @param p
     * @return
     */
    @Override
    public boolean validateObject(PooledObject<WebDriver> p) {
        return null != p.getObject();
    }

    /**
     * 激活一个对象
     * @param p
     * @throws Exception
     */
    @Override
    public void activateObject(PooledObject<WebDriver> p) throws Exception {
    }

    /**
     * 钝化一个对象，在归还前做一起清理动作。
     * @param p
     * @throws Exception
     */
    @Override
    public void passivateObject(PooledObject<WebDriver> p) throws Exception {
        WebDriver driver = p.getObject();
        Set<String> handles = driver.getWindowHandles();
        String[] handlesArray = handles.toArray(new String[handles.size()]);
        int size = handles.size();
        // 留一个窗口，否则driver会退出
        for (int i = 0; i < size - 1; i++) {
            driver.switchTo().window(handlesArray[size - i]);
            driver.close();
        }
    }

}
```

#### 3.4、Browser

```java
public enum Browser implements WebDriverInitializer {
    /**
     * Chrome
     */
    CHROME {
        @Override
        public WebDriver init(String path, Proxy proxy) {
            System.setProperty("webdriver.chrome.driver", path);

            if (proxy != null) {

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
                // Add the WebDriver proxy capability.
                options.setCapability("proxy", ProxyUtils.toSeleniumProxy(proxy));
                WebDriver driver = new ChromeDriver(options);
                // 设置获取页面元素的最大等待时间
                driver.manage().timeouts().implicitlyWait(20, TimeUnit.SECONDS);
                return driver;
            }
            return new ChromeDriver();
        }
    },
    /**
     * FireFox
     */
    FIREFOX {
        @Override
        public WebDriver init(String path, Proxy proxy) {
            System.setProperty("webdriver.gecko.driver", path);

            if (proxy != null) {

                String PROXY = proxy.getIp() + ":" + proxy.getPort();

                org.openqa.selenium.Proxy seleniumProxy = new org.openqa.selenium.Proxy();
                seleniumProxy.setHttpProxy(PROXY)
                        .setFtpProxy(PROXY)
                        .setSslProxy(PROXY);
                DesiredCapabilities cap = new DesiredCapabilities();
                cap.setCapability(CapabilityType.PROXY, proxy);

                return new FirefoxDriver(cap);
            }

            return new FirefoxDriver();
        }
    },
    /**
     * IE
     */
    IE {
        @Override
        public WebDriver init(String path, Proxy proxy) {
            System.setProperty("webdriver.ie.driver", path);

            if (proxy != null) {

                String PROXY = proxy.getIp() + ":" + proxy.getPort();

                org.openqa.selenium.Proxy seleniumProxy = new org.openqa.selenium.Proxy();
                seleniumProxy.setHttpProxy(PROXY)
                        .setFtpProxy(PROXY)
                        .setSslProxy(PROXY);
                DesiredCapabilities cap = new DesiredCapabilities();
                cap.setCapability(CapabilityType.PROXY, proxy);

                return new InternetExplorerDriver(cap);
            }

            return new InternetExplorerDriver();
        }
    },
    /**
     * PhantomJs
     */
    PHANTOMJS {
        @Override
        public WebDriver init(String path, Proxy proxy) {

            DesiredCapabilities capabilities = new DesiredCapabilities();
            capabilities.setCapability("phantomjs.binary.path", path);
            capabilities.setCapability(CapabilityType.ACCEPT_SSL_CERTS, true);
            capabilities.setJavascriptEnabled(true);
            capabilities.setCapability("takesScreenshot", true);
            capabilities.setCapability("cssSelectorsEnabled", true);

            if (proxy != null) {

                ArrayList<String> cliArgsCap = new ArrayList<String>();
                cliArgsCap.add("--proxy=" + proxy.getIp() + ":" + proxy.getPort());
//                cliArgsCap.add("--proxy-auth=username:password");
                cliArgsCap.add("--proxy-type=http");
                capabilities.setCapability(
                        PhantomJSDriverService.PHANTOMJS_CLI_ARGS, cliArgsCap);
            }

            return new PhantomJSDriver(capabilities);
        }
    }
}
```

#### 3.5、WebDriverInitializer

```java
public interface WebDriverInitializer {
    WebDriver init(String driverPath, Proxy proxy);
}
```

#### 3.6、初始化

```java
//设置浏览器的驱动程序和浏览器的类型，浏览器的驱动程序要跟操作系统匹配。
WebDriverPoolConfig config = new WebDriverPoolConfig(ProjectConstant.WEBDRIVER_CHROME_DRIVER, Browser.CHROME);
// 需要先使用init，才能使用WebDriverPool
WebDriverPool.init(config);
```

### 4、参考实现

> - https://www.jianshu.com/p/061befafbfe5
> - https://blog.csdn.net/tiantiandjava/article/details/42915331