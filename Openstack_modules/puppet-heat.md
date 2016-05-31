# puppet-heat

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理heat服务？](#核心代码讲解)
    - [class heat](#class heat)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)


AWS CloudFormation服务，为用户提供了编排AWS中的资源的能力。Openstack社区在2012年推出了类似支持编排功能的服务Heat。Heat基本的workflow是这样的：
![](../images/heat.png)

我们来快速部署一个带有heat的all-in-one环境，我们需要一点hack：
在`fixtures/scenario-aio.pp`文件中追加: