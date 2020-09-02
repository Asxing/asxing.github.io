---
title: spring-data-jpa-实战（一）
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - JPA
  - Spring
  - ORM
date: 2018-04-01 21:32:16
password:
summary:  
categories: Spring-Data-JPA
---

在 SpringBoot 中不可或缺的一部分，以下对自己学习做一个简单记录。



主要实现类的结构图：

![](https://www.holddie.com/img/20200105152613.png)



`SimpleJpaRepository#save()` 源码分析：

```java
@Transactional
public <S extends T> S save(S entity) {

    if (entityInformation.isNew(entity)) {
        em.persist(entity);
        return entity;
    } else {
        return em.merge(entity);
    }
}
```

在对于save方法，会对传递进来的实体进行判断，一般有两种机制：

- 根据 **主键** 来判断


- 根据 `Version` 来判断

#### 方法的查询策略设置

配置方法的查询策略：

```java
@EnableJpaRepositories(queryLookupStrategy = QueryLookupStrategy.key.CREATE_IF_NOT_FOUND)
```

其中：

`QUeryLookupStrategy.key` 的值一共有三个：

-  `Create`：直接根据方法名进行创建，规则是根据方法名称的构造进行尝试，一般的方法是从方法名中删除给定的一组已知前缀，并解析该方法的其余部分，如果方法名不符合规则，启动的时候会报异常。
- `USE_DECLARED_QUERY`：声明方式创建，即本书说的注释方式，启动的时候会找到一个声明的查询，如果没有找到将抛出一个异常，查询可以由某处注释或其他的方法声明。
- `CREATE_IF_NOT_FOUND`：这个是默认的，以上两种方式的结合版，先用声明式进行查找，如果没有找到与方法相匹配的查询，那用 Create 的方法名创建规则创建一个查询。

QueryLookupStrategy 是策略的定义接口，jpaQueryLookupStrategy 是具体策略的实现类。

#### 查询方法的创建

具体实现细节：

![](https://www.holddie.com/img/20200105152705.png)



#### @Query 的优缺点

##### 优点

- 可以灵活快速的使用 JPQL 和 SQL
- 对返回的结果和字段记性自定义
- 支持连表查询和对象关联查询，可以组合出来复杂的 SQL 或 JPQL
- 可以很好的表达你的查询思路
- 灵活性非常强，快捷方便

##### 缺点

- 不支持动态 查询条件，参数个数如果是不固定的不支持
- 有些读者会将返回结果用 Map 或者 Object[] 数组接收结果，会导致调用此方法的开发人员不知道返回结果里面到底有些什么数据

##### 实战经验

- 当出现很复杂的SQL或者JPQL的时候建议用试图
- 返回结果一定要用对象接收，最好每个对象里面的字段和你返回的结果一一对应
- 能用 JPQL  的就不要用SQL

### @Entity 注解含义

我们平常使用的实体注解基本上都是在 `javax.persistence` 包下面，对应主要的关系结构图为：

![](https://www.holddie.com/img/20200105152744.png)

其中描述一下上述架构中的显示单元：

| 单元                 | 描述                                                         |
| :------------------- | ------------------------------------------------------------ |
| EntityManagerFactory | 这是一个 Entitymanager 的工厂类，它创建并管理多个 EntityManager 实例 |
| EntityManager        | 这是一个接口，它管理的持久化操作的对象，他的工作原理类似工厂的查询实例 |
| Entity               | 实体是持久化对象，是存储在数据库中的记录                     |
| EntityTransaction    | 它与 EntityManager 是一对一的关系，对于每个 EntityManager， 操作是由EntityTransaction 类维护 |
| Persistence          | 这个类包含静态方法来获取 EntityManagerFactory 实例           |
| Query                | 该接口由每个 JPA 供应商，能够获得符合标准的关系对象          |

对于PO实体：

- 必须实现 Serializable 接口
- 必须由默认的 public 无参构造方法
- 必须覆盖 equals 和 hashCode 方法，
  - equals 方法用于判断两个对象是否相等，EntityManager 通过 find 方法来查找 Entity 时，根据 equals 的返回值来判断的。
  - hashCode 方法返回当前对象的哈希值，生成 hashCode 相同的概率越小越好，算法可以进行优化。




#### Left join & Inner join 与 @EntityGraph

当时用 @ManyToMany、@ManyToOne、@OneTomany、@OneToOne 关联关系的时候，当 FetchType 怎么配置 LAZY 或者 EAGER，SQL 真正执行的时候都是有一条主表查询和N条子表查询组成，这种查询效率一般比较低下，子对象有多少个就会执行N+1条SQL，为此在 JPA2.1 推出了 @EntityGraph、@NamedEntityGraph 用来提高效率，很好解决了 N+1 效率。







### 坑

- 实体里面的注解要么在get方法上，要么全在字段上面，否则会启动报错，建议把注解放在get方法上面

- 当覆盖toString() 方法的时候，也会有双向关联死循环的问题，解决的方法是，toString的时候在一方排除即可

- 虽然我们使用关联查询，但是在实际工作中，所有的关联查询，表上一般是不需要建立外键约束的，为了提高操作效率，但是每个外键的字段上都会加上一般索引。

- 不同的关联关系的配置，`@JoinColumn` 里面的（name、referencedColumn）代表的意思是不一样的，很容易弄混：

  - 打印出SQL，配置如下设置：

    ```properties
    spring.jpa.show-sql=true
    spring.jpa.properties.hibernate.use_sql_comments=true
    spring.jpa.properties.hibernate.format_sql=true
    spring.jpa.properties.hibernate.type=trace
    logging.level.org.hibernate.type.descriptor.sql=trace
    ```

  - 我们在表上建立外键约束，然后利用 Intellij IDEA 自动生成关联关系注解，当生成玩代码的时候把表上的外键约束删除掉

- #### 级联操作的使用需要注意

  当我们使用关联操作的时候建议大家 cascade = CascadeType.PERSIST 配置成这个，这样 insert 的时候能帮我们不少忙，它的原理是两条都先 insert，然后再来个 update 把关联关系更新上去，读者自己打印出 SQL，也可以看得出来。如下：

  ```java
  @OneToMany(cascade = CascadeType.PERSIST)
  @JoinColumn(referencedColumnName = "id", name = "message_request_id")
  @JsonManagedReference
  public List<MessageRequestTelephone> getMessageRequestTelephone() {
      return messageRequestTelephone;
  }
  ```

  级联更新、级联删除的时候比较危险，建议考虑清楚，或者完全掌握的时候再去使用，否则生产产生事故还是比较糟糕的。







#### 级联操作的使用需要注意

当我们使用关联操作的时候建议大家 cascade = CascadeType.PERSIST 配置成这个，这样 insert 的时候能帮我们不少忙，它的原理是两条都先 insert，然后再来个 update 把关联关系更新上去，读者自己打印出 SQL，也可以看得出来。如下：

```
    @OneToMany(cascade = CascadeType.PERSIST)
    @JoinColumn(referencedColumnName = "id", name = "message_request_id")
    @JsonManagedReference
    public List<MessageRequestTelephone> getMessageRequestTelephone() {
        return messageRequestTelephone;
    }
```

级联更新、级联删除的时候比较危险，建议考虑清楚，或者完全掌握的时候再去使用，否则生产产生事故还是比较糟糕的。



### JpaRepository 使用

从  JpaRepository 开始的子类，都是SpringData项目对于 JPA 实现的封装和扩展

![](https://www.holddie.com/img/20200105152727.png)






