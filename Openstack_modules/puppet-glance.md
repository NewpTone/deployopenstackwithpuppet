# puppet-glance

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理glance服务？](#核心代码讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 1小时**
## 先睹为快
学习本章前，先“触（kai）摸(you)”一下神秘模块glance软件部署资源环节，这只是冰山的一角，更多的冰山请继续阅读核心代码章节。撸起你的袖子，开始吧。
编写puppet_glance.pp
```puppet
class glance(
  $package_ensure = 'present'
) {

  include ::glance::params

  file { '/etc/glance/':
    ensure => directory,
    owner  => 'glance',
    group  => 'root',
    mode   => '0770',
  }

  if ( $glance::params::api_package_name == $glance::params::registry_package_name ) {
    package { $::glance::params::api_package_name :
      ensure => $package_ensure,
      name   => $::glance::params::api_package_name,
      tag    => ['openstack', 'glance-package'],
    }
  }

  ensure_resource('package', 'python-openstackclient', {'ensure' => $package_ensure, tag => 'openstack'})
}
```


## 核心代码讲解

## 小结

## 动手练习