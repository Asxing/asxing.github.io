---
title: ElasticSearch-实战入门（三）
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - Elasticsearch
  - 搜索
date: 2018-04-22 21:32:16
password:
summary:  
categories: ElasticSearch
---

尖刺，玖拾胜利！



### cross_fields 搜索

直接使用 `cross_fields` 比使用 `most_fields` 搜索模拟的的权重 `score`要高一些。

关键点：

- 要求每个`term`都必须在任何一个`field`中出现，就是所有的都要找见。

- 既然每个term都必须出现，则长尾肯定被除掉了。

- 对于每个字段计算出来的IDF分数不会出现太高的情况。

  - Peter Smith 分为 Peter、Smith


  - Smith，在author_first_name这个field中，在所有doc的这个Field中，出现的频率很低，导致IDF分数很高；Smith在所有doc的author_last_name field中的频率算出一个IDF分数，因为一般来说last_name中的Smith频率都较高，所以IDF分数是正常的，不会太高；然后对于Smith来说，会取两个IDF分数中，较小的那个分数。就不会出现IDF分过高的情况。

执行语句：

```http
GET /forum/article/_search
{
  "query": {
    "multi_match": {
      "query": "Peter  Smith",
      "type": "cross_fields",
      "operator": "and",
      "fields": [
        "author_first_name",
        "author_last_name"
      ]
    }
  }
}
```

返回结果：

```json
{
  "took": 6,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 2,
    "max_score": 0.5753642,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "5",
        "_score": 0.5753642,
        "_source": {
          "articleID": "DHJK-B-1395-#Ky5",
          "userID": 3,
          "hidden": false,
          "postDate": "2017-03-01",
          "tag": [
            "elasticsearch"
          ],
          "tag_cnt": 1,
          "view_cnt": 10,
          "title": "this is spark blog",
          "content": "spark is best big data solution based on scala ,an programming language similar to java",
          "sub_title": "haha, hello world",
          "sub_title1": "haha, hello world",
          "author_first_name": "Tonny",
          "author_last_name": "Peter Smith",
          "new_author_last_name": "Peter Smith",
          "new_author_first_name": "Tonny"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "1",
        "_score": 0.5753642,
        "_source": {
          "articleID": "XHDK-A-1293-#fJ3",
          "userID": 1,
          "hidden": false,
          "postDate": "2017-01-01",
          "tag": [
            "java",
            "hadoop"
          ],
          "tag_cnt": 2,
          "view_cnt": 30,
          "title": "this is java and elasticsearch blog",
          "content": "i like to write best elasticsearch article",
          "sub_title": "learning more courses",
          "sub_title1": "learning more courses",
          "author_first_name": "Peter",
          "author_last_name": "Smith",
          "new_author_last_name": "Smith",
          "new_author_first_name": "Peter"
        }
      }
    ]
  }
}
```

### phrase matching 近似匹配

#### 解决问题：

- 搜索 关键字 "java spark" 关键词就是靠在一起，中间不允许插入其他任何字符，就要搜索出来这种doc
- 还有就是 两个关键词，之间的距离，越近，越被优先返回

对应的实现语法就是：phrase match，proximity match

match：仅仅搜索出 java 和 spark 紧靠在在一起的，一旦分开就不能识别。

phrase match：就是将多个term作为一个短语，一起去搜索，只有包含这个短语的doc 才会作为结果返回。

#### 主要思想

对于使用倒排索引，首先判断时候每个都包含，然后根据条件判断之间的position的位置。

语句：

```json
GET /forum/article/_search
{
    "query": {
        "match_phrase": {
            "content": "java spark"
        }
    }
}
```

建立索引的基本原理：

hello world, java spark		doc1
hi, spark java				doc2

hello 		doc1(0)		
wolrd		doc1(1)
java		doc1(2)	 doc2(2)
spark		doc1(3)	 doc2(1)

java spark -->  match phrase

java spark -->  java和spark

java --> 	doc1(2) 	doc2(2)
spark --> 	doc1(3) 	doc2(1)

要找到每个term都在的一个共有的那些doc，就是要求一个doc，必须包含每个term，才能拿出来继续计算。

