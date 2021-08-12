---
title: Mybatis-plus SQL性能优化（分页数据获取)
date: 2021-08-11 13:47:37
tags: mybatis 分页 
---

![image-20210811134932015](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210811134932015.png)

<!--more-->

## 特性

- **无侵入**：只做增强不做改变，引入它不会对现有工程产生影响，如丝般顺滑
- **损耗小**：启动即会自动注入基本 CURD，性能基本无损耗，直接面向对象操作
- **强大的 CRUD 操作**：内置通用 Mapper、通用 Service，仅仅通过少量配置即可实现单表大部分 CRUD 操作，更有强大的条件构造器，满足各类使用需求
- **支持 Lambda 形式调用**：通过 Lambda 表达式，方便的编写各类查询条件，无需再担心字段写错
- **支持主键自动生成**：支持多达 4 种主键策略（内含分布式唯一 ID 生成器 - Sequence），可自由配置，完美解决主键问题
- **支持 ActiveRecord 模式**：支持 ActiveRecord 形式调用，实体类只需继承 Model 类即可进行强大的 CRUD 操作
- **支持自定义全局通用操作**：支持全局通用方法注入（ Write once, use anywhere ）
- **内置代码生成器**：采用代码或者 Maven 插件可快速生成 Mapper 、 Model 、 Service 、 Controller 层代码，支持模板引擎，更有超多自定义配置等您来使用
- **内置分页插件**：基于 MyBatis 物理分页，开发者无需关心具体操作，配置好插件之后，写分页等同于普通 List 查询
- **分页插件支持多种数据库**：支持 MySQL、MariaDB、Oracle、DB2、H2、HSQL、SQLite、Postgre、SQLServer 等多种数据库
- **内置性能分析插件**：可输出 SQL 语句以及其执行时间，建议开发测试时启用该功能，能快速揪出慢查询
- **内置全局拦截插件**：提供全表 delete 、 update 操作智能分析阻断，也可自定义拦截规则，预防误操作

通过日志分析，目前mybatis获取分页的方法是执行两个sql，一个是count了，另一个是分页。查看日志方式，吧下方注释放开即可，但是日志量会陡增，生产环境不建议开启，log-impl: org.apache.ibatis.logging.stdout.StdOutImpl

![image-20210811135534008](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210811135534008.png)

**优化方向：**

那我们完全可以将这两步放到一次sql去执行获取，减少一半的查询时间。

看代码：

select SQL_CALC_FOUND_ROWS

  col_name1 as colName1,

  col_name2 as colName2

from table_name limit 0,10;

select FOUND_ROWS() as count;

在SELECT语句中加上修饰SQL_CALC_FOUND_ROWS 之后，SELECT FOUND_ROWS() 会返回满足条件记录的总数。

这样，你执行完 select SQL_CALC_FOUND_ROWS 之后，再取一下记录总数就行了。

看到没有，两个结果：第一个是分页list，第二个是总数count。接下来怎么办？

接下来我们就将相关代码放到JAVA中，可是我们会发现：在数据库中能够成功执行语句，但是放到代码中却会报错。



原来，mybatis在我们使用链接连接数据库时，需要我们手动在连接上加上代码：

&allowMultiQueries=true  //允许执行多条sql

这样，mybatis就可以成功通过多条sql语句get到多个数据集了。

那么现在问题来了：

我们在xml中如何去接收sql查询到的多数据集呢？

废话不多说，直接上代码：

```javascript
<!-- 获取学生列表数据-分页-+count数据 -->
<select id="getStudentManagePage" resultMap="StudentManageVoMap,count">
   SELECT sql_calc_found_rows 这里是字段 FROM
        tbl_student_infomation AS tsi
        LEFT JOIN tbl_college AS tco ON tsi.college_id=tco.id
        LEFT JOIN tbl_profession AS tp ON tsi.profession_id=tp.id
        LEFT JOIN tbl_class AS tcl ON tsi.class_id=tcl.id
        WHERE 1=1
        ORDER BY tcs.score DESC,tsi.is_track DESC,tsi.sno DESC limit #{offset},#{limit};
   SELECT found_rows() as count;
</select>
<!--接收count数据集-->
<resultMap type="Integer" id="count">
    <result column="count" jdbcType="INTEGER" javaType="Integer" />
</resultMap>
<!--接收分页数据集-->
<resultMap type="com.atage.entity.vo.StudentManageVo" id="StudentManageVoMap">
        <result column="sno" jdbcType="VARCHAR" property="sno" />
        <result column="name" jdbcType="VARCHAR" property="name" />
        <result column="sex" jdbcType="INTEGER" property="sex" />
        <result column="imgUrl" jdbcType="VARCHAR" property="imgUrl" />
        <result column="brithday" jdbcType="DATE" property="brithday" />
        <result column="sourcePlace" jdbcType="VARCHAR" property="sourcePlace" />
        <result column="singleton" jdbcType="INTEGER" property="singleton" />
        <result column="parentFamily" jdbcType="INTEGER" property="parentFamily" />
        <result column="enrollment" jdbcType="VARCHAR" property="enrollment" />
        <result column="collegeId" jdbcType="VARCHAR" property="collegeId" />
        <result column="professionId" jdbcType="VARCHAR" property="professionId" />
        <result column="classId" jdbcType="VARCHAR" property="classId" />
        <result column="isTrack" jdbcType="INTEGER" property="isTrack" />
        <result column="score" jdbcType="DOUBLE" property="score" />
        <result column="gradeC" jdbcType="DOUBLE" property="gradeC" />
        <result column="gradeQ" jdbcType="DOUBLE" property="gradeQ" />
        <result column="gradeId" jdbcType="VARCHAR" property="gradeId" />
        <result column="clollegeName" jdbcType="VARCHAR" property="clollegeName" />
        <result column="yearName" jdbcType="VARCHAR" property="yearName" />
        <result column="professionName" jdbcType="VARCHAR" property="professionName" />
        <result column="className" jdbcType="VARCHAR" property="className" />
        <result column="teacherId" jdbcType="VARCHAR" property="teacherId" />
    </resultMap>
```

通过分号把两个sql进行执行。

2.Mapper代码

```javascript
//接收用list<?>
List<?> getStudentManagePage(这里是传递的条件参数);
```

3.service代码

```javascript
//接收用list<?>
List<?> getStudentManagePage(这里是传递的条件参数);
```

4.serviceImpl代码

```javascript
@Override
    public List<?> getStudentManagePage(参数) {
        return tblStudentInfomationMapper.getStudentManagePage(参数);
    }
```

5.controller代码

```javascript
//这里是接收数据
List<?> list = tblStudentInfomationService.getStudentManagePage(参数);
List<StudentManageVo> studentManageVoList = new ArrayList<StudentManageVo>();
//接收分页数据
studentManageVoList = (List<StudentManageVo>)list.get(0);
//接收count数据
count = ((List<Integer>) list.get(1)).get(0);
```

好，按照以上配置，你就会发现SQL执行效率就大大提高了。

**☆重点提示**

强调下必须修改数据库连接 

1、修改数据库连接参数加上allowMultiQueries=true，如： 

```javascript
hikariConfig.security.jdbcUrl=jdbc:mysql://xx.xx.xx:3306/xxxxx?characterEncoding=utf-8&autoReconnect=true&failOverReadOnly=false&allowMultiQueries=true
```

2、直接写多条语句，用“；”隔开即可

```javascript
<delete id="deleteUserById" parameterType="String">
delete from sec_user_role where userId=#{id};
delete from sec_user where id=#{id};
</delete>
```

