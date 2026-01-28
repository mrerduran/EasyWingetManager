## 2024-05-22 - Non-semantic Navigation Pattern
**Learning:** The application uses `li` elements with `onclick` handlers for main navigation tabs, which by default makes them inaccessible to keyboard users and screen readers.
**Action:** When encountering this pattern, manually implement `role="button"`, `tabindex="0"`, and add `keydown` event listeners for Enter/Space keys to restore accessibility.
