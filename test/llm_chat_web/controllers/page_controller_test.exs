defmodule LlmChatWeb.PageControllerTest do
  use LlmChatWeb.ConnCase

  setup tags do
    LlmChat.DataCase.setup_sandbox(tags)
    :ok
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~
             "Please note: You will need to authenticate with Google to access the chat features."
  end
end
