# `puppet-vcsrepo`模块

1. [先睹为快](##1.先睹为快)
2. [使用示例](##2.使用示例)
3. [动手练习](##3.动手练习)

`puppet-vcsrepo`是由Puppet公司维护的官方模块,提供了管理版本控制系统(VCS)的能力，如:git,svn,cvs,bazaar等。 
`puppet-vcsrepo`项目地址：https://github.com/puppetlabs/puppetlabs-vcsrepo

**注1** `vcsrepo`并不会主动安装任何的vcs软件，因此在使用该模块前需要完成VCS的安装。    
**注2** `git`是Puppet公司唯一官方支持的vcs provider

## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！

创建一个git.pp文件并输入：
```puppet
vcsrepo { '/tmp/git_repo':
  ensure   => present,
  provider => git,
}
```
打开虚拟机终端并输入以下命令：
```
$ puppet apply -v git.pp
```
该命令将会创建一个git仓库，其路径是'/tmp/git_repo'。

## 2.使用示例

`puppet-vcsrepo`模块除了自定义资源类型vcsrepo以外，并没有任何manfests代码。因此，本节主要介绍使用vcsrepo来管理git仓库。

例1: 创建和管理一个空的git bare仓库：
```puppet
vcsrepo { '/path/to/repo':
  ensure   => bare,
  provider => git,
}
```

例2：clone/pull一个repo：

```puppet
vcsrepo { '/path/to/repo':
  ensure   => present,
  provider => git,
  source   => 'git://example.com/repo.git',
}
```

例3：指定branch或tag： 

注3：默认`vcsrepo`会使用源仓库master分支的HEAD。若要使用其他分支或指定的commit，可以设置`revision`来指定branch名称或commit SHA值或者tag号


- 指定Branch:
```puppet
vcsrepo { '/path/to/repo':
  ensure   => present,
  provider => git,
  source   => 'git://example.com/repo.git',
  revision => 'development',
}
```
- 指定SHA：
```puppet
vcsrepo { '/path/to/repo':
  ensure   => present,
  provider => git,
  source   => 'git://example.com/repo.git',
  revision => '0c466b8a5a45f6cd7de82c08df2fb4ce1e920a31',
}
```
- 指定tag：
```puppet
vcsrepo { '/path/to/repo':
  ensure   => present,
  provider => git,
  source   => 'git://example.com/repo.git',
  revision => '1.1.2rc1',
}
```

例4：保持repo为最新代码：

```puppet
vcsrepo { '/path/to/repo':
  ensure   => latest,
  provider => git,
  source   => 'git://example.com/repo.git',
  revision => 'master',
}
```

例5：clone repo，但是跳过初始化submodule:

```puppet
vcsrepo { '/path/to/repo':
  ensure     => latest,
  provider   => git,
  source     => 'git://example.com/repo.git',
  submodules => false,
}
```

例6：设置多个source，必须指定明确的remote：
```puppet
vcsrepo { '/path/to/repo':
  ensure   => present,
  provider => git,
  remote   => 'origin'
  source   => {
    'origin'       => 'https://github.com/puppetlabs/puppetlabs-vcsrepo.git',
    'other_remote' => 'https://github.com/other_user/puppetlabs-vcsrepo.git'
  },
}
```

例7：使用指定用户的SSH密钥来clone repo：

若要使用SSH方式连接到源码仓库，推荐使用Puppet来管理SSH密钥，并使用[`require`](http://docs.puppetlabs.com/references/stable/metaparameter.html#require)元参数来确保它们间的执行顺序。

```puppet
csrepo { '/path/to/repo':
  ensure     => latest,
  provider   => git,
  source     => 'git://username@example.com/repo.git',
  user       => 'toto', #uses toto's $HOME/.ssh setup
  require    => File['/home/toto/.ssh/id_rsa'],
}
```

### 2.1 Git支持的特性和参数

特性: 
 - `bare_repositories`
 -  `depth`
 -  `multiple_remotes`
 -  `reference_tracking`
 -  `ssh_identity`
 -  `submodules`
 -  `user`

参数: 
 - `depth` 
 - `ensure`
 - `excludes`
 - `force` 
 - `group` 
 - `identity`
 - `owner`
 - `path` 
 - `provider` 
 - `remote` 
 - `revision` 
 - `source`
 - `user`

## 3.动手练习

1.使用`vcsrepo`管理nova源码仓库，并使用stable/ocata分支   
2.使用`vcsrepo`管理一个带有submodule的项目，并指定管理submodule
