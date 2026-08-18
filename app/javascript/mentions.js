// "@nickname" autocomplete for Trix editors (post content, comment body). Queries
// fastandfarapp's nickname search as the visitor types past an "@", and lets them pick a
// match with the mouse, arrow keys + Enter/Tab, or dismiss with Escape/an outside click.
// The API itself decides who gets emailed once the post/comment is actually saved
// (see MentionNotifier server-side) — this file only ever inserts plain "@nickname" text.

// Requires a preceding start-of-line/whitespace so typing an email address doesn't
// trigger the menu (matches the server-side extraction in MentionNotifier).
const MENTION_PATTERN = /(?:^|\s)@([a-zA-Z0-9_-]{1,30})$/;
const DEBOUNCE_MS = 150;

function apiBase() {
  return document.querySelector('meta[name="fastandfarapp-origin"]')?.content;
}

function closeMenu(state) {
  state.menu?.remove();
  state.menu = null;
  state.items = [];
  state.activeIndex = -1;
  state.mentionStart = null;
}

function renderMenu(state, trixElement, nicknames, onPick) {
  state.menu?.remove();

  const menu = document.createElement("div");
  menu.className = "mention-menu";
  nicknames.forEach((nickname, index) => {
    const item = document.createElement("button");
    item.type = "button";
    item.className = "mention-menu-item";
    item.textContent = `@${nickname}`;
    item.dataset.index = String(index);
    item.addEventListener("mousedown", (event) => {
      // mousedown (not click) so it fires before the editor's blur/selection change.
      event.preventDefault();
      onPick(nickname);
    });
    menu.appendChild(item);
  });

  const selection = window.getSelection();
  const rect = selection && selection.rangeCount > 0
    ? selection.getRangeAt(0).getBoundingClientRect()
    : trixElement.getBoundingClientRect();

  menu.style.position = "absolute";
  menu.style.left = `${window.scrollX + rect.left}px`;
  menu.style.top = `${window.scrollY + rect.bottom + 4}px`;

  document.body.appendChild(menu);

  state.menu = menu;
  state.items = Array.from(menu.querySelectorAll(".mention-menu-item"));
  state.activeIndex = 0;
  highlightActive(state);
}

function highlightActive(state) {
  state.items.forEach((item, index) => {
    item.classList.toggle("active", index === state.activeIndex);
  });
}

function setupMentions(trixElement) {
  const editor = trixElement.editor;
  if (!editor || !apiBase()) return;

  const state = { menu: null, items: [], activeIndex: -1, mentionStart: null };
  let debounceTimer = null;
  let requestToken = 0;

  const pick = (nickname) => {
    const range = editor.getSelectedRange();
    // insertString replaces the current selection, so selecting the "@partial" range
    // and inserting over it does the replacement in one step.
    editor.setSelectedRange([state.mentionStart, range[1]]);
    editor.insertString(`@${nickname} `);
    closeMenu(state);
  };

  trixElement.addEventListener("trix-change", () => {
    const range = editor.getSelectedRange();
    if (range[0] !== range[1]) {
      closeMenu(state);
      return;
    }

    const caret = range[0];
    const textBeforeCaret = editor.getDocument().toString().slice(0, caret);
    const match = textBeforeCaret.match(MENTION_PATTERN);

    if (!match) {
      closeMenu(state);
      return;
    }

    const query = match[1];
    state.mentionStart = caret - query.length - 1; // -1 for the "@" itself

    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      const token = ++requestToken;
      fetch(`${apiBase()}/api/store/mentions/search?q=${encodeURIComponent(query)}`, {
        credentials: "include",
      })
        .then((response) => (response.ok ? response.json() : { nicknames: [] }))
        .then(({ nicknames }) => {
          if (token !== requestToken) return; // a newer keystroke superseded this request
          if (!nicknames || nicknames.length === 0) {
            closeMenu(state);
            return;
          }
          renderMenu(state, trixElement, nicknames, pick);
        })
        .catch(() => closeMenu(state));
    }, DEBOUNCE_MS);
  });

  // Capture phase so this runs before Trix's own keydown handling (which would
  // otherwise move the cursor / insert a newline / blur the editor first).
  trixElement.addEventListener(
    "keydown",
    (event) => {
      if (!state.menu) return;

      switch (event.key) {
        case "ArrowDown":
          event.preventDefault();
          state.activeIndex = (state.activeIndex + 1) % state.items.length;
          highlightActive(state);
          break;
        case "ArrowUp":
          event.preventDefault();
          state.activeIndex = (state.activeIndex - 1 + state.items.length) % state.items.length;
          highlightActive(state);
          break;
        case "Enter":
        case "Tab":
          event.preventDefault();
          state.items[state.activeIndex]?.dispatchEvent(new MouseEvent("mousedown"));
          break;
        case "Escape":
          event.preventDefault();
          closeMenu(state);
          break;
      }
    },
    true
  );

  trixElement.addEventListener("trix-blur", () => closeMenu(state));
}

document.addEventListener("trix-initialize", (event) => setupMentions(event.target));
