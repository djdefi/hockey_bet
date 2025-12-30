# NHL Fan League - Design System Documentation

## Overview

This design system provides a comprehensive set of design tokens, components, and utilities for building consistent, accessible, and performant user interfaces in the NHL Fan League application.

**Version:** 1.0.0  
**Last Updated:** December 2025

---

## Table of Contents

1. [Design Principles](#design-principles)
2. [Design Tokens](#design-tokens)
3. [Utility Classes](#utility-classes)
4. [Components](#components)
5. [Accessibility Guidelines](#accessibility-guidelines)
6. [Best Practices](#best-practices)
7. [Migration Guide](#migration-guide)

---

## Design Principles

### 1. Consistency
- Use design tokens for all styling decisions
- Follow established patterns for common UI elements
- Maintain visual hierarchy throughout the application

### 2. Accessibility
- WCAG 2.1 AA compliance minimum
- Keyboard navigation support
- Screen reader friendly markup
- Sufficient color contrast ratios

### 3. Performance
- Mobile-first responsive design
- Efficient CSS with minimal specificity
- Optimize for Core Web Vitals

### 4. Maintainability
- Use utility classes for rapid development
- Keep component styles DRY (Don't Repeat Yourself)
- Document custom patterns

---

## Design Tokens

Design tokens are stored in `lib/design-tokens.css` and provide the foundation for all styling.

### Color System

#### Primary Colors
```css
--color-bg-primary: #0b162a;     /* Main background */
--color-bg-secondary: #1a253a;   /* Cards, elevated surfaces */
--color-bg-tertiary: #2a3a52;    /* Hover states, borders */
```

#### Text Colors
```css
--color-text-primary: #ffffff;    /* Primary text */
--color-text-secondary: #8da1b9;  /* Secondary text, labels */
--color-text-muted: #6b7d93;      /* Tertiary text */
```

#### Accent Colors
```css
--color-accent-primary: #21d19f;  /* Green - Success, CTAs */
--color-accent-danger: #e74c3c;   /* Red - Errors, losses */
--color-accent-warning: #f39c12;  /* Orange - Warnings */
--color-accent-info: #2980b9;     /* Blue - Info, links */
```

**Usage:**
```html
<!-- Use utility classes -->
<div class="bg-secondary text-primary">Content</div>

<!-- Or reference directly in CSS -->
.custom-component {
  background-color: var(--color-bg-secondary);
  color: var(--color-text-primary);
}
```

### Spacing System

Based on a 4px (0.25rem) scale:

```css
--space-0: 0;
--space-1: 0.25rem;  /* 4px */
--space-2: 0.5rem;   /* 8px */
--space-3: 0.75rem;  /* 12px */
--space-4: 1rem;     /* 16px */
--space-5: 1.25rem;  /* 20px */
--space-6: 1.5rem;   /* 24px */
--space-8: 2rem;     /* 32px */
```

**Usage:**
```html
<!-- Use utility classes -->
<div class="p-4 m-2">Content</div>
<div class="px-3 py-2">Content</div>
<div class="gap-4">Content</div>

<!-- In CSS -->
.custom-spacing {
  padding: var(--space-4);
  margin-top: var(--space-2);
}
```

### Typography System

#### Font Sizes
```css
--font-size-xs: 0.65rem;    /* 10.4px */
--font-size-sm: 0.75rem;    /* 12px */
--font-size-base: 0.875rem; /* 14px */
--font-size-md: 0.95rem;    /* 15.2px */
--font-size-lg: 1rem;       /* 16px */
--font-size-xl: 1.125rem;   /* 18px */
--font-size-2xl: 1.25rem;   /* 20px */
--font-size-3xl: 1.5rem;    /* 24px */
```

#### Font Weights
```css
--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;
--font-weight-extrabold: 800;
```

**Usage:**
```html
<h1 class="text-3xl font-extrabold">Main Heading</h1>
<h2 class="text-2xl font-bold">Section Heading</h2>
<p class="text-base font-normal">Body text</p>
<small class="text-sm text-secondary">Helper text</small>
```

### Border Radius
```css
--radius-sm: 4px;
--radius-md: 6px;
--radius-lg: 8px;
--radius-xl: 10px;
--radius-2xl: 12px;
--radius-3xl: 16px;
--radius-full: 9999px;
```

**Usage:**
```html
<div class="rounded-2xl">Card</div>
<button class="rounded-lg">Button</button>
<span class="rounded-full">Badge</span>
```

### Shadows & Elevation
```css
--shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.1);
--shadow-md: 0 4px 12px rgba(0, 0, 0, 0.15);
--shadow-lg: 0 8px 24px rgba(0, 0, 0, 0.2);
--shadow-xl: 0 12px 32px rgba(0, 0, 0, 0.25);
```

**Usage:**
```html
<div class="shadow-md">Slightly elevated</div>
<div class="shadow-lg">More elevated</div>
```

---

## Utility Classes

Utility classes are stored in `lib/utilities.css` and provide atomic styling.

### Spacing Utilities

#### Margin
```html
<!-- All sides -->
<div class="m-0">No margin</div>
<div class="m-2">8px margin</div>
<div class="m-4">16px margin</div>

<!-- Individual sides -->
<div class="mt-2">Margin top</div>
<div class="mr-4">Margin right</div>
<div class="mb-3">Margin bottom</div>
<div class="ml-2">Margin left</div>

<!-- Horizontal / Vertical -->
<div class="mx-auto">Center horizontally</div>
<div class="my-4">Margin Y axis</div>
```

#### Padding
```html
<div class="p-4">16px padding</div>
<div class="px-3 py-2">Different X and Y</div>
<div class="pt-0 pb-4">Top and bottom only</div>
```

### Typography Utilities

```html
<!-- Size -->
<p class="text-xs">Extra small</p>
<p class="text-sm">Small</p>
<p class="text-base">Base size (14px)</p>
<p class="text-lg">Large</p>
<p class="text-2xl">2X Large</p>

<!-- Weight -->
<p class="font-normal">Regular</p>
<p class="font-semibold">Semi-bold</p>
<p class="font-bold">Bold</p>
<p class="font-extrabold">Extra bold</p>

<!-- Alignment -->
<p class="text-left">Left aligned</p>
<p class="text-center">Centered</p>
<p class="text-right">Right aligned</p>

<!-- Colors -->
<p class="text-primary">Primary text color</p>
<p class="text-secondary">Secondary text color</p>
<p class="text-success">Success green</p>
<p class="text-danger">Error red</p>
```

### Layout Utilities

```html
<!-- Display -->
<div class="block">Block element</div>
<div class="flex">Flexbox container</div>
<div class="grid">Grid container</div>
<div class="hidden">Hidden element</div>

<!-- Flexbox -->
<div class="flex items-center justify-between">
  <span>Left</span>
  <span>Right</span>
</div>

<div class="flex flex-col gap-2">
  <div>Item 1</div>
  <div>Item 2</div>
</div>

<!-- Grid -->
<div class="grid grid-cols-2 gap-4">
  <div>Column 1</div>
  <div>Column 2</div>
</div>
```

### Responsive Utilities

Use `md:` prefix for desktop breakpoint (768px+):

```html
<!-- Hidden on mobile, visible on desktop -->
<div class="hidden md:block">Desktop only</div>

<!-- Column on mobile, row on desktop -->
<div class="flex flex-col md:flex-row">
  <div>Item</div>
  <div>Item</div>
</div>

<!-- Different grid columns -->
<div class="grid grid-cols-1 md:grid-cols-3">
  <!-- Columns -->
</div>
```

---

## Components

### Cards

```html
<!-- Basic card -->
<div class="bg-secondary rounded-2xl p-4 border border-default">
  <h3 class="text-lg font-bold mb-2">Card Title</h3>
  <p class="text-secondary">Card content</p>
</div>

<!-- Elevated card with hover -->
<div class="bg-secondary rounded-2xl p-4 shadow-md hover:shadow-lg transition">
  Content
</div>
```

### Buttons

```html
<!-- Primary button -->
<button class="bg-primary text-primary px-4 py-3 rounded-lg font-bold 
               hover:bg-hover transition cursor-pointer">
  Primary Action
</button>

<!-- Secondary button -->
<button class="bg-secondary text-primary px-4 py-3 rounded-lg font-semibold 
               border border-default hover:border-primary transition">
  Secondary Action
</button>

<!-- Danger button -->
<button class="bg-danger text-primary px-4 py-3 rounded-lg font-bold 
               hover:opacity-75 transition">
  Delete
</button>
```

### Badges

```html
<!-- Status badge -->
<span class="inline-flex items-center px-3 py-1 rounded-full 
             bg-success text-primary text-xs font-semibold">
  ✓ Active
</span>

<!-- Count badge -->
<span class="inline-flex items-center justify-center w-6 h-6 
             rounded-full bg-danger text-primary text-xs font-bold">
  3
</span>
```

### Navigation

The app uses a fixed bottom navigation on mobile and desktop tabs:

```html
<!-- Mobile bottom nav (auto-hidden on desktop) -->
<nav class="bottom-nav">
  <button class="nav-item active" data-tab="league">
    <div class="nav-item-icon">🏠</div>
    <div class="nav-item-label">League</div>
  </button>
  <!-- More items -->
</nav>

<!-- Desktop tabs (auto-hidden on mobile) -->
<nav class="desktop-tabs">
  <button class="desktop-tab active" data-tab="league">League</button>
  <!-- More tabs -->
</nav>
```

### Team Cards

```html
<div class="team-card">
  <div class="team-card-main">
    <div class="team-card-left">
      <div class="team-rank">1</div>
      <img src="..." class="team-logo w-10 h-10 object-contain mr-3">
      <div class="team-info">
        <div class="team-name">Team Name</div>
        <div class="team-fan">Fan Name</div>
        <span class="status-badge">Status</span>
      </div>
    </div>
    <div class="team-card-right">
      <div class="team-points">
        <div class="team-points-value">45</div>
        <div class="team-points-label">PTS</div>
      </div>
    </div>
  </div>
</div>
```

---

## Accessibility Guidelines

### ARIA Labels

Always provide ARIA labels for interactive elements:

```html
<!-- Buttons -->
<button aria-label="Close modal" class="...">×</button>

<!-- Navigation -->
<nav role="navigation" aria-label="Main navigation">...</nav>

<!-- Sections -->
<section role="region" aria-label="Team standings">...</section>
```

### Keyboard Navigation

Ensure all interactive elements are keyboard accessible:

```html
<!-- Add tabindex for focusable elements -->
<div class="team-card" tabindex="0" role="button">...</div>

<!-- Visible focus states -->
<button class="... focus-visible:outline">Submit</button>
```

### Screen Reader Support

Use semantic HTML and appropriate ARIA attributes:

```html
<!-- Screen reader only text -->
<span class="sr-only">Additional context for screen readers</span>

<!-- Proper heading hierarchy -->
<h1>Main Title</h1>
<h2>Section Title</h2>
<h3>Subsection Title</h3>

<!-- Status updates -->
<div role="status" aria-live="polite">
  Updated standings available
</div>
```

### Color Contrast

All text must meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text):

✅ **Good Examples:**
- White text (#ffffff) on dark blue (#0b162a) - 15.35:1
- Secondary text (#8da1b9) on dark blue (#0b162a) - 7.18:1
- Green accent (#21d19f) on dark blue (#0b162a) - 8.94:1

❌ **Bad Examples:**
- Light gray on white - insufficient contrast
- Yellow on white - insufficient contrast

### Touch Targets

All interactive elements must be at least 44x44px:

```html
<!-- Good: Minimum touch target -->
<button class="px-4 py-3">Button</button>

<!-- Bad: Too small -->
<button class="px-1 py-1">Small</button>
```

---

## Best Practices

### DO's ✅

1. **Use design tokens consistently**
   ```css
   /* Good */
   .my-component {
     color: var(--color-text-primary);
     padding: var(--space-4);
   }
   
   /* Bad */
   .my-component {
     color: #ffffff;
     padding: 16px;
   }
   ```

2. **Prefer utility classes over custom CSS**
   ```html
   <!-- Good -->
   <div class="flex items-center gap-2 p-4 bg-secondary rounded-lg">
   
   <!-- Bad -->
   <div class="custom-container" style="display: flex; align-items: center;">
   ```

3. **Use semantic HTML**
   ```html
   <!-- Good -->
   <nav role="navigation">
     <button>Home</button>
   </nav>
   
   <!-- Bad -->
   <div onclick="navigate()">
     <div>Home</div>
   </div>
   ```

4. **Mobile-first responsive design**
   ```css
   /* Good - mobile first */
   .element {
     flex-direction: column;
   }
   
   @media (min-width: 768px) {
     .element {
       flex-direction: row;
     }
   }
   ```

5. **Document custom patterns**
   ```css
   /* Custom badge pattern for dynamic backgrounds */
   .achievement-badge {
     background-color: var(--badge-bg, transparent);
   }
   ```

### DON'Ts ❌

1. **Don't use inline styles (except for dynamic values)**
   ```html
   <!-- Bad -->
   <div style="color: red; padding: 10px;">
   
   <!-- Good -->
   <div class="text-danger p-2">
   
   <!-- OK for dynamic values -->
   <div style="--badge-bg: <%= dynamic_color %>;">
   ```

2. **Don't use !important unless absolutely necessary**
   ```css
   /* Bad */
   .my-class {
     color: red !important;
   }
   
   /* Good */
   .my-class {
     color: var(--color-accent-danger);
   }
   ```

3. **Don't use magic numbers**
   ```css
   /* Bad */
   .spacing {
     margin: 13px;
     padding: 17px;
   }
   
   /* Good */
   .spacing {
     margin: var(--space-3);
     padding: var(--space-4);
   }
   ```

4. **Don't nest selectors too deeply**
   ```css
   /* Bad */
   .nav .menu .item .link .icon {
     color: blue;
   }
   
   /* Good */
   .nav-icon {
     color: var(--color-accent-info);
   }
   ```

5. **Don't forget accessibility**
   ```html
   <!-- Bad -->
   <div onclick="doSomething()">Click me</div>
   
   <!-- Good -->
   <button aria-label="Action description" onclick="doSomething()">
     Click me
   </button>
   ```

---

## Migration Guide

### From Old Inline Styles to Utilities

#### Common Conversions

| Old Inline Style | New Utility Class |
|-----------------|-------------------|
| `style="display: none;"` | `class="hidden"` |
| `style="display: flex;"` | `class="flex"` |
| `style="text-align: center;"` | `class="text-center"` |
| `style="margin-bottom: 1rem;"` | `class="mb-4"` |
| `style="padding: 0.75rem;"` | `class="p-3"` |
| `style="font-size: 0.875rem;"` | `class="text-base"` |
| `style="font-weight: 700;"` | `class="font-bold"` |
| `style="color: #8da1b9;"` | `class="text-secondary"` |
| `style="border-radius: 12px;"` | `class="rounded-2xl"` |
| `style="background: #1a253a;"` | `class="bg-secondary"` |

#### Step-by-Step Migration

1. **Identify the inline styles**
   ```html
   <!-- Before -->
   <div style="display: flex; align-items: center; gap: 0.5rem; padding: 1rem;">
   ```

2. **Map to utility classes**
   - `display: flex` → `flex`
   - `align-items: center` → `items-center`
   - `gap: 0.5rem` → `gap-2`
   - `padding: 1rem` → `p-4`

3. **Apply the utilities**
   ```html
   <!-- After -->
   <div class="flex items-center gap-2 p-4">
   ```

4. **Test thoroughly**
   - Visual regression testing
   - Responsive behavior
   - Accessibility compliance

### Handling Dynamic Styles

For truly dynamic values (e.g., calculated widths, colors from database):

```html
<!-- Use CSS custom properties -->
<div class="stat-bar-fill" style="--fill-width: <%= percentage %>%;">
```

```css
.stat-bar-fill {
  width: var(--fill-width);
}
```

---

## File Organization

```
lib/
├── design-tokens.css     # Design tokens (colors, spacing, typography)
├── utilities.css         # Atomic utility classes
├── styles.css           # Main stylesheet (imports above + components)
├── playoff_styles.css   # Playoff-specific styles
├── standings.html.erb   # Main template
└── *.js                # JavaScript files
```

---

## Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [MDN Web Docs](https://developer.mozilla.org/)
- [Can I Use](https://caniuse.com/) - Browser compatibility
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

---

## Changelog

### Version 1.0.0 (December 2025)
- Initial design system documentation
- Created design token system
- Created utility class library
- Migrated majority of inline styles to utilities
- Established accessibility guidelines
- Defined best practices

---

## Support

For questions or suggestions about the design system:

1. Review this documentation
2. Check existing components for patterns
3. Refer to design tokens for values
4. Create an issue if something is unclear

---

**Maintained by:** NHL Fan League Team  
**License:** MIT
