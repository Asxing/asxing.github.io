---
title: ElasticSearch-实战入门（一）
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - ElasticSearch
  - 搜索
date: 2018-04-17 21:32:16
password:
summary:  
categories: ElasticSearch
---

在门外徘徊了两天，包括官方文档粗略过了一下，决定入门看看，望自己坚持一步一步走下去，最后希望达到的目的是完美解决工作中的问题。



#### 批量插入数据：

```http
POST /forum/article/_bulk
{ "index" : {"_id":1 }}
{ "articleID" : "XHDK-A-1293-#fJ3", "userID" : 1, "hidden": false, "postDate": "2017-01-01" }
{ "index": { "_id": 2 }}
{ "articleID" : "KDKE-B-9947-#kL5", "userID" : 1, "hidden": false, "postDate": "2017-01-02" }
{ "index": { "_id": 3 }}
{ "articleID" : "JODL-X-1937-#pV7", "userID" : 2, "hidden": false, "postDate": "2017-01-01" }
{ "index": { "_id": 4 }}
{ "articleID" : "QQPX-R-3956-#aD8", "userID" : 2, "hidden": true, "postDate": "2017-01-02" }
```

#### 查看对应index type的mapping

```http
GET /forum/_mapping/article
```

返回：

```json
{
  "forum": {
    "mappings": {
      "article": {
        "properties": {
          "articleID": {
            "type": "text",
            "fields": {
              "keyword": {
                "type": "keyword",
                "ignore_above": 256
              }
            }
          },
          "hidden": {
            "type": "boolean"
          },
          "postDate": {
            "type": "date"
          },
          "userID": {
            "type": "long"
          }
        }
      }
    }
  }
}
```

#### term 查询，使用指定字段查询，不分词

```http
GET /forum/article/_search
{
  "query": {
    "constant_score": {
      "filter": {
        "term": {
          "userID": 1
        }
      },
      "boost": 1.2
    }
  }
}
```

term 是不对搜索文本分词的

默认是 analyze的text类型的field，建立倒排索引的时候，就会对所有的`articleID`分词，分词以后原本的 `articleID` 就没有了，只有分词后的各个`word` 存在于倒排索引中

```http
GET /forum/article/_search
{
  "query": {
    "constant_score": {
      "filter": {
        "term": {
          "articleID.keyword": "XHDK-A-1293-#fJ3"
        }
      }
    }
  }
}

```

返回结果是：

```json
{
  "took": 2,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 1,
    "max_score": 1,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "1",
        "_score": 1,
        "_source": {
          "articleID": "XHDK-A-1293-#fJ3",
          "userID": 1,
          "hidden": false,
          "postDate": "2017-01-01"
        }
      }
    ]
  }
}
```

这个主要想说明的是ES高版本默认会自动生成，最新版本内置的，所以一个 articleID 过来的时候，会建立两次索引，一次是进行倒排索引，另一次不分词最多256字符，尽量可能还是自己手动建立索引，指定not_analyze，在最新的版本ES中，不需要指定not_analyze也可以，将 type=keyword即可。

#### 进行分词操作：

```http
GET /forum/_analyze
{
  "field": "articleID",
  "text": "XHDK-A-1293-#fJ3"
}
```

分词后结果：

```json
{
  "tokens": [
    {
      "token": "xhdk",
      "start_offset": 0,
      "end_offset": 4,
      "type": "<ALPHANUM>",
      "position": 0
    },
    {
      "token": "a",
      "start_offset": 5,
      "end_offset": 6,
      "type": "<ALPHANUM>",
      "position": 1
    },
    {
      "token": "1293",
      "start_offset": 7,
      "end_offset": 11,
      "type": "<NUM>",
      "position": 2
    },
    {
      "token": "fj3",
      "start_offset": 13,
      "end_offset": 16,
      "type": "<ALPHANUM>",
      "position": 3
    }
  ]
}
```

如果对默认的索引不是很满足，自己可以删除索引，进行自定义的设置：

```http
DELETE /forum
```

创建索引

```http
PUT /forum
{
  "mappings": {
    "article": {
      "properties": {
        "articleID": {
          "type": "keyword"
        }
      }
    }
  }
}
```

批量插入数据：

