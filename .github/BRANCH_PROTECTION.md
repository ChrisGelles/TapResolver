# Branch Protection Settings

This document describes the recommended branch protection settings for the `main` branch. Configure these in GitHub under **Settings → Branches → Branch protection rules**.

## Required Settings

### ✅ Require pull request reviews before merging
- **Required number of approvals:** 1
- **Dismiss stale pull request approvals when new commits are pushed:** ✅ Enabled
- **Require review from Code Owners:** Optional (if CODEOWNERS file exists)

### ✅ Require status checks to pass before merging
- **Required status checks:** 
  - `CI` (build check)
  - Add additional checks as they're configured
- **Require branches to be up to date before merging:** ✅ Enabled

### ✅ Require conversation resolution before merging
- Ensures all PR comments are addressed before merge

## Protection Rules

### ✅ Do not allow force pushes
- Prevents accidental history rewriting
- Applies to all users, including admins

### ✅ Do not allow deletions
- Prevents accidental branch deletion
- Protects against data loss

### ✅ Restrict who can push to matching branches
- Only allow pushes via pull requests
- Admins can still merge PRs

## Optional Settings

### Require linear history
- **Only enable if you prefer rebase workflow**
- Prevents merge commits
- Requires rebasing before merge

### Include administrators
- **Recommended:** ✅ Enabled
- Ensures protection rules apply to admins too

## How to Configure

1. Go to repository **Settings**
2. Click **Branches** in left sidebar
3. Click **Add rule** or edit existing rule for `main`
4. Configure settings as listed above
5. Click **Create** or **Save changes**

## Notes

- These settings only apply to the `main` branch
- Feature branches (`rewiring-beacon-dots`, etc.) are not protected
- Admins can temporarily bypass rules if absolutely necessary (not recommended)

