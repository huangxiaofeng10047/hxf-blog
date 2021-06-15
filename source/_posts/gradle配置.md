---
title: gradle配置
date: 2021-05-10 11:32:41
tags:
---

grade配置：

在~/.gradle/目录下新建 init.gradle文件

```
allprojects{
	repositories {
		def REPOSITORY_URL = 'http://mvnrepo.alibaba-inc.com/mvn/repository/'
		all { ArtifactRepository repo ->
			if(repo instanceof MavenArtifactRepository){
				def url = repo.url.toString()
				if (url.startsWith('https://repo1.maven.org/maven2') || url.startsWith('https://jcenter.bintray.com/')) {
					project.logger.lifecycle "Repository ${repo.url} replaced by $REPOSITORY_URL."
					remove repo
				}
			}
		}
		maven {
		 //允许url改变
		 allowInsecureProtocol = true
			url REPOSITORY_URL
		}
	}
}
```

- `./gradlew idea`来初始化项目,打出以下信息说明maven地址已经修改成功了

- 牛刀小试一下

- ```
  `git clone https://github.com/elastic/elasticsearch.git`
  ```

  ./gradlew idea