```http
POST /forum/article/_bulk
{ "index": { "_id": 1 }}
{ "articleID" : "XHDK-A-1293-#fJ3", "userID" : 1, "hidden": false, "postDate": "2017-01-01" }
{ "index": { "_id": 2 }}
{ "articleID" : "KDKE-B-9947-#kL5", "userID" : 1, "hidden": false, "postDate": "2017-01-02" }
{ "index": { "_id": 3 }}
{ "articleID" : "JODL-X-1937-#pV7", "userID" : 2, "hidden": false, "postDate": "2017-01-01" }
{ "index": { "_id": 4 }}
{ "articleID" : "QQPX-R-3956-#aD8", "userID" : 2, "hidden": true, "postDate": "2017-01-02" }
```

重新根据帖子的ID进行搜索

```http
GET /forum/article/_search
{
  "query": {
    "constant_score": {
      "filter": {
        "term": {
          "articleID": "XHDK-A-1293-#fJ3"
        }
      },
      "boost": 1.2
    }
  }
}
```

返回结果：、

```json
{
  "took": 1,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 1,
    "max_score": 1.2,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "1",
        "_score": 1.2,
        "_source": {
          "articleID": "XHDK-A-1293-#fJ3",
          "userID": 1,
          "hidden": false,
          "postDate": "2017-01-01"
        }
      }
    ]
  }
}
```

### 结构化搜索 filter

1. 在倒排索引中查找搜索串，获取document lsit

   1. | word       | doc1 | doc2 | doc3 |
      | ---------- | ---- | ---- | ---- |
      | 2017-01-01 | *    | *    |      |
      | 2017-01-02 |      | *    | *    |
      | 2017-01-03 | *    | *    | *    |

   2. 在倒排索引中查询，发现 2017-02-02 对应的document list是doc2，doc3

2. 为每个在倒排索引中搜到的结果，构建一个bitset，[0, 0, 0, 1, 0, 1]

   1. 使用找到的 doc list，构建一个bitset，就是一个二进制的数组，数组每个元素都是0或1，用来表示一个doc对一个filter条件是否匹配，如果匹配就是1，不匹配就是0
   2. [0, 1, 1]
   3. doc1: 不匹配这个filter的，doc2，doc3 就是匹配这个filter
   4. 尽可能使用简单的数据结构去实现复杂的功能，可以节省内存空间，提升性能

3. 遍历每个过滤条件对应的 bitset，优先从最稀疏的开始搜索，查找满足所有条件的document

   1. 一个Search中可能会有多个条件，就有多个filter
   2. 一般是从 最洗漱的开始遍历，过滤尽可能多的数据

4. caching bitset ，跟踪 query

   1. 在最近的256个filter中超过了一定次数的过滤条件，缓存器bitset，对于小于segment（<1000 或 3%），不缓存bitset
   2. segment 数据量很小，哪怕是扫描很快，segment 会在后台自动合并，意义不大。
   3. filter 比 query 的好处在于会caching，实际上并不是一个filter返回一个完整的doc list数据结果，而是filter bitset缓存起来，下次不用扫描倒排索引了。

5. filter 大部分情况实在query之前执行的，还会根据score排序

   1. query：计算doc对搜索条件的relevance score，还会根据这个score去排序
   2. filter：只是简单过滤出想要的结果，不计算relevance score，也不排序

6. 若document有新增或修改，那么cached bitset 会自动更新

7. 若以后只要有相同的filter，会直接使用对应的`cached bitset`

### bool 组合多个 filter 条件

基本知识点：

- bool、must、must_not、should，组合多个过滤条件
- bool 可以嵌套
- 相当于 SQL 中的多个 and 条件

基本的查询练习

1. 搜索发帖日期为2017-01-01，或者帖子ID为XHDK-A-1293-#fJ3的帖子，同时要求帖子的发帖日期绝对不为2017-01-02

   ```http
   GET /forum/article/_search
   {
     "query": {
       "constant_score": {
         "filter": {
           "bool": {
             "should": [
               {
                 "term": {
                   "postDate": "2017-01-01"
                 }
               },
               {
                 "term": {
                   "articleID": "XHDK-A-1293-#fJ3"
                 }
               }
             ],
             "must_not": {
               "term": {
                 "postDate": "2017-01-02"
               }
             }
           }
         }
       }
     }
   }
   ```

