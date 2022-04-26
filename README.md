# Alerting AWS Security Hub Findings

Terraform code that creates a solution that sends an email when an Amazon GuardDuty Finding is registered. It implements the following resources:

* **[EventBridge Event Rule]** --> 2 Events Rule. One for monitoring Security Hub Findings and one for executing daily deletion of resolved findigns.
* **[Step Function]** --> Serverless workflow for analyzing all the findings registered in Security Hub.
* **[Lambda Function]** --> 4 Lambda Function. 3 of them are integrated into Step Functions and the other is for daily execution.
* **[DynamoDB Table]** --> Table that keeps records of all active findings.
* **[Cloudwatch Log Group]** --> Log Groups containing Lambda execution logs.
* **[IAM Role]** --> 6 IAM Roles for handling Lambda, DynamoDB and Step Functions Permissions.
* **[SES Identity]** --> Verified identities for sending and receiving the findings emails.

[EventBridge Event Rule]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringPolicyExamples.html
[Step Function]: https://docs.aws.amazon.com/step-functions/latest/dg/welcome.html
[Lambda Function]: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
[DynamoDB Table]: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html
[Cloudwatch Log Group]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html
[IAM Role]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
[SES Identity]: https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html

![HLA](https://github.com/tograh/testrepository/3DTest.png)

## How It Works

1. 


## Usage

1. Clone the repository

    ```
    $ git clone https://github.com/lorenzocampo/alerting-securityhub-findings.git
    ```

2. Initialize a working directory containing Terraform configuration files:

    ```
    $ terraform init
    ```

3. Create an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure

    ```
    $ terraform plan
    ```

4. Executes the actions proposed in a Terraform plan

    ```
    $ terraform apply
    ```