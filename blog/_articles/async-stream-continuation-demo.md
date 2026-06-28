---
title: 用一个 SwiftUI Demo 理解 AsyncStream 和 Continuation
description: 从一个最小 iOS demo 出发，解释 AsyncStream 的读端、Continuation 的写端、finish、cancel、onTermination 和 cleanup 的关系。
summary: 通过 AsyncStreamContinuationDemo 观察 producer、consumer、Continuation、onTermination 和内存释放之间的真实生命周期。
category: Investigation
tag: Swift Concurrency
date: 2026-06-28
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/async-stream-continuation-demo
---

## 我想弄清楚的问题

`AsyncStream` 看起来很简单：producer 不断产生值，consumer 用 `for await` 读取值。但真正写代码时，容易卡在几个问题上：

- `AsyncStream` 和 `Continuation` 到底是什么关系？
- `Continuation.finish()` 应该在哪里调用？
- consumer 被 cancel 时，producer 怎么知道应该停下来？
- `onTermination` 是什么时候触发的？
- 能不能把同一个 stream 给多个 consumer 一起读？
- 内存释放时，能不能只靠 `deinit` cleanup？

`async-stream-continuation-demo` 就是围绕这些问题做的一个最小 SwiftUI demo。它没有把日志显示在界面里，而是把关键生命周期都打到 `Logger`，方便在 Xcode console 或系统日志里看真实顺序。

这篇文章不是单纯整理 API 用法，而是记录一个真实迭代：最初 `Drop Owner` 只释放 source，日志里常常只能看到 `source deinit`；后来我意识到这不是推荐写法，于是把它改成释放 owner 前先显式 `finish()`、取消 consumer task，并用测试覆盖这个行为。

## 背景：AsyncStream 是读端，Continuation 是写端

可以把 `AsyncStream` 理解成一个 async sequence。consumer 看到的是：

```swift
for await event in stream {
    // consume event
}
```

而 producer 手里拿到的是 `AsyncStream<Element>.Continuation`：

```swift
continuation.yield(event)
continuation.finish()
```

所以它们不是两个独立系统，而是同一个异步数据通道的两端：

```text
producer
  └─ continuation.yield(value)
        ↓
  AsyncStream internal buffer
        ↓
consumer
  └─ for await value in stream
```

Swift 现在更推荐用 `makeStream` 创建这一对对象：

```swift
let pair = AsyncStream.makeStream(
    of: StreamEvent.self,
    bufferingPolicy: .bufferingNewest(10)
)

events = pair.stream
continuation = pair.continuation
```

在 demo 里，这段代码位于 `async-stream-continuation-demo/AsyncStreamContinuationDemo/AsyncEventSource.swift`。`AsyncEventSource` 自己保存 `continuation`，对外只暴露 `events: AsyncStream<StreamEvent>`。这样 view model 只能消费事件，不能随手 `yield`，读写职责是分开的。

## Demo 的结构

界面只有四个按钮，每个按钮都对应一条生命周期路径：

- **`Start Stream`**：创建 `AsyncEventSource`，启动 consumer task，再启动 producer task。
- **`Cancel Consumer`**：取消读取 stream 的 task，用来观察 consumer cancel 如何触发 `onTermination`。
- **`Finish Producer`**：producer 主动调用 `continuation.finish()`，用来观察正常结束时 `for await` 如何退出。
- **`Drop Owner`**：先显式 `finish()` 和清掉 consumer task，再释放 view model 对 source 的引用。

阅读代码时可以按这个顺序走：

1. `AsyncEventSource.swift`：先看 `AsyncStream`、`Continuation`、producer task 和 cleanup。
2. `StreamDemoViewModel.swift`：再看按钮动作如何创建 source、启动 consumer、cancel 和 finish。
3. `ContentView.swift`：最后看最小 SwiftUI 交互界面。
4. `AsyncEventSourceTests.swift`：用测试确认 finish、cancel、cleanup 的行为没有靠猜。

## Start Stream：建立 producer 和 consumer 的关系

点击 `Start Stream` 时，`StreamDemoViewModel` 会创建一个新的 `AsyncEventSource`，保存到 `source`，然后取出 `source.events` 给 consumer task 使用：

```swift
let events = source.events

consumerTask = Task { [weak self, logger] in
    for await event in events {
        logger.info("consumer received event \(event.logDescription)")
        await MainActor.run {
            self?.status = .running(lastEvent: event.message)
        }
    }

    logger.info("for-await loop ended")
}
```

这里有一个重要边界：consumer task 只拿到 `events`，没有拿到 `continuation`。这说明 UI 层只消费，不生产。

source 侧会启动 producer task：

```swift
producerTask = Task { [weak self] in
    while Task.isCancelled == false {
        _ = await self?.emitNext()

        do {
            try await Task.sleep(for: interval)
        } catch {
            break
        }
    }
}
```

每次 `emitNext()` 都会构造一个 `StreamEvent`，然后调用：

```swift
let result = continuation.yield(event)
logger.debug("yield result \(describe(result))")
```

