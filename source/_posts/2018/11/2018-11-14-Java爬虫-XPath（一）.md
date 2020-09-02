---
title: Java爬虫-XPath（一）
author: HoldDie
tags: [Java,爬虫,XPath]
top: false
date: 2018-11-14 19:43:41
categories: 爬虫
---



当你走过漫漫长路，是否还记得那一眼花开的动心？ ——萌贝壳



> XPath 是一门在 XML 文档中查找信息的语言。XPath 用于在XML文档中通过元素和属性进行导航。

### 1、XPath 基本概念

#### 1.1、XPath 概念

- XPath 使用路径表达式在 XML 文档中进行导航
- XPath 包含了一个标准函数库
- XPath 是 XSLT 中的主要元素
- XPath 是一个 W3C 标准

#### 1.2、XPath 路径表达式

> XPath 使用路径表达式来选取 XML 文档中的节点或者节点集。这些路径表达式和我们在常规的电脑文件系统中看到的表达式非常相似。

#### 1.3、XPath 标准函数

> XPath 含有超过 100 个内建的函数。这些函数用于字符串值、数值、日期和时间比较、节点和 QName 处理、序列处理、逻辑值等等。

### 2、XPath 术语

#### 2.1、节点（Node）

> 在 XPath 中，有七种类型的节点：元素、属性、文本、命名空间、处理指令、注释以及文档节点。XML 文档是被作为节点数来对待的。树的根被称为文档节点或者根节点。

#### 2.2、基本值（Atomic value）

#### 2.3、项目（Item）

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>

<bookstore>
    <book>
        <title lang="en">Harry Potter</title>
        <author>J K. Rowling</author> 
        <year>2005</year>
        <price>29.99</price>
    </book>
</bookstore>

解释：
<bookstore> （文档节点）
<author>J K. Rowling</author> （元素节点）
lang="en" （属性节点） 
J K. Rowling "en" (基本值)
```

#### 2.4、节点关系

##### 父（Parent）

> 每个元素以及属性都有一个父

##### 子（Children）

> 元素节点可有零个、一个或多个子。

##### 同胞（Subling）

> 拥有相同的父的节点

##### 先辈（Ancestor）

> 某节点的父、父的父，等等。

##### 后代（Descendant）

> 某个节点的子，子的子，等等。

### 3、XPath 语法

> **XPath 使用路径表达式来选取 XML 文档中的节点或节点集。节点是通过沿着路径 (path) 或者步 (steps) 来选取的。**

#### 3.1、选取节点

##### 示例内容

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<bookstore>
    <book>
        <title lang="eng">Harry Potter</title>
        <price>29.99</price>
    </book>
    <book>
        <title lang="eng">Learning XML</title>
        <price>39.95</price>
    </book>
</bookstore>
```

##### 下面列出了最有用的路径表达式：

| 表达式   | 描述                                                       |
| -------- | ---------------------------------------------------------- |
| nodename | 选取此节点的所有子节点。                                   |
| /        | 从根节点选取。                                             |
| //       | 从匹配选择的当前节点选择文档中的节点，而不考虑它们的位置。 |
| .        | 选取当前节点。                                             |
| ..       | 选取当前节点的父节点。                                     |
| @        | 选取属性。                                                 |

##### 实例 ，在下面的表格中，我们已列出了一些路径表达式以及表达式的结果：

| 路径表达式      | 结果                                                         |
| --------------- | ------------------------------------------------------------ |
| bookstore       | 选取 bookstore 元素的所有子节点。                            |
| /bookstore      | 选取根元素 bookstore。注释：假如路径起始于正斜杠( / )，则此路径始终代表到某元素的绝对路径！ |
| bookstore/book  | 选取属于 bookstore 的子元素的所有 book 元素。                |
| //book          | 选取所有 book 子元素，而不管它们在文档中的位置。             |
| bookstore//book | 选择属于 bookstore 元素的后代的所有 book 元素，而不管它们位于 bookstore 之下的什么位置。 |
| //@lang         | 选取名为 lang 的所有属性。                                   |

