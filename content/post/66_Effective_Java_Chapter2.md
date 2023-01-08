---
title: "Effective Java Chapter2-Creating and Destroying Objects"
date: 2021-11-08
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
---

这是Effective Java第二章的总结, 主要涵盖对象的创建和销毁.

## Item 1: Consider static factory methods instead of constructors
这个建议和设计模式中的工厂方法不是一个东西, 这里指当我们创建对象的时候, 考虑用静态方法返回一个实例, 而不是通过new的方式直接创建对象. 

好处有
- 方法可以有自己的名字, 不像构造器只能用类名, 防止名字不符合对象本身的意义, 签名也不会=因为参数类型, 参数数量而固定
- 静态工厂方法不会像构造器一样在调用的时候创建新的对象, 像`Boolean.valueOf`返回的是`static final Boolean`
- 可以返回子类型的对象, 比如我们用接口定义一些行为, 返回这些对象不用考虑对象的具体实现
- 放回对象可根据输入不同而不同
- 在写方法的时候, 返回的实例不一定存在(各种service provider framework)

限制有
- 如果类只提供静态工厂方法, 没有public/protected的构造器, 那么没法被继承. 这种类更加推荐composition而不是inheritance
- 开发者找静态工厂方法比直接找构造器难, 所有会有新手用`new`而不是`valueOf`.

```
// new对象
Boolean bool1 = new Boolean(false);

// 更推荐用static method返回的对象, 而不是bool1中的new对象. 自定义的对象也可以参考这种设计
// 返回的是public static final Boolean的TRUE和FALSE
Boolean bool2 = Boolean.valueOf(false);

// 工厂方法返回
List list = Collections.emptyList();

// 放回对象根据输入不同而不同
// 在写方法的时候, 返回的实例不一定存在(service provider framework)
```

