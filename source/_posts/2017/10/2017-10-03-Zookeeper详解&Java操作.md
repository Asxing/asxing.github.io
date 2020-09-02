---
title: Zookeeper扫盲
author: HoldDie
img: 
top: false
cover: false
coverImg: 
toc: true
mathjax: true
tags:
  - CentOS
  - Zookeeper
date: 2017-10-04 21:32:16
password:
summary:  
categories: Zookeeper
---

# Zookeeper 扫盲 :disappointed_relieved:

### 配置文件详解：

+ tickTime：基本事件单元，以毫秒为单位，这个时间作为 Zookeeper 服务器之间或客户端之间维持心跳的时间间隔
+ dataDir：存储内存中数据库快照的位置，顾名思义就是 Zookeeper 保存数据的目录，默认情况下，Zookeeper 将写数据的日志文件也保存到这个目录里
+ clientPort：这个端口就是客户端连接 Zookeeper 服务器的端口，Zookeeper 会监听这个端口，接受客户端的访问请求
+ initLimit：这个配置项是用来配置 Zookeeper 接受客户端初始化连接时最长能忍受多少个心跳时间间隔
  + 当已经超过 10 个心跳的时间也就是（ticktime）长度后 Zookeeper 服务器还没有收到客户端的返回信息，那么表明这个客户端连接失败，总的时间长度就是：10*2000 = 20s
+ syncLimit：这个配置项表示 Leader 与 Follower 之间发送消息，请求和应答时间长度，最长不能超过多少个 tickTime 的时间长度，总的时间长度就是：5*2000 = 10s
+ server.A = B:C:D
  + A：表示这是第几号服务器
  + B：服务器的 IP 地址
  + C：服务器与集群中的 Leader 服务器交换信息的端口
  + D：一旦集群中的 Leader 服务器挂了，需要一个端口重新进行选举，选出一个新的 Leader
  + 2181：对外提供端口
  + 2888：内部同步端口
  + 3888：节点挂了，选举端口


### ZK 设计目标

+ 简单的数据结构（树形名字空间）
+ 构建集群（一般奇数，超过半数以上就可以正常访问）
+ 顺序访问
+ 高性能（12w QPS）

### 集群搭建

