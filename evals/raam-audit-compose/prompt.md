---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [raam-audit, trigger]
---

Audit this Jetpack Compose screen fragment for RAAM compliance and list the issues:

Row {
    Icon(Icons.Default.Delete, contentDescription = null,
         modifier = Modifier.size(20.dp).clickable { onDelete() })
    Text("Invoice #1042", fontSize = 14.sp, color = Color(0xFFAAAAAA))
}
