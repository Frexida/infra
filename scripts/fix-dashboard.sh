#!/bin/bash
# CloudWatch Dashboardのコメントアウトスクリプト

sed -i '60,155s/^/# /' /home/mtdnot/dev/frexida/infra/modules/self-healing-cicd/monitoring.tf
echo "CloudWatch Dashboard has been commented out"