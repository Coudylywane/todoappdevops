import "dotenv/config";
import express from "express";
import cors from "cors";
import todosRouter from "./routes/todos.js";
import { initDb } from "./db/init.js";
import { metricsHandler, metricsMiddleware } from "./metrics.js";

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(metricsMiddleware);

app.get("/metrics", metricsHandler);

app.get("/", (_req, res) => {
  res.json({ message: "API Todo en fonctionnement" });
});

app.use("/api/todos", todosRouter);

app.use((_req, res) => {
  res.status(404).json({ error: "Route introuvable" });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: "Erreur serveur interne" });
});

initDb()
  .catch((err) => {
    console.error("Échec de l'initialisation de la base:", err);
    process.exit(1);
  })
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Backend démarré sur http://localhost:${PORT}`);
    });
  });