2. 搜索帖子ID为XHDK-A-1293-#fJ3，或者是帖子ID为JODL-X-1937-#pV7而且发帖日期为2017-01-01的帖子

   ```http
   GET /forum/article/_search 
   {
     "query": {
       "constant_score": {
         "filter": {
           "bool": {
             "should": [
               {
                 "term": {
                   "articleID": "XHDK-A-1293-#fJ3"
                 }
               },
               {
                 "bool": {
                   "must": [
                     {
                       "term":{
                         "articleID": "JODL-X-1937-#pV7"
                       }
                     },
                     {
                       "term": {
                         "postDate": "2017-01-01"
                       }
                     }
                   ]
                 }
               }
             ]
           }
         }
       }
     }
   }
   ```

   返回的结果是：

   ```json
   {
     "took": 8,
     "timed_out": false,
     "_shards": {
       "total": 5,
       "successful": 5,
       "skipped": 0,
       "failed": 0
     },
     "hits": {
       "total": 2,
       "max_score": 1.2,
       "hits": [
         {
           "_index": "forum",
           "_type": "article",
           "_id": "1",
           "_score": 1.2,
           "_source": {
             "articleID": "XHDK-A-1293-#fJ3",
             "userID": 1,
             "hidden": false,
             "postDate": "2017-01-01"
           }
         },
         {
           "_index": "forum",
           "_type": "article",
           "_id": "3",
           "_score": 1.2,
           "_source": {
             "articleID": "JODL-X-1937-#pV7",
             "userID": 2,
             "hidden": false,
             "postDate": "2017-01-01"
           }
         }
       ]
     }
   }
   ```

### terms 搜索多值

1. #### 为帖子数据添加`tag`字段

   ```http
   POST /forum/article/_bulk
   { "update": { "_id": "1"} }
   { "doc" : {"tag" : ["java", "hadoop"]} }
   { "update": { "_id": "2"} }
   { "doc" : {"tag" : ["java"]} }
   { "update": { "_id": "3"} }
   { "doc" : {"tag" : ["hadoop"]} }
   { "update": { "_id": "4"} }
   { "doc" : {"tag" : ["java", "elasticsearch"]} }
   ```

2. #### 搜索articleID为KDKE-B-9947-#kL5或QQPX-R-3956-#aD8的帖子，搜索tag中包含java的帖子

   ```http
   POST /forum/article/_search
   {
     "query": {
       "constant_score": {
         "filter": {
           "terms": {
             "tag": [
               "java"  
             ]
           }
         },
         "boost": 1.2
       }
     }
   }
   ```

   ```http
   POST /forum/article/_search
   {
     "query": {
       "constant_score": {
         "filter": {
           "terms": {
             "articleID": [
               "KDKE-B-9947-#kL5",
               "QQPX-R-3956-#aD8"
             ]
           }
         },
         "boost": 1.2
       }
     }
   }
   ```

3. #### 优化搜索结果，仅仅搜索tag只包含java的帖子

   ```http
   POST /forum/article/_bulk
   {"update":{"_id":"1"}}
   {"doc":{"tag_cnt":2}}
   {"update":{"_id":"2"}}
   {"doc":{"tag_cnt":1}}
   {"update":{"_id":"3"}}
   {"doc":{"tag_cnt":1}}
   {"update":{"_id":"4"}}
   {"doc":{"tag_cnt":2}}
   ```

   ```http
   GET /forum/article/_search
   {
     "query": {
       "constant_score": {
         "filter": {
           "bool": {
             "must":[
               {
                 "term":{
                   "tag_cnt": 1
                 }
               },
               {
                 "terms":{
                   "tag": ["java"]
                 }
               }
             ]
           }
         },
         "boost": 1.2
       }
     }
   }
   ```

   查询只有一个 java 的 tag 的数据，实现的方式就是在数据中又新增了一个字段，描述tag标签长度的字段，这样可以多重筛选了。

### rang filter  进行范围过滤

1. 为帖子添加浏览量字段

   ```http
   POST /forum/article/_bulk
   {"update":{"_id":"1"}}
   {"doc":{"view_cnt":30}}
   {"update":{"_id":"2"}}
   {"doc":{"view_cnt":50}}
   {"update":{"_id":"3"}}
   {"doc":{"view_cnt":100}}
   {"update":{"_id":"4"}}
   {"doc":{"view_cnt":80}}
   ```

