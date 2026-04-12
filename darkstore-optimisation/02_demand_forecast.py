#!/usr/bin/env python3
"""
Dark Store Demand Forecast — Pin Code 560068 (Bellandur, Bengaluru)
====================================================================
Deliverable 2: ARIMA + Prophet demand forecast with MAE / RMSE
- Simulates 6 months of hourly order data with realistic Bengaluru patterns
- Trains ARIMA and Prophet models
- Forecasts next 7 days
- Reports MAE, RMSE, MAPE on a holdout test set
- Exports forecast CSV for dashboard ingestion
"""

import warnings
warnings.filterwarnings("ignore")

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta

from statsmodels.tsa.statespace.sarimax import SARIMAX
from statsmodels.tsa.stattools import adfuller
from prophet import Prophet

from sklearn.metrics import mean_absolute_error, mean_squared_error

# ── Reproducibility ──────────────────────────────────────────────────────────
np.random.seed(42)
STORE_PIN   = "560068"
STORE_NAME  = "Bellandur Dark Store"
SIM_DAYS    = 180          # 6 months of history
FORECAST_DAYS = 7

print("=" * 65)
print(f"  DARK STORE DEMAND FORECAST  |  {STORE_NAME}  |  {STORE_PIN}")
print("=" * 65)

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1 — SIMULATE REALISTIC ORDER DATA
# Bengaluru quick-commerce demand patterns:
#   • Morning spike 07-09 (breakfast, milk)
#   • Lunch lull 11-13
#   • Evening surge 17-21 (dinner groceries, snacks)
#   • Weekend amplification +25%
#   • Monthly pay-cycle bump (1st & last week)
# ─────────────────────────────────────────────────────────────────────────────

print("\n[1/6] Simulating 6 months of hourly order data ...")

start_date = datetime(2024, 10, 1)
hours       = pd.date_range(start=start_date, periods=SIM_DAYS * 24, freq="h")

# Hour-of-day demand weights (0-23)
hourly_weights = np.array([
    0.1, 0.05, 0.03, 0.02, 0.02, 0.05,   # 00-05  (overnight low)
    0.3,  0.9,  1.0,  0.7,  0.5,  0.4,   # 06-11  (morning spike)
    0.5,  0.4,  0.45, 0.5,  0.6,  0.9,   # 12-17  (afternoon)
    1.0,  1.0,  0.95, 0.8,  0.6,  0.3,   # 18-23  (evening surge)
])

def simulate_orders(ts_index):
    orders = []
    for ts in ts_index:
        base        = 18                              # avg orders/hour at peak
        hour_factor = hourly_weights[ts.hour]
        dow_factor  = 1.25 if ts.dayofweek >= 5 else 1.0   # weekend bump
        # Pay-cycle effect: 1st and last 5 days of month
        dom = ts.day
        mdays = (ts + pd.offsets.MonthEnd(0)).day
        pay_factor = 1.12 if (dom <= 5 or dom >= mdays - 4) else 1.0
        # Mild upward trend (+0.3% per week)
        week_num    = (ts - pd.Timestamp(start_date)).days // 7
        trend       = 1 + 0.003 * week_num
        mu = base * hour_factor * dow_factor * pay_factor * trend
        # Poisson draws feel realistic for order counts
        cnt = np.random.poisson(max(mu, 0.1))
        orders.append(cnt)
    return orders

df_hourly = pd.DataFrame({
    "ds":     hours,
    "orders": simulate_orders(hours)
})

# Daily aggregation for cleaner modelling
df_daily = (
    df_hourly
    .resample("D", on="ds")
    .sum()
    .rename(columns={"orders": "y"})
    .reset_index()
)

print(f"   ✓ Generated {len(df_hourly):,} hourly rows  →  {len(df_daily)} daily rows")
print(f"   Daily orders — min: {df_daily.y.min()}, max: {df_daily.y.max()}, "
      f"mean: {df_daily.y.mean():.1f}")


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2 — TRAIN / TEST SPLIT
# Hold out last 14 days for evaluation
# ─────────────────────────────────────────────────────────────────────────────

