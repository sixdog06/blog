---
title: "JVM入门-字符串常量池"
date: 2021-01-29
draft: false
author: "小拳头"
categories: ["Java"]
tags: ["JVM"]
---

String比较特殊, 具有不可变性(声明为final), 并且实现了Serializable接口(支持序列化), Comparable接口(可比较), 在介绍GC之前单独拿出来研究. 在jdk8中, String其实就是一个char的数组; jdk9中, String变成了byte数组, 因为像英文字母其实只需要一个byte存储, 如果用char存储, 那么另一个byte的空间就浪费了. 所以jdk9中ISO-8859-1/Latin-1编码就用一个byte存储; 而UTF-16, 就用byte+encoding-flag来表示一个字符, encoding-flag用来指明用哪个字符集.

## 不可变性
字符串常量池是不会存储相同字符串的. String在jdk7及之后储存在堆中的, 之前在方法区永久代. 为什么不放jdk7不放永久代, 因为永久代默认比较小, 而且垃圾回收频率低. 虽然常量池也在堆中, 但是为了方便, 后面描述jdk7及以后的字符串常量池和堆这些说法的时候, 默认堆指的是常量池以外的堆.
```
public class StringTest1 {
    public void test1() {
        String s1 = "abc"; //字面量定义的方式, "abc"存储在字符串常量池中
        String s2 = "abc";
        s1 = "hello";

        System.out.println(s1 == s2); //判断地址: true变false
        System.out.println(s1); //hello重新声明新的空间
        System.out.println(s2); //abc
    }

    public void test2() {
        String s1 = "abc";
        String s2 = "abc";
        s2 += "def";
        System.out.println(s2); //abcdef重新声明新的空间
        System.out.println(s1); //abc
    }

    public void test3() {
        String s1 = "abc";
        String s2 = s1.replace('a', 'm');
        System.out.println(s1); //abc
        System.out.println(s2); //mbc
    }
}
```

> String Pool是一个固定大小的Hashtable, 如果放进StringPool的String非常多, 会造成Hash冲突, 导致链表变长, 调用String和intern的性能就会大幅下降. 在jdk6中, StringTable的长度默认值是1009; 在jdk7中, StringTable的长度默认值是60013; jdk8开始, 1009是StringTable可设置的最小值. **使用-XX: StringTableSize可设置StringTable的长度**. 

Java语言中有8种基本数据类型和一种比较特殊的类型String, 为了使它们在运行过程中速度更快, 更节省内存, 都提供了一种常量池的概念. 在jdk6中如果内存爆了, 会出现`OutOfMemoryError: PermGen space`, jdk7及之后内存爆了会出现`OutOfMemoryError: Java heap space`, 证明字符串常量池的位置从永久代移动到了堆空间. 移动的原因主要是永久代空间较小而且垃圾回收频率不高. 

继续测试不变性, 下面代码的数字代表debug时的memory count大小, 注意不是从0开始的. Java语言规范规定相同的字符创字面量应该包含同样的Unicode字符序列(包含同一份码点序列常量), 并且必须指向同一个String类实例.
```
public static void main(String[] args) {
    System.out.println(); //2293
    System.out.println("1"); //2294
    System.out.println("2"); //2295
    System.out.println("3"); //2297
    //内存没有增加
    System.out.println("1"); //2297
    System.out.println("2"); //2297
}
```

官方案例:
```
class Memory {
    public static void main(String[] args) {//line 1
        int i = 1;//line 2
        Object obj = new Object();//line 3
        Memory mem = new Memory();//line 4
        mem.foo(obj);//line 5
    }//line 9

    private void foo(Object param) {//line 6
        String str = param.toString();//line 7 堆中字符串常量创建对象
        System.out.println(str);
    }//line 8
}
```
![](/37_1.png)

## 字符串拼接
1. 常量与常量的拼接结果在常量池, 因为经过了**编译期优化**.
2. 常量池中不会存在相同内容的常量.
3. **只要其中有一个是变量, 结果就在非常量池的堆中**. 变量拼接的原理是StringBuilder.
4. 如果拼接的结果调用intern()方法, 则主动将常量池中还没有的字符串对象放入池中, 并返回此对象地址.

