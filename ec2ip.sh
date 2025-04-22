aws ec2 describe-instances \
  --region us-west-2 \
  --query "Reservations[*].Instances[*].PrivateIpAddress" \
  --output text | grep '^10\.2\.20\.'