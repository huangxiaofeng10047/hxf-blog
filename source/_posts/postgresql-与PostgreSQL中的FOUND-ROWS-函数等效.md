---
title: postgresql - 与PostgreSQL中的FOUND_ROWS()函数等效
date: 2021-08-12 08:37:02
tags: postgres mysql found_rows()
---

我正在应用程序中进行一些分页，使用PostgreSQL的标准OFFSET和LIMIT关键字一次从数据库返回20行。例如，要获得第1页:

```
SELECT stuff FROM table WHERE condition ORDER BY stuff OFFSET 0 LIMIT 20
```



这也是应用程序的要求，我们还向用户显示记录总数。因此，显然，我可以通过发出一个单独的查询来获得总数:

```
SELECT COUNT(*) FROM table WHERE condition
```

<!--more-->
但是，如果有很多行，那么这不是最佳解决方案。我注意到MySQL具有一个非常有用的函数FOUND_ROWS()，它确实可以满足我的需求:

[http://dev.mysql.com/doc/refman/5.0/en/information-functions.html#function%5Ffound-rows](http://dev.mysql.com/doc/refman/5.0/en/information-functions.html#function_found-rows)

PostgreSQL中有等效的东西吗？



# 最佳答案

PostgreSQL已经有[window functions](http://www.postgresql.org/docs/current/interactive/tutorial-window.html)一段时间了，它可以用来做很多事情，包括在应用LIMIT之前对行进行计数。

根据以上示例:

```
SELECT stuff,
       count(*) OVER() AS total_count
FROM table
WHERE condition
ORDER BY stuff OFFSET 40 LIMIT 20
```



关于postgresql - 与PostgreSQL中的FOUND_ROWS()函数等效，我们在Stack Overflow上找到一个类似的问题： https://stackoverflow.com/questions/3984643/

# 但在postgresql测试性能并没有达到很大，建议分开执行。参考原则为以下：

# Re: SQL_CALC_FOUND_ROWS equivalent in PostgreSQL

| From:       | Oliver Elphick <olly(at)lfix(dot)co(dot)uk>                  |
| ----------- | ------------------------------------------------------------ |
| To:         | "Matt Arnilo S(dot) Baluyos (Mailing Lists)" <matt(dot)baluyos(dot)lists(at)gmail(dot)com> |
| Cc:         | pgsql-novice(at)postgresql(dot)org                           |
| Subject:    | Re: SQL_CALC_FOUND_ROWS equivalent in PostgreSQL             |
| Date:       | 2007-07-31 06:24:34                                          |
| Message-ID: | [1185863074.10580.91.camel@linda.lfix.co.uk](https://www.postgresql.org/message-id/1185863074.10580.91.camel%40linda.lfix.co.uk) |
| Views:      | [Raw Message](https://www.postgresql.org/message-id/raw/1185863074.10580.91.camel%40linda.lfix.co.uk) \| [Whole Thread](https://www.postgresql.org/message-id/flat/1185863074.10580.91.camel%40linda.lfix.co.uk) \| [Download mbox](https://www.postgresql.org/message-id/mbox/1185863074.10580.91.camel%40linda.lfix.co.uk) \| [Resend email](https://www.postgresql.org/message-id/resend/1185863074.10580.91.camel%40linda.lfix.co.uk) |
| Thread:     | 2007-07-31 01:22:25 from "Matt Arnilo S(dot) Baluyos (Mailing Lists)" <matt(dot)baluyos(dot)lists(at)gmail(dot)com>  2007-07-31 06:24:34 from Oliver Elphick <olly(at)lfix(dot)co(dot)uk>   2007-07-31 14:32:16 from Michael Fuhr <mike(at)fuhr(dot)org> |
| Lists:      | [pgsql-novice](https://www.postgresql.org/list/pgsql-novice/since/200707310624) |

On Tue, 2007-07-31 at 09:22 +0800, Matt Arnilo S. Baluyos (Mailing
Lists) wrote:
\> Hello everyone,
\> 
\> I would like to use PostgreSQL with the SmartyPaginate plugin of the
\> Smarty template engine.
\> 
\> In the examples on the documentation, the following two queries are used:
\> 
\> SELECT SQL_CALC_FOUND_ROWS * FROM mytable LIMIT X,Y
\> SELECT FOUND_ROWS() as total
\> 
\> What the SQL_CALC_FOUND_ROWS does is that it allows the FOUND_ROWS()
\> function to return the total rows if the first query didn't have the
\> LIMIT.
\> 
SQL_CALC_FOUND_ROWS and FOUND_ROWS() are MySQL features.

\> Is there an equivalent function in PostgreSQL for this or perhaps a
\> workaround?

There is no equivalent.  Use

   BEGIN;
   SELECT * FROM mytable OFFSET X LIMIT Y;
   SELECT COUNT(*) AS total FROM mytable;
   END;

(To ensure consistent results, both queries should be done in a single
transaction.)

If you are repeating the query multiple times for separate pages, it
would be more efficient to do the COUNT() selection first and not repeat
it for each page.  You could use a cursor to go back and forth through
the results while doing the query only once.

\-- 
Oliver Elphick                                          olly(at)lfix(dot)co(dot)uk
Isle of Wight                              http://www.lfix.co.uk/oliver
GPG: 1024D/A54310EA  92C8 39E7 280E 3631 3F0E  1EC0 5664 7A2F A543 10EA
                 ========================================
   Do you want to know God?   http://www.lfix.co.uk/knowing_god.html

\-- 
This message has been scanned for viruses and
dangerous content by MailScanner, and is
believed to be clean.





### In response to

- [SQL_CALC_FOUND_ROWS equivalent in PostgreSQL](https://www.postgresql.org/message-id/d1a6d7930707301822geda34b2i1e558ccd84ca9513%40mail.gmail.com) at 2007-07-31 01:22:25 from Matt Arnilo S. Baluyos (Mailing Lists)

### Responses

- [Re: SQL_CALC_FOUND_ROWS equivalent in PostgreSQL](https://www.postgresql.org/message-id/20070731143216.GA28226%40winnie.fuhr.org) at 2007-07-31 14:32:16 from Michael Fuhr

### Browse pgsql-novice by date

[postgresql found_rows性能并不好]: https://www.postgresql.org/message-id/1185863074.10580.91.camel@linda.lfix.co.uk

