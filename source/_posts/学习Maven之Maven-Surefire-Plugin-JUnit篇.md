---
title: 学习Maven之Maven Surefire Plugin(JUnit篇)
date: 2021-07-14 10:58:37
tags:
---
# 学习Maven之Maven Surefire Plugin(JUnit篇)
maven的生命周期有哪些阶段？

[validate, initialize, generate-sources, process-sources, generate-resources, process-resources, compile, process-classes, generate-test-sources, process-test-sources, generate-test-resources, process-test-resources, test-compile, process-test-classes, test, prepare-package, package, pre-integration-test, integration-test, post-integration-test, verify, install, deploy]
< !-- more -->
当然，如果你明确用的是JUnit4.7及以上版本，可以明确声明：
```
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-surefire-plugin</artifactId>
	<version>2.19</version>
	<dependencies>
		<dependency>
			<groupId>org.apache.maven.surefire</groupId>
			<artifactId>surefire-junit47</artifactId>
			<version>2.19</version>
		</dependency>
	</dependencies>
</plugin>
```
JUnit4.0(含)到JUnit4.7(不含)的版本，这样声明:
```
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-surefire-plugin</artifactId>
	<version>2.19</version>
	<dependencies>
		<dependency>
			<groupId>org.apache.maven.surefire</groupId>
			<artifactId>surefire-junit4</artifactId>
			<version>2.19</version>
		</dependency>
	</dependencies>
</plugin>
```
JUnit3.8(含)到JUnit4.0(不含)的版本，这样声明:
```
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-surefire-plugin</artifactId>
	<version>2.19</version>
	<dependencies>
		<dependency>
			<groupId>org.apache.maven.surefire</groupId>
			<artifactId>surefire-junit3</artifactId>
			<version>2.19</version>
		</dependency>
	</dependencies>
</plugin>
```
JUnit3.8以下的版本surefire不支持。建议大家用最新的JUnit版本，目前是4.12.
```
<dependencies>
	[...]
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.12</version>
        <scope>test</scope>
    </dependency>
	[...]        
</dependencies>
```
本文的例子我们用的Junit4.12.
本项目中：
```pom
 <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>2.22.1</version>
                <configuration>
                    <forkCount>1</forkCount>
                    <reuseForks>false</reuseForks>
                    <testFailureIgnore>true</testFailureIgnore>
                    <skipTests>false</skipTests>
                </configuration>
            </plugin>
```
dependency
```
 <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
            <exclusions>
                <exclusion>
                    <artifactId>mockito-core</artifactId>
                    <groupId>org.mockito</groupId>
                </exclusion>
                <exclusion>
                    <artifactId>junit</artifactId>
                    <groupId>junit</groupId>
                </exclusion>
            </exclusions>
        </dependency>
```
在spring-boot-starter-test中用的JUnit Jupiter        
Junit Jupiter是junit5
JUnit with Gradle
代码地址为
https://github.com/makotogo/HelloJUnit5
导入idea中会出现
“Cannot add task 'wrapper' as a task with that name already exists.”
这是因为gradle版本所致，修改文件
```

// 旧版本是:
task wrapper(type:Wrapper) {
    //configuration
}
 
// 新版本是：
wrapper {
    //configuration

```
运行gradle test报错
IDEA报错：Process ‘command ‘./Java/jdk1.8.0_131/bin/java.exe‘‘ finished with non-zero exit value 1 解决！
解决办法：
设置idea-》settings-》gradle 
设置run test using “intelij idea”