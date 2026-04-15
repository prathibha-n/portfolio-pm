# Returns Risk & Intervention System

This project addresses high return rates in the Indian fashion e-commerce market (typically 25–40%) by moving away from blanket policies and toward a data-driven, personalized risk management framework.

## Problem Statement
Fashion return rates in India are driven largely by size mismatch and low-commitment payment methods like Cash-on-Delivery (COD). Traditional approaches use "blunt" policies that hurt conversion without meaningfully reducing returns. This system identifies return risk at checkout to apply proportionate, targeted interventions.

## Process & Methodology
The project was developed following a rigorous Product Requirements Document (PRD) framework:

1.  **Risk Identification**: Analyzed 11 distinct signals—including user history, item category base rates, and session behavior (like size swaps)—to predict return probability 
2.  **Ethical Filtering**: Explicitly excluded features like pincode or device price to prevent geographic or income-based discrimination.
3.  **Two-Axis Routing**: Designed a logic matrix that uses both the **Score Band** (severity) and the **Top Driver** (cause) to determine the right intervention.
4.  **Guardrail Implementation**: Established a strict conversion rate guardrail—if an intervention degrades conversion by more than 1%, it is paused pending investigation.

## Project Structure (How to read this)
To understand the full scope of the system, review the files in this order:

1.  **`returns_reduction_PRD.md`**: The core documentation. Read this for the detailed business logic, feature specifications, and ethical guardrails.
2.  **`return_risk_model.ipynb`**: The technical implementation. This notebook contains the code for the scoring engine that processes the 11 input signals.
3.  **`flowchart.drawio.png`**: The visual architecture. This diagram shows how the system routes a user from a checkout event to a specific intervention based on their risk score.
