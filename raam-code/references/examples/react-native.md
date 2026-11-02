# RAAM 1.1 — React Native code examples

Companion to the *Core rules* in `SKILL.md`: the rules and their criterion numbers
live there; this file only shows them applied. Headings match the SKILL.md topics;
a topic missing here has no React Native-specific example yet.

## 1. Graphic Elements (Topic 1)

#### React Native

```jsx
// Informative image
<Image
  source={require('./chart.png')}
  accessible={true}
  accessibilityLabel="Sales increased 40% in Q3 2024"
/>

// Decorative image
<Image
  source={require('./decoration.png')}
  accessible={false}
  accessibilityElementsHidden={true}
  importantForAccessibility="no"
/>
```

## 5. Interactive Components (Topic 5)

#### React Native

```jsx
// GOOD: interactive component with state
<TouchableOpacity
  accessible={true}
  accessibilityRole="button"
  accessibilityLabel="Details"
  accessibilityState={{ expanded: isExpanded }}
  onPress={toggleExpansion}
>
  <Text>Details</Text>
</TouchableOpacity>
```

## 7. Information Structure (Topic 7)

#### React Native

```jsx
<Text accessibilityRole="header">Account Settings</Text>
```

## 9. Forms (Topic 9)

#### React Native

```jsx
// GOOD: accessible form field
<View accessible={true} accessibilityRole="none">
  <Text nativeID="emailLabel">Email address *</Text>
  <TextInput
    accessibilityLabelledBy="emailLabel"
    accessibilityHint="Required. Format: name@example.com"
    keyboardType="email-address"
    textContentType="emailAddress"      // iOS autocomplete
    autoComplete="email"                // Android autocomplete
    value={email}
    onChangeText={setEmail}
  />
  {emailError && (
    <Text accessibilityLiveRegion="polite" accessibilityRole="alert">
      {emailError}
    </Text>
  )}
</View>
```