解释：

- doc1 --> java和spark --> spark position恰巧比java大1 --> java的position是2，spark的position是3，恰好满足条件，doc1符合条件


- doc2 --> java和spark --> java position是2，spark position是1，spark position比java position小1，而不是大1 --> 光是position就不满足，那么doc2不匹配

### slop 近似匹配搜索

#### 知识点

- slop 代表的就是关键字之间距离的大小，可以指定支之间的距离，代表尝试的次数，若超过次数还没有结果，就返回空，否则就返回。
- query string，搜索文本，中的几个term，slop 是指会经过几次移动能够匹配。

#### 原理：

如果我们指定了slop，那么就允许java spark进行移动，来尝试与doc进行匹配

java		is		very		good		spark		is

java		spark
java		-->		spark
java				-->			spark
java							-->			spark

这里的slop，就是3，因为java spark这个短语，spark移动了3次，就可以跟一个doc匹配上了

加上slop的phrase match 就是 proximity match  近似匹配 。

#### 语句：

```json
GET /forum/article/_search
{
    "query": {
        "match_phrase": {
            "title": {
                "query": "java spark",
                "slop":  3
            }
        }
    }
}
```

#### 总结：

其实，加了 slop 的 phrase match ，就是 proximity match ，近似匹配

1、java spark，短语，doc，phrase match
2、java spark，可以有一定的距离，但是靠的越近，越先搜索出来，proximity match

### match 和 近似值 匹配

召回率：是指搜索一个关键词，总共有100个，能返回多少个doc作为结果，就是召回率。

精准度：是指搜索一个关键词，所返回的结果是不是足够精确，精确的在上面。

match phrase ，proximity match 要求doc必须包含所有的term，才能作为结果返回，如果某个doc中没有包含某个term，那么就无法作为结果返回。

一般情况下，当精准度高了的时候，召回率就会下降，两者是一个相互不可同时满足。

此时可以使用bool组合`match query` 和 `match_phrase` query 一起实现上述效果。

```json
GET /forum/article/_search
{
  "query": {
    "bool": {
      "must": {
        "match": { 
          "title": {
            "query": "java spark" --> java或spark或java spark，java和spark靠前，但是没法区分java和spark的距离，也许java和spark靠的很近，但是没法排在最前面
          }
        }
      },
      "should": {
        "match_phrase": { --> 在slop以内，如果java spark能匹配上一个doc，那么就会对doc贡献自己的relevance score，如果java和spark靠的越近，那么就分数越高
          "title": {
            "query": "java spark",
            "slop":  50
          }
        }
      }
    }
  }
}
```

### rescoring 机制优化近似匹配

#### `match` 和 `phrase match` 的区别：

- `match`：只要简单的匹配到一个term，就可以理解将term对应的doc作为返回结果，扫描倒排索引，扫描到了就ok
- `phrase match`：
  - 首先扫描到所有term的doc list，找到包含所有term的doc list
  - 然后对每个doc都计算每个term 的position，是否符合指定的范围 slop
  - 需要进行复杂的运算，来判断是否通过slop移动，匹配一个doc

优化 proximity match 的性能，一般就是减少要进行proximity match搜索的document数量，主要思路就是：用match query先过滤出需要的数据，然后再用proximity match来根据term距离提高doc的分数，同时proximity match只针对每个shard的分数排名前n个doc起作用，来重新调整他们的分数，这个过程就是 rescoring，重新计分。

因为一般用户会分页查询，只会看到前几页的数据，所以不需要对所有结果进行proximity match操作。

#### `match + proximity match`  同时实现召回率和精准度

默认情况下，match 也许匹配了 1000个doc，proximity match全都需要对每一个doc进行一遍运算，判断是否slop移动匹配，然后去贡献自己的分数，但是很多情况下match出来也许1000个doc，其实用户大部分情况下是分页查询的，所以可能罪过只会看到前几页，比如一页10条，最多看5页，一种就是50一条，proximity match 只要对前50个doc记性slop移动去匹配，去贡献自己的分数即可，不需要对全部1000个doc都去进行计算和贡献分数。

重点：

rescore：重打分