print("\n[2/6] Splitting train / test (last 14 days = test) ...")

HOLDOUT = 14
train = df_daily.iloc[:-HOLDOUT].copy()
test  = df_daily.iloc[-HOLDOUT:].copy()
print(f"   Train: {train.ds.min().date()} → {train.ds.max().date()}  ({len(train)} days)")
print(f"   Test : {test.ds.min().date()}  → {test.ds.max().date()}  ({len(test)} days)")


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3 — STATIONARITY CHECK
# ─────────────────────────────────────────────────────────────────────────────

print("\n[3/6] Stationarity check (ADF test) ...")

adf_result = adfuller(train["y"].values, autolag="AIC")
print(f"   ADF statistic : {adf_result[0]:.4f}")
print(f"   p-value       : {adf_result[1]:.4f}")
print(f"   Conclusion    : {'Stationary ✓' if adf_result[1] < 0.05 else 'Non-stationary — will difference'}")


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4 — SARIMA MODEL
# SARIMA(1,1,1)(1,0,1)[7]  — daily data, weekly seasonality
# ─────────────────────────────────────────────────────────────────────────────

print("\n[4/6] Fitting SARIMA(1,1,1)(1,0,1)[7] ...")

sarima_model = SARIMAX(
    train["y"],
    order=(1, 1, 1),
    seasonal_order=(1, 0, 1, 7),
    enforce_stationarity=False,
    enforce_invertibility=False
)
sarima_fit = sarima_model.fit(disp=False)

# In-sample forecast on test window
sarima_test_pred = sarima_fit.forecast(steps=HOLDOUT)
sarima_test_pred = np.maximum(sarima_test_pred, 0)   # clip negatives

# Forecast next 7 days
sarima_forecast = sarima_fit.forecast(steps=HOLDOUT + FORECAST_DAYS)[-FORECAST_DAYS:]
sarima_forecast = np.maximum(sarima_forecast, 0)

sarima_mae  = mean_absolute_error(test["y"], sarima_test_pred)
sarima_rmse = np.sqrt(mean_squared_error(test["y"], sarima_test_pred))
sarima_mape = np.mean(np.abs((test["y"].values - sarima_test_pred) / np.maximum(test["y"].values, 1))) * 100

print(f"   SARIMA  →  MAE: {sarima_mae:.2f}  |  RMSE: {sarima_rmse:.2f}  |  MAPE: {sarima_mape:.2f}%")


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 5 — PROPHET MODEL
# Adds Indian holidays + intraweek seasonality
# ─────────────────────────────────────────────────────────────────────────────

print("\n[5/6] Fitting Facebook Prophet with Indian holidays ...")

# Key Bengaluru / national holidays in the simulation window
holidays_df = pd.DataFrame({
    "holiday": [
        "Diwali", "Kannada Rajyotsava", "Christmas",
        "New Year", "Republic Day", "Holi", "Ugadi"
    ],
    "ds": pd.to_datetime([
        "2024-11-01", "2024-11-01", "2024-12-25",
        "2025-01-01", "2025-01-26", "2025-03-14", "2025-03-30"
    ]),
    "lower_window": [-1, -1, 0, -1, 0, 0, 0],
    "upper_window": [ 1,  0, 1,  1, 0, 1, 1],
})

prophet_model = Prophet(
    yearly_seasonality=False,
    weekly_seasonality=True,
    daily_seasonality=False,
    holidays=holidays_df,
    changepoint_prior_scale=0.15,
    seasonality_prior_scale=10,
    interval_width=0.90,
)
prophet_model.add_seasonality(name="monthly", period=30.5, fourier_order=4)
prophet_model.fit(train[["ds", "y"]])

# Predict on test
future_test = prophet_model.make_future_dataframe(periods=HOLDOUT + FORECAST_DAYS)
prophet_all  = prophet_model.predict(future_test)
prophet_test_pred = prophet_all.iloc[-(HOLDOUT + FORECAST_DAYS):-FORECAST_DAYS]["yhat"].values
prophet_test_pred = np.maximum(prophet_test_pred, 0)

