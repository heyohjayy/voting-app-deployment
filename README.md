# Voting Application Deployment with Docker, Docker Compose & Jenkins CI/CD

## 1. Project Overview

This project demonstrates the end-to-end deployment and automation of a three-tier microservices voting application using Docker, Docker Compose, Jenkins, GitHub, Docker Hub, and Slack. The objective was to transform a manually deployed containerised application into a production-oriented Continuous Integration and Continuous Deployment (CI/CD) solution capable of independently building, publishing, and deploying each application service.

Unlike the original implementation, where all application services were managed from a single Docker Compose file, this project adopts a per-service deployment architecture. Each application component (**Vote**, **Worker**, and **Result**) has its own Docker Compose configuration, Jenkins pipeline, and deployment script, allowing services to be updated independently without interrupting the rest of the application.

The solution integrates GitHub Webhooks for automatic build triggering, Docker Hub as the central image registry, Slack notifications for real-time pipeline monitoring, and an automated rollback mechanism to improve deployment reliability.

By the end of the implementation, every Git push automatically triggers the appropriate Jenkins pipeline, builds only the modified service, tags the Docker image using the current Git commit SHA, publishes the image to Docker Hub, deploys the updated container, validates the deployment, and sends the build status directly to Slack.

To reproduce the complete implementation, a detailed step-by-step guide is available in the project documentation:

- **[SETUP.md](docs/SETUP.md)** – Complete implementation guide containing every configuration step, command, and verification screenshot used throughout the project.

## 2. Repository Structure

The repository has been organised to separate application services, deployment automation, documentation, and supporting resources. Each microservice contains its own Dockerfile, Docker Compose configuration, and Jenkins pipeline, while deployment and rollback automation are centrally managed within the `deploy` directory.

```text
voting-app-deployment/
├── deploy/
│   ├── result.sh
│   ├── rollback.sh
│   ├── vote.sh
│   └── worker.sh
├── docs/
│   └── SETUP.md
├── extras/
│   ├── docker-stack.yml
│   ├── k8s-specifications/
│   └── seed-data/
├── healthchecks/
│   ├── postgres.sh
│   └── redis.sh
├── result/
│   ├── Dockerfile
│   ├── Jenkinsfile
│   ├── docker-compose.yml
│   └── ...
├── screenshots/
├── vote/
│   ├── Dockerfile
│   ├── Jenkinsfile
│   ├── docker-compose.yml
│   └── ...
├── worker/
│   ├── Dockerfile
│   ├── Jenkinsfile
│   ├── docker-compose.yml
│   └── ...
├── LICENSE
├── README.md
└── docker-compose.yml
```

The original project resources that were not required for the CI/CD implementation have been moved into the `extras` directory, allowing the repository to focus on the Docker and Jenkins deployment workflow implemented in this project.

## 3. Solution Architecture

The application follows a microservices architecture consisting of five interconnected services:

- **Vote Service** (Python/Flask) – Provides the web interface where users cast their votes.
- **Worker Service** (.NET) – Processes votes submitted by users and transfers them from Redis into PostgreSQL.
- **Result Service** (Node.js) – Retrieves processed voting results from PostgreSQL and displays them through the web interface.
- **Redis** – Acts as an in-memory message broker, temporarily storing incoming votes before they are processed.
- **PostgreSQL** – Serves as the application's persistent database, storing processed voting data for retrieval by the Result service.

The infrastructure is built around a shared Docker network, allowing all services to communicate securely while remaining independently deployable. The core infrastructure services (**Redis** and **PostgreSQL**) are managed through the root `docker-compose.yml`, while each application service (**Vote**, **Worker**, and **Result**) is deployed independently using its own Docker Compose configuration and Jenkins pipeline.

When code is pushed to GitHub, a webhook automatically triggers the appropriate Jenkins pipeline. Jenkins checks out the latest source code, builds a new Docker image, tags it using the current Git commit SHA, authenticates with Docker Hub, pushes the image to the registry, and executes the deployment script for the modified service.

The deployment script pulls the latest image from Docker Hub, recreates only the affected application service without interrupting the remaining containers, verifies that the deployment completed successfully, and automatically invokes the rollback script if validation fails. Throughout the deployment process, Slack provides real-time build notifications for every pipeline execution.

![CI/CD Architecture](screenshots/architecture-diagram.png)

## 4. Infrastructure Overview

The solution is hosted on a single **Ubuntu 24.04 Amazon EC2 instance** running in AWS.

Docker provides the container runtime for both the application services and the Jenkins environment, while Docker Compose manages the application containers. Redis and PostgreSQL provide the application's messaging and database layers through a shared external Docker network, allowing every service to communicate while remaining independently deployable.

