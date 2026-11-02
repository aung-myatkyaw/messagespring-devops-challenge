// Rendered per request, so the page shows the version of the image that is
// actually serving it: APP_VERSION is set in the runtime image (the commit
// SHA), not at build time. Makes each rollout and rollback visible.
export const dynamic = "force-dynamic";

export default function Home() {
  const version = process.env.APP_VERSION ?? "dev";

  return (
    <main
      style={{
        display: "grid",
        placeItems: "center",
        alignContent: "center",
        gap: "1rem",
        minHeight: "100vh",
      }}
    >
      <h1 style={{ fontSize: "clamp(3rem, 12vw, 9rem)", margin: 0 }}>Hello World</h1>
      <p style={{ margin: 0, fontFamily: "monospace", opacity: 0.6 }}>version {version}</p>
    </main>
  );
}
