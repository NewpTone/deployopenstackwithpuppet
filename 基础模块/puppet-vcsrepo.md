# puppet-vcsrepo

1. [先睹为快－使用用例](#先睹为快)
2. [小结](#小结) 
3. [动手练习](#动手练习)

puppet-vcsrepo模块的目的是提供了一种使用Puppet的方式来用户的管理版本控制系统(VCS)。  
**注1** `vcsrepo`并不会主动安装任何的vcs软件，因此在使用该模块前需要完成VCS的安装。    
**注2** `git`是puppet官方唯一支持的vcs provider


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


- 指定Branch名称:
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
