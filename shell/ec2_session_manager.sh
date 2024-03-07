#!/bin/sh

# Enable/disable debug tracing
set +x

# Check if the fzf command is available
if [ ! -x "$(command -v fzf)" ]; then
    echo "Error: fzf is not installed. Please install fzf."
    exit 1
fi

select_profile() {
    # Get list of profiles excluding 'default'
    local profiles=$(aws configure list-profiles | grep -v '^default$')

    # Use fzf for interactive selection
    local selected_profile=$(echo "$profiles" | fzf --prompt="Select AWS profile: ")
    echo "$selected_profile"
}

# Check if EC2 instance is provided
if [ -z "$1" ]; then
    echo "Error: Please provide an EC2 instance ID."
    echo "Usage: $0 <instance>"
    exit 1
fi

# Check if profile is provided
if [ -z "$2" ]; then
    selected_profile=$(select_profile)

    # Check if the user canceled the selection
    if [ -z "$selected_profile" ]; then
        echo "Error: No profile selected."
        exit 1
    fi

    profile="$selected_profile"
fi

# Verify identity of the caller
caller_identity=$(aws sts get-caller-identity --profile $profile 2> /dev/null)
if [ "$?" -ne 0 ]; then
    echo "Token for SSO session does not exist. Please refresh token:"
    aws sso login --sso-session main
fi

# Get the instance ID from an EC2 service
instanceId=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$1" \
    --query "Reservations[*].Instances[*].[InstanceId]" \
    --profile $profile \
    --output text)

# Connect to a Session Manager from localhost
aws ssm start-session --target $instanceId --profile $profile
