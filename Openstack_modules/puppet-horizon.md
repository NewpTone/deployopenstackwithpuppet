# puppet-horizon

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理keystone服务？](#核心代码讲解)
    - [class horizon](###class horizon)
    - [class horizon::params](###class horizon::params)
    - [class horzion::wsgi::apache](###class horizon::wsgi::apache)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)


这是读者和作者都会感到轻松又欢快的一章，因为puppet-horizon模块比较简单...
回到正题，puppet-horizon模块是用来配置和管理horzion服务，包括horzion软件包，配置文件和服务的管理，horizon将运行在Apache上。

## 先睹为快

```puppet
puppet apply -e 'class {'horizon': secret_key => 'big'}'
```