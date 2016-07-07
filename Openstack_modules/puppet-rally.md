# puppet-rally
`still in progress`

1. 基础知识
2. [先睹为快 - 一言不合，立马动手?](#先睹为快)
3. [核心代码讲解 - 如何做到管理Rally服务？](#核心代码讲解)
    - [class rally](#class rally)
4. [小结](##小结)
5. [动手练习 - 光看不练假把式](##动手练习)

**本节作者：余兴超**    
**阅读级别：选读 **  
**阅读时间: 40分钟**

## 基础知识

`Rally`项目是Openstack性能测试服务，可以被用于Openstack CI/CD中的基本工具链中，以提高Openstack的SLA。下图给出了Rally与Deployment,Verify,Benchmark之间的关系以及其执行流程。不过Rally当前的主要工作仍然集中在benchmark上，社区的进度比较缓慢。

![](../images/03/rally-process.png)
### 架构简介
Openstack大多数项目属于as-a-service类型，因此Rally提供了service和CLI两种方式：

- Rally as-a-Service  以web service方式对外提供服务
- Rally as-an-App     作为轻量级命令行工具使用

![](../images/03/rally-Arch.png)

## 先睹为快

在终端下执行以下命令:  
```
puppet apply -e 'include rally'
```

然后就可以开始使用rally了，是不是so easy？

## 代码讲解