![](https://www.holddie.com/img/20200105141731.png)

### Java 连接 ZK

+ 客户端通过创建一个 ZK 实例来连接 ZK 服务器


+ Zookeeper(Arguments) 方法
  + connectString：连接服务器列表，用“，”分隔
  + sessionTimeout：心跳检测时间周期（毫秒）
  + wather：时间处理通知器
  + canBeReadOnly：标识当前会话是否支持只读
  + SessionId 和 SessionPasswd：提供连接 Zookeeper 的sessionId 和 密码，通过这俩个确定唯一一台客户端，目的是可以提供重复会话
+ ZK 客户端和服务器会话的建立是一个异步的过程，我们程序方法在处理完客户端初始化后立即返回，
  + 也就是程序往下执行代码，这样，大多数情况下我们并没有真正构建好一个可用会话，在会话生命周期处于“CONNECTING”时，才算建立完毕

### Zookeeper 组成

+ 根据其身份的特征分为三种：Leader、Follower、Observer，其中 Follower 和 Observer 统称为 Learner （学习者）
+ leader：负责客户端的 writer 类型请求
+ Follower：负责客户端 reader 类型请求，参与 leader 选举
+ Observer：特殊的“Follower”，其可以接收客户端 reader 请求，但不参与选举。（扩容系统支撑能力，提高读取速度）因为他不接受任何同步的写入请求，只负责 leader 同步数据

### Java 操作方法

+ 创建节点（znode）方法：create
  + 提供了两套创建节点的方法，同步和异步创建节点方法
  + 参数1：节点路径：/nodeName （不允许递归创建节点，也就是在父节点不存在的情况下，不允许创建子节点）
  + 参数2：节点内容：要求类型是字节数组（不支持序列化方式，如果需要实现程序化，可使用 Java 相关序列化框架，如 Hession、Kryo 框架）
  + 参数3：节点权限：使用 Ids.OPEN_ACL_UNSAFE 开放权限
  + 参数4：节点类型：创建节点的类型： CreateMode.*
    + persistent（持久节点）
    + persistent_sequential（持久顺序节点）
    + ephemeral（临时节点）
    + ephemeral_sequential（临时顺序节点）
  + 参数5：注册一个异步回调函数，要实现 AsynCallBack.StringCallBack 接口，重写 processResult(int rc, String path, Object ctx, String name) 方法，当节点创建完毕后执行此方法。
    + rc：为服务端相应码 0 表示调用成功、-4 表示端口连接、-110 表示指定节点存在、-112 表示会话已经过期
    + path：接口调用时传入 API 的数据节点的路径参数
    + ctx：为调用接口传入 API 的 ctx 值
    + name：实际在服务器端创建节点的名称
  + 参数6：传递给回调函数的参数，一般为上下文（Context）信息


+ 使用了 CountDownLatch 中的 countDown 只要是要确保我们的zk 连接成功再继续往下进行。


+ 对于 Zookeeper 中存在节点时，我们添加相同节点时，我们不能创建成功。


在创建临时节点时，在本次回话有效，当本次回话结束时，我们的临时节点就会失效

单一视图，三个节点上数据是一致的，消息广播，临时的 temp

分布式锁原理：对于临时节点，同一时间只能有一个 Client 操作一个节点，同时貌似加了一把锁的形式，可以对于相同的业务逻辑，不同的 Tomcat 操作，就确保了操作的唯一性。存在内存中，效率高 12WQPS

```
zk.create("/app/c1", "c1".getBytes(), Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
```

原生的API中 Zookeeper 不允许递归创建节点

```java
public class ZookeeperBase {
 
    /** zookeeper地址 */
    static final String CONNECT_ADDR = "192.168.80.88:2181,192.168.80.87:2181,192.168.80.86:2181";
    /** session超时时间 */
    static final int SESSION_OUTTIME = 2000;//ms
    /** 信号量，阻塞程序执行，用于等待zookeeper连接成功，发送成功信号 */
    static final CountDownLatch connectedSemaphore = new CountDownLatch(1);
 
    public static void main(String[] args) throws Exception{
 
        ZooKeeper zk = new ZooKeeper(CONNECT_ADDR, SESSION_OUTTIME, new Watcher(){
            @Override
            public void process(WatchedEvent event) {
                //获取事件的状态
                KeeperState keeperState = event.getState();
                EventType eventType = event.getType();
                //如果是建立连接
                if(KeeperState.SyncConnected == keeperState){
                    if(EventType.None == eventType){
                        //如果建立连接成功，则发送信号量，让后续阻塞程序向下执行
                        connectedSemaphore.countDown();
                        System.out.println("zk 建立连接");
                    }
                }
            }
        });
 
        //进行阻塞
        connectedSemaphore.await();
 
        System.out.println("..");
        //创建父节点
//        zk.create("/testRoot", "testRoot".getBytes(), Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
 
        //创建子节点
//        zk.create("/testRoot/children", "children data".getBytes(), Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
 
        //获取节点洗信息
//        byte[] data = zk.getData("/testRoot", false, null);
//        System.out.println(new String(data));
//        System.out.println(zk.getChildren("/testRoot", false));
 
        //修改节点的值
//        zk.setData("/testRoot", "modify data root".getBytes(), -1);
//        byte[] data = zk.getData("/testRoot", false, null);
//        System.out.println(new String(data));    
 
        //判断节点是否存在
//        System.out.println(zk.exists("/testRoot/children", false));
        //删除节点
//        zk.delete("/testRoot/children", -1);
//        System.out.println(zk.exists("/testRoot/children", false));
 
        zk.close();
    }
 
}
```

getChildren 只可以取下面直接的一层，

使用 -1 是跳过版本检查，如果再删除的时候，会检查本地版本和远程版本若相同则会删除，否则不删除。同时不支持递归的删除

getChildren 读取数据方法：包括子节点列表的获取和子节点数据的获取

+ 参数1：path：获取指定节点的下的数据（获取子节点列表）
+ 参数2：watcher：注册的 watcher ，一旦在本次子节点获取后，子节点列表发生变化的话，那么就会向客户端发送通知，该参数允许为 null。
+ 参数3：表明是否需要注册一个 watcher：如果为 true，则会使用到 zookeeper 客户端上下文中提到的那个默认 watcher ，如果为 false，则表明不需要注册 watcher。
+ 参数4：cb：回调函数
+ 参数5：ctx：上下文信息对象
+ 参数6：stat：指定数据节点的节点状态信息

注意：

+ 当我们获取指定节点的子节点列表后，还需要订阅这个子节点列表的变化通知，这时候就可以注册一个 watcher 来实现
+ 当子节点被添加或删除时，服务器端就会触发一个“NodeChildrenChanged“类型的时间通知，
+ 服务器端发送给客户端收到这个事件通知中，是不包含最新的节点列表的，客户端必须主动从新进行获取，通常在客户端收到这个事件通知后，就可以再次主动获取最新的子节点列表了
+ ZK 服务端在向客户端发送 watcher “NodeChildrenChanged”事件通知的时候，仅仅只发了一个通知，不会节点把节点的节点的变化情况发送给客户端，需要客户端自己重新获取
+ watcher 通知是一次性的，即触发后失效，因此客户端需要反复注册 watcher 才行。

getData 方法：获取指定节点的数据内容

+ path：路径
+ watcher：注册的 watcher 对象，一旦之后节点内容有变更，则会向客户端发送通知，该参数允许为 null，触发事件为“NodeDataChanged”事件通知
+ stat：指定节点的状态信息
+ watch：是否使用 watcher，如果为 true 则使用默认上下文中的 watcher， false 则不使用 watcher
+ cb：回调函数
+ ctx：传递上下文信息对象

setData 方法：修改指定节点的数据内容

+ path：路径
+ data：数据内容
+ 版本号：（-1 覆盖之前的所有的版本）
+ cb：回调函数
+ ctx：用于传递的下文信息对象

exists 方法：检测节点是否存在

+ path：路径
+ watcher：注册的 watcher 对象，用于三类时间监听（节点的创建，删除，更新）
+ cb：回调函数
+ ctx：传递的上下文信息对象
+ exits 方法的意义在于无论节点是否存在，都可以进行注册 watcher，能够对节点的创建，删除和修改进行监听，但是其子节点发送各种变化，都不会通知客户端。

### 事件类型

+ ZK 有 watch 事件，是一次性触发的，当 watch 监视的数据发生变化时，通知设置了该watch 的 client ，即 watcher


+ watcher 是监听数据发送了某些变化，那就一定会有对应的事件类型和状态类型
+ 事件类型：（znode节点相关）
  + EventType.NodeCreated
  + EventType.NodeDataChanged
  + EventType.NodeChildrenChaged
  + EventType.NodeDeleted
+ 状态类型：（客户端实例相关）
  + KeeperState.Disconnected
  + KeeperState.SyncConnected
  + KeeperState.AuthFailed
  + KeeperState.Expired


+ watch事件是一次性的，watcher 表示 client


```java
package bjsxt.zookeeper.watcher;
 
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;
 
import org.apache.zookeeper.CreateMode;
import org.apache.zookeeper.WatchedEvent;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.Watcher.Event.EventType;
import org.apache.zookeeper.Watcher.Event.KeeperState;
import org.apache.zookeeper.ZooDefs.Ids;
import org.apache.zookeeper.ZooKeeper;
import org.apache.zookeeper.data.Stat;
 
/**
* Zookeeper Wathcher
* 本类就是一个Watcher类（实现了org.apache.zookeeper.Watcher类）
* @author（alienware）
* @since 2015-6-14
*/
public class ZooKeeperWatcher implements Watcher {
 
    /** 定义原子变量 */
    AtomicInteger seq = new AtomicInteger();
    /** 定义session失效时间 */
    private static final int SESSION_TIMEOUT = 10000;
    /** zookeeper服务器地址 */
    private static final String CONNECTION_ADDR = "192.168.80.88:2181";
    /** zk父路径设置 */
    private static final String PARENT_PATH = "/testWatch";
    /** zk子路径设置 */
    private static final String CHILDREN_PATH = "/testWatch/children";
    /** 进入标识 */
    private static final String LOG_PREFIX_OF_MAIN = "【Main】";
    /** zk变量 */
    private ZooKeeper zk = null;
    /** 信号量设置，用于等待zookeeper连接建立之后 通知阻塞程序继续向下执行 */
    private CountDownLatch connectedSemaphore = new CountDownLatch(1);
 
    /**
     * 创建ZK连接
     * @param connectAddr ZK服务器地址列表
     * @param sessionTimeout Session超时时间
     */
    public void createConnection(String connectAddr, int sessionTimeout) {
        this.releaseConnection();
        try {
            zk = new ZooKeeper(connectAddr, sessionTimeout, this);
            System.out.println(LOG_PREFIX_OF_MAIN + "开始连接ZK服务器");
            connectedSemaphore.await();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
 
    /**
     * 关闭ZK连接
     */
    public void releaseConnection() {
        if (this.zk != null) {
            try {
                this.zk.close();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
 
    /**
     * 创建节点
     * @param path 节点路径
     * @param data 数据内容
     * @return
     */
    public boolean createPath(String path, String data) {
        try {
            //设置监控(由于zookeeper的监控都是一次性的所以 每次必须设置监控)
            this.zk.exists(path, true);
            System.out.println(LOG_PREFIX_OF_MAIN + "节点创建成功, Path: " +
                               this.zk.create(    /**路径*/
                                                   path,
                                                   /**数据*/
                                                   data.getBytes(),
                                                   /**所有可见*/
                                                   Ids.OPEN_ACL_UNSAFE,
                                                   /**永久存储*/
                                                   CreateMode.PERSISTENT ) + 
                               ", content: " + data);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }
 
    /**
     * 读取指定节点数据内容
     * @param path 节点路径
     * @return
     */
    public String readData(String path, boolean needWatch) {
        try {
            return new String(this.zk.getData(path, needWatch, null));
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
    }
 
    /**
     * 更新指定节点数据内容
     * @param path 节点路径
     * @param data 数据内容
     * @return
     */
    public boolean writeData(String path, String data) {
        try {
            System.out.println(LOG_PREFIX_OF_MAIN + "更新数据成功，path：" + path + ", stat: " +
                                this.zk.setData(path, data.getBytes(), -1));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
 
    /**
     * 删除指定节点
     *
     * @param path
     *            节点path
     */
    public void deleteNode(String path) {
        try {
            this.zk.delete(path, -1);
            System.out.println(LOG_PREFIX_OF_MAIN + "删除节点成功，path：" + path);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
 
    /**
     * 判断指定节点是否存在
     * @param path 节点路径
     */
    public Stat exists(String path, boolean needWatch) {
        try {
            return this.zk.exists(path, needWatch);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
 
    /**
     * 获取子节点
     * @param path 节点路径
     */
    private List<String> getChildren(String path, boolean needWatch) {
        try {
            return this.zk.getChildren(path, needWatch);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
 
    /**
     * 删除所有节点
     */
    public void deleteAllTestPath() {
        if(this.exists(CHILDREN_PATH, false) != null){
            this.deleteNode(CHILDREN_PATH);
        }
        if(this.exists(PARENT_PATH, false) != null){
            this.deleteNode(PARENT_PATH);
        }    
    }
 
    /**
     * 收到来自Server的Watcher通知后的处理。
     */
    @Override
    public void process(WatchedEvent event) {
 
        System.out.println("进入 process 。。。。。event = " + event);
 
        try {
            Thread.sleep(200);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
 
        if (event == null) {
            return;
        }
 
        // 连接状态
        KeeperState keeperState = event.getState();
        // 事件类型
        EventType eventType = event.getType();
        // 受影响的path
        String path = event.getPath();
 
        String logPrefix = "【Watcher-" + this.seq.incrementAndGet() + "】";
 
        System.out.println(logPrefix + "收到Watcher通知");
        System.out.println(logPrefix + "连接状态:\t" + keeperState.toString());
        System.out.println(logPrefix + "事件类型:\t" + eventType.toString());
 
        if (KeeperState.SyncConnected == keeperState) {
            // 成功连接上ZK服务器
            if (EventType.None == eventType) {
                System.out.println(logPrefix + "成功连接上ZK服务器");
                connectedSemaphore.countDown();
            }
            //创建节点
            else if (EventType.NodeCreated == eventType) {
                System.out.println(logPrefix + "节点创建");
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                this.exists(path, true);
            }
            //更新节点
            else if (EventType.NodeDataChanged == eventType) {
                System.out.println(logPrefix + "节点数据更新");
                System.out.println("我看看走不走这里........");
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(logPrefix + "数据内容: " + this.readData(PARENT_PATH, true));
            }
            //更新子节点
            else if (EventType.NodeChildrenChanged == eventType) {
                System.out.println(logPrefix + "子节点变更");
                try {
                    Thread.sleep(3000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(logPrefix + "子节点列表：" + this.getChildren(PARENT_PATH, true));
            }
            //删除节点
            else if (EventType.NodeDeleted == eventType) {
                System.out.println(logPrefix + "节点 " + path + " 被删除");
            }
            else ;
        }
        else if (KeeperState.Disconnected == keeperState) {
            System.out.println(logPrefix + "与ZK服务器断开连接");
        }
        else if (KeeperState.AuthFailed == keeperState) {
            System.out.println(logPrefix + "权限检查失败");
        }
        else if (KeeperState.Expired == keeperState) {
            System.out.println(logPrefix + "会话失效");
        }
        else ;
 
        System.out.println("--------------------------------------------");
 
    }
 
    /**
     * <B>方法名称：</B>测试zookeeper监控<BR>
     * <B>概要说明：</B>主要测试watch功能<BR>
     * @param args
     * @throws Exception
     */
    public static void main(String[] args) throws Exception {
 
        //建立watcher
        ZooKeeperWatcher zkWatch = new ZooKeeperWatcher();
        //创建连接
        zkWatch.createConnection(CONNECTION_ADDR, SESSION_TIMEOUT);
        //System.out.println(zkWatch.zk.toString());
 
        Thread.sleep(1000);
 
        // 清理节点
        zkWatch.deleteAllTestPath();
 
        if (zkWatch.createPath(PARENT_PATH, System.currentTimeMillis() + "")) {
 
            Thread.sleep(1000);
 
 
            // 读取数据
            System.out.println("---------------------- read parent ----------------------------");
            //zkWatch.readData(PARENT_PATH, true);
 
            // 读取子节点
            System.out.println("---------------------- read children path ----------------------------");
            zkWatch.getChildren(PARENT_PATH, true);
 
            // 更新数据
            zkWatch.writeData(PARENT_PATH, System.currentTimeMillis() + "");
 
            Thread.sleep(1000);
 
            // 创建子节点
            zkWatch.createPath(CHILDREN_PATH, System.currentTimeMillis() + "");
 
            Thread.sleep(1000);
 
            zkWatch.writeData(CHILDREN_PATH, System.currentTimeMillis() + "");
        }
 
        Thread.sleep(50000);
        // 清理节点
        zkWatch.deleteAllTestPath();
        Thread.sleep(1000);
        zkWatch.releaseConnection();
    }
 
}
```
### Zookeeper 的 ACL （AUTH）

ACL（Access Control List），Zookeeper 作为一个分布式协调框架，其内部存储的都是一些关乎分布式系统运行时状态的元数据，尤其是涉及到一些分布式锁、Master选举和协调等应用场景。我们需要有效地保障 Zookeeper 中的数据安全，Zookeeper 提供一套完善的 ACL 权限控制机制来保障数据的安全。

ZK 提供了三种模式：权限模式、授权对象、权限

权限模式：Scheme 开发人员最多使用的如下四种权限模式：

+ IP ：IP 模式通过 IP 地址粒度来进行控制权限，例如配置了：IP：192.168.1.107 即表示权限控制都是针对这个 IP 地址的，同时也支持按网段分配，比如 192.168.1.*
+ Digest：digest 是最常用的权限控制模式，更符合我们对权限控制的认识，起类似于 username：password 形式的权限标识进行权限配置，ZK 会对形成的权限标识先后进行两次编码处理，分别是 SHA-1 加密算法、BASE64 编码
+ world：world 是一直最开放的权限控制模式，这种模式可以看做为特殊的 Disgest，它仅仅是一个标识而已
+ Super：超级用户模式，在超级用户模式下可以对 ZK 任意进行控制

权限对象：指的是权限赋予用户或者一个指定的实体，例如 IP 地址或机器等，在不同的模式下，授权对象是不同的，这种模式和权限对象一一对应。

权限：权限就是指那些通过权限检测后可以被允许执行的操作，在 ZK 中，对数据的操作权限分为五大类：CREATE、DELETE、READ、WRITE、ADMIN

认证只是针对某一个节点。

### zkClient 的使用

#### 创建客户端方法：ZKClient（Arguments）

+ arg1：zkServers zookeeper服务器的地址，用“，”分隔
+ arg2：sessionTimeout 超时会话，为毫秒，默认为 30 000ms
+ arg3：connectionTimeout 连接超时会话
+ arg4：IZkConnection 接口的实现类
+ arg5：zkSerializer 自定义序列化实现

可以使用递归创建，每个节点没法指定 value，可以递归删除

zkclient 最大的一个**优点**就是： **把重复watch的那个事情去掉，不需要再写数据时watch**

readeata 时，直接读取的就是字符串，不是byte字节流

#### 创建节点方法：create、createEphemeral、createEphemeralSequential、createPersistent、createPersistentSequential

+ arg1：path，路径
+ arg2：data，数据内容，可以传入 null
+ arg3：mode，节点类型，为一个枚举类型，四种形式
+ arg4：acl 策略
+ arg5：callback 回调函数
+ arg6：context 上下文对象
+ arg7：createParents 是否创建父节点

#### 删除节点方法：delete、deleteRecursive

+ arg1：Path，路径
+ arg2：callback，回调函数
+ arg3：context，上下文对象

#### 读取子节点数据方法：getChildren

+ arg1：path，路径

#### 读取节点数据方法：readData

+ arg1：path，路径
+ arg2：returnNullIFPathNotExists （避免为空节点抛出异常，直接返回 null）
+ arg3：节点状态

#### 更新数据方法：writeData

+ arg1：path，路径
+ arg2：data，数据信息
+ arg3：version 版本号

#### 检测节点是否存在方法：exists

+ arg：path，路径

我们发现，ZkClient 里面并没有类似的 watcher、watch 参数，这也就是我们说开发人员无需关心反复注册 Watcher 的问题，ZkClient 给我们提供了一套监听方式，我们可以使用监听节点的方式进行操作，剔除了繁琐的反复 watcher 操作，简化了代码复杂程度

#### subscribeChildChanges 方法

+ arg1：path，路径
+ 实现 IZkChildListener 接口的类，只需要重写其 `handleChaildChanges（String parentPath，List<String> currentChilds）` 方法，其中参数 parentPath 为所监听节点全路径，currentChilds 为最新的子节点列表（相对路径）
+ IZkChildListener 事件说明针对于下面三个事件触发：
  + 新增子节点
  + 减少子节点
  + 删除节点

#### IZkChildListener 有以下特点：

1. 客户端可以对一个不存在的节点进行变更的监听

2. 一旦客户端对一个节点注册了子节点列表变更监听后，那么当前节点的子节点雷彪发送变更的时候，服务端都会通知客户端，并将最新的自己诶单列表发送给客户端

3. 该节点本身创建或删除也会通知到客户端

4. 另外最重要的是这个监听是一直存在的，不是单次监听，相比较原生 API 提供的要简单的多

5. subscribeChildChange（"/super",new IZkChildListener() {}）

   + 对于 Zkclient 会告诉你变化之后的数据是多少，对于节点的当前和子级的状态


   + 当对于一个节点的update 的时候，并不会监听，只会监听当前节点或子节点的添加和删除

6. subscribeDataChange（"/super",new IZkDataListener() {}）

   + 对于变更的状态包括：删除和修改，其中的状态分开走

#### 原先zk设计的状况：

+ event 只会告诉你变化的事件，触发什么事件，自己根据path，读取数据，并且还是一次，



+ 通知，状态，节点路径，对于变化的之后的数据没有告诉，设计的理念就是轻量，敏捷。


## Curator 封装

是否可以监控一个节点下面所有节点的状态，分布式锁，原子统计

Curator 框架中使用了链式编程风格，易读性更强，使用工程方法创建连接对象

#### 使用 CuratorFrameworkFactory 的两个静态工厂方法（参数不同）来实现

+ arg1：connectString，连接串
+ arg2：retryPolicy，重试连接策略，有四种实现分别为：
  + ExponentialBackoffRetry
  + RetryNTimes
  + RetryOneTimes
  + RetryUntilElapsed
+ arg3：sessionTimeoutMs 会话超时时间 默认为 60 000ms
+ arg4：connectionTimeoutMs 连接超时时间，默认为15 000ms
+ 对于 retryPolicy 策略通过一个接口来让用户自定义实现

#### 创建节点 create 方法，可选链式项：

+ creatingParentsIfNeeded
+ withMode
+ forPath
+ withACL

#### 删除节点 delete 方法，可选链式项

+ deletingChildrenIfNedded
+ guaranteed
+ withVersion
+ forPath

#### 读取和修改数据

+ getData
+ setData

#### 异步绑定回调方法

+ 创建节点时绑定一个回调函数，该回调函数可以输出服务器的状态码以及服务器事件类型
+ 可以加入线程池进行优化

#### 读取子节点方法

+ getChildren

#### 判断子节点是否存在

+ checkExists

#### 回调函数为什么会使用线程池：

+ 一次性批量创建多个节点，不必要每次都回调
+ ThreadPoolExcutor 底层自定义线程
+ 批量节点操作，自己规划 callback ，多余的缓冲在队列中

#### Watcher 监听功能

+ 依赖 maven jar包

  ```xml
  <dependency>
      <groupid>org.apache.curator</groupid>
        <artifactid>curator-recipes</artifactid>
        <version>2.4.2</version>
  </dependency>
  ```


+ 我们使用 NodeCache 的方式去客户端实例中注册一个监听缓存，然后实现对应的监听方法即可，
+ 主要的监听方式：
  + NodeCacheListener：监听节点的新增，修改操作
  + PathchildrenCacheListener：监听子节点的新增、修改、删除操作

在客户端使用缓存，在服务端进行变化时，和本地的进行对比，有差异数据同步，空间换取时间，替换了原来的注册的思路。

只能监听一级节点，再下一级就不能实现，对于删除也不能迭代删除

 

### 分布式锁

分布式锁就是在共享的一段代码中，一个服务器使用，其他的服务器不允许访问，分布式锁

实现分布式锁，对于Java程序写出花来也没用，就是只针对同一个JVM，当多个JVM如何同步

#### 分布式计数器：DistributedAtomicInteger

使用了distribute，

重试的时间次数，

barrier 同时开始，同时结束，代码，

```
DistributedDoubleBarrier barrier = new DistributedDoubleBarrier(cf, "/super", 5);
```

其中的 5 代表五个客户端的连接，当五个连接上就可以同时开始，我们使用

```
barrier.enter();
```

此时就同时开始，

```
barrier.leave();
```

同时结束

在声明 Barrier 的时候也可以不设置程序的数量

同时还有另外一种写法：

实现声明 barrier

```java
/** zookeeper地址 */
    static final String CONNECT_ADDR = "192.168.1.171:2181,192.168.1.172:2181,192.168.1.173:2181";
    /** session超时时间 */
    static final int SESSION_OUTTIME = 5000;//ms
 
    static DistributedBarrier barrier = null;
 
    public static void main(String[] args) throws Exception {
 
 
 
        for(int i = 0; i < 5; i++){
            new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        RetryPolicy retryPolicy = new ExponentialBackoffRetry(1000, 10);
                        CuratorFramework cf = CuratorFrameworkFactory.builder()
                                    .connectString(CONNECT_ADDR)
                                    .sessionTimeoutMs(SESSION_OUTTIME)
                                    .retryPolicy(retryPolicy)
                                    .build();
                        cf.start();
                        barrier = new DistributedBarrier(cf, "/super");
                        System.out.println(Thread.currentThread().getName() + "设置barrier!");
                        barrier.setBarrier();    //设置
                        barrier.waitOnBarrier();    //等待
                        System.out.println("---------开始执行程序----------");
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            },"t" + i).start();
        }
 
        Thread.sleep(5000);
        barrier.removeBarrier();    //释放
 
 
    }
```

其中 barrier 作为第六人就是吹哨的人，一般我们自己设定的 const 包，用于设置的吹哨的公共

 

使用 curator 的分布式锁，对于监听的相同节点，若之前发生了变更，之后连接还会貌似数据恢复一点，数据同步，相当于重复注册，当前 /super 节点，持续订阅服务，

curator 人性化操作：

+ 对于一个节点的CRUD监控
+ 实现分布式锁
+ 实现barrier、原子计数器
+ 实现队列




