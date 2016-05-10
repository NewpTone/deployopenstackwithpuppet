# 模块剖析

Openstack服务类型的module目录结构是几乎一致的，这是在反复的迭代中形成的规范，每个模块都有统一的目录结构带来的好处有两点：
1. 易于理解和管理
2. 减少冗余代码，提高代码复用

那么我们就来看看一个openstack服务类型的module其一层目录结构是怎么样的：

* examples/      放置示例代码   
* ext/           放置external代码，和主要代码无关，但是一些有用的脚本
* lib/           放置library代码，例如自定义facter,resource type
* manifests/     放置puppet代码
* releasenotes/  放置releasenote
* spec/          放置class,unit,acceptance测试
* tests/         已弃用，使用examples/ 替代