`yield` 的返回值很值得看。它会告诉你值是进入 buffer 了、被 drop 了，还是 stream 已经 terminated。demo 刻意记录 `yield result`，就是为了让读者看到 producer 不是“盲写”的。

## 为什么要设置 bufferingPolicy

`AsyncStream` 默认 buffer 是 unbounded。学习 demo 如果直接用默认值，很容易给人留下“长期 producer 可以无限 yield”这种错误印象。

这个 demo 用的是：

```swift
.bufferingNewest(10)
```

意思是最多保留最新的 10 个元素。对于 UI 事件、传感器读数、状态变化这类“最新值更重要”的场景，这通常比无界 buffer 更安全。它不能替代真正的 back pressure，但至少不会让慢 consumer 无限堆积内存。

## Finish Producer：正常结束 stream

点击 `Finish Producer` 时，view model 会调用 source 的 `finish()`：

```swift
func finish() {
    guard finished == false else {
        logger.debug("finish requested after stream already finished")
        return
    }

    finished = true
    logger.info("finish requested")
    continuation.finish()
    cleanup(reason: "finish requested")
}
```

这里有两个细节。

第一，`finish()` 是 producer 告诉 stream：“不会再有新值了。”consumer 的 `for await` 因此可以自然结束。

第二，demo 自己加了 `finished` guard。`AsyncStream.Continuation.finish()` 多次调用通常可以被容忍，但 producer 自己的 cleanup 可能包括 cancel task、关闭资源、移除 observer、写状态日志，这些逻辑应该是幂等的。

所以更稳的习惯是：**让 public finish API 只真正执行一次，让 cleanup 也只真正执行一次。**

## Cancel Consumer：消费端取消时 producer 怎么停

点击 `Cancel Consumer` 时，view model 取消 consumer task：

```swift
consumerTask?.cancel()
consumerTask = nil
status = .cancelled
```

`for await` 所在 task 被取消后，stream 的消费关系结束。这个时候 producer 侧需要知道“没人读了”，否则 producer task 可能还在后台继续 yield。

这个通知点就是：

```swift
continuation.onTermination = { [weak self] termination in
    Task {
        await self?.handleTermination(termination)
    }
}
```

`onTermination` 会在 stream 的消费关系终止时调用。常见原因包括 consumer task 被 cancel、producer 调用 `finish()`、stream 或 iterator 被释放。demo 会记录：

```swift
logger.info("continuation onTermination reason \(String(describing: termination))")
cleanup(reason: "termination \(String(describing: termination))")
```

这就是本次 demo 最关键的学习点：**`onTermination` 是 consumer 端结束后，producer 端收到的生命周期回调。**

## Cleanup：不要只依赖 deinit

demo 的 cleanup 是这样写的：

```swift
private func cleanup(reason: String) {
    guard cleanedUp == false else {
        logger.debug("cleanup skipped because it already ran")
        return
    }

    cleanedUp = true
    cleanupCount += 1
    logger.info("cleanup started reason=\(reason)")
    producerTask?.cancel()
    producerTask = nil
    logger.info("cleanup completed")
}
```

它有两个作用：

1. 停掉 producer task。
2. 用 `cleanedUp` 防止重复 cleanup。

`deinit` 里也做了兜底：

```swift
deinit {
    logger.info("source deinit")
    producerTask?.cancel()
}
```

但这不是主要 cleanup 机制。原因是 `deinit` 不一定及时发生，甚至可能因为 task、closure、delegate 或其他引用关系而不发生。如果底层资源必须释放，应该有明确的 `finish()` / `stop()` / `cleanup()` 路径，再让 `deinit` 做最后保险。

这也是 `onTermination` 的价值：它不是等对象被释放，而是在 stream 消费关系结束时就通知 producer。

## Drop Owner：释放 owner 前先清理

我一开始让 `Drop Owner` 只做 `source = nil`，这样日志里经常只能看到 `source deinit`。这其实暴露了一个问题：owner 释放了，不代表 stream 的 consumer 一定退出，也不代表 producer 已经走完 cleanup。

旧版本的行为大概是这样：

```swift
func dropOwner() {
    logger.info("drop owner requested")
    source = nil
    status = .released
}
```

这段代码能让 `AsyncEventSource` 进入 `deinit`，但 consumer task 仍然可能持有 `source.events` 并继续等待下一个值。也就是说，“source 对象释放了”和“stream 生命周期被正确收尾了”不是一回事。

所以这个按钮后来改成先显式停止，再释放 owner：

```swift
func dropOwner() async {
    logger.info("drop owner requested")
    if let source {
        logger.info("finishing source before owner release")
        await source.finish()
    }

    consumerTask?.cancel()
    consumerTask = nil
    source = nil
    status = .released
}
```

这条路径现在表达的是推荐顺序：

1. 先让 producer `finish()` stream。
2. 再取消 consumer task，并清空 `consumerTask`。
3. 最后释放 `source` owner。

这里还有一个并发细节：`Start Stream` 会排队启动 producer task，如果用户很快点 `Drop Owner`，可能出现 `finish()` 已经 cleanup，但排队中的 `startProducing()` 后执行的情况。因此 `AsyncEventSource.startProducing()` 也要检查 stream 是否已经 finished 或 cleaned up，避免 cleanup 后又把 producer 启起来。

