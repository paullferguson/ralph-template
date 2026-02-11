import { testClient } from "hono/testing";
import { describe, it, expect } from "vitest";
import app from "./app.js";

describe("GET /api/health", () => {
  const client = testClient(app);

  it("should return status ok", async () => {
    const res = await client.api.health.$get();

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: "ok" });
  });
});
