---
title: Java爬虫-WebMagic（二）
author: HoldDie
tags: [Java,爬虫,WebMagic]
top: false
date: 2018-11-15 19:43:41
categories: 爬虫
---

> **你如此美好，我跌入花间忘了人间。 ——天涯**

### 1、Spider 架构

> WebMagic的结构分为`Downloader`、`PageProcessor`、`Scheduler`、`Pipeline`四大组件，并由Spider将它们彼此组织起来。

#### 1.2、四个组件

- Downloader

> Downloader负责从互联网上下载页面，以便后续处理。WebMagic默认使用了[Apache HttpClient](http://hc.apache.org/index.html)作为下载工具。

- PageProcessor

> PageProcessor负责解析页面，抽取有用信息，以及发现新的链接。WebMagic使用[Jsoup](http://jsoup.org/)作为HTML解析工具，并基于其开发了解析XPath的工具[Xsoup](https://github.com/code4craft/xsoup)。
>
> 在这四个组件中，`PageProcessor`对于每个站点每个页面都不一样，是需要使用者定制的部分。

- Scheduler

> Scheduler负责管理待抓取的URL，以及一些去重的工作。WebMagic默认提供了JDK的内存队列来管理URL，并用集合来进行去重。也支持使用Redis进行分布式管理。
>
> 除非项目有一些特殊的分布式需求，否则无需自己定制Scheduler。

- Pipeline

> Pipeline负责抽取结果的处理，包括计算、持久化到文件、数据库等。WebMagic默认提供了“输出到控制台”和“保存到文件”两种结果处理方案。
>
> `Pipeline`定义了结果保存的方式，如果你要保存到指定数据库，则需要编写对应的Pipeline。对于一类需求一般只需编写一个`Pipeline`。

#### 1.3、三个数据流对象

- Request

> `Request`是对URL地址的一层封装，一个Request对应一个URL地址。
>
> 它是PageProcessor与Downloader交互的载体，也是PageProcessor控制Downloader唯一方式。
>
> 除了URL本身外，它还包含一个Key-Value结构的字段`extra`。你可以在extra中保存一些特殊的属性，然后在其他地方读取，以完成不同的功能。例如附加上一个页面的一些信息等。

- Page

> `Page`代表了从Downloader下载到的一个页面——可能是HTML，也可能是JSON或者其他文本格式的内容。
>
> Page是WebMagic抽取过程的核心对象，它提供一些方法可供抽取、结果保存等。在第四章的例子中，我们会详细介绍它的使用。

- ResultItems

> `ResultItems`相当于一个Map，它保存PageProcessor处理的结果，供Pipeline使用。它的API与Map很类似，值得注意的是它有一个字段`skip`，若设置为true，则不应被Pipeline处理。

### 2、页面数据处理

> 实现 PageProcessor 接口

#### 2.1、页面元素抽取技术：

- ##### XPath

- ##### CSS 选择器

- ##### 正则表达式

- ##### JsonPath

#### 2.2、Selectable 抽取元素

> ###### 抽取API，这部分抽取API返回的都是一个`Selectable`接口

| 方法                                      | 说明                             | 示例                                |
| ----------------------------------------- | -------------------------------- | ----------------------------------- |
| xpath(String xpath)                       | 使用XPath选择                    | html.xpath(“//div[@class=’title’]”) |
| $(String selector)                        | 使用Css选择器选择                | html.$(“div.title”)                 |
| $(String selector,String attr)            | 使用Css选择器选择                | html.$(“div.title”,”text”)          |
| css(String selector)                      | 功能同$()，使用Css选择器选择     | html.css(“div.title”)               |
| links()                                   | 选择所有链接                     | html.links()                        |
| regex(String regex)                       | 使用正则表达式抽取               | html.regex(“(.*?)\”)                |
| regex(String regex,int group)             | 使用正则表达式抽取，并指定捕获组 | html.regex(“(.*?)\”,1)              |
| replace(String regex, String replacement) | 替换内容                         | html.replace(“\”,””)                |

#### 2.3、获取结果API

| 方法       | 说明                                  | 示例                                 |
| ---------- | ------------------------------------- | ------------------------------------ |
| get()      | 返回一条String类型的结果              | String link= html.links().get()      |
| toString() | 功能同get()，返回一条String类型的结果 | String link= html.links().toString() |
| all()      | 返回所有抽取结果                      | List links= html.links().all()       |
| match()    | 是否有匹配结果                        | if (html.links().match()){ xxx; }    |

### 3、爬虫配置

#### 3.1、Spider

| 方法                      | 说明                                             | 示例                                                         |
| ------------------------- | ------------------------------------------------ | ------------------------------------------------------------ |
| create(PageProcessor)     | 创建Spider                                       | Spider.create(new GithubRepoProcessor())                     |
| addUrl(String…)           | 添加初始的URL                                    | spider .addUrl(“http://webmagic.io/docs/“)                   |
| addRequest(Request…)      | 添加初始的Request                                | spider .addRequest(“http://webmagic.io/docs/“)               |
| thread(n)                 | 开启n个线程                                      | spider.thread(5)                                             |
| run()                     | 启动，会阻塞当前线程执行                         | spider.run()                                                 |
| start()/runAsync()        | 异步启动，当前线程继续执行                       | spider.start()                                               |
| stop()                    | 停止爬虫                                         | spider.stop()                                                |
| test(String)              | 抓取一个页面进行测试                             | spider .test(“http://webmagic.io/docs/“)                     |
| addPipeline(Pipeline)     | 添加一个Pipeline，一个Spider可以有多个Pipeline   | spider .addPipeline(new ConsolePipeline())                   |
| setScheduler(Scheduler)   | 设置Scheduler，一个Spider只能有个一个Scheduler   | spider.setScheduler(new RedisScheduler())                    |
| setDownloader(Downloader) | 设置Downloader，一个Spider只能有个一个Downloader | spider .setDownloader(new SeleniumDownloader())              |
| get(String)               | 同步调用，并直接取得结果                         | ResultItems result = spider .get(“http://webmagic.io/docs/“) |
| getAll(String…)           | 同步调用，并直接取得一堆结果                     | List results = spider .getAll(“http://webmagic.io/docs/“, “http://webmagic.io/xxx“) |

#### 3.2、Site

| 方法                     | 说明                                      | 示例                                                         |
| ------------------------ | ----------------------------------------- | ------------------------------------------------------------ |
| setCharset(String)       | 设置编码                                  | site.setCharset(“utf-8”)                                     |
| setUserAgent(String)     | 设置UserAgent                             | site.setUserAgent(“Spider”)                                  |
| setTimeOut(int)          | 设置超时时间，单位是毫秒                  | site.setTimeOut(3000)                                        |
| setRetryTimes(int)       | 设置重试次数                              | site.setRetryTimes(3)                                        |
| setCycleRetryTimes(int)  | 设置循环重试次数                          | site.setCycleRetryTimes(3)                                   |
| addCookie(String,String) | 添加一条cookie                            | site.addCookie(“dotcomt_user”,”code4craft”)                  |
| setDomain(String)        | 设置域名，需设置域名后，addCookie才可生效 | site.setDomain(“github.com”)                                 |
| addHeader(String,String) | 添加一条addHeader                         | site.addHeader(“Referer”,”[https://github.com](https://github.com/)“) |
| setHttpProxy(HttpHost)   | 设置Http代理                              | site.setHttpProxy(new HttpHost(“127.0.0.1”,8080))            |

#### 3.3、Jsoup

#### 3.4、Xsoup

| Name                  | Expression           | Support         |                 |
| --------------------- | -------------------- | --------------- | --------------- |
| nodename              | nodename             | yes             |                 |
| immediate parent      | /                    | yes             |                 |
| parent                | //                   | yes             |                 |
| attribute             | [@key=value]         | yes             |                 |
| nth child             | tag[n]               | yes             |                 |
| attribute             | /@key                | yes             |                 |
| wildcard in tagname   | /*                   | yes             |                 |
| wildcard in attribute | /[@*]                | yes             |                 |
| function              | function()           | part            |                 |
| or                    | a \                  | b               | yes since 0.2.0 |
| parent in path        | . or ..              | no              |                 |
| predicates            | price>35             | no              |                 |
| predicates logic      | @class=a or @class=b | yes since 0.2.0 |                 |

请注意，这些函数式标准XPath没有的。

| Expression              | Description                                                  | XPath1.0    |
| ----------------------- | ------------------------------------------------------------ | ----------- |
| text(n)                 | 第n个直接文本子节点，为0表示所有                             | text() only |
| allText()               | 所有的直接和间接文本子节点                                   | not support |
| tidyText()              | 所有的直接和间接文本子节点，并将一些标签替换为换行，使纯文本显示更整洁 | not support |
| html()                  | 内部html，不包括标签的html本身                               | not support |
| outerHtml()             | 内部html，包括标签的html本身                                 | not support |
| regex(@attr,expr,group) | 这里@attr和group均可选，默认是group0                         | not support |

### 4、配置代理

> 自定义的代理实现

#### 4.1、配置代理池

```java
  HttpClientDownloader httpClientDownloader = new HttpClientDownloader();
    httpClientDownloader.setProxyProvider(SimpleProxyProvider.from(
    new Proxy("101.101.101.101",8888)
    ,new Proxy("102.102.102.102",8888)));
```

#### 4.2、处理非GET方法

```java
Request request = new Request("http://xxx/path");
request.setMethod(HttpConstant.Method.POST);
request.setRequestBody(HttpRequestBody.json("{'id':1}","utf-8"));
```

HttpRequestBody 内置了几种初始化方式，支持最常见的表单提交、json提交等方式。

| API                                                          | 说明                                 |
| ------------------------------------------------------------ | ------------------------------------ |
| HttpRequestBody.form(Map\ params, String encoding)           | 使用表单提交的方式                   |
| HttpRequestBody.json(String json, String encoding)           | 使用JSON的方式，json是序列化后的结果 |
| HttpRequestBody.xml(String xml, String encoding)             | 设置xml的方式，xml是序列化后的结果   |
| HttpRequestBody.custom(byte[] body, String contentType, String encoding) | 设置自定义的requestBody              |

### 5、注解开发

#### 5.1、`@TargetUrl`

> - 类上面写
> - 抓取目标的地址
> - 页面详情（对应`HelpUrl`）
> - tips
>   - 将URL中常用的字符`.`默认做了转义，变成了`\.`
>   - 将”*“替换成了”.*“，直接使用可表示通配符。
> - sourceRegion
>   - **TargetUrl**还支持定义`sourceRegion`，这个参数是一个XPath表达式，指定了这个URL从哪里得到——不在sourceRegion的URL不会被抽取。

#### 5.2、`@HelpUrl`

> - 类上边写
> - 列表页面（对应 `TargetUrl`）
> - 对应关系
>   - 对于博客页，HelpUrl是列表页，TargetUrl是文章页。
>   - 对于论坛，HelpUrl是帖子列表，TargetUrl是帖子详情。
>   - 对于电商网站，HelpUrl是分类列表，TargetUrl是商品详情。
> - sourceRegion
>   - **TargetUrl**还支持定义`sourceRegion`，这个参数是一个XPath表达式，指定了这个URL从哪里得到——不在sourceRegion的URL不会被抽取。

#### 5.3、`@ExtractBy`

> - 类的字段上注解
> - 定义这个字段使用什么方式进行抽取
> - `value` 是一个XPath表示的抽取规则，而抽取到的结果则会保存到readme字段中。

```java
@ExtractBy(value = "div.BlogContent", type = ExtractBy.Type.Css)
private String content;
```

#### 5.4、`@ExtractByUrl`

> `@ExtractByUrl`是一个单独的注解，它的意思是“从URL中进行抽取”。它只支持正则表达式作为抽取规则。

#### 5.5、结果类型转换

```java
@Formatter("yyyy-MM-dd HH:mm")
@ExtractBy("//div[@class='BlogStat']/regex('\\d+-\\d+-\\d+\\s+\\d+:\\d+')")
private Date date;


@Formatter(value = "",subClazz = Integer.class)
@ExtractBy(value = "//div[@class='id']/text()", multi = true)
private List<Integer> ids;
```

##### 自定义`Formatter`

```java
public class StringTemplateFormatter implements ObjectFormatter<String> {

    private String template;

    @Override
    public String format(String raw) throws Exception {
        return String.format(template, raw);
    }

    @Override
    public Class<String> clazz() {
        return String.class;
    }

    @Override
    public void initParam(String[] extra) {
        template = extra[0];
    }
}

@Formatter(value = "author is %s",formatter = StringTemplateFormatter.class)
@ExtractByUrl("https://github\\.com/(\\w+)/.*")
private String author;
```

#### 5.6、AfterExtractor

> 注解模式无法满足，有些值需要计算之类的需求，可以在获取值之后，进行补充处理。

```java
//TargetUrl的意思是只有以下格式的URL才会被抽取出生成model对象
//这里对正则做了一点改动，'.'默认是不需要转义的，而'*'则会自动被替换成'.*'，因为这样描述URL看着舒服一点...
//继承jfinal中的Model
//实现AfterExtractor接口可以在填充属性后进行其他操作
@TargetUrl("http://my.oschina.net/flashsword/blog/*")
public class OschinaBlog extends Model<OschinaBlog> implements AfterExtractor {

    //用ExtractBy注解的字段会被自动抽取并填充
    //默认是xpath语法
    @ExtractBy("//title")
    private String title;

    //可以定义抽取语法为Css、Regex等
    @ExtractBy(value = "div.BlogContent", type = ExtractBy.Type.Css)
    private String content;

    //multi标注的抽取结果可以是一个List
    @ExtractBy(value = "//div[@class='BlogTags']/a/text()", multi = true)
    private List<String> tags;

    @Override
    public void afterProcess(Page page) {
        //jfinal的属性其实是一个Map而不是字段，没关系，填充进去就是了
        this.set("title", title);
        this.set("content", content);
        this.set("tags", StringUtils.join(tags, ","));
        //保存
        save();
    }

    public static void main(String[] args) {
        C3p0Plugin c3p0Plugin = new C3p0Plugin("jdbc:mysql://127.0.0.1/blog?characterEncoding=utf-8", "blog", "password");
        c3p0Plugin.start();
        ActiveRecordPlugin activeRecordPlugin = new ActiveRecordPlugin(c3p0Plugin);
        activeRecordPlugin.addMapping("blog", OschinaBlog.class);
        activeRecordPlugin.start();
        //启动webmagic
        OOSpider.create(Site.me().addStartUrl("http://my.oschina.net/flashsword/blog/145796"), OschinaBlog.class).run();
    }
}
```

### 6、组件定制

#### 6.1、Pipeline 定制

```java
public interface Pipeline {

    // ResultItems保存了抽取结果，它是一个Map结构，
    // 在page.putField(key,value)中保存的数据，可以通过ResultItems.get(key)获取
    public void process(ResultItems resultItems, Task task);

}

public class ConsolePipeline implements Pipeline {

    @Override
    public void process(ResultItems resultItems, Task task) {
        System.out.println("get page: " + resultItems.getRequest().getUrl());
        //遍历所有结果，输出到控制台，上面例子中的"author"、"name"、"readme"都是一个key，其结果则是对应的value
        for (Map.Entry<String, Object> entry : resultItems.getAll().entrySet()) {
            System.out.println(entry.getKey() + ":\t" + entry.getValue());
        }
    }
}
```

> 一个`Spider`可以有多个Pipeline，使用`Spider.addPipeline()`即可增加一个Pipeline。这些Pipeline都会得到处理。

WebMagic中已经提供了将结果输出到控制台、保存到文件和JSON格式保存的几个Pipeline：

| 类                        | 说明                             | 备注                             |
| ------------------------- | -------------------------------- | -------------------------------- |
| ConsolePipeline           | 输出结果到控制台                 | 抽取结果需要实现toString方法     |
| FilePipeline              | 保存结果到文件                   | 抽取结果需要实现toString方法     |
| JsonFilePipeline          | JSON格式保存结果到文件           |                                  |
| ConsolePageModelPipeline  | (注解模式)输出结果到控制台       |                                  |
| FilePageModelPipeline     | (注解模式)保存结果到文件         |                                  |
| JsonFilePageModelPipeline | (注解模式)JSON格式保存结果到文件 | 想要持久化的字段需要有getter方法 |

#### 6.2、Schedule 定制

Scheduler是WebMagic中进行URL管理的组件。一般来说，Scheduler包括两个作用：

1. 对待抓取的URL队列进行管理。
2. 对已抓取的URL进行去重。

WebMagic内置了几个常用的Scheduler。如果你只是在本地执行规模比较小的爬虫，那么基本无需定制Scheduler，但是了解一下已经提供的几个Scheduler还是有意义的。

| 类                        | 说明                                                         | 备注                                                         |
| ------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| DuplicateRemovedScheduler | 抽象基类，提供一些模板方法                                   | 继承它可以实现自己的功能                                     |
| QueueScheduler            | 使用内存队列保存待抓取URL                                    |                                                              |
| PriorityScheduler         | 使用带有优先级的内存队列保存待抓取URL                        | 耗费内存较QueueScheduler更大，但是当设置了request.priority之后，只能使用PriorityScheduler才可使优先级生效 |
| FileCacheQueueScheduler   | 使用文件保存抓取URL，可以在关闭程序并下次启动时，从之前抓取到的URL继续抓取 | 需指定路径，会建立.urls.txt和.cursor.txt两个文件             |
| RedisScheduler            | 使用Redis保存抓取队列，可进行多台机器同时合作抓取            | 需要安装并启动redis                                          |

在0.5.1版本里，我对Scheduler的内部实现进行了重构，去重部分被单独抽象成了一个接口：`DuplicateRemover`，从而可以为同一个Scheduler选择不同的去重方式，以适应不同的需要，目前提供了两种去重方式。

| 类                          | 说明                                                      |
| --------------------------- | --------------------------------------------------------- |
| HashSetDuplicateRemover     | 使用HashSet来进行去重，占用内存较大                       |
| BloomFilterDuplicateRemover | 使用BloomFilter来进行去重，占用内存较小，但是可能漏抓页面 |

所有默认的Scheduler都使用HashSetDuplicateRemover来进行去重，（除开RedisScheduler是使用Redis的set进行去重）。如果你的URL较多，使用HashSetDuplicateRemover会比较占用内存，所以也可以尝试以下BloomFilterDuplicateRemover[1](http://webmagic.io/docs/zh/posts/ch6-custom-componenet/scheduler.html#fn_1)，使用方式：

```java
//10000000是估计的页面数量
spider.setScheduler(new QueueScheduler()
                    .setDuplicateRemover(new BloomFilterDuplicateRemover(10000000)) 
                   )
```