The infrastructure consists of:

- Amazon EC2 (Ubuntu 24.04 LTS)
- Docker Engine
- Docker Compose
- Jenkins Controller (Docker Container)
- Jenkins Inbound Build Agent (Docker Container)
- Redis
- PostgreSQL
- GitHub
- Docker Hub
- Slack

## 5. Technology Stack

| Category | Technologies |
|----------|--------------|
| Cloud Platform | AWS EC2 (Ubuntu 24.04 LTS) |
| Containerisation | Docker, Docker Compose |
| CI/CD | Jenkins, Jenkins Inbound Agent |
| Source Control | Git, GitHub |
| Container Registry | Docker Hub |
| Automation | Bash |
| Notifications | Slack |
| Database | PostgreSQL 15 |
| Message Broker | Redis |
| Programming Languages | Python, C#, Node.js |
| Networking | Docker Bridge Network (tenet) |
| Image Versioning | Git Commit SHA Tagging |
| Deployment Strategy | Per-Service Continuous Deployment with Automated Rollback |

## 6. Docker Containerization

The first phase of the project focused on containerising the complete voting application using Docker. Each application component was packaged into its own Docker image to ensure consistency across development and deployment environments.

The project consists of three application services:

- **Vote Service** – A Python Flask application that provides the voting interface.
- **Worker Service** – A .NET background service responsible for processing votes.
- **Result Service** – A Node.js application that displays the voting results.

Supporting infrastructure services were also deployed using official Docker images:

- **Redis** – Message broker used to temporarily store incoming votes.
- **PostgreSQL** – Relational database used to persist processed voting data.

Each service was successfully containerised, allowing the application to run consistently regardless of the underlying host environment.

The Docker images were verified before proceeding with orchestration.

![Docker Image Build](screenshots/02-docker-app-image-build.png)

## 7. Docker Compose Deployment

After successfully containerising the application, Docker Compose was used to orchestrate the deployment of all services.

Unlike the original implementation, this project adopts a **per-service deployment architecture**. The root `docker-compose.yml` manages only the shared infrastructure services (**Redis** and **PostgreSQL**), while each application service has its own dedicated Docker Compose configuration:

- `vote/docker-compose.yml`
- `worker/docker-compose.yml`
- `result/docker-compose.yml`

This architecture enables independent deployment of each service without affecting the remaining application components. During a deployment, Jenkins updates only the modified service while Redis, PostgreSQL, and the other application services continue running uninterrupted.

The application services communicate through the shared external Docker network (`tenet`), ensuring seamless communication between containers while maintaining deployment isolation.

The project structure below illustrates the separation of the Docker Compose configurations.

![Docker Compose Project Structure](screenshots/08-tree-showing-composefiles.png)

The complete application was then deployed using Docker Compose and verified to ensure that every service started successfully.

![Docker Compose Deployment](screenshots/10-docker-compose-up.png)

## 8. Jenkins Build Automation

To automate the build and deployment process, Jenkins was deployed as a Docker container and configured as the project's Continuous Integration and Continuous Deployment (CI/CD) platform.

Rather than manually building Docker images and deploying containers after every code change, Jenkins automates the complete workflow. Every Git push triggers the appropriate pipeline, which performs the following tasks:

- Checks out the latest source code from GitHub.
- Retrieves the current Git commit SHA.
- Builds the Docker image for the modified service.
- Tags the image using the Git commit SHA.
- Authenticates with Docker Hub.
- Pushes the newly built image to Docker Hub.
- Executes the corresponding deployment script.
- Sends build notifications to Slack.

This automation significantly reduces manual intervention while ensuring every deployment follows the same repeatable process.

Jenkins was successfully deployed and configured using Docker.

![Jenkins Controller](screenshots/13-jenkins-container+UI-welcomepage.png)

## 9. Jenkins Build Agent

To separate build execution from the Jenkins controller, a dedicated Jenkins Inbound Build Agent was provisioned as a Docker container.

The build agent is responsible for executing all pipeline stages, including Docker image builds, image tagging, Docker Hub publishing, and deployment script execution. Offloading builds to a dedicated agent improves scalability and follows Jenkins best practices by keeping the controller focused on orchestration rather than workload execution.

The Jenkins controller communicates securely with the build agent through the Jenkins remoting protocol, allowing all pipelines to execute on the agent while remaining centrally managed from the Jenkins dashboard.

The successful connection between the Jenkins controller and the build agent was verified before implementing the CI/CD pipelines.

![Jenkins Build Agent](screenshots/19-jenkins-agent-online.png)

## 10. Per-Service CI/CD Pipeline Design

The CI/CD implementation follows a per-service pipeline design, where each application component is managed independently through its own Jenkins pipeline.

