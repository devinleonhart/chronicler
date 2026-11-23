---
paths:
  - "app/views/**"
  - "app/javascript/**"
  - "app/assets/**"
  - "app/helpers/**"
---

# Page Rules

- Pages render through `shared/_page`. Lists sit in the `results` Turbo frame, with their filters in the URL.
- Forms open in the layout's dialog, through the `dialog` frame and `DialogForms`. Saving refreshes the page under it.
- Invalid forms return 422 and show errors with `field_errors`. Dates are text fields, so that a bad one is kept.
- Deletions use `delete_button`, which confirms in the layout's dialog.
- Styles are the `bb-` components of `app/assets/tailwind/application.css`, the theme of Blackbook.
- The content security policy allows no inline scripts or styles.
- `vendor/javascript/vis-timeline.js` renders HTML: escape what it is given.
