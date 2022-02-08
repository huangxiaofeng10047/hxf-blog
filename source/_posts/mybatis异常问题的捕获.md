---
title: mybatis异常问题的捕获
date: 2021-08-24 15:23:24
tags: 
  - java 
  - mybatis
categories: 
- mybatis
---

今天定位问题定时任务不运行，通过远程debug 发现是异常没有被捕获，

MybatisMapperProxy  这个类会有异常抛出

<!--more-->

先来看看MybatisMapperProxy  代码：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210824153342299.png" alt="image-20210824153342299" style="zoom:80%;" />

其中出现的throwable代表可能会抛出异常，所以这个异常需要处理，所以我们在处理代码的时候，也要考虑异常的处理方式。

但是日志并有打印出来，造成排查问题无法迅速，这就引入了一个思考，我们的代码，要控制异常处理，针对异常的场景该有警觉

原有代码长这样：

![image-20210824152818184](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210824152818184.png)

左边是之前的代码，异常范围只是IOExeception 右边是变更后的代码，这个异常范围太窄，带了的问题，就是异常无法被捕获，这就造成了，定位问题困难。

带来的思考

Java异常处理中有throw开头的三兄弟，分别是throw,throws以及Throwable，那么他们之间到底怎么区分呢，且听我慢慢道来。

#### Throwable

Throwable是一个类，该类被异常类Exception以及错误类Error继承，其主要结构如下：

Throwable  
       |-- Error 严重错误，如栈溢出，内存溢出等  
       |-- Exception  
            |- - CheckedException 可查异常，若不加处理，编译不通过  
            |- - RuntimeException 运行时异常，可以进行编译

Java异常分为两种，一种是可查异常，即必须通过处理才能够进行编译，如FileNotFoundException等；另外一种是运行时异常，可以不用对其进行处理就能够编译，例如数组下标越界、除0等异常。

因此，Throwable作为所有异常的超类，在不知道发生何种异常的时候，可以直接使用Throwable来代替Exception或者各种具体的异常类。

#### throws

throws的作用是在方法声明的后面指明该方法可能会抛出异常（并不一定真的会出现异常）。如果在执行这个方法时出现异常，那么这个方法就不再执行了，而是抛出一个异常，把这个异常抛给调用他的方法，并且让调用他的那个方法去处理。

结合一段代码进行分析：

```
public static void method1() {
try {
method2();
}catch(Exception e) {
System.out.println("failed");
}
}

public static void method2() throws FileNotFoundException{
File f = new File("1.txt");
System.out.println("试图打开文件");
new FileInputStream(f);
System.out.println("打开文件成功");
}

public static void main(String[] args) {

method1();
}
```

根据上面的代码，在定义method2时，通过throws指明该方法可能会抛出FileNotFoundException异常。首先main函数调用method1，method1调用method2，而method2中文件f并不存在，因此在new FileInputStream(f)这行代码抛出异常，method2终止，并把这个抛出的异常甩锅给method1 。而此时，method1刚好可以catch住这个异常，异常就被处理掉了，得到的结果如下：  
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191019095213839.png)

#### throw

与throws不同，throw是一定会抛出一个异常，而且是在方法体内部使用。之前所说的异常类对象，都是JVM自动进行实例化的；有时候用户想要亲自实例化异常类对象，那么这个时候throw就登场了。先看一段代码：

```
public static void main(String[] args) {

try {
throw new FileNotFoundException();
}catch(Throwable e){
System.out.println("File not found");
}
}
```

该代码比较简单，在catch中通过throw，直接实例化了一个异常类FileNotFoundException的对象，通过catch接住，并进行输出，得到的结果如下：  
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191019100030627.png)

### 总结

Throwable是所有异常类的超类，Exception和Error两个类直接继承它；

throws写在方法声明的后面，表明这个方法可能会抛出某种异常；

throw写在方法体内部，手动抛出一个异常。

