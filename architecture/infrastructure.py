"""AWS infrastructure for one environment, plus the account-wide resources.

dev and prod are the same Terraform code (infra/envs/<env>) with different
terraform.tfvars, so one environment is drawn; the differences are in the
labels. Rendered by render.sh into infrastructure.png.
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import ECR, EC2AutoScaling, EKS, EC2Instances
from diagrams.aws.integration import SQS
from diagrams.aws.management import Cloudwatch, SystemsManagerParameterStore
from diagrams.aws.network import ALB, Endpoint, InternetGateway, NATGateway
from diagrams.aws.security import IAMRole, KMS, CertificateManager
from diagrams.aws.storage import S3
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.client import Users
from diagrams.saas.cdn import Cloudflare

GRAPH = {
    "fontsize": "22",
    "labelloc": "t",
    "pad": "0.4",
    "nodesep": "0.5",
    "ranksep": "0.9",
    "splines": "spline",
}
CLUSTER = {"fontsize": "14", "margin": "16"}

with Diagram(
    "MessageSpring on AWS (ap-southeast-7): one environment",
    filename="infrastructure",
    outformat="png",
    show=False,
    direction="LR",
    graph_attr=GRAPH,
):
    users = Users("Users")
    cloudflare = Cloudflare("Cloudflare DNS\napp record (external-dns)\nACM validation CNAMEs")
    github = GithubActions("GitHub Actions\n(OIDC, no stored keys)")

    with Cluster("AWS account", graph_attr=CLUSTER):
        with Cluster("Account-wide: infra/bootstrap + infra/envs/shared", graph_attr=CLUSTER):
            ci_roles = IAMRole(
                "GitHub OIDC roles\necr-push / ecr-scan (main)\ninfra-plan (PRs)\ninfra-apply-<env> (Environment)"
            )
            ecr = ECR("ECR messagespring/web\nimmutable tags, scan on push\nKMS")
            state = S3("Terraform state\nversioned, KMS\nS3 lock file")

        with Cluster(
            "Environment: infra/envs/dev (prod: same code, own tfvars)", graph_attr=CLUSTER
        ):
            acm = CertificateManager("ACM certificate\n(DNS-validated)")

            with Cluster(
                "VPC 10.10.0.0/16 (prod 10.20.0.0/16), 3 AZs, flow logs", graph_attr=CLUSTER
            ):
                igw = InternetGateway("Internet\ngateway")

                with Cluster("public subnets /24", graph_attr=CLUSTER):
                    alb = ALB("ALB (internet-facing)\nHTTPS 443, HTTP to HTTPS\ncreated by the LB controller")
                    nat = NATGateway("NAT gateway\ndev: 1, prod: 1 per AZ")

                with Cluster("private subnets /20: nodes and pods", graph_attr=CLUSTER):
                    system = EC2Instances(
                        "system node group\nOn-Demand, tainted\nCriticalAddonsOnly\ndev 1x t3.large\nprod 2x m7i.large"
                    )
                    apps = EC2AutoScaling(
                        "Karpenter NodePool 'apps'\ndev: Spot (tainted)\nprod: On-Demand"
                    )

                with Cluster("intra subnets /24: no internet route", graph_attr=CLUSTER):
                    eks = EKS("EKS 1.36 control plane\nprivate + allow-listed public\nendpoint, secrets KMS-encrypted")

                s3_endpoint = Endpoint("S3 gateway\nendpoint")

            with Cluster("Regional services", graph_attr=CLUSTER):
                buckets = S3("S3: Loki chunks + ruler (KMS)\nALB access logs (SSE-S3)\nTLS only, no public access")
                params = SystemsManagerParameterStore(
                    "Parameter Store\n/messagespring/<env>/*\nSecureString, env KMS key"
                )
                queue = SQS("Spot interruption\nqueue (Karpenter)")
                logs = Cloudwatch("CloudWatch Logs\ncontrol plane (api, audit,\nauthenticator), flow logs")

            keys = KMS("KMS keys\nEKS secrets, logs,\nparameters")

    # Request path
    users >> Edge(label="DNS lookup", style="dashed") >> cloudflare
    users >> Edge(label="HTTPS", color="darkgreen", penwidth="2") >> alb
    alb >> Edge(label="pod IPs (target-type ip)", color="darkgreen", penwidth="2") >> apps
    acm >> Edge(label="certificate", style="dashed") >> alb

    # Cluster
    eks >> Edge(label="manages", style="dashed") >> system
    eks >> Edge(style="dashed") >> apps
    system >> Edge(label="Karpenter\nlaunches nodes", style="dotted", constraint="false") >> apps
    system >> Edge(label="Karpenter reads\ninterruptions", style="dotted", constraint="false") >> queue
    eks >> Edge(style="dotted", constraint="false") >> logs
    keys >> Edge(style="dotted") >> eks

    # Egress
    apps >> Edge(label="egress") >> nat >> igw
    system >> Edge(label="S3 via endpoint\n(Loki, image layers)") >> s3_endpoint >> buckets
    system >> Edge(label="ESO (Pod Identity)", style="dashed") >> params
    system >> Edge(label="external-dns\nCloudflare token", style="dashed", constraint="false") >> cloudflare

    # Images and CI
    apps << Edge(label="pull image", style="dashed") << ecr
    github >> Edge(label="assume role (OIDC)") >> ci_roles
    ci_roles >> Edge(label="push image") >> ecr
    ci_roles >> Edge(label="plan / apply", style="dashed") >> state
