# 术语表

本书的后续章节中使用了与Puppet，Ruby，OpenStack等技术相关的术语，为了让读者更快地理解其含义，下表中给出了本书所出现的术语和释义。


| 名称 | 说明 |
| -- | -- |
| facter | 用于获取系统变量的组件 |
| puppet | 当出现在终端时，表示puppet软件的命令行工具；当出现在文中时，可能表示puppet软件，或者puppet client端 |
| resource | puppet中的资源单位，你可以认为它与“Linux中一切皆file“这句话对等 |
| class | puppet中resource的集合，与面向对象中的类无关 |
| define | puppet中resource的集合，与编程语言中的函数定义无关  |
| module | puppet中class和define的集合，与服务紧密相关，例如puppet-apache，专门管理apache所有相关配置 |
| transformation layer | 转换层，可以理解为对class和define的调用层 |
| manifests | 用于puppet代码的文件目录 |
| node definition | 节点定义文件，等价于角色定义 |
| hiera   |  数据文件，用于存放节点所有变量的赋值  |
|RVM | 安装和管理多个Ruby环境以及Ruby应用所使用的Ruby环境。|
|Rails |[Web开发框架](http://zh.wikipedia.org/wiki/Ruby_on_Rails)  |
|RubyGems| RubyGems是一个方便而强大的Ruby程序包管理器（ package manager），类似RedHat的RPM.它将一个Ruby应用程序打包到一个gem里，作为一个安装单元。无需安装，最新的Ruby版本已经包含RubyGems了|
| Gem |Gem是封装起来的Ruby应用程序或代码库。|
|Gemfile|定义你的应用依赖哪些第三方包，bundle根据该配置去寻找这些包。|
|Rake|Rake是一门构建语言，和make类似。Rake是用Ruby写的，它支持自己的DSL用来处理和维护Ruby程序。 Rails用rake扩展来完成多种不容任务，如数据库初始化、更新等。 详细 http://rake.rubyforge.org/ |
|Rakefile|[Rakefile](http://rake.rubyforge.org/files/doc/rakefile_rdoc.html)是由Ruby编写，Rake的命令执行就是由Rakefile文件定义。|
|Bundle| Bundler为Ruby应用维护了一个持久的包依赖环境。|

