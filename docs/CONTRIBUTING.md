# Contributing to TrueSight

Thank you for your interest in contributing to TrueSight! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Use the issue templates** when available
3. **Provide detailed information** including:
   - Lightroom version
   - Operating system
   - Plugin version
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots or logs if applicable

### Suggesting Features

We welcome feature suggestions! Please:

1. **Check the roadmap** to see if it's already planned
2. **Create a feature request** using the template
3. **Explain the use case** and why it would be valuable
4. **Consider the scope** - start with smaller, focused features

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch** from `develop`
3. **Make your changes** following our coding standards
4. **Add tests** if applicable
5. **Update documentation** as needed
6. **Submit a pull request** to the `develop` branch

## 🛠️ Development Setup

### Prerequisites

- Adobe Lightroom Classic 6.0+
- Lua 5.3+ (for syntax checking)
- Azure CLI
- Git
- Text editor with Lua support

### Local Development

1. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/truesight.git
   cd truesight
   git remote add upstream https://github.com/Lukasedv/truesight.git
   ```

2. **Create development branch**
   ```bash
   git checkout -b feature/your-feature-name develop
   ```

3. **Set up Azure resources** (for testing)
   ```bash
   cd azure-infrastructure
   ./deploy.sh
   ```

4. **Install plugin in Lightroom**
   - File > Plug-in Manager
   - Add > Select `lightroom-plugin` folder

### Testing Your Changes

1. **Syntax validation**
   ```bash
   find lightroom-plugin -name "*.lua" -exec lua5.3 -l {} \;
   ```

2. **ARM template validation**
   ```bash
   az deployment group validate \
     --resource-group "test-rg" \
     --template-file azure-infrastructure/deploy-openai.json
   ```

3. **Manual testing in Lightroom**
   - Test with various image types
   - Verify UI responsiveness
   - Check error handling

## 📝 Coding Standards

### Lua Code Style

```lua
-- Use clear, descriptive names
local ColorAnalysis = {}

-- Document public functions
-- Analyzes selected photos and provides color correction suggestions
-- @param context: LrFunctionContext for progress tracking
-- @return: boolean indicating success
function ColorAnalysis.analyzeSelectedPhotos(context)
    -- Implementation here
end

-- Use consistent indentation (4 spaces)
if condition then
    doSomething()
else
    doSomethingElse()
end

-- Group related functionality
local AzureOpenAI = {
    -- Constants
    VERSION = "2024-02-15-preview",
    TIMEOUT = 30,
    
    -- Public methods
    analyzeImage = function(imagePath) end,
    setConfig = function(config) end,
}
```

### File Organization

```
lightroom-plugin/
├── Info.lua                 # Plugin manifest - minimal changes only
├── ColorAnalysis.lua        # Main analysis logic
├── AzureOpenAI.lua         # API integration
├── ColorAdjustments.lua    # Lightroom adjustments
├── ExportDialog.lua        # Export UI
├── ConfigDialog.lua        # Configuration UI
├── help.html               # User documentation
└── utils/                  # Utility modules (if needed)
    ├── ImageUtils.lua
    └── JsonUtils.lua
```

### Documentation Standards

1. **Code Comments**
   - Explain complex logic
   - Document public APIs
   - Use clear, concise language

2. **Markdown Documentation**
   - Use consistent formatting
   - Include code examples
   - Provide context and rationale

3. **Help Documentation**
   - Keep user-friendly language
   - Include screenshots where helpful
   - Update with new features

## 🧪 Testing Guidelines

### Manual Testing Checklist

- [ ] Plugin loads without errors
- [ ] Configuration dialog works
- [ ] Color analysis completes successfully
- [ ] Adjustments apply correctly
- [ ] Export workflow functions
- [ ] Error handling works gracefully
- [ ] UI is responsive and intuitive

### Test Cases to Cover

1. **Happy Path**
   - Single photo analysis
   - Batch processing
   - Export with analysis

2. **Error Scenarios**
   - Invalid API credentials
   - Network connectivity issues
   - Unsupported image formats
   - API rate limiting

3. **Edge Cases**
   - Very large images
   - Very small images
   - Corrupted image files
   - Photos with no clear subjects

### Azure Infrastructure Testing

1. **Template Validation**
   ```bash
   az deployment group validate \
     --resource-group "test-rg" \
     --template-file azure-infrastructure/deploy-openai.json
   ```

2. **Deployment Testing**
   ```bash
   # Deploy to test environment
   az deployment group create \
     --resource-group "test-rg" \
     --template-file azure-infrastructure/deploy-openai.json \
     --parameters openAiServiceName="test-deployment-$(date +%s)"
   ```

## 🔄 Git Workflow

### Branch Naming

- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Critical fixes
- `docs/description` - Documentation updates

### Commit Messages

Follow conventional commits format:

```
type(scope): description

