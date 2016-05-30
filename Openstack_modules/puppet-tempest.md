# puppet-tempest

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理tempest服务？](#核心代码讲解)
    - [class tempest](#class tempest)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

Tempest是Openstack的集成测试框架，它的实现基于python的unittest2测试框架和nose测试框架。Tempest通过Openstack client发起API请求，并且对API响应结果进行验证。

## 先睹为快

我们借助puppet-openstack_integration模块的tempest.pp来完成tempest的部署：
```shell
puppet apply -e 'include openstack_integration::tempest'
```
很快我们就能完成对tempest的部署工作。

## 核心代码讲解

### class tempest

在tempest类中，和其他module不同的一点是关于如何使用源码来安装软件包的技巧。

先说说`ensure_packages`，接受列表或哈希类型的package变量并进行安装。以下为使用示例：

- Array类型:

```puppet
    ensure_packages(['ksh','openssl'], {'ensure' => 'present'})
```

- Hash类型:

```puppet
    ensure_packages({'ksh' => { enure => '20120801-1' } ,  'mypackage' => { source => '/tmp/myrpm-1.0.0.x86_64.rpm', provider => "rpm" }}, {'ensure' => 'present'})
```
**ensure_packages和package的区别** 

作用都是一样的，只是在遇到有多个软件包需安装的场景时，ensure_packages使用起来代码更加简洁。

再来看puppet如何下载tempest源码仓库，这里用到了我们在基础模块章节讲到的`vcsrepo`type：

```puppet
    if $git_clone {
      vcsrepo { $tempest_clone_path:
        ensure   => 'present',
        source   => $tempest_repo_uri,
        revision => $tempest_repo_revision,
        provider => 'git',
        require  => Package['git'],
        user     => $tempest_clone_owner,
      }
      Vcsrepo<||> -> Tempest_config<||>
    }
```
class tempest同时支持使用venv的方式安装tempest:

```puppet
    if $setup_venv {
      # virtualenv will be installed along with tox
      exec { 'setup-venv':
        command => "/usr/bin/virtualenv ${tempest_clone_path}/.venv && ${tempest_clone_path}/.venv/bin/pip install -U -r requirements.txt",
        cwd     => $tempest_clone_path,
        unless  => "/usr/bin/test -d ${tempest_clone_path}/.venv",
        require => [
          Exec['install-tox'],
          Package[$tempest::params::dev_packages],
        ],
      }
      if $git_clone {
        Vcsrepo<||> -> Exec['setup-venv']
      }
    }
```
下述的代码基本上只是使用tempest_config在完成相应服务的配置，就不再展开解释。

## 小结

在这一节中，我们了解了`ensure_packages`函数的使用，也见到`vcsrepo`是如何实现下载源码仓库的，也看到如何用Puppet实现python程序的venv安装方式。

###

1.部署tempest服务，并开启对sahara，swift的支持
2.对于当前的puppet-tempest，你觉得有什么值得改进的地方？