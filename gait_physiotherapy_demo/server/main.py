import os
import asyncio
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends, Header
from pydantic import BaseModel
from services.analysis_service import analyze_gait_data
from services.federated_service import share_to_federated_db
from services.slm_service import generate_session_insights, generate_overall_insights
from typing import Optional

app = FastAPI(title="Gait Physiotherapy Demo API")

MAX_FILE_SIZE = 5 * 1024 * 1024

class AnalysisResponse(BaseModel):
    steps_counted: int
    avg_cadence: float
    movement_smoothness_sparc: float
    phase_ratio_stance_pct: float
    phase_ratio_swing_pct: float
    avg_step_time_s: float
    avg_gait_speed_mps: float
    slm_insights: Optional[str] = None

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_file(
    file: UploadFile = File(...),
    consent: bool = Form(False, description="Consent to share data to federated db"),
    use_slm: bool = Form(True),
):
    """
    Analyzes gait data from a text file.
    """
    if not file.filename.endswith('.txt'):
        raise HTTPException(status_code=400, detail="Only .txt files are supported")
    
    if getattr(file, "size", 0) and file.size > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="File too large. Maximum size is 10MB.")

    try:
        content = await file.read()
        if len(content) > MAX_FILE_SIZE:
            raise HTTPException(status_code=413, detail="File too large. Maximum size is 10MB.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to read file: {e}")
        
    try:
        results = await asyncio.to_thread(analyze_gait_data, content)
        
        if consent:
            await asyncio.to_thread(share_to_federated_db, content)
            
        if use_slm:
            results["slm_insights"] = await generate_session_insights(results)
        else:
            results["slm_insights"] = None
        return results
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


class OverallInsightsRequest(BaseModel):
    data: dict
    is_single_patient: bool = True

class OverallInsightsResponse(BaseModel):
    insights: str

@app.post("/generate", response_model=OverallInsightsResponse)
async def generate_insights(request: OverallInsightsRequest):
    """
    takes data of a patient's multiple session or a physio's multiple patient's data summary [got using queries in the db that stores per session summary.]
    """
    try:
        insights = await generate_overall_insights(request.data, request.is_single_patient)
        return {"insights": insights}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate insights: {e}")