Optional longer description

Breaking changes or important notes
```

Examples:
```
feat(analysis): add support for RAW file analysis
fix(ui): resolve configuration dialog validation issue
docs(readme): update installation instructions
refactor(openai): improve error handling and retry logic
```

### Pull Request Process

1. **Create descriptive PR title**
2. **Fill out PR template completely**
3. **Reference related issues** using keywords like "Fixes #123"
4. **Add reviewers** if you know who should review
5. **Ensure CI passes** before requesting review
6. **Respond to feedback** promptly and professionally

## 📚 Architecture Guidelines

### Plugin Architecture

```
User Input (Lightroom UI)
    ↓
ColorAnalysis (Main Controller)
    ↓
AzureOpenAI (External Service)
    ↓
ColorAdjustments (Lightroom API)
    ↓
Updated Photo (Result)
```

### Design Principles

1. **Separation of Concerns**
   - UI logic separate from business logic
   - API integration isolated in dedicated modules
   - Configuration management centralized

2. **Error Handling**
   - Graceful degradation
   - User-friendly error messages
   - Comprehensive logging

3. **Performance**
   - Async operations where possible
   - Progress feedback for long operations
   - Efficient image processing

### Module Dependencies

```lua
-- Good: Clear dependencies
local AzureOpenAI = require 'AzureOpenAI'
local ColorAdjustments = require 'ColorAdjustments'

-- Avoid: Circular dependencies
-- ModuleA requires ModuleB, ModuleB requires ModuleA
```

## 🔒 Security Considerations

### Code Security

1. **No Hardcoded Secrets**
   ```lua
   -- Bad
   local API_KEY = "sk-1234567890abcdef"
   
   -- Good
   local config = AzureOpenAI.getConfig()
   local apiKey = config.apiKey
   ```

2. **Input Validation**
   ```lua
   function validateImagePath(path)
       if not path or path == "" then
           return false, "Image path cannot be empty"
       end
       
       if not LrFileUtils.exists(path) then
           return false, "Image file does not exist"
       end
       
       return true
   end
   ```

3. **Safe API Calls**
   ```lua
   local success, result = pcall(function()
       return LrHttp.post(url, body, headers)
   end)
   
   if not success then
       -- Handle error gracefully
       return nil, "Network request failed"
   end
   ```

### Azure Security

1. **Use Managed Identity** when possible
2. **Implement least privilege** access
3. **Enable audit logging**
4. **Regular key rotation**

## 📊 Performance Guidelines

### Image Processing

1. **Optimize Image Size**
   ```lua
   -- Resize large images before analysis
   local MAX_WIDTH = 1920
   local MAX_HEIGHT = 1080
   ```

2. **Efficient Memory Usage**
   ```lua
   -- Clean up temporary files
   if tempPath then
       LrFileUtils.delete(tempPath)
   end
   ```

3. **Async Operations**
   ```lua
   LrTasks.startAsyncTask(function()
       -- Long-running operations here
   end)
   ```

### API Optimization

1. **Implement Rate Limiting**
2. **Use Appropriate Timeouts**
3. **Implement Retry Logic**
4. **Cache Results When Appropriate**

## 🏷️ Release Process

### Version Numbering

We use Semantic Versioning (SemVer):
- `MAJOR.MINOR.PATCH`
- `1.0.0` - Initial release
- `1.1.0` - New feature
- `1.0.1` - Bug fix

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] Version number bumped
- [ ] Changelog updated
- [ ] Security review completed
- [ ] Performance impact assessed

## 🆘 Getting Help

### Documentation

- [README.md](../README.md) - Project overview
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment guide
- [Plugin Help](../lightroom-plugin/help.html) - User documentation

### Community

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - General questions and ideas
- **Pull Request Reviews** - Code-specific questions

### Maintainer Contact

For security issues or sensitive topics, contact the maintainers directly through GitHub.

## 📜 Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please:

- **Be respectful** in all interactions
- **Provide constructive feedback**
- **Help others learn and grow**
- **Focus on what's best for the community**

Report any issues to the project maintainers.

## 🙏 Recognition

Contributors will be recognized in:
- GitHub contributor graphs
- Release notes for significant contributions
- README acknowledgments

Thank you for contributing to TrueSight! Your efforts help make photography more accessible for everyone.