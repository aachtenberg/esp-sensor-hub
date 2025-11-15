"""
AWS CDK Stack for ESP8266 Temperature Logger Dashboard - Simplified

Creates:
- CloudWatch Dashboard for log visualization
- CloudWatch Alarms for notifications
- Log retention policy
- SNS topic for alerts
"""

try:
    from aws_cdk import (
        Stack,
        Duration,
        CfnOutput,
        App,
        RemovalPolicy,
        aws_cloudwatch as cloudwatch,
        aws_logs as logs,
        aws_sns as sns,
    )
    from constructs import Construct
except ImportError as e:
    print(f"ERROR: AWS CDK import failed: {e}")
    print("Install with: pip install -r cdk/requirements.txt")
    exit(1)


class TemperatureLoggerDashboardStack(Stack):
    """CDK Stack for Temperature Logger CloudWatch Dashboard"""

    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # Configuration
        log_group_name = "esp-sensor-logs"
        
        # Get or create log group with retention policy
        log_group = logs.LogGroup(
            self,
            "TemperatureLogGroup",
            log_group_name=log_group_name,
            retention=logs.RetentionDays.ONE_MONTH,
            removal_policy=RemovalPolicy.DESTROY
        )

        # Create SNS Topic for alarms
        alarm_topic = sns.Topic(
            self,
            "TemperatureAlarmTopic",
            display_name="ESP8266 Temperature Alerts",
            topic_name="esp8266-temperature-alerts"
        )

        # Create CloudWatch Dashboard
        dashboard = cloudwatch.Dashboard(
            self,
            "TemperatureLoggerDashboard",
            dashboard_name="ESP8266-Temperature-Logger"
        )

        # Add log activity widget
        dashboard.add_widgets(
            cloudwatch.GraphWidget(
                title="Log Activity",
                left=[
                    cloudwatch.Metric(
                        namespace="AWS/Logs",
                        metric_name="IncomingLogEvents",
                        statistic="Sum",
                        period=Duration.minutes(5),
                        region=self.region,
                        label="Incoming Events"
                    )
                ],
                width=24,
                height=6,
                left_y_axis=cloudwatch.YAxisProps(label="Count")
            )
        )

        # Add text widget with instructions
        dashboard.add_widgets(
            cloudwatch.TextWidget(
                markdown="""# ESP8266 Temperature Logger

**Status:** Ready to receive temperature data from device

**Data Flow:**
1. Device reads DS18B20 temperature every 30 seconds
2. Device sends JSON to Lambda: `{"tempC": X.XX, "tempF": X.XX, ...}`
3. Lambda logs to `/aws/lambda/esp-temperature-logger`
4. CloudWatch Logs Insights queries the data

**View temperatures:**
- AWS Console → CloudWatch → Logs Insights
- Query: `fields @timestamp, @message | filter @message like /Temp:/`
- Log Group: `/aws/lambda/esp-temperature-logger`
                """,
                width=24,
                height=8
            )
        )

        # Create Alarm: High activity
        high_alarm = cloudwatch.Alarm(
            self,
            "HighActivityAlarm",
            metric=cloudwatch.Metric(
                namespace="AWS/Logs",
                metric_name="IncomingLogEvents",
                statistic="Sum",
                period=Duration.minutes(5),
                region=self.region
            ),
            threshold=1,
            evaluation_periods=1,
            alarm_name="ESP8266-HighActivity",
            alarm_description="Alert on device activity",
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING
        )

        # Outputs
        CfnOutput(
            self,
            "DashboardURL",
            value=f"https://console.aws.amazon.com/cloudwatch/home?region={self.region}#dashboards:name=ESP8266-Temperature-Logger",
            description="CloudWatch Dashboard URL"
        )

        CfnOutput(
            self,
            "LogGroupName",
            value=log_group.log_group_name,
            description="CloudWatch Log Group Name"
        )

        CfnOutput(
            self,
            "SNSTopicArn",
            value=alarm_topic.topic_arn,
            description="SNS Topic ARN for alarms"
        )

        CfnOutput(
            self,
            "LambdaLogGroupInfo",
            value="/aws/lambda/esp-temperature-logger",
            description="Lambda function log group where temperatures are logged"
        )


class TemperatureLoggerApp(App):
    """CDK App for Temperature Logger Stack"""

    def __init__(self):
        super().__init__()
        
        TemperatureLoggerDashboardStack(
            self,
            "TemperatureLoggerDashboardStack",
            description="CloudWatch Dashboard for ESP8266 Temperature Logger"
        )


if __name__ == "__main__":
    app = TemperatureLoggerApp()
    app.synth()
