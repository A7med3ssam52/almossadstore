# Research: Shopping Cart UI Refinement

## Decisions & Rationale

### 1. UI: Glassmorphism & Animations
- **Decision**: Use `backdrop-blur-md` with semi-transparent backgrounds (e.g., `bg-white/80`).
- **Rationale**: Provides the "premium" feel requested by the user. Aligning with the project's aesthetic goals.
- **Alternatives**: Solid backgrounds were rejected for looking "flat" and "generic".

### 2. Sync: Immediate Persistence
- **Decision**: Trigger API updates for `cart_items` (on Supabase) immediately upon quantity changes, but with a slight debounce (300ms) to avoid overlapping requests.
- **Rationale**: Balances the user's "Immediate Sync" requirement with system stability and rate limiting.
- **Alternatives**: Pure immediate sync (no debounce) might cause performance issues if a user clicks rapidly.

### 3. State: Framer Motion Transitions
- **Decision**: Use `AnimatePresence` with `spring` transitions for the side drawer.
- **Rationale**: Smooth, high-performance animations that follow the "premium" principle.
- **Alternatives**: Simple CSS transitions were considered but lacked the "WOW" factor.

## Constraints & Dependencies
- **Tailwind CSS**: Required for layout and glassmorphism.
- **Framer Motion**: Required for drawer transitions and list animations.
- **Supabase**: Backend for data persistence.
