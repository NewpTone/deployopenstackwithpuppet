# puppet-heat

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理heat服务？](#核心代码讲解)
    - [class heat](#class heat)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

## 先睹为快

AWS CloudFormation服务，为用户提供了编排AWS中的资源的能力。Openstack社区在2012年推出了类似支持编排功能的服务Heat。Heat基本的workflow是这样的：
![](../images/heat.png)

我们来快速部署一个带有heat的all-in-one环境，我们需要一点hack：
在`fixtures/scenario-aio.pp`文件中追加:
```puppet
include ::openstack_integration::heat
```
然后在终端下执行:
```bash
   puppet apply -v fixtures/scenario-aio.pp
```
在执行完成后，我们通过systemctl命令，可以看到以下服务并启动：
```bash
 openstack-heat-api-cfn.service                                                                                 loaded    active   running   Openstack Heat CFN-compatible API Service
  openstack-heat-api-cloudwatch.service                                                                          loaded    active   running   OpenStack Heat CloudWatch API Service
  openstack-heat-api.service                                                                                     loaded    active   running   OpenStack Heat API Service
  openstack-heat-engine.service                                                                                  loaded    active   running   Openstack Heat Engine Service
  ```
  
## 核心代码讲解

### class heat::api
   和其他服务类似，heat::api完成了对heat-api软件包，相关配置文件和服务管理。
   
### class heat::api_cfn
   和其他服务类似，heat::api_cfn完成了对heat-api-cfn软件包，相关配置文件和服务管理。
   
### class heat::engine 
      和其他服务类似，heat::engine完成了对heat-engine软件包，相关配置文件和服务管理。