#### 3.2、谓语

> 谓语用来查找某个特定的节点或者包含某个指定的值的节点。谓语被嵌在方括号中。

在下面的表格中，我们列出了带有谓语的一些路径表达式，以及表达式的结果：

| 路径表达式                         | 结果                                                         |
| ---------------------------------- | ------------------------------------------------------------ |
| /bookstore/book[1]                 | 选取属于 bookstore 子元素的第一个 book 元素。                |
| /bookstore/book[last()]            | 选取属于 bookstore 子元素的最后一个 book 元素。              |
| /bookstore/book[last()-1]          | 选取属于 bookstore 子元素的倒数第二个 book 元素。            |
| /bookstore/book[position()<3]      | 选取最前面的两个属于 bookstore 元素的子元素的 book 元素。    |
| //title[@lang]                     | 选取所有拥有名为 lang 的属性的 title 元素。                  |
| //title[@lang=’eng’]               | 选取所有 title 元素，且这些元素拥有值为 eng 的 lang 属性。   |
| /bookstore/book[price>35.00]       | 选取 bookstore 元素的所有 book 元素，且其中的 price 元素的值须大于 35.00。 |
| /bookstore/book[price>35.00]/title | 选取 bookstore 元素中的 book 元素的所有 title 元素，且其中的 price 元素的值须大于 35.00。 |

#### 3.3、选取未知节点

> XPath 通配符可用来选取未知的 XML 元素。

| 通配符 | 描述                 |
| ------ | -------------------- |
| *      | 匹配任何元素节点。   |
| @*     | 匹配任何属性节点。   |
| node() | 匹配任何类型的节点。 |

##### 实例 在下面的表格中，我们列出了一些路径表达式，以及这些表达式的结果：

| 路径表达式   | 结果                              |
| ------------ | --------------------------------- |
| /bookstore/* | 选取 bookstore 元素的所有子元素。 |
| //*          | 选取文档中的所有元素。            |
| //title[@*]  | 选取所有带有属性的 title 元素。   |

#### 3.4、选取若干路径

> 通过在路径表达式中使用“|”运算符，您可以选取若干个路径。

##### 实例 在下面的表格中，我们列出了一些路径表达式，以及这些表达式的结果：

| 路径表达式              | 结果         |                                                              |
| ----------------------- | ------------ | ------------------------------------------------------------ |
| //book/title \          | //book/price | 选取 book 元素的所有 title 和 price 元素。                   |
| //title \               | //price      | 选取文档中的所有 title 和 price 元素。                       |
| /bookstore/book/title \ | //price      | 选取属于 bookstore 元素的 book 元素的所有 title 元素，以及文档中所有的 price 元素。 |

### 4、XPath Axes（轴）

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>

<bookstore>

    <book>
        <title lang="eng">Harry Potter</title>
        <price>29.99</price>
    </book>

    <book>
        <title lang="eng">Learning XML</title>
        <price>39.95</price>
    </book>

</bookstore>
```

> 轴可定义相对于当前节点的节点集。

| 轴名称             | 结果                                                     |
| ------------------ | -------------------------------------------------------- |
| ancestor           | 选取当前节点的所有先辈（父、祖父等）。                   |
| ancestor-or-self   | 选取当前节点的所有先辈（父、祖父等）以及当前节点本身。   |
| attribute          | 选取当前节点的所有属性。                                 |
| child              | 选取当前节点的所有子元素。                               |
| descendant         | 选取当前节点的所有后代元素（子、孙等）。                 |
| descendant-or-self | 选取当前节点的所有后代元素（子、孙等）以及当前节点本身。 |
| following          | 选取文档中当前节点的结束标签之后的所有节点。             |
| namespace          | 选取当前节点的所有命名空间节点。                         |
| parent             | 选取当前节点的父节点。                                   |
| preceding          | 选取文档中当前节点的开始标签之前的所有节点。             |
| preceding-sibling  | 选取当前节点之前的所有同级节点。                         |
| self               | 选取当前节点。                                           |

#### 4.1、位置路径表达式

> 1、位置路径可以是绝对的，也可以是相对的。
>
> 2、绝对路径起始于正斜杠( / )，而相对路径不会这样。在两种情况中，位置路径均包括一个或多个步，每个步均被斜杠分割：

##### 绝对位置路径：

```
/step/step/...
```

##### 相对位置路径：

```
step/step/...
```

每个步均根据当前节点集之中的节点来进行计算。

#### 4.2、步（step）包括：

- 轴（axis）

  定义所选节点与当前节点之间的树关系

- 节点测试（node-test）

  识别某个轴内部的节点

- 零个或者更多谓语（predicate）

  更深入地提炼所选的节点集

#### 4.3、步的语法：

```
轴名称::节点测试[谓语]
```

| 例子                   | 结果                                                         |
| ---------------------- | ------------------------------------------------------------ |
| child::book            | 选取所有属于当前节点的子元素的 book 节点。                   |
| attribute::lang        | 选取当前节点的 lang 属性。                                   |
| child::*               | 选取当前节点的所有子元素。                                   |
| attribute::*           | 选取当前节点的所有属性。                                     |
| child::text()          | 选取当前节点的所有文本子节点。                               |
| child::node()          | 选取当前节点的所有子节点。                                   |
| descendant::book       | 选取当前节点的所有 book 后代。                               |
| ancestor::book         | 选择当前节点的所有 book 先辈。                               |
| ancestor-or-self::book | 选取当前节点的所有 book 先辈以及当前节点（如果此节点是 book 节点） |
| child::*/child::price  | 选取当前节点的所有 price 孙节点。                            |

### 5、XPath 运算符

| 运算符 | 描述           | 实例                      | 返回值                                                       |      |                                      |
| ------ | -------------- | ------------------------- | ------------------------------------------------------------ | ---- | ------------------------------------ |
| \      |                | 计算两个节点集            | //book \                                                     | //cd | 返回所有拥有 book 和 cd 元素的节点集 |
| +      | 加法           | 6 + 4                     | 10                                                           |      |                                      |
| -      | 减法           | 6 - 4                     | 2                                                            |      |                                      |
| *      | 乘法           | 6 * 4                     | 24                                                           |      |                                      |
| div    | 除法           | 8 div 4                   | 2                                                            |      |                                      |
| =      | 等于           | price=9.80                | 如果 price 是 9.80，则返回 true。如果 price 是 9.90，则返回 false。 |      |                                      |
| !=     | 不等于         | price!=9.80               | 如果 price 是 9.90，则返回 true。如果 price 是 9.80，则返回 false。 |      |                                      |
| <      | 小于           | price<9.80                | 如果 price 是 9.00，则返回 true。如果 price 是 9.90，则返回 false。 |      |                                      |
| <=     | 小于或等于     | price<=9.80               | 如果 price 是 9.00，则返回 true。如果 price 是 9.90，则返回 false。 |      |                                      |
| >      | 大于           | price>9.80                | 如果 price 是 9.90，则返回 true。如果 price 是 9.80，则返回 false。 |      |                                      |
| >=     | 大于或等于     | price>=9.80               | 如果 price 是 9.90，则返回 true。如果 price 是 9.70，则返回 false。 |      |                                      |
| or     | 或             | price=9.80 or price=9.70  | 如果 price 是 9.80，则返回 true。如果 price 是 9.50，则返回 false。 |      |                                      |
| and    | 与             | price>9.00 and price<9.90 | 如果 price 是 9.80，则返回 true。如果 price 是 8.50，则返回 false。 |      |                                      |
| mod    | 计算除法的余数 | 5 mod 2                   | 1                                                            |      |                                      |

### 6、实战理解

