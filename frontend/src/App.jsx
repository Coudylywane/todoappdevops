import { useEffect, useState } from "react";
import { fetchTodos, createTodo, updateTodo, deleteTodo } from "./api.js";

export default function App() {
  const [todos, setTodos] = useState([]);
  const [title, setTitle] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState("all");

  useEffect(() => {
    loadTodos();
  }, []);

  async function loadTodos() {
    try {
      setLoading(true);
      setTodos(await fetchTodos());
    } catch (err) {
      setError("Impossible de charger les todos");
    } finally {
      setLoading(false);
    }
  }

  async function handleAdd(e) {
    e.preventDefault();
    if (!title.trim()) return;
    try {
      await createTodo({ title });
      setTitle("");
      await loadTodos();
    } catch (err) {
      setError("Impossible de créer le todo");
    }
  }

  async function handleToggle(todo) {
    try {
      await updateTodo(todo.id, { completed: !todo.completed });
      await loadTodos();
    } catch (err) {
      setError("Impossible de mettre à jour le todo");
    }
  }

  async function handleDelete(id) {
    try {
      await deleteTodo(id);
      await loadTodos();
    } catch (err) {
      setError("Impossible de supprimer le todo");
    }
  }

  const visibleTodos = todos.filter((todo) => {
    if (filter === "active") return !todo.completed;
    if (filter === "completed") return todo.completed;
    return true;
  });

  const remaining = todos.filter((t) => !t.completed).length;

  return (
    <div className="container">
      <h1>📝 Liste de tâches</h1>

      <form onSubmit={handleAdd} className="add-form">
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Ajouter une tâche..."
        />
        <button type="submit">Ajouter</button>
      </form>

      {error && <p className="error">{error}</p>}

      <div className="filters">
        <button className={filter === "all" ? "active" : ""} onClick={() => setFilter("all")}>
          Toutes ({todos.length})
        </button>
        <button className={filter === "active" ? "active" : ""} onClick={() => setFilter("active")}>
          À faire ({todos.filter((t) => !t.completed).length})
        </button>
        <button className={filter === "completed" ? "active" : ""} onClick={() => setFilter("completed")}>
          Terminées ({todos.length - remaining})
        </button>
      </div>

      {loading ? (
        <p>Chargement...</p>
      ) : visibleTodos.length === 0 ? (
        <p className="empty">Aucune tâche ici</p>
      ) : (
        <ul className="todo-list">
          {visibleTodos.map((todo) => (
            <li key={todo.id} className={todo.completed ? "completed" : ""}>
              <label>
                <input
                  type="checkbox"
                  checked={todo.completed}
                  onChange={() => handleToggle(todo)}
                />
                <span>{todo.title}</span>
              </label>
              <button className="delete" onClick={() => handleDelete(todo.id)}>
                ✕
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}