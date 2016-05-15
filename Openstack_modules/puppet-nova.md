# puppet-nova 模块介绍
1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理keystone服务？](#核心代码讲解)
    - [class keystone](###class keystone)
    - [class keystone::service](###class keystone::service)
    - [class keystone::endpoint](###class keystone::endpoint)
    - [define keystone::resource::service_identity](###define  keystone::resource::service_identity)
    - [class keystone::config](###class keystone::config) 
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 1.5h**

puppet-keystone是用来配置和管理keystone服务，包括服务，软件包，keystone user，role，service，endpoint等等。其中 keystone user, role, service, endpoint等资源的管理是使用自定义的resource type来实现。


