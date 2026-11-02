---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [raweb-audit, trigger]
---

Audit this snippet against RAWeb and give me a verdict per criterion:

<nav>
  <ul role="menu">
    <li role="menuitem"><a href="/">Home</a></li>
    <li role="menuitem"><a href="/services">Services</a></li>
  </ul>
</nav>
<div aria-live="polite" id="cart-status"></div>
<script>
  document.getElementById('cart-status').textContent = 'Item added to cart';
</script>
