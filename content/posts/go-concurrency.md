---
title: "Go 并发模式：从 goroutine 到 channel"
date: 2026-05-14
draft: false
tags: ["Go", "并发", "编程"]
categories: ["技术"]
summary: "深入理解 Go 语言的并发模型，掌握 goroutine 和 channel 的使用技巧。"
---

## goroutine 基础

Go 的并发基于 goroutine，它是一个轻量级线程。启动一个 goroutine 只需要在函数调用前加上 `go` 关键字。

```go
func main() {
    go fmt.Println("Hello from goroutine")
    time.Sleep(time.Second)
}
```

## Channel 通信

Channel 是 goroutine 之间通信的桥梁。

```go
ch := make(chan string)
go func() {
    ch <- "hello"
}()
msg := <-ch
fmt.Println(msg)
```

## Select 多路复用

`select` 语句可以同时等待多个 channel 操作。

```go
select {
case msg := <-ch1:
    fmt.Println("from ch1:", msg)
case msg := <-ch2:
    fmt.Println("from ch2:", msg)
case <-time.After(time.Second):
    fmt.Println("timeout")
}
```
