```markdown
# The Executive Assistant: A Design System for Premium Financial Intelligence

## 1. Overview & Creative North Star

### Creative North Star: "The Digital Concierge"
This design system moves beyond the utility of a standard fintech app and enters the realm of a high-end personal assistant. It is defined by **Tonal Architecture** and **Editorial Precision**. We reject the "boxed-in" feeling of traditional dashboards in favor of an expansive, airy, and layered environment that feels proactive rather than reactive.

To achieve this, we employ:
*   **Intentional Asymmetry:** Using the `20` (5rem) and `24` (6rem) spacing tokens to create "breathing rooms" that guide the eye to key financial insights.
*   **Layered Translucency:** Utilizing glassmorphism and the `surface-container` tiers to create a UI that feels like physical sheets of premium glass and paper stacked together.
*   **Data as Art:** Treating charts and numbers not as clinical data points, but as glowing, organic signals of growth and health.

---

## 2. Colors & Surface Architecture

The color system is rooted in the depth of `primary` (#101a77) and the vitality of `secondary` (#006b5c). 

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined solely through background color shifts or tonal transitions. To separate a section, place a `surface-container-low` (#f6f3f2) card atop a `surface` (#fcf9f8) background.

### Surface Hierarchy & Nesting
Depth is built through the Material 3 surface tokens. Use these to "nest" importance:
1.  **Base Layer:** `surface` (#fcf9f8) – The canvas.
2.  **Sectional Layer:** `surface-container-low` (#f6f3f2) – Large groupings of content.
3.  **Active Component Layer:** `surface-container-lowest` (#ffffff) – High-priority cards or input fields.
4.  **Information Layer:** `surface-container-high` (#ebe7e7) – Subtle callouts or secondary data points.

### The "Glass & Gradient" Rule
For high-impact elements (Balance Cards, Hero CTAs), use a signature gradient:
*   **Primary Gradient:** `primary` (#101a77) to `primary_container` (#2b348d) at a 135° angle.
*   **Signature Glow:** Apply a `secondary_fixed` (#68fadd) inner glow at 10% opacity to "Growth" components to simulate high-end digital illumination.

---

## 3. Typography: Editorial Authority

We use a dual-font approach to balance professional weight with approachable clarity.

*   **Display & Headlines (Manrope):** Chosen for its geometric precision and modern "tech-premium" feel. Use `display-lg` (3.5rem) sparingly for big financial milestones. Headlines should use `headline-md` (1.75rem) with a tight letter-spacing (-0.02em) to command authority.
*   **Body & Labels (Inter):** The workhorse font. Inter’s tall x-height ensures that complex financial figures remain legible at small sizes (`body-sm`, 0.75rem). 

**Hierarchy Strategy:** 
*   **The Power Lockup:** Pair a `headline-sm` (Manrope) with a `label-md` (Inter, All Caps, 0.05em tracking) for card headers to create an editorial, magazine-like feel.

---

## 4. Elevation & Depth

Standard shadows are too heavy for a premium experience. We use **Tonal Layering** supplemented by **Ambient Light**.

*   **The Layering Principle:** A `surface-container-lowest` card on a `surface-container-low` background provides enough contrast for the human eye without a shadow. This is the preferred method for 90% of the UI.
*   **Ambient Shadows:** When a card must "float" (e.g., a modal or a primary action card), use an extra-diffused shadow: `offset: 0, 12px; blur: 40px; color: rgba(16, 26, 119, 0.06)`. Note the use of the `primary` hue in the shadow to keep the palette cohesive.
*   **Ghost Borders:** If accessibility requires a border (e.g., in high-glare environments), use `outline-variant` (#c7c5d4) at 20% opacity. Never use 100% opaque outlines.
*   **Glassmorphism:** For the bottom navigation bar or floating action buttons, use `surface-container-lowest` at 80% opacity with a `24px` backdrop blur.

---

## 5. Components

### Cards
*   **Radius:** Always `xl` (1.5rem/24px) or `lg` (1rem/16px).
*   **Padding:** Standardized to `spacing-6` (1.5rem) to ensure data feels "expensive" and uncrowded.
*   **Visual Rule:** No divider lines. Use `spacing-4` (1rem) of vertical white space to separate list items within a card.

### Buttons
*   **Primary:** Gradient from `primary` to `primary_container`. Border radius `full`.
*   **Secondary:** Ghost style using `surface-container-high` as the background with `primary` text.
*   **Interaction:** On press, apply a 2px outer glow using `primary_fixed_dim` (#bdc2ff).

### The Financial Health Chart
*   **Line Graphs:** Use a `2px` stroke with a `secondary_fixed_dim` (#44ddc1) glow. Fill the area beneath with a gradient from `secondary_fixed` (20% opacity) to transparent.
*   **Donut Charts:** Use a thick stroke (12px) with `lg` rounded caps. Segments should use tonal shifts from `primary` to `secondary`.

### Status Indicators (Micro-Feedback)
*   **Synced:** `secondary` (#006b5c) with a subtle pulse.
*   **Pending:** `tertiary_container` (#830012) – soft, not alarming.
*   **Offline:** `outline` (#777683).
*   *Note: Use `label-sm` text alongside these colors to ensure accessibility.*

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical margins (e.g., more space at the top of a page than the sides) to create an editorial layout.
*   **Do** use `secondary` (#006b5c) for positive financial trends. It signals growth without the "stoplight" cliché of bright lime green.
*   **Do** use `surface-container-highest` for inactive states or empty progress bars to maintain the "physical material" feel.

### Don't
*   **Don't** use pure black (#000000). Always use `on-surface` (#1c1b1b) for text to maintain a soft, premium contrast.
*   **Don't** use 1px lines to separate list items. Use tonal backgrounds or the `spacing-px` value with 10% opacity if absolutely necessary.
*   **Don't** overcrowd the screen. If a view feels busy, increase the spacing from `8` (2rem) to `12` (3rem). In high-end design, white space is a luxury feature.

### Accessibility Note
Ensure all `on-surface` text on `surface` backgrounds maintains a 4.5:1 contrast ratio. When using `secondary` teal accents for data, ensure they are accompanied by a text label or icon to convey meaning without relying solely on color.```