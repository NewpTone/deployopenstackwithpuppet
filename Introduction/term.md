# 术语表

| 名称 | 说明 |
| -- | -- |
| facter | 用于获取系统变量的组件 |
| puppet | 当出现在终端时，表示puppet软件的命令行工具；当出现在文中时，可能表示puppet软件，或者puppet client端 |
| resource | puppet中的资源单位，你可以认为它与“Linux中一切皆file“这句话对等 |
| class | puppet中resource的集合，与面向对象中的类无关 |
| define | puppet中resource的集合，与编程语言中的函数定义无关  |
| module | puppet中class和define的集合，与服务紧密相关，例如puppet-apache，专门管理apache所有相关配置 |
| transformation layer | 转发层，你可以理解为对class和define的调用层 |
| manifests | puppet代码的文件夹路径 |
| node definition | 节点定义文件 |
| hiera   |  数据文件，用于存放puppet的变量赋值  |
