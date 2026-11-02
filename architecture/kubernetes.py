"""Inside one EKS cluster: what runs where, and how it talks to AWS.

Everything here is deployed by Argo CD from k8s/ (see gitops.mmd for the
order). Platform components run on the tainted system node group; the web
app runs on nodes Karpenter launches. Rendered by render.sh into
kubernetes.png.
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2AutoScaling, EC2Instances
from diagrams.aws.management import SystemsManagerParameterStore
from diagrams.aws.network import ALB
from diagrams.aws.storage import S3
from diagrams.k8s.clusterconfig import HPA
from diagrams.k8s.compute import DS, Deploy, Pod, STS
from diagrams.k8s.ecosystem import ExternalDns
from diagrams.k8s.network import Ing, Netpol, SVC
from diagrams.k8s.podconfig import Secret
from diagrams.onprem.client import User, Users
from diagrams.onprem.gitops import Argocd
from diagrams.onprem.logging import Loki
from diagrams.onprem.monitoring import Grafana
from diagrams.onprem.vcs import Github
from diagrams.saas.cdn import Cloudflare

GRAPH = {
    "fontsize": "22",
    "labelloc": "t",
    "pad": "0.4",
    "nodesep": "0.45",
    "ranksep": "0.9",
    "splines": "spline",
}
CLUSTER = {"fontsize": "14", "margin": "14"}
SYSTEM = {**CLUSTER, "bgcolor": "#eef3fb"}
APPS = {**CLUSTER, "bgcolor": "#eefbf0"}
PRIVILEGED = {**CLUSTER, "bgcolor": "#fdf0ef"}

with Diagram(
    "Inside one EKS cluster",
    filename="kubernetes",
    outformat="png",
    show=False,
    direction="TB",
    graph_attr=GRAPH,
):
    users = Users("Users")
    admin = User("Admin")
    repo = Github("Git: main\nk8s/argocd/envs/<env>")

    alb = ALB("ALB\nHTTPS, pod IP targets")
    cloudflare = Cloudflare("Cloudflare DNS")
    params = SystemsManagerParameterStore("Parameter Store\n/messagespring/<env>/*")
    loki_s3 = S3("S3 Loki chunks\n+ ruler")
    ec2 = EC2Instances("EC2 instances\n(Spot in dev)")

    with Cluster("EKS cluster: one per environment", graph_attr=CLUSTER):
        with Cluster(
            "system node group: nodeSelector role=system, toleration CriticalAddonsOnly",
            graph_attr=SYSTEM,
        ):
            with Cluster("argocd", graph_attr=CLUSTER):
                argocd = Argocd("Argo CD\nroot app-of-apps\nmanages itself")

            with Cluster("kube-system", graph_attr=CLUSTER):
                karpenter = EC2AutoScaling("Karpenter\nNodePool 'apps'")
                lbc = Deploy("AWS Load Balancer\nController")
                metrics = Deploy("metrics-server")

            with Cluster("external-secrets", graph_attr=CLUSTER):
                eso = Deploy("External Secrets\nClusterSecretStore\nparameter-store")

            with Cluster("external-dns", graph_attr=CLUSTER):
                edns = ExternalDns("external-dns\n(Cloudflare provider)")
                cf_token = Secret("Secret\ncloudflare-api-token")

            with Cluster("logging (PSA restricted)", graph_attr=CLUSTER):
                loki = Loki("Loki (monolithic)\nWAL on gp3 PVC")
                grafana = Grafana("Grafana\nLoki data source")
                grafana_admin = Secret("Secret\ngrafana-admin")

        with Cluster(
            "Karpenter nodes: NodePool 'apps' (dev: Spot + toleration)", graph_attr=APPS
        ):
            with Cluster("web (PSA restricted, readiness-gate injection)", graph_attr=CLUSTER):
                ing = Ing("Ingress (alb)\nHTTPS, redirect")
                svc = SVC("Service")
                web = Deploy("Deployment web\nsurge 1, unavailable 0\nPDB, zone spread")
                pods = Pod("pods\nnon-root, read-only FS\n/api/health probes")
                hpa = HPA("HPA\ndev 1-2, prod 2-6")
                netpol = Netpol("NetworkPolicy\nin: ALB subnets\nout: DNS only")

        with Cluster("alloy (PSA privileged: reads /var/log)", graph_attr=PRIVILEGED):
            alloy = DS("Alloy DaemonSet\nevery node")

    # GitOps
    repo >> Edge(label="watches, syncs\n(waves)", color="darkorange", penwidth="2") >> argocd
    argocd >> Edge(label="platform\nwaves -10 to -1", color="darkorange", style="dashed") >> karpenter
    argocd >> Edge(label="web, wave 10", color="darkorange", style="dashed") >> web

    # Traffic
    users >> Edge(label="HTTPS", color="darkgreen", penwidth="2") >> alb
    alb >> Edge(label="pod IPs", color="darkgreen", penwidth="2") >> pods
    ing - Edge(style="dotted") - svc
    web >> pods
    hpa >> Edge(style="dotted") >> web
    metrics >> Edge(label="CPU", style="dotted") >> hpa
    netpol - Edge(style="dotted") - pods
    lbc >> Edge(label="reconciles Ingress\ninto the ALB", style="dashed") >> alb
    edns >> Edge(label="record for the\nIngress host", style="dashed") >> cloudflare

    # Nodes
    karpenter >> Edge(label="launches,\nconsolidates", style="dashed") >> ec2

    # Secrets
    eso >> Edge(label="reads (Pod Identity)", style="dashed") >> params
    eso >> Edge(label="creates") >> cf_token
    eso >> Edge(label="creates") >> grafana_admin
    cf_token >> Edge(style="dotted") >> edns
    grafana_admin >> Edge(style="dotted") >> grafana

    # Logs
    alloy >> Edge(label="pod logs", color="purple") >> loki
    loki >> Edge(label="Pod Identity", color="purple") >> loki_s3
    grafana >> Edge(label="queries", style="dotted") >> loki
    admin >> Edge(label="port-forward", style="dotted") >> grafana
