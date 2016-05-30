# 代码风格

## 熟悉语法和风格

在提交代码前，请使用Lint,RSpec和Breaker工具检查一遍。

## 如何标记弃用(Deprecation)

**所有patch必须保持向后兼容（backward compatible）**

这意味着：
 - 不能破坏原有接口（参数弃用至少保持一个周期，并要添加warning信息)
 - 不能改变参数的默认值(除非有一个好理由，并在commit消息里解释清楚原因）





