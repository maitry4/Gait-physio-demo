# Fastapi Endpoint (REST)
# Takes securely txt file.
# Returns Clinical Results:
"""
Steps Counted
Avg Cadence
Movement Smoothness (SPARC)
Phase Ratio: Stance | Swing
Avg Step Time
Avg Gait Speed
"""
# Will call analysis_service.py's method for the analysis. 
# if use has allowed to contribute to federated anonymous database then 
# we will share it to the db directly through federated_service.py 
# [we will keep it yet to be implemented right now.
# Just upload it to some drive right now if needed.]


# from the provided file we will not be able to generate the plot 1 because that 
# needs a lot of raw data. it is not useful for the physiotherapist anyway.
# that's why we are adding the federated learning option in fastapi.