// BFF health endpoint used by the container HEALTHCHECK, the Kubernetes
// readiness/liveness/startup probes and the ALB target group health check.
//
// It is deliberately shallow: it reports that this process can serve requests
// and does not call downstream dependencies. A dependency outage must not make
// the liveness probe restart every pod.

// Evaluate on every request; never prerender or cache a health response.
export const dynamic = "force-dynamic";

export function GET() {
  return Response.json(
    {
      status: "ok",
      version: process.env.APP_VERSION ?? "dev",
      uptimeSeconds: Math.round(process.uptime()),
    },
    { headers: { "Cache-Control": "no-store" } },
  );
}
