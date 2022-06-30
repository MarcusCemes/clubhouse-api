[
  import_deps: [:ecto, :phoenix],
  inputs: ["*.{heex,ex,exs,md}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{heex,ex,exs,md}"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  subdirectories: ["priv/*/migrations"]
]
