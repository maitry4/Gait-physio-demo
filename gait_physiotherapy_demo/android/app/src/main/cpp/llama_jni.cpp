#include <jni.h>
#include <string>
#include <vector>
#include <mutex>
#include <android/log.h>
#include "llama.h"

#define LOG_TAG "LlamaJni"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static llama_model* g_model = nullptr;
static llama_context* g_context = nullptr;
static const llama_vocab* g_vocab = nullptr;
static llama_sampler* g_sampler = nullptr;
static std::mutex g_mutex;

void my_llama_log_callback(ggml_log_level level, const char * text, void * user_data) {
    (void)level;
    (void)user_data;
    __android_log_print(ANDROID_LOG_INFO, "LlamaCppLog", "%s", text);
}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_example_gait_1physiotherapy_1demo_MainActivity_nativeLoadModel(
    JNIEnv* env,
    jobject thiz,
    jstring model_path
) {
    std::lock_guard<std::mutex> lock(g_mutex);
    
    // Free existing resources if any
    if (g_sampler) {
        llama_sampler_free(g_sampler);
        g_sampler = nullptr;
    }
    if (g_context) {
        llama_free(g_context);
        g_context = nullptr;
    }
    if (g_model) {
        llama_model_free(g_model);
        g_model = nullptr;
    }
    g_vocab = nullptr;
    
    const char* path = env->GetStringUTFChars(model_path, nullptr);
    LOGI("Loading model from: %s", path);
    
    // Set up llama log callback
    llama_log_set(my_llama_log_callback, nullptr);
    
    // Set up model parameters
    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0; // CPU only for safety and stability on emulators
    
    g_model = llama_model_load_from_file(path, model_params);
    env->ReleaseStringUTFChars(model_path, path);
    
    if (!g_model) {
        LOGE("Failed to load model");
        return JNI_FALSE;
    }
    
    g_vocab = llama_model_get_vocab(g_model);
    
    // Create context
    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 2048;
    ctx_params.n_batch = 512;
    ctx_params.n_threads = 4;
    ctx_params.n_threads_batch = 4;
    
    g_context = llama_init_from_model(g_model, ctx_params);
    if (!g_context) {
        LOGE("Failed to create context");
        llama_model_free(g_model);
        g_model = nullptr;
        return JNI_FALSE;
    }
    
    LOGI("Model loaded successfully");
    return JNI_TRUE;
}

JNIEXPORT jstring JNICALL
Java_com_example_gait_1physiotherapy_1demo_MainActivity_nativeGenerate(
    JNIEnv* env,
    jobject thiz,
    jstring prompt
) {
    std::lock_guard<std::mutex> lock(g_mutex);
    
    if (!g_model || !g_context || !g_vocab) {
        LOGE("Model not loaded");
        return env->NewStringUTF("Error: Model not loaded");
    }
    
    const char* prompt_str = env->GetStringUTFChars(prompt, nullptr);
    std::string prompt_text(prompt_str);
    env->ReleaseStringUTFChars(prompt, prompt_str);
    
    // Tokenize prompt
    const int n_prompt = -llama_tokenize(g_vocab, prompt_text.c_str(), prompt_text.size(), NULL, 0, true, true);
    std::vector<llama_token> prompt_tokens(n_prompt);
    
    if (llama_tokenize(g_vocab, prompt_text.c_str(), prompt_text.size(), prompt_tokens.data(), prompt_tokens.size(), true, true) < 0) {
        LOGE("Failed to tokenize prompt");
        return env->NewStringUTF("Error: Failed to tokenize prompt");
    }
    
    // Create batch
    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), prompt_tokens.size());
    
    // Decode prompt
    if (llama_decode(g_context, batch) != 0) {
        LOGE("Failed to decode prompt");
        return env->NewStringUTF("Error: Failed to decode prompt");
    }
    
    // Initialize sampler chain
    auto sparams = llama_sampler_chain_default_params();
    g_sampler = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(g_sampler, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_p(0.95f, 1));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_dist(1234));
    
    std::string result;
    int max_tokens = 256;
    int n_pos = prompt_tokens.size();
    
    for (int i = 0; i < max_tokens; i++) {
        // Sample next token
        llama_token new_token = llama_sampler_sample(g_sampler, g_context, -1);
        
        // Check for EOS
        if (llama_vocab_is_eog(g_vocab, new_token)) {
            break;
        }
        
        // Convert token to text
        char token_str[256] = {0};
        int n = llama_token_to_piece(g_vocab, new_token, token_str, sizeof(token_str) - 1, 0, true);
        if (n > 0) {
            token_str[n] = '\0';
            result.append(token_str);
        }
        
        // Prepare for next iteration
        batch = llama_batch_get_one(&new_token, 1);
        n_pos++;
        
        if (llama_decode(g_context, batch) != 0) {
            LOGE("Failed to decode token");
            break;
        }
    }
    
    if (g_sampler) {
        llama_sampler_free(g_sampler);
        g_sampler = nullptr;
    }
    
    return env->NewStringUTF(result.c_str());
}

JNIEXPORT void JNICALL
Java_com_example_gait_1physiotherapy_1demo_MainActivity_nativeUnloadModel(
    JNIEnv* env,
    jobject thiz
) {
    std::lock_guard<std::mutex> lock(g_mutex);
    
    LOGI("Unloading model");
    
    if (g_sampler) {
        llama_sampler_free(g_sampler);
        g_sampler = nullptr;
    }
    if (g_context) {
        llama_free(g_context);
        g_context = nullptr;
    }
    if (g_model) {
        llama_model_free(g_model);
        g_model = nullptr;
    }
    g_vocab = nullptr;
    LOGI("Model unloaded successfully");
}

} // extern "C"
