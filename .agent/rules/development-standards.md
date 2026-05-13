## Development Standards

This project follows strict development standards that must be applied automatically.

### Context & Architecture
- Always use `graphify query`, `graphify path`, or `graphify explain` commands before making changes
- Check existing patterns and structure before implementing new features
- Maintain consistency with established architecture

### UI/UX Standards
- Match existing design system (colors, typography, spacing, shadows)
- No SafeArea unless explicitly requested
- Ensure full responsiveness (no overflow, RenderFlex, or keyboard issues)
- Use MediaQuery, Expanded, Flexible, SingleChildScrollView appropriately

### Code Quality
- Clean, modular, reusable code
- Meaningful variable names
- Proper separation of concerns
- No duplicate code or unused imports
- Performance-focused implementation

### Security
- Never store secrets in frontend code
- Use .env files (gitignored) for credentials
- No hardcoded API keys, tokens, or credentials

### Workflow
- Break large tasks into subtasks
- Execute step-by-step
- Test thoroughly before completion
- Commit with proper format: `feat:`, `fix:`, `refactor:`, `ui:`
- Update README when needed

### Error Prevention
- Check console errors, null safety, navigation flow
- Verify loading and error states
- No incomplete placeholder implementations

See `.kiro/steering/development-rules.md` for complete details.
