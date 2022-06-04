# 一、MQ介绍

## 1、什么是MQ？

​	MQ（Message Queue），消息队列。采用FIFO的数据结构。消息从生产者发送到MQ进行消费，然后按照顺序交由消息的消费者进行消费，典型的应用场景有QQ和微信。

## 2、MQ的作用（优点）

1. 异步
   + 例子：快递员发快递，直接到客户家效率会很低。引入菜鸟驿站后，快递员只需要把快递放到菜鸟驿站，就可以继续发其他快递去了。客户再按自己的时间安排去菜鸟驿站取快递。
   + 作用：异步提高系统的响应速度、吞吐量。
2. 解耦

   + 作用：

     1. 服务之间进行解耦，减少服务之间的影响。提高系统整体的稳定性以及扩展性。

     2. 解耦可以实现数据分发。生产者发送一个消息后，可以由一个或者多个消费者进行消费，并且消费者的增加或者减少对生产者没有影响。
3. 削峰
   + 例子：长江每年都会涨水，但是下游出水口的速度是基本稳定的，所以会涨水。引入三峡大坝后，可以把水储存起来，下游慢慢排水。
   + 作用：以稳定的系统资源应对突发的流量冲击。

## 3、MQ的缺点

+ 系统可用性降低

  系统引入的外部依赖增多，系统的稳定性就会变差。一旦MQ宕机，对业务也会产生影响。这时就需要考虑MQ的高可用。

+ 系统复杂度提高

  引入MQ后系统的复杂度会大大提高。之前服务之间可以进行同步调用。使用MQ就变为异步调用，数据链路就会变得复杂并且会带来数据安全问题，例如：如何保证消息不会丢失？不会被重复消费？怎么保证消息的顺序性问题的。

+ 消息一致性问题

  例如：A系统处理完业务，通过MQ发送消息给B、C系统进行后续业务的处理。B处理成功，C处理失败怎么办？

---



# 二、RabbitMQ集群模式

## 1、普通集群模式（默认）

+ 该集群模式下，集群的各个节点之间只会有相同的元数据（队列、交换机）。
+ 消息不会冗余，一条消息只会存在一个节点当中。
+ 消费时，如果消费的不是存有数据的节点，RabbitMQ会在临时节点之间进行数据传输，将消息从存在数据的节点传到消费的节点。
+ 集群的消息可靠性不高，如果其中一个节点服务宕机，那么这个节点上的数据将会无法消费，需要等该节点恢复后才能消费。而这时，消费者端已经消费过的消息就有可能给不了服务端正确应答，服务重启后，就会再次消费这些消息，造成这部分消息重复消费。如果消息未持久化，重启消息就会丢失。
+ 该集群模式不支持高可用，当一个节点服务挂掉，需要手动重启服务，才能保证这部分消息能正常消费。
+ 该集群只适用消息安全性不是很高的场景。在这种模式下，消费者应该尽量连接每一个节点，减少消息在集群中的传输。

## 2、镜像模式

+ 镜像模式是在普通模式的基础上实现的一种增强方案，这也是RabbitMQ官方HA高可用方案。
+ 镜像模式会在镜像节点中间主动进行消息同步，而不是普通模式在客户端拉取消息时临时同步。
+ 这种模式的消息可靠性更高，每个节点都存在全量的消息，而弊端也很明显，集群内部同步通讯需要消耗大量的网络带宽，降低整个的集群性能，因此在这该模式下，队列数量不要过多，并且尽量不要让RabbitMQ产生大量的消息积压。

---



# 三、RabbitMQ基本概念

RabbitMQ是基于AMQP协议开发的一个MQ产品。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%BB%84%E6%88%90.png?raw=true)

## **1、虚拟主机 virtual host**

+ RabbitMQ出于对服务器复用，可以在一个RabbitMQ集群中划分出多个虚拟主机，每个虚拟主机都有AMQP的全套基础组建，并且可以针对每个虚拟主机进行权限、数据的分配。

+ 不同虚拟主机之间是完全隔离的。

## **2、连接 Connection**

客户端与RabbitMQ进行交互，首先需要建立一个TCP连接，这个连接就是Connection。

## **3、信道 Channel**

+ 客户端与RabbitMQ建立连接后，就会分配一个AMQP信道Channel。每个信道都会被分配一个唯一的ID。也可以理解为客户端与RabbitMQ进行数据交互的通道。

+ RabbitMQ为了减少性能开销，也会在一个Connection中建立多个Channel，这样便于客户端进行多线程连接，这些连接会复用同一个Connection的TCP通道。

+ 在实际业务中，对于Connection和Channel的分配也需要根据实际情况进行考量。

## **4、交换机 Exchange**

+ 交换机是RabbitMQ中进行数据路由的重要组件。消息发送到MQ中后，会首先进入一个交换机，然后由交换机负责将消息转发到不同队列中。

+ RabbitMQ中有多种不同类型的交换机来支持不同的路由策略。

  ![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E4%BA%A4%E6%8D%A2%E6%9C%BA.png?raw=true)

  + 交换机一般多用于与生产者打交道，生产者的消息通过交换机分发到绑定的队列上。
  + 对于消费者来说，只需要关注自己感兴趣的队列即可。

## 5、队列 Queue

队列是MQ实际保存的最小单元。队列天生就具有FIFO的特性，消息最终都被分发到不同的队列中，然后才被消费者消费。

最为常用的是经典队列Classic。RabbitMQ 3.8.X版本添加了Quorum队列，3.9.X又添加了Stream队列。

### 1）Classic 经典队列

这是RabbitMQ最为经典的队列类型。在单机环境下，拥有比较高的消息可靠性。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%BB%8F%E5%85%B8%E9%98%9F%E5%88%97%E5%8F%82%E6%95%B0.png?raw=true)

参数：

**Name：**队列的名字

队列的名字，建议格式可以为多个字段，表示队列中存放的内容，比如task.queue

**Durability：是否持久化**

+ Durable：表示队列会将消息保存到硬盘，这样消息的安全性更高。但是同时，由于需要有更多的IO操作，所以生产和消费消息的性能，相比Transient会比较低

+ Transient：只是存在内存当中，服务重启，数据就没有了。

**Auto delete：是否自动删除**

+ NO：不自动删除

+ YES：队列将在至少一个消费者已经连接，然后所有的消费者都断开连接后删除自己。

**Arguments：参数配置**

| 配置名                   | 作用                                                         | 参数名                     | 值类型                                      |
| ------------------------ | ------------------------------------------------------------ | -------------------------- | ------------------------------------------- |
| Message TTL              | 发布到队列的消息在被丢弃前可以保存的时间（毫秒）             | x-message-ttl              | Number                                      |
| Auto expire              | 队列在被自动删除之前可以空闲多长时间（毫秒）                 | x-expires                  | Number                                      |
| Overflow behaviour       | 设置队列溢出行为。决定当到达队列的最大长度时，将对消息采取什么样的操作。有效值：drop-head（丢弃头部消息）、reject-publish（拒绝发布）、reject-publish-dlx（丢弃到死信队列）。 | x-overflow                 | drop-head/reject-publish/reject-publish-dlx |
| Single active consumer   | 确保一次只有一个消费者从队列里消费，并在活动消费者被取消或者死亡的情况下故障转移到另一个注册的消费者 | x-single-active-consumer   | String                                      |
| Dead letter exchange     | 死信队列。如果消息被拒绝或者过期后，消息被重新放入的exchange名称 | x-dead-letter-exchange     | String                                      |
| Dead letter rounting key | 当消息dead-lettered，根据routing key 进行路由消息，如果没有设置，会使用消息的原始routing key | x-dead-letter-rounting-key | String                                      |
| Max length               | 队列最大长度                                                 | x-max-length               | Number                                      |
| Max length bytes         | 队列最大容量，当队列的内存达到指定字节时，将采用LRU算法对以往消息进行删除 | x-max-length-bytes         | String                                      |
| Maximum priority         | 优先级队列，任何一个队列都可以通过客户端配置参数方式设置一个优先级(但是不能使用策略的方式配置这个参数)。当前优先级的最大值为：255。这个值最好在1到10之间 | x-max-priority             | String                                      |
| Lazy mode                | 惰性队列。则会将尽可能多的消息保存到磁盘上，减少内存的使用，如果不设置，则所有消息都放到内存，保证最快速度的分发 | x-queue-mode               | String（lazy）                              |
| Master locator           | 当在集群中时，设置队列为master location mode，会决定队列master在集群中的位置 | x-queue-master-locator     | String                                      |

### 2）Quorum仲裁队列

#### 1.介绍

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%9A%84Quorum%E4%BB%B2%E8%A3%81%E9%98%9F%E5%88%97.png?raw=true)

仲裁队列是RabbitMQ3.8.0版本引入的一个新的队列类型，整个3.8.X版本都是围绕仲裁队列进行完善和优化。相比Classic经典队列，在分布式环境下对消息的可靠性保障更高。并且在未来，Quorum仲裁队列会代替传统的Classic队列。

**Quorum是基于Raft一致性协议实现的一种新型的分布式消息队列**，实现了持久化，多备份的FIFO队列，主要是针对RabbbitMQ的镜像模式设计的。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%9A%84Quorum%E4%B8%8E%E7%BB%8F%E5%85%B8%E9%98%9F%E5%88%97%E7%9A%84%E5%8C%BA%E5%88%AB.png?raw=true)

说明：

1. 简单理解就是quorum队列中的消息需要集群中半数以上的节点同意确认后才会将消息写入到队列中。这样可以保证消息在集群内部不会丢失，保证消息的可靠性和安全性。
2. Quorum队列是在Classic经典队列的基础上做减法，因此对于长期使用RabbitMQ的长期使用者而言，是会影响使用体验。他与普通队列的区别：
   1. Non-durable queues：表示是非持久化的内存队列，Quorum仲裁队列不支持，说明仲裁队列是持久化队列，是以数据安全性为前提。
   2. Exclusivity：表示独占队列，即表示队列只能由声明该队列的Connection连接来进行使用，包括队列创建、删除、收发消息等，并且独占队列会在声明该队列的Connection断开后自动删除，而Quorum仲裁队列不支持，说明该类型队列希望队列是长期存在的。
   3. Poison Message(有毒的消息)：Quorum仲裁队列会持续跟踪消息的失败投递次数，并记录在“x-delivery-count”的一个头部参数。然后通过设置Delivery limit参数来指定一个毒消息的删除策略。当消息的重复投递次数超过了Delivery limit参数阈值，就会删除这些毒消息。如果配置了死信队列则将毒消息投放到dxl队列中。（所谓毒消息是指消息一直不能被消费者正常消费，可能是由于消费者失败或者消费逻辑有问题等，就会导致消息不断的重新入队，这样这些消息就成为了毒消息）

#### 2.总结

Quorum队列更适合队列长期存在，并且对容错、数据安全性方面的要求比低延迟、不持久等高级队列更加严格的场景。

**Quorum适用的场景：**

例如电商系统的订单，引入MQ后，处理速度慢一点，但是订单不会丢失，安全性是首要。

**Quorum不适用的场景：**

1. 一些临时的队列：比如transient临时队列，exclusive独占队列，或者经常会修改和删除的队列。
2. 对消息的低延迟有要求：一致性算法会影响消息的延迟。
3. 对数据的安全性要求不高：Quorum队列需要消费者手动通知或者生产者手动确认。
4. 队列消息积压严重：如果队列中的消息很大或者积压严重，就不要使用Quorum队列。Quorum队列当前会将所有消息始终保存在内存中，知道达到内存使用极限。

### 3）Stream队列

#### 1.介绍

Stream队列是RabbitMQ自3.9.0版本开始引入的一种新的数据队列类型，也是目前官方最推荐的队列类型。**这种队列类型的消息是持久化到磁盘并且具备分布式备份，更适合消费者多，读消息频繁的场景。**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%9A%84Stream%E9%98%9F%E5%88%97.png?raw=true)

#### 2.特性

Stream队列的核心是以append-only添加日志的方式来记录消息，整体来说，就是将消息以append-only的方式持久化到日志文件中（可以参考Redis的AOF持久化），然后通过调整每个消费者的消费进度offset，来实现消息的多次分发。

下方有几个属性也都是来定义日志文件的大小以及保存时间。Stream队列提供了其他队列类型不太好实现的四个特性：

##### 1）large fan-outs 大规模分发

当需要向多个订阅者发送相同的消息时，以往的队列类型必须为每个消费者绑定一个专用队列。如果消费者的数量很大，就会导致性能地下。而Stream队列允许任意数量的消费者使用同一个队列的消息，从而消除绑定多个队列的需求。

##### 2）Replay/Time-travelling 消息回溯

在RabbitMQ已有的这些队列类型，在消费者处理完消息后，消息都会从队列里删除，因此无法重新获取已经消费过的消息。而Stream队列允许用户在日志的任何一个连接点开始重新读取数据。

##### 3）Throughput Performance 高吞吐性能

Stream队列的设计是以性能为主要目标，对消息传递的吞吐量的提升是非常明显的。

##### 4）Large logs 大日志

