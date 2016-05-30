# puppet-vcsrepo

1. [先睹为快－一言不和，立马动手?](#先睹为快)
2. [核心代码－如何管理apache服务](＃核心代码讲解)
3. [小结](#小结) 
4. [动手练习](#动手练习)

puppet-vcsrepo模块的目的是提供了一种使用Puppet的方式来用户的管理版本控制系统(VCS)。  
**注1** `vcsrepo`并不会主动安装任何的vcs软件，因此在使用该模块前需要完成VCS的安装。    
**注2** `git`是puppet官方唯一支持的vcs provider


