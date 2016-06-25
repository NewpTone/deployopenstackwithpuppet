# puppet-cookiebutter

1. [先睹为快](#先睹为快)
2. [核心资源讲解](#核心资源讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)


**本节作者：余兴超**    
**阅读级别：选读 **  
**阅读时间: 1小时**

## 先睹为快

本篇是选读章节，和Openstack部署没有任何关系。但推荐希望维护内部module的工程师阅读。
`puppet-cookiebutter`模块的作用是快速生成一个符合PuppetOpenstack module风格的新module。
二话不说，我们先来生成一个`puppet-test`:
```bash
$ cookiecutter puppet-openstack-cookiecutter/
project_name [YOURPROJECTNAME without 'puppet-']: test
version [0.0.1]:
year [2016]:
```
