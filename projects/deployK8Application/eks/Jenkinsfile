#!/usr/bin/env groovy
pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = "us-east-1"
    }
    stages {
        stage("Create an EKS Cluster") {
            steps {
                script {
                    dir('projects/deployK8Application/eks') {
                        sh 'terraform init'
                        sh 'terraform plan'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage("Deploy to EKS") {
            steps {
                script {
                    dir('projects/deployK8Application/kubernetes') {
                        sh '''
                            echo "=== Configuring kubeconfig ==="
                            aws eks update-kubeconfig --name my-eks-cluster --region $AWS_DEFAULT_REGION

                            echo "=== Deploying Nginx ==="
                            kubectl apply -f nginx-deployment.yaml

                            # Delete service if exists (safe: --ignore-not-found)
                            kubectl delete service nginx --ignore-not-found

                            # Apply service → creates new LB in PUBLIC subnets
                            kubectl apply -f nginx-service.yaml

                            echo "=== Done. LB will be ready in 2-5 minutes ==="
                        '''
                    }
                }
            }
        }
    }
}