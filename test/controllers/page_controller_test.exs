defmodule Discuss.PageControllerTest do
  use Discuss.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Hello Discuss!"
  end
end