RabbitMQ一直以来让人诟病的地方就是消息积压过多时，会导致非常明显的性能下降。但是Stream队列的设计目标就是以最小的内存开销高效地存储大量的数据。

#### 3.总结

+ 总体来说，RabbitMQ的Stream队列有很多地方借鉴了其他MQ产品的优点，因此在保证消息的可靠性的基础上，提高队列的消息吞吐量以及消息转发性能。
+ Stream队列也是RabbitMQ解决了消息积压导致性能下降明显的问题。

### 4）着眼RabbitMQ未来

从整体功能上来讲，队列只不过是一个实现FIFO的数据结构而已，这种数据结构其实是越简单越好。而当前RabbitMQ区分出这么多种队列类型，其实极大的增加了应用层面的使用难度，应用层面必须有一些不同的机制兼容各种队列。

所以，在未来版本中，RabbitMQ很可能还是会将这几种队列类型最终统一成一种类型。例如官方已经说明未来会使用Quorum队列类型替代经典队列，到那时，应用层很多工具就可以得到简化，比如不需要再设置durable和exclusive属性。

虽然Quorum队列和Stream队列目前还没有合并的打算，但是在应用层面来看，他们两者是冲突的，是一种竞争关系，未来也很有可能最终统一保留成一种类型。至于未来走向如何，我们可以在后续版本拭目以待。

---



# 四、RabbitMQ基础编程模型

这些各种各样的消息模型其实都对应一个比较统一的基础编程模型。

```java
public class RabbitMQUtils {
    private static Connection connection;
    //	private static final String HOST_NAME="localhost";
    private static final String HOST_NAME="192.168.147.135";
    private static final int HOST_PORT=5672;

    public static final String QUEUE_HELLO="hello";
    public static final String QUEUE_WORK="work";
    public static final String QUEUE_PUBLISH="publish";

    public RabbitMQUtils() {
    }

    public static Connection getConnection() throws IOException, TimeoutException {
        if(connection==null){
            ConnectionFactory connectionFactory = new ConnectionFactory();
            connectionFactory.setHost(HOST_NAME);
            connectionFactory.setPort(HOST_PORT);
            connectionFactory.setUsername("admin");
            connectionFactory.setPassword("123456");
            connectionFactory.setVirtualHost("/mirror");
            connection = connectionFactory.newConnection();
        }
        return connection;
    }
}
```

## **step1、首先创建连接，获取Channel** 

```
Connection connection = RabbitMQUtils.getConnection();
Channel channel = connection.createChannel();
```

## **step2、声明queue队列**

①.classic普通队列

```java
Map params = new HashMap<String,Object>();
params.put("x-message-ttl",3000000);
params.put("x-overflow","drop-head");
params.put("x-max-length",3000);
channel.queueDeclare("order",true,false,false,params);
/**
* channel.queueDeclare(String queue, boolean durable, boolean exclusive, boolean *autoDelete, Map<String, Object> arguments);
* queue 队列名
* durable 是否持久化
* exclusive 是否独占
* autoDelete 是否自动删除
* arguments 队列需要配置的参数
*/
```

②.quorum仲裁队列

```java
Map<String,Object> params = new HashMap<>(); 
//声明Quorum队列的方式就是添加一个x-queue-type参数，指定为quorum。默认是classic 
params.put("x-queue-type","quorum"); 
channel.queueDeclare(QUEUE_NAME, true, false, false, params);
//注意：1、对于Quorum类型，durable参数就必须是true了，设置成false的话，会报错。
//     2、同样，exclusive参数必须设置为false
```

③.stream队列

```java
Map<String,Object> params = new HashMap<>(); 
params.put("x-queue-type","stream"); 
params.put("x-max-length-bytes", 20_000_000_000L); // maximum stream size: 20 GB 
params.put("x-stream-max-segment-size-bytes", 100_000_000); // size of segment files: 100 MB 
channel.queueDeclare(QUEUE_NAME, true, false, false, params);
/*
注意：
    1、同样，durable参数必须是true，exclusive必须是false。 --你应该会想到，对于这两种队列，这两个参数就是多余的了，未来可以直接删除。
    2、x-max-length-bytes 表示日志文件的最大字节数。x-stream-max-segment-size-bytes每一个日志文件的最大大小。这两个是可选参数，通常为了防止stream日志无限制累计，都会配合stream队列一起声明。
*/
```

## **step3、Producer根据应用场景发送消息到queue**

```java
channel.basicPublish("","order",null,message.getBytes(StandardCharsets.UTF_8));
/*
channel.basicPublish(String exchange, String routingKey, BasicProperties props,message.getBytes("UTF-8")) ;
exchange  交换机名称
routingkey 路由键
props  队列参数（与生产者声明队列参数一致）
message 发送的消息
*/
```

## **step4、Consumer消费消息**

定义消费者，消费消息进行处理，并向RabbitMQ进行消息确认。确认了之后就表明这个消息已经消费完了，否则RabbitMQ还会继续让别的消费者实例来处理。

主要收集了两种消费方式：

1. 被动消费模式：Consumer等待rabbitMQ服务器将message推送过来再消费。一般是启动一个一直挂起的线程来等待。

   ```java
   DefaultConsumer consumer = new DefaultConsumer(channel) {
               @Override
               public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                   System.out.println("========================");
                   String routingKey = envelope.getRoutingKey();
                   System.out.println("routingKey >"+routingKey);
                   String contentType = properties.getContentType();
                   System.out.println("contentType >"+contentType);
                   long deliveryTag = envelope.getDeliveryTag();
                   System.out.println("deliveryTag >"+deliveryTag);
                   System.out.println("content:"+new String(body,"UTF-8"));
                   // (process the message components here ...)
                   //消息处理完后，进行答复。答复过的消息，服务器就不会再次转发。
                   //没有答复过的消息，服务器会一直不停转发。
                   channel.basicAck(deliveryTag, false);
               }
           };
    channel.basicConsume("order",false,consumer);
   /*
   其中autoAck是个关键。
   autoAck为true则表示消息发送到该Consumer后就被Consumer消费掉了，不需要再往其他Consumer转发。
   autoAck为false则会继续往其他Consumer转发。
   要注意如果每个Consumer一直为false，会导致消息不停的被转发，不停的吞噬系
   统资源，最终造成宕机。
   */
   ```

2. 主动消费模式：Comsumer主动到rabbitMQ服务器上去获取指定的messge进行消费。

   ```java
   GetResponse response = channel.basicGet("order", false);
   if(response!=null){
          System.out.println(new String(response.getBody(),"UTF-8"),true);
   }
   ```

3. Stream队列消费：

   + channel必须设置basicQos属性。

   + 正确声明Stream队列。

   + 消费时需要指定offset

   ```java
   public class StreamPushConsumer {
       private static final String QUEUE_NAME = "hello";
   
       /**
        * 保持长连接，等待服务器推送的消费方式。
        *
        * @param args
        * @throws Exception
        */
       public static void main(String[] args) throws Exception {
           Connection connection = RabbitMQUtil.getConnection();
           Channel channel = connection.createChannel();
           //1、这个属性必须设置。
           channel.basicQos(100);
           //2、声明Stream队列
           Map<String,Object> params = new HashMap<>();
           params.put("x-queue-type","stream");
           params.put("x-max-length-bytes", 20_000_000_000L); // maximum stream size: 20 GB
           params.put("x-stream-max-segment-size-bytes", 100_000_000); // size of segment files: 100 MB
           channel.queueDeclare(QUEUE_NAME, true, false, false, params);
   
           //Consumer接口还一个实现QueueConsuemr 但是代码注释过期了。
           Consumer myconsumer = new DefaultConsumer(channel) {
               @Override
               public void handleDelivery(String consumerTag, Envelope envelope,
                                          AMQP.BasicProperties properties, byte[] body)
                       throws IOException {
                   System.out.println("========================");
                   String routingKey = envelope.getRoutingKey();
                   System.out.println("routingKey >" + routingKey);
                   String contentType = properties.getContentType();
                   System.out.println("contentType >" + contentType);
                   long deliveryTag = envelope.getDeliveryTag();
                   System.out.println("deliveryTag >" + deliveryTag);
                   System.out.println("content:" + new String(body, "UTF-8"));
                   // (process the message components here ...)
                   //消息处理完后，进行答复。答复过的消息，服务器就不会再次转发。
                   //没有答复过的消息，服务器会一直不停转发。
                   channel.basicAck(deliveryTag, false);
               }
           };
           //3、消费时，必须指定offset。 可选的值：
           // first: 从日志队列中第一个可消费的消息开始消费
           // last: 消费消息日志中最后一个消息
           // next: 相当于不指定offset，消费不到消息。
           // Offset: 一个数字型的偏移量
           // Timestamp:一个代表时间的Data类型变量，表示从这个时间点开始消费。例如 一个小时前 Date timestamp = new Date(System.currentTimeMillis() - 60 * 60 * 1_000)
           Map<String,Object> consumeParam = new HashMap<>();
           consumeParam.put("x-stream-offset","last");
           channel.basicConsume(QUEUE_NAME, false,consumeParam, myconsumer);
   
           channel.close();
       }
   }
   ```

   ## **step5、完成以后关闭连接，释放资源**

   ```java
   channel.close(); 
   ```

---



# 五、RabbitMQ的工作模式

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%9A%84%E5%B7%A5%E4%BD%9C%E6%A8%A1%E5%BC%8F.png?raw=true)

## 1、hello world（简单模式）

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%AE%80%E5%8D%95%E6%A8%A1%E5%BC%8F.png?raw=true)

由P端发送一个消息到一个指定的Queue，中间不需要任何的exchange和Rounting key规则。C端按照queue的方式进行消费。

**productor：**

```java
public class Provider {
    public static void main(String[] args) throws IOException, TimeoutException {
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.queueDeclare("order",true,false,false,null);
        String message = "{productId:10001,orderId:1523}";
        channel.basicPublish("","order",null,message.getBytes(StandardCharsets.UTF_8));
        channel.close();
        connection.close();
    }
}
```

**consumer：**

```java
ublic class CosumerPush {
    public static void main(String[] args) throws IOException, TimeoutException {
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        //每次确认1条消息
        channel.basicQos(1);
        channel.queueDeclare("order", true, false, false, null);
        DefaultConsumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("========================");
                String routingKey = envelope.getRoutingKey();
                System.out.println("routingKey >"+routingKey);
                String contentType = properties.getContentType();
                System.out.println("contentType >"+contentType);
                long deliveryTag = envelope.getDeliveryTag();
                System.out.println("deliveryTag >"+deliveryTag);
                System.out.println("content:"+new String(body,"UTF-8"));
                // (process the message components here ...)
                //消息处理完后，进行答复。
                //答复过的消息，服务器就不会再次转发。
                //没有答复过的消息，服务器会一直不停转发。
                channel.basicAck(deliveryTag, false);
            }
        };
        channel.basicConsume("order",false,consumer);
    }
}
```

## 2、Work queues （工作队列模式）

这就是Kafka同意groupId的消息分发的模式

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E5%B7%A5%E4%BD%9C%E9%98%9F%E5%88%97.png?raw=true)

Producer消息发送给queue，服务器根据负载方案决定吧消息发送给一个指定的Consumer处理。

### **1.producer：**

```java
public class LeaderPublishTask {
    public static void main(String[] args) throws IOException, TimeoutException {
        String WORK_QUEUE_NAME = "task";
        Channel channel = null;
        Connection connection = null;
        connection = RabbitMQUtils.getConnection();
        channel = connection.createChannel();
        //任务一般是 不能因为消息中间件的服务而被耽误的，
        // 所以durable设置成了true，这样，即使rabbitMQ服务断了，这个消息也不会消失
        channel.queueDeclare(WORK_QUEUE_NAME, true, false, false, null);
        String message = "task:go to sleep";
        channel.basicPublish("", WORK_QUEUE_NAME, 	 	MessageProperties.PERSISTENT_TEXT_PLAIN, message.getBytes("UTF-8"));
        channel.close();
        connection.close();
    }
}
```

#### **①.channel.basicPublish()的参数：**

1. 交换机名称-exchange
2. 消息的路由键-routingKey
3. 消息属性-properties
4. 消息体-body

#### **②.properties消息属性：**

+ headers:我们有如果自定义的参数，可以封装成一个map，然后放到headers属性里
+ expiration:消息的过期时间，单位是毫秒,String类型参数。例如10秒表示为"10000"
+ deliveryMode：消息的持久化。2:消息持久化 1:消息非持久化
+ appId：应用程序id
+ clusterId：集群id
+ contentEncoding：消息内容的字符集
+ contentType：消息内容的类型
+ correlationId：一般用作为消息的唯一ID
+ messageId：消息的Id
+ priority：消息的优先级（0-9）越大越高
+ replyTo：消息失败，如果需要重回队列，重回到那个队列
+ timestamp：时间戳
+ type：消息类型
+ userId：用户id

### **2.consumer：**

