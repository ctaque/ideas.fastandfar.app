// Autosaves the post title/content form to localStorage as the visitor types, so an
// accidental reload (or crash) doesn't lose an in-progress post. Restored on load and
// cleared once the post is actually saved, so a later "new post" visit starts blank.

function draftKey(form) {
  return `post-draft:${form.dataset.draftId}`;
}

function trixInputFor(trixElement) {
  const inputId = trixElement.getAttribute("input");
  return inputId ? document.getElementById(inputId) : null;
}

function fieldsFor(form) {
  return {
    titleField: form.querySelector('input[name="post[title]"]'),
    trixElement: form.querySelector("trix-editor"),
  };
}

function restoreDraft(form) {
  const raw = localStorage.getItem(draftKey(form));
  if (!raw) return;

  let draft;
  try {
    draft = JSON.parse(raw);
  } catch (e) {
    return;
  }

  const { titleField, trixElement } = fieldsFor(form);
  if (titleField && typeof draft.title === "string") titleField.value = draft.title;
  if (trixElement?.editor && typeof draft.content === "string") {
    trixElement.editor.loadHTML(draft.content);
  }
}

function saveDraft(form) {
  const { titleField, trixElement } = fieldsFor(form);
  const contentInput = trixElement ? trixInputFor(trixElement) : null;

  localStorage.setItem(
    draftKey(form),
    JSON.stringify({
      title: titleField ? titleField.value : "",
      content: contentInput ? contentInput.value : "",
    })
  );
}

function setupPostDraft(form) {
  if (form.dataset.draftBound) return;
  form.dataset.draftBound = "true";

  restoreDraft(form);

  const { titleField, trixElement } = fieldsFor(form);
  titleField?.addEventListener("input", () => saveDraft(form));
  trixElement?.addEventListener("trix-change", () => saveDraft(form));
}

document.addEventListener("turbo:load", () => {
  document.querySelectorAll("form[data-draft-id]").forEach(setupPostDraft);
});

document.addEventListener("turbo:submit-end", (event) => {
  const form = event.target;
  if (form.matches?.("form[data-draft-id]") && event.detail.success) {
    localStorage.removeItem(draftKey(form));
  }
});
