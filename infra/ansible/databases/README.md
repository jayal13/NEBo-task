# Ansible Playbook: Provisioning and Configuring Databases

This Ansible playbook automates the installation and configuration of *MongoDB, **Redis, and **MySQL* on separate hosts. It also handles system package updates, secure authentication, and remote accessibility settings. The playbook reads sensitive credentials (e.g., passwords) from an encrypted secrets.yml file, demonstrating the integration of secret management with automated configuration.

---

## Overview of Plays

### 1. *Base Dependencies Installation*
- *Play Name:* "Provisión y configuración de bases de datos"
- *Hosts:* all
- *Purpose:*  
  Installs general dependencies such as curl, gnupg, and other required packages on all targeted hosts.  

### 2. *MongoDB 7.0 on Ubuntu 22.04*
- *Play Name:* "Instalar MongoDB 7.0 en Ubuntu 22.04"
- *Hosts:* mongodb
- *Tasks Include:*  
  - Importing MongoDB’s public GPG key and setting up the repository for MongoDB 8.0 (the play references “server-8.0” in the code).  
  - Installing and enabling MongoDB service.  
  - Configuring *bindIpAll* and *authorization* in mongod.conf for remote connections and authentication.  
  - Creating an *admin user* and a standard database user for the nebo-task database.  
  - Storing admin creation status in a marker file to avoid repeated creation.

### 3. *Redis*
- *Play Name:* "Configurar Redis"
- *Hosts:* redis
- *Tasks Include:*  
  - Installing Redis.  
  - Setting a password (from secrets.yml).  
  - Adjusting redis.conf to allow external connections (bind all IPs).  
  - Creating a custom ACL user (nebo) with necessary permissions.  
  - Restarting the Redis service.

### 4. *MySQL*
- *Play Name:* "Configuración de MySQL"
- *Hosts:* mysql
- *Tasks Include:*  
  - Installing MySQL (if absent).  
  - Allowing remote connections by modifying mysqld.cnf.  
  - Changing the root authentication method to mysql_native_password (executed once, tracked by a marker file).  
  - Creating /root/.my.cnf with root credentials for convenience.  
  - Creating the nebo-task database and a user nebo with full privileges on that database.

---

## Relevant Tasks Addressed

From the provided task list, this Ansible playbook addresses the following:

- *(2) Use secret management tool while using automated configuration*  
  - Credentials (such as mongo_admin_password, mysql_password) are stored in secrets.yml, presumably encrypted with Ansible Vault.

- *(10) CLOUD: Provision a NoSQL instance*  
  - MongoDB is a NoSQL database, installed and configured by this playbook.

- *(11) CLOUD: Provision of an in-memory service*  
  - Redis is an in-memory database/cache, installed and configured here.

- *(12) CLOUD: Provision of Relational DB*  
  - MySQL is a relational database, provisioned in this playbook.