# 一、介绍

**SpringCloudStream 是一个构建高扩展和事件驱动的微服务系统的框架，用于连接共有消息系统**，官网地址： https://spring.io/projects/spring-cloud-stream。

整体上是把各种花里胡哨的MQ产品抽象成了一套非常简单的统一的编程框架，以实现事件驱动的编程模型。社区官方实现了RabbitMQ、Apache Kafka、Kafka、Stream和Amazon Kinesis这几种产品，而其他还有很多产品比如RocketMQ，都是由产品方自行提供扩展实现。

所以可以看到，对于RabbitMQ，使用SpringCloudStream框架算是一种比较成熟的集成方案。但是需要主要注意的是，SpringCloudStream框架集成的版本通常是比RabbitMQ落后几个版本的，使用时需要注意。

SpringCloudStream框架封装出了三个最基础的概念来对各种消息中间件提供统一的抽象：

+ Destination Binders：负责集成外部消息系统的组件。

+ Destination Binding：由Binders创建的，负责沟通外部消息系统、消息发送者和消息消费者的桥梁。

+ Message：消息发送者与消息消费者沟通的简单数据结构。

可以看到，这个模型非常简单，使用时也会非常方便。但是简单，意味着SCStream中的各种概念模型，与RabbitMQ的基础概念之间是有比较大的差距的，例如Exchange、Queue这些原生概念，集成到SCStream框架时，都需要注意如何配置，如何转换。

# 二、集成方式

## 1.引入依赖

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

## 2.基础使用方法

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

# 三、SpringcloudStream对接RabbitMQ

非常简单的几行代码，你甚至都不需要感知RabbitMQ的存在，就完成了与RabbitMQ的对接。但是，简单的背后，意味着，如果你要深入使用更多功能，需要有更扎实的技术基础，对SpringCloudStream有更深入的了解。

我们先来了解下，在刚才的简单示例当中，SpringCloudStream都干了些什么事情。

### 1.配置RabbitMQ服务器

在SpringBoot的autoconfigure包当中，有个 RabbitProperties类，这个类就会解析application.properties中以spring.rabbitmq开头的配置。里面配置了跟RabbitMQ相关的主要参数，包含服务器地址等。里面对每个参数也都提供了默认值。默认就是访问本地的RabbitMQ服务。

```java
#这几个是默认配置。 
spring.rabbitmq.host=localhost 
spring.rabbitmq.port=5672 
spring.rabbitmq.username=guest 
spring.rabbitmq.password=guest 
spring.rabbitmq.virtual-host=/
```

### 2.在RabbitMQ中声明Exchange和Queue

+ 既然是要对接RabbitMQ，那么最终还是需要与RabbitMQ服务器进行交互的。
+ 从RabbitMQ的管理页面上来看，SCStream帮我们在RabbitMQ的根虚拟机上创建了一个topic类型的scstreamExchange交换机，然后在这个交换机上绑定了一个scstreamExchange.stream队列，绑定的RoutingKey是#。 而程序中的消息发送者是将消息发送到scstreamExchange交换机，然后RabbitMQ将消息转发到scstreamExchange.stream队列，消息接收者从队列接收到消息。
+ 这个流程，就是Spring Cloud Stream在背后为我们做的事情。 在这里可以尝试对应RabbitMQ的基础概念以及SCStream框架中的基础概念，整理一下他们之间的对应关系。

其实这个示例也演示了SCStream的特点。SCStream框架帮我们屏蔽了与消息中间件的交互细节，开发人员甚至都不需要感知消息中间件的存在，将更多的关注点放到业务处理的细节里。

实际上，就我们这个简单的示例，只需要将maven中的spring-cloud-starter-stream-rabbit依赖，换成spring-cloud-starter-streamkafka，就可以完成与本地Kafka服务的交互，代码不需要做任何的改动。

# 四、SCStream高级

这里需要注意，SCStream框架的设计目的，是为了实现一套简明的事件驱动模型。在这个事件驱动模型中，是没有RabbitMQ中这些Exchange、queue或者是kafka中的Topic之类的这些功能的，所以这也意味着，如果想要使用RabbitMQ的一些特性功能，比如Quorum队列，死信队列，懒加载队列等，反而会比较麻烦。这就需要对各种基础概念有更深的了解。

### ①.配置Binder

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

### ②.Binding配置

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

### ③.SCStream的分组消费策略

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

### ④.使用原生消息转发机制

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

### ⑤.使用SCStream配置死信队列

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

### ⑥.扩展的事件监听机制

另外，在SCStream框架的Sink消费者端，还可以添加@EventListener注解。加入这个注解后，这个Sink消费者，不光可以消费MQ消息，还能监控很多Spring内的事件，像 AsyncConsumerStartedEvent、ApplicationReadyEvent(springBoot启动事件)、ServletRequestHandledEvent(请求响应事件)等等。而使用这些功能，我们可以将Spring的应用事件作为业务事件一样处理，这对于构建统一的Spring应用监控体系是非常有用的。

### ⑦.SCStream框架总结

对于事件驱动这个应用场景来说，SCStream框架绝对是一个举足轻重的产品。

一方面，他极大的简化的事件驱动的开发过程，让技术人员可以减少对于不同MQ产品的适应过程，更多的关注业务逻辑。

另一方面，SCStream框架对各种五花八门的MQ产品提供了一种统一的实现流程，从而可以极大的减少应用对于具体MQ产品的依赖，极大提高应用的灵活性。例如如果应用某一天想要从RabbitMQ切换成Kafka或者RocketMQ等其他的MQ产品，如果采用其他框架，需要对应用程序做非常大的改动。但是，如果使用SCStream框架，那么基本上就是换Maven依赖，调整相关配置就可以了。应用代码基本不需要做任何改动。

当然，SCStream框架使用非常方便的背后，也意味着更高的学习门槛。如果只是最简单的使用MQ产品，那你当然可以不用感知MQ产品的存在，就用SCStream框架进行快速的开发。但是，当你需要深入的使用MQ产品时，那就不光需要学习MQ产品本身，还需要学习具体MQ产品模型如何与SCStream的基础模型对应以及转换。这其实对技术反而提出了更高的要求。所以SCStream在一些技术非常扎实的。

---

