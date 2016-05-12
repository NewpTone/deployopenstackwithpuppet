# puppet-horizon

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理keystone服务？](#核心代码讲解)
    - [class keystone](###class keystone)
    - [class keystone::service](###class keystone::service)
    - [class keystone::endpoint](###class keystone::endpoint)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)


这是轻松又欢快的一章，因为这章特别容易。
puppet-horizon是用来配置和管理horzion服务，包括软件包，配置文件和服务，其中horizon将运行在Apache上。