module sui_ai_sdk::ai_agent {
    use std::string::{Self, String};
    use std::vector;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::dynamic_field as df;
    use sui::dynamic_object_field as dof;

    // ===== Error codes =====
    const EInvalidAgentState: u64 = 0;
    const EUnauthorizedAccess: u64 = 1;
    const EInvalidModelId: u64 = 2;
    const EAgentNotActive: u64 = 3;

    // ===== Structs =====
    
    /// Core AI Agent object - represents an autonomous AI entity on Sui
    public struct AIAgent has key, store {
        id: UID,
        name: String,
        description: String,
        owner: address,
        model_id: ID,
        state: u8, // 0: inactive, 1: active, 2: training, 3: suspended
        capabilities: vector<String>,
        created_at: u64,
        last_active: u64,
        inference_count: u64,
        version: u64,
    }

    /// AI Agent capability - defines what the agent can do
    public struct AgentCapability has store {
        name: String,
        description: String,
        parameters: vector<u8>, // Serialized parameters
        enabled: bool,
    }

    /// Agent execution context for AI inference
    public struct ExecutionContext has store {
        request_id: String,
        input_data: vector<u8>,
        timestamp: u64,
        requester: address,
    }

    /// Agent response after AI inference
    public struct AgentResponse has store {
        request_id: String,
        output_data: vector<u8>,
        confidence_score: u64, // 0-100
        execution_time_ms: u64,
        gas_used: u64,
    }

    // ===== Events =====
    
    public struct AgentCreated has copy, drop {
        agent_id: ID,
        owner: address,
        name: String,
        model_id: ID,
    }

    public struct AgentExecuted has copy, drop {
        agent_id: ID,
        request_id: String,
        confidence_score: u64,
        execution_time_ms: u64,
    }

    public struct AgentStateChanged has copy, drop {
        agent_id: ID,
        old_state: u8,
        new_state: u8,
        timestamp: u64,
    }

    // ===== Public Functions =====

    /// Create a new AI agent
    public fun create_agent(
        name: String,
        description: String,
        model_id: ID,
        capabilities: vector<String>,
        clock: &Clock,
        ctx: &mut TxContext
    ): AIAgent {
        let agent_id = object::new(ctx);
        let current_time = clock::timestamp_ms(clock);
        
        let agent = AIAgent {
            id: agent_id,
            name,
            description,
            owner: tx_context::sender(ctx),
            model_id,
            state: 1, // Active by default
            capabilities,
            created_at: current_time,
            last_active: current_time,
            inference_count: 0,
            version: 1,
        };

        event::emit(AgentCreated {
            agent_id: object::uid_to_inner(&agent.id),
            owner: agent.owner,
            name: agent.name,
            model_id: agent.model_id,
        });

        agent
    }

    /// Execute AI inference with the agent
    public fun execute_inference(
        agent: &mut AIAgent,
        context: ExecutionContext,
        clock: &Clock,
        ctx: &mut TxContext
    ): AgentResponse {
        assert!(agent.state == 1, EAgentNotActive);
        
        let current_time = clock::timestamp_ms(clock);
        agent.last_active = current_time;
        agent.inference_count = agent.inference_count + 1;

        // Simulate AI inference (in real implementation, this would call off-chain AI)
        let mock_output = b"AI response data";
        let confidence = 85; // Mock confidence score
        let execution_time = 150; // Mock execution time in ms

        let response = AgentResponse {
            request_id: context.request_id,
            output_data: mock_output,
            confidence_score: confidence,
            execution_time_ms: execution_time,
            gas_used: 1000, // Mock gas usage
        };

        event::emit(AgentExecuted {
            agent_id: object::uid_to_inner(&agent.id),
            request_id: response.request_id,
            confidence_score: response.confidence_score,
            execution_time_ms: response.execution_time_ms,
        });

        response
    }

    /// Add a new capability to the agent
    public fun add_capability(
        agent: &mut AIAgent,
        capability: AgentCapability,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == agent.owner, EUnauthorizedAccess);
        
        let capability_name = capability.name;
        df::add(&mut agent.id, capability_name, capability);
        
        vector::push_back(&mut agent.capabilities, capability_name);
        agent.version = agent.version + 1;
    }

    /// Update agent state
    public fun update_state(
        agent: &mut AIAgent,
        new_state: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == agent.owner, EUnauthorizedAccess);
        
        let old_state = agent.state;
        agent.state = new_state;
        
        event::emit(AgentStateChanged {
            agent_id: object::uid_to_inner(&agent.id),
            old_state,
            new_state,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    // ===== Getter Functions =====

    public fun get_agent_info(agent: &AIAgent): (String, String, address, u8, u64) {
        (agent.name, agent.description, agent.owner, agent.state, agent.inference_count)
    }

    public fun get_agent_id(agent: &AIAgent): ID {
        object::uid_to_inner(&agent.id)
    }

    public fun is_active(agent: &AIAgent): bool {
        agent.state == 1
    }

    public fun get_capabilities(agent: &AIAgent): &vector<String> {
        &agent.capabilities
    }

    // ===== Utility Functions =====

    public fun create_execution_context(
        request_id: String,
        input_data: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ExecutionContext {
        ExecutionContext {
            request_id,
            input_data,
            timestamp: clock::timestamp_ms(clock),
            requester: tx_context::sender(ctx),
        }
    }

    public fun create_capability(
        name: String,
        description: String,
        parameters: vector<u8>
    ): AgentCapability {
        AgentCapability {
            name,
            description,
            parameters,
            enabled: true,
        }
    }
}