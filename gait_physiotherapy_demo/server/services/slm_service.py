import os
import httpx

CLOUDFLARE_ACCOUNT_ID = os.getenv("CLOUDFLARE_ACCOUNT_ID")
CLOUDFLARE_API_TOKEN = os.getenv("CLOUDFLARE_API_TOKEN")

async def call_cloudflare_ai(model_alias: str, system_prompt: str, user_content: str) -> str:
    """Helper function to cleanly execute Cloudflare REST API requests."""
    url = f"https://api.cloudflare.com/client/v4/accounts/{CLOUDFLARE_ACCOUNT_ID}/ai/run/{model_alias}"
    headers = {
        "Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}",
        "Content-Type": "application/json"
    }
    payload = {
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content}
        ]
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(url, headers=headers, json=payload, timeout=15.0)
            response.raise_for_status()
            return response.json()["result"]["response"]
    except Exception as e:
        return f"System was unable to generate AI insights due to an upstream error: {str(e)}"


async def generate_session_insights(metrics: dict) -> str:
    """
    Takes the clinical metrics from a single session and generates a short SLM insight 
    using a fast, lightweight 8B parameter model.
    """
    system_prompt = (
        "You are a helpful, concise physical therapy assistant. Review the provided "
        "gait metrics JSON for a single session and give a 2-sentence clinical takeaway."
    )
    user_content = f"Metrics: {metrics}"
    
    return await call_cloudflare_ai("@cf/meta/llama-3.1-8b-instruct", system_prompt, user_content)


async def generate_overall_insights(data: dict, is_single_patient: bool = True) -> str:
    """
    Takes data across multiple sessions (or multiple patients) and generates a comprehensive 
    long-term progression analysis using a high-reasoning 70B parameter model.
    """
    if is_single_patient:
        context = "for a single patient to track their individual progression and structural trends."
    else:
        context = "across multiple patients to identify broader clinic-wide patterns and average improvements."

    system_prompt = (
        f"You are an expert clinical gait analyst. Analyze the following historical data summary "
        f"{context} Provide a professional, structured overview for the physiotherapist."
    )
    user_content = f"Historical JSON Data: {data}"
    
    return await call_cloudflare_ai("@cf/meta/llama-3.3-70b-instruct-fp8-fast", system_prompt, user_content)