## Item 2: Consider a builder when faced with many constructor parameters
用一个静态内部类Builder去替代telescoping constructor, 这个Builder可以替代setter, 还可以让这个类immutable. 从实现上看, builder明显比telescope constructor更加冗长, Effective Java推荐在4个字段以上才用这种builder的方式. 像`NutritionFacts`的例子, 需要set许多字段, 除了构造器必填字段, 其他的都是可选的. 或是像`Pizza`的例子, 枚举类的toppings, 的含义是几乎等价的.
```
public class NutritionFacts {
    private final int servingSize;
    private final int servings;
    private final int calories;
    private final int fat;
    private final int sodium;
    private final int carbohydrate;

    public static class Builder {
        // Required parameters
        private final int servingSize;
        private final int servings;

        // Optional parameters - initialized to default values
        private int calories = 0;
        private int fat = 0;
        private int sodium = 0;
        private int carbohydrate = 0;

        public Builder(int servingSize, int servings) {
            this.servingSize = servingSize;
            this.servings = servings;
        }

        public Builder calories(int val) {
            calories = val;
            return this;
        }

        public Builder fat(int val){
            fat = val;
            return this;
        }

        public Builder sodium(int val) {
            sodium = val;
            return this;
        }

        public Builder carbohydrate(int val) {
            carbohydrate = val;
            return this;
        }

        public NutritionFacts build() {
            return new NutritionFacts(this);
        }
    }

    private NutritionFacts(Builder builder) {
        servingSize = builder.servingSize;
        servings = builder.servings;
        calories = builder.calories;
        fat = builder.fat;
        sodium = builder.sodium;
        carbohydrate = builder.carbohydrate;
    }

        public static void main(String[] args) {
        // 用builder就可以这样创建一个类, 这个NutritionFacts是immutable的
        NutritionFacts cocaCola = new NutritionFacts.Builder(240, 8)
                .calories(100).sodium(35).carbohydrate(27).build();
        System.out.println(cocaCola);

        // Pizza
        NyPizza pizza = new NyPizza.Builder(SMALL)
                .addTopping(SAUSAGE).addTopping(ONION).build();
        Calzone calzone = new Calzone.Builder()
                .addTopping(HAM).sauceInside().build();
    }
}

public abstract class Pizza {

    /**
     * 枚举类定义左右pizza通用的topping
     */
    public enum Topping {
        HAM, MUSHROOM, ONION, PEPPER, SAUSAGE
    }

    /**
     * 某个pizza要加的toppings
     */
    final Set<Topping> toppings;

    abstract static class Builder<T extends Builder<T>> {

        // 初始化toppings
        EnumSet<Topping> toppings = EnumSet.noneOf(Topping.class);

        // 可重复添加, 每次都会把self(this) return回去
        public T addTopping(Topping topping) {
            toppings.add(Objects.requireNonNull(topping));
            return self();
        }

        // 返回最终的Pizza实例
        abstract Pizza build();

        /**
         * Subclasses must override this method to return "this"
         */
        protected abstract T self();
    }

    // 构造器需传入builder
    Pizza(Builder<?> builder) {
        toppings = builder.toppings.clone(); // See Item 50
    }
}

public class NyPizza extends Pizza {

    public enum Size { SMALL, MEDIUM, LARGE }

    private final Size size;

    public static class Builder extends Pizza.Builder<Builder> {

        private final Size size;

        public Builder(Size size) {
            this.size = Objects.requireNonNull(size);
        }

        @Override
        public NyPizza build() {
            return new NyPizza(this);
        }

        @Override
        protected Builder self() { return this; }
    }

    private NyPizza(Builder builder) {
        super(builder);
        size = builder.size;
    }
}

public class Calzone extends Pizza {

    private final boolean sauceInside;

    public static class Builder extends Pizza.Builder<Builder> {

        private boolean sauceInside = false; // Default

        public Builder sauceInside() {
            sauceInside = true;
            return this;
        }

        @Override
        public Calzone build() {
            return new Calzone(this);
        }

        @Override
        protected Builder self() {
            return this;
        }
    }

    private Calzone(Builder builder) {
        super(builder);
        sauceInside = builder.sauceInside;
    }
}
```

## Item 3: Enforce the singleton property with a private constructor or an enum type
构造器私有化, 实例为`static final`的, 如果实例是public的, 那么调用时直接通过类字段可以拿到, 如果是private的, 那么需要通过`getInstance()`的静态工厂方法返回. 静态工厂方法可以清楚地指明这个类是单例的, 并且灵活度更高. **用单例的时候, 如果没有继承关系, 最好的方式是考虑枚举类**, 枚举类的特性让我们可以非常轻松地new许多类型的单例对象, 按需返回.
```
public class Elvis {

    public static final Elvis INSTANCE = new Elvis();
    //private static final Elvis INSTANCE = new Elvis();

    /**
     * 构造器私有化
     */
    private Elvis() {

    }

    /**
     * 用静态工厂方法返回instance, 可以把INSTANCE改为private
     * @return INSTANCE
     */
    public static Elvis getInstance() {
        return INSTANCE;
    }

    public void leaveTheBuilding() {

    }
}
```

## Item 4: Enforce noninstantiability with a private constructor
对于一个Util工具类, 可以把这个类的构造器私有化, 防止这个类被实例化, 为防止类的内部调用构造器, 还可以在构造器内`throw new AssertionError();`, 彻底杜绝实例化. 缺点是这种类无法被继承.
```
public class UtilityClass {

    // 不能实例化
    private UtilityClass() {
        throw new AssertionError();
    }

    public static void staticMethod() {
        System.out.println("this is a static method");
    }

    public static void wrongMethod() {
        new UtilityClass();
    }
}
```

