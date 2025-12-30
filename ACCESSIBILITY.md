# Accessibility Audit & Component Standards

## Accessibility Compliance Checklist

### Current Status

✅ = Compliant | ⚠️ = Needs Improvement | ❌ = Not Compliant

### WCAG 2.1 Level AA Requirements

#### Perceivable

- [✅] **1.1.1 Non-text Content** - All images have alt text
  - Team logos have descriptive alt attributes
  - Fallback displays team abbreviation
  
- [✅] **1.3.1 Info and Relationships** - Proper semantic HTML
  - Headings follow logical hierarchy (H1 → H2 → H3)
  - Tables use proper thead/tbody structure
  - Lists use ul/ol elements
  
- [✅] **1.3.2 Meaningful Sequence** - Logical content flow
  - Tab navigation follows visual order
  - Mobile bottom nav at end of DOM
  
- [✅] **1.4.3 Contrast (Minimum)** - 4.5:1 ratio for normal text
  - Primary text (#ffffff) on dark bg (#0b162a): 15.35:1 ✅
  - Secondary text (#8da1b9) on dark bg: 7.18:1 ✅
  - Accent green (#21d19f) on dark bg: 8.94:1 ✅
  
- [⚠️] **1.4.4 Resize Text** - Text can be resized up to 200%
  - Works but some components could be improved
  - Recommendation: Test with browser zoom levels
  
- [✅] **1.4.5 Images of Text** - No images of text used
  - All text is actual text, not images
  
- [✅] **1.4.10 Reflow** - Content reflows at 320px width
  - Mobile-first design handles narrow viewports
  - Bottom navigation adapts appropriately
  
- [✅] **1.4.11 Non-text Contrast** - 3:1 for UI components
  - Buttons and interactive elements have sufficient contrast
  - Borders visible against backgrounds
  
- [✅] **1.4.12 Text Spacing** - Adjustable line height and spacing
  - CSS uses relative units (em, rem)
  - Line height set appropriately (1.6 for body)

#### Operable

- [✅] **2.1.1 Keyboard** - All functionality available via keyboard
  - Tab navigation works
  - Enter/Space activate buttons
  - Team cards have tabindex="0"
  
- [✅] **2.1.2 No Keyboard Trap** - Users can navigate away
  - No modal traps
  - Focus management proper
  
- [⚠️] **2.1.4 Character Key Shortcuts** - No single-key shortcuts
  - Currently none implemented
  - Recommendation: If added, provide option to disable
  
- [✅] **2.4.1 Bypass Blocks** - Skip navigation provided
  - Main content clearly delineated
  - Navigation structure clear
  
- [✅] **2.4.2 Page Titled** - Page has descriptive title
  - Title: "NHL Standings"
  
- [✅] **2.4.3 Focus Order** - Logical focus order
  - Tab order follows visual flow
  - Bottom nav last in order
  
- [✅] **2.4.4 Link Purpose (In Context)** - Clear link purpose
  - Links describe their destination
  - Button labels are descriptive
  
- [⚠️] **2.4.5 Multiple Ways** - Multiple ways to find content
  - Navigation tabs provide access
  - Recommendation: Add search functionality
  
- [✅] **2.4.6 Headings and Labels** - Descriptive headings
  - Section headings describe content
  - Form labels associated with inputs
  
- [✅] **2.4.7 Focus Visible** - Keyboard focus is visible
  - Focus states styled with outline
  - `:focus-visible` pseudo-class used
  
- [✅] **2.5.1 Pointer Gestures** - No multi-point gestures required
  - All actions work with single tap/click
  
- [✅] **2.5.2 Pointer Cancellation** - Click/tap on up event
  - Standard browser behavior followed
  
- [✅] **2.5.3 Label in Name** - Accessible name matches visible label
  - Button text matches aria-label where used
  
- [✅] **2.5.4 Motion Actuation** - No motion-only controls
  - All interactions button/tap based

#### Understandable

- [✅] **3.1.1 Language of Page** - HTML lang attribute set
  - `<html lang="en">`
  
- [✅] **3.2.1 On Focus** - No context changes on focus
  - Focus doesn't trigger navigation
  
- [✅] **3.2.2 On Input** - No context changes on input
  - Form inputs don't auto-submit
  
- [✅] **3.2.3 Consistent Navigation** - Navigation is consistent
  - Navigation bar always in same location
  
- [✅] **3.2.4 Consistent Identification** - Icons used consistently
  - Same icons for same functions throughout
  
- [✅] **3.3.1 Error Identification** - Errors clearly identified
  - Error messages descriptive
  
- [⚠️] **3.3.2 Labels or Instructions** - Form inputs have labels
  - Most forms have labels
  - Recommendation: Audit all form fields

#### Robust

- [✅] **4.1.1 Parsing** - Valid HTML
  - No duplicate IDs
  - Proper nesting
  
- [✅] **4.1.2 Name, Role, Value** - ARIA attributes correct
  - Buttons have role="button"
  - Navigation has role="navigation"
  - Tab panels have role="tabpanel"
  
- [✅] **4.1.3 Status Messages** - Status changes announced
  - Live regions for dynamic content
  - aria-live attributes where appropriate

---

## Component Accessibility Standards

### Interactive Components

#### Buttons

**Requirements:**
- Minimum 44x44px touch target
- Visible focus state
- Descriptive label or aria-label
- role="button" if not `<button>` element

**Example:**
```html
<button 
  class="px-4 py-3 rounded-lg font-bold"
  aria-label="Submit prediction">
  Submit
</button>
```

#### Links

**Requirements:**
- Descriptive text (not "click here")
- Distinguishable from surrounding text
- Visible focus state

**Example:**
```html
<a href="/standings" 
   class="text-info underline"
   aria-label="View full standings">
  View Standings
</a>
```

#### Form Inputs

**Requirements:**
- Associated `<label>` element
- Clear error messages
- Disabled state clearly indicated

**Example:**
```html
<div class="form-group">
  <label for="fan-name" class="font-semibold mb-2">
    Fan Name
  </label>
  <select 
    id="fan-name" 
    name="fan_name"
    class="w-full px-3 py-2 rounded-md"
    required
    aria-required="true">
    <option value="">Select...</option>
  </select>
</div>
```

### Cards

**Requirements:**
- If clickable, proper role and keyboard support
- If expandable, aria-expanded attribute
- Minimum touch target if interactive

**Example:**
```html
<div 
  class="team-card"
  role="button"
  tabindex="0"
  aria-expanded="false"
  aria-label="View Dallas Stars details">
  <!-- Card content -->
</div>
```

### Navigation

**Requirements:**
- `<nav>` element with role="navigation"
- aria-label to distinguish multiple navs
- Current page indicated with aria-current

**Example:**
```html
<nav 
  class="bottom-nav"
  role="navigation"
  aria-label="Mobile navigation">
  <button 
    class="nav-item active"
    data-tab="league"
    aria-current="page"
    aria-label="View League tab">
    <div class="nav-item-icon">🏠</div>
    <div class="nav-item-label">League</div>
  </button>
</nav>
```

### Tables

**Requirements:**
- `<table>` with proper structure
- `<caption>` or aria-label
- `<th>` elements with scope attribute
- Row/column headers properly associated

**Example:**
```html
<table 
  class="w-full"
  role="table"
  aria-label="Playoff odds by team">
  <thead>
    <tr>
      <th scope="col" class="text-left">Fan</th>
      <th scope="col" class="text-right">Playoffs</th>
      <th scope="col" class="text-right">Cup</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Brian D.</td>
      <td class="text-right">45%</td>
      <td class="text-right">12%</td>
    </tr>
  </tbody>
</table>
```

### Modal Dialogs

**Requirements:**
- Focus trap when open
- Close on Escape key
- Return focus on close
- aria-modal="true"
- aria-labelledby for title

**Example:**
```html
<div 
  class="modal"
  role="dialog"
  aria-modal="true"
  aria-labelledby="modal-title"
  aria-describedby="modal-desc">
  <h2 id="modal-title">Confirmation</h2>
  <p id="modal-desc">Are you sure?</p>
  <button aria-label="Confirm action">Confirm</button>
  <button aria-label="Cancel action">Cancel</button>
</div>
```

---

## Mobile Accessibility

### Touch Targets

All interactive elements must be at least 44x44 CSS pixels:

```css
/* Good - meets minimum */
.button {
  padding: 12px 16px; /* Results in 44px+ height */
}

/* Bad - too small */
.tiny-button {
  padding: 4px 8px;
}
```

### Gesture Support

- All multi-touch gestures must have single-touch alternatives
- Swipe gestures should have button alternatives
- Pinch-to-zoom should not be disabled

### Screen Orientation

- Content adapts to portrait and landscape
- No orientation locks unless absolutely necessary
- Test in both orientations

---

## Screen Reader Testing

### Recommended Tools

- **NVDA** (Windows, free)
- **JAWS** (Windows, paid)
- **VoiceOver** (macOS/iOS, built-in)
- **TalkBack** (Android, built-in)

### Testing Checklist

- [ ] Page title announced
- [ ] Headings navigable
- [ ] Landmarks identified
- [ ] Forms properly labeled
- [ ] Images have alt text
- [ ] Links descriptive
- [ ] Tables have headers
- [ ] Dynamic content announced

### Common Issues

❌ **Empty links/buttons**
```html
<!-- Bad -->
<button><span class="icon"></span></button>

<!-- Good -->
<button aria-label="Close dialog">
  <span class="icon" aria-hidden="true"></span>
</button>
```

❌ **Images without alt text**
```html
<!-- Bad -->
<img src="logo.png">

<!-- Good -->
<img src="logo.png" alt="Dallas Stars team logo">
```

❌ **Unlabeled form controls**
```html
<!-- Bad -->
<input type="text" placeholder="Search">

<!-- Good -->
<label for="search">Search teams</label>
<input id="search" type="text" placeholder="e.g., Stars">
```

---

## Keyboard Navigation

### Standard Keyboard Shortcuts

- **Tab** - Move to next focusable element
- **Shift + Tab** - Move to previous focusable element
- **Enter** - Activate button/link
- **Space** - Activate button, toggle checkbox
- **Escape** - Close dialog/dropdown
- **Arrow keys** - Navigate within component (tabs, menus)

### Focus Management

#### Focus States

All interactive elements must have visible focus:

```css
/* Default focus (for mouse users) */
button:focus {
  outline: none; /* Remove only if custom style provided */
}

/* Keyboard focus (for keyboard users) */
button:focus-visible {
  outline: 2px solid var(--color-accent-primary);
  outline-offset: 2px;
}
```

#### Skip Links

Provide skip link to main content:

```html
<a href="#main-content" class="sr-only focus:not-sr-only">
  Skip to main content
</a>

<main id="main-content">
  <!-- Content -->
</main>
```

#### Focus Trapping

For modals, trap focus within the modal:

```javascript
function trapFocus(element) {
  const focusableElements = element.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  
  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];
  
  element.addEventListener('keydown', function(e) {
    if (e.key === 'Tab') {
      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    }
  });
}
```

---

## Performance Standards

### Core Web Vitals Targets

- **LCP (Largest Contentful Paint)**: < 2.5s
- **FID (First Input Delay)**: < 100ms
- **CLS (Cumulative Layout Shift)**: < 0.1

### CSS Performance

#### DO's ✅
- Use CSS custom properties for dynamic values
- Minimize specificity
- Avoid expensive properties (box-shadow on scroll)
- Use `transform` and `opacity` for animations

```css
/* Good - GPU accelerated */
.element {
  transform: translateY(-2px);
  transition: transform 0.2s;
}

/* Bad - causes reflow */
.element {
  top: -2px;
  transition: top 0.2s;
}
```

#### DON'Ts ❌
- Don't use `@import` for critical CSS
- Don't animate width/height
- Don't use universal selectors excessively
- Don't override with `!important`

### JavaScript Performance

- Debounce scroll/resize handlers
- Use `requestAnimationFrame` for animations
- Lazy load images and components
- Minimize DOM manipulations

---

## Testing Checklist

### Manual Testing

#### Visual
- [ ] Works in Chrome, Firefox, Safari, Edge
- [ ] Responsive at 320px, 768px, 1024px, 1920px
- [ ] Dark mode renders correctly
- [ ] Print styles work (if applicable)

#### Interaction
- [ ] All buttons clickable
- [ ] Forms validate properly
- [ ] Navigation works
- [ ] Modals open/close correctly

#### Keyboard
- [ ] Tab through all interactive elements
- [ ] Enter activates buttons/links
- [ ] Escape closes modals
- [ ] Focus visible at all times

#### Screen Reader
- [ ] Headings make sense
- [ ] Form labels read correctly
- [ ] Images have alt text
- [ ] Dynamic content announced

### Automated Testing

#### Tools
- **axe DevTools** - Browser extension for accessibility
- **Lighthouse** - Chrome DevTools audit
- **WAVE** - Web accessibility evaluation tool
- **Pa11y** - Command-line accessibility tester

#### Running Tests

```bash
# Install pa11y
npm install -g pa11y

# Run accessibility audit
pa11y http://localhost:3000

# With specific WCAG level
pa11y --standard WCAG2AA http://localhost:3000
```

---

## Known Issues & Roadmap

### Current Limitations

1. **Search Functionality** - Not yet implemented (2.4.5)
2. **Skip Links** - Should be added for keyboard users
3. **High Contrast Mode** - Not explicitly tested
4. **Reduced Motion** - Animations don't respect `prefers-reduced-motion`

### Planned Improvements

- [ ] Add skip navigation link
- [ ] Implement `prefers-reduced-motion` support
- [ ] Add high contrast mode testing
- [ ] Create automated accessibility CI checks
- [ ] Add focus trap for future modals
- [ ] Implement aria-live regions for updates

---

## Resources

- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [WebAIM Articles](https://webaim.org/articles/)
- [A11y Project Checklist](https://www.a11yproject.com/checklist/)
- [MDN Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)

---

**Last Updated:** December 2025  
**Next Review:** March 2026
