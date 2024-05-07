#!/bin/bash

# Define ASG Name
ASG_NAME="your-auto-scaling-group-name"

# Step 1: Increase the desired capacity of the ASG by N
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --desired-capacity $(($(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].DesiredCapacity') + N))

# Wait for new instances to be in service
while [[ $(aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[?AutoScalingGroupName==`'$ASG_NAME'`].[LifecycleState]' --output text | grep -c "InService") -lt $(($(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].DesiredCapacity'))) ]]; do
  echo "Waiting for instances to be in service..."
  sleep 30
done

# Step 2: Update the ASG to use a new Launch Template version if necessary
# aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --launch-template LaunchTemplateName=your-template-name,Version=new-version

# Step 3: Reduce the desired capacity to original size
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --desired-capacity $(($(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].DesiredCapacity') - N))

# Optional: Cleanup - identify and terminate older instances
# Your logic to select and terminate older instances goes here

