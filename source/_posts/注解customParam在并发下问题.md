---
title: 注解customParam在并发下问题
date: 2021-08-03 09:59:35
tags: 注解 customParam
---

IPH中引入自定义customParam参数

customParam在并发情况下，会出现报错，



![image-20210803101609700](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210803101609700.png)

报错代码在

![image-20210803101710426](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210803101710426.png)

该原因是因为value在并发情况下为空，分析问题，原因为param不因作为类的私有变量，在并发情况下map不安全，需要吧map作为局部变量使用，当改为局部变量，该问题解决。

代码类位置为CustomMethodArgumentResolver

![image-20210803102111316](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210803102111316.png)

第二个问题，customParam是作为单个参数接收的，当改为局部变量，做login接口变为customParam来接受username和password，则会报错，因为customParam会两次经过customHandler来处理，所以需要改写requestBody来接受用户名和密码，

![image-20210803102651718](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210803102651718.png)

![image-20210803102616035](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210803102616035.png

![image-20210803102239469](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210803102239469.png)

customParam推荐接收单个参数，多个参数使用bean来接受

需要大家检测自身代码问题，

针对于requestbody这种修改方式，综合考虑成本比较大，涉及到之前的很多接口，需要重新考虑该接口如何实现，

通过分析，发现多个customParam注解为什么会不成功，是因为getrequestbody只能获取一次，多个参数时，获取不到，那么解决办法，需要保证能多次从requestbody中获取数据。

我们先来看看为什么HttpServletRequest的输入流只能读一次，当我们调用`getInputStream()`方法获取输入流时得到的是一个InputStream对象，而实际类型是ServletInputStream，它继承于InputStream。

InputStream的`read()`方法内部有一个postion，标志当前流被读取到的位置，每读取一次，该标志就会移动一次，如果读到最后，`read()`会返回-1，表示已经读取完了。如果想要重新读取则需要调用`reset()`方法，position就会移动到上次调用mark的位置，mark默认是0，所以就能从头再读了。调用`reset()`方法的前提是已经重写了`reset()`方法，当然能否reset也是有条件的，它取决于`markSupported()`方法是否返回true。

InputStream默认不实现`reset()`，并且`markSupported()`默认也是返回false，这一点查看其源码便知：

我们再来看看ServletInputStream，可以看到该类没有重写`mark()`，`reset()`以及`markSupported()`方法：

综上，InputStream默认不实现reset的相关方法，而ServletInputStream也没有重写reset的相关方法，这样就无法重复读取流，这就是我们从request对象中获取的输入流就只能读取一次的原因。

### 使用HttpServletRequestWrapper + Filter解决输入流不能重复读取问题

既然ServletInputStream不支持重新读写，那么为什么不把流读出来后用容器存储起来，后面就可以多次利用了。那么问题就来了，要如何存储这个流呢？

所幸JavaEE提供了一个 HttpServletRequestWrapper类，从类名也可以知道它是一个http请求包装器，其基于装饰者模式实现了HttpServletRequest界面，部分源码如下：

![image-20210804101044518](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210804101044518.png)

从上图中的部分源码可以看到，该类并没有真正去实现HttpServletRequest的方法，而只是在方法内又去调用HttpServletRequest的方法，所以我们可以通过继承该类并实现想要重新定义的方法以达到包装原生HttpServletRequest对象的目的。

首先我们要定义一个容器，将输入流里面的数据存储到这个容器里，这个容器可以是数组或集合。然后我们重写getInputStream方法，每次都从这个容器里读数据，这样我们的输入流就可以读取任意次了。

具体的实现代码如下：

```


import lombok.extern.slf4j.Slf4j;

import javax.servlet.ReadListener;
import javax.servlet.ServletInputStream;
import javax.servlet.ServletRequest;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import java.io.*;
import java.nio.charset.Charset;

@Slf4j
public class RequestWrapper extends HttpServletRequestWrapper {
    /**
     * 存储body数据的容器
     */
    private final byte[] body;

    public RequestWrapper(HttpServletRequest request) throws IOException {
        super(request);

        // 将body数据存储起来
        String bodyStr = getBodyString(request);
        body = bodyStr.getBytes(Charset.defaultCharset());
    }

    /**
     * 获取请求Body
     *
     * @param request request
     * @return String
     */
    public String getBodyString(final ServletRequest request) {
        try {
            return inputStream2String(request.getInputStream());
        } catch (IOException e) {
            log.error("", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * 获取请求Body
     *
     * @return String
     */
    public String getBodyString() {
        final InputStream inputStream = new ByteArrayInputStream(body);

        return inputStream2String(inputStream);
    }

    /**
     * 将inputStream里的数据读取出来并转换成字符串
     *
     * @param inputStream inputStream
     * @return String
     */
    private String inputStream2String(InputStream inputStream) {
        StringBuilder sb = new StringBuilder();
        BufferedReader reader = null;

        try {
            reader = new BufferedReader(new InputStreamReader(inputStream, Charset.defaultCharset()));
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        } catch (IOException e) {
            log.error("", e);
            throw new RuntimeException(e);
        } finally {
            if (reader != null) {
                try {
                    reader.close();
                } catch (IOException e) {
                    log.error("", e);
                }
            }
        }

        return sb.toString();
    }

    @Override
    public BufferedReader getReader() throws IOException {
        return new BufferedReader(new InputStreamReader(getInputStream()));
    }

    @Override
    public ServletInputStream getInputStream() throws IOException {

        final ByteArrayInputStream inputStream = new ByteArrayInputStream(body);

        return new ServletInputStream() {
            @Override
            public int read() throws IOException {
                return inputStream.read();
            }

            @Override
            public boolean isFinished() {
                return false;
            }

            @Override
            public boolean isReady() {
                return false;
            }

            @Override
            public void setReadListener(ReadListener readListener) {
            }
        };
    }
}

```

除了要写一个包装器外，我们还需要在过滤器里将原生的HttpServletRequest对象替换成我们的RequestWrapper对象，代码如下：

```


import lombok.extern.slf4j.Slf4j;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import java.io.IOException;

@Slf4j
public class ReplaceStreamFilter implements Filter {
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        log.info("StreamFilter初始化...");
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        ServletRequest requestWrapper = new RequestWrapper((HttpServletRequest) request);
        chain.doFilter(requestWrapper, response);
    }

    @Override
    public void destroy() {
        log.info("StreamFilter销毁...");
    }
}

```

从而我们在customParam中使用requestbody就没有问题了

![image-20210804101807196](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210804101807196.png)

```
private String getRequestBody(HttpServletRequest servletRequest)  {
        String jsonParam = null;
        try {
            jsonParam = new RequestWrapper(servletRequest).getBodyString();
        } catch (IOException e) {
            log.error("读取流异常", e);
            throw new BizException(ErrorCodeConstant.SERVER_INTERNAL_ERROR,"IO异常");
        }
        log.info("[preHandle] json数据 : {}", jsonParam);
        return jsonParam;
    }
```

编写完以上的代码后，还需要将过滤器在配置类中进行注册才会生效，过滤器配置类代码如下：

![image-20210804102053267](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210804102053267.png)

```
   /**
     * 实例化StreamFilter
     *
     * @return Filter
     */
    @Bean(name = "replaceStreamFilter")
    public Filter replaceStreamFilter() {
        return new ReplaceStreamFilter();
    }
```

经过以上配置，就可以正常使用@customParam在多参数下。

