#cloud-config

runcmd:
  - cd /tmp && wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
  - sudo dpkg -i amazon-ssm-agent.deb
  - sudo systemctl enable amazon-ssm-agent

bootcmd:
  - echo 'SERVER_ENVIRONMENT=${environment}' >> /etc/environment
  - echo 'SERVER_GROUP=${name}' >> /etc/environment
  - echo 'SERVER_REGION=${region}' >> /etc/environment

  - mkdir -p /etc/ecs
  - echo 'ECS_CLUSTER=${name}' >> /etc/ecs/ecs.config


  - echo 'ECS_ENGINE_AUTH_TYPE=${docker_auth_type}' >> /etc/ecs/ecs.config
  - >
    echo 'ECS_ENGINE_AUTH_DATA=${docker_auth_data}' >> /etc/ecs/ecs.config


