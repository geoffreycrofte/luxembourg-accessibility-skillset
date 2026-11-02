---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [raam-code, trigger]
---

In my SwiftUI app I have this button. Make it accessible for the Luxembourg mobile accessibility framework:

Button(action: { cart.add(item) }) {
    Image(systemName: "cart.badge.plus")
}
.frame(width: 28, height: 28)
