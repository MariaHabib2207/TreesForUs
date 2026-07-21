// app/javascript/dashboard/user_search.js
// Debounced live search hitting /search/users, rendering avatar (if the
// searched user's avatar_visibility permits current_user to see it — see
// UserSearchController#avatar_url_for), name, family tree name, and email.

let debounceTimer = null;

function renderResults(container, results) {
  if (results.length === 0) {
    container.innerHTML = `<p class="text-sm text-gray-400 px-3 py-4 text-center">No users found.</p>`;
    container.classList.remove("hidden");
    return;
  }

  container.innerHTML = results
    .map((user) => {
      const avatarHtml = user.avatar_url
        ? `<img src="${user.avatar_url}" class="w-10 h-10 rounded-full object-cover shrink-0" />`
        : `<div class="w-10 h-10 rounded-full bg-[#1D4D3A]/10 text-[#1D4D3A] flex items-center justify-center text-sm font-semibold shrink-0">${user.initials}</div>`;

      return `
        <a href="${user.profile_path}" class="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-gray-50 transition-colors">
          ${avatarHtml}
          <div class="min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">${user.name}</p>
            <p class="text-xs text-gray-500 truncate">${[user.family_name, user.email].filter(Boolean).join(" · ")}</p>
          </div>
        </a>
      `;
    })
    .join("");

  container.classList.remove("hidden");
}

async function performSearch(query, container) {
  try {
    const res = await fetch(`/search/users?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "application/json" },
    });
    if (!res.ok) return;
    const data = await res.json();
    renderResults(container, data.results);
  } catch (err) {
    console.error("User search error:", err);
  }
}

export function initUserSearch() {
  const input = document.getElementById("user-search-input");
  const resultsContainer = document.getElementById("user-search-results");
  if (!input || !resultsContainer) return;

  input.addEventListener("input", () => {
    clearTimeout(debounceTimer);
    const query = input.value.trim();

    if (query.length < 1) {
      resultsContainer.classList.add("hidden");
      resultsContainer.innerHTML = "";
      return;
    }

    debounceTimer = setTimeout(() => performSearch(query, resultsContainer), 300);
  });

  document.addEventListener("click", (e) => {
    if (!input.contains(e.target) && !resultsContainer.contains(e.target)) {
      resultsContainer.classList.add("hidden");
    }
  });
}

document.addEventListener("turbo:load", initUserSearch);
document.addEventListener("DOMContentLoaded", initUserSearch);