```java
public class Worker01ReceiveTask {
    public static void main(String[] args) throws IOException, TimeoutException {
        String WORK_QUEUE_NAME= "task";
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.queueDeclare(WORK_QUEUE_NAME, true, false, false, null);
        channel.basicQos(1);
        channel.basicConsume(WORK_QUEUE_NAME,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("========================");
                String routingKey = envelope.getRoutingKey();
                System.out.println("routingKey >"+routingKey);
                String contentType = properties.getContentType();
                System.out.println("contentType >"+contentType);
                long deliveryTag = envelope.getDeliveryTag();
                System.out.println("deliveryTag >"+deliveryTag);
                System.out.println("content:"+new String(body,"UTF-8"));
                channel.basicAck(deliveryTag,false);
            }
        });
    }
}
//worker02也如此
```

####  **1. **启动消费者basicConsume

channel.basicConsume(QUEUE_NAME, autoAck, consumer)参数：

+ QUEUE_NAME 队列名

+ autoAck：自动应答

  1. autoAck为true则表示消息发送到该Consumer后就被Consumer消费掉了，不需要再往其他Consumer转发。
  2. autoAck为false则会继续往其他Consumer转发。
  3. 要注意如果每个Consumer一直为false，会导致消息不停的被转发，不停的吞噬系统资源，最终造成宕机。

  ```java
  //自动应答
  boolean autoAck = true;
  channel.basicConsume(QUEUE_NAME, autoAck, consumer);
  
  //手动应答
  boolean autoAck = false;
  channel.basicConsume(QUEUE_NAME, autoAck, consumer);
  ```

  

+ consumer

#### **2. **消息确认basicAck

basicAck(long deliveryTag, boolean multiple)属性：

+ deliveryTag：该消息的index。
+ multiple：是否批量。true:将一次性ack所有小于deliveryTag的消息。

```java
//单一消费
channel.basicAck(envelope.getDeliveryTag(), false)
//批量消费
channel.basicAck(envelope.getDeliveryTag(), true)
```

#### **3. **拒绝消息basicNack

basicNack(delivery.getEnvelope().getDeliveryTag(), false, true)：

+ deliveryTag:该消息的index。
+ multiple：是否批量。true:将一次性拒绝所有小于deliveryTag的消息。
+ requeue：被拒绝的是否重新入队列。

#### **4. 拒绝单条消息 basicReject**

void basicReject(long deliveryTag, boolean requeue) throws IOException;

+ deliveryTag:发布的每一条消息都会获得一个唯一的deliveryTag，它在channel范围内是唯一的

+ requeue：表示如何处理这条消息，为true表示重新放入RabbitMQ的发送队列中，为false表示通知RabbitMQ销毁该消息

  注意：channel.basicNack 与 channel.basicReject 的区别在于basicNack可以拒绝多条消息，而basicReject一次只能拒绝一条消息

#### **5. 拒绝多条消息 basicReject**

void basicNack(long deliveryTag, boolean multiple, boolean requeue) throws IOException;

+ deliveryTag:发布的每一条消息都会获得一个唯一的deliveryTag，它在channel范围内是唯一的

+ multiple：批量确认标志，为true表示包含当前消息在内的所有比该消息的deliveryTag值小的消息都被拒绝， 除了已经被应答的消息。为false则表示只拒绝本条消息

+ requeue：表示如何处理这条消息，为true表示重新放入RabbitMQ的发送队列中，为false表示通知RabbitMQ销毁该消息

需要注意：如果队列中只有一个消费者的时候，需要确认不会因为拒绝消息并重新放入消息队列中而导致在同一个消费者身上发生死循环。

#### **6. 重新投递 basicRecover**

Basic.RecoverOk basicRecover(boolean requeue);

重新投递并没有所谓的像basicReject中的basicReject的deliveryTag参数，所以重新投递好像是将消费者还没有处理的所有的消息都重新放入到队列中，而不是将某一条消息放入到队列中，与basicReject不同的是，重新投递可以指定投递的消息是否允许当前消费者消费。

#### **7. 是否重复投递isRedeliver()**

envelope.isRedeliver()

+ true :重复投递
+ false: 首次投递

#### 8.queueDeclare声明队列（声明后交给MQ创建队列）

channel.queueDeclare(String queue, boolean durable, boolean exclusive, boolean autoDelete,

Map<String, Object> arguments) throws IOException;

+ queue ：队列名称。
+ durable ： 是否持久化。true持久化，队列会保存磁盘。服务器重启时可以保证不丢失相关信息。
+ exclusive ：设置是否排他。true排他的。如果一个队列声明为排他队列，该队列仅对首次声明它的连接可见，并在连接断开时自动删除。排它是基于连接可见的，同一个连接不同信道是可以访问同一连接创建的排它队列，“首次”是指如果一个连接已经声明了一个排他队列，其他连接是不允许建立同名的排他队列，即使这个队列是持久化的，一旦连接关闭或者客户端退出，该排它队列会被自动删除，这种队列适用于一个客户端同时发送与接口消息的场景。
+ autoDelete :设置是否自动删除。true是自动删除。自动删除的前提是：致少有一个消费者连接到这个队列，之后所有与这个队列连接的消费者都断开 时，才会自动删除生产者创建这个队列，或者没有消费者客户端与这个队列连接时，都不会自动删除这个队列。
+ arguments ：设置队列的一些其它参数。如x-message-ttl,x-expires等。

### 3.总结：

+ 首先。Consumer端的autoAck字段设置的是false，这表示consumer在接收到消息后不会自动反馈服务器已消费了message，而要改在对message处理完成了之后，再调用channel.basicAck来通知服务器已经消费了该message.这样即使Consumer在执行message过程中出问题了，也不会造成message被忽略，因为没有ack的message会被服务器重新进行投递。但是，这其中也要注意一个很常见的BUG，就是如果所有的consumer都忘记调用basicAck()了，就会造成message被不停的分发，也就造成不断的消耗系统资源。这也就是 Poison Message(毒消息)
+ 其次，官方特意提到的message的持久性。关键的message不能因为服务出现问题而被忽略。还要注意，官方特意提到，所有的queue是不能被多次定义的。如果一个queue在开始时被声明为durable，那在后面再次声明这个queue时，即使声明为 not durable，那这个queue的结果也还是durable的。
+ 然后，是中间件最为关键的分发方式。这里，RabbitMQ默认是采用的fairdispatch，也叫round-robin模式，就是把消息轮询，在所有consumer中轮流发送。这种方式，没有考虑消息处理的复杂度以及consumer的处理能力。而他们改进后的方案，是consumer可以向服务器声明一个prefetchCount，我把他叫做预处理能力值。channel.basicQos(prefetchCount);表示当前这个consumer可以同时处理几个message。这样服务器在进行消息发送前，会检查这个consumer当前正在处理中的message(message已经发送，但是未收到consumer的basicAck)有几个，如果超过了这个consumer节点的能力值，就不再往这个consumer发布。这种模式，官方也指出还是有问题的，消息有可能全部阻塞，所有consumer节点都超过了能力值，那消息就阻塞在服务器上，这时需要自己及时发现这个问题，采取措施，比如增加consumer节点或者其他策略
+ 另外官网上没有深入提到的，就是还是没有考虑到message处理的复杂程度。有的message处理可能很简单，有的可能很复杂，现在还是将所有message的处理程度当成一样的。还是有缺陷的，但是目前也只看到dubbo里对单个服务有权重值的概念，涉及到了这个问题。

## 3、Publish/Subscribe 发布订阅模式

**exchange type：fanout**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%9A%84%E5%8F%91%E5%B8%83%E8%AE%A2%E9%98%85%E6%A8%A1%E5%BC%8F.png?raw=true)

该机制是对上面的一种补充。也就是把producer与consumer进行进一步的解耦。producer只负责发送消息，至于消息进入哪一个queue，由exchange来分配。如上图，就是把producer发送的消息，交由exchange同时发送到两个queue里，然后由不同的Consumer去进行消费。

**producer：**//只负责往exchange里发消息，后面的事情不管。

```java
public class SnnaWB {
    public static void main(String[] args) throws IOException, TimeoutException {
        String EXCHANGE_NAME_SINA="sina.wb";
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME_SINA,"fanout");
        String message="新浪微博：今天天气晴";
        channel.basicPublish(EXCHANGE_NAME_SINA,"",null,message.getBytes(StandardCharsets.UTF_8));
        channel.close();
        connection.close();
    }
}
```

```java
public class TecentWB {
    public static void main(String[] args) throws IOException, TimeoutException {
        String EXCHANGE_NAME_TENCENT="tencent.wb";
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME_TENCENT,"fanout");
        String message="腾讯微博：五一节假日将放假5天";
        channel.basicPublish(EXCHANGE_NAME_TENCENT,"",null,message.getBytes(StandardCharsets.UTF_8));
        channel.close();
        connection.close();
    }
}
```

**receiver：** //将消费的目标队列绑定到exchange上。

```java
public class User001 {
    public static void main(String[] args) throws IOException, TimeoutException {
        String EXCHANGE_NAME_SINA="sina.wb";
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME_SINA,"fanout");
        String queue = channel.queueDeclare().getQueue();
        channel.queueBind(queue,EXCHANGE_NAME_SINA,"");
        channel.basicConsume(queue,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("========================");
                String routingKey = envelope.getRoutingKey();
                System.out.println("routingKey >"+routingKey);
                String contentType = properties.getContentType();
                System.out.println("contentType >"+contentType);
                long deliveryTag = envelope.getDeliveryTag();
                System.out.println("deliveryTag >"+deliveryTag);
                System.out.println("content:"+new String(body,"UTF-8"));
                channel.basicAck(deliveryTag,false);
            }
        });
    }
}
```

```java
public class User003 {
    public static void main(String[] args) throws IOException, TimeoutException {
        String EXCHANGE_NAME_SINA="sina.wb";
        String EXCHANGE_NAME_TENCENT="tencent.wb";
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME_SINA,"fanout");
        channel.exchangeDeclare(EXCHANGE_NAME_TENCENT,"fanout");
        String queue = channel.queueDeclare().getQueue();
        channel.queueBind(queue,EXCHANGE_NAME_SINA,"");
        channel.queueBind(queue,EXCHANGE_NAME_TENCENT,"");
        channel.basicConsume(queue,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("========================");
                String routingKey = envelope.getRoutingKey();
                System.out.println("routingKey >"+routingKey);
                String contentType = properties.getContentType();
                System.out.println("contentType >"+contentType);
                long deliveryTag = envelope.getDeliveryTag();
                System.out.println("deliveryTag >"+deliveryTag);
                System.out.println("content:"+new String(body,"UTF-8"));
                channel.basicAck(deliveryTag,false);
            }
        });
    }
}
```

## 4、Routing基于内容的路由模式

**exchange type：direct**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%9A%84%E8%B7%AF%E7%94%B1%E6%A8%A1%E5%BC%8F.png?raw=true)

这种模式一看图就清晰了。 在上一章 exchange 往所有队列发送消息的基础上，增加一个路由配置，指定exchange如何将不同类别的消息分发到不同的queue上。

关键代码===> 

```
public interface Queues {
    String ElectronicProductQueue="phone.queue";
    String FoodProductQueue="food.queue";
}
```

```
public interface RountKey {
     String phoneRoutingKey="phone";
     String fruitRoutingKey="fruit";
     String vegetablesRoutingKey="vegetables";
}
```

**Producer：**//消息发布社

```java
public class MixMessagePublisher {
    private static final String  EXCHANGE_NAME="mix.message.exchange";
    public static void main(String[] args) throws IOException, TimeoutException {
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME,"direct");
        String message="今天的热卖水果是西瓜";
        String message01="今天的热卖的蔬菜是黄瓜";
        String message02="今天的手机是华为手机";
        channel.basicPublish(EXCHANGE_NAME,RountKey.fruitRoutingKey,null,message.getBytes(StandardCharsets.UTF_8));
channel.basicPublish(EXCHANGE_NAME,RountKey.vegetablesRoutingKey,null,message01.getBytes(StandardCharsets.UTF_8));
channel.basicPublish(EXCHANGE_NAME,RountKey.phoneRoutingKey,null,message02.getBytes(StandardCharsets.UTF_8));
        channel.close();
        connection.close();
    }
}
```

**Receiver：**

食物消息需求者：

```java
public class FoodProductNews {
            private static final String  EXCHANGE_NAME="mix.message.exchange";
            public static void main(String[] args) throws IOException, TimeoutException {
                Connection connection = RabbitMQUtils.getConnection();
                Channel channel = connection.createChannel();
         //1.绑定交换机
        channel.exchangeDeclare(EXCHANGE_NAME,"direct");
         //2.声明队列
        channel.queueDeclare(Queues.FoodProductQueue,false,false,true,null);
       //3.绑定队列       
                channel.queueBind(Queues.FoodProductQueue,EXCHANGE_NAME,RountKey.fruitRoutingKey);
  channel.queueBind(Queues.FoodProductQueue,EXCHANGE_NAME,RountKey.vegetablesRoutingKey);
       //4.声明消费者
  channel.basicConsume(Queues.FoodProductQueue,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                //（推模式）
                System.out.println("========================");
                String routingKey = envelope.getRoutingKey();
                System.out.println("routingKey >"+routingKey);
                String contentType = properties.getContentType();
                System.out.println("contentType >"+contentType);
                long deliveryTag = envelope.getDeliveryTag();
                System.out.println("deliveryTag >"+deliveryTag);
                System.out.println("content:"+new String(body,"UTF-8"));
                channel.basicAck(deliveryTag,false);
            }
        });
    }
}
```

