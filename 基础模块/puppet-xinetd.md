# puppet-xinetd
1. [看啥看 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理xineted服务？](#核心代码讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 30分钟**
## 看啥看
puppet-xinetd 由puppetlabs开发，此模块可管理xinetd(超级进程管理器....)。咱们还是用一句话来了解这货儿。xinetd即extended internet daemon，xinetd是新一代的网络守护进程服务程序，又叫超级Internet服务器。经常用来管理多种轻量级Internet服务。xinetd提供类似于inetd+tcp_wrapper的功能，但是更加强大和安全。那么我来撸起你袖子来搞：
```puppet
  puppet apply -e "class { 'xinetd': }"
```


## 核心代码讲解
###Class xinetd
####软件包管理
```puppet

```

###Class:
####服务管理
```puppet
```


## 小结

## 动手练习