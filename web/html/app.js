// InferScale web page. The page and the API come from the same address,
// so the browser sends the login with every API call and no CORS setup is needed.
const $ = (id) => document.getElementById(id);

async function api(path, body) {
  const options = body
    ? { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }
    : {};
  const response = await fetch("/api" + path, options);
  if (!response.ok) throw new Error(`Error ${response.status}: ${response.statusText}`);
  return response.json();
}

// textContent, never innerHTML: the text of a review can never inject HTML into the page
function show(element, text, isError = false) {
  element.textContent = text;
  element.classList.toggle("error", isError);
}

function addItem(list, text, isError = false) {
  const item = document.createElement("li");
  show(item, text, isError);
  list.append(item);
}

$("analyze").addEventListener("click", async () => {
  try {
    const r = await api("/predict", { text: $("text").value });
    show($("result"), `${r.label} (score ${r.score.toFixed(3)})`);
  } catch (e) {
    show($("result"), e.message, true);
  }
});

$("filter").addEventListener("click", async () => {
  const list = $("kept");
  list.replaceChildren();
  const texts = $("texts").value.split("\n").map((t) => t.trim()).filter(Boolean);
  try {
    const kept = await api("/filter", { texts, label: $("label").value, min_score: Number($("min").value) });
    if (kept.length === 0) addItem(list, "No review matched.");
    for (const r of kept) addItem(list, `${r.text} (score ${r.score.toFixed(3)})`);
  } catch (e) {
    addItem(list, e.message, true);
  }
});

$("history").addEventListener("click", async () => {
  const table = $("rows");
  table.replaceChildren();
  try {
    const rows = await api("/history?limit=20");
    if (rows.length === 0) table.insertRow().insertCell().textContent = "No reviews yet.";
    for (const r of rows) {
      const row = table.insertRow();
      for (const value of [new Date(r.time).toLocaleString(), r.label, r.score.toFixed(3), r.text]) {
        row.insertCell().textContent = value;
      }
    }
  } catch (e) {
    show(table.insertRow().insertCell(), e.message, true);
  }
});
