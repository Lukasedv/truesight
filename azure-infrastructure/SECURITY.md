# Security Checklist for TrueSight Azure Infrastructure

## ✅ Pre-Commit Security Checklist

Before committing any changes to this repository, verify:

### 1. Sensitive Files Protection
- [ ] `.gitignore` is present and includes all sensitive file patterns
- [ ] No `*-config.txt` files are staged for commit (except `*.example.txt`)
- [ ] No files containing real API keys, secrets, or tokens are staged
- [ ] No Azure CLI output files or logs are staged

### 2. Code Security Review
- [ ] No hardcoded API keys, secrets, or passwords in source code
- [ ] No hardcoded resource names that could expose sensitive information
- [ ] All sensitive data is properly masked in log outputs
- [ ] Configuration files are created with restricted permissions (600)

### 3. Files Safe to Commit
✅ **These files are SAFE to commit:**
- `deploy.sh` - Deployment script (no secrets)
- `cleanup.sh` - Cleanup script (no secrets)
- `validate.sh` - Validation script (no secrets)
- `deploy-openai.json` - ARM template (no secrets)
- `README.md` - Documentation
- `.gitignore` - Git ignore rules
- `*.example.txt` - Example files with fake data
- `SECURITY.md` - This security checklist

❌ **These files should NEVER be committed:**
- `truesight-config.txt` - Contains real API keys
- `*-config.txt` - Any actual configuration files
- `deployment-output.json` - May contain sensitive data
- `*.log` - Log files that may contain keys
- Any file with actual API keys, secrets, or tokens

### 4. Quick Security Commands

```bash
# Check what files are staged for commit
git status

# Check if any sensitive patterns are in staged files
git diff --cached | grep -i "api.*key\|secret\|token\|password"

# Remove sensitive files from staging if accidentally added
git reset HEAD sensitive-file.txt

# Check .gitignore effectiveness
git check-ignore *-config.txt  # Should return the files (meaning they're ignored)
```

### 5. If You Accidentally Commit Secrets

If you accidentally commit API keys or other secrets:

1. **Immediately rotate/regenerate the exposed secrets**
2. **Remove from git history:**
   ```bash
   # For the most recent commit
   git reset --soft HEAD~1
   git reset HEAD sensitive-file.txt
   git commit -m "Remove sensitive data"
   
   # For older commits, use git filter-branch or BFG Repo-Cleaner
   ```
3. **Force push to remote (if already pushed):**
   ```bash
   git push --force-with-lease origin main
   ```
4. **Notify team members to regenerate their local copies**

### 6. Environment Variables vs Files

Prefer environment variables for sensitive configuration:
```bash
# Good - using environment variables
export AZURE_OPENAI_API_KEY="your-key-here"
export AZURE_OPENAI_ENDPOINT="your-endpoint-here"

# Bad - hardcoded in scripts
API_KEY="sk-1234567890abcdef..."
```

### 7. Regular Security Maintenance

- [ ] Regularly rotate API keys (recommended: every 90 days)
- [ ] Review and update `.gitignore` when adding new file types
- [ ] Audit repository for any accidentally committed secrets
- [ ] Keep Azure CLI and other tools updated

## 🚨 Emergency Contact

If secrets are accidentally exposed:
1. Immediately disable/rotate the exposed credentials in Azure Portal
2. Follow the git history cleanup steps above
3. Document the incident and lessons learned

## Additional Resources

- [GitHub's guide on removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Azure security best practices](https://docs.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [Git secrets tool](https://github.com/awslabs/git-secrets) for automated secret detection
