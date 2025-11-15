# 📊 CloudWatch Dashboard with AWS CDK

## Overview

This project includes an **AWS CDK application** that automatically creates a professional CloudWatch dashboard for monitoring your ESP8266 temperature sensor. Instead of manually clicking around the AWS console, CDK handles everything with code.

## What Gets Created

When you run `cdk deploy`, AWS automatically provisions:

### 🎨 CloudWatch Dashboard
```
┌─────────────────────────────────────────────────────────┐
│         ESP8266-Temperature-Logger Dashboard            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Temperature Over Time (24h)  │  Current Temp (Avg)    │
│  ├─ Line graph with C & F     │  ├─ Single value       │
│  ├─ Min/Max bands             │  └─ 5-min average      │
│  └─ 1-min intervals           │                        │
│                               │                        │
├─────────────────────────────────────────────────────────┤
│  Successful Uploads (5m)      │  Error Count (5m)      │
│  ├─ Sum of uploads            │  ├─ Error trends       │
│  └─ Device health indicator   │  └─ Performance metric │
│                               │                        │
├─────────────────────────────────────────────────────────┤
│  Max Temp (24h) │ Min Temp (24h) │ Avg Temp (24h)     │
├─────────────────────────────────────────────────────────┤
│  Recent Temperature Readings (CloudWatch Logs Insights)│
│  ├─ Last 100 readings                                  │
│  ├─ Statistics: avg, min, max grouped by 5-min bins    │
│  └─ Live updates as device sends data                  │
└─────────────────────────────────────────────────────────┘
```

### 🔔 CloudWatch Alarms (with SNS notifications)
- **High Temperature**: Alert when > 30°C (customizable)
- **Low Temperature**: Alert when < 5°C (customizable)
- **No Data**: Alert when device offline for 10+ minutes

### 📨 SNS Topic
- Automatically sends email when alarms trigger
- Add more subscribers (Slack, PagerDuty, etc.)

### 📝 Log Management
- 30-day retention policy (customizable)
- Automatic cleanup of old logs

---

## Quick Start

### Option 1: Automated Setup (Recommended)

```bash
cd esp12f_ds18b20_temp_sensor

# Run setup script (handles everything)
chmod +x cdk/setup.sh
./cdk/setup.sh

# Script will:
# ✓ Check Python, Node.js, AWS CLI
# ✓ Install CDK globally
# ✓ Install Python dependencies
# ✓ Bootstrap AWS account
# ✓ Deploy dashboard
```

### Option 2: Manual Setup

```bash
cd esp12f_ds18b20_temp_sensor

# 1. Install dependencies
pip install -r cdk/requirements.txt

# 2. Install CDK
npm install -g aws-cdk

# 3. Configure AWS (if not already done)
aws configure
# Enter: Access Key, Secret, Region (ca-central-1)

# 4. Bootstrap account (one-time)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
cdk bootstrap aws://$ACCOUNT_ID/ca-central-1

# 5. Deploy dashboard
cdk deploy
```

---

## How CDK Works

### What is AWS CDK?

CDK is **infrastructure as code** - you write Python/TypeScript to define AWS resources instead of clicking the AWS console.

### Benefits

✅ **Reproducible**: Same code = same resources every time  
✅ **Version Controlled**: Track changes in git  
✅ **Automated**: Deploy/update with single command  
✅ **Testable**: Write unit tests for infrastructure  
✅ **Idempotent**: Safe to run multiple times  

### How the Stack Works

```
┌────────────────────┐
│   app.py           │  Define dashboard, alarms, metrics
│                    │
│  Stack:            │
│  - Dashboard       │  What resources to create
│  - Alarms          │
│  - SNS Topic       │
└─────────┬──────────┘
          │
          ↓ cdk synth
┌────────────────────┐
│ CloudFormation     │  AWS template (cdk.out/*.json)
│ Template           │  Describes resources in AWS format
│ (JSON)             │
└─────────┬──────────┘
          │
          ↓ cdk deploy
┌────────────────────┐
│ AWS Resources      │  Actual resources created
│                    │  - CloudWatch Dashboard
│ ✓ Dashboard        │  - CloudWatch Alarms
│ ✓ Alarms           │  - SNS Topic
│ ✓ SNS Topic        │
└────────────────────┘
```

---

## Customization

### Change Temperature Thresholds

Edit `cdk/app.py`:

