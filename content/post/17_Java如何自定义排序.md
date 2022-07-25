---
title: "Java如何自定义排序"
date: 2020-10-14
draft: false
author: "小拳头"
categories: ["编程语言"]
tags: ["Java"]
---

## Comparable接口
自定义的类自定义排序需要implements``Comparable``并且重写`public int compareTo(Object o)`
1. String等包装类实现了Comparable接口, 重写了compareTo(obj)方法, 实现升序排列
2. compareTo(obj): 当前对象this大于形参对象obj, 返回正整数. 小于返回负整数. 相等返回0.

## Comparator接口
Comparator多用于自定义排序已有的类, 比如多维数组, 自定义排序String等. 如果当前类没有实现Comparable, 那么也就只能借助Comparator. 需要重写`compare(Object o1, Object o2)`, 比较o1/o2大小. 返回正整数, 则o1大于o2. 其他同理. 

```
import java.util.Arrays;
import java.util.Comparator;

// 倒序排列
public class Compare {
    public static void main(String[] args) {
        Integer[] arr = {3, 2, 7, 4, -1, 6};

        // 实现类去实现Comparator接口, 一次性
        Arrays.sort(arr, new Comparator<Integer>() {
            @Override
            public int compare(Integer o1, Integer o2) {
                if (o1 instanceof Integer && o2 instanceof  Integer) {
                    if (o1 < o2) {
                        return 1;
                    } else if (o1 > o2) {
                        return -1;
                    } else {
                        return 0;
                    }
                }
                return 0;
            }
        });
        for (int i: arr) System.out.println(i);
    }
}
```

当然实际中要倒序, 可以转换为Collection集合类, 再`Collections.reverse()`.

## Lambda
上面的还是写太多, 用Lambda更容易(Java8后). 编译器自动判断a, b的类型和返回值的类型, **但是要注意不能是primitive的类型**.
```
Arrays.sort(arr, (a, b) -> {
    return b.compareTo(a);
});
```

其中`compareTo`调用了静态方法`compare`:
```
public static int compare(int x, int y) {
    return (x < y) ? -1 : ((x == y) ? 0 : 1);
}
```

## 哈希表排序
如果是只需要对key排序, 那么直接`new ArrayList(map.keySet())`即可. 如果是value排序的话, 直接`new ArrayList(map.values())`. 有时候需要两者一起排序, 那么就需要借助`map.entrySet()`.
```
@Test
public void test() {
    HashMap<String, Integer> map = new HashMap<>();
    map.put("A", 5);
    map.put("C", 3);
    map.put("B", 2);

    ArrayList<Map.Entry<String, Integer>> list = new ArrayList<>(map.entrySet());
    System.out.println(list); //[A=5, B=2, C=3]
    list.sort((a, b) -> {
        return a.getValue().compareTo(b.getValue());
    });
    System.out.println(list); //[B=2, C=3, A=5]
}
```

## 参考
1. Java核心技术
2. [comparable自然排序](https://www.bilibili.com/video/BV1Kb411W75N?p=491)