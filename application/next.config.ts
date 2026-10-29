import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Emit a self-contained server (.next/standalone) with only the node_modules
  // it needs, so the runtime image doesn't ship the full dependency tree.
  output: "standalone",
  poweredByHeader: false,

  // The app serves no images through next/image, so the image optimiser and its
  // native dependency (sharp/libvips, ~38 MB with both libc variants) are dropped
  // from the standalone output: smaller image, fewer native libraries to patch.
  images: { unoptimized: true },
  outputFileTracingExcludes: {
    "*": ["node_modules/sharp/**", "node_modules/@img/**"],
  },

  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
        ],
      },
    ];
  },
};

export default nextConfig;
