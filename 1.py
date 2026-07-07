import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter
import skdh as skdh
from skdh.gait import GaitLumbar
import os

# =============================================================================
# 1. DATA LOADING AND PREPROCESSING
# =============================================================================
file_path = "E:\\summer_internship\\Subject_Data\\Subject_Data\\Healthy_Subject\\LeftLeg\\final1.txt"
# Automatically set output path to the folder containing the input file
# output_dir = "Data_Collection_2.0/Ortho/Patients/K/sdh_script_plots" # Specify your directory here

# if not os.path.exists(output_dir) and output_dir != "":
#     os.makedirs(output_dir)

try:
    df = pd.read_csv(
        file_path, 
        skiprows=1, 
        header=None, 
        names=['SerialNumber', 'Timestamp', 'x_acc', 'y_acc', 'z_acc'],
        on_bad_lines='skip'
    )
    
    for col in ['x_acc', 'y_acc', 'z_acc']:
        df[col] = pd.to_numeric(df[col].astype(str).str.replace('acc:', ''), errors='coerce')
    
    df.dropna(inplace=True)

    raw_timestamps = df['Timestamp'].values.astype(float)
    time_seconds = (raw_timestamps - raw_timestamps[0]) / 1000.0
    accel = df[['x_acc', 'y_acc', 'z_acc']].values
    
    fs = 1.0 / np.mean(np.diff(time_seconds))
    acc_mag = np.sqrt(np.sum(accel**2, axis=1))
    
    print(f"--- Data Loaded Successfully ---")
    print(f"Sampling Rate: {fs:.2f} Hz | Duration: {time_seconds[-1]:.2f}s")

except Exception as e:
    print(f"Error: {e}")
    exit()

# =============================================================================
# 2. SKDH CLINICAL GAIT ANALYSIS
# =============================================================================
gait = GaitLumbar()
data_dict = {'time': time_seconds, 'accel': accel}

print("\nRunning SKDH Clinical Prediction...")

try:
    results = gait.predict(**data_dict, height=1.75)

    if results is not None and len(results['step time']) > 0:
        res_df = pd.DataFrame(results)
        
        # --- EXTENDED METRICS SUMMARY ---
        avg_stance = res_df['stance time'].mean()
        avg_swing = res_df['swing time'].mean()
        avg_stride = res_df['stride time'].mean()
        
        stance_pct = (avg_stance / avg_stride) * 100
        swing_pct = (avg_swing / avg_stride) * 100

        # Prepare summary text
        summary_lines = [
            "--- Extended Clinical Results ---",
            f"Steps Counted: {len(res_df)}",
            f"Avg Cadence: {res_df['cadence'].mean():.2f} steps/min",
            f"Movement Smoothness (SPARC): {res_df['stride SPARC'].mean():.3f}",
            f"Phase Ratio: Stance {stance_pct:.1f}% | Swing {swing_pct:.1f}%",
            f"Avg Step Time: {res_df['step time'].mean():.3f} s",
            f"Avg Gait Speed: {res_df['gait speed'].mean():.3f} m/s",
            # Add these to your summary_lines list
            f"Avg Stride Time: {res_df['stride time'].mean():.3f} s",
            f"Avg Stance Time: {res_df['stance time'].mean():.3f} s", 
            f"Avg Swing Time: {res_df['swing time'].mean():.3f} s",
            # f"Avg Impact (IC): {avg_impact:.3f} g",
            f"SPARC per stride (first 5): {res_df['stride SPARC'].head().tolist()}",
        ]

        # Print to console
        print("\n" + "\n".join(summary_lines))
        print("\nAll available metrics:")
        print(res_df.columns.tolist())
        print(res_df.describe())

        # Save Summary to Text File
        # with open(os.path.join(output_dir, "gait_clinical_summary.txt"), "w") as f:
        #     f.write("\n".join(summary_lines))

        # =============================================================================
        # 3. PLOT 1: GAIT VALIDATION & IMPACT
        # =============================================================================
        ic_times = results['IC Time']
        ic_acc_values = np.interp(ic_times, time_seconds, acc_mag)
        avg_impact = np.mean(ic_acc_values)
        
        plt.figure(figsize=(15, 6))
        plt.plot(time_seconds, acc_mag, color='blue', alpha=0.4, label='Acc Magnitude', linewidth=1)
        plt.axhline(y=avg_impact, color='green', linestyle='--', alpha=0.6, label=f'Avg Impact ({avg_impact:.2f}g)')
        #plt.scatter(ic_times, ic_acc_values, color='red', s=100, edgecolors='black', label='Heel Strikes (IC)', zorder=5)

        plt.gca().xaxis.set_major_formatter(ScalarFormatter(useOffset=False))
        plt.ticklabel_format(style='plain', axis='x')
        plt.title('Gait Validation & Impact Analysis', fontsize=16)
        plt.xlabel('Time (Seconds)')
        plt.ylabel('Acceleration (g)')
        plt.legend()
        plt.grid(True, linestyle=':', alpha=0.5)
        
        # Save Plot 1
        # plt.savefig(os.path.join(output_dir, "gait_validation_plot.png"))
        plt.show()

        # =============================================================================
        # 4. PLOT 2: AVERAGE GAIT CYCLE PHASES (STANCE vs SWING)
        # =============================================================================
        plt.figure(figsize=(10, 4))
        
        # Creating a horizontal bar chart
        plt.barh(['Average Gait Cycle'], [stance_pct], color='steelblue', label='Stance Phase')
        plt.barh(['Average Gait Cycle'], [swing_pct], left=[stance_pct], color='lightskyblue', label='Swing Phase')
        
        # Text labels for the percentages
        plt.text(stance_pct/2, 0, f"Stance\n{stance_pct:.1f}%", ha='center', va='center', color='white', fontweight='bold')
        plt.text(stance_pct + swing_pct/2, 0, f"Swing\n{swing_pct:.1f}%", ha='center', va='center', color='black', fontweight='bold')

        plt.title('Clinical Gait Cycle Composition', fontsize=16)
        plt.xlabel('Percentage of Stride (%)')
        plt.xlim(0, 100)
        plt.legend(loc='lower center', bbox_to_anchor=(0.5, -0.3), ncol=2)
        plt.tight_layout()
        
        # Save Plot 2
        # plt.savefig(os.path.join(output_dir, "gait_phase_composition.png"))
        plt.show()

        # Save metrics to CSV
        # res_df.to_csv(os.path.join(output_dir, "gait_clinical_results_extended.csv"), index=False)
        # print(f"\nFiles saved to: {os.path.abspath(output_dir)}")
        
    else:
        print("\nNo walking bouts detected.")

except Exception as e:
    print(f"An error occurred: {e}")



#
# Understanding the SPARC Score
# In gait research, SPARC (Spectral Arc Length) measures the complexity of the movement's frequency spectrum.

# -2.0 to -4.0: Generally seen in healthy, stable walking.

# Below -6.0: Often indicates "jittery" or tremulous gait, sometimes seen in fatigue or specific neurological conditions.

# Near 0: Hypothetically "perfect" smoothness (rare in human biology).