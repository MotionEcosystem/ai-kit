module sui_ai_sdk::ai_model {
    use std::string::{Self, String};
    use std::vector;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::url::{Self, Url};

    // ===== Error codes =====
    const EInvalidModelType: u64 = 0;
    const EUnauthorizedAccess: u64 = 1;
    const EModelNotActive: u64 = 2;

    // ===== Constants =====
    const MODEL_TYPE_INFERENCE: u8 = 0;
    const MODEL_TYPE_TRAINING: u8 = 1;
    const MODEL_TYPE_HYBRID: u8 = 2;

    // ===== Structs =====

    /// AI Model metadata and configuration
    public struct AIModel has key, store {
        id: UID,
        name: String,
        description: String,
        model_type: u8,
        version: String,
        owner: address,
        model_hash: String, // IPFS hash or other content identifier
        model_url: Url,
        config: ModelConfig,
        metrics: ModelMetrics,
        created_at: u64,
        updated_at: u64,
        is_public: bool,
        is_active: bool,
    }

    public struct ModelConfig has store {
        input_shape: vector<u64>,
        output_shape: vector<u64>,
        model_size_bytes: u64,
        max_inference_time_ms: u64,
        required_memory_mb: u64,
        supported_formats: vector<String>,
    }

    public struct ModelMetrics has store {
        total_inferences: u64,
        avg_inference_time_ms: u64,
        accuracy_score: u64, // 0-100
        last_inference: u64,
        total_gas_used: u64,
    }

    public struct ModelLicense has store {
        license_type: String,
        commercial_use: bool,
        attribution_required: bool,
        share_alike: bool,
    }

    // ===== Events =====

    public struct ModelCreated has copy, drop {
        model_id: ID,
        name: String,
        owner: address,
        model_type: u8,
        is_public: bool,
    }

    public struct ModelUpdated has copy, drop {
        model_id: ID,
        version: String,
        updated_by: address,
        timestamp: u64,
    }

    public struct ModelInferenceExecuted has copy, drop {
        model_id: ID,
        execution_time_ms: u64,
        gas_used: u64,
        timestamp: u64,
    }

    // ===== Public Functions =====

    /// Create a new AI model
    public fun create_model(
        name: String,
        description: String,
        model_type: u8,
        version: String,
        model_hash: String,
        model_url: Url,
        config: ModelConfig,
        is_public: bool,
        clock: &Clock,
        ctx: &mut TxContext
    ): AIModel {
        assert!(model_type <= MODEL_TYPE_HYBRID, EInvalidModelType);
        
        let model_id = object::new(ctx);
        let current_time = clock::timestamp_ms(clock);
        
        let metrics = ModelMetrics {
            total_inferences: 0,
            avg_inference_time_ms: 0,
            accuracy_score: 0,
            last_inference: 0,
            total_gas_used: 0,
        };

        let model = AIModel {
            id: model_id,
            name,
            description,
            model_type,
            version,
            owner: tx_context::sender(ctx),
            model_hash,
            model_url,
            config,
            metrics,
            created_at: current_time,
            updated_at: current_time,
            is_public,
            is_active: true,
        };

        event::emit(ModelCreated {
            model_id: object::uid_to_inner(&model.id),
            name: model.name,
            owner: model.owner,
            model_type: model.model_type,
            is_public: model.is_public,
        });

        model
    }

    /// Update model metrics after inference
    public fun update_metrics(
        model: &mut AIModel,
        execution_time_ms: u64,
        gas_used: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        
        model.metrics.total_inferences = model.metrics.total_inferences + 1;
        model.metrics.last_inference = current_time;
        model.metrics.total_gas_used = model.metrics.total_gas_used + gas_used;
        
        // Update average inference time
        let total_time = model.metrics.avg_inference_time_ms * (model.metrics.total_inferences - 1) + execution_time_ms;
        model.metrics.avg_inference_time_ms = total_time / model.metrics.total_inferences;

        event::emit(ModelInferenceExecuted {
            model_id: object::uid_to_inner(&model.id),
            execution_time_ms,
            gas_used,
            timestamp: current_time,
        });
    }

    /// Update model version
    public fun update_model(
        model: &mut AIModel,
        new_version: String,
        new_hash: String,
        new_url: Url,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == model.owner, EUnauthorizedAccess);
        
        model.version = new_version;
        model.model_hash = new_hash;
        model.model_url = new_url;
        model.updated_at = clock::timestamp_ms(clock);

        event::emit(ModelUpdated {
            model_id: object::uid_to_inner(&model.id),
            version: model.version,
            updated_by: tx_context::sender(ctx),
            timestamp: model.updated_at,
        });
    }

    // ===== Getter Functions =====

    public fun get_model_info(model: &AIModel): (String, String, String, bool) {
        (model.name, model.description, model.version, model.is_active)
    }

    public fun get_model_config(model: &AIModel): &ModelConfig {
        &model.config
    }

    public fun get_model_metrics(model: &AIModel): &ModelMetrics {
        &model.metrics
    }

    public fun get_model_hash(model: &AIModel): String {
        model.model_hash
    }

    public fun get_model_url(model: &AIModel): &Url {
        &model.model_url
    }

    public fun is_public(model: &AIModel): bool {
        model.is_public
    }

    public fun is_active(model: &AIModel): bool {
        model.is_active
    }

    // ===== Utility Functions =====

    public fun create_model_config(
        input_shape: vector<u64>,
        output_shape: vector<u64>,
        model_size_bytes: u64,
        max_inference_time_ms: u64,
        required_memory_mb: u64,
        supported_formats: vector<String>
    ): ModelConfig {
        ModelConfig {
            input_shape,
            output_shape,
            model_size_bytes,
            max_inference_time_ms,
            required_memory_mb,
            supported_formats,
        }
    }
}