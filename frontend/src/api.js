const BASE_URL = "/api";

async function request(path, options = {}) {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  if (res.status === 204) return null;
  const data = await res.json().catch(() => null);
  if (!res.ok) throw new Error(data?.error || "Erreur API");
  return data;
}

export const fetchTodos = () => request("/todos");
export const createTodo = (body) =>
  request("/todos", { method: "POST", body: JSON.stringify(body) });
export const updateTodo = (id, body) =>
  request(`/todos/${id}`, { method: "PUT", body: JSON.stringify(body) });
export const deleteTodo = (id) => request(`/todos/${id}`, { method: "DELETE" });