2. 搜索浏览量在30-60之间的帖子

   ```http
   GET /forum/article/_search
   {
     "query": {"constant_score": {
       "filter": {"range": {
         "view_cnt": {
           "gt": 30,
           "lt": 60
         }
       }},
       "boost": 1.2
     }}
   }
   ```

   ```json
   {
     "took": 4,
     "timed_out": false,
     "_shards": {
       "total": 5,
       "successful": 5,
       "skipped": 0,
       "failed": 0
     },
     "hits": {
       "total": 1,
       "max_score": 1.2,
       "hits": [
         {
           "_index": "forum",
           "_type": "article",
           "_id": "2",
           "_score": 1.2,
           "_source": {
             "articleID": "KDKE-B-9947-#kL5",
             "userID": 1,
             "hidden": false,
             "postDate": "2017-01-02",
             "tag": [
               "java"
             ],
             "tag_cnt": 1,
             "view_cnt": 50
           }
         }
       ]
     }
   }
   ```

3. 搜索发帖日期在最近一个月的帖子

   ```http
   GET /forum/article/_search
   {
     "query": {
       "constant_score": {
         "filter": {
           "range": {
             "postDate": {
               "gte": "2017-03-10||-30d"
             }
           }
         },
         "boost": 1.2
       }
     }
   }
   ```

   返回结果：

   ```json
   {
     "took": 17,
     "timed_out": false,
     "_shards": {
       "total": 5,
       "successful": 5,
       "skipped": 0,
       "failed": 0
     },
     "hits": {
       "total": 1,
       "max_score": 1.2,
       "hits": [
         {
           "_index": "forum",
           "_type": "article",
           "_id": "5",
           "_score": 1.2,
           "_source": {
             "articleID": "DHJK-B-1395-#Ky5",
             "userID": 3,
             "hidden": false,
             "postDate": "2017-03-01",
             "tag": [
               "elasticsearch"
             ],
             "tag_cnt": 1,
             "view_cnt": 10
           }
         }
       ]
     }
   }
   ```

### 全文检索 match

1. 为帖子数据增加标题字段

   ```http
   POST /forum/article/_bulk
   {"update":{"_id":"1"}}
   {"doc":{"title":"this is java and elasticsearch blog"}}
   {"update":{"_id":"2"}}
   {"doc":{"title":"this is java blog"}}
   {"update":{"_id":"3"}}
   {"doc":{"title":"this is elasticsearch blog"}}
   {"update":{"_id":"4"}}
   {"doc":{"title":"this is java, elasticsearch, hadoop blog"}}
   {"update":{"_id":"5"}}
   {"doc":{"title":"this is spark blog"}}
   ```

2. 搜索标题中包含java或elasticsearch的blog

   ```http
   GET /forum/article/_search
   {
     "query": {
       "match": {
         "title": "java elaticsearch"
       }
     }
   }
   ```

3. 搜索标题中`java`和`elasticsearch` 的`blog`

   ```http
   GET /forum/article/_search
   {
     "query": {
       "match": {
         "title": {
           "query": "java elasticsearch",
           "operator": "and"
         }
       }
     }
   }
   ```

4. 搜索包含 `java`、`elasticsearch`、`spark`、`hadoop`4关键字中，至少3个 `blog`

   ```http
   GET /forum/article/_search
   {
     "query": {
       "match": {
         "title": {
           "query": "java elasticsearch spark hadoop",
           "minimum_should_match": "75%"
         }
       }
     }
   }
   ```

5. 用 bool 组合多个搜索条件，来搜索 title

   ```http
   GET /forum/article/_search
   {
     "query": {
       "bool": {
         "must": [
           {
             "match": {
               "title": "java"
             }
           }
         ],
         "must_not": [
           {
             "match": {
               "title": "spark"
             }
           }
         ],
         "should": [
           {
             "match": {
               "title": "hadoop"
             }
           },
           {
             "match": {
               "title": "elasticsearch"
             }
           }
         ]
       }
     }
   }
   ```

