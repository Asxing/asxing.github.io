---
title: spring-data-jpa-QueryDsl（二）
author: HoldDie
tags: [JPA,QueryDsl]
top: false
date: 2018-12-23 19:43:41
categories: JPA 
---

**在最深沉的夜里，连自己的影子都会离你而去。 ——江左煤狼**

> 怒怼一波 QuserDsl ，业务需要，DDL领域模型需要

### 1. Maven 依赖

#### 1.1 添加依赖

```xml
<!--query dsl -->  
<dependency>  
    <groupId>com.querydsl</groupId>  
    <artifactId>querydsl-jpa</artifactId>  
</dependency>  
<dependency>  
    <groupId>com.querydsl</groupId>  
    <artifactId>querydsl-apt</artifactId>  
    <scope>provided</scope>  
</dependency>
```

#### 1.2 编译插件

```xml
<plugin>  
    <groupId>com.mysema.maven</groupId>  
    <artifactId>apt-maven-plugin</artifactId>  
    <version>1.1.3</version>  
    <executions>  
        <execution>  
            <goals>  
                <goal>process</goal>  
            </goals>  
            <configuration>  
                <outputDirectory>target/generated-sources/java</outputDirectory>  
                <processor>com.querydsl.apt.jpa.JPAAnnotationProcessor</processor>  
            </configuration>  
        </execution>  
    </executions>  
</plugin>
```

### 2. 单表查询

```java
package com.chhliu.springboot.jpa.repository;

import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;
import javax.transaction.Transactional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import com.chhliu.springboot.jpa.entity.QUser;
import com.chhliu.springboot.jpa.entity.User;
import com.querydsl.core.types.Predicate;
import com.querydsl.jpa.impl.JPAQueryFactory;

/**
 * 描述：QueryDSL JPA
 * @author chhliu
 */
@Component
@Transactional
public class UserRepositoryManagerDsl {
    @Autowired
    private UserRepositoryDls repository;

    @Autowired
    @PersistenceContext
    private EntityManager entityManager;

    private JPAQueryFactory queryFactory;

    @PostConstruct
    public void init() {
        queryFactory = new JPAQueryFactory(entityManager);
    }

    public User findUserByUserName(final String userName){
        /**
         * 该例是使用spring data QueryDSL实现
         */
        QUser quser = QUser.user;
        Predicate predicate = quser.name.eq(userName);
        return repository.findOne(predicate);
    }

    /**
     * attention:
     * Details：查询user表中的所有记录
     */
    public List<User> findAll(){
        QUser quser = QUser.user;
        return queryFactory.selectFrom(quser)
            .fetch();
    }

    /**
     * Details：单条件查询
     */
    public User findOneByUserName(final String userName){
        QUser quser = QUser.user;
        return queryFactory.selectFrom(quser)
            .where(quser.name.eq(userName))
            .fetchOne();
    }

    /**
     * Details：单表多条件查询
     */
    public User findOneByUserNameAndAddress(final String userName, final String address){
        QUser quser = QUser.user;
        return queryFactory.select(quser)
            .from(quser) // 上面两句代码等价与selectFrom
            .where(quser.name.eq(userName).and(quser.address.eq(address)))// 这句代码等同于where(quser.name.eq(userName), quser.address.eq(address))
            .fetchOne();
    }

    /**
     * Details：使用join查询
     */
    public List<User> findUsersByJoin(){
        QUser quser = QUser.user;
        QUser userName = new QUser("name");
        return queryFactory.selectFrom(quser)
            .innerJoin(quser)
            .on(quser.id.intValue().eq(userName.id.intValue()))
            .fetch();
    }

    /**
     * Details：将查询结果排序
     */
    public List<User> findUserAndOrder(){
        QUser quser = QUser.user;
        return queryFactory.selectFrom(quser)
            .orderBy(quser.id.desc())
            .fetch();
    }

    /**
     * Details：Group By使用
     */
    public List<String> findUserByGroup(){
        QUser quser = QUser.user;
        return queryFactory.select(quser.name)
            .from(quser)
            .groupBy(quser.name)
            .fetch();
    }

    /**
     * Details：删除用户
     */
    public long deleteUser(String userName){
        QUser quser = QUser.user;
        return queryFactory.delete(quser).where(quser.name.eq(userName)).execute();
    }

    /**
     * Details：更新记录
     */
    public long updateUser(final User u, final String userName){
        QUser quser = QUser.user;
        return queryFactory.update(quser).where(quser.name.eq(userName))
            .set(quser.name, u.getName())
            .set(quser.age, u.getAge())
            .set(quser.address, u.getAddress())
            .execute();
    }

    /**
     * Details：使用原生Query
     */
    public User findOneUserByOriginalSql(final String userName){
        QUser quser = QUser.user;
        Query query = queryFactory.selectFrom(quser)
            .where(quser.name.eq(userName)).createQuery();
        return (User) query.getSingleResult();
    }

    /**
     * Details：分页查询单表
     */
    public Page<User> findAllAndPager(final int offset, final int pageSize){
        Predicate predicate = QUser.user.id.lt(10);
        Sort sort = new Sort(new Sort.Order(Sort.Direction.DESC, "id"));
        PageRequest pr = new PageRequest(offset, pageSize, sort);
        return repository.findAll(predicate, pr);
    }
}
```

