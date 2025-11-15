#!/usr/bin/env python3
"""
CDK app entry point for ESP8266 Temperature Logger Dashboard

Usage:
    python3 cdk/app.py       # Synthesize CloudFormation template
    cdk deploy               # Deploy to AWS
    cdk destroy             # Tear down resources
"""

from cdk.app import TemperatureLoggerDashboardStack
from aws_cdk import App


def main():
    app = App()
    
    TemperatureLoggerDashboardStack(
        app,
        "TemperatureLoggerDashboardStack",
        description="CloudWatch Dashboard and Alarms for ESP8266 Temperature Logger"
    )
    
    app.synth()


if __name__ == "__main__":
    main()