电子产品消息需求者：

```java
public class PhoneProductNews {
    private static final String  EXCHANGE_NAME="mix.message.exchange";
    public static void main(String[] args) throws IOException, TimeoutException {
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_NAME,"direct");
        channel.queueDeclare(Queues.ElectronicProductQueue,false,false,true,null);
        channel.queueBind(Queues.ElectronicProductQueue,EXCHANGE_NAME,RountKey.phoneRoutingKey);
        channel.basicConsume(Queues.ElectronicProductQueue,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("========================");
                String routingKey = envelope.getRoutingKey();
                System.out.println("routingKey >"+routingKey);
                String contentType = properties.getContentType();
                System.out.println("contentType >"+contentType);
                long deliveryTag = envelope.getDeliveryTag();
                System.out.println("deliveryTag >"+deliveryTag);
                System.out.println("content:"+new String(body,"UTF-8"));
                channel.basicAck(deliveryTag,false);
            }
        });
    }
}
```

## 5、Topics基于话题的主题模式

**exchange type：topic**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%9A%84Topics%E8%AF%9D%E9%A2%98%E6%A8%A1%E5%BC%8F.png?raw=true)

**Producer：**//邮局总转站

```java
public class PostOffice {
    private static String EXCHANGE_EMAIL="email.exchange";
    public static void main(String[] args) throws IOException, TimeoutException {
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_EMAIL,"topic");
        String message_zhang="上海:张先生收";
        String message_wang="山东:王先生收";
        String message_li="成都:李先生收";
        channel.basicPublish(EXCHANGE_EMAIL,"wang.shanghai.xiaoqu",null,message_zhang.getBytes(StandardCharsets.UTF_8));
        channel.basicPublish(EXCHANGE_EMAIL,"shandong.bingguan.wang",null,message_wang.getBytes(StandardCharsets.UTF_8));
        channel.basicPublish(EXCHANGE_EMAIL,"li.sushe.chengdu",null,message_li.getBytes(StandardCharsets.UTF_8));
        channel.close();
        connection.close();
    }
}
```

**Receiver：**

邮局东方站：

```java
public class EastPostOffice {
    private static String EXCHANGE_EMAIL="email.exchange";
    public static void main(String[] args) throws IOException, TimeoutException {
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_EMAIL,"topic");
        channel.queueDeclare(PostQueues.Queue_East,false,false,true,null);
        channel.queueBind(PostQueues.Queue_East,EXCHANGE_EMAIL,EmailRountKey.RoutingKey_EAST_SHANDONG);
        channel.queueBind(PostQueues.Queue_East,EXCHANGE_EMAIL,EmailRountKey.RoutingKey_EAST_SHANGHAI);
        channel.basicConsume(PostQueues.Queue_East,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("========================");
                String routingKey = envelope.getRoutingKey();
                System.out.println("routingKey >"+routingKey);
                String contentType = properties.getContentType();
                System.out.println("contentType >"+contentType);
                long deliveryTag = envelope.getDeliveryTag();
                System.out.println("deliveryTag >"+deliveryTag);
                System.out.println("content:"+new String(body,"UTF-8"));
                channel.basicAck(deliveryTag,false);
            }
        });
    }
}
```

邮局南方站：

```java
public class SouthPostOffice {
    private static String EXCHANGE_EMAIL="email.exchange";
    public static void main(String[] args) throws IOException, TimeoutException {
        Connection connection = RabbitMQUtils.getConnection();
        Channel channel = connection.createChannel();
        channel.exchangeDeclare(EXCHANGE_EMAIL,"topic");
        channel.queueDeclare(PostQueues.Queue_South,false,false,true,null);
        channel.queueBind(PostQueues.Queue_South,EXCHANGE_EMAIL,EmailRountKey.RoutingKey_SOUTH_CHENGDU);
        channel.basicConsume(PostQueues.Queue_South,new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("========================");
                String routingKey = envelope.getRoutingKey();
                System.out.println("routingKey >"+routingKey);
                String contentType = properties.getContentType();
                System.out.println("contentType >"+contentType);
                long deliveryTag = envelope.getDeliveryTag();
                System.out.println("deliveryTag >"+deliveryTag);
                System.out.println("content:"+new String(body,"UTF-8"));
                channel.basicAck(deliveryTag,false);
            }
        });
    }
}
```

## 6、RPC远程调用

+ 远程调用是同步阻塞的调用远程服务并获取结果。

+ RPC远程调用机制其实并不是消息中间件的处理强项。毕竟消息队列机制很大程度上来说就是为了缓冲同步RPC调用造成的瞬间高峰。而RabbitMQ的同步调用示例，看着也确实怪怪的。
+ RPC远程调用的场景，也有太多可替代的技术会比用消息中间件处理得更优雅，并且更流畅。

## 7、Publisher Confirms 发送者消息确认

### 1.介绍

RabbitMQ的消息可靠性是非常高的，但是他以往的机制都是保证消息发送到了MQ之后，可以推送到消费者消费，不会丢失消息。但是发送者发送消息是否成功是没有保证的。

我们可以回顾下，发送者发送消息的基础API：

Producer.basicPublish方法是没有返回值的，也就是说，一次发送消息是否成功，应用是不知道的，这在业务上就容易造成消息丢失。而这个模块就是通过给发送者提供一些确认机制，来保证这个消息发送的过程是成功的。

### 2.使用

发送者确认模式默认是不开启的，所以如果需要开启发送者确认模式，需要手动在channel中进行声明。

```java
channel.confirmSelect(); 
```

### 3.Publisher Confirms的三种模式

#### ①.发布单条消息

即发布一条消息就确认一条消息。

核心代码：

```java
public class Sender {
    public static void main(String[] args) throws IOException, TimeoutException, InterruptedException {
        long timeStart = System.currentTimeMillis();
        Connection connection = RabbitMQUtils.getConnection();
        //开启发送者确认模式
        Channel channel = connection.createChannel();
        channel.confirmSelect();
        Map params = new HashMap<String,Object>();
        params.put("x-message-ttl",3000000);
        params.put("x-overflow","drop-head");
        params.put("x-max-length",3000);
        channel.queueDeclare("order",true,false,false,params);
        for(int i=0;i<1000;i++) {
            String message = "Hello World，this is No."+(i+1)+" news";
        channel.basicPublish("","order",null,message.getBytes(StandardCharsets.UTF_8));
            //该方法会阻塞channel，等待消息收到的确认，再确认期间会一直阻塞，直到确认后再发送下条消息
            channel.waitForConfirmsOrDie(5_000);
        }
        channel.close();
        connection.close();
        long timeEnd = System.currentTimeMillis();
        System.out.println("花费时间："+(timeEnd-timeStart));
    }
}
花费时间：3664
```

#### ②.发送批量消息

对比单条消息发布，批量消息发送的吞吐量肯定是要比单条高的，具体操作是批量发送一批消息，再批量确认

```java
public class Sender01 {

    public static void main(String[] args) throws IOException, TimeoutException, InterruptedException {
        long timeStart = System.currentTimeMillis();
        int outstandingMessageCount=0;
        Connection connection = RabbitMQUtils.getConnection();
        //开启发送者确认模式
        Channel channel = connection.createChannel();
        channel.confirmSelect();
        Map params = new HashMap<String,Object>();
        params.put("x-message-ttl",3000000);
        params.put("x-overflow","drop-head");
        params.put("x-max-length",3000);
        channel.queueDeclare("order",true,false,false,params);
        for(int i=0;i<1000;i++) {
            outstandingMessageCount++;
            String message = "Hello World，this is No."+(i+1)+" news";
            channel.basicPublish("","order",null,message.getBytes(StandardCharsets.UTF_8));
            if(outstandingMessageCount==100){
                channel.waitForConfirmsOrDie(5_000);
                outstandingMessageCount=0;
            }
        }
        channel.close();
        connection.close();
        long timeEnd = System.currentTimeMillis();
        System.out.println("花费时间："+(timeEnd-timeStart));
    }
}
花费时间：388
```

**总结：**

这种方式可以稍微缓解下发送者确认模式对吞吐量的影响。但是也有个固有的问题，当确认出现异常时，发送者只能知道是这一批消息出问题了， 而无法确认具体是哪一条消息出了问题。所以接下来就需要增加一个机制能够具体对每一条发送出错的消息进行处理。

#### ③.异步确认消息

实现的方式也比较简单，Producer在channel中注册监听器来对消息进行确认。

核心代码就是一个：



```java
/**
 * sequenceNumer：
 *        这个是一个唯一的序列号，代表一个唯一的消息。
 *        在RabbitMQ中，他的消息体只是一个二进制数组，并不像RocketMQ一样有一个
 *        封装的对象，所以默认消息是没有序列号的。而RabbitMQ提供了一个方法int
 *        sequenceNumber = channel.getNextPublishSeqNo());来生成一个全局
 *        递增的序列号。然后应用程序需要自己来将这个序列号与消息对应起来。没错！
 *        是的！需要客户端自己去做对应！
 * multiple：
 *          这个是一个Boolean型的参数。如果是true，就表示这一次只确认了
 *         当前一条消息。如果是false，就表示RabbitMQ这一次确认了一批消息，在
 *         sequenceNumber之前的所有消息都已经确认完成了。
 */
ConfirmCallback cleanOutstandingConfirms = (sequenceNumber, multiple) -> {
       if (multiple) {
            ConcurrentNavigableMap<Long, String> confirmed = outstandingConfirms.headMap(
                            sequenceNumber, true);
                    confirmed.clear();
                } else {
                        outstandingConfirms.remove(sequenceNumber);
                }
            };
channel.addConfirmListener(ConfirmCallback cleanOutstandingConfirms, ConfirmCallback var2);
```

按说监听只要注册一个就可以了，那为什么这里要注册两个呢？如果对照下RocketMQ的事务消息机制，这就很容易理解了。发送者在发送完消息后，就会执行第一个监听器callback1，然后等服务端发过来的反馈后，再执行第二个监听器callback2。

然后关于这个ConfirmCallback，这是个监听器接口，里面只有一个方法： voidhandle(long sequenceNumber, boolean multiple) throws IOException; 

## 8、Headers路由（额外）

在官网的体验示例中，还有一种路由策略并没有提及，那就是Headers路由。其实官网之所以没有过多介绍，就是因为这种策略在实际中用得比较少，但是在某些比较特殊的业务场景特别适用。

官网示例中的集中路由策略， direct,fanout,topic等这些Exchange，都是以routingkey为关键字来进行消息路由的，但是这些Exchange有一个普遍的局限就是都是只支持一个字符串的形式，而不支持其他形式。

Headers类型的Exchange就是一种忽略routingKey的路由方式。他通过Headers来进行消息路由。这个headers是一个键值对，发送者可以在发送的时候定义一些键值对，接受者也可以在绑定时定义自己的键值对。当键值对匹配时，对应的消费者就能接收到消息。匹配的方式有两种：

+ all：表示需要所有的键值对都满足才行。
+ any：表示只要满足其中一个键值就可以了。

而这个值，可以是List、Boolean等多个类型。

例如我们收集应用日志时，如果需要实现按Log4j那种向上收集的方式，就可以使用这种Headers路由策略。

日志等级分为 debug - info - warning - error四个级别。而针对四个日志级别，按四个队列进行分开收集，收集时，每个队列对应一个日志级别，然后收集该日志级别以上级别的所有日志(包含当前日志级别)。像这种场景，就比较适合使用Headers路由机制。

```java
    //声明Binding
//绑定header中txtyp=1的队列。header的队列匹配可以用mathces和exisits
@Bean
public Binding bindHeaderTxTyp1() {
    return BindingBuilder.bind(headQueueTxTyp1())
        .to(setHeaderExchange()).where("txTyp").matches("1");
}
//绑定Header中busTyp=1的队列。
@Bean
public Binding bindHeaderBusTyp1() {
    return BindingBuilder.bind(headQueueBusTyp1())
        .to(setHeaderExchange()).where("busTyp").matches("1");
}
//绑定Header中txtyp=1或者busTyp=1的队列。
@Bean
public Binding bindHeaderTxBusTyp1() {
    Map<String, Object> condMap = new HashMap<>();
    condMap.put("txTyp", "1");
    condMap.put("busTyp", "1");
  //return BindingBuilder.bind(headQueueTxBusTyp())
  //    .to(setHeaderExchange()).whereAny(new String[] {"txTyp","busTyp"}).exist();
    return BindingBuilder.bind(headQueueTxBusTyp())
        .to(setHeaderExchange()).whereAll(condMap).match();
}
```

---



# 六、Springbooot集成RabbitMQ

+ SpringBoot官方就集成了RabbitMQ，所以RabbitMQ与SpringBoot的集成是非常简单的。

