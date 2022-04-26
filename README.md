# Alerting AWS Security Hub Findings

Terraform code that creates a solution for sending emails with Security Hub Findings. It implements the following resources:

* **[EventBridge Event Rule]** --> Two Events Rule. One for monitoring Security Hub Findings and one for executing daily deletion of resolved findigns.
* **[Step Function]** --> Serverless workflow for analyzing all the findings registered in Security Hub.
* **[Lambda Function]** --> Four Lambda Function. Three of them are integrated into Step Functions and the other is for daily execution.
* **[DynamoDB Table]** --> Table that keeps records of all active findings.
* **[Cloudwatch Log Group]** --> Log Groups containing Lambda execution logs.
* **[IAM Role]** --> Six IAM Roles for handling Lambda, DynamoDB and Step Functions Permissions.
* **[SES Identity]** --> Verified identities for sending and receiving the findings emails.

[EventBridge Event Rule]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringPolicyExamples.html
[Step Function]: https://docs.aws.amazon.com/step-functions/latest/dg/welcome.html
[Lambda Function]: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
[DynamoDB Table]: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html
[Cloudwatch Log Group]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html
[IAM Role]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
[SES Identity]: https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html


## High Level Architecture

![HLA](https://github.com/lorenzocampo/alerting-securityhub-findings/blob/main/images/HLA_SecurityHub_Alerting.JPG)

## How It Works

1. An Event Rule monitors Security Hub Findings. These Findings are filtered by source service. Currently this solution supports findings originated Security Hub (CIS and Foundational benchmarks), GuardDuty and Inspector.
2. When the Event Rule detects an Event it triggers a Step Function State Machine Workflow.

3. If the Finding is new or if it has been active for more than 15 days, it sends an Email to Operations, extracting the most important attributes of the json event and formatting the email in HTML, to make it more human readable.

4. Additionally, a lambda is run on a daily basis checking, for each item in the dynamodb table, whether it is still active in the security hub or not. If it is no longer active, it removes the item from the table.

 
## Why is this solution necessary?

Security Hub alerts for each finding of the services you have integrated but the same finding can be logged several times before being resolved so if you send an email to the support team for each finding, they will find duplicate findings so, to avoid spam, I have set up a workflow with step functions to alert only about findings that are not repeated and are active.

## Step Function State Machine Workflow

![HLA](https://github.com/lorenzocampo/alerting-securityhub-findings/blob/main/images/StepFunction_Workflow.JPG)

1. The first Lambda Function checks if the finding item is in the DynamoDB table. If it is not there, it means it is a new finding so it adds the item to the table, sends the event to the next Lambda which will parse the event in HTML and send it to the operations teams via SES.
2. If the item exists it means that the finding is duplicated and it is still active in Security Hub so another Lambda Function is executed to check if the finding has been active for more than 15 days. If yes, it execute de parse HTML Lambda to notify the support team and if the finding has been active for less than 15 days, it does noting.

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