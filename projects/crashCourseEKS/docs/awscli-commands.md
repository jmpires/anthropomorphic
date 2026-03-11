
# Allow disable the deletion protection
aws dynamodb update-table \
    --table-name terraform-state-lock \
    --no-deletion-protection-enabled