### 3. 多表操作一对一

```java
package com.chhliu.springboot.jpa.repository;

import java.util.ArrayList;
import java.util.List;

import javax.annotation.PostConstruct;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.chhliu.springboot.jpa.dto.PersonIDCardDto;
import com.chhliu.springboot.jpa.entity.QIDCard;
import com.chhliu.springboot.jpa.entity.QPerson;
import com.querydsl.core.QueryResults;
import com.querydsl.core.Tuple;
import com.querydsl.core.types.Predicate;
import com.querydsl.jpa.impl.JPAQuery;
import com.querydsl.jpa.impl.JPAQueryFactory;

@Component
public class PersonAndIDCardManager {
    @Autowired
    @PersistenceContext
    private EntityManager entityManager;

    private JPAQueryFactory queryFactory;

    @PostConstruct
    public void init() {
        queryFactory = new JPAQueryFactory(entityManager);
    }

    /**
     * Details：多表动态查询
     */
    public List<Tuple> findAllPersonAndIdCard(){
        Predicate predicate = (QPerson.person.id.intValue()).eq(QIDCard.iDCard.person.id.intValue());
        JPAQuery<Tuple> jpaQuery = queryFactory.select(QIDCard.iDCard.idNo, QPerson.person.address, QPerson.person.name)
                .from(QIDCard.iDCard, QPerson.person)
                .where(predicate);
        return jpaQuery.fetch();
    }

    /**
     * Details：将查询结果以DTO的方式输出
     */
    public List<PersonIDCardDto> findByDTO(){
        Predicate predicate = (QPerson.person.id.intValue()).eq(QIDCard.iDCard.person.id.intValue());
        JPAQuery<Tuple> jpaQuery = queryFactory.select(QIDCard.iDCard.idNo, QPerson.person.address, QPerson.person.name)
                .from(QIDCard.iDCard, QPerson.person)
                .where(predicate);
        List<Tuple> tuples = jpaQuery.fetch();
        List<PersonIDCardDto> dtos = new ArrayList<PersonIDCardDto>();
        if(null != tuples && !tuples.isEmpty()){
            for(Tuple tuple:tuples){
                String address = tuple.get(QPerson.person.address);
                String name = tuple.get(QPerson.person.name);
                String idCard = tuple.get(QIDCard.iDCard.idNo);
                PersonIDCardDto dto = new PersonIDCardDto();
                dto.setAddress(address);
                dto.setIdNo(idCard);
                dto.setName(name);
                dtos.add(dto);
            }
        }
        return dtos;
    }

    /**
     * Details：多表动态查询，并分页
     */
    public QueryResults<Tuple> findByDtoAndPager(int offset, int pageSize){
        Predicate predicate = (QPerson.person.id.intValue()).eq(QIDCard.iDCard.person.id.intValue());
        return queryFactory.select(QIDCard.iDCard.idNo, QPerson.person.address, QPerson.person.name)
                .from(QIDCard.iDCard, QPerson.person)
                .where(predicate)
                .offset(offset)
                .limit(pageSize)
                .fetchResults();
    }
}
```

