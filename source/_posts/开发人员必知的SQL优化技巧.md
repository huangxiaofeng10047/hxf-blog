---
title: 开发人员必知的SQL优化技巧
date: 2021-08-13 14:23:16
tags:
- sql
categories: 
- 数据库
---

#### 不会命中索引的情况

1. 负向条件不会命中索引

   ```
   SELECT id FROM user WHERE status !=1 AND status != 2;  /* 不会命中 */
   ```

   负向条件有`!=`、`<>`、`not in`、`not exists`、`not like`等

   

2. 前导模糊查询不会命中索引

   ```
   select id from user where name like '%xx'  /* 不会命中 */
   ```

   ```
   select id from user where name like 'xx%'  /* 会命中 */
   ```

3. 数据类型存在隐形转换的不会命中索引

   ```
   SELECT id FROM user WHERE name=1;     /* 不会命中 */
   ```

   ```
   SELECT id FROM user WHERE name='1';   /* 会命中 */
   ```

4. 复合索引最左原则

   对于复合索引（(username, passwd)

   ```
   select id from user where username=? and passwd=?      /* 能命中 */
   ```

   ```
   select id from user where passwd=? and username=?  /* 能命中 */
   ```

   ```
   select id from user where username=?                   /* 能命中 */
   ```

   ```
   select id from user where passwd=?                     /* 不能，不满足复合索引最左原则 */
   ```

5. 用OR分割的条件，如果其中有一个不是索引字段，则都不会走索引

   ```
   SELECT id FROM user WHERE username = 'aa' OR age = 12; 
   ```

   因为or后面的条件列中没有索引，那么后面的查询肯定要走全表扫描，在存在全表扫描的情况下，就没有必要多一次索引扫描增加IO访问。

6. 在字段上做计算，不会使用索引

   ```
   select id from user where YEAR(create_date) < = '2020'
   ```

   即使create_date建了索引，也不会命中。

 

#### 索引规范

1. 数据区分度不大的字段不宜使用索引，或者说字段的值的差异性不大或重复性高

   ```
   select id from user where sex=1
   ```

   原因：性别只有两个值，每次过滤掉的数据很少，不宜使用索引。

2. 如果单条查询更频繁，使用Hash索引性能更好

   ```
   select id from user where username=?
   ```

   原因：B-Tree时间复杂度O(logn)，Hash索引时间复杂度O(1)

3. 对于索引字段，应该不允许为null，否则查询存在大坑，可能得到不是预期的结果集

   ```
   select id from user where username != 'aaa'
   ```

   如果username允许为null，索引不存储null值，结果集中不会包含这些记录。

 

#### 最佳实践

1. SELECT语句务必指明字段名称

   原因有三：

   - SELECT * 增加很多不必要的消耗（CPU、IO、内存、网络带宽）

   - 增加了使用覆盖索引的可能性；

     ```
     select name, password FROM user 
     ```

     假如已经有复合索引(name, password)，那么数据只用从索引中就能够取得，不必去读取数据行。大大提升性能。

   - 当表结构发生改变时，调用端代码也需要跟着调整。

2. 如果明确知道只有一条结果返回，limit 1能够提高效率。

   ```
   select * from user where username=?;
   ```

   ```
   /* 可以优化为 */
   ```

   ```
   select * from user where username=? limit 1
   ```

   原因：明确告诉数据库有一条数据，它会在找到数据后，停止继续往下查找，从而提高效率

3. 把计算放到业务层，而不是放在数据库端。

   把计算放到业务层，传给数据库一条静态SQL，才有可能利用上数据库内部的缓存，从而得到意想不到优化效果。

   ```
   select * from where create_date < = CURDATE()
   ```

   并不是好的实践

   ```
   # Python代码
   ```

   ```
   sql = "select * from order where create_date < = " + date.today.strftime("%Y-%m-%d") cursor.execute(sql)
   ```

4. 尽量用union all代替union

   union和union all的差异主要是前者需要将结果集合并后再进行唯一性过滤操作，这就会涉及到排序，增加大量的CPU运算，加大资源消耗及延迟。当然，union all的前提条件是两个结果集没有重复数据。

5. 灵活使用in、exists

   对于以下两条SQL语句：

   ```
   select * from A where id in (select id from B);
   ```

   ```
   select * from A where exists (select 1 from B where A.id=B.id);
   ```

   - IN()只执行一次，它查出B表中的所有id字段并缓存起来。之后，检查A表的id是否与B表中的id相等，如果相等则将A表的记录加入结果集中，直到遍历完A表的所有记录。
   - exists()会执行A.length次，它并不缓存exists()结果集，因为exists()结果集的内容并不重要，重要的是其内查询语句的结果集空或者非空，空则返回false，非空则返回true。
   - 所以当A表比B表大时，IN效率更优，反之exists更优