Three independent declarative Jenkins pipelines were implemented to support the deployment of each application service:

- **vote-pipeline**
- **worker-pipeline**
- **result-pipeline**

Each pipeline references its own service-specific `Jenkinsfile` and deployment script, ensuring that modifications to one service trigger only its corresponding pipeline without affecting the remaining application components.

Rather than combining Continuous Integration (CI) and Continuous Deployment (CD) into a single Jenkinsfile, the responsibilities were deliberately separated to improve maintainability and scalability.

The **Jenkinsfile** is responsible for the Continuous Integration (CI) phase. Its responsibilities include:

1. Checking out the latest source code from GitHub.
2. Retrieving the current Git commit SHA.
3. Building the Docker image.
4. Tagging the image using the Git commit SHA.
5. Authenticating with Docker Hub.
6. Pushing the tagged image to Docker Hub.
7. Executing the corresponding deployment script.

Once the image has been successfully built and published, the deployment process is handed over to the service-specific deployment script ([vote.sh](deploy/vote.sh), [worker.sh](deploy/worker.sh), or [result.sh](deploy/result.sh)).

Each deployment script is responsible for the Continuous Deployment (CD) phase by:

- Pulling the newly published image from Docker Hub.
- Recreating only the affected application service using its dedicated Docker Compose configuration.
- Verifying that the service has started successfully.
- Automatically invoking `rollback.sh` if the deployment validation fails.

By separating CI and CD responsibilities, the Jenkins pipelines remain lightweight and focused solely on build automation, while all deployment logic is isolated within reusable Bash scripts. This design also improves future maintainability. For example, if the deployment platform changes from Docker Compose to Kubernetes, only the deployment scripts need to be updated, while the Jenkins pipelines remain largely unchanged.

This modular approach reduces deployment time, minimises service interruption, simplifies maintenance, and allows each microservice to evolve independently while maintaining a consistent deployment workflow across the entire application.

![Jenkins Pipeline Configuration](screenshots/22-pipeline-job-configuration-general.png)

## 11. GitHub Integration

GitHub served as the project's central source code repository, providing version control and acting as the single source of truth for all application code, deployment scripts, and CI/CD configuration.

The repository was restructured to support a per-service deployment model, with each application service maintaining its own Docker Compose configuration and Jenkins pipeline. A dedicated feature branch (`feature/voting-app-cicd`) was used throughout development to isolate CI/CD implementation from the original project before validation.

Jenkins securely authenticates with GitHub using a Personal Access Token (PAT), allowing each pipeline to clone the repository, retrieve the latest source code, and build the appropriate service whenever changes are pushed.

This integration forms the first stage of the automated CI/CD workflow by ensuring every deployment begins with the latest version of the source code.

## 12. Docker Hub Integration

Docker Hub was configured as the project's private container registry, providing a central location for storing and distributing Docker images produced during the CI pipeline.

After building each application service, Jenkins authenticates with Docker Hub using securely stored Jenkins credentials before publishing the newly built image.

To improve image traceability and version control, every image is tagged using the current Git commit SHA. This approach guarantees that each deployment references a unique image version while also supporting automated rollback to previously deployed releases when necessary.

A typical image publication workflow consists of:

1. Build the Docker image.
2. Tag the image using the current Git commit SHA.
3. Authenticate with Docker Hub.
4. Push the tagged image to Docker Hub.
5. Log out of Docker Hub.

Using Docker Hub as the central image registry ensures that deployment servers always retrieve the exact image version produced by the Jenkins pipeline.

![Docker Hub Repository](screenshots/35-dockerhub-images.png)

## 13. Automated Deployment & Rollback

Once Jenkins successfully completes the Continuous Integration phase, control is transferred to the service-specific deployment scripts responsible for Continuous Deployment.

Each deployment script performs the following tasks:

1. Pull the newly published Docker image from Docker Hub.
2. Recreate only the affected application service using its dedicated Docker Compose configuration.
3. Verify that the deployment completed successfully.
4. Automatically invoke the rollback script if deployment validation fails.

The rollback mechanism provides an additional layer of deployment reliability by restoring the previously deployed image whenever a deployment cannot be successfully completed. This prevents failed deployments from leaving the application in an unstable state while minimising service disruption.

Separating deployment and rollback logic into dedicated Bash scripts keeps the Jenkins pipelines lightweight, reusable, and easier to maintain. It also allows the deployment strategy to evolve independently from the CI process. For example, migrating from Docker Compose to Kubernetes would require changes only to the deployment scripts, while the Jenkins pipelines would remain largely unchanged.

This modular design improves maintainability, simplifies troubleshooting, and provides a robust deployment workflow suitable for production-oriented environments.

