---
title: ElasticSearch-ELK（十二）
author: HoldDie
tags: [ElasticSearch,搜索,聚合分析]
top: false
date: 2018-10-09 19:43:41
categories: ElasticSearch
---



> 这世上每个人都背负着枷锁，有的人是别人给的，有的是自己给的。 ——子龙

### FileBeat

#### 启动

```shell
# 启动
sudo ./filebeat

# 指定配置文件
sudo ./filebeat -e -c filebeat.yml
```

#### 查看索引

```http
# 查看创建的索引
GET /_cat/indices?v

# 查看索引的数据格式
GET /filebeat*/_search?q=*
```

#### 配置索引模板

默认情况下，如果输出是 elasticsearch，filebeat 自动创建推荐的索引模板（定义在fileds.yml）

- 如果要使用自定义模板，可以在`filebeat.yml` 中配置模板

```yaml
setup.template.name: "template_name"

setup.template.fields: "path/to/fields.yml"
```

- 覆盖已存在的模板

```yaml
setup.template.overwrite: true
```

- 改变索引的名字，默认为filebeat-6.2.4-yyyy.MM.dd

```yaml
# 对应日志索引名字中应该包含版本号和日期部分
output.elasticsearch.index: "customname-%{[beat.version]}-%{+yyyy.MM.dd}"
setup.template.name: "customname"
setup.template.pattern: "customname-*"
# 使用kibana的dashboard时需要开启
#setup.dashboards.index: "customname-*"
```

- 手动配置

> 手动载入模板，当使用logstash时，需要手动执行命令来向ES创建模板

```shell
filebeat setup --template -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
```

- 配置 kibana 的 dashboards，在 filebeat.yml 中

```yaml
setup.dashboards.enabled: true
setup.kibana:
    host: "mykibanahost:5601"
    # 当有认证的时候
    username: "elastic"
    password: "elastic"
```

- 输出到 `logstash`

```yaml
output.logstash:
    hosts: ["127.0.0.1:5044"]
```

- FileBeat 中各种配置说明
  - https://www.elastic.co/guide/en/beats/filebeat/6.2/configuring-howto-filebeat.html
- 运行命令行说明
  - https://www.elastic.co/guide/en/beats/filebeat/6.2/command-line-options.html
- FileBeat moudles 模块
  - fileBeat 提供了很多常见的应用日志格式的读取解析模块，简化使用。
  - https://www.elastic.co/guide/en/beats/filebeat/6.2/filebeat-modules-quickstart.html
  - https://www.elastic.co/guide/en/beats/filebeat/6.2/filebeat-modules-overview.html
  - https://www.elastic.co/guide/en/beats/filebeat/6.2/configuration-filebeat-modules.html
- 安装插件

```shell
# 安装对应插件,nginx 日志解析过滤
sudo bin/elasticsearch-plugin install ingest-geoip
sudo bin/elasticsearch-plugin install ingest-user-agent
# 查看、启用模块
./filebeat modules list
filebeat modules enable apache2 auditd mysql

# 装完插件之后，内存不够使用，此时我们要设置jvm.options配置，
```

- 对于应用模块解析，日志地址指定

### Logstash

```json
{
    head: [
        {
            name: "颜色",
            value: "param1"
        },
        {    
            name: "尺码"，
            value: "param2"
        },
        {
            name: "售价",
            value: "param3"
        },
        {
            name: "供货价(元)",
            value: "param4"
        },
        {
            name: "利润(元)",
            value: "param5"
        }
    ],
    body: [
        {
            param1: "红色",
            param2: "大",
            param3: "30",
            param4: "29",
            param5: "1"            
        },
        {
            param1: "黑色",
            param2: "小",
            param3: "30",
            param4: "29",
            param5: "1"  
        }
    ]
}
```