```
public void test1() {
    String s1 = "a" + "b" + "c"; //等同于"abc"(编译期优化), 字节码命令是ldc #2<abc>
    String s2 = "abc"; //"abc"一定是放在字符串常量池中，将此地址赋给s2
    
    System.out.println(s1 == s2); //true
    System.out.println(s1.equals(s2)); //true
}

public void test2() {
    String s1 = "javaEE";
    String s2 = "hadoop";

    String s3 = "javaEEhadoop";
    String s4 = "javaEE" + "hadoop"; //编译期优化
    String s5 = s1 + "hadoop"; //相当于在堆空间中new String(), 具体的内容为拼接的结果: javaEEhadoop, 不在常量池中
    String s6 = "javaEE" + s2;
    String s7 = s1 + s2;

    System.out.println(s3 == s4);//true
    System.out.println(s3 == s5);//false
    System.out.println(s3 == s6);//false
    System.out.println(s3 == s7);//false
    System.out.println(s5 == s6);//false
    System.out.println(s5 == s7);//false
    System.out.println(s6 == s7);//false
    
    String s8 = s6.intern(); //intern(): 判断字符串常量池中是否存在javaEEhadoop值, 如果存在, 则返回常量池中javaEEhadoop的地址;
    //如果字符串常量池中不存在javaEEhadoop, 则在常量池中加载一份javaEEhadoop, 并返回次对象的地址.
    System.out.println(s3 == s8);//true
}

/*
    s1+s2的执行细节(s1和s2都是变量):
    1. StringBuilder s = new StringBuilder();
    2. s.append("a")
    3. s.append("b")
    4. s.toString() -> 类似new String("ab")

    注意在jdk5.0之后使用的是StringBuilder, 在jdk5.0之前使用的是StringBuffer
*/
public void test3() {
    String s1 = "a";
    String s2 = "b";
    String s3 = "ab";

    String s4 = s1 + s2;
    System.out.println(s3 == s4); //false
}

/*
    1. 字符串拼接操作不一定使用的是StringBuilder, 如果拼接符号左右两边都是字符串常量或常量引用(test4的s1和s2), 则仍然使用编译期优化
    2. 针对于final修饰类, 方法, 基本数据类型, 引用数据类型的量的结构时, 能使用上final就用; 为了在编译器就初始化值, 也就是在类加载器的linking中的prepare阶段就初始化.
*/
public void test4() {
    final String s1 = "a";
    final String s2 = "b";
    String s3 = "ab";
    String s4 = s1 + s2;
    System.out.println(s3 == s4);//true
}

// test5原理和test4类似
public void test5() {
    String s1 = "javaEEhadoop";
    String s2 = "javaEE";
    String s3 = s2 + "hadoop";
    System.out.println(s1 == s3); //false

    final String s4 = "javaEE"; //s4:常量
    String s5 = s4 + "hadoop";
    System.out.println(s1 == s5); //true
}
```

注意**append效率要比字符串拼接高**. 因为StringBuilder的append()的方式自始至终中只创建过一个StringBuilder的对象, 而字符串拼接方式: 内存中由于创建了较多的StringBuilder和String的对象, 内存占用更大, 如果有垃圾回收就会花费额外的时间. 在实际开发中, 如果确定要前后添加的字符串长度不高于某个限定值highLevel的情况下, 建议使用构造器实例化: StringBuilder s = new StringBuilder(highLevel); //new char[highLevel]. 这样就避免的扩容的操作.

## intern方法
如果不是用双引号声明的String对象, 可以使用String提供的intern方法, intern方法会从字符串常量池中查询当前字符串是否存在(用equals方法判断), 若不存在就会将当前字符串放入常量池中.
```
// 为了保证变量s指向字符串常量池数据, 可以用字面量定义方式
String s = "test"

// 或者调用intern
String s  = new String("test").intern();
String s = new StringBuilder("test").toString().intern();
```

## 几个问题
***new String("ab")会创建几个对象?*** 看字节码, 有两个. 一个对象是new关键字在堆空间创建的; 另一个对象是字符串常量池中的对象"ab"(对应字节码命令ldc).

