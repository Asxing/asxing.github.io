---
title: JVM-card-table
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - JVM
  - card-tale
date: 2018-02-05 21:32:16
password:
summary:  
categories: JVM
---



由卡表出发，Java内存管理一日游！



## 垃圾回收中一些抉择

### 串行回收VS并行回收

- 串行：同一时间点只会发生一件事情。
- 并行：垃圾回收操作分成不同的子模块，由不同的 CPU 并行执行，但是会有更高的复杂性以及潜在的碎片情况。

### 并行回收VS全局暂停回收

- stop-the-world 垃圾收集器：在执行时，将堆锁住，对象在此期间不发生变动。
- 并行垃圾回收：应用暂停的时间会更短，但是收集器必须额外考虑，当应用在使用对象的时候，是否应该执行更新操作，在堆较大的时候，会带来一定的性能影响。

### 压缩VS不压缩VS拷贝

- 压缩：将存活的对象收集到一起，重新利用剩余的空间，在压缩之后，可以很容易的给对象分配空间，可以使用一个指针来跟踪分配对象的结尾。
- 非压缩：垃圾收集速度快，但是内存碎片化问题比较严重，一般而言，非压缩算法的分配成本高于压缩算法。
- 拷贝：将所有存活的对象拷贝到另一块内存区域，好处在于，之前使用的内存区域就可以当成是完全新的，劣势是需要拷贝所需的内存空间。

## 性能上的度量

- **吞吐**：指不在垃圾回收上面使用的时间占比。
- **垃圾收集负载**：指吞吐的对立面，是在垃圾回收上面的时间占比。
- **暂停时间**：当执行垃圾回收的时候，应用暂停执行的时间。
- **收集频率**：多久执行一次，这个值通常和应用的执行时相关。
- **占用的空间**：对空间的占用的衡量，比如堆的大小。
- **迅捷**：当一个对象成为了垃圾对象和它占用空间可用的时间间隔。

## 参数回顾

### 串行收集器

```bash
-XX:+UseSerialGC
```

### 并行收集器

``` bash
-XX:+UseParallelGC
```

### 并行压缩收集器

``` bash
-XX:+ParallelGCThreads=n
```

### 并发标记-替换收集器（concurrent mark-sweep）

```bash
–XX:CMSInitiatingOccupancyFraction=n
#其中 n 表示的就是老年代的一个占比，默认值为68。

-XX:+UseConcMarkSweepGC
```

### 增量模式

```bash
-XX:+CMSIncrementalMode
```

## G1垃圾收集器

G1（Garbage First）是JDK1.7提供的一个工作在新生代和老年代的收集器，基于“标记-整理”算法实现，在收集结束后可以避免内存碎片问题。

#### G1优点：

1、并行与并发：充分利用多CPU来缩短Stop The World的停顿时间；
2、分代收集：不需要其他收集配合就可以管理整个Java堆，采用不同的方式处理新建的对象、已经存活一段时间和经历过多次GC的对象获取更好的收集效果;
3、空间整合：与CMS的"标记-清除"算法不同，G1在运行期间不会产生内存空间碎片，有利于应用的长时间运行，且分配大对象时，不会导致由于无法申请到足够大的连续内存而提前触发一次Full GC;
4、停顿预测：G1中可以建立可预测的停顿时间模型，能让使用者明确指定在M毫秒的时间片段内，消耗在垃圾收集上的时间不得超过N毫秒。

使用G1收集器时，Java堆的内存布局与其他收集器有很大区别，整个Java堆会被划分为多个大小相等的独立区域Region，新生代和老年代不再是物理隔离了，都是一部分Region（不需要连续）的集合。G1会跟踪各个Region的垃圾收集情况（回收空间大小和回收消耗的时间），维护一个优先列表，根据允许的收集时间，优先回收价值最大的Region，避免在整个Java堆上进行全区域的垃圾回收，确保了G1收集器可以在有限的时间内尽可能收集更多的垃圾。

不过问题来了：使用G1收集器，一个对象分配在某个Region中，可以和Java堆上任意的对象有引用关系，那么如何判定一个对象是否存活，是否需要扫描整个Java堆？其实这个问题在之前收集器中也存在，如果回收新生代的对象时，不得不同时扫描老年代的话，会大大降低Minor GC的效率。

针对这种情况，虚拟机提供了一个解决方案：G1收集器中Region之间的对象引用关系和其他收集器中新生代与老年代之间的对象引用关系被保存在 Remenbered Set 数据结构中，用来避免全堆扫描。G1中每个Region都有一个对应的 Remenbered Set，当虚拟机发现程序对Reference类型的数据进行写操作时，会产生一个Write Barrier暂时中断写操作，检查Reference引用的对象是否处于相同的Region中，如果不是，则通过CardTable把相关引用信息记录到被引用对象所属Region的Remenbered Set中。

