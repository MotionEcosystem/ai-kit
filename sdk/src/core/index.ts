import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { fromB64 } from '@mysten/sui.js/utils';

export interface SuiAISDKConfig {
  network: 'mainnet' | 'testnet' | 'devnet' | 'localnet';
  packageId: string;
  rpcUrl?: string;
  keypair?: Ed25519Keypair;
}

export interface AIAgentConfig {
  name: string;
  description: string;
  modelId: string;
  capabilities: string[];
}

export interface AIModelConfig {
  name: string;
  description: string;
  modelType: number;
  version: string;
  modelHash: string;
  modelUrl: string;
  inputShape: number[];
  outputShape: number[];
  modelSizeBytes: number;
  maxInferenceTimeMs: number;
  requiredMemoryMb: number;
  supportedFormats: string[];
  isPublic: boolean;
}

export interface ExecutionContext {
  requestId: string;
  inputData: Uint8Array;
}

export interface AgentResponse {
  requestId: string;
  outputData: Uint8Array;
  confidenceScore: number;
  executionTimeMs: number;
  gasUsed: number;
}

export class SuiAISDK {
  private client: SuiClient;
  private packageId: string;
  private keypair?: Ed25519Keypair;

  constructor(config: SuiAISDKConfig) {
    this.client = new SuiClient({
      url: config.rpcUrl || getFullnodeUrl(config.network),
    });
    this.packageId = config.packageId;
    this.keypair = config.keypair;
  }

  // ===== AI Agent Management =====

  async createAgent(config: AIAgentConfig): Promise<string> {
    if (!this.keypair) {
      throw new Error('Keypair required for creating agents');
    }

    const tx = new TransactionBlock();
    
    // Get clock object
    tx.moveCall({
      target: `0x2::clock::Clock`,
    });

    const [clock] = tx.moveCall({
      target: `${this.packageId}::ai_agent::create_agent`,
      arguments: [
        tx.pure(config.name),
        tx.pure(config.description),
        tx.pure(config.modelId),
        tx.pure(config.capabilities),
        tx.object('0x6'), // Clock object ID
      ],
    });

    tx.transferObjects([clock], tx.pure(this.keypair.getPublicKey().toSuiAddress()));

    const result = await this.client.signAndExecuteTransactionBlock({
      signer: this.keypair,
      transactionBlock: tx,
    });

    return result.digest;
  }

  async executeInference(
    agentId: string,
    context: ExecutionContext
  ): Promise<AgentResponse> {
    if (!this.keypair) {
      throw new Error('Keypair required for executing inference');
    }

    const tx = new TransactionBlock();

    // Create execution context
    const [executionContext] = tx.moveCall({
      target: `${this.packageId}::ai_agent::create_execution_context`,
      arguments: [
        tx.pure(context.requestId),
        tx.pure(Array.from(context.inputData)),
        tx.object('0x6'), // Clock object ID
      ],
    });

    // Execute inference
    const [response] = tx.moveCall({
      target: `${this.packageId}::ai_agent::execute_inference`,
      arguments: [
        tx.object(agentId),
        executionContext,
        tx.object('0x6'), // Clock object ID
      ],
    });

    const result = await this.client.signAndExecuteTransactionBlock({
      signer: this.keypair,
      transactionBlock: tx,
    });

    // Parse response from transaction effects
    // This is a simplified version - real implementation would parse the response object
    return {
      requestId: context.requestId,
      outputData: new Uint8Array([]), // Would be parsed from transaction
      confidenceScore: 0,
      executionTimeMs: 0,
      gasUsed: Number(result.effects?.gasUsed?.computationCost || 0),
    };
  }

  // ===== AI Model Management =====

  async createModel(config: AIModelConfig): Promise<string> {
    if (!this.keypair) {
      throw new Error('Keypair required for creating models');
    }

    const tx = new TransactionBlock();

    // Create model config
    const [modelConfig] = tx.moveCall({
      target: `${this.packageId}::ai_model::create_model_config`,
      arguments: [
        tx.pure(config.inputShape),
        tx.pure(config.outputShape),
        tx.pure(config.modelSizeBytes),
        tx.pure(config.maxInferenceTimeMs),
        tx.pure(config.requiredMemoryMb),
        tx.pure(config.supportedFormats),
      ],
    });

    // Create model
    const [model] = tx.moveCall({
      target: `${this.packageId}::ai_model::create_model`,
      arguments: [
        tx.pure(config.name),
        tx.pure(config.description),
        tx.pure(config.modelType),
        tx.pure(config.version),
        tx.pure(config.modelHash),
        tx.pure(config.modelUrl),
        modelConfig,
        tx.pure(config.isPublic),
        tx.object('0x6'), // Clock object ID
      ],
    });

    tx.transferObjects([model], tx.pure(this.keypair.getPublicKey().toSuiAddress()));

    const result = await this.client.signAndExecuteTransactionBlock({
      signer: this.keypair,
      transactionBlock: tx,
    });

    return result.digest;
  }

  // ===== Query Functions =====

  async getAgent(agentId: string) {
    const result = await this.client.getObject({
      id: agentId,
      options: {
        showContent: true,
        showType: true,
      },
    });

    return result.data;
  }

  async getModel(modelId: string) {
    const result = await this.client.getObject({
      id: modelId,
      options: {
        showContent: true,
        showType: true,
      },
    });

    return result.data;
  }

  async queryAgentsByOwner(owner: string) {
    // Implementation would use GraphQL or indexer
    // This is a placeholder
    return [];
  }

  async queryPublicModels() {
    // Implementation would use GraphQL or indexer
    // This is a placeholder
    return [];
  }

  // ===== Utility Functions =====

  setKeypair(keypair: Ed25519Keypair) {
    this.keypair = keypair;
  }

  getClient(): SuiClient {
    return this.client;
  }

  getPackageId(): string {
    return this.packageId;
  }
}

// Export utility functions
export const createKeypairFromMnemonic = (mnemonic: string): Ed25519Keypair => {
  return Ed25519Keypair.deriveKeypair(mnemonic);
};

export const createKeypairFromPrivateKey = (privateKey: string): Ed25519Keypair => {
  return Ed25519Keypair.fromSecretKey(fromB64(privateKey));
};