## Item 5: Prefer dependency injection to hardwiring resources
当Class需要依赖资源, 可以通过构造器注入这个资源实例, 让这个Class的字段指向这个实例. 单例或者静态工厂类无法做到这一点. 因为单例的字段不能随便改动, 而静态工厂类只提供通用的静态方法.
```
public class SpellChecker {

    private final Lexicon dictionary;

    /**
     * SpellChecker依赖dictionary, 单例/静态工厂不能实现这种依赖的行为
     * @param dictionary
     */
    public SpellChecker(Lexicon dictionary) {
        this.dictionary = Objects.requireNonNull(dictionary);
    }

    public boolean isValid(String word) {
        return true;
    }

    public List<String> suggestions(String typo) {
        return null;
    }
}
```

## Item 6: Avoid creating unnecessary objects
简而言之, 有两点, 一个是new的时候要考虑是不是可以用其他方式拿到这个实例, 第二是在装箱的时候想有没有多余的对象被创建, 能用基本类型就用, **注意没必要的自动装箱**.
```
// 只创建一次, 多次创建会多次使用有限状态机, 开销大
private static final Pattern ROMAN = Pattern.compile(
        "^(?=.)M*(C[MD]|D?C{0,3})"
                + "(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})$");

public static boolean isRomanNumeral(String s) {
    return ROMAN.matcher(s).matches();
}

private static long sum() {
    // 应该用long
    Long sum = 0L;
    for (long i = 0; i <= Integer.MAX_VALUE; i++) {
        // 频繁装箱, 影响性能
        sum += i;
    }
    return sum;
}
```

## Item 7: Eliminate obsolete object references
被淘汰的对象引用如果持续存在就产生了内存泄漏的问题. 有三种情况: 
1. 我们写的Class有自己的memory, 如例子中的Stack, 可以通过吧引用指向null来释放引用
2. Class有自己的caches, 如WeakHashMap/LinkedHashMap的entry, 有自动释放机制. 这种机制包括结构本身可以释放. 如果本身释放机制不够好, 可通过一个线程去释放. 或者向`LinkedHashMap`通过`removeEldestEntry`方法, 在有新的值插入时去检查是否要释放缓存.
3. listeners/callbacks没有及时deregister
分析可以通过`heap profiler`这类的debug工具看堆的情况.

## Item 8: Avoid finalizers and cleaners
不要手动调用垃圾回收方法.

## Item 9: Prefer try-with-resources to try-finally
遇到资源需要被关闭的情况, 总是用`try-with-resources`替换`try-finally`. `try-finally`如果出现finally中的close和try中的语句同时报错, finally中的错会盖掉try中的错(Suppressed Exception), 导致debug困难. 而用`getSuppressed`会让代码冗余. 若果有多resources, 多个`try-catch`会让代码不必要地冗长.
```
public class Item9 {

    private static final int BUFFER_SIZE = 100;

    public static void main(String[] args) {
        try {
            throw new IllegalArgumentException();
        } catch (IllegalArgumentException e) {
            throw new IndexOutOfBoundsException(e.getMessage());
        } finally {
            // finally中的exception覆盖try中的IllegalArgumentException(Suppressed Exception)
            throw new NullPointerException();
        }
    }

    /**
     * 单resource
     */
    static String firstLineOfFile(String path) throws IOException {
        try (BufferedReader br = new BufferedReader(new FileReader(path))) {
            return br.readLine();
        }
    }

    /**
     * 多resource
     */
    static void copy(String src, String dst) throws IOException {
        try (InputStream in = new FileInputStream(src);
             OutputStream out = new FileOutputStream(dst)) {
            byte[] buf = new byte[BUFFER_SIZE];
            int n;
            while ((n = in.read(buf)) >= 0) {
                out.write(buf, 0, n);
            }
        }
    }

    /**
     * try-with-resource同样可以try-catch
     */
    static String firstLineOfFile(String path, String defaultVal) {
        try (BufferedReader br = new BufferedReader(new FileReader(path))) {
            return br.readLine();
        } catch (IOException e) {
            return defaultVal;
        }
    }
}
```
