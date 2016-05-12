# puppet-openstacklib
在部署一个 OpenStack 集群时，我们可能需要安装多个 OpenStack 项目，由于 OpenStack 项目都是按照类似的设计模式开发的，因此这些不同的服务的架构都具有某些共同的特点，例如每个服务一般都会有一个专用的数据库，都会使用消息队列来完成内部组件通信，一般都由 Python 开发，可以使用 WSGI 的方式进行部署等等...

由于这些服务的共同特性，在部署 OpenStack 服务时，我们的很多操作往往需要重复进行，例如为每个服务创建数据库，以及数据库的用户和访问权限，这些操作可能存在于每个服务对应的 Puppet 模块中，为了尽可能的减少重复性代码，社区将一些常用的通用性操作写成 Puppet 中的 define 并放在一个公共模块中供其他模块使用，这样其他模块只需要调用这个公共模块中定义好 define 资源即可。这个公共模块就是 `puppet-oepnstacklib`，它的作用类似于软件开发中的公共类库。

`puppet-openstacklib` 主要提供了下面这些 define 资源：
* `openstacklib::service_validation`，用于执行脚本或命令对服务可用性进行验证
* `openstacklib::db::mysql`，用于完成数据库，数据库用户的创建和用户的授权
* `openstacklib::policy::base`，用于配置 policy.json 文件
