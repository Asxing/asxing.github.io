---
title: Flutter-Dart基础（一）
author: HoldDie
tags: [Flutter,Dart]
top: false
date: 2019-01-21 19:43:41
categories: Flutter
---



> **不要随意翻动回忆，因为它是不可测的深渊。 ——吕洞宾拉小提琴**

#### 新建类

```dart
class Bicyle {
    int cadence;
    int _speed;
    int get speed => _speed;
    int gear;

    Bicyle(int cadence, int speed, int gear) {
        this._speed = speed;
        this.cadence = cadence;
        this.gear = gear;
    }
}

void main() {
    var bike = new Bicyle(2, 0, 1);
    print(bike);
}
```

#### 注意

- 在变量名前加下划线_来标记为它是私有的，也就是说仅仅通过改变变量名来实现将speed标记为只读的。
- 未初始化的变量的值都为Null
- 所有名字以下划线开头的变量，Dart 的编译器都会讲其强制标记为私有的
- 默认情况下，Dart 会为所有公开的变量提供存取的方法，除非你需要提供仅仅可读，可写，或者在某些情况下需要在getter方法中进行计算或是在setter方法中进行某些值得更新，否则都不需要再重新定义存取方法。
- 当拥有自己的存取方法时，可以直接使用对象点的方式，进行对象属性取值
- Dart 中不支持构造函数的重载（也就是不允许两个方法的名称相同，参数类型或者个数不同的形式）

#### 重载函数可变参数描述

```dart
import 'dart:math';

class Rectangle {
    int width;
    int height;
    Point origin;

    Rectangle({this.origin = const Point(0, 0), this.width = 0, this.height = 0});

    String toString() =>
        'Orgin: (${origin.x},${origin.y}), width: $width, height: $height';
}

main() {
    print(Rectangle(origin: const Point(10, 20), width: 100, height: 200));
    print(Rectangle(origin: const Point(11, 12)));
    print(Rectangle(width: 122));
    print(Rectangle());
} // Included main() to suppress uncaught exception.
```

工厂模式

```dart
import 'dart:math';

abstract class Shape {
    factory Shape(String type) {
        if (type == 'circle') return Circle(2);
        if (type == 'square') return Square(2);
        throw 'Can\'t create $type.';
    }
    num get area;
}

class Circle implements Shape {
    final num radius;
    Circle(this.radius);
    num get area => pi * pow(radius, 2);
}

class Square implements Shape {
    final num side;
    Square(this.side);
    num get area => pow(side, 2);
}

main() {
    // final circle = Circle(2);
    // final square = Square(2);
    // final circle = shapeFactory('circle');
    // final square = shapeFactory('square');
    final circle = Shape('circle');
    final square = Shape('square');
    print(circle.area);
    print(square.area);
}

Shape shapeFactory(String type) {
    if (type == 'circle') {
        return Circle(2);
    }
    if (type == 'square') {
        return Square(2);
    }
    throw 'Can`t create $type.';
}
```

要点：

- Dart 支持抽象类
- 可以在一个文本中定义多个类
- dart.math 是一个核心库