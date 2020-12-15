# CircleCI Deployments Orb Project

[![CircleCI Build Status](https://circleci.com/gh/vnatures/circleci-deployments.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/vnatures/circleci-deployments) [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/versatile/circleci-deployments)](https://circleci.com/orbs/registry/orb/versatile/circleci-deployments) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/vnatures/circleci-deployments/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)


## Usage

See the [orb registry listing](https://circleci.com/orbs/registry/orb/versatile/circleci-deployments) for usage guidelines.

# NodeJS (Typescript) Service Example

## Prerequisites:

---

### Configure environment variables on CircleCI
The following [environment variables](https://circleci.com/docs/2.0/env-vars/#setting-an-environment-variable-in-a-project) must be set for the project on CircleCI via the project settings page, before the project can be built successfully.


| Variable                       | Description                                                 |
| ------------------------------ | ---------------------------------------------------------   |
| `APP_NAME`                     | Your service name used as the container-name, service-name in ECS, task-definition prefix and as ECR repo name                                                                    |
| `AWS_ACCESS_KEY_ID`            | Used by the AWS CLI                                         |
| `AWS_SECRET_ACCESS_KEY `       | Used by the AWS CLI                                         |
| `AWS_REGION`                   | Used by the AWS CLI. Example value: "us-east-2" (Please make sure the specified region is supported by the Fargate launch type)                                                |
| `AWS_ACCOUNT_ID`               | AWS account id. This information is required for deployment.|


To use slack channel please configure the additional 2 more environment variables and follow this guide [setup slack orb](https://github.com/CircleCI-Public/slack-orb):
SLACK
| Variable                       | Description                                               |
| ------------------------------ | --------------------------------------------------------- |
| `SLACK_ACCESS_TOKEN`           | Your access token created in the Slack Apps dashboard     |
| `SLACK_DEFAULT_CHANNEL`        | The channel used to send notification by the bot          |


> Optional: add environment specific variables in contexts such as NODE_ENV, ECS_CLUSTER_NAME

#### We've organize them in CircleCI contexts:

Organization level:
* base-context: [AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, AWS_ACCOUNT_ID]
* staging/production: [NODE_ENV, ECS_CLUSTER_NAME]
* slack-secrets: [NODE_ENV, ECS_CLUSTER_NAME]

Project level:
* APP_NAME: the service name (the git repo name or agreed upon name)

```yaml
version: 2.1
orbs:
  versatile: versatile/circleci-deployments@1.0.0

jobs:
  build:
    executor: versatile/default
    steps:
      - checkout
      - run: env
      - run:
          command: 'npm ci'
          name: 'Install Dependencies'
      - run:
          command: 'npm run build'
          name: 'Build app'
      - persist_to_workspace:
          root: ~/project
          paths:
            - build
            - config
            - Dockerfile
            - package.json
            - package-lock.json
            - .npmrc
            - env.js
            - node_modules

  run-migrations:
    executor: versatile/default
    steps:
      - checkout
      - aws-cli/install
      - aws-cli/setup
      - attach_workspace:
          at: ~/project
      - run: env
      - run: node env.js
      - run:
          command: 'npm run db:prepare'
          name: 'Running DB Migrations'

workflows:
  deploy-staging:
    when:
      not:
        - equal: [ master, << pipeline.git.branch >> ]
    jobs:
      - build:
          context: base-context
      - versatile/push-docker-image:
          workspace-root: ~/project
          context:
            - base-context
            - staging
          requires:
            - build
      - slack/on-hold:
          context: slack-secrets
          requires:
            - versatile/push-docker-image
      - approve-deploy:
          type: approval
          release-timeout: 600
          requires:
            - slack/on-hold
            - versatile/push-docker-image
      - run-migrations:
          context:
            - base-context
            - staging
          requires:
            - approve-deploy
      - versatile/deploy-docker-image:
          name: deploy-docker-image-staging
          requires:
            - run-migrations
          context:
            - base-context
            - staging
            - slack-secrets
  deploy-production:
    when:
      equal: [ master, << pipeline.git.branch >> ]
    jobs:
      - build:
          context: base-context
      - versatile/push-docker-image:
          workspace-root: ~/project
          context:
            - base-context
            - production
          requires:
            - build
      - run-migrations:
          context:
            - base-context
            - production
          requires:
            - versatile/push-docker-image
      - versatile/deploy-docker-image:
          name: deploy-docker-image-production-spot
          cluster-name: '${ECS_SPOT_CLUSTER_NAME}'
          requires:
            - run-migrations
          context:
            - base-context
            - production
            - slack-secrets
      - versatile/deploy-docker-image:
          name: deploy-docker-image-production-on-demand
          cluster-name: '${ECS_ON_DEMAND_CLUSTER_NAME}'
          requires:
            - run-migrations
            - deploy-docker-image-production-spot
          context:
            - base-context
            - production
            - slack-secrets
```



### UI only (FED) application bundle deploy (AWS S3 bucket + CloudFront)

For deploying frontend application, additional env var required
AWS_DIST_ID: cloudfront's distribution id.

```yaml
version: 2.1
orbs:
  versatile: versatile/circleci-deployments@1.0.0

jobs:
  build:
    docker:
      - image: circleci/node:12.18.4-browsers
    steps:
      - checkout
      - run:
        name: "Setup Environment"
        command: |
          mkdir -p ~/reports
          node --version
          npm --version
          env
      - node/install-packages
      - run: cp ./envs/$NODE_ENV.env .env
      - run: npm run build
      - persist_to_workspace:
        root: ~/project
        paths:
          - build

workflows:
  build:
    jobs:
      - build
  deploy:
    jobs:
      - versatile/invalidate-and-sync-s3:
          workspace-root: ~/project
          build-path: build
          node-env: staging # refered from NODE_ENV if not provided.
          bucket-name: '${APP_NAME}-${NODE_ENV}.example.com'
          context:
            - base-context
            - staging
```

## References
- https://github.com/circleci/go-ecs-ecr
- https://github.com/awslabs/aws-cloudformation-templates
- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_GetStarted.html
