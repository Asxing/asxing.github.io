---
title: ElasticSearch-查询建议（八）
tags: [ElasticSearch,源码]
date: 2018-09-27 09:16:58
categories: ElasticSearch
---



> 命运是被覆上朦胧的面纱，看得见，却永远也看不清。 ——我爱千泷

## 查询建议

主要包含：

- 拼写建议
- 自动补全

查询建议是使用_search端点地址，在DSL中suggest节点来蒂尼需要的建议查询。

```json
POST twitter/_search
{
    "query": {
        "match": {
            "message": "tring out elasticsearch"
        }
    },
    "suggest": {
        "my-suggestion": {
            "text": "tring out elasticsearch",
            "term": {
                "field": "message"
            }
        }
    }
}
```

### Term suggester

term 词项建议器，对给入的文本进行分词，为每个词进行模糊查询提供词项建议。对于在索引中存在词默认不提供建议词，不存在的词则根据模糊查询结果进行排序后取一定数量的建议词。

常见的建议选项：

| text         | 指定搜索文本                                                 |
| ------------ | ------------------------------------------------------------ |
| field        | 获取建议词的搜索字段                                         |
| analyzer     | 指定分词器                                                   |
| size         | 每个词返回的最大建议词数                                     |
| sort         | 如何对建议词进行排序，可用选项：score: 先按评分排序、再按文档频率排、term顺序；frequency: 先按文档频率排，再按评分、term顺序排。 |
| suggest_mode | 建议模式，控制提供建议词的方式：missing: 仅在搜索的词项在索引中不存在时才提供建议词，默认值；popular: 仅建议文档频率比搜索词项高的词 . always: 总是提供匹配的建议词。 |

### phrase suggest

phrase 短语建议，在term的基础上，会考量多个term之间的关系，比如是否同时出现在索引的原文里，相邻程度，以及词频等，效果不是特别好

```json
POST /ftq/_search
{
    "query": {
        "match_all": {}
    },
    "suggest" : {
        "myss":{
            "text": "java sprin boot",
            "phrase": {
                "field": "title"
            }
        }
    }
}
```

### completion suggester 自动补全

- 特点：针对用户的需求，迅速的返回结果
- 传统搜索使用反向倒排索引，比较慢
- 自动补全采用的是将analyze过的数据编码成FST和索引，一起存放。
- 对于一个open状态的索引，FST 会被ES整个装载到内存里，进行前缀查找速度极快，
- 缺陷就是FST索引只可以进行前缀查找
- 可以进行去重，