6. bool 组合多个搜索条件，如何计算relevance score

   must 和 should 搜索对应的分数，加起来除以 must 和 should 的总数

   should 是可以影响相关度分数的

   must 的确说，谁必须由这个关键字，同时会根据 must 的条件去计算出 document 对这个搜索条件的 relevance score 它在满足must 的基础之上，should 中的条件，不匹配也可以，但是如果匹配的更多，那么 document 的relevance score 就会更高

   ```json
   {
     "took": 9,
     "timed_out": false,
     "_shards": {
       "total": 5,
       "successful": 5,
       "skipped": 0,
       "failed": 0
     },
     "hits": {
       "total": 3,
       "max_score": 1.449981,
       "hits": [
         {
           "_index": "forum",
           "_type": "article",
           "_id": "4",
           "_score": 1.449981,
           "_source": {
             "articleID": "QQPX-R-3956-#aD8",
             "userID": 2,
             "hidden": true,
             "postDate": "2017-01-02",
             "tag": [
               "java",
               "elasticsearch"
             ],
             "tag_cnt": 2,
             "view_cnt": 80,
             "title": "this is java, elasticsearch, hadoop blog"
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
             "title": "this is java and elasticsearch blog"
           }
         },
         {
           "_index": "forum",
           "_type": "article",
           "_id": "2",
           "_score": 0.19856805,
           "_source": {
             "articleID": "KDKE-B-9947-#kL5",
             "userID": 1,
             "hidden": false,
             "postDate": "2017-01-02",
             "tag": [
               "java"
             ],
             "tag_cnt": 1,
             "view_cnt": 50,
             "title": "this is java blog"
           }
         }
       ]
     }
   }
   ```

7. 搜索`java`，`hadoop`，`spark`，`elasticsearch`至少包含其中`3`个关键字

   默认情况是，should 是可以不匹配任何一个的，比如上面的搜索 `this is java blog` ，就不匹配任何一个 `should` 条件但是有个额外的情况，如果没有 must 的话，那么should中必须至少匹配一个才可以

   比如下面的搜索，should 中有 4个条件，默认情况下，只要满足一个条件，就可以匹配作为结果返回，但是可以精确控制，should 的4个条件，至少匹配几个才能作为结果返回。

   ```http
   GET /forum/article/_search
   {
     "query": {
       "bool": {
         "should": [
           {"match": {
             "title": "java"
           }},
           {
             "match": {
               "title": "elasticsearch"
             }
           },
           {
             "match": {
               "title": "hadoop"
             }
           },
           {
             "match": {
               "title": "spark"
             }
           }
         ],
         "minimum_should_match": 3
       }
     }
   }
   ```

   知识点：

   1. 全文检索的时候，进行多值检索，match query，should term
   2. 控制搜索结果精确度：and  operator，minimum_should_match

### match 转 term + should

1. #### 普通match如何转换为term+should

   ```http
   GET /forum/article/_search
   {
     "query": {
       "match": {
         "title": "java elasticsearch"
       }
     }
   }
   ```

   转化后：

   ```http
   GET /forum/article/_search
   {
     "query": {
       "bool": {
         "should": [
           {
             "term": {
               "title": {
                 "value": "java"
               }
             }
           },
           {
             "term": {
               "title": {
                 "value": "elasticsearch"
               }
             }
           }
         ]
       }
     }
   }
   ```

   

2. #### and match如何转换为term+must

   ```http
   GET /forum/article/_search
   {
     "query": {
       "match": {
         "title": {
           "query": "java elasticsearch",
           "operator": "and"
         }
       }
     }
   }
   ```

   转化后：

   ```http
   GET /forum/article/_search
   {
     "query": {
       "bool": {
         "must": [
           {
             "term": {
               "title": {
                 "value": "java"
               }
             }
           },
           {
             "term": {
               "title": {
                 "value": "elasticsearch"
               }
             }
           }
         ]
       }
     }
   }
   ```

   

3. #### minimum_should_match如何转换

   ```http
   GET /forum/article/_search
   {
     "query": {
       "match": {
         "title": {
           "query": "java elasticsearch hadoop spark",
           "minimum_should_match": "75%"
         }
       }
     }
   }
   ```

   转化后

   ```http
   GET /forum/article/_search
   {
     "query": {
       "bool": {
         "should": [
           {
             "term": {
               "title": {
                 "value": "java"
               }
             }
           },
           {
             "term": {
               "title": {
                 "value": "elasticsearch"
               }
             }
           },
           {
             "term": {
               "title": {
                 "value": "hadoop"
               }
             }
           },
           {
             "term": {
               "title": {
                 "value": "spark"
               }
             }
           }
         ],
         "minimum_should_match": 3
       }
     }
   }
   ```

