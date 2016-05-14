# puppet-rsync

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理rsync服务？](#核心代码讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 30分钟**
## 先睹为快
puppet-rsync由puppetlabs开发，此模块可管理rsync的客户端、服务器，并且通过provider自定义define轻松获取远程服务器的数据。学习本模块前咱们先快刀斩乱马（rsync），在命令行执行如下命令:

```puppet
  puppet apply -e "class { 'rsync': }"
```
fine，有木有很too simple？既然这样，我们需要知道它是如何实现的。so...

## 核心代码讲解
#Class: rsync
#软件包管理
```puppet
class rsync(
  $package_ensure    = 'installed',
  $manage_package    = true,
  $puts              = {},
  $gets              = {},
) {

  if $manage_package {
    package { 'rsync':
      ensure => $package_ensure,
    } -> Rsync::Get<| |>
  }

  create_resources(rsync::put, $puts)
  create_resources(rsync::get, $gets)
}
```

## 小结

## 动手练习