+ SpringBoot集成RabbitMQ的方式是按照Spring的一套统一的MQ模型创建的，因此SpringBoot集成插件中对于生产者、消息、消费者等重要的对象模型，与RabbitMQ原生的各个组件有对应关系，但是并不完全相同。

## 1、引入依赖

SpringBoot官方集成了RabbitMQ，只需要快速引入依赖包即可使用。RabbitMQ与SpringBoot集成的核心maven依赖就下面一个。

```java
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

注意：不同版本下，Springboot采用的配置方式会有变化。

## 2、配置文件application.properties

在application.properties配置支撑rabbitmq基础的配置。

所有配置均以spring.rabbitmq开头。

```java
server.port=8080
spring.rabbitmq.host=192.168.147.135
spring.rabbitmq.port=5672
spring.rabbitmq.username=admin
spring.rabbitmq.password=123456
spring.rabbitmq.virtual-host=/mirror
```

注意：如果需要更详细的配置资料，那就需要到官方的github仓库上去查了。

## 3、配置生产者

基础的运行环境参数以及生产者的一些默认属性配置都集中到了application.properties配置文件中。所有配置项都以spring.rabbitmq开头。

## 4、声明队列

所有的exchange, queue, binding的配置，都需要以对象的方式声明。默认情况下，这些业务对象一经声明，应用就会自动到RabbitMQ上常见对应的业务对象。但是也是可以配置成绑定已有业务对象的。

```java
@Configuration
public class FanoutConfig {
	//声明队列
	@Bean
	public Queue fanoutQ1() {
		return new Queue(MyConstants.QUEUE_FANOUT_Q1);
	}
	//声明exchange
	@Bean
	public FanoutExchange setFanoutExchange() {
		return new FanoutExchange(MyConstants.EXCHANGE_FANOUT);
	}
	//声明Binding,exchange与queue的绑定关系
	@Bean
	public Binding bindQ1() {
		return BindingBuilder.bind(fanoutQ1()).to(setFanoutExchange());
	}

}

```

## 5、使用RabbitmqTemplate对象发送消息

生产者的所有属性都已经在application.properties配置文件中进行配置。项目启动时，就会在Spring容器中初始化一个RabbitmqTemplate对象，然后所有的发送消息操作都通过这个对象来进行。

```java
@RestController
public class ProducerController {

    @Autowired
    private RabbitTemplate rabbitTemplate;
    @Autowired
    private Queue directQueue;
    
    @ApiOperation(value="direct发送接口",notes="直接发送到队列。task模式")
    @GetMapping(value="/directSend")
    public Object sendMessage(String message) throws UnsupportedEncodingException {
        MessageProperties messageProperties = new MessageProperties();
        messageProperties.setContentType(MessageProperties.CONTENT_TYPE_TEXT_PLAIN);
        messageProperties.setPriority(2);
        rabbitTemplate.setMessageConverter(new Jackson2JsonMessageConverter());
        System.out.println(new Message(message.getBytes(StandardCharsets.UTF_8),messageProperties));
        //发消息
        rabbitTemplate.send(directQueue.getName(),new Message(message.getBytes("UTF-8"),messageProperties));
        return "message sended : "+message;
    }

}
```

## 6.使用@RabbitListener注解声明消费者

消费者都是通过@RabbitListener注解来声明。注解中包含了声明消费者队列时所需要的重点参数。

对照原生API，这些参数就不难理解了。

```java
@Component
public class DirectReceiver {

   @RabbitListener(queues=MyConstants.QUEUE_DIRECT)
   public void directReceive2(String message) {
      System.out.println("consumer2 received message : " +message);
   }
   //直连模式的多个消费者，会分到其中一个消费者进行消费。类似task模式
   //通过注入RabbitContainerFactory对象，来设置一些属性，相当于task里的channel.basicQos
   @RabbitListener(queues=MyConstants.QUEUE_DIRECT,containerFactory="qos_4")
   public void directReceive22(Message message, Channel channel, String messageStr) {
      System.out.println("consumer1 received message : " +messageStr);
   }
	//quorum
   @RabbitListener(queues = MyConstants.QUEUE_QUORUM)
   public void quorumReceiver(String message){
      System.out.println("quorumReceiver received message : "+ message);
   }
	//stream
   @RabbitListener(queues = MyConstants.QUEUE_STREAM)
   public void stremReceiver(Channel channel, String message){
      try {
         channel.basicQos(1);
         Consumer myconsumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope,
                                 AMQP.BasicProperties properties, byte[] body)
                  throws IOException {
               System.out.println("========================");
               String routingKey = envelope.getRoutingKey();
               System.out.println("routingKey >"+routingKey);
               String contentType = properties.getContentType();
               System.out.println("contentType >"+contentType);
               long deliveryTag = envelope.getDeliveryTag();
               System.out.println("deliveryTag >"+deliveryTag);
               System.out.println("content:"+new String(body,"UTF-8"));
               // (process the message components here ...)
               //消息处理完后，进行答复。答复过的消息，服务器就不会再次转发。
               //没有答复过的消息，服务器会一直不停转发。
               channel.basicAck(deliveryTag, false);
            }
         };

         Map<String,Object> consumeParam = new HashMap<>();
         consumeParam.put("x-stream-offset","last");
         channel.basicConsume(MyConstants.QUEUE_STREAM, false,consumeParam, myconsumer);
      } catch (IOException e) {
         e.printStackTrace();
      }
      System.out.println("quorumReceiver received message : "+ message);
   }
}
```

但是当要消费Stream队列时，还是要重点注意他的三个必要的步骤：

+ channel必须设置basicQos属性。channel对象可以在@RabbitListener声明的消费者方法中直接引用，Spring框架会进行注入。
+ 正确声明Stream队列。 通过往Spring容器中注入Queue对象的方式声明队列。在Queue对象中传入声明Stream队列所需要的参数。
+ 消费时需要指定offset。 可以通过注入Channel对象，使用原生API传入offset属性。

总结：使用SpringBoot框架集成RabbitMQ后，开发过程可以得到很大的简化，所以使用过程并不难，对照一下示例就能很快上手。但是需要理解一下的是，SpringBoot集成后的RabbitMQ中的很多概念，虽然都能跟原生API对应上，但是这些模型中间都是做了转换，比如Message，就不是原生RabbitMQ中的消息了。使用SpringBoot框架，尤其需要加深对RabbitMQ原生API的理解，这样才能以不变应万变，深入理解各种看起来简单，但是其实坑很多的各种对象声明方式。

---



# 七、关于Stream队列

在目前版本下，使用RabbitMQ的SpringBoot框架集成，可以正常声明Stream队列，往Stream队列发送消息，但是无法直接消费Stream队列了。

关于这个问题，还是需要从Stream队列的三个重点操作入手。SpringBoot框架集成RabbitMQ后，为了简化编程模型，就把channel，connection等这些关键对象给隐藏了，目前框架下，无法直接接入这些对象的注入过程，所以无法直接使用。

如果非要使用Stream队列，那么有两种方式：

+ 一种是使用原生API的方式，在SpringBoot框架下自行封装。
+ 另一种是使用RabbitMQ的Stream 插件。在服务端通过Strem插件打开TCP连接接口，并配合单独提供的Stream客户端使用。这种方式对应用端的影响太重了，并且并没有提供与SpringBoot框架的集成，还需要自行完善，因此选择使用的企业还比较少。

关于Stream插件的使用和配置方式参见官方文档：https://www.rabbitmq.com/stream.html。

配合Stream插件使用的客户端有Java和GO两个版本。

其中Java版本客户端参见git仓库：https://github.com/rabbitmq/rabbitmq-stream-java-client 。

---



# 八、SpringCloudStream

SpringCloudStream 是一个构建高扩展和事件驱动的微服务系统的框架，用于连接共有消息系统，官网地址： https://spring.io/projects/spring-cloud-stream。

整体上是把各种花里胡哨的MQ产品抽象成了一套非常简单的统一的编程框架，以实现事件驱动的编程模型。社区官方实现了RabbitMQ、Apache Kafka、Kafka、Stream和Amazon Kinesis这几种产品，而其他还有很多产品比如RocketMQ，都是由产品方自行提供扩展实现。

所以可以看到，对于RabbitMQ，使用SpringCloudStream框架算是一种比较成熟的集成方案。但是需要主要注意的是，SpringCloudStream框架集成的版本通常是比RabbitMQ落后几个版本的，使用时需要注意。

SpringCloudStream框架封装出了三个最基础的概念来对各种消息中间件提供统一的抽象：

+ Destination Binders：负责集成外部消息系统的组件。

+ Destination Binding：由Binders创建的，负责沟通外部消息系统、消息发送者和消息消费者的桥梁。

+ Message：消息发送者与消息消费者沟通的简单数据结构。

可以看到，这个模型非常简单，使用时也会非常方便。但是简单，意味着SCStream中的各种概念模型，与RabbitMQ的基础概念之间是有比较大的差距的，例如Exchange、Queue这些原生概念，集成到SCStream框架时，都需要注意如何配置，如何转换。

## 1、集成方式

### 1.引入依赖

RabbitMQ的SpringCloudStream支持是由Spring社区官网提供的，所以这也是相当成熟的一种集成方案。但是要注意，SpringCloudStream框架集成的版本通常是比RabbitMQ产品本身落后几个版本的，使用时需要注意。

核心依赖：

```
<dependency> 
	<groupId>org.springframework.cloud</groupId> 
	<!-- artifactId>spring-cloud-starter-stream-rabbit</artifactId --> 
	<artifactId>spring-cloud-stream-binder-rabbit</artifactId> 
</dependency> 
```

这两个Maven依赖没有什么特别大的区别，实际上，他们的github代码库是在一起的。

仓库地址：https://github.com/spring-cloud/springcloud-stream-binder-rabbit

### 2.基础使用方法

使用SCStream框架集成RabbitMQ，编程模型非常的简单。我们先在本地搭建一个RabbitMQ服务，

按照以下三步就可以完成与RabbitMQ的对接：

1. 声明Sink消息消费者

```java
@Component 
@EnableBinding(Sink.class) 
public class MessageReceiver { 
private Logger logger = LoggerFactory.getLogger(MessageReceiver.class); @EventListener @StreamListener(Sink.INPUT) 
public void process(Object message) { 
	System.out.println("received message : " + message);
    logger.info("received message : {}", message); 
    }
}
```

2. 使用Source 消息生产者发送消息

   ```java
   @Component 
   @EnableBinding(Source.class) 
   public class MessageSender { 
   	@Autowired 
   	private Source source; 
   	public void sendMessage(Object message) {
       	MessageBuilder<Object> builder = MessageBuilder.withPayload(message); 				source.output().send(builder.build()); 
       } 
   }
   ```

3. 在SpringBoot的配置文件中增加配置

   ```
   server.port=8080 
   spring.cloud.stream.bindings.output.destination=streamExchange spring.cloud.stream.bindings.input.destination=streamExchange spring.cloud.stream.bindings.input.group=stream spring.cloud.stream.bindings.input.content-type=text/plain
   ```

   这样三个步骤，就完成了与本地RabbitMQ的对接。

4. 增加SpringBoot启动类，以及测试用的Controller启动测试。

   ```java
   @RestController //@EnableBinding(Source.class) 
   public class SendMessageController { 
   	@Autowired 
   	private Source source; 
   	
   	@GetMapping("/send") 
   	public Object send(String message) {
       	MessageBuilder<String> messageBuilder = MessageBuilder.withPayload(message); 		 source.output().send(messageBuilder.build()); 
       	return "message sended : "+message; 
       } 
   }
   ```

   启动应用后，访问Controller提供的测试端口 http://localhost:8080/send?message=123 。后台就能收到这个消息。

   这里可以看到，当前消费者不光收到了MQ消息，还收到了一些系统事件。这些系统事件需要添加@EventListener注解才能接收到。

### 3.SCStream干了什么

非常简单的几行代码，你甚至都不需要感知RabbitMQ的存在，就完成了与RabbitMQ的对接。但是，简单的背后，意味着，如果你要深入使用更多功能，需要有更扎实的技术基础，对SpringCloudStream有更深入的了解。

我们先来了解下，在刚才的简单示例当中，SpringCloudStream都干了些什么事情。

#### 1.配置RabbitMQ服务器

在SpringBoot的autoconfigure包当中，有个 RabbitProperties类，这个类就会解析application.properties中以spring.rabbitmq开头的配置。里面配置了跟RabbitMQ相关的主要参数，包含服务器地址等。里面对每个参数也都提供了默认值。默认就是访问本地的RabbitMQ服务。

```java
#这几个是默认配置。 
spring.rabbitmq.host=localhost 
spring.rabbitmq.port=5672 
spring.rabbitmq.username=guest 
spring.rabbitmq.password=guest 
spring.rabbitmq.virtual-host=/
```

#### 2.在RabbitMQ中声明Exchange和Queue

+ 既然是要对接RabbitMQ，那么最终还是需要与RabbitMQ服务器进行交互的。
+ 从RabbitMQ的管理页面上来看，SCStream帮我们在RabbitMQ的根虚拟机上创建了一个topic类型的scstreamExchange交换机，然后在这个交换机上绑定了一个scstreamExchange.stream队列，绑定的RoutingKey是#。 而程序中的消息发送者是将消息发送到scstreamExchange交换机，然后RabbitMQ将消息转发到scstreamExchange.stream队列，消息接收者从队列接收到消息。
+ 这个流程，就是Spring Cloud Stream在背后为我们做的事情。 在这里可以尝试对应RabbitMQ的基础概念以及SCStream框架中的基础概念，整理一下他们之间的对应关系。

其实这个示例也演示了SCStream的特点。SCStream框架帮我们屏蔽了与消息中间件的交互细节，开发人员甚至都不需要感知消息中间件的存在，将更多的关注点放到业务处理的细节里。

实际上，就我们这个简单的示例，只需要将maven中的spring-cloud-starter-stream-rabbit依赖，换成spring-cloud-starter-streamkafka，就可以完成与本地Kafka服务的交互，代码不需要做任何的改动。

### 4.SCStream高级

这里需要注意，SCStream框架的设计目的，是为了实现一套简明的事件驱动模型。在这个事件驱动模型中，是没有RabbitMQ中这些Exchange、queue或者是kafka中的Topic之类的这些功能的，所以这也意味着，如果想要使用RabbitMQ的一些特性功能，比如Quorum队列，死信队列，懒加载队列等，反而会比较麻烦。这就需要对各种基础概念有更深的了解。

#### ①.配置Binder

SCStream是通过Binder来定义一个外部消息服务器。具体对于RabbitMQ来说，Binder就是一个Exchange的抽象。默认情况下，RabbitMQ的binder使用了SpringBoot的ConnectionFactory，所以，他也支持spring-boot-starter-amqp组件中提供的对RabbitMQ的所有配置信息。这些配置信息在application.properties里都以spring.rabbitmq开头。

而在SCStream框架中，也支持配置多个Binder访问不同的外部消息服务器(例如同时访问kafka和rabbitmq，或者同时访问rabbitmq的多个virtual-host)，就可以通过Binder进行定义。配置的方式都是通过spring.cloud.stream.binders.[bindername].environment.[props]=[value]的格式来进行配置。另外，如果配置

了多个binder，也可以通过spring.cloud.stream.default-binder属性指定默认的binder。

例如：

```java
#配置多个binder
spring.cloud.stream.default-binder=rabbit1
spring.cloud.stream.binders.rabbit1.type=rabbit
spring.cloud.stream.binders.rabbit1.environment.spring.rabbitmq.host=192.168.147.135
spring.cloud.stream.binders.rabbit1.environment.spring.rabbitmq.port=5672
spring.cloud.stream.binders.rabbit1.environment.spring.rabbitmq.username=admin
spring.cloud.stream.binders.rabbit1.environment.spring.rabbitmq.password=123456
spring.cloud.stream.binders.rabbit1.environment.spring.rabbitmq.virtual-host=/mirror

