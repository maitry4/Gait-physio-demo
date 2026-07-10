import pandas as pd
import numpy as np
import io
import skdh as skdh
from skdh.gait import GaitLumbar

def analyze_gait_data(file_bytes: bytes, height: float = 1.75) -> dict:
    try:
        df = pd.read_csv(
            io.BytesIO(file_bytes), 
            skiprows=1, 
            header=None, 
            names=['SerialNumber', 'Timestamp', 'x_acc', 'y_acc', 'z_acc'],
            on_bad_lines='skip'
        )
        
        for col in ['x_acc', 'y_acc', 'z_acc']:
            df[col] = pd.to_numeric(df[col].astype(str).str.replace('acc:', ''), errors='coerce')
        
        df.dropna(inplace=True)

        if df.empty:
            raise ValueError("Parsed data is empty or invalid format.")

        raw_timestamps = df['Timestamp'].values.astype(float)
        time_seconds = (raw_timestamps - raw_timestamps[0]) / 1000.0
        accel = df[['x_acc', 'y_acc', 'z_acc']].values
        
    except Exception as e:
        raise ValueError(f"Error parsing data file: {e}")

    gait = GaitLumbar()
    data_dict = {'time': time_seconds, 'accel': accel}

    try:
        results = gait.predict(**data_dict, height=height)

        if results is not None and len(results.get('step time', [])) > 0:
            res_df = pd.DataFrame(results)
            
            avg_stance = res_df['stance time'].mean()
            avg_swing = res_df['swing time'].mean()
            avg_stride = res_df['stride time'].mean()
            
            stance_pct = (avg_stance / avg_stride) * 100
            swing_pct = (avg_swing / avg_stride) * 100

            return {
                "steps_counted": int(len(res_df)),
                "avg_cadence": float(res_df['cadence'].mean()),
                "movement_smoothness_sparc": float(res_df['stride SPARC'].mean()),
                "phase_ratio_stance_pct": float(stance_pct),
                "phase_ratio_swing_pct": float(swing_pct),
                "avg_step_time_s": float(res_df['step time'].mean()),
                "avg_gait_speed_mps": float(res_df['gait speed'].mean())
            }
        else:
            raise ValueError("No walking bouts detected.")

    except ValueError:
        raise
    except Exception as e:
        raise RuntimeError(f"An error occurred during gait prediction: {e}")