```python
# Around line 180 - High temperature alarm
threshold=30,  # Change to your desired temperature

# Around line 196 - Low temperature alarm
threshold=5,   # Change to your desired temperature
```

Then redeploy:
```bash
cdk deploy
```

### Add Email Notifications

Edit `cdk/app.py` - uncomment (around line 65):

```python
alarm_topic.add_subscription(
    sns_subs.EmailSubscription("your-email@example.com")
)
```

Redeploy and confirm email subscription:
```bash
cdk deploy
# Check your email for confirmation link
```

### Change Log Retention

Edit `cdk/app.py` (around line 55):

```python
log_group.retention = logs.RetentionDays.THREE_MONTHS  # Instead of ONE_MONTH
```

Options: `ONE_WEEK`, `TWO_WEEKS`, `ONE_MONTH`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`, `FOREVER`

### Add More Widgets

Extend `cdk/app.py` to add custom widgets:

```python
# Example: Add a widget showing last 10 minutes of data
dashboard.add_widgets(
    cloudwatch.GraphWidget(
        title="Last 10 Minutes",
        left=[temp_c_metric],
        width=6,
        height=4,
        period=core.Duration.minutes(1),
        yaxis=cloudwatch.YAxisProps(min=15, max=30)
    )
)
```

---

## Usage Commands

### View Dashboard

**After deploying**, CDK prints the URL:

```
Outputs:
DashboardURL = https://console.aws.amazon.com/cloudwatch/home?region=ca-central-1#dashboards:name=ESP8266-Temperature-Logger
```

Open in browser or via AWS Console:
1. AWS Console → CloudWatch
2. Dashboards → ESP8266-Temperature-Logger

### Update Dashboard

Make changes to `cdk/app.py`, then:

```bash
# Review changes
cdk diff

# Deploy updates
cdk deploy
```

### View Generated CloudFormation

```bash
# Generates AWS CloudFormation template
cdk synth

# Output stored in cdk.out/TemperatureLoggerDashboardStack.json
cat cdk.out/TemperatureLoggerDashboardStack.json
```

### View Deployment Status

```bash
# List all stacks
aws cloudformation list-stacks

# Describe specific stack
aws cloudformation describe-stacks \
  --stack-name TemperatureLoggerDashboardStack

# View stack resources
aws cloudformation describe-stack-resources \
  --stack-name TemperatureLoggerDashboardStack
```

### Destroy Resources

```bash
# Remove dashboard, alarms, SNS topic
# (Keeps log group intact for safety)
cdk destroy

# Or destroy all including logs
cdk destroy && \
aws logs delete-log-group --log-group-name esp-sensor-logs
```

---

## Dashboard Walkthrough

### Section 1: Temperature Graph
**What**: Real-time temperature over last 24 hours  
**Left axis**: Celsius (°C)  
**Right axis**: Fahrenheit (°F)  
**Update frequency**: Every 1 minute

**How to read**:
- Green line = Celsius trend
- Blue line = Fahrenheit trend
- Peaks/valleys = Temperature fluctuations

### Section 2: Current Temperature
**What**: Single number showing average from last 5 minutes  
**Update frequency**: Every 5 minutes  

**Why useful**:
- Quick glance at current conditions
- Complements the detailed graph

### Section 3: Device Health
**Left**: Successful uploads count  
- Should increase ~2 per minute (every 30 seconds)
- Flat line = device offline

**Right**: Error count  
- Should stay at 0
- Spike = problem detected

### Section 4: 24-Hour Statistics
**Max Temp**: Highest temperature reading in 24 hours  
**Min Temp**: Lowest temperature reading in 24 hours  
**Avg Temp**: Average of all readings in 24 hours  

### Section 5: Recent Readings (Logs Insights)
**What**: Detailed log entries from last 100 readings  
**Shows**: Timestamp, message, parsed temperature values  
**Update**: Live as device sends data

**Example query** (in dashboard):
```
fields @timestamp, @message, tempC, tempF
| filter @message like /Temp:/
| stats count() as readings, avg(tempC) as avg_temp by bin(5m)
| limit 100
```

---

## Alarms & Notifications

### How Alarms Work

```
Device sends data
    ↓
CloudWatch Logs Insight parses
    ↓
Metric calculated (avg temperature)
    ↓
Alarm evaluates (is it > 30°C?)
    ↓
If YES → Trigger SNS notification
    ↓