prophet_forecast_df = prophet_all.iloc[-FORECAST_DAYS:][["ds", "yhat", "yhat_lower", "yhat_upper"]].copy()
prophet_forecast_df["yhat"]       = np.maximum(prophet_forecast_df["yhat"], 0)
prophet_forecast_df["yhat_lower"] = np.maximum(prophet_forecast_df["yhat_lower"], 0)

prophet_mae  = mean_absolute_error(test["y"], prophet_test_pred)
prophet_rmse = np.sqrt(mean_squared_error(test["y"], prophet_test_pred))
prophet_mape = np.mean(np.abs((test["y"].values - prophet_test_pred) / np.maximum(test["y"].values, 1))) * 100

print(f"   Prophet →  MAE: {prophet_mae:.2f}  |  RMSE: {prophet_rmse:.2f}  |  MAPE: {prophet_mape:.2f}%")


# ─────────────────────────────────────────────────────────────────────────────
# MODEL COMPARISON TABLE
# ─────────────────────────────────────────────────────────────────────────────

print("\n" + "─" * 55)
print(f"  {'Model':<12} {'MAE':>8} {'RMSE':>8} {'MAPE':>8}")
print("─" * 55)
print(f"  {'SARIMA':<12} {sarima_mae:>8.2f} {sarima_rmse:>8.2f} {sarima_mape:>7.2f}%")
print(f"  {'Prophet':<12} {prophet_mae:>8.2f} {prophet_rmse:>8.2f} {prophet_mape:>7.2f}%")
winner = "Prophet" if prophet_rmse < sarima_rmse else "SARIMA"
print("─" * 55)
print(f"  Winner (lower RMSE): {winner}")
print("─" * 55)


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 6 — 7-DAY FORECAST TABLE
# ─────────────────────────────────────────────────────────────────────────────

print("\n[6/6] 7-Day Order Forecast (Prophet) ...")
print()
print(f"  {'Date':<14} {'Day':<10} {'Forecast':>10} {'Lower 90%':>11} {'Upper 90%':>11}")
print("  " + "─" * 56)

forecast_dates = pd.date_range(start=df_daily.ds.max() + timedelta(days=1), periods=FORECAST_DAYS)
for i, row in prophet_forecast_df.iterrows():
    day_name = row["ds"].strftime("%a")
    print(f"  {str(row['ds'].date()):<14} {day_name:<10} "
          f"{int(row['yhat']):>10,} {int(row['yhat_lower']):>11,} {int(row['yhat_upper']):>11,}")


# ─────────────────────────────────────────────────────────────────────────────
# VISUALISATIONS
# ─────────────────────────────────────────────────────────────────────────────

fig, axes = plt.subplots(3, 1, figsize=(14, 16))
fig.suptitle(
    f"Dark Store Demand Forecast Dashboard\n{STORE_NAME} | PIN {STORE_PIN}",
    fontsize=14, fontweight="bold", y=0.98
)

# — Plot 1: Historical + Forecast ——————————————————————————————————————————
ax1 = axes[0]
ax1.plot(train["ds"], train["y"], color="#2563eb", linewidth=1.2, label="Training data")
ax1.plot(test["ds"],  test["y"],  color="#64748b", linewidth=1.5, linestyle="--", label="Actual (test)")
ax1.plot(test["ds"],  prophet_test_pred, color="#f97316", linewidth=1.5, label="Prophet forecast (test)")
ax1.plot(prophet_forecast_df["ds"], prophet_forecast_df["yhat"],
         color="#10b981", linewidth=2, marker="o", markersize=5, label="7-day forecast")
