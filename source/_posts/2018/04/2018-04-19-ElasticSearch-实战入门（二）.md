---
title: ElasticSearch-实战入门（二）
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
date: 2018-04-19 21:32:16
password:
summary:  
categories: ElasticSearch
---

尖刺，玖拾胜利！



### boost 权重计算

解决问题：当搜索标题中包含 java 的帖子，同时标题中包含hadoop或elasticsearch就优先搜索出来，同时有hadoop的帖子要比有elasticsearch的帖子优先显示。

知识点：

- boost 搜索条件的权重，可以将某个搜索条件的权重加大，
- 当匹配这个搜索条件和匹配另一个搜索条件的document，计算relevance score时，匹配权重更大的搜索条件的document，relevance score会更高，当然也就会优先被返回回来。
- 默认情况下，搜索条件的权重都是一样的，都是1。

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
        }
      ],
      "should": [
        {
          "term": {
            "title": {
              "value": "hadoop",
              "boost": 4
            }
          }
        },
        {
          "term": {
            "title": {
              "value": "elasticsearch",
              "boost": 2
            }
          }
        }
      ]
    }
  }
}
```

结果：

```json
{
  "took": 3,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 3,
    "max_score": 4.012878,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "4",
        "_score": 4.012878,
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
        "_score": 0.8630463,
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

单独使用 boost，可以把某个 结果的 boost 的值设置更高，则此时会优先显示优先级更高条件的结果，但是还是会优先返回符合更多条件的那个结果。

```http
GET /forum/article/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "term": {
            "title": {
              "value": "blog"
            }
          }
        }
      ],
      "should": [
        {
          "term": {
            "title": {
              "value": "java",
              "boost": 2
            }
          }
        },
        {
          "term": {
            "title": {
              "value": "hadoop",
              "boost": 4
            }
          }
        },
        {
          "term": {
            "title": {
              "value": "elasticsearch",
              "boost": 2
            }
          }
        },
        {
          "term": {
            "title": {
              "value": "spark",
              "boost": 5
            }
          }
        }
      ]
    }
  }
}
```

 返回结果：

```json
{
  "took": 7,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 5,
    "max_score": 4.3499427,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "4",
        "_score": 4.3499427,
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
        "_id": "5",
        "_score": 1.7260925,
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
          "title": "this is spark blog"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "1",
        "_score": 1.4384104,
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
        "_id": "3",
        "_score": 0.8630463,
        "_source": {
          "articleID": "JODL-X-1937-#pV7",
          "userID": 2,
          "hidden": false,
          "postDate": "2017-01-01",
          "tag": [
            "hadoop"
          ],
          "tag_cnt": 1,
          "view_cnt": 100,
          "title": "this is elasticsearch blog"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "2",
        "_score": 0.59570414,
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

### 多 `Shard` 场景 relevance score 不准确

#### 问题描述：

- 由于我们对一个 index 我们可以设置 shard 数，默认是 5，所接受的数据会均匀的分布到每个 Shard 中。
- 但是若在每某个`shard`中，有很多个document，包含了title中有java这个关键字，比如说10个doc的title包含了java
- 当一个搜索title包含java请求，到这个shard的时候，应该会计算relevance score，使用 TF/IDF 算法。
  - 在一个document中tittle中，java出现了几次
  - 在所有的document的title中，java出现了几次 
  - 这个document的title的长度
- shard 中只是整体的一部分，默认就是在 shard local中本地计算IDF。
- 此时另外一个shard中，只有一个document title包含java，此时计算 shard local IDF，就会分数很高，相关度很高。
- 在这种情况下，就会导致出现搜索结果，就是太片面了，可能关键信息不能够准确搜索出来。

#### 解决办法：

- 生产环境下，数据量大，尽可能实现均匀分配
  - 如果数据量特别大，而且每个shard上均匀分布，这个可以避免上述情况。
- 测试环境下，将索引的 primary shard 设置为1，number_of_shards=1，index settings
  - 如果只有一个shard，那么当然，所有的document都在这个shard里面
- 测试环境下，搜索附带search_type=dfs_query_then_fetch参数，会将local IDF取出来计算 global IDF
  - 计算一个doc的相关度分数的时候，就会将所有shard的local IDF计算一下，获取出来，在本地进行global IDF分数的计算，会将所有的shard的doc作为上下文来进行计算，也能确保准确性，但是production生产环境下，不推荐这个参数，因为性能很差。

### dis_max 多字段搜索最佳策略

问题描述：

- 普通的多字段搜索，在ES中默认的搜索是，匹配多个字段匹配尽可能多的字段，而不是对于单个字段匹配最符合的规则
- 每个document的relevance score的计算方式：每个query的分数，乘以matched query数量，除以总query数量

#### 为数据新增字段：

```http
POST /forum/article/_bulk
{"update":{"_id":"1"}}
{"doc":{"content":"i like to write best elasticsearch article"}}
{"update":{"_id":"2"}}
{"doc":{"content":"i think java is the best programming language"}}
{"update":{"_id":"3"}}
{"doc":{"content":"i am only an elasticsearch beginner"}}
{"update":{"_id":"4"}}
{"doc":{"content":"elasticsearch and hadoop are all very good solution, i am a beginner"}}
{"update":{"_id":"5"}}
{"doc":{"content":"spark is best big data solution based on scala ,an programming language similar to java"}}
```

#### 进行普通的多字段搜索：

```http
GET /forum/article/_search
{
  "query": {
    "bool": {
      "should": [
        {"match": {
          "title": "java solution"
        }},{
          "match": {
            "content": "java solution"
          }
        }
      ]
    }
  }
}
```

搜索结果：

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
    "total": 4,
    "max_score": 0.95348084,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "2",
        "_score": 0.95348084,
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
          "title": "this is java blog",
          "content": "i think java is the best programming language"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "4",
        "_score": 0.8092568,
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
          "title": "this is java, elasticsearch, hadoop blog",
          "content": "elasticsearch and hadoop are all very good solution, i am a beginner"
        }
      },
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
          "content": "spark is best big data solution based on scala ,an programming language similar to java"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "1",
        "_score": 0.2876821,
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
          "content": "i like to write best elasticsearch article"
        }
      }
    ]
  }
}
```

未达到预期的结果，单个字段中出现了次数最多的优先显示出来

使用 `dis_max` 策略

```http
GET /forum/article/_search
{
  "query": {
    "dis_max": {
      "queries": [
        {"match": {
          "title": "java solution"
        }},{
          "match": {
            "content": "java solution"
          }
        }  
      ]
    }
  }
}
```

### tie_breaker 参数调优

问题描述：

- 当只是用dis_max的时候，某个字段中匹配度最高的返回，但是与此同时，当我们想参考其他字段的权重时。
- 此时的问题就比较尴尬，因为是一刀切，难免会有问题，此时使用tie_breaker就可以很好的实现辅助调优。

知识点：

- `tie_breaker`的关键词的取值返回在：`0~1`之间，是一个小数就`ojbk`
- `tie_breaker` 代表的是其他`query`的分数，进行综合计算

```http
GET /forum/article/_search
{
  "query": {
    "dis_max": {
      "queries": [
        {"match": {
          "title": "java solution"
        }},{
          "match": {
            "content": "java solution"
          }
        }  
      ],
      "tie_breaker": 0.7
    }
  }
}
```

### mult_match 简化

问题描述：

- 对于上述的表达方式的简化
- 次数多使用了一个 minimum_should_match 的参数进行多个匹配

知识点：

- minimum_should_match：去长尾，比如同时查询5个关键字，但是只匹配一个关键字，不符合我们的预期，控制搜索结果的精准度，只有匹配一定数量的关键词的数据，才能返回。

原始数据：

```http
GET /forum/article/_search
{
  "query": {
    "dis_max": {
      "tie_breaker": 0.7,
      "boost": 1.2,
      "queries": [
        {
          "match": {
            "title": {
              "query": "java begginer",
              "minimum_should_match": "70%",
              "boost": 2
            }
          }
        },
        {
          "match": {
            "content": {
              "query": "java content",
              "minimum_should_match": "50%",
              "boost": 4
            }
          }
        }
      ]
    }
  }
}
```

搜索的结果：

```json
{
  "took": 5,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 4,
    "max_score": 3.957176,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "2",
        "_score": 3.957176,
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
          "title": "this is java blog",
          "content": "i think java is the best programming language"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "5",
        "_score": 1.380874,
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
          "content": "spark is best big data solution based on scala ,an programming language similar to java"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "1",
        "_score": 0.690437,
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
          "content": "i like to write best elasticsearch article"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "4",
        "_score": 0.4044781,
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
          "title": "this is java, elasticsearch, hadoop blog",
          "content": "elasticsearch and hadoop are all very good solution, i am a beginner"
        }
      }
    ]
  }
}
```

变换形式后：

```http
GET /forum/article/_search
{
  "query": {
    "multi_match": {
      "query": "java solution",
      "fields": [
        "title^2",
        "content"
      ],
      "type": "best_fields",
      "tie_breaker": 0.3,
      "minimum_should_match": "50%"
    }
  }
}
```

搜索的结果为：

```json
{
  "took": 25,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 4,
    "max_score": 0.8740536,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "2",
        "_score": 0.8740536,
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
          "title": "this is java blog",
          "content": "i think java is the best programming language"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "4",
        "_score": 0.74184376,
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
          "title": "this is java, elasticsearch, hadoop blog",
          "content": "elasticsearch and hadoop are all very good solution, i am a beginner"
        }
      },
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
          "content": "spark is best big data solution based on scala ,an programming language similar to java"
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
          "content": "i like to write best elasticsearch article"
        }
      }
    ]
  }
}
```

#### most-fields 策略

知识点：

best-fields：主要是讲某一个field匹配尽可能多的关键词的doc优先返回回来

most-fields：主要是尽可能多的返回更多field匹配到某个关键词doc，优先返回回来

```http
POST /forum/_mapping/article
{
  "properties": {
    "sub_title1": {
      "type": "text",
      "analyzer": "english",
      "fields": {
        "std": {
          "type": "text",
          "analyzer": "standard"
        }
      }
    }
  }
}
```

返回结果：

```json
{
  "acknowledged": true
}
```

插入数据：

```http
POST /forum/article/_bulk
{"update":{"_id":"1"}}
{"doc":{"sub_title1":"learning more courses"}}
{"update":{"_id":"2"}}
{"doc":{"sub_title1":"learned a lot of course"}}
{"update":{"_id":"3"}}
{"doc":{"sub_title1":"we have a lot of fun"}}
{"update":{"_id":"4"}}
{"doc":{"sub_title1":"both of them are good"}}
{"update":{"_id":"5"}}
{"doc":{"sub_title1":"haha, hello world"}}
```

查询语句：

```http
GET /forum/article/_search
{
  "query": {
    "match": {
      "sub_title1": "learning courses"
    }
  }
}
```

返回语句：

```json
{
  "took": 10,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 2,
    "max_score": 1.3862944,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "2",
        "_score": 1.3862944,
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
          "title": "this is java blog",
          "content": "i think java is the best programming language",
          "sub_title": "learned a lot of course",
          "sub_title1": "learned a lot of course"
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
          "sub_title1": "learning more courses"
        }
      }
    ]
  }
}
```

返回的结果解释就是，对于 `"sub_title1": "learned a lot of course"`返回比 `"learning more courses"`更加靠前，不符合我们自己的预期，因为是使用了 english 分词之后就会把 learning --->  learn ，sources ---> source ，之后就是先关结果根据score分数的比重进行显示，至此我们使用了most-fields 来试一下。

```http
GET /forum/article/_search
{
  "query": {
    "multi_match": {
      "query": "learning courses",
      "fields": [
        "sub_title1",
        "sub_title1.std"
      ],
      "type": "most_fields"
    }
  }
}
```

返回结果：

```json
{
  "took": 11,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 2,
    "max_score": 1.3862944,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "2",
        "_score": 1.3862944,
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
          "title": "this is java blog",
          "content": "i think java is the best programming language",
          "sub_title": "learned a lot of course",
          "sub_title1": "learned a lot of course"
        }
      },
      {
        "_index": "forum",
        "_type": "article",
        "_id": "1",
        "_score": 1.1507283,
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
          "sub_title1": "learning more courses"
        }
      }
    ]
  }
}
```

对于返回的结果就是虽然，上述那个依然还是排在前面，但是我们会发现在第二个的score的分数所占的权重变大了，数据量大时，会有明显的变化。

总结：

most-fields 与 best-fields 区别：

1. best-fields：对多个field进行搜索，挑选某个field匹配度最高的那个分数，同时在多个query最高分相同的情况下，在一定程度上考虑其他query的分数，简单的来说，你对多个field进行搜索，就想搜索到某一个field尽可能包含更多关键字的数据
   1. 优点：通过best-fields策略，以及综合考虑其他field，还有minimum_should_match支持，可以尽可能精确地将匹配的结果推送到最前面。
   2. 缺点：撤了那些精准匹配的结果，其他差不的结果，排序结果不是太均匀了，没有什么区别度了。
2. most-fields：综合多个field一起进行搜索，尽可能多地让所有field的query参与到总分数的计算中来，此时就会是个搭载会，出现类似 best-fields案例最开始的那个结果，有更多的field匹配到，所以排在了前面，所以需要建立类似 sub_title.std这样的field，尽可能让某一个field精准匹配到query
   1. 优点：将尽可能匹配更多field的结果推送到最前面，整个排序结果是比较均匀的
   2. 缺点：可能那些精准匹配的结果，无法优先显示在最前面

### cross-fields 搜索

知识点：

- cross-fields搜索，一个唯一标识，跨多个field，比如一个人的姓名，可能出现在first-name、也可以出现在last-name

```http
POST /forum/article/_bulk
{"update":{"_id":"1"}}
{"doc":{"author_first_name":"Peter","author_last_name":"Smith"}}
{"update":{"_id":"2"}}
{"doc":{"author_first_name":"Smith","author_last_name":"Williams"}}
{"update":{"_id":"3"}}
{"doc":{"author_first_name":"Jack","author_last_name":"Ma"}}
{"update":{"_id":"4"}}
{"doc":{"author_first_name":"Robbin","author_last_name":"Li"}}
{"update":{"_id":"5"}}
{"doc":{"author_first_name":"Tonny","author_last_name":"Peter Smith"}}
```

查询语句：

```http
GET /forum/article/_search
{
  "query": {
    "multi_match": {
      "query": "Peter Smith",
      "type": "cross_fields",
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
  "took": 31,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 3,
    "max_score": 0.6931472,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "2",
        "_score": 0.6931472,
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
          "title": "this is java blog",
          "content": "i think java is the best programming language",
          "sub_title": "learned a lot of course",
          "sub_title1": "learned a lot of course",
          "author_first_name": "Smith",
          "author_last_name": "Williams"
        }
      },
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
          "author_last_name": "Peter Smith"
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
          "author_last_name": "Smith"
        }
      }
    ]
  }
}
```

同样的问题就是我们需要关注的结果，没有优先的展示在最前面，此处还是内部的IDF分数计算，只能是相对会有所作用。

总结：

使用`cross_fields` 的问题：

- 只是找到尽可能多的field匹配的doc，而不是某个field完全匹配的doc
- most_fields 没办法用 minimum_should_match 去掉长尾数据，就是匹配特别少的结果
- TF/IDF 算法，比如`Peter Smith` 和 `Smith Williams`，搜索`Peter Smith`的时候，由于first_name中很少有`Smith`的，所以query在所有document中的频率很低，得到的分数很高，导致 `Smith Williams`反而会排在`Peter Smith`前面

### Copy_to 定制组合搜索

解决问题：

- most-fields 存在三大弊端
- 每次查询会有多个字段，每次评分导致的，评分规则太多复杂，不太准

使用copy_to 就可以将多个字段的值拷贝到一个字段中，并建立倒排索引。

新建的new_auth_full_name是一个隐藏字段，不会直接查询显示出来。

进字段合并：

```http
PUT /forum/_mapping/article
{
  "properties": {
    "new_author_first_name": {
      "type": "text",
      "copy_to": "new_author_full_name"
    },
    "new_author_last_name": {
      "type": "text",
      "copy_to": "new_author_full_name"
    },
    "new_author_full_name": {
      "type": "text"
    }
  }
}
```

进行数据填充：

```http
POST /forum/article/_bulk
{"update":{"_id":"1"}}
{"doc":{"new_author_first_name":"Peter","new_author_last_name":"Smith"}}
{"update":{"_id":"2"}}
{"doc":{"new_author_first_name":"Smith","new_author_last_name":"Williams"}}
{"update":{"_id":"3"}}
{"doc":{"new_author_first_name":"Jack","new_author_last_name":"Ma"}}
{"update":{"_id":"4"}}
{"doc":{"new_author_first_name":"Robbin","new_author_last_name":"Li"}}
{"update":{"_id":"5"}}
{"doc":{"new_author_first_name":"Tonny","new_author_last_name":"Peter Smith"}}
```

进行字段查询：

```http
GET /forum/article/_search
{
  "query": {
    "match": {
      "new_author_full_name": "Peter Smith"
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
    "total": 3,
    "max_score": 0.6931472,
    "hits": [
      {
        "_index": "forum",
        "_type": "article",
        "_id": "2",
        "_score": 0.6931472,
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
          "title": "this is java blog",
          "content": "i think java is the best programming language",
          "sub_title": "learned a lot of course",
          "sub_title1": "learned a lot of course",
          "author_first_name": "Smith",
          "author_last_name": "Williams",
          "new_author_last_name": "Williams",
          "new_author_first_name": "Smith"
        }
      },
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

总结：

对于上述存在缺陷的解决办法：

问题1：查询多个字段，解决：把多个字段进行合并为一个字段

问题2：most_fields，没办法用minimum_should_match去掉长尾数据，就是匹配的特别少的结果。解决：可以使用 minimum_should_match 去掉长尾数据

问题3：TF/IDF算法，比如`Peter Smith`和`Smith Williams`，搜索`Peter Smith`的时候，由于`first_name`中很少有`Smith`的，所以`query`在所有`document`中的频率很低，得到的分数很高，可能`Smith Williams`反而会排在`Peter Smith`前面 --> 解决，`Smith`和`Peter`在一个`field`了，所以在所有`document`中出现的次数是均匀的，不会有极端的偏差

![](https://www.holddie.com/img/20200105153815.jpg)