## 14. GitHub Webhook Automation

GitHub Webhooks were configured to eliminate the need for manually triggering Jenkins builds.

Whenever code is pushed to the repository, GitHub immediately sends a webhook event to the Jenkins server. Jenkins receives the notification, determines which pipeline should be executed, checks out the latest source code, and begins the automated CI/CD workflow.

This event-driven approach ensures that deployments occur automatically after every successful code push, enabling a fully automated Continuous Integration and Continuous Deployment process.

The webhook payload targets the Jenkins GitHub webhook endpoint and is configured to trigger on every push event.

![GitHub Webhook Configuration](screenshots/31-github-webhook-configuration.png)

## 15. Slack Notification Integration

Slack was integrated with Jenkins to provide real-time visibility into pipeline execution.

The Jenkins Slack Notification Plugin was configured using a Slack Bot User OAuth Token stored securely as a Jenkins Secret Text credential. Once configured, each pipeline automatically posts notifications to the designated Slack channel after every build.

Notifications include important deployment information such as:

- Pipeline status (Success, Failure, or Aborted).
- Jenkins job name.
- Build number.
- Source branch.
- Direct link to the Jenkins build.

This integration enables rapid monitoring of deployment activities without requiring administrators to continuously access the Jenkins dashboard.

![Slack Build Notification](screenshots/36-slack-build-notification.png)

## 16. End-to-End CI/CD Workflow

The completed CI/CD solution provides a fully automated deployment pipeline that begins with a code change and ends with a successful deployment of the updated application service.

The workflow consists of the following stages:

1. A developer pushes code to the GitHub repository.
2. GitHub sends a webhook event to Jenkins.
3. Jenkins automatically triggers the corresponding service pipeline.
4. Jenkins checks out the latest source code.
5. The current Git commit SHA is retrieved.
6. A new Docker image is built.
7. The image is tagged using the Git commit SHA.
8. Jenkins authenticates with Docker Hub.
9. The tagged image is published to Docker Hub.
10. The service-specific deployment script is executed.
11. The deployment script pulls the latest image from Docker Hub.
12. Only the affected application service is recreated using its dedicated Docker Compose configuration.
13. The deployment is validated to confirm that the service is running successfully.
14. If deployment validation fails, the rollback script automatically restores the previous image.
15. Jenkins sends the final pipeline status to the configured Slack channel.

This workflow enables fully automated Continuous Integration and Continuous Deployment while ensuring that application updates remain isolated to the modified service, reducing downtime and improving deployment reliability.

![Pipeline Build Success](screenshots/33-pipeline-build-success.png)

## 17. Project Validation

The completed solution was validated to confirm that every component of the CI/CD pipeline functioned as expected.

The following implementation objectives were successfully achieved:

- Dockerised the complete three-tier voting application.
- Deployed Redis and PostgreSQL as shared infrastructure services.
- Implemented independent Docker Compose configurations for the Vote, Worker, and Result services.
- Provisioned Jenkins Controller and Jenkins Inbound Build Agent using Docker.
- Created three independent declarative Jenkins pipelines.
- Integrated GitHub using secure Personal Access Token authentication.
- Configured Docker Hub as the central container registry.
- Implemented Git commit SHA image versioning.
- Automated deployments using service-specific deployment scripts.
- Implemented automatic rollback for failed deployments.
- Configured GitHub Webhooks for automatic pipeline execution.
- Integrated Slack notifications for real-time build monitoring.
- Successfully validated the complete end-to-end CI/CD workflow.

The successful execution of all three service pipelines demonstrates that the complete deployment process—from source code commit to production deployment—operates automatically without manual intervention.

![Successful Pipeline Execution](screenshots/34-result-stageviewbuild-success.png)

## 18. Conclusion

This project demonstrates the successful implementation of a production-oriented CI/CD solution for a microservices-based voting application using Docker, Docker Compose, Jenkins, GitHub, Docker Hub, and Slack.

By separating the application into independently deployable services, introducing dedicated Jenkins pipelines, implementing automated deployment scripts with rollback support, and integrating GitHub Webhooks and Slack notifications, the deployment workflow has been transformed from a manual process into a reliable, repeatable, and fully automated CI/CD pipeline.

The modular architecture adopted throughout this implementation improves scalability, simplifies maintenance, minimises service disruption during deployments, and provides a solid foundation for future enhancements such as Kubernetes-based orchestration, Infrastructure as Code, automated testing, and advanced deployment strategies.

For readers interested in reproducing the complete implementation, a detailed step-by-step guide is available in the project documentation:

- **[SETUP.md](docs/SETUP.md)** – Complete implementation guide containing every configuration step, command, and verification screenshot used throughout the project.
