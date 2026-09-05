import client from "prom-client";

client.collectDefaultMetrics();

const httpRequestsTotal = new client.Counter({
  name: "todo_http_requests_total",
  help: "Nombre total de requêtes HTTP reçues par l'API",
  labelNames: ["method", "status_code"],
});

export function metricsMiddleware(req, res, next) {
  res.on("finish", () => {
    httpRequestsTotal.inc({
      method: req.method,
      status_code: res.statusCode,
    });
  });
  next();
}

export async function metricsHandler(_req, res) {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
}