### 4. 一对多

```java
package com.chhliu.springboot.jpa.repository;

import java.util.List;

import javax.annotation.PostConstruct;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.chhliu.springboot.jpa.entity.QOrder;
import com.chhliu.springboot.jpa.entity.QOrderItem;
import com.querydsl.core.Tuple;
import com.querydsl.core.types.Predicate;
import com.querydsl.jpa.impl.JPAQuery;
import com.querydsl.jpa.impl.JPAQueryFactory;

@Component
public class OrderAndOrderItemManager {

    @Autowired
    @PersistenceContext
    private EntityManager entityManager;

    private JPAQueryFactory queryFactory;

    @PostConstruct
    public void init() {
        queryFactory = new JPAQueryFactory(entityManager);
    }

    /**
     * Details：一对多，条件查询
     */
    public List<Tuple> findOrderAndOrderItemByOrderName(String orderName){
        //添加查询条件
        Predicate predicate = QOrder.order.orderName.eq(orderName);
        JPAQuery<Tuple> jpaQuery = queryFactory.select(QOrder.order, QOrderItem.orderItem)
            .from(QOrder.order, QOrderItem.orderItem)
            .where(QOrderItem.orderItem.order.id.intValue().eq(QOrder.order.id.intValue()), predicate);

        //拿到结果
        return jpaQuery.fetch();
    }

    /**
     * Details：多表连接查询
     */
    public List<Tuple> findAllByOrderName(String orderName){
        //添加查询条件
        Predicate predicate = QOrder.order.orderName.eq(orderName);
        JPAQuery<Tuple> jpaQuery = queryFactory.select(QOrder.order, QOrderItem.orderItem)
            .from(QOrder.order, QOrderItem.orderItem)
            .rightJoin(QOrder.order)
            .on(QOrderItem.orderItem.order.id.intValue().eq(QOrder.order.id.intValue()));
        jpaQuery.where(predicate);
        //拿到结果
        return jpaQuery.fetch();
    }
}
```

### 5. 返回结果封装

```java
/**
     * Details：方式一：使用Bean投影
     */
public List<PersonIDCardDto> findByDTOUseBean(){
    Predicate predicate = (QPerson.person.id.intValue()).eq(QIDCard.iDCard.person.id.intValue());
    return queryFactory.select(
        Projections.bean(PersonIDCardDto.class, QIDCard.iDCard.idNo, QPerson.person.address, QPerson.person.name))
        .from(QIDCard.iDCard, QPerson.person)
        .where(predicate)
        .fetch();
}

/**
     * Details：方式二：使用fields来代替setter
     */
public List<PersonIDCardDto> findByDTOUseFields(){
    Predicate predicate = (QPerson.person.id.intValue()).eq(QIDCard.iDCard.person.id.intValue());
    return queryFactory.select(
        Projections.fields(PersonIDCardDto.class, QIDCard.iDCard.idNo, QPerson.person.address, QPerson.person.name))
        .from(QIDCard.iDCard, QPerson.person)
        .where(predicate)
        .fetch();
}

/**
     * Details：方式三：使用构造方法，注意构造方法中属性的顺序必须和构造器中的顺序一致
     */
public List<PersonIDCardDto> findByDTOUseConstructor(){
    Predicate predicate = (QPerson.person.id.intValue()).eq(QIDCard.iDCard.person.id.intValue());
    return queryFactory.select(
        Projections.constructor(PersonIDCardDto.class, QPerson.person.name, QPerson.person.address, QIDCard.iDCard.idNo))
        .from(QIDCard.iDCard, QPerson.person)
        .where(predicate)
        .fetch();
}
```

### 6. QueryDSL的使用

```java
@Repository
public interface DebtRepository extends DebtRepositoryCustom, JpaRepository<Debt, Long>, QuerydslPredicateExecutor<Debt> {
}

public interface DebtRepositoryCustom {
}

public class DebtRepositoryImpl extends QuerydslRepositorySupport implements DebtRepositoryCustom {
    public DebtRepositoryImpl() {
        super(Debt.class);
    }
}
```