match：1000个doc，其实这个时候每个doc都有一个分数了

proximity match：前 50 个doc，进行rescore，重打分即可

让前50个doc，term距离越近的，越排在前面。

```json
GET /forum/article/_search 
{
  "query": {
    "match": {
      "content": "java spark"
    }
  },
  "rescore": {
    "window_size": 50,
    "query": {
      "rescore_query": {
        "match_phrase": {
          "content": {
            "query": "java spark",
            "slop": 50
          }
        }
      }
    }
  }
}
```

### 万不得已的搜索

#### 前缀搜索

基本原理就是全文进行遍历记性检索，这个是当输入搜索条件时，才会记性的搜索，事前不准备任何东西，因此十分低效。

```json
PUT my_index
{
  "mappings": {
    "my_type": {
      "properties": {
        "title": {
          "type": "keyword"
        }
      }
    }
  }
}

GET my_index/my_type/_search
{
  "query": {
    "prefix": {
      "title": {
        "value": "C3"
      }
    }
  }
}
```

### 通配符搜索

原理：同样是扫描整个倒排索引

规则：

- ?：任意字符
- *：0个或任意多个字符

语句：

```json
GET my_index/my_type/_search
{
  "query": {
    "wildcard": {
      "title": {
        "value": "C?K*5"
      }
    }
  }
}
```

### 正则搜索

原理：扫描整个倒排索引

规则：

- [0-9]：指定范围内的数字
- [a-z]：指定范围内的字母
- .：一个字符
- +：前面的正则表达式可以出现一次或多次

语句：

```json
GET /my_index/my_type/_search 
{
  "query": {
    "regexp": {
      "title": "C[0-9].+"
    }
  }
}
```

### search-time 推荐搜索

先看一个样例：

```json
GET /my_index/my_type/_search 
{
  "query": {
    "match_phrase_prefix": {
      "title": "hello d"
    }
  }
}
```

原理：跟 `match_phrase` 一样，唯一的区别就是把最后一个term作为前缀，进行搜索，同时也直指slop，就是后面再进行分词的总长度。

max_expansions：指定prefix最多匹配多少个term，超过这个数量就不继续匹配了，限定性能。

默认情况下，前缀扫描所有的倒排索引中的term，去查找w打头的单次，但是这样的性能太差了，同样这个语法能不用尽量不用，扫描大量的索引，性能会很差。

### ngram 分词搜索

这种匹配的手段就是实现做了一些事情，根据 ngram 的长度进行分词，提前做了功课。

什么是edge ngram

quick，anchor首字母后进行ngram

q
qu
qui
quic
quick

使用edge ngram将每个单词都进行进一步的分词切分，用切分后的ngram来实现前缀搜索推荐功能

hello world
hello we

h
he
hel
hell
hello		doc1,doc2

w			doc1,doc2
wo
wor
worl
world
e			doc2

helloworld

min ngram = 1
max ngram = 3

h
he
hel

hello w

hello --> hello，doc1
w --> w，doc1

doc1，hello和w，而且position也匹配，所以，ok，doc1返回，hello world

搜索的时候，不用再根据一个前缀，然后扫描整个倒排索引了; 简单的拿前缀去倒排索引中匹配即可，如果匹配上了，那么就好了; match，全文检索

语句：

```json
PUT /my_index
{
    "settings": {
        "analysis": {
            "filter": {
                "autocomplete_filter": { 
                    "type":     "edge_ngram",
                    "min_gram": 1,
                    "max_gram": 20
                }
            },
            "analyzer": {
                "autocomplete": {
                    "type":      "custom",
                    "tokenizer": "standard",
                    "filter": [
                        "lowercase",
                        "autocomplete_filter" 
                    ]
                }
            }
        }
    }
}
```

请求数据：

```json
GET /my_index/_analyze
{
  "analyzer": "autocomplete",
  "text": "quick brown"
}

PUT /my_index/_mapping/my_type
{
  "properties": {
      "title": {
          "type":     "string",
          "analyzer": "autocomplete",
          "search_analyzer": "standard"
      }
  }
}
```

![](https://www.holddie.com/img/20200105154004.jpg)