#### 6.1、文档

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<bookstore>

    <book category="COOKING">
        <title lang="en">Everyday Italian</title>
        <author>Giada De Laurentiis</author>
        <year>2005</year>
        <price>30.00</price>
    </book>

    <book category="CHILDREN">
        <title lang="en">Harry Potter</title>
        <author>J K. Rowling</author>
        <year>2005</year>
        <price>29.99</price>
    </book>

    <book category="WEB">
        <title lang="en">XQuery Kick Start</title>
        <author>James McGovern</author>
        <author>Per Bothner</author>
        <author>Kurt Cagle</author>
        <author>James Linn</author>
        <author>Vaidyanathan Nagarajan</author>
        <year>2003</year>
        <price>49.99</price>
    </book>

    <book category="WEB">
        <title lang="en">Learning XML</title>
        <author>Erik T. Ray</author>
        <year>2003</year>
        <price>39.95</price>
    </book>

</bookstore>
```

#### 6.2、加载 XML 文档

> 所有现代浏览器都支持使用 XMLHttpRequest 来加载 XML 文档的方法。

针对大多数现代浏览器的代码：

```javascript
var xmlhttp=new XMLHttpRequest()    
```

针对古老的微软浏览器（IE 5 和 6）的代码：

```javascript
var xmlhttp=new ActiveXObject("Microsoft.XMLHTTP")
```

#### 6.3、选取节点

不幸的是，Internet Explorer 和其他处理 XPath 的方式不同。在我们的例子中，包含适用于大多数主流浏览器的代码。

Internet Explorer 使用 selectNodes() 方法从 XML 文档中的选取节点：

```javascript
xmlDoc.selectNodes(xpath);
```

Firefox、Chrome、Opera 以及 Safari 使用 evaluate() 方法从 XML 文档中选取节点：

```javascript
xmlDoc.evaluate(xpath, xmlDoc, null, XPathResult.ANY_TYPE,null);
```

#### 6.4、实践代码

##### books.xml

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<bookstore>

    <book category="COOKING">
        <title lang="en">Everyday Italian</title>
        <author>Giada De Laurentiis</author>
        <year>2005</year>
        <price>30.00</price>
    </book>

    <book category="CHILDREN">
        <title lang="en">Harry Potter</title>
        <author>J K. Rowling</author>
        <year>2005</year>
        <price>29.99</price>
    </book>

    <book category="WEB">
        <title lang="en">XQuery Kick Start</title>
        <author>James McGovern</author>
        <author>Per Bothner</author>
        <author>Kurt Cagle</author>
        <author>James Linn</author>
        <author>Vaidyanathan Nagarajan</author>
        <year>2003</year>
        <price>49.99</price>
    </book>

    <book category="WEB">
        <title lang="en">Learning XML</title>
        <author>Erik T. Ray</author>
        <year>2003</year>
        <price>39.95</price>
    </book>

</bookstore>
```

##### books.html

```xml
<html>

<body>
  <script type="text/javascript">
    function loadXMLDoc(dname) {
      if (window.XMLHttpRequest) {
        xhttp = new XMLHttpRequest();
      }
      else {
        xhttp = new ActiveXObject("Microsoft.XMLHTTP");
      }
      xhttp.open("GET", dname, false);
      xhttp.send("");
      return xhttp.responseXML;
    }

    xml = loadXMLDoc("/books.xml");
    // 获取所有title节点
    // path = "/bookstore/book/title";
    // 获取第一个book的title
    // path = "/bookstore/book[1]/title";
    // 选取所有价格
    // path = "/bookstore/book/price";
    // 获取价格高于35的price节点
    // path = "/bookstore/book[price>35]/price";
    // 选取价格高于35的title节点
    path = "/bookstore/book[price>35]/title";

    // code for IE
    if (window.ActiveXObject) {
      var nodes = xml.selectNodes(path);

      for (i = 0; i < nodes.length; i++) {
        document.write(nodes[i].childNodes[0].nodeValue);
        document.write("<br />");
      }
    }
    // code for Mozilla, Firefox, Opera, etc.
    else if (document.implementation && document.implementation.createDocument) {
      var nodes = xml.evaluate(path, xml, null, XPathResult.ANY_TYPE, null);
      var result = nodes.iterateNext();

      while (result) {
        document.write(result.childNodes[0].nodeValue);
        document.write("<br />");
        result = nodes.iterateNext();
      }
    }
  </script>
</body>

</html>
```