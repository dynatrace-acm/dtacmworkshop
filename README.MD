# Dynatrace ACM Workshop
Unbreakable DevOps Pipeline Tutorial with Self-Healing using Kubernetes, Jenkins, JMeter, Ansible Tower, and Dynatrace

The goal of this tutorial is having a full end-to-end DevOps Pipeline (Staging, Approval, Production) that is fully monitored with Dynatrace. With Dynatrace injected into the pipeline we implement the following use cases:

1. **Self-service Monitoring** Have your environment automatically discovered and monitored from end-to-end within a few minutes.
2. **Shift-Left**: Automated the delivery pipeline, enable automated testing every gate of your pipeline and and detect performance regressions earlier in the lifecycle. Enable automated build promotion at your gates, stop bad build from progressing.
3. **Shift-Right** Automate deployment and get new builds faster to production. Provide more visibility and context on delivery pipeline and production work load. Increase service reliability for end users.
4. **Self-Healing**: No testing can guarantee 100% smooth sailing in production. And response to problems must be near instantaneous. So, we must think about how to automate remediation when something goes wrong.

## Pre-Requisites
1. You will need either a GCP or Azure account, and access to the cloud providers cloud shell.
1. You will need a Dynatrace Account. Get your [Free SaaS Trial here!](https://www.dynatrace.com/trial/)
1. You will need an Ansible Tower license. [Get a Free license here.](https://www.ansible.com/workshop-license)
1. You will need to copy the contents of this GitHub repo to your cloud shell instance.

## What are we going to accomplish
The workshop create a 3 nodes Kubernetes cluster on either GCP or AKS which will host a Dev and Production instance of our sample application, SockShop.  Using Jenkins we will build a pipeline to deploy new versions of our application.  In order to ensure we don't deploy builds that will impact our customers, we will integration Dynatrace Quality Gates to keep bad builds out of Production.
We will then create a "self-healing" pipeline using Dynatrace and Ansible Tower.  If a bad build does make its way into production or a feature flag doesn't work as intended, Dynatrace will automatically detect this problem and trigger a remediation job via Ansible Tower.

More detailed steps can be found in the [PowerPoint Deck with the repo](DynatraceACM.pptx).

![](./images/acmsetup.JPG)
