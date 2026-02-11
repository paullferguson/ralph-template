import { Hono } from "hono";

const app = new Hono().get("/api/health", (c) => {
  return c.json({ status: "ok" });
});

export default app;
