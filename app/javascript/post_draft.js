// Autosaves the post title/content form to localStorage as the visitor types, so an
// accidental reload (or crash) doesn't lose an in-progress post. Restored on load and
// cleared on submit, so a later "new post" visit starts blank.

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

  if (trixElement && typeof draft.content === "string") {
    const loadContent = () => trixElement.editor.loadHTML(draft.content);
    // trix-editor upgrades itself (and sets .editor) asynchronously, after the custom
    // element registers - which can still be pending when this runs immediately on
    // script load. Trix fires "trix-initialize" once .editor is actually ready.
    if (trixElement.editor) {
      loadContent();
    } else {
      trixElement.addEventListener("trix-initialize", loadContent, { once: true });
    }
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

  // This app doesn't load Turbo's JS runtime (only the turbo-rails gem, for
  // data-turbo-track), so every navigation - including the form's own submit -
  // is a plain full-page load rather than a Turbo visit. A regular "submit"
  // fires synchronously before that navigation, giving us a chance to drop the
  // draft; we can't tell here whether the server will accept it, but on a
  // validation failure Rails re-renders the same fields with the submitted
  // values anyway, so nothing is lost.
  form.addEventListener("submit", () => localStorage.removeItem(draftKey(form)));
}

function setupAllPostDrafts() {
  document.querySelectorAll("form[data-draft-id]").forEach(setupPostDraft);
}

setupAllPostDrafts();
document.addEventListener("turbo:load", setupAllPostDrafts);
