# RAAM 1.1 — Android (Jetpack Compose, XML Views) code examples

Companion to the *Core rules* in `SKILL.md`: the rules and their criterion numbers
live there; this file only shows them applied. Headings match the SKILL.md topics;
a topic missing here has no Android-specific example yet.

## 1. Graphic Elements (Topic 1)

#### Android (Jetpack Compose)

```kotlin
// GOOD: informative image
Image(
    painter = painterResource(R.drawable.chart_sales),
    contentDescription = "Sales increased 40% in Q3 2024"
)

// GOOD: decorative image
Image(
    painter = painterResource(R.drawable.decorative_wave),
    contentDescription = null // null = decorative in Compose
)

// GOOD: icon button
IconButton(onClick = { /* ... */ }) {
    Icon(
        Icons.Default.Search,
        contentDescription = "Search"
    )
}
```

#### Android (XML Views)

```xml
<!-- Informative image -->
<ImageView
    android:contentDescription="Sales increased 40% in Q3 2024"
    android:importantForAccessibility="yes" />

<!-- Decorative image -->
<ImageView
    android:contentDescription="@null"
    android:importantForAccessibility="no" />
```

## 2. Colours (Topic 2)

#### Android

```kotlin
// Support high contrast text mode
// Use theme colours that respond to system accessibility settings
Text(
    text = "Important",
    color = MaterialTheme.colorScheme.onSurface // adapts to theme
)
```

## 4. Tables (Topic 4)

#### Android (Compose)

```kotlin
// GOOD: announce table structure to TalkBack
Column(modifier = Modifier.semantics {
    contentDescription = "Revenue table, 3 regions, 2 columns: region and revenue"
}) {
    // Table content
}
```

## 5. Interactive Components (Topic 5)

#### Android (Compose)

```kotlin
// GOOD: expandable section with state
Row(
    modifier = Modifier
        .clickable { toggleExpansion() }
        .semantics {
            role = Role.Button
            stateDescription = if (isExpanded) "expanded" else "collapsed"
        }
) {
    Text("Details")
    Icon(
        if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
        contentDescription = null // described by parent semantics
    )
}

// GOOD: disabled button announces state
Button(
    onClick = { /* ... */ },
    enabled = false // Compose announces "disabled" to TalkBack
) {
    Text("Submit")
}
```

## 6. Mandatory Elements (Topic 6)

#### Android

```kotlin
// Compose: screen title for TalkBack
Scaffold(
    topBar = {
        TopAppBar(title = { Text("Settings") })
    }
) { /* ... */ }

// Activity: label in AndroidManifest.xml
// <activity android:label="@string/settings_title" />

// Language: set in AndroidManifest.xml
// <application android:localeConfig="@xml/locales_config">
```

## 7. Information Structure (Topic 7)

#### Android (Compose)

```kotlin
// GOOD: heading semantics
Text(
    text = "Account Settings",
    style = MaterialTheme.typography.headlineMedium,
    modifier = Modifier.semantics { heading() }
)
```

## 8. Presentation of Information (Topic 8)

#### Android

```kotlin
// GOOD: use sp (scalable pixels) for text
Text(
    text = "Welcome back",
    fontSize = 16.sp // scales with system settings
)

// GOOD: support rotation in AndroidManifest.xml
// android:screenOrientation="unspecified"
```

## 9. Forms (Topic 9)

#### Android (Compose)

```kotlin
// GOOD: labelled text field with error
OutlinedTextField(
    value = email,
    onValueChange = { email = it },
    label = { Text("Email address *") },
    isError = emailError != null,
    supportingText = emailError?.let { { Text(it) } },
    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
    modifier = Modifier.semantics {
        contentDescription = "Email address, required"
        if (emailError != null) {
            error("Error: $emailError")
        }
    }
)

// GOOD: autofill hint (9.12)
OutlinedTextField(
    value = firstName,
    onValueChange = { firstName = it },
    label = { Text("First name") },
    modifier = Modifier.autofill(
        autofillTypes = listOf(AutofillType.PersonFirstName),
        onFill = { firstName = it }
    )
)
```

## 10. Navigation (Topic 10)

#### Android

```kotlin
// GOOD: traversal order follows layout
Column {
    TextField(/* first name */)
    TextField(/* last name */)
    Button(onClick = { submit() }) { Text("Submit") }
}
// Compose follows composition order by default

// For XML views, use android:accessibilityTraversalBefore/After
// sparingly and only to fix non-obvious order issues
```