## Card-table

### 产生原因

在垃圾回收的过程中，会碰到一个问题，就是老年代中的对象可能引用年轻代中的对象。这种情况下，每次遍历老年代的对象来查找所有存活对象的时候会消耗相当的时间。实际上，这种引用也非常少，这就导致遍历整个老年代是非常不划算的。

### 引用赋值操作

当在用户代码中执行了引用赋值操作的时候，其实都有JVM隐式的将赋值操作进行额外的处理。这份额外的吃力回避角度想被赋值的地址，是否在老年代范围。如果是老年代的范围，则将对应的card-table中的bit置为1，表示当前 bit 对应的内存块，

card-table的每个 4KB 的内存块，只是针对老年代的标记的一定程度的优化，若我们能将粒度细化到对象的程度上，那自然就可以更大程度的减少标记的时间，但是同时 card-table 的大小也将显著变大，而且更大的 card-table 也会令赋值引用操作（JIT执行的额外动作来赋值 card-table）变得更慢。

在 JVM 中，一个 Card 的大小是 512 字节，在多个线程并行收集时，JVM通过ParGCCardsPerStrideChunk 参数设置每个线程每次扫描的 Card 数量，默认是256，相当于是吧老年代分成许多 strides，每个线程每次扫描一个 stride，每个 stride 大小为 512*256 = 128K，如果你的老年代大小为 4G，那总共有 4G/128K = 32K 个stride。多线程在扫描这么多的 strides 时就涉及到调度和分配的问题，stride 数量太多就会导致线程在 stride 之间切换的开销增加，进而导致 GC 暂停时间增长。因此 JVM 提供了 ParGCCardsPerStrideChunk 这个参数来配置每个 stride 对应的 card 数量，这个数量要根据实际的业务场景进行调优，网上一般流传3个魔术数字：32768、4K 和 8K。

```bash
-XX:+UnlockDiagnosticVMOptions
-XX:+ParGCCardsPerStrideChunk=4096
```

这个值不能设置的太大，因为GC线程需要扫描这个 Stride 中老年代对象持有的新生代对象的引用，如果只有少量引用新生代的对象那就导致浪费了时间在根本不需要扫描的对象上。



## Java内存区域

| 名称    | 是否线程共享 |
| ----- | ------ |
| 堆区    | 是      |
| 方法区   | 是      |
| 虚拟机栈  | 否      |
| 本地方法栈 | 否      |
| 程序计数器 | 否      |



### 方法区（Method Area）：

- 在 Java 虚拟机规范中，将方法区作为对的一个逻辑部分来对待，但事实上，方法区并不是堆（Heap）。
- 方法区用于存储被虚拟机加载的类信息（即加载类时需要加载的信息，包括版本、field、方法、接口等信息）、final 常量、静态变量、编译器即时编译的代码等。
- 方法区在物理上也不需要是连续的，可以选择固定大小或者可扩展大小，并且方法区比堆还多了一个限制：可以选择是否执行垃圾收集。
- 一般方法区上需要垃圾收集的很少，但是并不代表没有，其上的垃圾收集主要是针对常量池的内存回收和对已加载类的卸载。
- 在方法区上定义了 OutOfMemoryError：PermGen space 异常，在内存不足时抛出
- 运行时常量池是方法去的一部分，用于存储编译期就生成的字面常量、符号引用、翻译出来的直接引用（符号引用就是编码是字符串表示某个变量、接口的位置，直接引用就是根据符号引用翻译出来的地址，将在类链接阶段完成翻译）；
- 运行时常量池除了存储编译器常量外，也可以存储运行期间产生的常量（比如 String 类的 intern() 方法，作用时 String 维护了一个常量池，如果调用的字符“abc”已经在常量池中，则返回池中的字符串地址，否则，新建一个常量加入池中，并返回地址）。

### 直接内存

- 直接内存并不是JVM管理的内存，就是JVM以外的机器内存。

## Java 对象的访问方式

- 一个Java的引用访问涉及到3个内存区域：JVM栈、堆、方法区。

