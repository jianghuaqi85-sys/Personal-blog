---
title: "Vue 3 响应式原理深度解析"
date: 2026-05-12
draft: false
tags: ["Vue", "前端", "JavaScript"]
categories: ["前端"]
summary: "深入 Vue 3 的 Proxy-based 响应式系统，理解其设计哲学。"
---

## Proxy vs Object.defineProperty

Vue 3 使用 Proxy 替代了 Vue 2 的 Object.defineProperty。核心优势：

- 可以监听新增属性
- 可以监听数组变化
- 可以监听删除操作

## reactive() 的实现

```javascript
function reactive(target) {
  return new Proxy(target, {
    get(target, key, receiver) {
      track(target, key)
      return Reflect.get(target, key, receiver)
    },
    set(target, key, value, receiver) {
      const result = Reflect.set(target, key, value, receiver)
      trigger(target, key)
      return result
    }
  })
}
```

## 依赖收集

Vue 3 使用 `WeakMap` + `Map` + `Set` 三级结构进行依赖收集：

- **WeakMap** - 以 target 为 key
- **Map** - 以 key 为 key
- **Set** - 存储依赖的 effect

## 总结

Vue 3 的响应式系统设计精巧，Proxy 的使用让响应式更加完整和高效。
