---
title: "CSAPP-123讲"
date: 2022-12-28
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["CSAPP"]
---

# 1_Overview
第一节课几乎没有讲任何的知识, 只是单纯地介绍了这节课, 老师是Bryant和O’Hallaron, CSAPP原书的作者. 这门课的前置要求是会C语言, 教材有两本, 一是**Computer Systems: A Programmer’s Perspective, Third Edition (CS:APP3e), Pearson, 2016**, 二是讲C语言的书**The C Programming Language, Second Edition, Prence Hall, 1988**. 目前网上找得到的版本是FALL 2015的课, 各个视频平台都有, CMU也把这门课放在了[panopto](https://scs.hosted.panopto.com/Panopto/Pages/Sessions/List.aspx#folderID=%22b96d90ae-9871-4fae-91e2-b1627b43e25e%22), 可以体验上网课的感觉. 这门课的课件都在*参考1*的连接, lab在*参考2*的链接.

这门课的中心是一句话: **Abstraction Is Good But Don’t Forget Reality**, 当我们用软件去抽象现实中的东西时, 不能不考虑现实中的限制. 课上举了几个例子.
1. Ints are not Integers, Floats are not Reals. 课上用lldb举了个例子, 我们会发现50000的平方计算出来了一个神奇的数字, 乘法结合律也错了. 而这些结果并不是随机的数字.
```
(lldb) print 40000 * 40000
(int) $0 = 1600000000
(lldb) print 50000 * 50000
(int) $1 = -1794967296
(lldb)

(lldb) print (1e20 + -1e20) + 3.14
(double) $2 = 3.1400000000000001
(lldb) print 1e20 + (-1e20 + 3.14)
(double) $3 = 0
```

2. You’ve Got to Know Assembly. 你可以不写, 但是不能不懂.
3. Memory Matters. 当入参是0, 1, 2, 3直到6的时候, 发现输出改变了, 原因是不应该访问的内存被访问了. (我没复现)
```
typedef struct {
  int a[2];
  double d;
} struct_t;

double fun(int i) {
  volatile struct_t s;
  s.d = 3.14;
  s.a[i] = 1073741824; /* Possibly out of bounds */
  return s.d;
}
```

4. There’s more to performance than asymptotic complexity. 换一下两个for的顺序, 运行的速度就会慢很多.
```
void copyij(int src[2048][2048],
            int dst[2048][2048]) {
  int i,j;
  for (i = 0; i < 2048; i++)
    for (j = 0; j < 2048; j++)
      dst[i][j] = src[i][j];
}
```
5. Computers do more than execute programs. 比如网络操作, 各种i/o操作. 

# 2_Bits_Bytes_and_Integers-II
首先要了解位运算的一些常识如与, 或, 非, 异或的运算, 他们的符号分别为`&, |, ~, ^`, 以及2进制, 16进制, 10进制的转换. 在C语言中, 所有的整型都适用位运算. 对于这些整型的表示, unsigned integer为$\sum^{w-1}_{i=0}x_{i}\cdot 2^{i}$. 而signed integer为Two’s Complement: $-x_{w-1}\cdot 2^{w-1} + \sum^{w-2}_{i=0}x_{i}\cdot 2^{i}$, $x_{i}$表示某一位. 在这里不要被公式迷惑了, 实际上, unsigned整型就是直接用10进制转换的2进制存储, 而signed整型用**2的补码存储**, 且首位为是否负号的标志位. 这种区分unsigned和signed的编码形式在其他语言不一定能见到. 比如Java中的int, 就默认是32位的signed编码. 

举个例子: 我们知道当unsigned与signed做比较时, signed会自动转为unsigned, 这会造成神奇的现象, 比如`-1`与`0U`比较的结果是大于, 因为`-1`的编码为11111, 而0U是00000(假设用5位的编码).

还有个更有趣的例子, 看下面的代码, 你能看出来有什么隐藏的问题吗? 代码中`sizeof(char)`返回的是unsigned的整型, 而`int i;`在C语言中默认是`signed int i;`, 在做运算时, `i`会被转换unsigned, 而`i`在转换后, 就很有可能让这个循环的终止条件产生出乎意料的现象. 
```
int i;
for (i = n - 1; i - sizeof(char) >= 0; i--) {
    ...
}
```

课上还介绍了**sign extension**. 用有符号的整型扩充一位作为例子. 我们会很轻松地发现, 第三位的`+8`和`-8`抵消了, 只要在最高位扩充`1`, 得到的数字实际是一样的.
```
 1110 =    -8+4+2 = -2
11110 = -16+8+4+2 = -2
```

反过来**truncate**一个数字会发生什么呢? 先看一个无符号的例子, 会发现其实是做了一个mod最高位的操作.
```
27 mod 16 = 11
11011 = 16+8+0+2+1 = 27
 1011 =    8+0+2+1 = 16
```

上面是unsigned的情况, 如果是signed会怎样呢. 如下是负数去掉最高位的例子, 我们会发现, 转化成10进制后这两个数字并没有什么关系. 所以只能把`10001`当成无符号的十进制数字19, 然后再mod 16, 最后得到结果3.
```
10001 = -16+2+1 = 13
 0011 =     2+1 = 3
```

# 3_Bits_Bytes_and_Integers-II
紧接上一节课的内容, 我们先尝试一下位运算. 首先是**unsigned的加法运算**. 如果超出了范围, 最高位会被直接丢弃.
```
 1101
+0101
10010
```

而对于**two's complement的加法**, 如果是负数加正数, 实际上就实现了相减的效果. 单计算结果超出范围时, 结果也会错误, 因为最高位是符号位, 所以可能会造成计算结果正负号的改变.
```
 1101  -3
+0101   5
10010  -2

 1011  -5
+0011   3
 1010  -2
```

对于**乘法计算**, 和加法的道理是一样的, 因为计算的结果可能会超过限制的范围, 导致值出现奇怪的数字. 用**two's complement的乘法**举例.
```
 0100  5
*0100  5
11001 -7 (最高位被丢弃)
```

对于乘法计算, 如果是乘或除以$2^{n}$, 可以用左右位移来计算, 这样就可以一次运算得到结果, 而不是让加法器不断循环地去加每个数字. 当然现代机器不仅仅有加法器, 乘法并不是一直让加法去循环处理, 但是位移这种计算方式显然是更快的. 提到位移, 我们要清楚两个概念: arithmetic shift和logical shift. 前者考虑符号位, 也就是如果对于signed整型进行右移, 最高位补的数字会与符号位相同, 0则补0, 1则补1. 而后者不考虑符号位. 

对于移位还有一个现象. 考虑signed整型右移时的情况, 若原数字是`1101`, 也就是十进制的-3, 我们将它右移一位, 得到`1110`, 也就是十进制的-2. 而如果是正数`0101`的右移一位是`0010`, 也就是从5变成了2, 相当于在除以2之后进行了向下取整. 为了使正负数的计逻辑一致, 在执行负数位移时, 机器会加上一个bias number. 也就是`1101`变成了`1110`, 在进行向右位移, 得到`1111`, 也就是十进制的-1, 这样就和正数的向下取整逻辑一致了. 

## 参考
1. [Intro to Computer Systems: Schedule for Fall 2015](http://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/schedule.html)
2. [lab](http://csapp.cs.cmu.edu/3e/labs.html)