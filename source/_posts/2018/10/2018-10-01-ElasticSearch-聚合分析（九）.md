---
title: ElasticSearch-聚合分析（九）
author: HoldDie
tags: [ElasticSearch,搜索,聚合分析]
top: false
date: 2018-10-01 19:43:41
categories: ElasticSearch
---



> 回忆是现实的避难所，而现实却带你去往未来。 ——R.S

### 聚合分析

聚合分析完成一个查询的数据集中数据的聚合计算。

对一个数据集求最大，最小 和 平均值等指标的聚合，指标聚合（ `metric`）

在关系型数据库中出了有聚合函数以外，还有对查询出的数据进行分组group by，在这个组上进行指标聚合，在ES中Group By称为分桶，桶聚合（bucketing）

除此之外，ES中还有 矩阵聚合（matrix）、管道聚合（pipleline）

聚合分析写法：

```json

```

聚合计算的值，可以取字段的值，也可以是脚本计算的结果。

### 指标聚合

- max aggregation
- min aggregation
- sum aggregation
- avg aggregation
- cardinality aggregation
- stats aggregation
  - 会同时统计count、max、min、avg、sum，一次得到多个值
- extended stats aggregation
- percentiles aggregation
  - 按从小到大累计每个值对应的文档数的占比（占所有命中文档的百分比），返回指定占比比例对应的值。
- percentile ranks aggregation
  - 统计指定值的占比值
- value count aggregation
- Geo bounds aggregation
- Geo gentroid aggregation

进行聚合分析的时候，我们记性sort排序只是针对查询的排序，而不是聚合之后的排序，

聚合的类型

### 桶聚合

分类：

- Terms Aggregation
  - 值项分组聚合，根据对应值进行分组，不是分词之后的值
  - 文档最大值计算可能有偏差
  - size：指定返回多个分组
  - shard_size：指定每个分片上返回多少个分组
- Filter Aggregation
  - 在查询命中的文旦中选取复合过滤条件的文档进行聚合
  - 当成一个查询过滤就👌
- Filters Aggregation
  - 多个过滤条件
  - 并且前后两个filters，进行嵌套过滤
- Range Aggregation
  - 范围分组聚合，使用range，
  - 指定字段，执行范围
  - from 、to：包含下边界，不包含上边界
  - keyd：true，表示内部指定的数值范围是
- Date Range Aggregation
  - 时间范围聚合
  - 多了一个修饰为：format，指定格式
- Date Histogram Aggregation
  - 时间直方图（柱状）聚合
  - 就是按天、月、年等进行聚合统计
  - 可按year（1y）、quarter（1q）、month（1M）、week（1w）、day（1day）、hour（1h）
- Missing Aggregation
  - 缺失值统计
  - missing
- Geo Distance Aggregation
  - 地理距离分区聚合

注意要点：

- 进行桶聚合结果不是很准确
- 把 shard_size 调小，偏差会变大
- shard_size 的默认值为：
  - 索引只有一个分片：size
  - 多个分片：size*1.5 + 10
- size = 0 ，hits 中不需要返回值，
- 对于文本字段，可以使用模糊匹配，包含、不包含、脚本计算、缺失的值、文本值为一个范围内的值、