```swift
func startProducing(interval: Duration = .milliseconds(700)) {
    guard finished == false && cleanedUp == false else {
        logger.debug("producer task not started because stream is already finished")
        return
    }

    // start producer task...
}
```

这个 bug 的价值在于，它说明 cleanup 不只是“按钮最后调用一下 finish”这么简单。只要 producer 的启动和停止跨 task 排队，就要在 producer 自己的入口也做状态防护。

## 多个 consumer 应该怎么处理

一个容易误解的问题是：能不能把同一个 `AsyncStream` 给多个 task 一起 `for await`？

不应该把 `AsyncStream` 当成天然广播流。它更适合被理解成 single-consumer / unicast。多个 task 同时消费同一个 stream 时，不要期待每个 consumer 都收到每个 value。

如果需要 multicast，更清晰的做法是：每个 consumer 创建自己的 `AsyncStream`，producer 维护多个 continuation。每次事件到来时，producer 对所有 continuation 调用 `yield`。这样每个 consumer 有自己的 buffer、自己的 `onTermination`，某个 consumer 取消时只移除自己的 continuation。

这个 demo 没有实现 multicast，因为它的目标是先把单个 producer 和单个 consumer 的生命周期讲清楚。

## 日志应该怎么看

app 使用的 Logger subsystem 是：

```text
com.huahuahu.demo.AsyncStreamContinuationDemo
```

可以在 Xcode console、Simulator console 或系统日志里过滤这个 subsystem。重点观察这些日志：

- `stream created`
- `continuation stored`
- `producer task started`
- `yield requested`
- `yield result`
- `consumer task started`
- `consumer received event`
- `finish requested`
- `cancel requested`
- `drop owner requested`
- `finishing source before owner release`
- `for-await loop ended`
- `continuation onTermination reason`
- `cleanup started`
- `cleanup completed`
- `producer task not started because stream is already finished`
- `source deinit`

对照按钮操作看日志，比只读代码更容易理解：到底是 producer 先 finish，还是 consumer cancel 先触发 termination；cleanup 有没有重复跑；`yield` 在 stream terminated 后会返回什么状态。

## 测试验证了什么

`AsyncEventSourceTests.swift` 主要验证四件事：

1. `emitNext()` 能产出第一个事件。
2. `finish()` 会让 stream 结束，并触发 cleanup。
3. consumer cancel 会走 `onTermination` cleanup。
4. cleanup 会停止 producer task。

`StreamDemoViewModelTests.swift` 验证按钮动作对应的状态变化，例如 start 后进入 `.running`，cancel 后进入 `.cancelled`，finish 后进入 `.finished`，drop owner 会先 finish source、清掉 consumer task，再进入 `.released`。

最关键的回归测试是 `dropOwnerFinishesSourceAndCancelsConsumerBeforeRelease()`。这个测试要求：

- view model 状态进入 `.released`。
- `canDropOwner` 变成 `false`。
- `canCancel` 变成 `false`。
- source 的 snapshot 显示 `isFinished == true`、`cleanupCount == 1`、`isProducing == false`。

它一开始失败在两个地方：`canCancel` 仍然是 `true`，并且 source 没有完成 cleanup。修复 `dropOwner()` 后，又暴露出第二个问题：排队中的 `startProducing()` 可能在 cleanup 后启动 producer task。最后是在 `AsyncEventSource.startProducing()` 入口加 finished/cleanedUp guard 才完整解决。

这些测试没有替代人工看日志，但它们保证 demo 的生命周期行为不会在后续改动中悄悄坏掉。

验证时还有一个工具层面的坑：单独用 `-only-testing` 选择 Swift Testing 的某个测试时，曾出现命令成功但日志显示 `Executed 0 tests` 的情况。对这个 demo，我更信任 XcodeBuildMCP 的全量 `test_sim` 结果；它能避免把“没有实际执行测试”误判成通过。

## 关键理解

这次 demo 帮我把 `AsyncStream` 的几个边界理清了：

- `AsyncStream` 是读端，`Continuation` 是写端。
- producer 拥有 continuation，consumer 只拿 stream。
- `yield` 可以多次调用，`finish` 用来声明不会再有新值。
- `finish` 最好自己做幂等保护，因为 cleanup 往往不该重复执行。
- `onTermination` 是 consumer 端结束后通知 producer cleanup 的关键钩子。
- 释放 owner 前应该先显式结束 stream、取消 consumer，再释放引用。
- producer 启动入口也要防止 cleanup 后被异步任务重新启动。
- 长期 producer 不要默认使用 unbounded buffer。
- `deinit` 只能兜底，不能作为唯一 cleanup 策略。
- 同一个 `AsyncStream` 不适合作为天然广播流；多个 consumer 应该各自拥有 stream。

如果只记一句话：**把 `AsyncStream` 当成 consumer 面向的异步序列，把 `Continuation` 当成 producer 面向的写入和结束控制器；真正可靠的资源释放发生在明确的 finish / termination / cleanup 路径里，而不是靠对象自然 deinit。**
