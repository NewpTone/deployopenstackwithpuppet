# Puppet核心概念

在Puppet中有一些重要的概念，对于这些概念的理解，有助于读者快速掌握Puppet Modules的开发。

## Resource

在Linux中，一切皆文件(`file`)。而在Puppet中，一切皆资源(`resource`)。


比如，软件包（package)就属于一种资源(resource type)。

要在服务器上安装vim软件包，只需要声明一个package资源:


```

package {'vim':
  ensure => present
}
```


