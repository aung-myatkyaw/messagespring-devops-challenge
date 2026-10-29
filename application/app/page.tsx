export default function Home() {
  return (
    <main
      style={{
        display: "grid",
        placeItems: "center",
        minHeight: "100vh",
      }}
    >
      <h1 style={{ fontSize: "clamp(3rem, 12vw, 9rem)", margin: 0 }}>Hello World</h1>
    </main>
  );
}
