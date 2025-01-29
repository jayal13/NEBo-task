# Terraform Module: Static Website on Amazon S3 with CloudFront, Versioning, Lifecycle Policies, and AWS Backup

This Terraform module provisions a fully managed static website infrastructure on AWS using the following components:

- *S3 Bucket* (hosting static web content, with public read access)
- *S3 Website Configuration* (index document setup)
- *S3 Bucket Policy* for public read access
- *S3 Object* (example index.html file)
- *CloudFront Distribution* (CDN for fast content delivery)
- *S3 Bucket Versioning* (enabling version control of objects)
- *S3 Lifecycle Rules* (to transition objects to Glacier and eventually expire them)
- *AWS Backup Vault and Backup Plan* (to automate backups)
- *IAM Role* for AWS Backup (with policy attachments)

## Overview of Resources

1. *S3 Bucket (aws_s3_bucket.web_bucket)*  
   - Stores static website files.

2. *Public Access Block (aws_s3_bucket_public_access_block.example)*  
   - Configured to allow public read access for static web hosting.

3. *S3 Website Configuration (aws_s3_bucket_website_configuration.web_config)*  
   - Specifies the index document (index.html).

4. *Bucket Policy (aws_s3_bucket_policy.public_access)*  
   - Allows the public to read objects (GET) in the bucket.

5. *S3 Object (aws_s3_object.index)*  
   - Demonstrates uploading an index.html with "Hello World" content.

6. *CloudFront Distribution (aws_cloudfront_distribution.cdn)*  
   - Fronts the S3 bucket with a CDN for faster and more secure content delivery.
   - Uses viewer_protocol_policy = "redirect-to-https" to enforce HTTPS.

7. *Bucket Versioning (aws_s3_bucket_versioning.versioning)*  
   - Enables versioning to retain historical copies of objects.

8. *S3 Lifecycle Configuration (aws_s3_bucket_lifecycle_configuration.lifecycle)*  
   - Moves objects to *Glacier* storage class after 30 days.
   - Expires objects after 365 days.

9. *AWS Backup Vault (aws_backup_vault.backup_vault)*  
   - A designated vault to store backup data.

10. *AWS Backup Plan (aws_backup_plan.backup_plan)*  
    - Defines a rule to back up the S3 bucket daily at 12:00 UTC.
    - Retains backups for 90 days.

11. *Backup Selection (aws_backup_selection.backup_selection)*  
    - Associates the S3 bucket with the backup plan.
    - Uses an IAM role for AWS Backup.

12. *IAM Role and Policy Attachment (aws_iam_role.backup_role, aws_iam_policy_attachment.backup_policy_attach)*  
    - Grants AWS Backup service permission to manage the specified S3 bucket.

## Tasks Addressed

From the provided task list, this module addresses the following:

- *(13) CLOUD: Archive and back up storage services*  
  - Through *S3 Lifecycle rules* (archiving objects to Glacier) and *AWS Backup* (automated backups).
- *(18) CLOUD: Provision fast delivery of Internet content*  
  - By creating a *CloudFront distribution* to serve static content globally.
- *(22) Work with data according to the security best practices
  - By using bucket encryption.