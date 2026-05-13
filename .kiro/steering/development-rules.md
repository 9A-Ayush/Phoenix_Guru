---
inclusion: auto
---

# AI Development Rules — Mandatory Project Standards

These rules are global and must be followed automatically in every task, screen, feature, refactor, and update without requiring manual reminders.

## 1. Project Context Usage

- Always use the `graphify` command for project context understanding before making changes
- Never assume architecture, flow, theme, or navigation structure without checking project context first
- Maintain consistency with existing project structure and patterns

## 2. UI/UX Consistency

Every newly created screen must exactly match the existing app design system.

Follow the existing:
- Color palette
- Typography
- Spacing
- Border radius
- Shadows
- Component patterns
- Animations
- Layout structure

**Do not introduce random styling or inconsistent UI patterns.**

## 3. SafeArea Restriction

- **Do NOT use SafeArea** in any screen unless explicitly instructed
- Handle spacing manually using proper padding and layout structure

## 4. Task Execution Workflow

Always break large tasks into small actionable subtasks before implementation.

Execute tasks step-by-step in a logical order.

Clearly track completed and pending tasks during implementation.

**Example workflow:**
1. Analyze existing structure
2. Create backend logic
3. Create UI
4. Connect state management
5. Add validation
6. Test responsiveness
7. Fix overlays/errors
8. Push changes

## 5. Overlay & Responsiveness Rules

Every screen must be fully responsive.

**Prevent all:**
- Overflow errors
- RenderFlex errors
- Bottom overflow issues
- Keyboard overlap issues
- Unbounded height issues

**Properly use:**
- MediaQuery
- Expanded
- Flexible
- SingleChildScrollView
- Responsive sizing

Test layouts for different screen sizes before finalizing.

## 6. Git & Documentation Workflow

After completing EVERY task:

### Mandatory Actions
- Push changes to GitHub
- Write a clean professional commit message
- Update the README.md if:
  - New features are added
  - Setup steps changed
  - Dependencies changed
  - Architecture changed

### Commit Message Format

```
feat: add live quiz leaderboard
```

**Examples:**
- `feat: add live quiz leaderboard`
- `fix: resolve overflow issue in quiz screen`
- `refactor: optimize auth state handling`
- `ui: redesign teacher dashboard`

## 7. Security Rules

**NEVER store:**
- API keys
- Secrets
- Tokens
- Credentials
- Private URLs

inside frontend code.

### Mandatory Security Standards

- All secrets must remain in backend or environment files
- `.env` files must never be pushed to GitHub
- Add sensitive files to `.gitignore`
- Never hardcode credentials in:
  - Dart files
  - JavaScript files
  - Config files
  - Client-side requests

Always follow secure backend communication practices.

## 8. Code Quality Standards

**Always write:**
- Clean code
- Modular code
- Reusable components
- Optimized logic
- Proper folder structure
- Scalable architecture

**Avoid:**
- Duplicate code
- Unused imports
- Large monolithic widgets
- Hardcoded values
- Poor naming conventions
- Deeply nested widgets when avoidable

**Required:**
- Meaningful variable names
- Proper comments where necessary
- Separation of concerns
- Performance-focused implementation

## 9. Error Prevention Rules

Before completing any task:

- ✅ Check for console errors
- ✅ Check for overlay/render issues
- ✅ Check null safety
- ✅ Check navigation flow
- ✅ Check backend/frontend integration
- ✅ Check loading and error states

**Never leave incomplete placeholder implementations.**

## 10. Automatic Rule Enforcement

These rules are permanent project standards.

The AI assistant must:
- Automatically apply these rules in every response and implementation
- Never require manual reminders
- Never ignore these standards unless explicitly overridden by the user

**These rules apply globally across the entire project lifecycle.**
