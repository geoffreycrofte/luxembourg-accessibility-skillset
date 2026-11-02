# RAAM 1.1 — iOS (SwiftUI, UIKit) code examples

Companion to the *Core rules* in `SKILL.md`: the rules and their criterion numbers
live there; this file only shows them applied. Headings match the SKILL.md topics;
a topic missing here has no iOS-specific example yet.

## 1. Graphic Elements (Topic 1)

#### iOS (SwiftUI)

```swift
// GOOD: informative image
Image("chart-sales")
    .accessibilityLabel("Sales increased 40% in Q3 2024")

// GOOD: decorative image — hidden from VoiceOver
Image("decorative-wave")
    .accessibilityHidden(true)

// GOOD: icon button with accessibility
Button(action: { /* ... */ }) {
    Image(systemName: "magnifyingglass")
}
.accessibilityLabel("Search")
```

#### iOS (UIKit)

```swift
// Informative image
imageView.isAccessibilityElement = true
imageView.accessibilityLabel = "Sales increased 40% in Q3 2024"

// Decorative image
decorativeImageView.isAccessibilityElement = false
decorativeImageView.accessibilityElementsHidden = true
```

## 2. Colours (Topic 2)

#### iOS

```swift
// GOOD: support system contrast settings
// Use semantic colours that adapt to Increase Contrast mode
Text("Important")
    .foregroundColor(.primary) // adapts to accessibility settings

// Support Differentiate Without Colour
HStack {
    Image(systemName: "checkmark.circle.fill")
        .foregroundColor(.green)
    Text("Validated") // text reinforces the green colour meaning
}
```

## 4. Tables (Topic 4)

#### iOS (SwiftUI)

```swift
// GOOD: accessible table with header
List {
    Section(header: Text("Q3 Revenue by Region")) {
        ForEach(regions) { region in
            HStack {
                Text(region.name)
                Spacer()
                Text(region.revenue)
                    .accessibilityLabel("\(region.name): \(region.revenue)")
            }
        }
    }
}
```

## 5. Interactive Components (Topic 5)

#### iOS (SwiftUI)

```swift
// GOOD: button with state
Toggle(isOn: $isEnabled) {
    Text("Notifications")
}
// SwiftUI handles accessibility state automatically

// GOOD: custom component with traits and state
Button(action: toggleExpansion) {
    HStack {
        Text("Details")
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
    }
}
.accessibilityAddTraits(.isButton)
.accessibilityValue(isExpanded ? "expanded" : "collapsed")

// GOOD: custom slider
Slider(value: $volume, in: 0...100)
    .accessibilityLabel("Volume")
    .accessibilityValue("\(Int(volume)) percent")
```

## 6. Mandatory Elements (Topic 6)

#### iOS

```swift
// SwiftUI: screen title
NavigationView {
    ContentView()
        .navigationTitle("Settings")
}

// UIKit: screen title
override func viewDidLoad() {
    super.viewDidLoad()
    title = "Settings"
}

// App language: set in Info.plist CFBundleDevelopmentRegion
// and Localizable.strings
```

## 7. Information Structure (Topic 7)

#### iOS (SwiftUI)

```swift
// GOOD: heading semantics
Text("Account Settings")
    .font(.title)
    .accessibilityAddTraits(.isHeader)

Text("Privacy")
    .font(.headline)
    .accessibilityAddTraits(.isHeader)
```

## 8. Presentation of Information (Topic 8)

#### iOS

```swift
// GOOD: support Dynamic Type
Text("Welcome back")
    .font(.body) // respects system text size
    // Never use fixed point sizes for body text

// GOOD: allow both orientations in Info.plist
// UISupportedInterfaceOrientations: all orientations
```

## 9. Forms (Topic 9)

#### iOS (SwiftUI)

```swift
// GOOD: labelled text field
TextField("Email address", text: $email)
    .textContentType(.emailAddress) // enables autocomplete (9.12)
    .keyboardType(.emailAddress)
    .accessibilityLabel("Email address")
    .accessibilityHint("Required. Format: name@example.com")

// GOOD: field group
Section(header: Text("Personal information")) {
    TextField("First name", text: $firstName)
        .textContentType(.givenName)
    TextField("Last name", text: $lastName)
        .textContentType(.familyName)
}

// GOOD: error message
TextField("Email address", text: $email)
    .accessibilityLabel("Email address")
if let error = emailError {
    Text(error)
        .foregroundColor(.red)
        .accessibilityLabel("Error: \(error)")
        // Post notification so VoiceOver announces immediately
}
```

## 10. Navigation (Topic 10)

#### iOS (SwiftUI)

```swift
// GOOD: logical focus order
VStack {
    TextField("First name", text: $firstName)
    TextField("Last name", text: $lastName)
    Button("Submit") { submit() }
}
.accessibilityElement(children: .contain)
// SwiftUI follows visual order by default

// BAD: custom accessibility sort that breaks logical order
// .accessibilitySortPriority() — use only when needed
```

## 11. Consultation (Topic 11)

#### iOS

```swift
// GOOD: single-pointer alternative to pinch-to-zoom
// Provide + / - buttons alongside pinch gesture
ZStack {
    MapView()
    VStack {
        Spacer()
        HStack {
            Button(action: { zoomIn() }) {
                Image(systemName: "plus.magnifyingglass")
            }
            .accessibilityLabel("Zoom in")
            .frame(minWidth: 44, minHeight: 44) // minimum touch target

            Button(action: { zoomOut() }) {
                Image(systemName: "minus.magnifyingglass")
            }
            .accessibilityLabel("Zoom out")
            .frame(minWidth: 44, minHeight: 44)
        }
    }
}
```
