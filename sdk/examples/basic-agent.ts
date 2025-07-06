import { SuiAISDK, createKeypairFromMnemonic } from '../src/core';

async function basicAgentExample() {
  // Initialize SDK
  const sdk = new SuiAISDK({
    network: 'testnet',
    packageId: '0x1234...', // Your deployed package ID
  });

  // Create keypair from mnemonic (in production, use secure key management)
  const mnemonic = 'your twelve word mnemonic phrase here for testing purposes only';
  const keypair = createKeypairFromMnemonic(mnemonic);
  sdk.setKeypair(keypair);

  try {
    // 1. Create an AI model
    console.log('Creating AI model...');
    const modelTx = await sdk.createModel({
      name: 'Basic Text Classifier',
      description: 'A simple text classification model',
      modelType: 0, // Inference type
      version: '1.0.0',
      modelHash: 'QmExample123...', // IPFS hash
      modelUrl: 'https://ipfs.io/ipfs/QmExample123...',
      inputShape: [512], // Text embedding size
      outputShape: [10], // Number of classes
      modelSizeBytes: 1024000, // 1MB
      maxInferenceTimeMs: 1000,
      requiredMemoryMb: 100,
      supportedFormats: ['onnx', 'pytorch'],
      isPublic: true,
    });
    console.log('Model created:', modelTx);

    // 2. Create an AI agent
    console.log('Creating AI agent...');
    const agentTx = await sdk.createAgent({
      name: 'Text Classifier Agent',
      description: 'An agent that classifies text input',
      modelId: 'model-object-id-from-previous-step',
      capabilities: ['text_classification', 'sentiment_analysis'],
    });
    console.log('Agent created:', agentTx);

    // 3. Execute inference
    console.log('Executing inference...');
    const response = await sdk.executeInference('agent-object-id', {
      requestId: 'req_' + Date.now(),
      inputData: new TextEncoder().encode('This is a test message for classification'),
    });
    console.log('Inference result:', response);

  } catch (error) {
    console.error('Error:', error);
  }
}

// Run the example
basicAgentExample();