spring.cloud.stream.binders.rabbit2.type=rabbit
spring.cloud.stream.binders.rabbit2.environment.spring.rabbitmq.host=192.168.147.136
spring.cloud.stream.binders.rabbit2.environment.spring.rabbitmq.port=5672
spring.cloud.stream.binders.rabbit2.environment.spring.rabbitmq.username=admin
spring.cloud.stream.binders.rabbit2.environment.spring.rabbitmq.password=123456
```

这个配置方式就配置了一个名为testbinder的Binder。

#### ②.Binding配置

Binding是SCStream中实际进行消息交互的桥梁。在RabbitMQ中，一个binding可以对应消费者的一个queue，在发送消息时，也可以直接对应一个exchange。在SCStream中，就是通过将Binding和Binder建立绑定关系，然后客户端就之需要通过Binding来进行实际的消息收发。

在SCStream框架中，配置Binding首先需要进行声明。声明Binding的方式是在应用中通过@EnableBinding注解，向Spring容器中逐日一个Binding接口对象。在这个接口中，增加@Input注解指定接收消息的Binding，而通过@Output注解指定发送消息的Binding。

在SCStream中，默认提供了**Source、Sink、Processor**三个接口对象，这三个对象都是简单的接口，可以直接拿来使用，当然也可以配置自己的Binding接口对象。

比如Source，他的定义就是这样的：

```java
public interface Source { 
	String OUTPUT = "output"; 
	@Output(Source.OUTPUT) 
	MessageChannel output(); 
}
```

```java
public interface Sink {
    String INPUT = "input";

    @Input("input")
    SubscribableChannel input();
}
```

```java
public interface Processor extends Source, Sink {
}
```

通过这个@Output直接，就声明出了一个Binding对象，他的名字就叫做output，对于RabbitMQ，就对应一个queue，**SCStream就会将这个output声明为一个消息发送队列。**

接下来就可以在应用中使用@EnableBinding(Source.class)，声明这个Binding对象。接下来，就可以在Spring应用中使用@Autowired注入，然后**通过source.output()方法获取到MesasgeChannel对象**，进而发送消息了。

```java
@Component
@EnableBinding({Source.class, Processor.class})
public class MessageSender {

    @Autowired
    private Source source;
    public void sendMessage(Object message) {
        MessageBuilder<Object> builder = MessageBuilder.withPayload(message);           		source.output().send(builder.build());
    }
}
```

注意：**如果不对output这个Binding做任何配置，应用启动后，会在RabbitMQ中声明出一个默认的exchange和queue。**但是默认的名字都太奇怪，而且很多细节功能不够好用。所以，通常都会对这个Binding进行配置。配置的方式都是在application.properties中配置。所有配置都是按照

**spring.cloud.stream.binding.[bindingname].[props]=[value]**的格式进行指定。例如：

```java
spring.cloud.stream.bindings.output.destination=scstreamExchange spring.cloud.stream.bindings.output.group=myoutput spring.cloud.stream.bindings.output.binder=testbinder
```

这样就指定了output这个Binding对应的Exchange。

注意：

1、如果不希望每个Binding都单独指定Binder，就可以配置默认的Binder。

```java
spring.cloud.stream.default-binder=rabbit1
spring.cloud.stream.binders.rabbit1.type=rabbit
...
```

2、对于binding，可以指定group所属组的属性。Group这个概念在RabbitMQ中是不存在的，但是SCStream会按照这个group属性，声明一个名为scstreamExchange.myoutput的queue队列，并与scstreamExchange建立绑定关系。

```java
spring.cloud.stream.bindings.output.destination=streamExchange
spring.cloud.stream.bindings.input.destination=streamExchange
#指定group所属组的属性
spring.cloud.stream.bindings.input.group=stream
spring.cloud.stream.bindings.input.content-type=text/plain
```

#### ③.SCStream的分组消费策略

通过Binding，即可以声明消息生产者，也可以声明消息消费者。基础的配置方式是差不多的。参见之前的示例，不难理解。下面重点来看下这个group组属性。消费者组的概念，在RabbitMQ中是不存在的。但是，如果你接触过Kafka或者RocketMQ，那么对于组，你就不会陌生了。

**SCStream中的消费者分组策略**，其实整体来看是一种类似于Kafka的分组消费机制。**即不同group的消费者，都会消费到所有的message消息，而在同一个goup中，每个message消息，只会被消费一次。**这种分组消费的策略，严格来说，在RabbitMQ中是不存在的，RabbitMQ是通过不同类型的Exchange来实现不同的消费策略。而使用SCStream框架，就可以直接在RabbitMQ中实现这种分组消费的策略。

```java
spring.cloud.stream.function.definition=echo;input;consumer;gather;gatherEcho
spring.cloud.stream.bindings.input-in-0.destination=scstreamExchange
spring.cloud.stream.bindings.echo-in-0.destination=scstreamExchange
spring.cloud.stream.bindings.consumer-in-0.destination=scstreamExchange2
spring.cloud.stream.bindings.echo-out-0.destination=scstreamExchange2

spring.cloud.stream.bindings.input-in-0.group=myinput1
spring.cloud.stream.bindings.echo-in-0.group=echo
spring.cloud.stream.bindings.consumer-in-0.group=consumers
spring.cloud.stream.bindings.echo-out-0.group=consumers
```

例如这样，就声明了两个消费者组。consumer、echo是一个组(consumers)，input（myinput1），echo（echo）。接下来，可以自行验证一下消息的分发过程。

```java
@Configuration
public class Subscriber {
    //注入Consumer方法就可以自动声明Consumer对应的binding了。binding的名字是input-in-0
    //input对应方法名，in表示是Consumer,后面的0表示数据流中只有单数据输入。
    @Bean
    public Consumer<String> input(){
        return message -> {
            System.out.println("received message from input binding ; message = 					"+message);
        };
    }

    //Function方式声明binding，相当于同时声明了一个Producer的Bindng和一个Consumer的Binding。echo-	in-0 表示消费者  echo-out-0 表示生产者
    //其作用就在于，如果同时配置了echo-in-0和echo-out-0，那么echo-in-0收到的消息，立即就会通过echo-		out-0发送出去。
    @Bean
    public Function<String,String> echo(){
        return message -> {
            System.out.println("echo: "+message);
            return "echo:"+message;
        };
    }

    @Bean
    public Consumer<String> consumer(){
        return message -> {
            System.out.println("received message from echo2 binding ; message = 					"+message);
        };
    }
}
```

对于这种分组消费的策略，SCStream框架不光提供了实现，同时还提供了扩展。可以对每个组进行分区(partition，是不是感觉越来越像Kafka了？)。

例如做这样的配置

```java
#消息生产者端配置 
#启动发送者分区 
spring.cloud.stream.bindings.output.producer.partitioned=true 
#指定参与消息分区的消费端节点数量 
spring.cloud.stream.bindings.output.producer.partition-count=2 
#只有消费端分区ID为1的消费端能接收到消息 
spring.cloud.stream.bindings.output.producer.partition-key-expression=1 

