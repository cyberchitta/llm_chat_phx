defmodule LlmChat.Contexts.Markdown do
  def to_html(markdown) do
    options = %Earmark.Options{code_class_prefix: "language-", smartypants: false, breaks: true}
    to_html(markdown, options) |> add_tailwind_classes()
  end

  defp to_html(markdown, options) do
    case Earmark.as_html(markdown, options) do
      {:ok, html, _} -> html
      {:error, html, _error_messages} -> html
    end
  end

  defp add_tailwind_classes(html) do
    html
    |> String.replace("<h1", "<h1 class=\"text-3xl font-bold my-4\"")
    |> String.replace("<h2", "<h2 class=\"text-2xl font-bold my-3\"")
    |> String.replace("<h3", "<h3 class=\"text-xl font-bold my-2\"")
    |> String.replace("<h4", "<h4 class=\"text-lg font-bold my-2\"")
    |> String.replace("<h5", "<h5 class=\"text-base font-bold my-1\"")
    |> String.replace("<h6", "<h6 class=\"text-sm font-bold my-1\"")
    |> String.replace("<p", "<p class=\"my-2\"")
    |> String.replace("<ul", "<ul class=\"list-disc list-inside my-2\"")
    |> String.replace("<ol", "<ol class=\"list-decimal list-inside my-2\"")
    |> String.replace("<li", "<li class=\"ml-4\"")
    |> String.replace("<code", "<code class=\"bg-base-200 text-base-content px-1 rounded\"")
    |> String.replace("<pre", "<pre class=\"bg-base-200 p-2 rounded overflow-x-auto my-2\"")
    |> String.replace("<blockquote", "<blockquote class=\"border-l-4 border-base-300 pl-4 my-2\"")
    |> String.replace("<a", "<a class=\"text-primary hover:underline\"")
  end
end
