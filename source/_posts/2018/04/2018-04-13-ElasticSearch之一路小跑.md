---
title: ElasticSearch之一路小跑
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
date: 2018-04-13 21:32:16
password:
summary:  
categories: ElasticSearch
---

ElasticSearch  从安装到小跑，一路火花。。。。



### 安装

安装插件

```shell
elasticsearch-plugin install file:///E:\elasticsearch-analysis-ik-6.2.3.zip
```

卸载插件

```shell
elasticsearch-plugin remove elasticsearch-analysis-ansj
```

顺便推荐一个 Chrome 浏览器插件：

```http
https://chrome.google.com/webstore/detail/elasticsearch-head/ffmkiejjmecolpfloofpjologoblkegm/
```

### 基本概念

将 ElasticSearch 和 传统RDBMS 类比

| MySQL                  | Elasticsearch                                      |
| ---------------------- | -------------------------------------------------- |
| Database（数据库）     | Index （索引）                                     |
| Table（表）            | Type （类型）                                      |
| Row （行）             | Document （文档）                                  |
| Column （列）          | Field （字段）                                     |
| Schema （方案）        | Mapping （映射）                                   |
| Index （索引）         | Everything Indexed by default （所有字段都被索引） |
| SQL （结构化查询语言） | Query DSL （查询专用语言）                         |

Node：单个 Elastic 实例称为一个节点

Cluster：一组节点构成一个集群

Index：ES 会索引所有字段，经过处理后写入一个反向索引（Inverted Index）

Document：类似于一条记录，不要求具有相同的结构，但最好保持相同（高效）

Type：Document 可以分组，比如 weather 这个 Index 里面可以按照城市分组、按气候分组，分组就是 Type，不同的 Type，应具有相似的结构。



一些经典语句

```http
PUT /customer?pretty
```



```http
PUT /customer/_doc/1?pretty
{
    "name": "holddie" 
}
```



```http
GET /customer/_doc/1?pretty
```



```http
DELETE /customer?pretty
```



```http
PUT /customer/_doc/2?pretty
{
  "name": "Jane Doe"
}
```



```http
POST /customer/_doc?pretty
{
  "name": "Jane Doe"
}
```



```http
POST /customer/_doc/1/_update?pretty
{
  "doc": { "name": "Jane Doe" }
}
```

下载指定文件：

```http
CURL  https://raw.githubusercontent.com/elastic/elasticsearch/master/docs/src/test/resources/accounts.json  >> account.json
```

导入数据命令：

```http
CURL -H "Content-Type: application/json" -XPOST "10.20.69.235:9200/bank/_doc/_bulk?pretty&refresh" --data-binary "@/root/account.json"
```

导入数据：

```http
curl -H "Content-Type: application/json" -XPOST "localhost:9200/bank/_doc/_bulk?pretty&refresh" --data-binary "@accounts.json"
```

查看导入情况：

```http
curl "localhost:9200/_cat/indices?v"
```

来一个组合查询示例：

```http
GET /bank/_search
{
  "query": { "match_all": {} },
  "sort": [
    { "account_number": "asc" }
  ]
}
```

全部查询 Document：

```http
GET /bank/_search
{
  "query": { "match_all": {} }
}
```

筛选排序为一个：

```http
GET /bank/_search
{
  "query": { "match_all": {} },
  "size": 1
}
```

获取从第十个指定开始，后面10个：


```http
GET /bank/_search
{
  "query": { "match_all": {} },
  "from": 10,
  "size": 10
}
```

指定字段倒序：

```http
GET /bank/_search
{
  "query": { "match_all": {} },
  "sort": { "balance": { "order": "desc" } }
}
```

指定返回指定字段：

```http
GET /bank/_search
{
  "query": { "match_all": {} },
  "_source": ["account_number", "balance"]
}
```

指定字段指定具体值

```http
GET /bank/_search
{
  "query": { "match": { "account_number": 20 } }
}
```

指定包含指定字段

```http
GET /bank/_search
{
  "query": { "match": { "address": "mill" } }
}
```

多个指定字段或查询（空格隔开）

```http
GET /bank/_search
{
  "query": { "match": { "address": "mill lane" } }
}
```

指定包含字段为 `"mill lane"` 的结果集

```http
GET /bank/_search
{
  "query": { "match_phrase": { "address": "mill lane" } }
}
```

同一字段，多个限制条件 and，`bool  must` 

```http
GET /bank/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "address": "mill" } },
        { "match": { "address": "lane" } }
      ]
    }
  }
}
```

同一字段，多个限制条件 or，`bool should` 

```http
GET /bank/_search
{
  "query": {
    "bool": {
      "should": [
        { "match": { "address": "mill" } },
        { "match": { "address": "lane" } }
      ]
    }
  }
}
```

同一字段，多个限制条件 not in ，`bool must_not`

```http
GET /bank/_search
{
  "query": {
    "bool": {
      "must_not": [
        { "match": { "address": "mill" } },
        { "match": { "address": "lane" } }
      ]
    }
  }
}
```

组合操作一下，查询 age 为 40，state 不是 ID 