ax1.fill_between(
    prophet_forecast_df["ds"],
    prophet_forecast_df["yhat_lower"],
    prophet_forecast_df["yhat_upper"],
    alpha=0.15, color="#10b981", label="90% CI"
)
ax1.axvline(test["ds"].iloc[0], color="red", linestyle=":", linewidth=1.2, alpha=0.7)
ax1.set_title("Daily Order Volume — History + 7-Day Forecast", fontsize=12)
ax1.set_ylabel("Orders / Day")
ax1.legend(fontsize=9, loc="upper left")
ax1.grid(True, alpha=0.3)
ax1.xaxis.set_major_formatter(mdates.DateFormatter("%b %d"))
ax1.xaxis.set_major_locator(mdates.WeekdayLocator(interval=2))
plt.setp(ax1.xaxis.get_majorticklabels(), rotation=30)

# — Plot 2: Hour-of-Day Demand Heatmap ————————————————————————————————————
ax2 = axes[1]
pivot = (
    df_hourly.assign(
        dow=df_hourly.ds.dt.dayofweek,
        hour=df_hourly.ds.dt.hour
    )
    .groupby(["dow", "hour"])["orders"]
    .mean()
    .unstack("hour")
)
days_labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
# Reindex so Monday=0
pivot = pivot.reindex(range(7))

im = ax2.imshow(pivot.values, aspect="auto", cmap="YlOrRd", interpolation="nearest")
ax2.set_yticks(range(7))
ax2.set_yticklabels(days_labels)
ax2.set_xticks(range(0, 24, 2))
ax2.set_xticklabels([f"{h:02d}:00" for h in range(0, 24, 2)], rotation=45, fontsize=8)
ax2.set_title("Average Orders Heatmap — Hour of Day × Day of Week", fontsize=12)
ax2.set_xlabel("Hour of Day")
plt.colorbar(im, ax=ax2, label="Avg Orders")

# Annotate cells
for i in range(7):
    for j in range(24):
        val = pivot.values[i, j]
        ax2.text(j, i, f"{val:.0f}", ha="center", va="center",
                 fontsize=6, color="black" if val < 15 else "white")

# — Plot 3: Model Comparison on Test Set ——————————————————————————————————
ax3 = axes[2]
x = np.arange(HOLDOUT)
width = 0.3
ax3.bar(x - width/2, test["y"].values, width, label="Actual", color="#2563eb", alpha=0.8)
ax3.bar(x + width/2, prophet_test_pred, width, label="Prophet forecast", color="#f97316", alpha=0.8)
ax3.plot(x, sarima_test_pred, color="#7c3aed", linewidth=2, marker="^",
         markersize=7, label="SARIMA forecast")
ax3.set_xticks(x)
ax3.set_xticklabels([d.strftime("%b %d") for d in test["ds"]], rotation=40, fontsize=8)
ax3.set_title(
    f"Test Set Comparison — Prophet MAE={prophet_mae:.1f} RMSE={prophet_rmse:.1f} | "
    f"SARIMA MAE={sarima_mae:.1f} RMSE={sarima_rmse:.1f}",
    fontsize=10
)
ax3.set_ylabel("Orders / Day")
ax3.legend(fontsize=9)
ax3.grid(True, alpha=0.3, axis="y")

plt.tight_layout(rect=[0, 0, 1, 0.97])
plt.savefig("/mnt/user-data/outputs/02_demand_forecast_charts.png", dpi=150, bbox_inches="tight")
print("\n   ✓ Charts saved → 02_demand_forecast_charts.png")


# ─────────────────────────────────────────────────────────────────────────────
# EXPORT FORECAST CSV
# ─────────────────────────────────────────────────────────────────────────────

forecast_export = prophet_forecast_df[["ds", "yhat", "yhat_lower", "yhat_upper"]].copy()
forecast_export.columns = ["date", "forecast_orders", "lower_90pct", "upper_90pct"]
forecast_export["store_pin"]    = STORE_PIN
forecast_export["model"]        = "Prophet"
forecast_export["generated_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
forecast_export = forecast_export[["store_pin", "model", "generated_at",
                                    "date", "forecast_orders", "lower_90pct", "upper_90pct"]]
forecast_export.to_csv("/mnt/user-data/outputs/02_7day_forecast.csv", index=False)
print("   ✓ Forecast CSV saved → 02_7day_forecast.csv")

print("\n" + "=" * 65)
print("  DONE  —  All outputs saved.")
print("=" * 65)