#消息消费者端配置
#启动消费分区 
spring.cloud.stream.bindings.input.consumer.partitioned=true 
#参与分区的消费端节点个数 
spring.cloud.stream.bindings.input.consumer.instance-count=2 
#设置该实例的消费端分区ID 
spring.cloud.stream.bindings.input.consumer.instance-index=1
```

通过这样的分组策略，当前这个消费者实例就只会消费奇数编号的消息，而偶数编号的消息则不会发送到这个消费者中。

**注意：**这并不是说偶数编号的消息就不会被消费，只是不会被当前这个实例消费而已。

**总结：**

SCStream框架虽然实现了这种分组策略机制，但是其实是不太严谨的，当把分区数量和分区ID不按套路分配时，并没有太多的检查和日志信息，但是就是收不到消息。另外，在@StreamListener注解中还有condition属性也可以配置消费者的分配逻辑，该属性支持一个SPELl表达式，只接收满足条件的消息。

#### ④.使用原生消息转发机制

SCStream其实自身实现了一套事件驱动的流程。这种流程，对于各种不同的MQ产品都是一样的。但是毕竟每个MQ产品的实现机制和功能特性是不一样的，所以，SCStream还是提供了一套针对各个MQ产品的兼容机制。

在RabbitMQ的实现中，所有个性化的属性配置实现都是以spring.cloud.stream.rabbit开头，支持对binder、producer、consumer进行单独配置。

```java
#绑定exchange 
spring.cloud.stream.binding.<bindingName>.destination=fanoutExchange 
#绑定queue 
spring.cloud.stream.binding.<bindingName>.group=myQueue 
#不自动创建
queue spring.cloud.stream.rabbit.bindings.<bindingName>.consumer.bindQueue=false 
#不自动声明exchange(自动声明的exchange都是topic) 
spring.cloud.stream.rabbit.bindings. <bindingName>.consumer.declareExchange=false
#队列名只声明组名(前面不带destination前缀) 
spring.cloud.stream.rabbit.bindings. <bindingName>.consumer.queueNameGroupOnly=true
#绑定rouytingKey 
spring.cloud.stream.rabbit.bindings.<bindingName>.consumer.bindingRoutingKey=myRoutingKey #绑定exchange类型
spring.cloud.stream.rabbit.bindings.<bindingName>.consumer.exchangeType= <type> 
#绑定routingKey 
spring.cloud.stream.rabbit.bindings.<bindingName>.producer.routingKeyExpression='myRoutingKey'
```

通过这些配置可以按照RabbitMQ原生的方式进行声明。例如，SCStream自动创建的Exchange都是Topic类型的，如果想要用其他类型的Exchange交换机，就可以手动创建交换机，然后在应用中声明不自动创建交换机。

所有可配置的属性，参见github仓库中的说明。例如，如果需要声明一个Quorum仲裁队列，那么只要给这个Binding配置quorum.enabled属性，值为true就可以了。

**注意：**Stream队列目前尚不支持。RabbitMQ周边生态的发展肯定是比产品自身的发展速度要慢的，由此也可见，目前阶段，Stream队列离大规模使用还是有一点距离的。

#### ⑤.使用SCStream配置死信队列

死信(Dead letter)队列是RabbitMQ中的一个高级功能，所谓死信，就是长期没有人消费的消息。

RabbitMQ中有以下几种情况会产生死信：

+ 消息被拒绝(basic.reject/baskc.nack)并且设置消息不重新返回队列 (配置spring.rabbitmq.listener.default-requeue-rejected=true/false 。这个属性默认是true，就是消息处理失败后，就会重新返回队列，后续重新投递。但是这里需要注意，如果队列已经满了，那就会循环不断的报错，这时候就要考虑死信了)

+ 队列达到最大长度

+ 消息TTL过期

RabbitMQ的死信队列实现机制，是在正常队列上声明一个死信交换机dlExchange，然后这个死信交换机dlExchange可以像正常交换机Exchange一样，去绑定队列，分发消息等。其配置方式，就是在队列中增加声明几个属性来指定死信交换机。而这几个队列属性，即可以在服务器上直接配置，也可以用原生API配置，还可以用SpringBoot的方式声明Queue队列来实现，并且在SCStream框架中也支持定制。主要就是这几个属性：

```
x-dead-letter-exchange: mirror.dlExchange 对应的死信交换机 
x-dead-letter-routing-key: mirror.messageExchange1.messageQueue1 死信交换机 
routing-key 
x-message-ttl: 3000 消息过期时间 
durable: true 持久化，这个是必须的。
```

配置完成后，在管理页面也能看到队列信息：

![img}](https://github.com/hepengjun2022/doc-java/blob/master/pic/SCStream%E6%AD%BB%E4%BF%A1%E4%BA%A4%E6%8D%A2%E6%9C%BA.png?raw=true)

这样配置完成后，在当前队列中的消息，经过3秒无人消费，就会通过指定的死信交换机mirror.dlExchange，分发到对应的死信队列中。

关于如何配置这些属性，在之前声明Quorum仲裁队列和Stream队列时，都有说明。

而在SCStream框架中，就可以通过以下的方式进行配置：

```java
spring.cloud.stream.rabbit.bindings.input.destination=DlqExchange spring.cloud.stream.rabbit.bindings.input.group=dlQueue spring.cloud.stream.rabbit.bindings.output.destination=messageExchange1 spring.cloud.stream.rabbit.bindings.output.producer.required- groups=messageQueue1 spring.cloud.stream.rabbit.rabbit.bindings.output.producer.autoBindDlq=true spring.cloud.stream.rabbit.rabbit.bindings.output.producer.ttl=3000 spring.cloud.stream.rabbit.rabbit.bindings.output.producer.deadLetterExchang e=DlqExchange spring.cloud.stream.rabbit.rabbit.bindings.output.producer.deadLetterQueueNa me=DlqExchange.dlQueue
```

#### ⑥.扩展的事件监听机制

另外，在SCStream框架的Sink消费者端，还可以添加@EventListener注解。加入这个注解后，这个Sink消费者，不光可以消费MQ消息，还能监控很多Spring内的事件，像 AsyncConsumerStartedEvent、ApplicationReadyEvent(springBoot启动事件)、ServletRequestHandledEvent(请求响应事件)等等。而使用这些功能，我们可以将Spring的应用事件作为业务事件一样处理，这对于构建统一的Spring应用监控体系是非常有用的。

#### ⑦.SCStream框架总结

对于事件驱动这个应用场景来说，SCStream框架绝对是一个举足轻重的产品。

一方面，他极大的简化的事件驱动的开发过程，让技术人员可以减少对于不同MQ产品的适应过程，更多的关注业务逻辑。

另一方面，SCStream框架对各种五花八门的MQ产品提供了一种统一的实现流程，从而可以极大的减少应用对于具体MQ产品的依赖，极大提高应用的灵活性。例如如果应用某一天想要从RabbitMQ切换成Kafka或者RocketMQ等其他的MQ产品，如果采用其他框架，需要对应用程序做非常大的改动。但是，如果使用SCStream框架，那么基本上就是换Maven依赖，调整相关配置就可以了。应用代码基本不需要做任何改动。

当然，SCStream框架使用非常方便的背后，也意味着更高的学习门槛。如果只是最简单的使用MQ产品，那你当然可以不用感知MQ产品的存在，就用SCStream框架进行快速的开发。但是，当你需要深入的使用MQ产品时，那就不光需要学习MQ产品本身，还需要学习具体MQ产品模型如何与SCStream的基础模型对应以及转换。这其实对技术反而提出了更高的要求。所以SCStream在一些技术非常扎实的。

---



# 九、分组消费模式详解

## 1、分组消费概念

我们回顾下RabbitMQ的消费模式，Exchange与Queue之间的消息路由都是通过RoutingKey关键字来进行的，不同类型的Exchange对RoutingKey进行不同的处理。那有没有不通过RoutingKey来进行路由的策略呢？

在RabbitMQ产品当中，确实没有这样的路由策略，但是在SpringCloudStream框架对RabbitMQ进行封装时，提供了一个这种策略，即分区消费策略。

+ 这种策略很类似于kafka的分组消费策略。

+ 在kafka中的分组策略，是不同的group，都会消费到同样的一份message副本，而在同一个group中，只会有一个消费者消费到一个message。这种分组消费策略，严格来说，在Rabbit中是不存在的。

+ RabbitMQ是通过不同类型的exchange来实现不同的消费策略的。这虽然与kafka的这一套完全不同，但是在SpringCloudStream针对RabbitMQ的实现中，可以很容易的看到kafka这种分组策略的影子。

当有多个消费者实例消费同一个bingding时，Spring Cloud Stream同样是希望将这种分组策略，移植到RabbitMQ中来的。就是在不同的group中，会同样消费同一个Message，而在同一个group中，只会有一个消费者消息到一个Message。

## 2、实例配置

要使用分组消费策略，需要在生产者和消费者两端都进行分组配置。

### 1.生产者端核心配置

```java
#指定参与消息分区的消费端节点数量 
spring.cloud.stream.bindings.output.producer.partition-count=2 
#只有消费端分区ID为1的消费端能接收到消息 
spring.cloud.stream.bindings.output.producer.partition-key-expression=1
```

### 2.消费者端启动两个实例，组成一个消费者组

#### ①.消费者1核心配置

```
#启动消费分区 
spring.cloud.stream.bindings.input.consumer.partitioned=true 
#参与分区的消费端节点个数 
spring.cloud.stream.bindings.input.consumer.instance-count=2 
#设置该实例的消费端分区ID 
spring.cloud.stream.bindings.input.consumer.instance-index=1
```

#### ②.消费者2核心配置

```
#启动消费分区 
spring.cloud.stream.bindings.input.consumer.partitioned=true 
#参与分区的消费端节点个数 
spring.cloud.stream.bindings.input.consumer.instance-count=2 
#设置该实例的消费端分区ID 
spring.cloud.stream.bindings.input.consumer.instance-index=0
```

这样就完成了一个分组消费的配置。两个消费者实例会组成一个消费者组。而生产者发送的消息，只会被消费者1 消费到(生产者的partition-key-expression 和 消费者的 instance-index 匹配)。

## 3、实现原理

实际上，在跟踪查看RabbitMQ的实现时，就会发现，Spring Cloud Stream在增加了消费者端的分区设置后，会对每个有效的分区创建一个单独的queue，这个队列的队列名是在原有队列名后面加上一个索引值。而发送者端的消息，会最终发送到这个带索引值的队列上，而不是原队列上。这样就完成了分区消费。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E5%88%86%E7%BB%84%E6%B6%88%E8%B4%B9%E5%AE%9E%E7%8E%B0%E5%9B%BE%E8%A7%A3.png?raw=true)

我们的示例中，分组表达式是直接指定的，这样其实是丧失了灵活性的。实际开发中，可以将这个分组表达式放到消息的header当中，在发送消息时指定，这样就更有灵活性了。

例如：将生产者端的分组表达式配置为header['partitonkey']

```
#生产者端设置 spring.cloud.stream.bindings.output.producer.partition-key- expression=header['partitionkey']
```

在发送消息时，给消息指定一个header属性来控制控制分组消费的结果。

```
Message message = MessageBuilder.withPayload(str).setHeader("partitionKey", 0).build(); source.output().send(message);
```

## 4、总结

分组消费策略是在原有路由策略上的一个补充，在实际生产中也是经常会用到的一种策略。并且，MQ的使用场景是非常多的，这也意味着，不管MQ产品设计得如何完善，在复杂场景下，往往都不可能满足所有的使用要求。这时，如果想要自行设计一些更灵活的使用方式，那么这种分组消费的模式就是一个很好的示例。

# 十、RabbitMQ生产环境

## 1、如何保证消息不丢失？

这是面试时最喜欢问的问题，其实这是个所有MQ的一个共性的问题，大致的解决思路也是差不多的，但是针对不同的MQ产品会有不同的解决方案。而RabbitMQ设计之处就是针对企业内部系统之间进行调用设计的，所以他的消息可靠性是比较高的。

### 1.哪些环节会有丢消息的可能？

我们考虑一个通用的MQ场景：

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E6%B6%88%E6%81%AF%E4%B8%A2%E5%A4%B1%E9%97%AE%E9%A2%98.png?raw=true)

**1，2，4：**

三个场景都是跨网络的，而跨网络就肯定会有丢消息的可能。

**3：**

通常MQ存盘时都会先写入操作系统的缓存page cache中，然后再由操作系统异步的将消息写入硬盘。这个中间有个时间差，就可能会造成消息丢失。如果服务挂了，缓存中还没有来得及写入硬盘的消息就会丢失。这也是任何用户态的应用程序无法避免的。

**注意：对于任何MQ产品，都应该从这四个方面来考虑数据的安全性。那我们看看用RabbitMQ时要如何解决这个问题。**

### 2.RabbitMQ消息零丢失方案：

#### ①.生产者保证消息正确发送到RibbitMQ

**方式一：同步确认和异步确认**

对于单个数据，可以使用生产者确认机制。通过多次确认的方式，保证生产者的消息能够正确的发送到RabbitMQ中。

RabbitMQ的生产者确认机制分为同步确认和异步确认。同步确认主要是通过在生产者端使用Channel.waitForConfirmsOrDie()指定一个等待确认的完成时间。异步确认机制则是通过channel.addConfirmListener(ConfirmCallback var1,ConfirmCallback var2)在生产者端注入两个回调确认函数。

+ var1：是在生产者发送消息时调用。

+ var2：是生产者收到Broker的消息确认请求时调用。

两个函数需要通过sequenceNumber自行完成消息的前后对应。sequenceNumber的生成方式需要通过channel的序列获取。int sequenceNumber =channel.getNextPublishSeqNo()。

**方式二：手动事务**

在RabbitMQ中，另外还有一种手动事务的方式，可以保证消息正确发送。

手动事务机制主要有几个关键的方法： 

+ channel.txSelect() 开启事务；

+ channel.txCommit() 提交事务； 
+ channel.txRollback() 回滚事务； 

这种方式需要手动控制事务逻辑，并且手动事务会对channel产生阻塞，造成吞吐量下降。

#### ②.RabbitMQ消息存盘不丢消息

这个在RabbitMQ中比较好处理，对于Classic经典队列，直接将队列声明成为持久化队列即可。而新增的Quorum队列和Stream队列，都是明显的持久化队列，能更好的保证服务端消息不会丢失。

#### ③.RabbitMQ主从消息同时不丢消息

这涉及到RabbitMQ的集群架构。首先他的普通集群模式，消息是分散存储的，不会主动进行消息同步了，是有可能丢失消息的。而镜像模式集群，数据会主动在集群各个节点当中同步，这时丢失消息的概率不会太高。

另外，启用Federation联邦机制，给包含重要消息的队列建立一个远端备份，也是一个不错的选择。

#### ④.RabbitMQ消费者不丢失消息

RabbitMQ在消费消息时可以指定是自动应答，还是手动应答。如果是自动应答模式，消费者会在完成业务处理后自动进行应答，而如果消费者的业务逻辑抛出异常，RabbitMQ会将消息进行重试，这样是不会丢失消息的，但是有可能会造成消息一直重复消费。

将RabbitMQ的应答模式设定为手动应答可以提高消息消费的可靠性。

```java
DefaultConsumer consumer = new DefaultConsumer(channel) {
      @Override
      public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
            System.out.println("========================");
            String routingKey = envelope.getRoutingKey();
            System.out.println("routingKey >"+routingKey);
            String contentType = properties.getContentType();
            System.out.println("contentType >"+contentType);
            long deliveryTag = envelope.getDeliveryTag();
            System.out.println("deliveryTag >"+deliveryTag);
            System.out.println("content:"+new String(body,"UTF-8"));
            // (process the message components here ...)
            //消息处理完后，进行答复。答复过的消息，服务器就不会再次转发。
            //没有答复过的消息，服务器会一直不停转发。
            channel.basicAck(deliveryTag, false);
      }
};
channel.basicConsume("order",false,consumer);
```

另外这个应答模式在SpringBoot集成案例中，也可以在配置文件中通过属性spring.rabbitmq.listener.simple.acknowledge-mode 进行指定。

+ AUTO 自动应答； 
+ MANUAL 手动应答；
+ NONE 不应答；

其中这个NONE不应答，就是不启动应答机制，RabbitMQ只管往消费者推送消息后，就不再重复推送消息了，相当于RocketMQ的sendoneway， 这样效率更高，但是显然会有丢消息的可能。

最后，任何用户态的应用程序都无法保证绝对的数据安全，所以，备份与恢复的方案也需要考虑到。

## 2、如何保证消息幂等性？

### 1.RabbitMQ的自动重试功能

当消费者消费消息处理业务逻辑时，如果抛出异常，或者不向RabbitMQ返回响应，默认情况下，RabbitMQ会无限次数的重复进行消息消费。处理幂等问题，**首先要设定RabbitMQ的重试次数**。

在SpringBoot集成RabbitMQ时，可以在配置文件中指定spring.rabbitmq.listener.simple.retry开头的一系列属性，来制定重试策略。

**然后，需要在业务上处理幂等问题**。

处理幂等问题的关键是要给每个消息一个唯一的标识。

在SpringBoot框架集成RabbitMQ后，可以给每个消息指定一个全局唯一的MessageID，在消费者端针对MessageID做幂等性判断。关键代码：

```java
//发送者指定ID字段 
Message message2 =MessageBuilder.withBody(message.getBytes())
    .setMessageId(UUID.randomUUID().toString()).build(); 