***new String("a")+new String("b")会创建几个对象?*** : 对象1: StringBuilder(因为有拼接操作); 对象2: new String("a"); 对象3: 常量池中的"a"; 对象4: new String("b"); 对象5: 常量池中的"b". 

其实`StringBuilder()`的底层也通过new String("ab")从创建了对象, 但是"ab"本身是不在字符串常量池的, 因为字节码命令中没有ldc.

***想为什么出现下面代码的结果***
```
/**
 * 如何保证变量s指向的是字符串常量池中的数据呢？
 * 有两种方式：
 * 方式一： String s = "test";//字面量定义的方式
 * 方式二： 调用intern()
 *         String s = new String("test").intern();
 *         String s = new StringBuilder("test").toString().intern();
 */
public class StringIntern {
    public static void main(String[] args) {
        String s = new String("1"); //s 指向堆空间"1"的内存地址
        String s1 = s.intern(); //s1 指向字符串常量池中"1"的内存地址, 因为上一行使"1"已经存在于字符串常量池了
        String s2 = "1"; //s2 指向字符串常量池已存在的"1"的内存地址, 所以s1==s2        
        
        System.out.println(s == s2); //jdk6: false  jdk7/8: false
        System.out.println(s1 == s2);//jdk6: true  jdk7/8: true

        // s3变量记录的地址为: new String("11")
        String s3 = new String("1") + new String("1"); //字符串常量池中不存在"11", 只有"1"

        //jdk6: 创建了一个新的对象"11", 也就有新的地址, "11"在永久代
        //jdk7: 此时常量池中并没有创建"11", 而是创建一个指向堆空间中new String("11")的地址, 因为堆空间有了"11", 常量池只要用指针指向new的堆空间的"11"即可
        s3.intern();

        String s4 = "11"; //使用的是上一行代码执行时, 在常量池中生成的"11"的地址
        System.out.println(s3 == s4); //jdk6: false  jdk7/8: true
    }
}
```

再来一段代码, s3.intern()在不同位置结果一样吗?
```
public class StringIntern1 {
    public static void main(String[] args) {
        String s3 = new String("1") + new String("1"); 
        // s3.intern(); // 字符创常量池创建"11"指向外面的堆中的s3
        String s4 = "11";
        // s3.intern(); // 字符创常量池没有"11", 只有造个新的
        System.out.println(s3 == s4); //s3在前true, 在后false
    }
}
```

## 总结
- jdk1.6中, 将这个字符串对象尝试放入串池: **如果字符串常量池中有, 则并不会放入, 返回已有的池中的对象的地址; 如果没有, 会把此对象复制一份, 放入池, 并返回池中的对象地址.**
- Jdk1.7起, 将这个字符串对象尝试放入串池: **如果字符串常量池中有, 则并不会放入, 返回已有的池中的对象的地址; 如果没有, 则会把对象的引用地址复制一份, 放入串池, 并返回串池中的引用地址.**

## 空间效率
如果需要内存中存储大量的字符串, 这时候如果字符串都调用intern()方法, 就会明显降低内存的大小, 也就是省空间. 因为有一些new的String在池外面的堆中, 可以被回收. 

## 垃圾回收
增加下面代码循环数(j的大小), 就可以看到有GC发生. 垃圾回收器G1能自动持续对String有去重操作, 很明显常量池是没有去重的, 去重发生在池外的堆中. 

- UseStringDeduplication(bool): 开启String去重(默认是不开启).
- PrintStringDedupl icationStatistics(bool): 打印详细的去重统计信息.
- tringDedupl icationAgeThreshold(uintx): 达到这个年龄的string对象被认为是去重的候选对象.
```
/**
 * String的垃圾回收:
 * -Xms15m -Xmx15m -XX:+PrintStringTableStatistics -XX:+PrintGCDetails
 */
public class StringGCTest {
    public static void main(String[] args) {
        for (int j = 0; j < 100000; j++) {
            String.valueOf(j).intern();
        }
    }
}
```

## 参考
1. [尚硅谷最新版宋红康JVM教程](https://www.bilibili.com/video/BV1PJ411n7xZ?p=1)
2. [The Java® Virtual Machine Specification](https://docs.oracle.com/javase/specs/jvms/se8/html/index.html)