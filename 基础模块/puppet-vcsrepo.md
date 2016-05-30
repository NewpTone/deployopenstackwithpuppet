# puppet-vcsrepo

1. [先睹为快－使用用例](#先睹为快)
2. [动手练习](#动手练习)

**本节作者：余兴超**    
**建议阅读时间 30分钟**

puppet-vcsrepo模块的目的是提供了一种使用Puppet的方式来用户的管理版本控制系统(VCS)，如:git,svn,cvs,bazaar等。 
**注1** `vcsrepo`并不会主动安装任何的vcs软件，因此在使用该模块前需要完成VCS的安装。    
**注2** `git`是puppet公司官方支持的vcs provider

# 先睹为快

## Git

例1: 创建和管理一个空的文件：
```puppet
vcsrepo { '/path/to/repo':
  ensure   => present,
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
### via SSH

若要使用SSH方式连接到源码仓库，推荐使用Puppet来管理SSH密钥，并使用[`require`](http://docs.puppetlabs.com/references/stable/metaparameter.html#require)元参数来确保它们间的执行顺序。

例7：使用指定用户的key clone repo：

```puppet
csrepo { '/path/to/repo':
  ensure     => latest,
  provider   => git,
  source     => 'git://username@example.com/repo.git',
  user       => 'toto', #uses toto's $HOME/.ssh setup
  require    => File['/home/toto/.ssh/id_rsa'],
}
```

## Git支持的特性和参数

Features: `bare_repositories`, `depth`, `multiple_remotes`, `reference_tracking`, `ssh_identity`, `submodules`, `user`

Parameters: `depth`, `ensure`, `excludes`, `force`, `group`, `identity`, `owner`, `path`, `provider`, `remote`, `revision`, `source`, `user`

## 动手练习
1.使用`vcsrepo`管理nova源码仓库，并使用stable/mitaka分支
2.使用`vcsrepo`管理一个带有submodule的项目，并指定管理submodule