# 代码风格


## 熟悉语法和风格

在提交代码前，请使用Lint,RSpec和Breaker工具检查一遍。

## 如何标记弃用(Deprecation)

**所有patch必须保持向后兼容（backwardcompatible）**


It meansː

do not break the interface (deprecate parameters for at least one cycle, and add a warning for our users)
do not change default parameters (except if you have a good reason but your commit message must explain it)



