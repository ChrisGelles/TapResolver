# Contributing to TapResolver

## Development Workflow

### Branch Strategy
- `main` - Production-ready code
- `develop` - Integration branch (if used)
- Feature branches - `feature/description` or descriptive names like `rewiring-beacon-dots`

### Pre-Merge Checklist

Before opening a PR, ensure:

1. **Working tree is clean**
   ```bash
   git status
   ```
   Should show: `nothing to commit, working tree clean`

2. **Branch is pushed**
   ```bash
   git log origin/your-branch..HEAD --oneline
   ```
   Should show: (empty - no output)

3. **Main is up to date**
   ```bash
   git checkout main
   git pull origin main
   ```

4. **Feature branch is not behind main**
   ```bash
   git checkout your-branch
   git log HEAD..origin/main --oneline
   ```
   Should show: (empty - no output)

5. **Code builds successfully**
   - Open Xcode, build (`⌘B`)
   - No build errors or warnings

6. **Manual testing completed**
   - App launches
   - Core features work
   - No obvious console errors

### Pull Request Process

1. **Create PR** with descriptive title and description
2. **Fill out PR template** completely
3. **Wait for CI checks** to pass
4. **Get at least one approval** (if required)
5. **Merge** using merge commit (not rebase for shared branches)
6. **Delete feature branch** after merge

### Code Style

- Follow Swift naming conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and reasonably sized
- Run SwiftLint before committing:
  ```bash
  swiftlint lint
  ```

### Commit Messages

- Use present tense: "Add feature" not "Added feature"
- Be descriptive but concise
- Reference issues/PRs if applicable

Example:
```
Consolidate beacon dot persistence to V2 single source of truth

- Remove legacy dots.json and separate UserDefaults keys
- Add BeaconDotV2 struct for consolidated storage
- Add recovery function for legacy data migration
```

### Testing

- Test on device when possible
- Test on simulator for quick iterations
- Verify no console errors or warnings
- Test edge cases and error conditions

### Documentation

- Update README.md for user-facing changes
- Add inline comments for complex logic
- Update architecture docs if significant changes
- Document migration paths for data model changes

## Branch Protection Rules

The `main` branch is protected with:
- Require pull request reviews before merging
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Do not allow force pushes
- Do not allow deletions

## Getting Help

- Check existing documentation in `/docs` or root `.md` files
- Review similar code in the codebase
- Ask questions in PR comments

## Data Migration Guidelines

When changing persistence models:

1. **Provide migration path** - Don't break existing user data
2. **Add recovery tools** - Diagnostic functions to recover from legacy formats
3. **Document migration** - Clear instructions for users/collaborators
4. **Test migration** - Verify data survives app updates
5. **Monitor for issues** - Watch for user reports of missing data

Example: See `BeaconDotStore` V2 migration for reference.