rabbitTemplate.send(message2); 
//消费者获取MessageID，自己做幂等性判断 
@RabbitListener(queues = "fanout_email_queue") 
public void process(Message message) throws Exception { 
    // 获取消息Id 
    String messageId = message.getMessageProperties().getMessageId();
    ... 
}
```

在原生API当中，也是支持MessageId的。当然，在实际工作中，最好还是能够添加一个具有业务意义的数据作为唯一键会更好，这样能更好的防止重复消费问题对业务的影响。比如，针对订单消息，那就用订单ID来做唯一键。在RabbitMQ中，消息的头部就是一个很好的携带数据的地方。

```java
// ==== 发送消息时，携带sequenceNumber和orderNo 
AMQP.BasicProperties.Builder builder = new AMQP.BasicProperties.Builder(); builder.deliveryMode(MessageProperties.PERSISTENT_TEXT_PLAIN.getDeliveryMode()); builder.priority(MessageProperties.PERSISTENT_TEXT_PLAIN.getPriority());//携带消息ID 
builder.messageId(""+channel.getNextPublishSeqNo()); 
Map<String, Object> headers = new HashMap<>(); //携带订单号 
headers.put("order", "123"); 
builder.headers(headers); 
channel.basicPublish("", QUEUE_NAME, builder.build(), message.getBytes("UTF-8")); 
// ==== 接收消息时，拿到sequenceNumber 
Consumer myconsumer = new DefaultConsumer(channel) { 
    @Override 
    public void handleDelivery(String consumerTag, Envelope envelope, BasicProperties 								properties, byte[] body) throws IOException { 
        //获取消息ID 
        System.out.println("messageId:"+properties.getMessageId()); 
        //获取订单ID
        properties.getHeaders().forEach((key,value)-> System.out.println("key: "+key +"; 																	value: "+value)); 
        // (process the message components here ...) 
        //消息处理完后，进行答复。答复过的消息，服务器就不会再次转发。 
        //没有答复过的消息，服务器会一直不停转发。 
        channel.basicAck(deliveryTag, false);
    }
};
channel.basicConsume(QUEUE_NAME, false, myconsumer);
```

## 3、如何保证消息的顺序？

某些场景下，需要保证消息的消费顺序，例如一个下单过程，需要先完成扣款，然后扣减库存，然后通知快递发货，这个顺序不能乱。如果每个步骤都通过消息进行异步通知的话，这一组消息就必须保证他们的消费顺序是一致的。

在RabbitMQ当中，针对消息顺序的设计其实是比较弱的。唯一比较好的策略就是单队列+单消息推送。即一组有序消息，只发到一个队列中，利用队列的FIFO特性保证消息在队列内顺序不会乱。但是，显然，这是以极度消耗性能作为代价的，在实际适应过程中，应该尽量避免这种场景。

然后在消费者进行消费时，保证只有一个消费者，同时指定prefetch属性为1，即每次RabbitMQ都只往客户端推送一个消息。像这样：

```
spring.rabbitmq.listener.simple.prefetch=1
```

而在多队列情况下，如何保证消息的顺序性，目前使用RabbitMQ的话，还没有比较好的解决方案。在使用时，应该尽量避免这种情况。

## 4、关于RabbitMQ的数据堆积问题

RabbitMQ一直以来都有一个缺点，就是对于消息堆积问题的处理不好。当RabbitMQ中有大量消息堆积时，整体性能会严重下降。而目前新推出的Quorum队列以及Stream队列，目的就在于解决这个核心问题。但是这两种队列的稳定性和周边生态都还不够完善，因此，在使用RabbitMQ时，还是要非常注意消息堆积的问题。尽量让消息的消费速度和生产速度保持一致。

而如果确实出现了消息堆积比较严重的场景，就需要从数据流转的各个环节综合考虑，设计适合的解决方案。

+ 消息生产者端：

对于生产者端，最明显的方式自然是降低消息生产的速度。但是，生产者端产生消息的速度通常是跟业务息息相关的，一般情况下不太好直接优化。但是可以选择尽量多采用批量消息的方式，降低IO频率。

+ 在RabbitMQ服务端：

从前面的分享中也能看出，RabbitMQ本身其实也在着力于提高服务端的消息堆积能力。对于消息堆积严重的队列，可以预先添加懒加载机制，或者创建Sharding分片队列，这些措施都有助于优化服务端的消息堆积能力。另外，尝试使用Stream队列，也能很好的提高服务端的消息堆积能力。

+ 接下来在消息消费者端：

要提升消费速度最直接的方式，就是增加消费者数量了。尤其当消费端的服务出现问题，已经有大量消息堆积时。这时，可以尽量多的申请机器，部署消费端应用，争取在最短的时间内消费掉积压的消息。但是这种方式需要注意对其他组件的性能压力。

对于单个消费者端，可以通过配置提升消费者端的吞吐量。

```java
# 单次推送消息数量 
spring.rabbitmq.listener.simple.prefetch=1 
# 消费者的消费线程数量 
spring.rabbitmq.listener.simple.concurrency=5
```

灵活配置这几个参数，能够在一定程度上调整每个消费者实例的吞吐量，减少消息堆积数量。

当确实遇到紧急状况，来不及调整消费者端时，可以紧急上线一个消费者组，专门用来将消息快速转录。保存到数据库或者Redis，然后再慢慢进行处理。

# 十一、RabbitMQ的备份与恢复

RabbitMQ有一个data目录会保存分配到该节点上的所有消息。我们的实验环境中，默认是在/var/lib/rabbitmq/mnesia目录下这个目录里面的备份分为两个部分，一个是元数据(定义结构的数据)，一个是消息存储目录。

**对于元数据，可以在Web管理页面通过json文件直接导出或导入。**

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E6%95%B0%E6%8D%AE%E5%A4%87%E4%BB%BD.png?raw=true)

**而对于消息，可以手动进行备份恢复**

其实对于消息，由于MQ的特性，是不建议进行备份恢复的。而RabbitMQ如果要进行数据备份恢复，也非常简单。

首先，要保证要恢复的RabbitMQ中已经有了全部的元数据，这个可以通过上一步的json文件来恢复。

然后，备份过程必须要先停止应用。如果是针对镜像集群，还需要把整个集群全部停止。

最后，在RabbitMQ的数据目录中，有按virtual hosts组织的文件夹。你只需要按照虚拟主机，将整个文件夹复制到新的服务中即可。持久化消息和非持久化消息都会一起备份。 我们实验环境的默认目录是/var/lib/rabbitmq/mnesia/rabbit@worker2/msg_stores/vhosts

# 十二、RabbitMQ的性能监控

关于RabbitMQ的性能监控，在管理控制台中提供了非常丰富的展示。例如在下面这个简单的集群节点图中，就监控了非常多系统的关键资源。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E6%95%B0%E6%8D%AE%E5%A4%87%E4%BB%BD.png?raw=true)

还包括消息的生产消费频率、关键组件使用情况等等非常多的信息，都可以从这个管理控制台上展现出来。但是，对于构建一个自动化的性能监控系统来说，这个管理页面就不太够用了。为此，RabbitMQ也提供了一系列的HTTP接口，通过这些接口可以非常全面的使用并管理RabbitMQ的各种功能。

这些HTTP的接口不需要专门去查手册，在部署的管理控制台页面下方已经集成了详细的文档，我们只需要打开HTTP API的页面就能看到。

![img](https://github.com/hepengjun2022/doc-java/blob/master/pic/RabbitMQ%E7%9A%84HTTP%20API.png?raw=true)

比如最常用的 http://[server:port]/api/overview 接口，会列出非常多的信息，包含系统的资源使用情况。通过这个接口，就可以很好的对接Promethus、Grafana等工具，构建更灵活的监控告警体系。

可以看到，这里面的接口相当丰富，不光可以通过GET请求获取各种消息，还可以通过其他类型的HTTP请求来管理RabbitMQ中的各种资源，因此在实际使用时，还需要考虑这些接口的安全性。

# 十三、搭建HAProxy，实现高可用集群

我们之前搭建的镜像集群，已经具备了集群的功能，请求发送到任何一个节点上，数据都是在集群内共享的。但是，在企业使用时，通常还会选择在集群基础上增加负载均衡的能力。即希望将客户端的请求能够尽量均匀的分配到集群中各个节点上，这样可以让集群的压力得到平衡。

实现负载均衡的方式有很多，HAProxy就是其中一种可选方案。HAProxy是一个免费、快速并且可靠的解决方案，有很多大型互联网公司都在使用。通过HAProxy，应用可以直连一个单一的IP地址，然后HAProxy会将这个IP地址的TCP请求进行转发，并在转发过程中实现负载均衡。

提示：很多有实力的大企业会采用F5等其他的一些负载均衡工具。

安装步骤：

## 1、安装HAProxy

```java
#安装 
yum install haproxy 
    
#检测安装是否成功 
haproxy 
    
#查找haproxy.cfg文件的位置 
find / ‐name haproxy.cfg 
    
#配置haproxy.cfg文件,后面会列出参考配置 
vim /etc/haproxy/haproxy.cfg 
    
#启动haproxy 
haproxy ‐f /etc/haproxy/haproxy.cfg 
    
#查看haproxy进程状态 
systemctl status haproxy.service 
#状态如下说明 已经启动成功 Active: active (running) 
    
#访问如下地址对mq节点进行监控 
http://47.114.175.29:1080/haproxy_stats 

#代码中访问mq集群地址，则变为访问haproxy地址:5672
```

## 2、配置HAProxy

修改haproxy.cfg文件。下面是参考配置。注意将节点的IP地址和端口换成你自己的

环境。

```java
#对MQ集群进行监听 
listen rabbitmq_cluster 
bind 0.0.0.0:5672 
option tcplog 
mode tcp 
option clitcpka 
timeout connect 1s 
timeout client 10s 
timeout server 10s 
balance roundrobin 
server node1 worker1:5672 check inter 5s rise 2 fall 3 
server node2 worker2:5672 check inter 5s rise 2 fall 3 
server node3 worker3:5672 check inter 5s rise 2 fall 3 

#开启haproxy监控服务 
listen http_front 
bind 0.0.0.0:1080 
stats refresh 30s 
stats uri /haproxy_stats 
stats auth admin:admin
```

# 十四、总结

基于MQ的事件驱动机制，给庞大的互联网应用带来了不一样的方向。MQ的异步、解耦、削峰三大功能特点在很多业务场景下都能带来极大的性能提升，在日常工作过程中，应该尝试总结这些设计的思想。

虽然MQ的功能，说起来比较简单，但是随着MQ的应用逐渐深化，所需要解决的问题也更深入。对各种细化问题的挖掘程度，很大程度上决定了开发团队能不能真正Hold得住MQ产品。通常面向互联网的应用场景，更加注重MQ的吞吐量，需要将消息尽快的保存下来，再供后端慢慢消费。而针对企业内部的应用场景，更加注重MQ的数据安全性，在复杂多变的业务场景下，每一个消息都需要有更加严格的安全保障。而在当今互联网，Kafka是第一个场景的不二代表，但是他会丢失消息的特性，让kafka的使用场景比较局限。RabbitMQ作为一个老牌产品，是第二个场景最有力的代表。当然，随着互联网应用不端成熟，也不断有其他更全能的产品冒出来，比如阿里的RocketMQ以及雅虎的Pulsar。但是不管未来MQ领域会是什么样子，RabbitMQ依然是目前企业级最为经典也最为重要的一个产品。他的功能最为全面，周边生态也非常成熟，并且RabbitMQ有庞大的Spring社区支持，本身也在吸收其他产品的各种优点，持续进化，所以未来RabbitMQ的重要性也会更加凸显。

整个课程，从RabbitMQ的安装、应用、扩展等多个方面，综合介绍了RabbitMQ的各种常用使用方法以及业务场景。希望能够带你打开一扇大门，更真实，更深入的理解MQ这个工具。
