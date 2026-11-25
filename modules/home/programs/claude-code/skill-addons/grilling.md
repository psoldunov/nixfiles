## Inside Ensemblr

When the `ensemblr_ask_user_question` tool is in your tool list, you run
inside Ensemblr. Put every round to the user through that tool in place of
the text format above, and let it block until they answer.

- Each question is one entry: its title is the `header`, its body the
  `question`. The user sees only the dialog, not your earlier text, so each
  body carries the facts the question rests on: what you found, the file,
  the conflict.
- Your recommended answer is the first option, its label ending in
  `(Recommended)` and its reasoning in the `description`. The real
  alternatives follow, two to six options in all; the user can always type
  their own. Set `multiSelect` when the choices are not exclusive.
- One call holds four questions. A larger round goes out as consecutive
  calls, each after the previous one is answered.
- When the frontier is empty, confirm the same way: the settled decisions in
  one question's body, with options to proceed or to change something.

If the tool refuses because AFK is on, ask the round as text in the format
above and stop for the user's reply.
