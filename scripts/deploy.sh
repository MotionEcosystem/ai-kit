#!/bin/bash

set -e

# Sui AI SDK Deployment Script
echo "🚀 Starting Sui AI SDK Deployment..."

# Configuration
NETWORK=${1:-testnet}
GAS_BUDGET=${2:-10000000}
DEPLOY_ENV=${3:-staging}

echo "📝 Deployment Configuration:"
echo "  Network: $NETWORK"
echo "  Gas Budget: $GAS_BUDGET"
echo "  Environment: $DEPLOY_ENV"

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v sui &> /dev/null; then
    echo "❌ Sui CLI not found. Please install Sui CLI first."
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

# Build Move contracts
echo "🏗️ Building Move contracts..."
cd move
sui move build

if [ $? -ne 0 ]; then
    echo "❌ Move contract build failed!"
    exit 1
fi

# Deploy contracts
echo "📦 Deploying contracts to $NETWORK..."
DEPLOY_OUTPUT=$(sui client publish --gas-budget $GAS_BUDGET --json)

if [ $? -ne 0 ]; then
    echo "❌ Contract deployment failed!"
    exit 1
fi

# Extract package ID
PACKAGE_ID=$(echo $DEPLOY_OUTPUT | jq -r '.objectChanges[] | select(.type == "published") | .packageId')
echo "✅ Contracts deployed successfully!"
echo "📍 Package ID: $PACKAGE_ID"

# Update configuration files
echo "📝 Updating configuration files..."

# Update TypeScript SDK config
cd ../sdk
cat > src/config/deployed.ts << EOF
// Auto-generated deployment configuration
export const DEPLOYED_CONTRACTS = {
  network: '$NETWORK',
  packageId: '$PACKAGE_ID',
  deployedAt: '$(date -u +"%Y-%m-%dT%H:%M:%SZ")',
  environment: '$DEPLOY_ENV'
};
EOF

# Update CLI config
cd ../tools/cli
cat > src/config/deployed.json << EOF
{
  "network": "$NETWORK",
  "packageId": "$PACKAGE_ID",
  "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment": "$DEPLOY_ENV"
}
EOF

# Build and test SDK
echo "🔨 Building TypeScript SDK..."
cd ../../sdk
npm install
npm run build
npm test

if [ $? -ne 0 ]; then
    echo "❌ SDK build or tests failed!"
    exit 1
fi

# Build CLI tools
echo "🛠️ Building CLI tools..."
cd ../tools/cli
npm install
npm run build

if [ $? -ne 0 ]; then
    echo "❌ CLI build failed!"
    exit 1
fi

# Run integration tests
echo "🧪 Running integration tests..."
cd ../../examples
npm install

# Set environment variables for tests
export SUI_AI_SDK_PACKAGE_ID=$PACKAGE_ID
export SUI_AI_SDK_NETWORK=$NETWORK

npm test

if [ $? -ne 0 ]; then
    echo "❌ Integration tests failed!"
    exit 1
fi

# Generate documentation
echo "📚 Generating documentation..."
cd ../docs
npm install
npm run build

# Create deployment summary
echo "📋 Creating deployment summary..."
cat > ../DEPLOYMENT_SUMMARY.md << EOF
# Deployment Summary

**Deployed on:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Network:** $NETWORK
**Environment:** $DEPLOY_ENV
**Package ID:** $PACKAGE_ID

## Deployed Contracts

- **AI Agent Contract:** $PACKAGE_ID::ai_agent
- **AI Model Contract:** $PACKAGE_ID::ai_model
- **AI Oracle Contract:** $PACKAGE_ID::ai_oracle
- **AI Registry Contract:** $PACKAGE_ID::ai_registry

## SDK Configuration

The SDK is now configured to use the deployed contracts.
You can start using the SDK with:

\`\`\`typescript
import { SuiAISDK } from '@sui-ai-sdk/core';

const sdk = new SuiAISDK({
  network: '$NETWORK',
  packageId: '$PACKAGE_ID'
});
\`\`\`

## CLI Usage

\`\`\`bash
# Create a new AI agent
sui-ai create-agent --name "My Agent" --description "Test agent"

# Deploy an AI model
sui-ai deploy-model --file model.onnx --name "My Model"

# Execute inference
sui-ai inference --agent-id <agent-id> --input "test input"
\`\`\`

## Next Steps

1. Test the deployment with example scripts
2. Set up monitoring and alerting
3. Configure CI/CD for automated deployments
4. Update documentation with new endpoints

---
Generated by Sui AI SDK deployment script
EOF

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📍 Package ID: $PACKAGE_ID"
echo "🌐 Network: $NETWORK"
echo "📁 Summary: DEPLOYMENT_SUMMARY.md"
echo ""
echo "🚀 You can now start building AI applications on Sui!"
echo ""
echo "Next steps:"
echo "  1. Test with: cd examples && npm test"
echo "  2. Try CLI: sui-ai --help"
echo "  3. Read docs: open docs/index.html"
echo ""