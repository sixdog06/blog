---
title: "Java String"
date: 2021-03-11
draft: false
author: "小拳头"
categories: ["Tech"]
tags: ["Java"]
---

在面试中遇到了一个问题: Java String是线程安全的吗? 我刚开始回答它是不安全的, 因为方法都没有加`synchronized`, 后来被面试官引导到字符串常量池才反应过来, String底层是`private final char value[];`, 是常量, 所以**String一定是线程安全的**, 并不能从`synchronized`来看是不是安全, 因为这个char数组就没法用方法修改.

从常量池的角度来看, 在[JVM-字符创常量池](https://xqt01.github.io/post/jvm/8_%E5%AD%97%E7%AC%A6%E4%B8%B2%E5%B8%B8%E9%87%8F%E6%B1%A0/)已经总结了. 去理解`String`到底在底层创建了多少个对象, `intern()`的作用, 字符串拼接底层在干什么.

对于String底层, 我们直接先看构造方法. (JDK8下依然是char[], JDK9及之后就是byte[]了)
```
//this constructor is unnecessary since Strings are immutable.
public String() {
    this.value = "".value;
}

// Unless an explicit copy of {@code original} is needed, use of this constructor is unnecessary since Strings are immutable.
public String(String original) {
    this.value = original.value;
    this.hash = original.hash;
}

// 用char sequence创建String对象, 也有public String(char value[], int offset, int count), 可以限制范围
public String(char value[]) {
    this.value = Arrays.copyOf(value, value.length);
}

public String(StringBuffer buffer) {
    synchronized(buffer) {
        this.value = Arrays.copyOf(buffer.getValue(), buffer.length());
    }
}

public String(StringBuilder builder) {
    this.value = Arrays.copyOf(builder.getValue(), builder.length());
}
```

还有一些常用方法.
```
// 返回对应index的char字符
public char charAt(int index) {
    if ((index < 0) || (index >= value.length)) {
        throw new StringIndexOutOfBoundsException(index);
    }
    return value[index];
}

// 比较两个String, 
public int compareTo(String anotherString) {
    int len1 = value.length;
    int len2 = anotherString.value.length; //类的内部可以调用value, 也不需要用length()方法
    int lim = Math.min(len1, len2);
    char v1[] = value;
    char v2[] = anotherString.value;

    int k = 0;
    while (k < lim) { //如果长度重叠部分有不同的字符, 则相当于把String的每一个char看成一个桶中的数字
        char c1 = v1[k];
        char c2 = v2[k];
        if (c1 != c2) {
            return c1 - c2;
        }
        k++;
    }
    return len1 - len2; //长度重叠部分没有不同的字符, 比较长度
}

public String concat(String str) {
    int otherLen = str.length();
    if (otherLen == 0) {
        return this;
    }
    int len = value.length;
    char buf[] = Arrays.copyOf(value, len + otherLen);
    str.getChars(buf, len);
    return new String(buf, true);
}

// 返回一个char数组, 不能用Arrays.copyOf, 我的猜测是初始化阶段当String初始化的时候, Arrays还没有初始化
public char[] toCharArray() {
    // Cannot use Arrays.copyOf because of class initialization order issues
    char result[] = new char[value.length];
    System.arraycopy(value, 0, result, 0, value.length);
    return result;
}

// 重写了hashCode方法, 所以即使两个String对象的哈希值相同, 不代表内容相同
public int hashCode() {
    int h = hash;
    if (h == 0 && value.length > 0) {
        char val[] = value;

        for (int i = 0; i < value.length; i++) {
            h = 31 * h + val[i];
        }
        hash = h;
    }
    return h;
}

// 去掉首尾空格
public String trim() {
    int len = value.length;
    int st = 0;
    char[] val = value;    /* avoid getfield opcode */

    while ((st < len) && (val[st] <= ' ')) {
        st++;
    }
    while ((st < len) && (val[len - 1] <= ' ')) {
        len--;
    }
    return ((st > 0) || (len < value.length)) ? substring(st, len) : this;
}
```

## 参考
1. Javadoc
2. [Doubts about typecast "(String)anObject" and anotherString.value.length](https://stackoverflow.com/questions/57508759/doubts-about-typecast-stringanobject-and-anotherstring-value-length)
3. [Why doesn't String toCharArray use Arrays.copyOf?](https://stackoverflow.com/questions/49715328/why-doesnt-string-tochararray-use-arrays-copyof)