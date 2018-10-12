defmodule Discuss.PageController do
  use Discuss.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
    IO.puts "Before signin"

  end
end
