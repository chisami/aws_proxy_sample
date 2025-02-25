#!/bin/bash

# Parameters
max_retries=1000          # Maximum number of retries
retry_interval=30        # Wait time (in seconds) between retries
retry_count=0            # Retry counter
terraform_command="terraform apply -auto-approve"  # Terraform apply command

# Function to check if at least one instance has been created
check_instance_created() {
    # Check if any `oci_core_instance` resource exists in the Terraform state
    terraform state list | grep "oci_core_instance" > /dev/null 2>&1
    return $?  # Return 0 if at least one instance is found, 1 otherwise
}

# Retry loop for Terraform apply
while true; do
    echo "Attempting 'terraform apply' (attempt $((retry_count + 1)))..."

    # Run terraform apply and capture output
    output=$($terraform_command 2>&1)
    exit_code=$?

    # Check Terraform state for at least one created instance
    if check_instance_created; then
        echo "At least one instance has been successfully created!"
        break
    fi

    # Handle Terraform apply errors
    if [ $exit_code -ne 0 ]; then
        # Check for specific "Out of host capacity" error
        if echo "$output" | grep -q "Out of host capacity"; then
            echo "Error: Out of host capacity. Retrying in $retry_interval seconds..."
            ((retry_count++))

            # Check if max retries are reached
            if [ $retry_count -ge $max_retries ]; then
                echo "Max retries reached. Terraform apply failed."
                exit 1
            fi

            # Wait before retrying
            sleep $retry_interval
        else
            # Unexpected error, exit immediately
            echo "Unexpected error encountered:"
            echo "$output"
            exit $exit_code
        fi
    fi
done