Email sent to subscriber(s)
```

### Create Custom Alarms

Add to `cdk/app.py`:

```python
# Alert if no data for 5 minutes
no_data_alarm = cloudwatch.Alarm(
    self,
    "NoDataAlarm",
    metric=uploads_metric,
    threshold=0,
    evaluation_periods=1,
    datapoints_to_alarm=1,
    alarm_name="ESP8266-NoDataFor5Min",
    alarm_description="Alert if device hasn't sent data in 5 minutes",
    comparison_operator=cloudwatch.ComparisonOperator.LESS_THAN_OR_EQUAL_TO_THRESHOLD
)
no_data_alarm.add_alarm_action(
    cw_actions.SnsAction(alarm_topic)
)
```

Then redeploy:
```bash
cdk deploy
```

---

## Integrate with Other Services

### Slack Notifications

Instead of email, send alarms to Slack:

```python
# Install boto3 (if not already)
pip install boto3

# Create Lambda that posts to Slack
# Lambda gets triggered by SNS
# Lambda posts to Slack webhook
```

See AWS docs for Slack integration via Lambda.

### Grafana Dashboard

Connect Grafana to CloudWatch Logs:

1. Grafana → Data Sources → CloudWatch
2. Enter AWS credentials
3. Create dashboard with same metrics

### Export to S3

Auto-export logs to S3 for archival:

```python
# Add to cdk/app.py
s3_export = logs.ExportDestination(
    self,
    "S3Destination",
    bucket=s3.Bucket(self, "LogsBucket")
)

log_group.add_export_to_s3(
    bucket=s3_export.bucket,
    prefix="temperature-logs/"
)
```

---

## Troubleshooting

### CDK Not Found

```bash
npm install -g aws-cdk
cdk --version
```

### AWS Credentials Error

```bash
aws configure
aws sts get-caller-identity  # Test credentials
```

### Bootstrap Error

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
cdk bootstrap aws://$ACCOUNT_ID/ca-central-1
```

### Deploy Permission Error

Ensure AWS user has IAM permissions for:
- `cloudwatch:*`
- `logs:*`
- `sns:*`
- `cloudformation:*`

### Dashboard Not Showing Data

1. **Check device is uploading**: Serial monitor should show "HTTP Code: 200"
2. **Wait 5 minutes**: First data takes time to aggregate
3. **Verify log group exists**: `aws logs describe-log-groups`
4. **Check log stream**: `aws logs describe-log-streams --log-group-name esp-sensor-logs`

---

## Files Reference

```
cdk/
├── app.py                    # Main stack definition
├── __init__.py              # Python module marker
├── requirements.txt         # Python dependencies
├── setup.sh                 # Automated setup script
└── README.md               # Detailed CDK guide

cdk.out/                    # Generated files (auto-created)
└── TemperatureLoggerDashboardStack.json

Root:
└── cdk_app.py              # Entry point (cdk deploy runs this)
```

---

## Complete Example

```bash
# Full deployment from scratch
cd ~/PlatformIO/esp12f_ds18b20_temp_sensor

# Install CDK globally
npm install -g aws-cdk

# Install Python dependencies
pip install -r cdk/requirements.txt

# Configure AWS
aws configure
# Enter credentials for ca-central-1 region

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Bootstrap (one-time)
cdk bootstrap aws://$ACCOUNT_ID/ca-central-1

# Deploy
cdk deploy

# View output - copy the DashboardURL
# Open in browser

# Monitor serial output from ESP8266
platformio device monitor -p /dev/ttyUSB0 -b 115200

# Within 5-10 seconds, you should see data on dashboard
# Within 30 seconds, graph will start building
# Within 5 minutes, you'll see all statistics
```

---

## Next Steps

1. ✅ Run `cdk deploy`
2. ✅ View dashboard (copy URL from output)
3. ✅ Wait 5 minutes for data to appear
4. ✅ (Optional) Add email notifications
5. ✅ (Optional) Customize temperature thresholds
6. ✅ (Optional) Create Grafana dashboard

---

## Cost

✅ **Completely free** (within free tier):
- CloudWatch Dashboard: Free
- CloudWatch Alarms: Free (first 10)
- CloudWatch Logs Insights: ~$0.50 per 1GB scanned (but free tier covers it)
- SNS Email: Free
- Total: **$0.00/month** ✅

---

**Happy Monitoring!** 📊🎉
