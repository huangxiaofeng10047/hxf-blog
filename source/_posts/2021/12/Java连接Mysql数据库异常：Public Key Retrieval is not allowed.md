## [Java连接Mysql数据库异常：Public Key Retrieval is not allowed](https://www.cnblogs.com/YuyuanNo1/p/13738228.html)

本文主要介绍通过connector 8.0.11连接Mysql数据库，出现Public Key Retrieval is not allowed(Exception in thread “main”java.sql.SQLNonTransientConnectionException: Public Key Retrieval is not allowed)的异常信息的解决方法。

堆栈跟踪：

Exception in thread "main" java.sql.SQLNonTransientConnectionException: Public Key Retrieval is not allowed at com.mysql.cj.jdbc.exceptions.SQLError.createSQLException(SQLError.java:108) at com.mysql.cj.jdbc.exceptions.SQLError.createSQLException(SQLError.java:95) at com.mysql.cj.jdbc.exceptions.SQLExceptionsMapping.translateException(SQLExceptionsMapping.java:122) at 
 com.mysql.cj.jdbc.ConnectionImpl.createNewIO(ConnectionImpl.java:862) at com.mysql.cj.jdbc.ConnectionImpl.(ConnectionImpl.java:444) at com.mysql.cj.jdbc.ConnectionImpl.getInstance(ConnectionImpl.java:230) at com.mysql.cj.jdbc.NonRegisteringDriver.connect(NonRegisteringDriver.java:226) at com.mysql.cj.jdbc.MysqlDataSource.getConnection(MysqlDataSource.java:438) at com.mysql.cj.jdbc.MysqlDataSource.getConnection(MysqlDataSource.java:146) at com.mysql.cj.jdbc.MysqlDataSource.getConnection(MysqlDataSource.java:119) at ConnectionManager.getConnection(ConnectionManager.java:28) at Main.main(Main.java:8)

连接代码：

public class ConnectionManager {

    public static final String serverTimeZone = "UTC";
    public static final String serverName = "localhost";
    public static final String databaseName ="mysqldb";
    public static final int portNumber = 3306;
    public static final String user = "anyroot";
    public static final String password = "anyroot";
    
    public static Connection getConnection() throws SQLException {
    
        MysqlDataSource dataSource = new MysqlDataSource();
    
        dataSource.setUseSSL( false );
        dataSource.setServerTimezone( serverTimeZone );
        dataSource.setServerName( serverName );
        dataSource.setDatabaseName( databaseName );
        dataSource.setPortNumber( portNumber );
        dataSource.setUser( user );
        dataSource.setPassword( password );
    
        return dataSource.getConnection();
    }
}

解决异常问题

解决此异常问题需要将`allowPublicKeyRetrieval=true`和`useSSL=false`。

1）通过代码设置

dataSource.setAllowPublicKeyRetrieval(true);  
dataSource.setUseSSL(false);

2）jdbc的url设置

jdbc:mysql://localhost:3306/Database\_dbName?allowPublicKeyRetrieval=true&useSSL=false;

3）Spring boot配置

spring.datasource.url=jdbc:mysql://localhost:3306/db-name?useUnicode=true&characterEncoding=UTF-8&allowPublicKeyRetrieval=true&useSSL=false
spring.datasource.username=root
spring.datasource.password=root

不积跬步无以至千里，不积小流无以成江海

posted on 2020-09-27 10:59  [小甜瓜安东泥](https://www.cnblogs.com/YuyuanNo1/)  阅读(4522)  评论()  [编辑](https://i.cnblogs.com/EditPosts.aspx?postid=13738228)  收藏  举报