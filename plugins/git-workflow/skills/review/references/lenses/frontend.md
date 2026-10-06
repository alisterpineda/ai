# Frontend Lens

This diff changes what users see and interact with: components, templates, styles, client-side state, or routing. Frontend bugs hide in what the author's own session never exercised — a keyboard instead of a mouse, a slow network, a narrow screen, a second click, a screen reader. Hunt the hazards below through your own charter's attitude; this lens adds things to look for and never changes your charter's rules or output format.

## Hazards

- **Keyboard and screen-reader access.** Interactive non-semantic elements (a clickable `div`) that can't be focused or activated by keyboard; inputs without labels; images without alt text; focus not moved into or restored from dialogs and route changes; `aria-hidden` on focusable content; ARIA roles that contradict the element.
- **Meaning carried only visually.** State shown only by color, insufficient contrast, icons without accessible names, motion with no reduced-motion handling.
- **Async races.** An older response overwriting a newer one, updates after unmount, double submission, missing loading, error, and empty states.
- **Stale and duplicated state.** Effects with missing dependencies that read stale values, derived data copied into state and drifting from its source, list keys that break on reorder.
- **Injection sinks.** User-controlled content reaching raw-HTML sinks (`innerHTML`, `dangerouslySetInnerHTML`, `v-html`) or URL attributes without sanitization.
- **Server/client mismatch.** Server-rendered output that differs on the client (time, randomness, browser-only APIs during render), breaking hydration.
- **Layout under real conditions.** Narrow viewports, long or translated text, right-to-left scripts, zoom, unsized media that shifts the layout as it loads.
- **Rendering cost.** Re-render cascades from unstable props or context, heavy work during render, large dependencies pulled in for a small use.
- **Client-only validation.** Rules enforced in the form but not on the server they protect.
