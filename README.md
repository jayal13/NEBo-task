![CI](https://github.com/jayal13/NEBo-task/actions/workflows/release.yml/badge.svg)

### 1. .github/workflows/release.yml
Contains a *GitHub Actions* workflow that automates:
- *Semantic Release* for code versioning in GitHub.
- *Docker image versioning* and publishing to Docker Hub.
- *Slack notifications* for job status.

> *Location:* NEBO-TASK/.github/workflows/release.yml

#### Workflow Details

1. *Trigger*  
   - Runs when pushing to the master branch.

2. *Permissions*  
   - Grants write permission to contents, issues, and pull requests.

3. *Jobs*
   - *release-code*  
     - Checks out the repository and installs Node.js dependencies.  
     - Executes *Semantic Release* (npm run release) to automatically bump versions, update changelogs, and create GitHub releases based on commit messages.  
     - Sends a Slack notification with the job status and branch information.
   - *release-docker*  
     - Authenticates with Docker Hub using repository secrets.  
     - Runs the docker-version.sh script, which builds and tags Docker images, then pushes them to Docker Hub.  
     - Sends a Slack notification on completion with the job status and branch info.

### 2. go-rest-api-nebo
A *fork* of an existing Go REST API application. This is the main microservice or backend component that the Nebo project uses.

### 3. infra/ansible
Contains *Ansible* playbooks for provisioning and configuring servers (e.g., installing and configuring databases, setting up system packages, etc.).

### 4. infra/terraform
Houses *Terraform* code for AWS infrastructure (VPCs, subnets, EC2 instances, databases, ECS services, etc.). Each module or configuration handles specific aspects like networking, compute resources, databases, or private networking/peering.

### 5. Other Key Files

- *.releaserc.js*  
  Configuration for *Semantic Release*, defining plugins, release rules, and additional behaviors for the release process.
  
- *CHANGELOG.md*  
  Maintained by *Semantic Release* to track version history and notable changes automatically.

- *docker-version.sh*  
  A script that builds, tags, and publishes Docker images, used in the release-docker job.

---

## Tasks Addressed

-  *(1) Maintenance and support automated configuration of infrastructure environments*  
    Storing infrastructure code in infra/terraform and configuration playbooks in infra/ansible ensures repeatable, maintainable environments.

- *(2) Use secret management tool while using automated configuration*  
- *(20) Follow security practices when working with artifacts*  
- *(21) Secure Continuous Integrations and Delivery Pipelines
    GitHub Actions uses *repository secrets* (e.g., GITHUB_TOKEN, DOCKER_USERNAME, DOCKER_PASSWORD, SLACK_WEBHOOK) to manage credentials securely.  
    Ansible Vault or AWS Secrets Manager usage could also be integrated in the infra portion (not shown but recommended).

- *(3) Store configuration files in the version control system*  
    All Terraform modules, Ansible playbooks, and Docker scripts are committed to GitHub.

- *(4) Configure versioning of artifacts during the CI flow*  
    *Semantic Release* automatically updates version numbers, creates tags, and maintains the changelog in CHANGELOG.md.

- *(5) Integrate feedback loop into Continuous Integration and Deployment (Delivery) flows*  
    Slack notifications are sent upon job completion, providing immediate feedback on build/deployment status.

---

## Usage

1. *Clone or Fork* this repository (NEBO-TASK) locally.
2. *Configure* GitHub Actions secrets:
   - GITHUB_TOKEN: provided automatically by GitHub Actions (ensure it has the necessary permissions).
   - DOCKER_USERNAME / DOCKER_PASSWORD: Docker Hub credentials.
   - SLACK_WEBHOOK: Slack incoming webhook URL for notifications.
3. *Push* to the master branch to trigger:
   - Automated Semantic Release for code versioning.
   - Docker image builds and pushes.
   - Slack alerts on job completion.
4. *Manage Infrastructure* by customizing and running:
   - *Terraform* code in infra/terraform.
   - *Ansible* playbooks in infra/ansible.