```http
GET /bank/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "age": "40" } }
      ],
      "must_not": [
        { "match": { "state": "ID" } }
      ]
    }
  }
}
```

`bool filter range` 关键字进行过滤，通常过滤一段数字和日期之间的内容

```http
GET /bank/_search
{
  "query": {
    "bool": {
      "must": { "match_all": {} },
      "filter": {
        "range": {
          "balance": {
            "gte": 20000,
            "lte": 30000
          }
        }
      }
    }
  }
}
```

聚合操作，`aggregations` 

```http
GET /bank/_search
{
  "size": 0,
  "aggs": {
    "group_by_state": {
      "terms": {
        "field": "state.keyword"
      }
    }
  }
}
```

以上的查询类似于

```sql
SELECT state, COUNT(*) FROM bank GROUP BY state ORDER BY COUNT(*) DESC
```

返回结果如下：

```json
{
  "took": 32,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 1000,
    "max_score": 0,
    "hits": []
  },
  "aggregations": {
    "group_by_state": {
      "doc_count_error_upper_bound": 20,
      "sum_other_doc_count": 770,
      "buckets": [
        {
          "key": "ID",
          "doc_count": 27
        },
        {
          "key": "TX",
          "doc_count": 27
        },
        {
          "key": "AL",
          "doc_count": 25
        },
        {
          "key": "MD",
          "doc_count": 25
        },
        {
          "key": "TN",
          "doc_count": 23
        },
        {
          "key": "MA",
          "doc_count": 21
        },
        {
          "key": "NC",
          "doc_count": 21
        },
        {
          "key": "ND",
          "doc_count": 21
        },
        {
          "key": "ME",
          "doc_count": 20
        },
        {
          "key": "MO",
          "doc_count": 20
        }
      ]
    }
  }
}
```

对于聚合进行求平均值

```http
GET /bank/_search
{
  "size": 0,
  "aggs": {
    "group_by_state": {
      "terms": {
        "field": "state.keyword",
        "order": {
          "average_balance": "desc"
        }
      },
      "aggs": {
        "average_balance": {
          "avg": {
            "field": "balance"
          }
        }
      }
    }
  }
}
```

对于聚合求平均值，并且对平均值排序

```http
GET /bank/_search
{
  "size": 0,
  "aggs": {
    "group_by_state": {
      "terms": {
        "field": "state.keyword",
        "order": {
          "average_balance": "desc"
        }
      },
      "aggs": {
        "average_balance": {
          "avg": {
            "field": "balance"
          }
        }
      }
    }
  }
}
```

总送对平均值，然后按照分段进行分组排序

```http
GET /bank/_search
{
  "size": 0,
  "aggs": {
    "group_by_age": {
      "range": {
        "field": "age",
        "ranges": [
          {
            "from": 20,
            "to": 30
          },
          {
            "from": 30,
            "to": 40
          },
          {
            "from": 40,
            "to": 50
          }
        ]
      },
      "aggs": {
        "group_by_gender": {
          "terms": {
            "field": "gender.keyword"
          },
          "aggs": {
            "average_balance": {
              "avg": {
                "field": "balance"
              }
            }
          }
        }
      }
    }
  }
}
```

返回结果：

```json
{
  "took": 27,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 1000,
    "max_score": 0,
    "hits": []
  },
  "aggregations": {
    "group_by_age": {
      "buckets": [
        {
          "key": "20.0-30.0",
          "from": 20,
          "to": 30,
          "doc_count": 451,
          "group_by_gender": {
            "doc_count_error_upper_bound": 0,
            "sum_other_doc_count": 0,
            "buckets": [
              {
                "key": "M",
                "doc_count": 232,
                "average_balance": {
                  "value": 27374.05172413793
                }
              },
              {
                "key": "F",
                "doc_count": 219,
                "average_balance": {
                  "value": 25341.260273972603
                }
              }
            ]
          }
        },
        {
          "key": "30.0-40.0",
          "from": 30,
          "to": 40,
          "doc_count": 504,
          "group_by_gender": {
            "doc_count_error_upper_bound": 0,
            "sum_other_doc_count": 0,
            "buckets": [
              {
                "key": "F",
                "doc_count": 253,
                "average_balance": {
                  "value": 25670.869565217392
                }
              },
              {
                "key": "M",
                "doc_count": 251,
                "average_balance": {
                  "value": 24288.239043824702
                }
              }
            ]
          }
        },
        {
          "key": "40.0-50.0",
          "from": 40,
          "to": 50,
          "doc_count": 45,
          "group_by_gender": {
            "doc_count_error_upper_bound": 0,
            "sum_other_doc_count": 0,
            "buckets": [
              {
                "key": "M",
                "doc_count": 24,
                "average_balance": {
                  "value": 26474.958333333332
                }
              },
              {
                "key": "F",
                "doc_count": 21,
                "average_balance": {
                  "value": 27992.571428571428
                }
              }
            ]
          }
        }
      ]
    }
  }
}
```

至此，官方基本入门文档体验了一波。

![](https://www.holddie.com/img/20200105153438.jpg)



















