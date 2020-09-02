---
title: ElasticSearch-搜索详解（七）
tags: [ElasticSearch,源码]
date: 2018-09-26 09:16:58
categories: ElasticSearch
---



> 奋力前行后你会发现，当初你所忌惮的人，将不配成为你的对手。 ——黎煋

## 搜索API

### 搜索端点地址说明

```http
GET /twitter/_search?q=user:kimchy

GET /twitter/tweet,user/_search?q=user:kimchy

GET /kimchy,elasticsearch/_search?q=tag:wow

GET /_all/_search?q=tag:wow

GET /_search?q=tag:wow
```

搜索的端点地址可以是多索引多mapping type 的。

搜索的参数可作为URI请求参数给出，也可用request body 给出。

### URI Search

通过URI参数来指定查询相关参数

参考文档：`https://www.elastic.co/guide/en/elasticsearch/reference/current/search-uri-request.html`

### 返回结果说明

### Request Body Search

#### Query 指定查询

#### 指定返回内容

#### 过滤

#### 排序

#### 折叠

#### 分页

使用`search_after`必须指定排序，并且这个排序组合值每个文档唯一，最好排序中包含`_id`字段。

search_after 的值就是这个排序值，用search_after时，from只能为0、-1。

#### 高亮

高亮单独展示，对于数据的展示，

#### profile

为了调试查看详细的查询信息，针对查询详情优化，查询耗时

explain 是针对查询的评分详情

### Count API

查询的数量，在type后面使用`_count`，返回结果中包含 `count`字段

`_validate` 底层的查询校验，会帮助我们查询是否正确，获取正确的，并且 `explain=true` 查看定义是否正确，可以使用`rewrite=true`，会获得比explain更详细的内容，获取是

### Explain API

### Search shards API

## Query DSL

Domain Specific Language：领域特定语言

ElasticSearch 给予JSON提供完成的查询DSL来定义查询。

一个查询可以由两部分构成：

- Leaf query clauses（叶子查询）
  - 指定的字段上查询指定的值
  - match、term、range query
- compound query clauses （复合查询）
  - 以逻辑方式组合多个叶子、复合查询为一个查询

一个字句的行为取决于他用在query context 还是 filter context：

query context：查询上下文 使用query元素，主要回答：“这个文档有多匹配这个查询？”，会给出一个相关性评分。

filter context：过滤上下文使用filter元素，主要回答“这个文档是否匹配这个查询”，不参与相关性评分。

被频繁使用的过滤器将被ES自动缓存，来提高查询性能。

query 和 filter 都是面向所有文档，最后结果是两个集合交集。

### match all query

全部查询和全部不查询，

### full text querys

#### match（单个字段）

match：只会针对一个字段进行查询，当关键词之间存在空格的时候，一般情况下，默认操作是or，可以指定oprator

match_phrase：关键词短语查询，短语关键词顺序固定，除非使用移动因子slot

match_phrase_prefix：关键词前缀查询，可以指定前缀匹配选用的最大词项数量，`max_expansions` 选项

#### multi_match（多个字段查询）

multi_match：可以指定多个字段使用 fields 数组包含。支持模糊字段，以及字段加权

### common term query

#### tf：term frequency 词频：一个词在一片文档中出现的频率

##### tf 是否越大越好？

- 不是的，针对于平常使用的简单短语无效，可以自定义自己的计算方式。

#### df：document frequency 文档频率：包含某个词的文档数

- df 值越大说明这个词在这个文档中是越不重要，因为每一篇文档中都有
- 若 tf 越高，df 也越高，那么说明文档是重要，两高就越重要
- 如何体现数值重要性：文档总数/df

#### idf：inverse document frequency 逆文档频率：用来表示文档集中的重要性

idf = log(文档集总文档/(包含词t的文档数+1))

+1 ：为了避免除0

common 区分常用（高频）词查询让我们可以通过cutoff_frequency来指定一个分界文档频率值，将搜索文本中的词分为高频词和低频词，低频词的重要性高于高频词，先对低频词进行搜索并计算所有匹配文档相关性得分，然后在搜索和高频词匹配的文档，这时会搜到很多文档，但只对和低频词重叠的文档进行相关性得分计算和低频词累加作为文档得分（可以保证搜索精度，同时大大提高搜索性能）。实际执行的搜索是必须包含低频词+或包含高频词。

优化：如果都是高频词，那就对这些词进行and查询

进一步优化：让用户可以自己对高频词做and、or操作，自己定义对低频词进行and、or操作，或指定最少得多少个同时匹配。

```json
GET /_search
{
    "query": {
        "common": {
            "message": {
                "query": "this is bonsai cool",
                "cutoff_frequency": 0.001,
                "low_freq_operator": "and",
                "minimum_should_match": {
                    "low_freq": 2,
                    "high_freq": 3
                }
            }
        }
    }
}
# cutoff_frequency: 值大于1表示文档数，0~1.0表示占比，此处界定文档频率大于0.1%的词为高频词。
# low_freq_operator: 表示关键词之间的关系
# 可用参数：minimum_should_match(high_freq, low_freq),low_freq_operator,high_freq_operator,boost and analyzer
```

### query string

query_string 查询，直接用lucene查询语法，ES中接到请求后，通过查询解析器解析查询串生成对应的查询。

### term level query

词项查询

- trem query
  - 用于查询指定字段包含某个词项的文档
  - 可以使用boost加权重
- terms query
  - 查询指定字段包含某些词项的文档
- terms set query
  - 可以进行嵌套查询，指定索引，type，id，path，routing
- range query
  - 范围查询指定边界值
  - gte、gt、lte、lt、boost、format（指定格式）
  - 时间舍入规则
    - now-1/d
- exists query
  - 查询指定字段不为空的文档
- prefix query
  - 前缀查询
- wildcard query
  - ？：一个或多个
  - *：零个或多个
- regexp query
  - 指定字段
- fuzzy query
  - fuzziness：2，最大也就是2
- type query
  - 可以直接指定type查询
- ids query
  - 根据文档id查询

### compound query

复合查询：

- constant score query
  - 用来指定查询，将查询匹配到的文档的评分设为一个常值，指定boost
- bool query
  - 用来组合多个查询字句为一个查询
  - 关键字：
    - must：必须满足
    - filter：必须满足，但是执行的是filter上下文，不影响评分
    - should：或
    - must_not：必须不满足，在filter上下文中执行
- dis max query
- function score query
- boosting query

### joining query

### geo qurey

### specialized query

### span qurey