- 通过句柄访问（图来自于《深入理解Java虚拟机：JVM高级特效与最佳实现》）：

  ![](https://www.holddie.com/img/20200105144949.png)

  通过句柄访问的实现方式中，JVM堆中会专门有一块区域用来作为句柄池，存储相关句柄所执行的实例数据地址（包括在堆中地址和在方法区中的地址）。这种实现方法由于用句柄表示地址，因此十分稳定。

- 通过直接指针访问：（图来自于《深入理解Java虚拟机：JVM高级特效与最佳实现》）

  ![](https://www.holddie.com/img/20200105145014.png)

  通过直接指针访问的方式中，reference中存储的就是对象在堆中的实际地址，在堆中存储的对象信息中包含了在方法区中的相应类型数据。这种方法最大的优势是速度快，在HotSpot虚拟机中用的就是这种方式。

## JVM 内存分配机制

### 年轻代

​	基本的内存分配机制：Eden 区是连续的空间，且 Survivor 总有一个为空，经过一次 GC 和复制，一个 Survivor 中保存着当前还活着的对象，而 Eden 和 另一个 Survivor 区的内容都不再需要了，可以直接清空，到下一次 GC 时，两个 Survivor 的角色再互换。这种垃圾回收的方式就是**“停止-复制（Stop-and-copy）清理法”**。

​	在 Eden 区，HotSpot 虚拟机使用了两种技术加快内存分配。分别是 bump-the-pointer 和 TLAB（Thread-Local-Allocation-Buffers）。这两种做法分别是：由于 Eden 区是连续的，因此 bump-the-pointer 技术的核心就是跟踪最后创建的一个对象，在对象创建时，只需要检查最有一个对象是否有足够的内存即可，从而大大加快内存分配速度；而对于 TLAB 技术是对于多线程而言的，将 Eden 区分为若干段，每个线程使用独立的一段，避免相互影响。TLAB 结合 bump-the-pointer 将保证每个线程都使用 Eden 区的一段，并快速分配内存。

### CMS（Concurrent Mark Sweep）

> CMS收集的执行过程是：初始标记(CMS-initial-mark) -> 并发标记(CMS-concurrent-mark) -->预清理(CMS-concurrent-preclean)-->可控预清理(CMS-concurrent-abortable-preclean)-> 重新标记(CMS-remark) -> 并发清除(CMS-concurrent-sweep) ->并发重设状态等待下次CMS的触发(CMS-concurrent-reset)
>
> 具体的说，先2次标记，1次预清理，1次重新标记，再1次清除。 
>
> 1，首先jvm根据-XX:CMSInitiatingOccupancyFraction，-XX:+UseCMSInitiatingOccupancyOnly来决定什么时间开始垃圾收集；
>
> 2，如果设置了-XX:+UseCMSInitiatingOccupancyOnly，那么只有当old代占用确实达到了-XX:CMSInitiatingOccupancyFraction参数所设定的比例时才会触发cms gc；
>
> 3，如果没有设置-XX:+UseCMSInitiatingOccupancyOnly，那么系统会根据统计数据自行决定什么时候触发cms gc；因此有时会遇到设置了80%比例才cms gc，但是50%时就已经触发了，就是因为这个参数没有设置的原因；
>
> 4，当cms gc开始时，首先的阶段是初始标记(CMS-initial-mark)，是stop the world阶段，因此此阶段标记的对象只是从root集最直接可达的对象；
>
> ​     CMS-initial-mark：961330K（1572864K），指标记时，old代的已用空间和总空间
>
> 5，下一个阶段是并发标记(CMS-concurrent-mark)，此阶段是和应用线程并发执行的，所谓并发收集器指的就是这个，主要作用是标记可达的对象，此阶段不需要用户停顿。
>
> ​       此阶段会打印2条日志：CMS-concurrent-mark-start，CMS-concurrent-mark
>
> 6，下一个阶段是CMS-concurrent-preclean，此阶段主要是进行一些预清理，因为标记和应用线程是并发执行的，因此会有些对象的状态在标记后会改变，此阶段正是解决这个问题因为之后的Rescan阶段也会stop the world，为了使暂停的时间尽可能的小，也需要preclean阶段先做一部分工作以节省时间
>
> ​     此阶段会打印2条日志：CMS-concurrent-preclean-start，CMS-concurrent-preclean
>
> 7，下一阶段是CMS-concurrent-abortable-preclean阶段，加入此阶段的目的是使cms gc更加可控一些，作用也是执行一些预清理，以减少Rescan阶段造成应用暂停的时间
>
> ​     此阶段涉及几个参数：
>
> ​     -XX:CMSMaxAbortablePrecleanTime：当abortable-preclean阶段执行达到这个时间时才会结束
>
> ​     -XX:CMSScheduleRemarkEdenSizeThreshold（默认2m）：控制abortable-preclean阶段什么时候开始执行，
>
> ​      即当eden使用达到此值时，才会开始abortable-preclean阶段
>
> ​     -XX:CMSScheduleRemarkEdenPenetratio（默认50%）：控制abortable-preclean阶段什么时候结束执行
>
> ​      此阶段会打印一些日志如下：
>
> ​     CMS-concurrent-abortable-preclean-start，CMS-concurrent-abortable-preclean，
>
> ​      CMS：abort preclean due to time XXX
>
> 8，再下一个阶段是第二个stop the world阶段了，即Rescan阶段，此阶段暂停应用线程，停顿时间比并发标记小得多，但比初始标记稍长。对对象进行重新扫描并标记；
>
> ​       YG occupancy：964861K（2403008K），指执行时young代的情况
>
> ​       CMS remark：961330K（1572864K），指执行时old代的情况
>
> ​      此外，还打印出了弱引用处理、类卸载等过程的耗时
>
> 9，再下一个阶段是CMS-concurrent-sweep，进行并发的垃圾清理
>
> 10，最后是CMS-concurrent-reset，为下一次cms gc重置相关数据结构
>
>  
>
> 有2种情况会触发CMS 的悲观full gc，在悲观full gc时，整个应用会暂停
>
> ​       A，concurrent-mode-failure：预清理阶段可能出现，当cms gc正进行时，此时有新的对象要进行old代，但是old代空间不足造成的。其可能性有：1，O区空间不足以让新生代晋级，2，O区空间用完之前，无法完成对无引用的对象的清理。这表明，当前有大量数据进入内存且无法释放。
>
> ​       B，promotion-failed：新生代young gc可能出现，当进行young gc时，有部分young代对象仍然可用，但是S1或S2放不下，因此需要放到old代，但此时old代空间无法容纳此。
>
>  
>
> 影响cms gc时长及触发的参数是以下2个：
>
> ​        -XX:CMSMaxAbortablePrecleanTime=5000
>
> ​        -XX:CMSInitiatingOccupancyFraction=80
>
> 解决也是针对这两个参数来的，根本的原因是每次请求消耗的内存量过大
>
> 解决方式：
>
> ​      A，针对cms gc的触发阶段，调整-XX:CMSInitiatingOccupancyFraction=50，提早触发cms gc，就可以缓解当old代达到80%，cms gc处理不完，从而造成concurrent mode failure引发full gc
>
> ​     B，修改-XX:CMSMaxAbortablePrecleanTime=500，缩小CMS-concurrent-abortable-preclean阶段的时间
>
> ​     C，考虑到cms gc时不会进行compact，因此加入-XX:+UseCMSCompactAtFullCollection
>
> ​       （cms gc后会进行内存的compact）和-XX:CMSFullGCsBeforeCompaction=4（在full gc4次后会进行compact）参数
>
>  
>
> 在CMS清理过程中，只有初始标记和重新标记需要短暂停顿，并发标记和并发清除都不需要暂停用户线程，因此效率很高，很适合高交互的场合。
>
> CMS也有缺点，它需要消耗额外的CPU和内存资源，在CPU和内存资源紧张，CPU较少时，会加重系统负担（CMS默认启动线程数为(CPU数量+3)/4）。
>
> 另外，在并发收集过程中，用户线程仍然在运行，仍然产生内存垃圾，所以可能产生“浮动垃圾”，本次无法清理，只能下一次Full GC才清理，因此在GC期间，需要预留足够的内存给用户线程使用。所以使用CMS的收集器并不是老年代满了才触发Full GC，而是在使用了一大半（默认68%，即2/3，使用-XX:CMSInitiatingOccupancyFraction来设置）的时候就要进行Full GC，如果用户线程消耗内存不是特别大，可以适当调高-XX:CMSInitiatingOccupancyFraction以降低GC次数，提高性能，如果预留的用户线程内存不够，则会触发Concurrent Mode Failure，此时，将触发备用方案：使用Serial Old 收集器进行收集，但这样停顿时间就长了，因此-XX:CMSInitiatingOccupancyFraction不宜设的过大。
>
> 还有，CMS采用的是标记清除算法，会导致内存碎片的产生，可以使用-XX：+UseCMSCompactAtFullCollection来设置是否在Full GC之后进行碎片整理，用-XX：CMSFullGCsBeforeCompaction来设置在执行多少次不压缩的Full GC之后，来一次带压缩的Full GC。



参考资料：

> [Java GC的那些事（2）]: https://www.jianshu.com/p/94989b278114
> [Java内存管理（三）——卡片表]: http://blog.csdn.net/EthanWhite/article/details/72676874
> [Java系列笔记(3) - Java 内存区域和GC机制]: https://www.cnblogs.com/zhguang/p/3257367.html
> [JVM调优:CardTable简介]: http://www.itboth.com/d/2Qbqey/jvm
> [JVM 很关键]: https://www.cubrid.org/blog/tags/Java/